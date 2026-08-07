variable "ami-id" {
  default     = "ami-0b6d9d3d33ba97d99"
  description = "The AMI ID for the ALB instances"
}
variable "instance-type" {
  default     = "t2.micro"
  description = "The instance type for the ALB instances"
}