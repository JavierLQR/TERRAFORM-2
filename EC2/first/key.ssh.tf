resource "aws_key_pair" "deployer" {
  key_name   = "${var.server_name}.key"
  public_key = file("${var.server_name}.key.pub")
}
