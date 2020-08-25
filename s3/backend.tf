terraform {
  backend "s3" {
    bucket         = "tlz-demo-dev-terraform-state-567366700664"
    dynamodb_table = "tlz-demo-dev-terraform-state-567366700664-lock"
    key            = "tlz-ptfe-s3.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
