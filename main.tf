locals {
  servers = {
    web1 = "server1"
    web2 = "server2"
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "alb-vpc"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-b"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "alb-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instance_sg" {
  name        = "instance-sg"
  description = "Security group for instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "instance" {
  for_each               = local.servers
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = <<-EOF
#!/bin/bash
apt update -y
apt install apache2 -y
systemctl start apache2
systemctl enable apache2
echo "<h1>Hello Souleymane from My ${each.value}</h1>" > /var/www/html/index.html
EOF

  tags = {
    Name = each.key
  }
}

resource "aws_lb" "alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "my-alb"
  }
}

resource "aws_lb_target_group" "alb_tg" {
  name     = "my-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "my-alb-tg"
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "instance" {
  for_each          = aws_instance.instance
  target_group_arn  = aws_lb_target_group.alb_tg.arn
  target_id         = each.value.id
  port              = 80
}

    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
  }
}

resource "aws_lb_target_group" "app2_tg" {
  name     = "tg-app2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
  }
}

# -------------------------
# Listener
# -------------------------
resource "aws_lb_listener" "http" {
>>>>>>> 54e6e2b (Initial commit)
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
<<<<<<< HEAD
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}
resource "aws_lb_target_group_attachment" "alb_tg_attachment" {
  for_each         = local.servers
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = aws_instance.instance[each.key].id
  port             = 80
}
=======
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Welcome to App1 or App2"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener_rule" "app1_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = <<-HTML
<!DOCTYPE html>
<html>
<head>
<title>Application 1</title>
<style>
body{
    font-family: Arial, sans-serif;
    text-align:center;
    margin-top:100px;
    background-color:#e8f4fd;
}
.container{
    width:60%;
    margin:auto;
    padding:30px;
    background:white;
    border-radius:10px;
    box-shadow:0px 0px 10px gray;
}
h1{
    color:#0078d7;
}
</style>
</head>
<body>
<div class="container">
    <h1>Welcome to Application 1</h1>
    <h2>Path Accessed: /app1</h2>
    <p>This request was routed by AWS ALB using Path-Based Routing.</p>
    <p><strong>Target Group:</strong> TG-App1</p>
</div>
</body>
</html>
HTML
      status_code  = "200"
    }
  }

  condition {
    path_pattern {
      values = ["/app1", "/app1/*"]
    }
  }
}
resource "aws_lb_listener_rule" "app2_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = <<-HTML
<!DOCTYPE html>
<html>
<head>
<title>Application 2</title>
<style>
body{
    font-family: Arial, sans-serif;
    text-align:center;
    margin-top:100px;
    background-color:#fef3e2;
}
.container{
    width:60%;
    margin:auto;
    padding:30px;
    background:white;
    border-radius:10px;
    box-shadow:0px 0px 10px gray;
}
h1{
    color:#ff6b00;
}
</style>
</head>
<body>
<div class="container">
    <h1>Welcome to Application 2</h1>
    <h2>Path Accessed: /app2</h2>
    <p>This request was routed by AWS ALB using Path-Based Routing.</p>
    <p><strong>Target Group:</strong> TG-App2</p>
</div>
</body>
</html>
HTML
      status_code  = "200"
    }
  }

  condition {
    path_pattern {
      values = ["/app2", "/app2/*"]
    }
  }
} # -------------------------
# EC2 Instances (App1 & App2)
# -------------------------
resource "aws_instance" "app1" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
#!/bin/bash
set -eux
yum update -y
yum install -y httpd
systemctl enable --now httpd
echo "<h1>Application 1</h1>" > /var/www/html/index.html
EOF
}
resource "aws_instance" "app2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_b.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
#!/bin/bash
set -eux
yum update -y
yum install -y httpd
systemctl enable --now httpd
echo "<h1>Application 2</h1>" > /var/www/html/index.html
EOF
} # -------------------------
# Register EC2 Instances to Target Groups
# -------------------------
resource "aws_lb_target_group_attachment" "app1_attach" {
  target_group_arn = aws_lb_target_group.app1_tg.arn
  target_id        = aws_instance.app1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "app2_attach" {
  target_group_arn = aws_lb_target_group.app2_tg.arn
  target_id        = aws_instance.app2.id
  port             = 80
}
>>>>>>> 54e6e2b (Initial commit)
