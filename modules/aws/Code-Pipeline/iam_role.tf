# -------------------------------------------------------------------------------------
#
# Copyright (c) 2025, WSO2 LLC. (https://www.wso2.com) All Rights Reserved.
#
# WSO2 LLC. licenses this file to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, 
# software distributed under the License is distributed on 
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
# either express or implied. See the License for the 
# specific language governing permissions and limitations under the License.
#
# --------------------------------------------------------------------------------------

# IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name               = join("-", [var.project, var.application, var.environment, var.region, "pipeline-iam-role"])
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json
}

data "aws_iam_policy_document" "codepipeline_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = join("-", [var.project, var.application, var.environment, var.region, "pipeline-policy"])
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
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
      "codestar-connections:GetConnectionToken",
      "codestar-connections:GetConnection",
      "codeconnections:GetConnectionToken",
      "codeconnections:GetConnection",
      "codeconnections:UseConnection"
    ]

    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      var.source_connection_arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [var.source_connection_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = ["*"]
  }
}

# EKS access role
resource "aws_iam_role" "eks_access_role" {
  name               = join("-", [var.project, var.application, var.environment, var.region, "eks-access-iam-role"])
  assume_role_policy = data.aws_iam_policy_document.eks_access_assume_role.json
}

data "aws_iam_policy_document" "eks_access_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "eks_access_codebuild_policy" {
  name   = join("-", [var.project, var.application, var.environment, var.region, "eks-access-policy"])
  role   = aws_iam_role.eks_access_role.id
  policy = data.aws_iam_policy_document.eks_access_policy.json
}

data "aws_iam_policy_document" "eks_access_policy" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:CreateLogGroup"]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.codepipeline_bucket.arn}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
      "ec2:CreateNetworkInterfacePermission"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
      "eks:DescribeNodegroup",
      "eks:ListNodegroups",
      "eks:DescribeFargateProfile",
      "eks:ListFargateProfiles",
      "eks:DescribeAddonVersions",
      "eks:AccessKubernetesApi"
    ]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["*"]
  }
}

# Code build role
resource "aws_iam_role" "codebuild_role" {
  name               = join("-", [var.project, var.application, var.environment, var.region, "codebuild-iam-role"])
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [module.eks_access_role.arn]
    }
  }
}

# IAM Role for CodeDeploy
resource "aws_iam_role" "codedeploy_role" {
  name               = join("-", [var.project, var.application, var.environment, var.region, "codedeploy-iam-role"])
  assume_role_policy = data.aws_iam_policy_document.codedeploy_assume_role.json
}

data "aws_iam_policy_document" "codedeploy_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [module.eks_access_role.arn]
    }
  }
}
