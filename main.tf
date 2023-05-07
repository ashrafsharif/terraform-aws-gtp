provider "aws" {
  region     = "ap-southeast-1"
  access_key = ""
  secret_key = ""

  default_tags {
    tags = {
      Environment = "Production"
      Name        = "GTP"
      CreatedBy   = "ACE/Silverstream/DataSpeed"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

##################
# Launch template
##################

data "aws_key_pair" "deployer" {
  key_name = ""
}

resource "aws_launch_configuration" "gtp_prod_app" {
  name_prefix                 = "gtp-prod-auto-scaling-"
  image_id                    = "ami-04ba270ccd8098407" # Red Hat Enterprise Linux 9 (HVM), SSD Volume Type x86_64
  instance_type               = "t2.small"              # Real prod: c5.2xlarge
  user_data                   = file("user-data-app.sh")
  security_groups             = [aws_security_group.gtp_prod_app_instance.id]
  key_name                    = data.aws_key_pair.deployer.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.gtp_prod_ec2_instance_profile.name

  lifecycle {
    create_before_destroy = true
  }
}

##################
# Auto scaling
##################

resource "aws_autoscaling_group" "gtp_prod_app" {
  name_prefix          = "gtp-prod-app-"
  min_size             = 1
  max_size             = 3
  desired_capacity     = 2
  launch_configuration = aws_launch_configuration.gtp_prod_app.name
  vpc_zone_identifier  = [data.aws_subnets.public.ids[0], data.aws_subnets.public.ids[1]]

  tag {
    key                 = "Name"
    value               = "gtp-prod-app (autoscaling)"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "Application"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "Production"
    propagate_at_launch = true
  }

  tag {
    key                 = "CodeDeploy"
    value               = "gtp-prod-app"
    propagate_at_launch = true
  }

  tag {
    key                 = "Snapshot"
    value               = "true"
    propagate_at_launch = true
  }

}
