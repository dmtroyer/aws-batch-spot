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

resource "aws_launch_template" "launch_template" {
  name = "${terraform.workspace}-launch-template"
  key_name = aws_key_pair.key_pair.key_name

  # The EBS volume to attach to the instance.
  block_device_mappings {
    device_name = "/dev/sdb"
    ebs {
      volume_size = 100
      volume_type = "gp3"
      iops = 10000
      throughput = 500
    }
  }

  update_default_version = true
  user_data = filebase64("${path.module}/conf/user_data.multipart")
}

# The AWS Batch compute environment for the spot instances to live in.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/batch_compute_environment
resource "aws_batch_compute_environment" "compute_environment" {
  compute_environment_name = "${terraform.workspace}-compute-environment"
  type = "MANAGED"

  compute_resources {
    type = "SPOT"
    bid_percentage = 80
    # type = "EC2"

    # Roles
    spot_iam_fleet_role = aws_iam_role.ec2_spot_fleet_tagging_role.arn
    instance_role       = aws_iam_instance_profile.ecs_instance_role.arn

    # Compute resources
    instance_type = local.instance_types
    desired_vcpus = 32
    max_vcpus     = 32
    min_vcpus = 0
    launch_template {
      launch_template_id = aws_launch_template.launch_template.id
      version = aws_launch_template.launch_template.latest_version
    }

    # Networking
    security_group_ids = [aws_security_group.security_group.id]
    subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id, aws_subnet.public_subnet_c.id]
  }
}

