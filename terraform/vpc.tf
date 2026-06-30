# creates the VPC and its subnets
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "wiz-vpc"
  cidr   = "10.0.0.0/16"

  # EKS requires at least 2 AZs, or cluster creation fails
  azs = ["us-east-1a", "us-east-1b"]

  # auto-assigns public IPs to instances in public subnets
  # (SSH access itself is controlled separately, by security group rules)
  map_public_ip_on_launch = true

  public_subnets  = ["10.0.1.0/26", "10.0.1.64/26"]
  private_subnets = ["10.0.2.0/26", "10.0.2.64/26"]

  # lets resources in private subnets (EKS nodes) reach the internet
  enable_nat_gateway = true

  # tags subnets so the ALB controller knows where to place load balancers.
  # role/elb = internet-facing, role/internal-elb = internal only
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  # unused for now, here in case an internal load balancer is needed later
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# lets private subnet resources reach S3 directly, skipping the NAT gateway
# (used by the backup script's aws s3 cp call)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.us-east-1.s3"
}