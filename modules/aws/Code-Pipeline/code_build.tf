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

resource "aws_codebuild_project" "build_project" {
  count        = length(var.pipeline_stages)
  name         = join("-", [var.project, var.application, var.environment, var.region, var.pipeline_stages[count.index].name])
  service_role = var.eks_access != false ? var.pipeline_stages[count.index].custom_codebuild_role_arn : aws_iam_role.codebuild_role[0].arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = var.pipeline_stages[count.index].build_compute_type
    image           = var.pipeline_stages[count.index].build_image
    type            = var.pipeline_stages[count.index].build_environment_type
    privileged_mode = var.pipeline_stages[count.index].build_privileged_mode

    dynamic "environment_variable" {
      for_each = var.pipeline_stages[count.index].build_environment_variables != null ? var.pipeline_stages[count.index].build_environment_variables : []
      content {
        name  = environment_variable.value["name"]
        value = environment_variable.value["value"]
      }
    }
  }

  dynamic "vpc_config" {
    for_each = var.pipeline_stages[count.index].build_vpc_config != null ? [var.pipeline_stages[count.index].build_vpc_config] : []
    content {
      vpc_id             = var.pipeline_stages[count.index].build_vpc_config.vpc_id
      subnets            = var.pipeline_stages[count.index].build_vpc_config.subnets
      security_group_ids = var.pipeline_stages[count.index].build_vpc_config.security_group_ids
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = var.pipeline_stages[count.index].buildspec
  }

  depends_on = [
    aws_iam_role.codebuild_role
  ]
}
