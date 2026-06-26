# create the ec2 module instance on aws
module "ec2" {
  source = "terraform-aws-modules/ec2-instance/aws"
  name   = "wiz-ec2-instance" #
# pulls out instance type from variables.tf which lists t3.micro
  instance_type = var.ec2_instance_type
  key_name = "tylwiz"
# control plane audit logging with CloudWatch
  monitoring = true
  subnet_id = module.vpc.public_subnets[0]
# amazon machine image, it is ubuntu 20.04 LTS from 2022. Requirement for outdated linux.
  ami = var.ami_id
# This gives the EC2 instance a public, and a private IP address. This is bad for a database server and I put this in on purpose.
  associate_public_ip_address = true
# Grabs the VPC SG ID's from the aws_security_group defined below this block. This controls inbound/outbound traffic.
  vpc_security_group_ids = [aws_security_group.mongo_sg.id]
# attaches overly permissive IAM role to the EC2 instance. EC2 checks for a instance profile on boot, not IAM role - EC2 quirk. Instance profile is the same thing.
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
# gives the user data script, and if it changes - destroy and rebuild the EC2 instance.
  user_data                   = file("userdata.sh")
  user_data_replace_on_change = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
