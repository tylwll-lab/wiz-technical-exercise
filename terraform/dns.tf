# creates a private DNS zone only resolvable inside the vpc we created
# dns zone is just a configuration object in AWS
# name I chose for this is route53rocks.internal because it solved an annoying process.
resource "aws_route53_zone" "private" {
  name = "route53rocks.internal"
  vpc {
    vpc_id = module.vpc.vpc_id
  }
}
# dns record that maps    
resource "aws_route53_record" "mongodb" {
  # when the zone is created, aws generates a unique id automatically, we store it here
  zone_id = aws_route53_zone.private.zone_id
  # full record name for the env variable in wiz-app
  name = "mongodb.route53rocks.internal"
  # type A means ipv4 address
  type = "A"
  # TTL is a required field for DNS A records, gets a validation error without it.
  # DNS clients cache this for 60 seconds before re-checking, this can also affect Route53 as it costs per query (very minimal).
  ttl = 60
  # pulls the EC2 instance private ip from ec2.tf
  records = [module.ec2.private_ip]
}


