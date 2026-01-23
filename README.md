# terraform-jenkins-eks-cicd
Automated, reproducible infrastructure as code (IaC) to deploy Jenkins on AWS EKS with a CI/CD pipeline using Terraform, Helm, and Kubernetes.

[![Terraform](https://img.shields.io/badge/Terraform-%233452A6.svg?style=flat&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23232F3E.svg?style=flat&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-%23326CE5.svg?style=flat&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Jenkins](https://img.shields.io/badge/Jenkins-%23D24939.svg?style=flat&logo=jenkins&logoColor=white)](https://www.jenkins.io/)
[![Helm](https://img.shields.io/badge/Helm-%23FF6C37.svg?style=flat&logo=helm&logoColor=white)](https://helm.sh/)

---

A complete Terraform-based automation to provision:
- VPC, networking and security groups
- EKS cluster and managed node groups (or Fargate profile)
- IAM roles and policies
- ECR repositories (optional)
- Helm release for Jenkins (configured for running builds on Kubernetes agents)
- Basic Jenkins configuration seeding (credentials, plugins, jobs) via configuration-as-code or init containers

This repository aims to convert manual, error-prone steps into a single reproducible workflow so teams can focus on delivering software — not maintaining infrastructure.

Table of contents
- Overview
- Architecture
- Prerequisites
- Quickstart (full automated flow)
- Useful commands & Terraform variables
- Jenkins setup & pipeline examples
- Destroy / clean up
- Time-savings estimate
- Cost considerations
- Troubleshooting
- Contributing & License

---

Overview
--------
This project provisions an entire CI/CD platform (Jenkins) on AWS EKS using Terraform and Helm. The goal is:
- Reproducibility: one set of Terraform files that create identical environments
- Speed: deploy end-to-end CI/CD infrastructure quickly
- Maintainability: manage infra in code and track changes in Git
- Best practices: least-privilege IAM, isolated network, secure secrets (recommend using SSM/Secrets Manager)

Architecture
------------
ASCII diagram (high-level):

<!--
Animated single-slide architecture for Terraform Jenkins on EKS.
Open this file in any modern browser (Chrome/Firefox) to see the animation.
-->
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="520" viewBox="0 0 1200 520" style="font-family:Inter, Arial, sans-serif">
  <defs>
    <linearGradient id="grad" x1="0" x2="1">
      <stop offset="0%" stop-color="#00c6ff"/>
      <stop offset="100%" stop-color="#0072ff"/>
    </linearGradient>
    <style>
      .card { fill: #0f1724; stroke: #1f2937; stroke-width:2; rx:14; ry:14; filter: drop-shadow(0 6px 10px rgba(2,6,23,0.35)); }
      .title { fill:#fff; font-weight:700; font-size:16px; }
      .sub { fill:#cbd5e1; font-size:12px; }
      .glow { stroke: url(#grad); stroke-width:3; stroke-linecap:round; stroke-linejoin:round; fill:none; opacity:0.95; }
      .dot { fill: #ffdd57; filter: drop-shadow(0 2px 6px rgba(255,200,50,0.4)); }
      .pulse { transform-origin:center; animation: pulse 1.8s infinite; }
      @keyframes pulse {
        0% { transform: scale(1); opacity:1 }
        50% { transform: scale(1.08); opacity:0.75 }
        100% { transform: scale(1); opacity:1 }
      }
      .arrow { stroke:#9ca3af; stroke-width:2; fill:none; stroke-linecap:round; stroke-linejoin:round; opacity:0.9; }
      .label { fill:#e6eef8; font-size:11px; }
      .emoji { font-size:28px; }
    </style>
  </defs>

  <!-- Background -->
  <rect width="1200" height="520" fill="#071128"/>

  <!-- Developer -->
  <g transform="translate(40,60)">
    <rect class="card" width="220" height="120"></rect>
    <text class="emoji" x="16" y="40">👩‍💻</text>
    <text class="title" x="68" y="40">Developer</text>
    <text class="sub" x="68" y="66">Pushes code / triggers CI</text>
    <circle cx="188" cy="60" r="10" class="dot pulse"/>
  </g>

  <!-- Git / Repo -->
  <g transform="translate(300,40)">
    <rect class="card" width="200" height="80"></rect>
    <text class="emoji" x="16" y="36">🗂️</text>
    <text class="title" x="60" y="36">Git Repo</text>
    <text class="sub" x="60" y="58">IaC + Jenkinsfile</text>
  </g>

  <!-- arrow Developer -> Git -->
  <path d="M260 120 C 280 100, 290 90, 300 80" class="arrow" marker-end="url(#none)"/>
  <path id="path-dev-git" d="M260 120 C 280 100, 290 90, 300 80" stroke="transparent" fill="none"/>

  <!-- Jenkins Master on EKS -->
  <g transform="translate(520,30)">
    <rect class="card" width="300" height="130"></rect>
    <text class="emoji" x="18" y="44">⚙️</text>
    <text class="title" x="60" y="44">Jenkins (Helm)</text>
    <text class="sub" x="60" y="68">Master on EKS — seeds jobs, triggers pipelines</text>

    <!-- small cloud label -->
    <rect x="68" y="80" width="110" height="30" rx="8" ry="8" fill="#07263a" stroke="#134a6a"/>
    <text class="label" x="80" y="100">CI Orchestration</text>
    <circle cx="280" cy="64" r="9" class="dot"/>
  </g>

  <!-- arrow Git -> Jenkins -->
  <path d="M500 80 C 520 60, 540 52, 520 60" class="arrow"/>
  <path id="path-git-jenkins" d="M500 80 C 520 60, 540 52, 520 60" stroke="transparent" fill="none"/>

  <!-- EKS Cluster -->
  <g transform="translate(470,200)">
    <rect class="card" width="420" height="220"></rect>
    <text class="title" x="20" y="38" fill="#fff">Amazon EKS Cluster</text>
    <text class="sub" x="20" y="56">Kubernetes-managed build agents & workloads</text>

    <!-- Agents / Pods -->
    <g transform="translate(30,80)">
      <rect x="0" y="0" width="120" height="100" rx="10" ry="10" fill="#05172b" stroke="#0b3a59"/>
      <text class="sub" x="12" y="18">K8s Agents</text>
      <g transform="translate(10,32)">
        <circle cx="14" cy="10" r="10" fill="#22c55e" />
        <circle cx="44" cy="10" r="10" fill="#60a5fa" />
        <circle cx="74" cy="10" r="10" fill="#f97316" />
      </g>
    </g>

    <!-- Jenkins Helm Release block -->
    <g transform="translate(170,80)">
      <rect x="0" y="0" width="220" height="100" rx="10" ry="10" fill="#061427" stroke="#0b3760"/>
      <text class="sub" x="10" y="18">Helm Release</text>
      <text class="label" x="10" y="40">jenkins (namespace: jenkins)</text>
      <g transform="translate(10,52)">
        <rect width="28" height="20" rx="4" fill="#a78bfa"/>
        <rect x="36" width="28" height="20" rx="4" fill="#7dd3fc"/>
        <rect x="72" width="28" height="20" rx="4" fill="#fca5a5"/>
      </g>
    </g>
  </g>

  <!-- ECR / S3 -->
  <g transform="translate(940,60)">
    <rect class="card" width="200" height="120"></rect>
    <text class="emoji" x="18" y="38">🧰</text>
    <text class="title" x="60" y="38">ECR / S3</text>
    <text class="sub" x="60" y="64">Artifact & image storage</text>
    <circle cx="170" cy="70" r="8" class="dot pulse"/>
  </g>

  <!-- arrow Jenkins -> EKS (trigger agents) -->
  <path id="path-jenkins-eks" d="M670 150 C 720 180, 760 200, 780 230" class="arrow"/>
  <!-- arrow EKS -> ECR -->
  <path id="path-eks-ecr" d="M880 260 C 920 240, 930 200, 940 180" class="arrow"/>

  <!-- Moving dot along flow to show CI pipeline -->
  <circle r="8" class="dot">
    <animateMotion dur="3s" repeatCount="indefinite" path="M260 120 C 280 100, 290 90, 300 80 L 420 70 C 460 60, 500 60, 520 60 C 560 70, 600 85, 620 90 C 640 95, 680 120, 720 150 C 760 180, 820 210, 880 240" />
  </circle>

  <!-- footer notes -->
  <text class="sub" x="30" y="500">Architecture: Code (Git) → Jenkins (Helm on EKS) → K8s Agents → ECR/S3 (artifacts). Animated flow shows a typical CI run (build → push → deploy).</text>

  <!-- subtle animated glow around EKS cluster -->
  <g transform="translate(460,195)">
    <rect x="-6" y="-6" width="432" height="232" rx="18" ry="18" fill="none" stroke="url(#grad)" class="glow" style="opacity:0.18">
      <animate attributeName="opacity" values="0.18;0.05;0.18" dur="3.6s" repeatCount="indefinite"/>
    </rect>
  </g>
</svg>

```
                       ┌────────────┐
                       │   Developer│
                       └──────┬─────┘
                              │
                              │ git push / trigger
                              ▼
                      ┌─────────────────┐
                      │   Jenkins Master│
                      │  (Helm on EKS)  │
                      └─────┬──────┬────┘
                            │      │
            ┌───────────────┘      └───────────────┐
            │                                      │
     ┌────────────┐                         ┌────────────┐
     │K8s Agents / │                         │  ECR / S3  │
     │ Kubernetes  │                         │  Artifact  │
     │  pods       │                         │  Storage   │
     └────────────┘                         └────────────┘
            │
            ▼
      Build -> Test -> Push -> Deploy -> EKS
```

Prerequisites
-------------
- AWS account with permission to create: VPC, EKS, IAM, EC2, ECR, S3 (for remote state), CloudWatch
- Local:
  - Terraform v1.2+ (matching provider requirements in repo)
  - AWS CLI configured (aws configure)
  - kubectl
  - helm
  - jq (optional, for quick JSON handling)
  - A Git client
- Optional but recommended:
  - An S3 bucket + DynamoDB table for Terraform remote state locking
  - AWS IAM user / role for automation with programmatic keys
  - Docker (for local image builds)

Quickstart — deploy everything (recommended)
-------------------------------------------
1. Clone the repo
```bash
git clone https://github.com/AnirbanB13/terraform-jenkins-eks-cicd.git
cd terraform-jenkins-eks-cicd
```

2. Configure AWS credentials and variables
```bash
export AWS_PROFILE=your-aws-profile
export AWS_REGION=us-east-1
# Optional overrides:
export TF_VAR_cluster_name=my-jenkins-eks
export TF_VAR_admin_email=you@example.com
```

3. (Optional) Configure remote state (S3 + DynamoDB). Example backend config:
- Create S3 bucket for state and DynamoDB table for locks, then update backend config or set backend variables.

4. Initialize Terraform
```bash
terraform init -backend-config="bucket=your-terraform-state-bucket" \
               -backend-config="key=jenkins-eks/terraform.tfstate" \
               -backend-config="region=${AWS_REGION}"
```

5. Validate and plan
```bash
terraform validate
terraform plan -out=tfplan
```

6. Apply (this provisions infra + Jenkins via Helm)
```bash
terraform apply "tfplan"
# or
terraform apply -auto-approve
```

7. Wait for outputs and retrieve Jenkins URL & initial admin password
```bash
terraform output -json
# Example output keys: jenkins_url, kubeconfig, cluster_name
```
Then
```bash
kubectl get svc --namespace jenkins
# or open the jenkins_url in your browser
```

Estimated runtime for full automated deployment:
- Terraform provisioning (VPC, EKS, IAM): 10–30 minutes (typical, depending on region and node provisioning)
- EKS node readiness + Helm install for Jenkins: 5–20 minutes
- Jenkins initialization & plugin install: 2–15 minutes
Total: roughly 20–65 minutes end-to-end (varies by AWS region, selected instance types, and network speed).

Useful Terraform variables & common settings
-------------------------------------------
- TF_VAR_cluster_name — name of the EKS cluster
- TF_VAR_region — AWS region
- TF_VAR_node_group_instance_types — e.g., ["t3.medium"]
- TF_VAR_desired_capacity, min_size, max_size — node group scaling
- TF_VAR_jenkins_helm_values — path to a helm values.yaml (if exposed)

Example override via var file (dev.tfvars):
```hcl
cluster_name = "my-jenkins-eks"
region = "us-east-1"
node_instance_types = ["t3.medium"]
jenkins_admin_user = "admin"
jenkins_admin_password = "ChangeMe123!"
```

Then:
```bash
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

Jenkins setup and best practices
-------------------------------
- This repo deploys Jenkins via Helm to the EKS cluster. The Helm chart can be configured using a values YAML file (plugins list, admin user, ingress, persistence).
- Recommended Jenkins configuration:
  - Use Kubernetes plugin to spawn ephemeral agents
  - Store secrets in AWS Secrets Manager or Kubernetes Secrets encrypted
  - Use Jenkins Configuration as Code (JCasC) to seed jobs and plugins automatically
  - Integrate with ECR / Docker registry credentials and set up service accounts

Destroy / clean up
------------------
To remove everything provisioned by Terraform:
```bash
terraform destroy -auto-approve
```
Make sure you have the correct Terraform workspace and remote state configured — destroying will remove infra and possibly data in ECR / persistent volumes.

Time-savings estimate (Manual vs IaC)
-------------------------------------
The intent of this section is to give a practical sense of time saved by using this repository versus manual setup.

Estimated manual time (typical experienced engineer):
- Networking + VPC: 1–2 hours
- EKS cluster (console/eksctl) + nodegroups + IAM roles: 1–3 hours (including troubleshooting)
- Configure Jenkins cluster (helm/chart, ingress, persistent volumes): 1–2 hours
- Jenkins admin config, plugin installs, agent config, ECR credential setup: 1–3 hours
Total manual: 4–10 hours (could be longer for teams unfamiliar with EKS/Jenkins)

Automated (this IaC repo):
- Prepare variables, state, credentials: 10–30 minutes
- Run terraform & helm to provision + Jenkins bootstrap: 20–65 minutes
Total automated: 30–95 minutes

Conservative time saved: 3–9 hours per environment bootstrap.
In many cases, repeated provisioning (staging/qa/prod per team) multiplies savings. If you do this repeatedly (or recover after incidents), IaC saves both time and error risk.

Cost considerations
-------------------
- Running EKS node groups and Jenkins workers costs EC2 instance-hours. Use spot instances for build agents to reduce cost.
- Always review persistent storage (EBS/PV) and load balancer costs.
- Terraform state S3 and DynamoDB have minimal costs; ECR storage is billed.
- Tip: During development, choose smaller instance types (t3.small/medium) or use Fargate to minimize cost.

Troubleshooting & FAQ
---------------------
- Jenkins pods not scheduling? Check node taints/tolerations, resource requests, and node group capacity.
- Helm release failing? Run `helm status <release> -n jenkins` and check `kubectl logs` for the pods.
- Terraform Apply hangs on EKS node creation? Node provisioning in certain regions can take longer; check EC2 quotas and AZ capacity.
- Need to rotate Jenkins admin password? Prefer JCasC or Secret Manager integration; avoid committing plain text credentials.

Contributing
------------
Contributions, suggestions, and improvements are welcome!
- Open an issue if you hit a problem or want a feature
- Fork the repo and open a pull request for fixes or enhancements
- Follow repository conventions and include tests where applicable

License
-------
This repository is provided under the MIT License. See LICENSE for details.