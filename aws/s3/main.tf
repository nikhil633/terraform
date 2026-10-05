resource "aws_s3_bucket" "example" {
  bucket = "my-tf-test-bucket-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}


resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}