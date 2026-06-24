# creates the iam role for the EC2 instance, encodes into json as that is how AWS receieves policy information.
# The role policy allows the ec2 instance to take the role of the aws_iam_role.
resource "aws_iam_role" "ec2_role" {
  name = "wiz-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}


#
# The next line attaches the EC2_admin role to administrator access policy. It is very dangerous.
# AdministratorAccess grants full access to every AWS service on the account from the EC2 instance.
# 169.254.169.254 is the AWS instance metadata service. It's an endpoint (HTTP) that lives inside every EC2 Instance.
# 
# DEMO on EC2:
# TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
# curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/wiz-ec2-role
#


resource "aws_iam_role_policy_attachment" "ec2_admin" {
  role = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# referenced in the ec2.tf, this is the instance profile needed to assume the role when the EC2 instance boots up.
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "wiz-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
