terraform {
    backend "s3" {
        bucket = "nikhil-mybucket143"
        key = "cloudfront/terraform.tfstate"
        region = "us-east-1"
        encrypt = true
    }
}