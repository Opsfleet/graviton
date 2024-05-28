resource "aws_iam_role" "codebuild_role" {
  name = "CodeBuildRole"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sts:AssumeRole"
        ],
        "Principal" : {
          "Service" : [
            "codebuild.amazonaws.com"
          ]
        }
      }
    ]
  })

  inline_policy {
    name = "AllowCodeBuildECRPushPolicy"
    policy = jsonencode(
      {
        "Statement" : [
          {
            "Sid" : "GetAuthorizationToken",
            "Effect" : "Allow",
            "Action" : [
              "ecr:GetAuthorizationToken"
            ],
            "Resource" : "*"
          },
          {
            "Action" : [
              "ecr:BatchCheckLayerAvailability",
              "ecr:BatchGetImage",
              "ecr:CompleteLayerUpload",
              "ecr:GetAuthorizationToken",
              "ecr:InitiateLayerUpload",
              "ecr:PutImage",
              "ecr:UploadLayerPart",
              "ecr:GetDownloadUrlForLayer"
            ],
            "Resource" : [aws_ecr_repository.javascript_api.arn, aws_ecr_repository.go_api.arn],
            "Effect" : "Allow"
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "codecommit:GitPull",
              "codecommit:GetBranch",
              "codecommit:GetCommit",
              "codecommit:GetRepository"
            ],
            "Resource" : [
              aws_codecommit_repository.go_api.arn, aws_codecommit_repository.javascript_api.arn
            ]
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "logs:CreateLogGroup"
            ],
            "Resource" : "arn:aws:logs:*:*:log-group:codebuild:*"
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource" : "arn:aws:logs:*:*:log-group:codebuild:log-stream:*"
          },
          {
            "Effect" : "Allow"
            "Action" : [
              "s3:ListObjects",
              "s3:ListBucket",
              "s3:GetObject",
              "s3:GetObjectVersion",
              "s3:GetBucketVersioning",
              "s3:PutObjectAcl",
              "s3:PutObject",
            ],
            "Resource" : [
              aws_s3_bucket.codepipeline_bucket.arn,
              "${aws_s3_bucket.codepipeline_bucket.arn}/*"
            ]
          }

        ]
      }

    )
  }
}

resource "aws_codebuild_project" "go_api_arm" {
  name          = "go_api_arm64"
  description   = "GoApi arm64 build"
  build_timeout = 5
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-aarch64-standard:3.0"
    type                        = "ARM_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.region.id
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.account_id.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.go_api.name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }

    environment_variable {
      name  = "ARCH"
      value = "arm64"
    }
  }

  source {
    type            = "CODECOMMIT"
    location        = aws_codecommit_repository.go_api.clone_url_http
    git_clone_depth = 1
  }

  source_version = aws_codecommit_repository.go_api.default_branch

  logs_config {
    cloudwatch_logs {
      group_name  = "codebuild"
      stream_name = "go_api_arm64"
    }
  }
}

resource "aws_codebuild_project" "go_api_x86" {
  name          = "go_api_x86"
  description   = "GoApi x86 build"
  build_timeout = 5
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.region.id
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.account_id.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.go_api.name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }

    environment_variable {
      name  = "ARCH"
      value = "x86"
    }
  }

  source {
    type            = "CODECOMMIT"
    location        = aws_codecommit_repository.go_api.clone_url_http
    git_clone_depth = 1
  }

  source_version = aws_codecommit_repository.go_api.default_branch

  logs_config {
    cloudwatch_logs {
      group_name  = "codebuild"
      stream_name = "go_api_x86"
    }
  }
}

resource "aws_codebuild_project" "go_api_manifest" {
  name          = "go_api_manifest"
  description   = "GoApi manifest build"
  build_timeout = 5
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.region.id
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.account_id.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.go_api.name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
  }

  source {
    type            = "CODECOMMIT"
    location        = aws_codecommit_repository.go_api.clone_url_http
    git_clone_depth = 1
    buildspec       = "manifest_buildspec.yaml"
  }

  source_version = aws_codecommit_repository.go_api.default_branch

  logs_config {
    cloudwatch_logs {
      group_name  = "codebuild"
      stream_name = "go_api_manifest"
    }
  }
}

resource "aws_codebuild_project" "javascript_api_arm" {
  name          = "javascript_api_arm64"
  description   = "JavascriptApi arm64 build"
  build_timeout = 5
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-aarch64-standard:3.0"
    type                        = "ARM_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.region.id
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.account_id.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.javascript_api.name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }

    environment_variable {
      name  = "ARCH"
      value = "arm64"
    }
  }

  source {
    type            = "CODECOMMIT"
    location        = aws_codecommit_repository.javascript_api.clone_url_http
    git_clone_depth = 1
  }

  source_version = aws_codecommit_repository.javascript_api.default_branch

  logs_config {
    cloudwatch_logs {
      status = "DISABLED"
    }
  }
}

resource "aws_codebuild_project" "javascript_api_x86" {
  name          = "javascript_api_x86"
  description   = "JavascriptApi x86 build"
  build_timeout = 5
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.region.id
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.account_id.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.javascript_api.name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }

    environment_variable {
      name  = "ARCH"
      value = "x86"
    }
  }

  source {
    type            = "CODECOMMIT"
    location        = aws_codecommit_repository.javascript_api.clone_url_http
    git_clone_depth = 1
  }

  source_version = aws_codecommit_repository.javascript_api.default_branch

  logs_config {
    cloudwatch_logs {
      status = "DISABLED"
    }
  }
}

resource "aws_codebuild_project" "javascript_api_manifest" {
  name          = "javascript_api_manifest"
  description   = "JavascriptApi manifest build"
  build_timeout = 5
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.region.id
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.account_id.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.javascript_api.name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
  }

  source {
    type            = "CODECOMMIT"
    location        = aws_codecommit_repository.javascript_api.clone_url_http
    git_clone_depth = 1
    buildspec       = "manifest_buildspec.yaml"
  }

  source_version = aws_codecommit_repository.javascript_api.default_branch

  logs_config {
    cloudwatch_logs {
      group_name  = "codebuild"
      stream_name = "javascript_api_manifest"
    }
  }
}