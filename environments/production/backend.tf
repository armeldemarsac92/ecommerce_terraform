terraform {
  backend "s3" {
    bucket         = "tdev700-terraform-state"
    key            = "tdev700/prod.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}