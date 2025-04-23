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
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the
# specific language governing permissions and limitations
# under the License.
#
# --------------------------------------------------------------------------------------

resource "aws_iam_role" "iam_role" {
  count = var.node_iam_role_arn != null ? 0 : 1
  name  = join("-", [var.eks_cluster_name, var.node_group_name, "eks-node-group-iam-role"])

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  tags = var.tags
}

# Required as per https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html
resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  count      = var.node_iam_role_arn != null ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.iam_role[0].name

  depends_on = [
    aws_iam_role.iam_role
  ]
}

# Required as per https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html
resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  count      = var.node_iam_role_arn != null ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.iam_role[0].name

  depends_on = [
    aws_iam_role.iam_role
  ]
}

# Required as per https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html
resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  count      = var.node_iam_role_arn != null ? 0 : 1
  role       = aws_iam_role.iam_role[0].name

  depends_on = [
    aws_iam_role.iam_role
  ]
}

resource "aws_iam_role_policy_attachment" "amazon_ssm_managed_instance_core" {
  count      = var.enable_ssm_access == false ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.iam_role[0].name

  depends_on = [
    aws_iam_role.iam_role
  ]
}

/* TODO:: Review and remove if not required
resource "aws_iam_role_policy_attachment" "amazon_cloud_watch_agent_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.iam_role.name

  depends_on = [
    aws_iam_role.iam_role
  ]
}

# Ignore: AVD-AWS-0057 (https://avd.aquasec.com/misconfig/aws/iam/avd-aws-0057/)
# Reason: This policy provides the necessary permissions for configuring the cluster autoscaler
# AWS Documentation: https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#full-cluster-autoscaler-features-policy-recommended
# trivy:ignore:AVD-AWS-0057
resource "aws_iam_policy" "node_group_autoscaler_policy" {
  name = join("-", [var.eks_cluster_name, var.node_group_name, "eks-cluster-auto-scaler-policy"])
  policy = jsonencode({
    Statement = [{
      Action = [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:DescribeInstanceTypes"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
    Version = "2012-10-17"
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_ca_iam_policy_attach" {
  role       = aws_iam_role.iam_role.name
  policy_arn = aws_iam_policy.node_group_autoscaler_policy.arn

  depends_on = [
    aws_iam_role.iam_role,
    aws_iam_policy.node_group_autoscaler_policy
  ]
}
*/

# Required for accessing ECR Cache registries
# Ignore: AVD-AWS-0057 (https://avd.aquasec.com/misconfig/aws/iam/avd-aws-0057/)
# Reason: This policy provides the necessary permissions to use pull through cache to the Node Group
# AWS Documentation: https://docs.aws.amazon.com/AmazonECR/latest/userguide/pull-through-cache.html
# trivy:ignore:AVD-AWS-0057
resource "aws_iam_policy" "amazon_ec2_cache_policy" {
  count = var.node_iam_role_arn != null ? 0 : 1
  name  = join("-", [var.eks_cluster_name, var.node_group_name, "eks-cluster-ecr-pull-cache-policy"])
  policy = jsonencode({
    Statement = [{
      Action = [
        "ecr:CreatePullThroughCacheRule",
        "ecr:BatchImportUpstreamImage",
        "ecr:CreateRepository"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
    Version = "2012-10-17"
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_cache_policy_attachment" {
  count      = var.node_iam_role_arn != null ? 0 : 1
  policy_arn = aws_iam_policy.amazon_ec2_cache_policy[0].arn
  role       = aws_iam_role.iam_role[0].name

  depends_on = [
    aws_iam_role.iam_role
  ]
}
