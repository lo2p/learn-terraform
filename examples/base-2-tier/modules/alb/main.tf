resource "aws_lb" "alb" {
  name               = var.name
  load_balancer_type = "application"
  internal           = false
  security_groups    = var.security_groups
  subnets            = var.subnets
  idle_timeout       = 60
  enable_deletion_protection = false
  tags = var.tags
}

resource "aws_lb_target_group" "tg" {
  name        = substr(var.target_group_name, 0, 32)
  vpc_id      = var.vpc_id
  port        = var.target_group_port
  protocol    = "HTTP"
  target_type = "instance"

  health_check {
    enabled             = true
    path                = var.health_check_path
    matcher             = "200-399"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.listener_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group_attachment" "attach" {
  count            = var.target_count
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = var.target_ids[count.index]
  port             = var.target_group_port
}
