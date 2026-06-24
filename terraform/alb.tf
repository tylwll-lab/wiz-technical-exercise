# IAM policy that defines what AWS permissions the load balancer controller needs needs
resource "aws_iam_policy" "alb_controller" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("iam_policy.json")  # reads the official policy JSON from the terraform directory
}

# IAM role that the load balancer controller pod gets with IRSA (IAM Roles for Service Accounts)
resource "aws_iam_role" "alb_controller" {
  name = "AmazonEKSLoadBalancerControllerRole"

  # trust policy allows the OIDC provider to exchange kubernetes tokens for AWS credentials
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
     # allow action below
      Effect = "Allow" 
      Principal = {
        # the OIDC provider for our specific EKS cluster
        Federated = "arn:aws:iam::795176247566:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/7D3027EED7356AD5E64791F29AE2C833"
      }
      # allows kubernetes service accounts to assume this role via web identity
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          # only the aws-load-balancer-controller service account in kube-system can assume this role
          "oidc.eks.us-east-1.amazonaws.com/id/7D3027EED7356AD5E64791F29AE2C833:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

# security group rule so our load balancer can communicate to the kubernetes node
resource "aws_security_group_rule" "alb_to_nodes" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = "sg-08a43349d160a2926"
  source_security_group_id = "sg-005847eb84c40f5bf"
  description              = "Allow ALB to reach pods on port 8080"
}

# attaches the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

# installs the load balancer controller intro helm -> which then reads the ingress.yaml and creates the ALB on AWS.
resource "helm_release" "alb_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"  # official AWS EKS charts repo
  chart            = "aws-load-balancer-controller"
  namespace        = "kube-system"  # install into kube-system namespace
  create_namespace = true

  values = [
    yamlencode({
      clusterName = "wiz-cluster"  # tells the controller which cluster it's managing
      vpcId = module.vpc.vpc_id
      serviceAccount = {
        create = true  # create the service account automatically
        name   = "aws-load-balancer-controller"  # name of the service account
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn  # links service account to IAM role via IRSA
        }
      }
    })
  ]

  # wait for the IAM role and policy to be ready before installing, added this to prevent error
  depends_on = [aws_iam_role_policy_attachment.alb_controller]
}
