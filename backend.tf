terraform {
  required_version = ">=1.5"
  backend "s3" {
    region  = "us-east-1"
    profile = "default"
    key     = "terraformstatefile"
    bucket  = "terraformstatebucket2137"
  }
}
