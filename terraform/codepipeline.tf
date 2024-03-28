resource "aws_iam_role" "event_role" {
  name = "TriggerPipelinesRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "events.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  inline_policy {
    name = "TriggerPipelinesPolcy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "codepipeline:StartPipelineExecution"
          ],
          "Resource" : [
            "arn:aws:codepipeline:${data.aws_region.region.id}:${data.aws_caller_identity.account_id.account_id}:*"
          ]
        }
      ]
    })
  }
}

resource "aws_cloudwatch_event_rule" "go_commit" {
  name        = "go_commit"
  description = "Capture commits to ${aws_codecommit_repository.go_api.repository_name} repository"

  event_pattern = jsonencode({
    source      = ["aws.codecommit"]
    detail-type = ["CodeCommit Repository State Change"]
    detail = {
      event          = ["referenceUpdated"],
      repositoryName = [aws_codecommit_repository.go_api.repository_name]
    }
  })
}

resource "aws_cloudwatch_event_rule" "javascript_commit" {
  name        = "javascript_commit"
  description = "Capture commits to ${aws_codecommit_repository.javascript_api.repository_name} repository"

  event_pattern = jsonencode({
    source      = ["aws.codecommit"]
    detail-type = ["CodeCommit Repository State Change"]
    detail = {
      event          = ["referenceUpdated"],
      repositoryName = [aws_codecommit_repository.javascript_api.repository_name]
    }
  })
}

resource "aws_cloudwatch_event_target" "go_commit" {
  rule     = aws_cloudwatch_event_rule.go_commit.name
  arn      = aws_codepipeline.goapi_codepipeline.arn
  role_arn = aws_iam_role.event_role.arn
}

resource "aws_cloudwatch_event_target" "javascript_commit" {
  rule     = aws_cloudwatch_event_rule.javascript_commit.name
  arn      = aws_codepipeline.javascript_api_codepipeline.arn
  role_arn = aws_iam_role.event_role.arn
}

resource "random_id" "key" {
  byte_length = 8
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "codepipeline${random_id.key.hex}"
}

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_pab" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "CodePipelineRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = [
      aws_codebuild_project.go_api_x86.arn,
      aws_codebuild_project.go_api_arm.arn,
      aws_codebuild_project.go_api_manifest.arn,
      aws_codebuild_project.javascript_api_x86.arn,
      aws_codebuild_project.javascript_api_arm.arn,
      aws_codebuild_project.javascript_api_manifest.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "codecommit:GitPull",
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:GetRepository",
      "codecommit:UploadArchive",
      "codecommit:GetUploadArchiveStatus"
    ]
    resources = [
      aws_codecommit_repository.go_api.arn, aws_codecommit_repository.javascript_api.arn
    ]

  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

resource "aws_codepipeline" "goapi_codepipeline_single_arch" {
  name          = "GoApiSingleArch"
  pipeline_type = "V2"
  role_arn      = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName       = aws_codecommit_repository.go_api.repository_name
        BranchName           = aws_codecommit_repository.go_api.default_branch
        PollForSourceChanges = false
      }
      namespace = "codecommit"
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build_x86_Image"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output_x86"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.go_api_x86.name
        EnvironmentVariables = jsonencode(
          [
            {
              name  = "IMAGE_TAG"
              type  = "PLAINTEXT"
              value = "#{codecommit.CommitId}"
            },
          ]
        )
      }
    }
  }
}

resource "aws_codepipeline" "goapi_codepipeline" {
  name          = "GoApi"
  pipeline_type = "V2"
  role_arn      = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName       = aws_codecommit_repository.go_api.repository_name
        BranchName           = aws_codecommit_repository.go_api.default_branch
        PollForSourceChanges = false
      }
      namespace = "codecommit"
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build_x86_Image"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output_x86"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.go_api_x86.name
        EnvironmentVariables = jsonencode(
          [
            {
              name  = "IMAGE_TAG"
              type  = "PLAINTEXT"
              value = "#{codecommit.CommitId}"
            },
          ]
        )
      }
    }

    action {
      name             = "Build_ARM64_Image"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output_arm_64"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.go_api_arm.name
        EnvironmentVariables = jsonencode(
          [
            {
              name  = "IMAGE_TAG"
              type  = "PLAINTEXT"
              value = "#{codecommit.CommitId}"
            },
          ]
        )
      }
    }
  }

  stage {
    name = "Push"

    action {
      name             = "Build_Manifest"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output_manifest"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.go_api_manifest.name
        EnvironmentVariables = jsonencode(
          [
            {
              name  = "IMAGE_TAG"
              type  = "PLAINTEXT"
              value = "#{codecommit.CommitId}"
            },
          ]
        )
      }
    }
  }
}

resource "aws_codepipeline" "javascript_api_codepipeline" {
  name          = "JavascriptApi"
  pipeline_type = "V2"
  role_arn      = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName       = aws_codecommit_repository.javascript_api.repository_name
        BranchName           = aws_codecommit_repository.javascript_api.default_branch
        PollForSourceChanges = false
      }
      namespace = "codecommit"
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build_x86_Image"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output_x86"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.javascript_api_x86.name
        EnvironmentVariables = jsonencode(
          [
            {
              name  = "IMAGE_TAG"
              type  = "PLAINTEXT"
              value = "#{codecommit.CommitId}"
            },
          ]
        )
      }
    }

    action {
      name             = "Build_ARM64_Image"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output_arm_64"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.javascript_api_arm.name
        EnvironmentVariables = jsonencode(
          [
            {
              name  = "IMAGE_TAG"
              type  = "PLAINTEXT"
              value = "#{codecommit.CommitId}"
            },
          ]
        )
      }
    }
  }

  stage {
    name = "Push"

    action {
      name             = "Build_Manifest"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output_manifest"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.javascript_api_manifest.name
        EnvironmentVariables = jsonencode(
          [
            {
              name  = "IMAGE_TAG"
              type  = "PLAINTEXT"
              value = "#{codecommit.CommitId}"
            },
          ]
        )
      }
    }
  }
}