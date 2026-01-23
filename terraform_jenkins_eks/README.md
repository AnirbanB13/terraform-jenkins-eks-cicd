I reviewed the terraform_jenkins_eks folder (main.tf, provider.tf, backend.tf, terraform.tfvars, jenkins-install.sh, and the repo-level Jenkinsfile) and created a compact, attractive README tailored to this project. Below is the new README ready to drop into terraform_jenkins_eks/README.md — it uses badges, emojis, and GIFs to keep it lively while remaining concise and actionable.

````markdown name=terraform_jenkins_eks/README.md
# 🚀 Jenkins on EKS — Terraform Automation (compact & pretty)

![rocket header](https://media.giphy.com/media/3oEjI6SIIHBdRxXI40/giphy.gif)

[![Terraform](https://img.shields.io/badge/Terraform-%2325448C.svg?style=flat&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=flat&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-%23326CE5.svg?style=flat&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Jenkins](https://img.shields.io/badge/Jenkins-%23D24939.svg?style=flat&logo=jenkins&logoColor=white)](https://www.jenkins.io/)

A minimal, beautiful README for provisioning a Jenkins CI/CD platform on AWS EKS using Terraform + Helm. This repo automates VPC, EKS, IAM, and a Helm-deployed Jenkins (with pipelines running on Kubernetes agents).

Quick demo:  
![deploy demo](https://media.giphy.com/media/xUOxf48f5xYV8xkq1K/giphy.gif)

Why use this?
- 🔁 Reproducible infra-as-code
- ⚡ Fast CI/CD setup (Terraform + Helm)
- 🔒 Best-practice AWS resources (S3 backend, IAM scoping)
- ♻️ Clean destroy with `terraform destroy`

Highlights
- terraform_jenkins_eks/main.tf — VPC, SG, EC2 node definitions, EKS bits
- terraform_jenkins_eks/provider.tf — provider config (us-east-1)
- terraform_jenkins_eks/backend.tf — S3 remote state (bucket: terraform-jenkins-eks-project)
- terraform_jenkins_eks/terraform.tfvars — example variables (vpc_cidr, public_subnets, instance_type)
- terraform_jenkins_eks/jenkins-install.sh — helper to install Jenkins on EC2 (if used)
- Jenkinsfile (repo root) — a Jenkins pipeline that runs Terraform steps

Prerequisites ⚙️
- AWS account with permissions for: VPC, EKS, IAM, EC2, S3, ECR (for artifacts)
- Local: Terraform v1.2+, AWS CLI, kubectl, helm, git
- Optional but recommended: S3 bucket + DynamoDB for remote state locking

Compact Quickstart (5 min)
1. Clone
   git clone https://github.com/AnirbanB13/terraform-jenkins-eks-cicd.git
   cd terraform-jenkins-eks/terraform_jenkins_eks

2. Configure AWS + env
   export AWS_PROFILE=your-profile
   export AWS_REGION=us-east-1

3. (Optional) Backend — update backend.tf or init with your bucket
   terraform init -backend-config="bucket=your-state-bucket" \
                  -backend-config="key=jenkins/terraform.tfstate" \
                  -backend-config="region=${AWS_REGION}"

4. Plan & Apply
   terraform validate
   terraform plan -out=tfplan
   terraform apply -auto-approve

5. Get Jenkins URL & kubeconfig
   terraform output -json
   # or:
   kubectl get svc --namespace jenkins

Example variables (dev.tfvars)
```hcl
cluster_name = "my-jenkins-eks"
region       = "us-east-1"
node_instance_types = ["t3.medium"]
jenkins_admin_user   = "admin"
jenkins_admin_password = "ChangeMe123!"
```

Useful commands
- Format & validate: terraform fmt && terraform validate
- Preview: terraform plan
- Destroy: terraform destroy -auto-approve

Security & notes 🔐
- Do NOT commit secrets or real admin passwords. Use SSM / Secrets Manager for production.
- Backend in this folder references bucket `terraform-jenkins-eks-project` — change to your own bucket.
- IAM least-privilege is recommended for automation users.

Files of interest
- main.tf — network, SGs, EC2, EKS bits
- provider.tf — provider config (region)
- backend.tf — S3 backend
- terraform.tfvars — example quick overrides
- jenkins-install.sh — quick install script (for EC2-based Jenkins)
- Jenkinsfile — pipeline automation for Terraform runs

````