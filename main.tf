locals {
  resource_prefix = "ky-tf"
  ip_range_all = "0.0.0.0/0"
}

########## AWS IAM RESOURCES ##################

resource "aws_iam_role" "ec2_role" {
  name = "${local.resource_prefix}_ec2_rds_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Terraform = "true"
  }
}

resource "aws_iam_policy" "ec2_rds_secrets_policy" {
  name   = "${local.resource_prefix}-rds-secretsmanager_access_policy"
  description = "Policy for EC2 to access RDS and Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "rds-db:connect"  # Access RDS databases using IAM auth
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_rds_secrets_policy.arn
}

resource "aws_iam_instance_profile" "read_profile" {
  name = "${local.resource_prefix}-RDS-read-role"
  role = aws_iam_role.ec2_role.name
}

########## AWS SECRET MANAGER RESOURCES #####################

resource "aws_secretsmanager_secret" "rds_secret" {
  name = "${local.resource_prefix}_rds_secret"
  description = "RDS Credentials for application"
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    username = var.username
    password = var.password
  })
}

############# AWS SECURITY GROUP RESOURCES ##############

resource "aws_security_group" "rds-sg" {
  name        = "${local.resource_prefix}-RDS-SG"
  description = "Security Group created for DRDS read"
  vpc_id      = data.aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allowrdsport" {
  security_group_id = aws_security_group.rds-sg.id

  cidr_ipv4   = local.ip_range_all
  from_port   = 3306
  ip_protocol = "tcp"
  to_port     = 3306
}

resource "aws_vpc_security_group_ingress_rule" "allowssh" {
  security_group_id = aws_security_group.rds-sg.id

  cidr_ipv4   = local.ip_range_all
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_vpc_security_group_egress_rule" "outgoing" {
  security_group_id = aws_security_group.rds-sg.id

  cidr_ipv4   = local.ip_range_all
  from_port   = -1
  ip_protocol = "-1"
  to_port     = -1
}

############### RDS DATABASE RESOURCES ###################

resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "rds_subnet_group"
  subnet_ids  = [var.private_subnet, var.private_subnet2]
  description = "Subnet group for RDS instance"

  tags = {
    Name = "${local.resource_prefix}-RDS Subnet Group"
  }
}

resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  storage_type         = "gp2"
  db_name              = "mydb"
  identifier           = "${local.resource_prefix}-database"
  engine               = "mysql"   
  engine_version       = "8.0.40"  # Engine version
  instance_class       = "db.t3.micro"  # Instance type
  skip_final_snapshot  = true

  username = jsondecode(aws_secretsmanager_secret_version.rds_secret_version.secret_string)["username"]
  password = jsondecode(aws_secretsmanager_secret_version.rds_secret_version.secret_string)["password"]

  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  publicly_accessible = false
  vpc_security_group_ids = [ aws_security_group.rds-sg.id ]

  tags = {
    Name = "${local.resource_prefix}-RDS-database"
  }
}

########### EC2 READ RESOURCES ##################

resource "aws_instance" "read" {
  ami                         = data.aws_ami.ami_linux.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnet.public_subnet.id
  associate_public_ip_address = true
  key_name                    = var.keypair
  vpc_security_group_ids      = [aws_security_group.rds-sg.id]
  iam_instance_profile        = aws_iam_instance_profile.read_profile.id

  tags = {
    Name = "${local.resource_prefix}-rds-reader"
  }
}