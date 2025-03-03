terraform {
  backend "s3" {
    bucket         = "tdev700-terraform-state"
    key            = "tdev700/production.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}