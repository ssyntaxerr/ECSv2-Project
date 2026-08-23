terraform {
  backend "s3" {
    bucket = "ecsv2-bucket-sufs"
    key    = "terraform.tfstate"
    region = "eu-west-2"
  }
}