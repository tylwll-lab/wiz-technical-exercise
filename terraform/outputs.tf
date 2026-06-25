# outputs print important values to the terminal after terraform apply completes
# these are values that only exist after AWS creates the resources (IPs, URLs, ARNs etc)

# name of the EKS cluster - used to reference the cluster in kubectl and aws cli commands
output "eks_cluster_name" {
  value = module.eks.cluster_name
}

# EKS API endpoint URL - written to ~/.kube/config when running aws eks update-kubeconfig
# this is what kubectl sends commands to
output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

# public IP of the EC2 MongoDB instance, changes every time EC2 is destroyed and recreated
# used to SSH in and also to update the EC2 IP in deployment.yaml for the mongoDB environment variable.
output "ec2_public_ip" {
  value = module.ec2.public_ip
}

# S3 bucket name for MongoDB backups
output "s3_bucket_name" {
  value = aws_s3_bucket.mongo_backups.bucket
}

# S3 bucket ARN - used when referencing the bucket in IAM policies
output "s3_bucket_arn" {
  value = aws_s3_bucket.mongo_backups.arn
}

# VPC ID 
# Pulls from the VPC.tf
output "vpc_id" {
  value = module.vpc.vpc_id
}

# ECR repository URLs
# format: account_id.dkr.ecr.region.amazonaws.com/repo-name
# when ECR is created, it generates a repository URL to reach it. format line above is how it appears. You don't know this until the resource is created.
output "ecr_repository_url" {
  value = aws_ecr_repository.wiz_ecr.repository_url
}

# hardcoded this to make connecting easier
output "alb_url" {
  value = "http://k8s-default-wizingre-867e94750f-545847822.us-east-1.elb.amazonaws.com"
}
