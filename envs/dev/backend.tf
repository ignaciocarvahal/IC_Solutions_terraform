terraform {
  backend "s3" {
    bucket         = "terraform-state-ignacio-587461243642"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
