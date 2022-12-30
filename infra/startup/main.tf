resource "null_resource" "install-driver" {
  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt upgrade -y",
      "sudo apt install nvidia-driver-525 -y",
      "pip install --upgrade git+https://github.com/huggingface/diffusers.git transformers accelerate scipy",
      "pip install flask-cors",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_privkey_location)
      host        = var.vm_public_ip
    }
  }
}