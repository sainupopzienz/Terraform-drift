terraform {
  backend "s3" {
    bucket = "terraform-state-196024211776"
    key    = "terraform-drift-test/terraform.tfstate"
    region = "us-east-1"
  }
}
