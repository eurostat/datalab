terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.16.0"
    }
  }

  backend "s3" {}
  required_version = ">= 0.14.9"
}

provider "aws" {
  region  = "${var.AWS_REGION}"
}

data "aws_caller_identity" "current" {}
data "aws_ecr_authorization_token" "token" {}

provider "docker" {
  host = "${var.DOCKER_HOST}"
  registry_auth {
    address  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.AWS_REGION}.amazonaws.com"
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}

resource "aws_ecr_repository" "repository" {
  count = var.USE_ECR ? length(var.DOCKER_IMAGES_LIST) : 0
  name = "${var.DOCKER_IMAGES_LIST[count.index]}"
}

resource "docker_image" "image" {
  count = length(var.DOCKER_IMAGES_LIST)
  name = var.USE_ECR ? "${aws_ecr_repository.repository[count.index].repository_url}:latest" : "${var.DOCKER_USERNAME}/${var.DOCKER_IMAGES_LIST[count.index]}"
  build {
    path = "../../images/${var.DOCKER_IMAGES_LIST[count.index]}"
  }
  keep_locally = false
}

resource "null_resource" "push_images" {
  count = var.USE_ECR ? 0 : length(var.DOCKER_IMAGES_LIST)
  provisioner "local-exec" {
    command = "docker login -u ${var.DOCKER_USERNAME} -p ${var.DOCKER_PASSWORD} | docker push ${var.DOCKER_USERNAME}/${var.DOCKER_IMAGES_LIST[count.index]}"
    #interpreter = ["PowerShell", "-Command"]
  }
  depends_on = [docker_image.image]
}


resource "docker_registry_image" "registry" {
  count = var.USE_ECR ? length(var.DOCKER_IMAGES_LIST) : 0
  name = "${aws_ecr_repository.repository[count.index].repository_url}:latest"
  depends_on = [docker_image.image] 
}

locals{
  datalab_values_1  = replace("${file("${var.PATH_TO_DATALAB_VALUES}")}", "# placeHolder1", var.USE_ECR ? "${aws_ecr_repository.repository[0].repository_url}:latest" : "${var.DOCKER_USERNAME}/${var.DOCKER_IMAGES_LIST[0]}:latest")
  datalab_values_2 = replace("${local.datalab_values_1}", "# placeHolder2", var.USE_ECR ? "${aws_ecr_repository.repository[1].repository_url}:latest" : "${var.DOCKER_USERNAME}/${var.DOCKER_IMAGES_LIST[1]}:latest")
  datalab_values_3_1 = replace("${local.datalab_values_2}", "# placeHolder3.1", var.USE_ECR ? "${aws_ecr_repository.repository[2].repository_url}" : "${var.DOCKER_USERNAME}/${var.DOCKER_IMAGES_LIST[2]}")
  datalab_values_3_2 = replace("${local.datalab_values_3_1}", "# placeHolder3.2", "latest")
}


resource "local_file" "datalab_values" {
    content  = local.datalab_values_3_2
    filename = "${var.PATH_TO_DATALAB_VALUES}"
}
