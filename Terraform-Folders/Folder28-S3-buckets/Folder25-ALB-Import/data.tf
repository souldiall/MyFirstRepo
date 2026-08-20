data "aws_lb_listener" "http" {
  arn = "arn:aws:elasticloadbalancing:us-east-1:582427612955:listener/app/ALB-Lab-ALB-rsDJ97ISgBH1/a4fa2637a9d78933/8c0a4213250cd857"
}

resource "aws_lb_listener_rule" "path_rule" {
  listener_arn = data.aws_lb_listener.http.arn
  priority     = 5

  condition {
    path_pattern {
      values = ["/ALB"]
    }
  }

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Welcome to Mr Valery Class"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener_rule" "terraform_path_rule" {
  listener_arn = data.aws_lb_listener.http.arn
  priority     = 4

  condition {
    path_pattern {
      values = ["/terraform"]
    }
  }

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Welcome to Mr Staline Class"
      status_code  = "200"
    }
  }
}