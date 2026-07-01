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

  # changed from auto mode which wouldnt place the app pods in two separate private subnets, also added scheduling constraint in deployment.yaml.
  eks_managed_node_groups = {
    general = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 5
      desired_size   = 2
      subnet_ids     = module.vpc.private_subnets
    }
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

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = module.eks.cluster_name
  addon_name   = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = module.eks.cluster_name
  addon_name   = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on   = [aws_eks_addon.vpc_cni]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = module.eks.cluster_name
  addon_name   = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
}
