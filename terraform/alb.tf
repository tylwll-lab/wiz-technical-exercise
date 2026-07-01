# installs the load balancer controller which then reads the ingress.yaml and creates the ALB on AWS.
resource "helm_release" "alb_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts" # official AWS EKS charts repo
  chart            = "aws-load-balancer-controller"
  namespace        = "kube-system" # install into kube-system namespace
  create_namespace = true
  values = [
    yamlencode({
# tells the controller which cluster it's managing
      clusterName = var.cluster_name 
      vpcId       = module.vpc.vpc_id
      serviceAccount = {
# create the service account automatically
        create = true
# name of the service account                           
        name   = "aws-load-balancer-controller"
        annotations = {
# links service account to IAM role via IRSA (iam.tf)
          "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
        }
      }
    })
  ]
# helm is installing the alb controller before IAM role and policy attachment
# wait for the IAM role and policy to be ready before installing, added this to prevent error
  depends_on = [aws_iam_role_policy_attachment.alb_controller]
}

# test comment
