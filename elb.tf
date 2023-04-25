##################
# Load balancer
##################

resource "aws_lb" "gtp_prod_app" {
  name               = "gtp-prod-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.gtp_prod_lb.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_listener" "gtp_prod_app" {
  load_balancer_arn = aws_lb.gtp_prod_app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gtp_prod_app.arn
  }
}

resource "aws_lb_target_group" "gtp_prod_app" {
  name     = "gtp-prod-app"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}


resource "aws_autoscaling_attachment" "gtp_prod_app" {
  autoscaling_group_name = aws_autoscaling_group.gtp_prod_app.id
  lb_target_group_arn    = aws_lb_target_group.gtp_prod_app.arn
}
