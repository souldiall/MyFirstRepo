############################################
# VPC
############################################
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

############################################
# Security Groups
############################################
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.main.id

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

resource "aws_security_group" "web_sg" {
  name   = "web-sg"
  vpc_id = aws_vpc.main.id

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

############################################
# ALB
############################################
resource "aws_lb" "alb" {
  name               = "path-routing-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
}

############################################
# Target Groups
############################################
resource "aws_lb_target_group" "app1_tg" {
  name     = "tg-app1"
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

############################################
# Listener + Path-Based Routing
############################################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Welcome to app1 or app2"
      status_code  = "200"
    }
  }
}

############################################
# /app1 HTML Response
############################################
resource "aws_lb_listener_rule" "app1_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      status_code  = "200"
      message_body = <<EOF
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
EOF
    }
  }

  condition {
    path_pattern {
      values = [
        "/app1",
        "/app1/*"
      ]
    }
  }
}

############################################
# /app2 HTML Response
############################################
resource "aws_lb_listener_rule" "app2_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 2

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      status_code  = "200"
      message_body = <<EOF
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
EOF
    }
  }

  condition {
    path_pattern {
      values = [
        "/app2",
        "/app2/*"
      ]
    }
  }
}

############################################
# EC2 Instance 1 (Ubuntu + HTML)
############################################
resource "aws_instance" "app1" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  tags = {
    Name  = "App1-Ubuntu"
    Owner = "Souleymane"
  }

  root_block_device {
    tags = {
      Name = "App1-Ubuntu"
    }
  }

  user_data = <<-EOF
#!/bin/bash
apt update -y
apt install -y apache2
systemctl enable --now apache2

cat << 'HTML' > /var/www/html/index.html
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
EOF
}

############################################
# EC2 Instance 2 (Ubuntu + HTML)
############################################
resource "aws_instance" "app2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_b.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  tags = {
    Name  = "App2-Ubuntu"
    Owner = "Souleymane"
  }

  root_block_device {
    tags = {
      Name = "App2-Ubuntu"
    }
  }

  user_data = <<-EOF
#!/bin/bash
apt update -y
apt install -y apache2
systemctl enable --now apache2

cat << 'HTML' > /var/www/html/index.html
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
EOF
}

############################################
# Target Group Attachments
############################################
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
