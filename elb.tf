##################
# Load balancer
##################

resource "aws_lb" "gtp_prod_app" {
  name               = "gtp-prod-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.gtp_prod_lb.id]
  subnets            = [data.aws_subnets.public.ids[0], data.aws_subnets.public.ids[1]]
}

resource "aws_lb_listener" "gtp_prod_app_https" {
  load_balancer_arn = aws_lb.gtp_prod_app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.gtp_prod_app_cert.arn
  depends_on = [
    aws_lb_target_group.gtp_prod_app_https
  ]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gtp_prod_app_https.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "gtp_prod_app_https" {
  name     = "gtp-prod-app"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = data.aws_vpc.target_vpc.id
}

resource "aws_autoscaling_attachment" "gtp_prod_app_https" {
  autoscaling_group_name = aws_autoscaling_group.gtp_prod_app.id
  lb_target_group_arn    = aws_lb_target_group.gtp_prod_app_https.arn
}
