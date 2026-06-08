# ==============================================================================
# LAB CD9 - EC2 Instance Configuration
# Khoi tao may chu ao, chay script bootstrap va dong bo hoa tien trinh
# ==============================================================================

resource "aws_instance" "minikube" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name
  subnet_id     = aws_subnet.public_a.id

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = templatefile("${path.module}/scripts/user_data.sh", {
    proxy_port = var.proxy_port
  })

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-minikube"
  })
}

# Dong bo hoa: Doi EC2 va Proxy san sang moi de Kubernetes Provider ket noi
resource "null_resource" "wait_for_minikube" {
  depends_on = [aws_instance.minikube]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
    host        = aws_instance.minikube.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      # B1: Doi cloud-init (toan bo user_data.sh) chay xong
      "echo 'Waiting for cloud-init to complete...'",
      "sudo cloud-init status --wait",

      # B2: Xac nhan Proxy da thuc su bat len (file flag duoc tao sau khi proxy up)
      "echo 'Checking if K8s API Proxy is up...'",
      "until curl -s http://localhost:${var.proxy_port}/api/v1/namespaces > /dev/null 2>&1; do echo 'Proxy not ready yet, retrying...'; sleep 5; done",
      "echo 'K8s API Proxy is ready on port ${var.proxy_port}!'",
    ]
  }
}