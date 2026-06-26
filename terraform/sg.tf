# security group rule so our load balancer can communicate to the kubernetes node
# references EKS module outputs instead of hardcoded IDs so it works after destroy
resource "aws_security_group_rule" "alb_to_nodes" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = module.eks.node_security_group_id # EKS node security group
  source_security_group_id = module.eks.cluster_security_group_id # EKS cluster security group
  description              = "Allow ALB to reach pods on port 8080"
}
# security group for the MongoDB EC2 instance
resource "aws_security_group" "mongo_sg" {
  name        = "wiz-mongo-sg"
  description = "MongoDB EC2 Security Group"
  vpc_id      = module.vpc.vpc_id
# allows traffic inbound from port 22, via tcp, to everything.
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
# allows traffic inbound from port 27017, required for mongo
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/26", "10.0.0.64/26"]
    description = "allow mongodb  access from eks private subnets"
  }
# allows all outbound traffic, need internet i can install packages and backup to S3
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
