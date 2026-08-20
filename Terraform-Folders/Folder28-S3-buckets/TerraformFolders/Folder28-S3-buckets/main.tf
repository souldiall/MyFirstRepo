resource "aws_s3_bucket" "buckets" {
  for_each = local.bucket_names

  bucket = each.value

  tags = {
    Environment = each.key
    Name        = each.value
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  for_each = local.bucket_names

  bucket = aws_s3_bucket.buckets[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  for_each = local.bucket_names

  bucket = aws_s3_bucket.buckets[each.key].id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  for_each = local.bucket_names

  bucket = aws_s3_bucket.buckets[each.key].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_policy" "public_read" {
  for_each = local.bucket_names

  bucket = aws_s3_bucket.buckets[each.key].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.buckets[each.key].arn}/*"
      }
    ]
  })
}

resource "aws_s3_object" "readme" {
  for_each = local.bucket_names

  bucket       = aws_s3_bucket.buckets[each.key].bucket
  key          = "README.txt"
  content      = local.readme_content[each.key]
  content_type = "text/html"
}