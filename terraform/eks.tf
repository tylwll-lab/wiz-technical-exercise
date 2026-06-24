# creates the eks cluster using the terraform eks module
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"
  name = "wiz-cluster"
  kubernetes_version = "1.31"
# allows EKS API endpoint reachable from the internet, makes it to where I can run kubectl commands at home and interact with the cluster in EKS.
# we can run | aws eks update-kubeconfig --region us-east-1 (region where our eks is located) --name wiz-cluster | This updates our local kubeconfig with the correct eks API endpoint URL. 
  endpoint_public_access = true
# grants my wiz user odl_user_xqz eks cluster admin rights, found this may not be the default natively. 
  enable_cluster_creator_admin_permissions = true

# turns on EKS auto-mode, which means we don't define EC2 instances traditionally with the eks_managed_node_groups command (specifying min,max size. instantce type 't3 medium' etc. Cost effecient as workload is on AWS to determine if a new instance is needed.
  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

# pulls the vpc id and subnet id's from the vpc module in vpc.tf
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
#metadata for aws dashboard - i can see cost basis by environments if needed.
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
