# terraform block for the configuration of terraform itself. "you need at least this version to run this code."
# Referenced when running terraform init, it downloads these.
terraform {
  required_version = ">= 1.15.6"
  # backs up our terraform state file to the s3 bucket used for mongo dumps so the ci/cd pipeline can know the state of the cluster.
  backend "s3" {
    bucket = "wiz-state-backups-tyler"
    key    = "terraform/state/terraform.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
  }
}

# configures the aws plugin, pulls the region variable from variables.tf
provider "aws" {
  region = var.aws_region
}

# Helm, which is the plugin/mechanism that deploys a kubernetes resource via helm charts, needs to be able to talk to the cluster so it can deploy the application loadbalancer on AWS. 
provider "helm" {
  kubernetes = {
    # host is the same EKS cluster endpoint I send my kubectl commands send to as well.
    host = module.eks.cluster_endpoint
    # Needs the cluster CA certificate so it can establish trust and verify it's talking to the right cluster. AWS returns certs in binary format, so we convert so it can check against it.
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)


    # I have the exec block here so we don't hardcode credentials. 
    # it runs this command when I issue terraform apply, which updates the AWS infra.
    # It runs | aws eks get-token --cluster-name wiz-cluster
    # With this method I don't have to worry about token expiry because it generates a new one everytime I terraform apply.

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", "wiz-cluster"]
      command     = "aws"
    }
  }
}
