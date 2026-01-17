terraform {
  backend "s3" {
    bucket = "terraform-jenkins-eks-project"
    key    = "jenkins/terraform.tfstate"
    region = "us-east-1"
  }
}