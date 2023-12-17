resource "tls_private_key" "private_key" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "key_pair" {
  key_name   = "terraKey"
  public_key = tls_private_key.private_key.public_key_openssh
}

output "private_key" {
  value     = tls_private_key.private_key.private_key_openssh
  sensitive = true
}
