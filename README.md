## Table of contents

- [Repository layout](#repository-layout)
- [Architecture overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Important files and what they do](#important-files-and-what-they-do)
- [Quick start — Jenkins EC2 deployment](#quick-start---jenkins-ec2-deployment)
- [Quick start — EKS cluster deployment](#quick-start---eks-cluster-deployment)
- [Common Terraform commands](#common-terraform-commands)
- [Variables and customization](#variables-and-customization)
- [Backends and state](#backends-and-state)
- [Security, costs, and cleanup](#security-costs-and-cleanup)
- [Troubleshooting and tips](#troubleshooting-and-tips)
- [Next steps / Recommendations](#next-steps--recommendations)
- [Contributing](#contributing)
- [License & contact](#license--contact)

---

## Repository layout

- terraform_jenkins_eks/
  - `provider.tf` — AWS provider config and version (aws = 6.28.0)
  - `backend.tf` — S3 backend configuration (bucket: `terraform-jenkins-eks-project`, key: `jenkins/terraform.tfstate`)
  - `main.tf` — VPC + Security Group + EC2 instance (Jenkins) modules and resource definitions
  - `variables.tf` — variables for Jenkins configuration (vpc_cidr, public_subnets, instance_type)
  - `terraform.tfvars` — example var values for Jenkins stack
  - `jenkins-install.sh` — user-data script used to install Jenkins, Git, Terraform, kubectl on the instance
  - `README.md` — (small message present in repo)
- eks/
  - `provider.tf` — AWS provider config (aws = 6.28.0)
  - `backend.tf` — S3 backend config (bucket: `terraform-jenkins-eks-project`, key: `eks/terraform.tfstate`)
  - `main.tf` — VPC + EKS module configuration (terraform-aws-modules/eks/aws)
  - `variables.tf` — variables including vpc_cidr, public/private subnets
  - `terraform.tfvars` — example var values for EKS stack
  - `data.tf` — availability zones data source

---

## Architecture overview

This repository separates concerns into 2 independent Terraform deployments:

1. Jenkins (EC2-based)
   - Uses `terraform-aws-modules/vpc/aws` for VPC and public subnet(s)
   - Creates a Security Group allowing HTTP (8080/8090) and SSH and egress as required
   - Provisions an EC2 instance with `user_data` that runs `jenkins-install.sh` on boot to install Jenkins, Git, Terraform, and kubectl

2. EKS (Kubernetes cluster)
   - Uses `terraform-aws-modules/vpc/aws` for VPC and `terraform-aws-modules/eks/aws` for the EKS cluster
   - Deploys managed node groups (example instance type: `t2.small`, configurable)
   - Private and public subnets defined for cluster placement

These stacks can be used independently (e.g., run just Jenkins provisioning or just EKS), but the repository aims to enable a CI/CD pipeline that uses Jenkins (on EC2) to operate on workloads deployed to EKS.

---

## Prerequisites

- An AWS account with permissions to create IAM roles, EC2, VPC, EKS, S3 (for state backend), and related resources.
- Terraform installed (recommended 1.4+ — check compatibility with modules; provider pinned: aws = 6.28.0).
- AWS CLI installed (for authentication and kubeconfig setup).
- kubectl (for interacting with EKS).
- A pre-created EC2 key pair if you intend to SSH to the Jenkins instance (the Terraform config references `key_name = "jenkins-server-key"` — update as needed).
- Create the S3 backend bucket(s) or change backend settings before running `terraform init` (see [Backends and state](#backends-and-state)).

Environment notes:
- Set AWS credentials via environment variables, shared profile, or IAM role on a dev machine:
  - `export AWS_PROFILE=your-profile`
  - `export AWS_REGION=us-east-1` (the Terraform provider files set `region = "us-east-1"`)

---

## Important files and what they do

- terraform_jenkins_eks/provider.tf
  - Specifies the AWS provider version (6.28.0) and region `us-east-1`.
- terraform_jenkins_eks/backend.tf
  - Configures S3 backend:
    - bucket: `terraform-jenkins-eks-project`
    - key: `jenkins/terraform.tfstate`
    - region: `us-east-1`
- terraform_jenkins_eks/jenkins-install.sh
  - Bash script that installs Jenkins, Git, Terraform, and kubectl on Amazon Linux 2 (uses yum, installs OpenJDK 11, Jenkins package repo).
- terraform_jenkins_eks/main.tf
  - Creates VPC, security group, and EC2 instance; the EC2 module uses `user_data = file("jenkins-install.sh")`.
- eks/backend.tf
  - Configures S3 backend:
    - bucket: `terraform-jenkins-eks-project`
    - key: `eks/terraform.tfstate`
- eks/main.tf
  - Creates a VPC and an EKS cluster using the `terraform-aws-modules/eks/aws` module with managed node groups
  - Example kubernetes_version set to `1.33` (adjust to a supported version in your account/region)

---

## Quick start — Jenkins EC2 deployment

1. Prepare backend (S3) and ensure the bucket exists:
   - Create S3 bucket `terraform-jenkins-eks-project` (or update `backend.tf` to your bucket).
   - Optionally enable versioning and encryption on the backend bucket.

2. Change to the Jenkins terraform directory:
   - `cd terraform_jenkins_eks`

3. Customize variables:
   - Edit `terraform.tfvars` or provide overrides via `-var` or environment variables.
   - Ensure `instance_type`, `vpc_cidr`, and `public_subnets` are as desired.

4. Initialize and apply:
   - `terraform init`
   - `terraform plan -out plan.tfplan`
   - `terraform apply "plan.tfplan"`

5. After apply completes:
   - Note the EC2 public IP — Jenkins will be available on port `8080` (or ports allowed by the SG).
   - The `jenkins-install.sh` script runs as user-data and will install Jenkins and start the service.
   - SSH into the instance if needed (ensure your `key_name` exists in the region).

6. Initial Jenkins setup:
   - Connect to `http://<ec2-public-ip>:8080` and follow Jenkins initial setup.
   - Install recommended plugins and create an admin user.

---

## Quick start — EKS cluster deployment

1. Prepare backend S3 bucket or reuse the same bucket but different `key` in `eks/backend.tf`.

2. Change to the EKS terraform directory:
   - `cd eks`

3. Customize variables in `eks/terraform.tfvars`:
   - Set `vpc_cidr`, `private_subnets`, `public_subnets` as appropriate for your network design.

4. Initialize and apply:
   - `terraform init`
   - `terraform plan -out eks-plan.tfplan`
   - `terraform apply "eks-plan.tfplan"`

5. Configure kubectl to use the created cluster:
   - After Terraform creates the EKS cluster, run:
     - `aws eks update-kubeconfig --region us-east-1 --name my-eks-cluster`
   - Validate:
     - `kubectl get nodes`
     - `kubectl get pods -A`

Notes:
- The example config uses managed node groups with `instance_type = ["t2.small"]`. Adjust instance types and scaling settings as needed.
- Check the `kubernetes_version` value in `eks/main.tf` and change to a region-supported version if required.

---

## Common Terraform commands

- Initialize working directory:
  - `terraform init`
- Validate:
  - `terraform validate`
- Create plan:
  - `terraform plan -out plan.tfplan`
- Apply:
  - `terraform apply "plan.tfplan"`
- Destroy (clean up resources):
  - `terraform destroy`
  - Or `terraform plan -destroy -out destroy.tfplan && terraform apply "destroy.tfplan"`

---

## Variables and customization

Examples found in repo:

- terraform_jenkins_eks/terraform.tfvars
  - vpc_cidr = "10.0.0.0/16"
  - public_subnets = ["10.0.1.0/24"]
  - instance_type = "t2.micro"

- eks/terraform.tfvars
  - vpc_cidr = "192.168.0.0/16"
  - private_subnets = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
  - public_subnets  = ["192.168.4.0/24", "192.168.5.0/24", "192.168.6.0/24"]

When customizing:
- Keep subnet CIDR ranges non-overlapping with your existing network to avoid routing issues.
- Update EC2 `key_name` to an existing key pair in your AWS account (`jenkins-server-key` is referenced in the EC2 module).
- Consider tagging and naming conventions to track resources.

---

## Backends and state

Both stacks are configured to use S3 backends in `backend.tf`:
- Bucket: `terraform-jenkins-eks-project`
- Keys:
  - Jenkins stack: `jenkins/terraform.tfstate`
  - EKS stack: `eks/terraform.tfstate`

Before running `terraform init`:
- Create the S3 bucket and an optional DynamoDB table for state locking (recommended).
- Or change `backend.tf` to point to your own bucket and lock table.

Example to create DynamoDB lock table:
- Table name: `terraform-locks`
- Primary key: `LockID` (string)

---

## Security, costs, and cleanup

Security:
- Do not commit AWS credentials to Git. Use environment variables, AWS profiles, or IAM roles.
- Secure the Jenkins server:
  - Limit Security Group access to trusted IPs for SSH and the Jenkins web UI.
  - Use HTTPS for Jenkins (set up a reverse proxy + certificate).
  - Rotate credentials and lock down IAM policies for any instance profiles or roles you attach.

Costs:
- EC2 instances, EKS cluster control plane and worker nodes, NAT gateways, and other AWS resources will incur costs.
- EKS control plane is billed by AWS; monitor the cluster when testing.
- Use small instance types for development (example uses `t2.micro` and `t2.small`), but be mindful of AWS free-tier limits and availability.

Cleanup:
- Run `terraform destroy` in each directory (after setting proper AWS credentials) to remove resources.
- Manually verify that S3 backend states and any created S3 buckets / DynamoDB tables are handled according to your policies.

---

## Troubleshooting and tips

- If propagation issues or resource limits occur, increase timeouts or re-run `terraform apply`.
- EKS version mismatch:
  - The repo references `kubernetes_version = "1.33"` — replace with a supported Kubernetes version for your AWS region (e.g., `1.27`/`1.28` etc.) before applying if `1.33` is not supported yet.
- If `jenkins-install.sh` fails:
  - SSH into the instance and inspect logs: `sudo journalctl -u jenkins` and system logs.
  - Confirm the instance has internet access (NAT or public IP) to download packages.
- Backend initialization errors:
  - Ensure the S3 bucket exists and the executing IAM principal has `s3:GetObject`, `s3:PutObject`, `s3:ListBucket`, and if using DynamoDB locking, the appropriate DynamoDB permissions.

---

## Next steps / Recommendations

- Integrate Jenkins with EKS:
  - Either run Jenkins agents inside the EKS cluster (Kubernetes plugin) or configure Jenkins to deploy to the EKS cluster via kubectl/helm.
- Add CI pipeline examples:
  - Create example Jenkins pipelines (Jenkinsfile) that demonstrate building Docker images and deploying to EKS.
- Modularize more:
  - Break down the Terraform into reusable modules (VPC module reused across stacks).
- Add automated tests:
  - Use infrastructure testing frameworks (e.g., Terratest) or CI (GitHub Actions) to validate Terraform plan/validate.
- Improve security:
  - Use IAM roles for service accounts (IRSA) for pods on EKS, use least privilege IAM policies for Jenkins.

---

## Contributing

Contributions are welcome. Suggested workflow:
1. Fork the repository.
2. Create a feature branch: `git checkout -b feat/my-change`
3. Make changes, add documentation or tests.
4. Open a pull request describing the change and usage details.

Please ensure:
- Sensitive information is never committed.
- Terraform code is formatted: `terraform fmt`.
- Modules are validated: `terraform validate`.

---

## License & contact

- This repository does not include a LICENSE file in the current tree. Add a license of your choice if you intend to open-source it (e.g., MIT, Apache-2.0).
- Questions or issues: open an issue in the GitHub repository.
