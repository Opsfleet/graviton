resource "aws_codecommit_repository" "go_api" {
  repository_name = "GoAPI"
  description     = "GO API that returns the architecture of the platform it is running on"
  default_branch  = "main"
}

resource "aws_codecommit_repository" "javascript_api" {
  repository_name = "JavascriptAPI"
  description     = "Javascript API that returns the architecture of the platform it is running on"
  default_branch  = "main"
}