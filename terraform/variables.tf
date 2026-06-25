# These are configurable inputs referenced by terraform.
# This offers a mechanism of "change here, change everywhere."

# AWS Region where all the resources are deployed:
variable "aws_region" {
  description = "aws region that application is hosted"
  type        = string
  default     = "us-east-1"
}

# Project name label, it's not actively referenced in my terraform files.
variable "project_name" {
  description = "name of the wiz project"
  type        = string
  default     = "wiz-technical-exercise"
}

# EC2 instance size, referenced in ec2.tf as var.ec2_instance_type.
variable "ec2_instance_type" {
  description = "ec2 compute instance type on AWS"
  type        = string
  default     = "t3.micro"
}

# This is currently just an empty string and unused.
# the MongoDB password is hardcoded into the environment variable of the EC2 instance.
# For improved security later on, there is a .tfvars file I could use. This would be in the terraform folder.
# I could set the mongodb credentials here, and then exclude the tfvars file from the github repo, so it couldn't be pulled.
# I could also use AWS Secrets Manager from my research, but this is for production level infra. 

variable "mdb_credentials" {
  description = "mongodb credentials"
  type        = string
  default     = ""
  sensitive   = true
}

# example of a better method:
#
# define the variables here in variables.tf but do not give a value (remove the default = xyz)
# create a .tfvars file, then have the password stored there - excluded from the github repo.
# 
# variables.tf:
#
# variable "mdb_credentials" {
#   type = string
#   sensitive = true
#
# terraform.tfvars:
#
# mdb_credentails = "xyz"
#
# i can access the variables locally and hide the hardcoded stuff in the repo.
