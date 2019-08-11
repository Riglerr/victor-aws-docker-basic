// ******************************************************************
// *                       LOAD BALANCING                           *
// * ALB - LISTENER - LISTENER RULE - TARGET GROUP - SECURITY GROUP *
// ******************************************************************

#region LOAD BALANCING
resource "aws_lb" "primary" {
  name               = "${var.instance_group_name}-alb"
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = [
    aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.primary.arn
  port              = var.listen_port
  protocol          = var.listen_protocol

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: Page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "primary" {
  name     = "${var.instance_group_name}-tg"
  port     = var.server_port
  protocol = var.server_protocol
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener_rule" "primary" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  condition {
    field  = "path-pattern"
    values = ["*"]
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.primary.arn
  }
}

resource "aws_security_group" "alb" {
  name = "${var.instance_group_name}-sg"

  ingress {
    from_port   = var.listen_port
    to_port     = var.listen_port
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

#endregion

// ******************************************************************
// *                       AUTO SCALING                             *
// * LAUNCH CONFIGURATION - SCALING GROUP - SECURITY GROUP          *
// ******************************************************************

#region AUTO SCALING

resource "aws_launch_configuration" "primary" {
  image_id        = var.ami_id
  instance_type   = var.instance_type
  key_name        = var.key_name
  user_data       = <<-EOF
              #!/bin/bash
              yum install busybox
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  security_groups = [aws_security_group.ec2.id]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "primary" {
  launch_configuration = aws_launch_configuration.primary.name
  vpc_zone_identifier  = var.subnet_ids
  min_size             = var.min_size
  max_size             = var.max_size

  target_group_arns = [
    aws_lb_target_group.primary.arn]
  health_check_type = "ELB"

  tags = [{
    key                 = "Name"
    value               = "${var.instance_group_name}-asg"
    propagate_at_launch = true
  }]
}

resource "aws_security_group" "ec2" {
  name = "${var.instance_group_name}-ec2-sg"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  // All internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}
#endregion