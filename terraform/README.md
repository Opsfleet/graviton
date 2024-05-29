# Terraform Infrastructure for Demo

This repository contains Terraform manifests that are designed to deploy all the necessary infrastructure required to run the demo. The infrastructure can be deployed using either Terraform or OpenTofu.

## Infrastructure Components

The following components will be set up by these manifests:

- **VPC, Subnets, etc:** The manifests will set up a Virtual Private Cloud (VPC) with the necessary subnets for your resources.

- **IAM roles and permissions:** The manifests will create the necessary IAM roles and assign the appropriate permissions to these roles.

- **CodeCommit, CodeBuild, and CodePipeline:** The manifests will set up a CodeCommit repository, a CodeBuild project for building your code, and a CodePipeline for continuous integration and continuous deployment (CI/CD).

- **EKS Cluster and core managed nodegroup:** The manifests will set up an Amazon EKS cluster along with a core managed nodegroup.

## Usage

To deploy the infrastructure, follow these steps:

1. Clone this repository.
2. Navigate to the repository directory.
3. Apply the Terraform manifests using either Terraform or OpenTofu.

Please refer to the individual manifest files for more detailed instructions.