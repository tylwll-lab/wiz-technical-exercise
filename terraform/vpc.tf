# Creates the vpc resource in AWS 
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "wiz-vpc"
  # assigns the 10.0.0.0/16 range to the entire VPC. 65K addresses (probably too large)
  cidr = "10.0.0.0/24"
  # This will auto-assign public IP's to instances launched in public subnets defined below. This allows me to SSH into it from my local PC.
  map_public_ip_on_launch = true
  # Defines the availaility zones in which the VPC spans.
  azs = ["us-east-1a", "us-east-1b"]
  # Creating private/public subnets.
  private_subnets = ["10.0.0.0/26", "10.0.0.64/26"]
  public_subnets  = ["10.0.0.128/26", "10.0.0.192/26"]

  # enables a nat gateway so that the resources inside the cluster can communicate to the internet.
  enable_nat_gateway = true


  # Required tags for the AWS load balancer controller (deployed via helm)

  # Tells EKS which subnets to place internal load balancers in
  # /role/internal-elb and /role/elb is a specific key name that says this subnets plays the role of an ELB subnet either internal or internet facing.

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  # Tells EKS which subnets to place the internet facing load balancers in
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

