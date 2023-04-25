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

######
# VPC
######

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "GTP-PROD"
  cidr = "10.165.0.0/16"

  azs                  = ["ap-southeast-1a", "ap-southeast-1b"]
  public_subnets       = ["10.165.1.0/24", "10.165.2.0/24"]
  private_subnets      = ["10.165.11.0/24", "10.165.12.0/24"]
  database_subnets     = ["10.165.21.0/24", "10.165.22.0/24"]
  elasticache_subnets  = ["10.165.31.0/24", "10.165.32.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
  #single_nat_gateway     = true
  #one_nat_gateway_per_az = false

}

######
# AMI
######

data "aws_ami" "rhel" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["RHEL-9.0.0_HVM-*-x86_64-*"]
  }
}

data "aws_ami" "rockylinux9" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["Rocky-9-EC2-Base-9*x86_64-*"]
  }
}

##################
# Launch template
##################

data "aws_key_pair" "deployer" {
  key_name = ""
}

resource "aws_launch_configuration" "gtp_prod_app" {
  name_prefix                 = "gtp-prod-auto-scaling-"
  image_id                    = data.aws_ami.rockylinux9.id # Real prod: data.aws_ami.rhel.id
  instance_type               = "t2.small"                  # Real prod: c5.2xlarge
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
  vpc_zone_identifier  = module.vpc.public_subnets

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
