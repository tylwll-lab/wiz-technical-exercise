# creates an image repo for our images we build from the docker file in application code.
resource "aws_ecr_repository" "wiz_ecr" {
  name = "wiz-ecr-repo"
# mutable means we can update the images to latest with each image update instead of specific image versions each time.
  image_tag_mutability = "MUTABLE"
# allows terraform to delete the repo even if there are images inside. need it for ci/cd nuke workflow, probably not great in production. 
  force_delete = true
# ECR will scan the image for known vulnerabilities on push. This is seperate from Trivy on github actions.  
# https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning.html
  image_scanning_configuration {
    scan_on_push = true
  }
}
