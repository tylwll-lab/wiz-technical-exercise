# creates the eks cluster using the terraform eks module
module "eks" {
  source             = "terraform-aws-modules/eks/aws"
  version            = "~> 21.0"
  name               = var.cluster_name
  kubernetes_version = "1.31"
# allows EKS API endpoint reachable from the internet, makes it to where I can run kubectl commands at home and interact with the cluster in EKS.
# This allows us to update our local kubeconfig with the correct eks api endpoint url.
  endpoint_public_access = true
# grants my wiz user odl_user_xyz eks cluster admin rights, found this may not be the default natively.
  enable_cluster_creator_admin_permissions = true

  compute_config = {
      enabled    = true
      node_pools = ["general-purpose"]
    }

# pulls the vpc id and subnet ids from the vpc module in vpc.tf
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
# metadata for aws dashboard - i can see cost basis by environments if needed.
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

