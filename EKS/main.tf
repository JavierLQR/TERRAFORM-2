provider "aws" {
  region = "us-east-1"

}

module "eks" {
  source = "./modules/eks"
}
