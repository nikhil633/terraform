terraform {
    backend "s3" {
        bucket = "nikhil-mybucket143"
        key = "ec2/terraform.tfstate"
        region = "us-east-1"
        encrypt = true
    }
}