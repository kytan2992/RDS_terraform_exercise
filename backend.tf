terraform {
  backend "s3" {
    bucket = "ky-s3-terraform"
    key    = "ky-tf-coaching8.tfstate"
    region = "us-east-1"
  }
}