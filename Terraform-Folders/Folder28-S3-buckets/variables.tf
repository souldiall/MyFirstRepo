variable "envs" {
  description = "Environment names for S3 buckets"
  type        = set(string)

  default = ["dev", "staging", "prod"]
}
