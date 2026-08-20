resource "aws_lb" "ALB-Lab-ALB-rsDJ97ISgBH1" {
  name               = "ALB-Lab-ALB-rsDJ97ISgBH1"
  load_balancer_type = "application"

  subnets = [
    "subnet-054e622b557c184a3",
    "subnet-0855e646452546789"
  ]
}