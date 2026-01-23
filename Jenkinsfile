pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION = 'us-west-1'
        EKS_CLUSTER_NAME   = 'jenkins-eks-cluster'
    }
    stages {
        stage('Checkout SCM') {
            steps {
                script {
                    checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/AnirbanB13/terraform-jenkins-eks-cicd.git']])
                }
            }
        } 
        stage('Terraform Init') {
            steps {
                dir('EKS') {
                    sh 'terraform init'
                }
            }
        }
        stage('Formatting Terraform Code') {
            steps {
                dir('EKS') {
                    sh 'terraform fmt -check'
                }
            }
        }
        stage('Validate Terraform Code') {
            steps {
                dir('EKS') {
                    sh 'terraform validate'
                }
            }
        }
        stage('Preview the infra using terraform') {
            steps {
                dir('EKS') {    
                    sh 'terraform plan'
                }
                input (message: 'Do you want to proceed to apply the changes?', ok: 'Yes, Proceed')
            }
        }
        stage('Creating/destroying an EKS Cluster') {
            steps {
                dir('EKS') {
                    sh 'terraform $action -auto-approve'
                }
            }
        }
