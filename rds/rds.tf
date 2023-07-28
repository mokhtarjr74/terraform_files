resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "my_db_subnet_group"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "rds_sg" {
  name        = "rds_security_group"
  description = "RDS security group"
  vpc_id      = var.vpc_id


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}
}

resource "aws_security_group_rule" "inbound_traffic" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  security_group_id = aws_security_group.rds_sg.id
  source_security_group_id = var.sg_id
}

resource "aws_db_instance" "db" {
  depends_on = [ var.subnet_ids, var.sg_id, var.vpc_id]
  allocated_storage    = 20
  identifier           = "mydb"
  engine               = "postgres"
  engine_version       = "14.8"
  instance_class       = "db.t3.micro"
  username             = "test"
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  port                 = 3306
  publicly_accessible = false
}

output "rds_db_host" {
  value = aws_db_instance.db.address
}
output "rds_db_username" {
  value = aws_db_instance.db.username
}
