locals {
  instance_types = jsondecode(file("${path.module}/conf/instance_types.json")).instance_types
}
