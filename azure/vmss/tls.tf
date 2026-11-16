resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "private_key" {
  filename        = "${path.module}/azure-vm-key.pem"
  content         = tls_private_key.ssh.private_key_pem
  file_permission = "0600"
}

resource "local_file" "public_key" {
  filename        = "${path.module}/azure-vm-key.pub"
  content         = tls_private_key.ssh.public_key_openssh
  file_permission = "0644"
}

