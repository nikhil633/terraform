terraform {
    backend "s3" {
        bucket = "nikhil-mybucket143"
        key = "policy_governence/terraform.tfstate"
        region = "us-east-1"
        encrypt = true
        use_lockfile = "true"
    }
}