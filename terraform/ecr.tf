# creates an aws elastic container registry reposiotry for our images we built from the Docker file in application code.
resource "aws_ecr_repository" "wiz_ecr" {
  name = "wiz-ecr-repo"
  # mutable means we can update the images to latest with each image update instead of specifical image versions each time.
  image_tag_mutability = "MUTABLE"
  # allows terraform to delete the repo even if there are images inside. probably not great for production.
  force_delete = true
  # ECR will scan the image for known vulnerabilities on push.  
  # https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning.html
  image_scanning_configuration {
    scan_on_push = true
  }
}
