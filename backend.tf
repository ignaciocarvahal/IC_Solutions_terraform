terraform {
  backend "s3" {
    bucket         = "terraform-state-ignacio-587461243642"
    key            = "infraestructura/terraform.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }

  required_version = "~> 1.6"
}
