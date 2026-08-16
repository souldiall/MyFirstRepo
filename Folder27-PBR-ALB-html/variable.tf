variable "ami_id" {
  type        = string
  default     = "ami-0b6d9d3d33ba97d99"
  description = "The AMI ID for the ALB instances"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "The instance type for the ALB instances"
}
