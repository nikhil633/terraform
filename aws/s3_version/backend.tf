terraform {
  backend "s3" {
    bucket  = "nikhil-mybucket143"
    key     = "s3_version/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}