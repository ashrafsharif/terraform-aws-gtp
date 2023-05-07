################
# CodeDeploy
################

resource "aws_codedeploy_app" "gtp_prod_app" {
  compute_platform = "Server"
  name             = "gtp-prod-app"
}

resource "aws_codedeploy_deployment_config" "gtp_prod_app" {
  deployment_config_name = "gtp-prod-app-deployment-config"

  minimum_healthy_hosts {
    type  = "HOST_COUNT"
    value = 1
  }
}

resource "aws_sns_topic" "gtp_prod_app" {
  name = "gtp-prod-app-topic"
}

resource "aws_codedeploy_deployment_group" "gtp_prod_app" {
  app_name               = aws_codedeploy_app.gtp_prod_app.name
  deployment_group_name  = "gtp-prod-app"
  service_role_arn       = aws_iam_role.gtp_prod_app_role.arn
  deployment_config_name = aws_codedeploy_deployment_config.gtp_prod_app.id

  ec2_tag_filter {
    key   = "CodeDeploy"
    type  = "KEY_AND_VALUE"
    value = "gtp-prod-app"
  }

  trigger_configuration {
    trigger_events     = ["DeploymentFailure"]
    trigger_name       = "gtp-trigger"
    trigger_target_arn = aws_sns_topic.gtp_prod_app.arn
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  alarm_configuration {
    alarms  = ["gtp-alarm"]
    enabled = true
  }
}
