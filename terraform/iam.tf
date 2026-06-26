# IAM policy that defines what AWS permissions the load balancer controller needs
resource "aws_iam_policy" "alb_controller" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("iam_policy.json") # reads the official policy JSON from the terraform directory
}
# IAM role that the load balancer controller pod gets with IRSA
resource "aws_iam_role" "alb_controller" {
  name = "AmazonEKSLoadBalancerControllerRole"
# trust policy allows the OIDC provider to exchange kubernetes tokens for AWS credentials
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
# federated = trust is coming from an external identifty provider rather than an IAM user. 
# the EKS cluster has a mechanism called OpenID Connect (OIDC), which allows non IAM users to make changes. This establishes that link.
        Federated = module.eks.oidc_provider_arn
      }
# allows kubernetes service accounts to assume this role via web identity
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
# only the aws-load-balancer-controller service account in kube-system can assume this role
          "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}
# attaches the IAM policy to the IAM role for the ALB controller
resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}
# creates the iam role for the EC2 instance, aws takes policy info from json
# the trust policy allows the EC2 service to assume this role on boot
resource "aws_iam_role" "ec2_role" {
  name = "wiz-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}
#
# The next line attaches the EC2_admin role to administrator access policy. It is very dangerous.
# AdministratorAccess grants full access to every AWS service on the account from the EC2 instance.
# 169.254.169.254 is the AWS instance metadata service. It's an endpoint (HTTP) that lives inside every EC2 Instance.
# It allows processes running on the EC2 instance to retrieve temporary credentials for the IAM role attached to the instance.
#
# DEMO on EC2:
# TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
# curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/wiz-ec2-role
#
resource "aws_iam_role_policy_attachment" "ec2_admin" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
# referenced in the ec2.tf, this is the instance profile needed to assume the role when the EC2 instance boots up.
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "wiz-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
