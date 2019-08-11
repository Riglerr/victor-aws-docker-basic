output "alb_dns_name" {
  value       = aws_lb.primary.dns_name
  description = "The domain name of the load balancer"
}

data "aws_instance" "created" {

  filter {
    name   = "tag:Name"
    values = ["${var.instance_group_name}-asg"]
  }

  depends_on = [aws_autoscaling_group.primary]
}

output "asg_instances" {
  value = "${data.aws_instance.created}"
  description = "The instances created by the ASG"
}
