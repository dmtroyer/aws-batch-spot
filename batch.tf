# Profiles, roles, etc is out of control.check
# https://docs.aws.amazon.com/batch/latest/userguide/IAM_policies.html
data "aws_iam_policy_document" "ec2_spot_fleet_tagging_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["spotfleet.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ec2_spot_fleet_tagging_role" {
  name               = "ec2_spot_fleet_tagging_role"
  assume_role_policy = data.aws_iam_policy_document.ec2_spot_fleet_tagging_role.json
}

resource "aws_iam_role_policy_attachment" "ec2_spot_fleet_tagging_role" {
  role       = aws_iam_role.ec2_spot_fleet_tagging_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name               = "ecs_instance_role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_role" {
  name = "ecs_instance_role"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_batch_job_queue" "job_queue" {
  name     = "${terraform.workspace}-job-queue"
  state    = "ENABLED"
  priority = 1
  compute_environments = [
    aws_batch_compute_environment.compute_environment.arn
  ]
}

resource "aws_batch_job_definition" "job_definition" {
  name = "${terraform.workspace}-job-definition"
  type = "container"
  container_properties = file("${path.module}/conf/container_properties.json")
}

# The AWS Batch compute environment for the spot instances to live in.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/batch_compute_environment
resource "aws_batch_compute_environment" "compute_environment" {
  compute_environment_name = "${terraform.workspace}-compute-environment"

  compute_resources {
    spot_iam_fleet_role = aws_iam_role.ec2_spot_fleet_tagging_role.arn
    instance_role = aws_iam_instance_profile.ecs_instance_role.arn

    instance_type = local.instance_types

    desired_vcpus = 32
    max_vcpus = 64

    security_group_ids = [
      aws_security_group.security_group.id,
    ]

    subnets = [
      aws_subnet.public_subnet.id,
    ]

    type = "SPOT"
  }

  type = "MANAGED"
}

