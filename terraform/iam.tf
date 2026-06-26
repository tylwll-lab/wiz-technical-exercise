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
      # allow action below
      Effect = "Allow"
      Principal = {
        # the OIDC provider for our specific EKS cluster - uses module output so it works after destroy and rebuild
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
# attaches the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}
