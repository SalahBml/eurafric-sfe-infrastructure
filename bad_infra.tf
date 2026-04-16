# bad_infra.tf
resource "aws_security_group" "terrible_idea_sg" {
  name        = "allow_all_ssh"
  description = "Allow SSH from anywhere in the world"

  ingress {
    description = "SSH from internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # This is the vulnerability!
  }
}
