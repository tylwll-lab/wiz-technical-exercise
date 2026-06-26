# Creates the vpc resource in AWS 
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "wiz-vpc"
# assigns the 10.0.0.0/24 range to the entire VPC. 256 addresses (251 usable, 5 for aws)
  cidr = "10.0.0.0/24"
# Defines the availaility zones in which the VPC spans EKS requires 2 or failure
  azs = ["us-east-1a", "us-east-1b"]
# This will auto-assign public IP's to instances launched in public_subnets defined below
# Needed to inherently create EC2 SSH access
  map_public_ip_on_launch = true
# Creating private/public subnets
  private_subnets = ["10.0.0.0/26", "10.0.0.64/26"]
  public_subnets  = ["10.0.0.128/26", "10.0.0.192/26"]

# enables a nat gateway so that the resources inside private subnet (eks) can get to internet.
  enable_nat_gateway = true


# Required tags for the AWS load balancer controller to know which subnets to provision load balancers into.
# alb.ingress.kubernetes.io/scheme: internet-facing | annotation in ingress.yaml that triggers alb-controller-manager to look for subnets tagged with kubernetes.io/role/elb = 1 when placing the ALB.
# /role/elb = internet facing, /role/internal-elb = internal only
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
# not currently used, but tagged as best practice in case an internal load balancer is needed later
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

