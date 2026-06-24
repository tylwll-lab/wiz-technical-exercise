# Creates the s3 bucket resource to house our mongo backups.
resource "aws_s3_bucket" "mongo_backups" {
  bucket = "wiz-mongo-backups-tyler"
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# AWS blocks access by default to all S3 buckets that are created as a safety precaution.
# I turned off all 4 parameters to make the bucket fully accessible. I believe this satifies the requirement of the bucket needing read/write from the internet.
# Anyone with aws plugin installed can run: 
# aws s3 ls s3://wiz-mongo-backups-tyler/ --no-sign-request.
# aws s3 ls s3://wiz-mongo-backups-tyler/go-mongodb/ --no-sign-request
# 
# Output:
# 2026-06-23 22:00:48        128 user.bson
# 2026-06-23 22:00:48        171 user.metadata.json

 
resource "aws_s3_bucket_public_access_block" "mongo_backups" {
  bucket                  = aws_s3_bucket.mongo_backups.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# We create a policy for the bucket, and pass a policy statement encoded in json to obtain read/write privileges to EVERYONE (Intentional misconfiguration).
# We allow everyone because principal is set to the wildcard "*".

resource "aws_s3_bucket_policy" "mongo_backups" {
  bucket = aws_s3_bucket.mongo_backups.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject", "s3:ListBucket"]
      Resource  = [
        aws_s3_bucket.mongo_backups.arn,
        "${aws_s3_bucket.mongo_backups.arn}/*"
      ]
    }]
  })
# Added this line because I was getting terraform failures because this wasn't finished yet.
# This says "Before the policy is applied, the public access block must be finished. the second block was completing after the policy applied.
# depends_on fixed this.

  depends_on = [aws_s3_bucket_public_access_block.mongo_backups]
}
