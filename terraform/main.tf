provider "aws" {
  version                 = "~> 2.25"
  region                  = "us-east-1"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "ivoy-production"
}
provider "random" {
  version = "~> 2.2"
}
######################################
# Data sources to get VPC and subnets
######################################
data "aws_vpc" "default" {
  default = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${data.aws_vpc.default.id}"
}
module "subnets" {
  source              = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=master"
  namespace           = "evidences subnets"
  stage               = "${var.environment}"
  name                = "evidence-subnets"
  vpc_id              = "${data.aws_vpc.default.id}"
  igw_id              = "${aws_internet_gateway.igw.id}"
  cidr_block          = "10.0.0.0/16"
  availability_zones  = ["us-east-1a","us-east-1b"]
}

#############
# RDS Aurora
#############
module "aurora" {
  source                              = "terraform-aws-modules/rds-aurora/aws"
  version                             = "~> 2.0"
  name                                = "evidences-database"
  engine                              = "aurora"  
  subnets                             = module.subnets.public_subnet_ids
  vpc_id                              = "${data.aws_vpc.default.id}"
  replica_count                       = 1
  instance_type                       = "db.t3.medium"
  apply_immediately                   = true
  skip_final_snapshot                 = true
  publicly_accessible                 = true
  tags = {
    Service     = "${var.serviceName}"
    Environment = "${var.environment}"
    Terraform   = "true"
  }
}

module "evidence_service_sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/mysql"
  version = "~> 3.0"

  name        = "evidences-service"
  description = "Security group for evidences-service with custom ports open within VPC"
  vpc_id = "${data.aws_vpc.default.id}"

  ingress_cidr_blocks = ["10.10.0.0/26"]
}

#############
# EC2
#############

resource "aws_security_group" "ec2-sg" {
  name        = "ec2-evidences-security-group"
  description = "evidences security-group"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    protocol    = "tcp"
    from_port   = var.input_sg_port
    to_port     = var.input_sg_port
    cidr_blocks = ["10.0.0.0/26"]
  }

  egress {
    protocol    = "-1"
    from_port   = var.output_sg_port
    to_port     = var.output_sg_port
    cidr_blocks = ["10.0.0.0/26"]
  }
}

module "ec2_cluster"{
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 2.0"

  name                   = "ec2_evidence_cluster"
  instance_count         = 1

  ami                    = "ami-ebd02392"
  instance_type          = "t3.micro"
  key_name               = "ec2-evidence"
  monitoring             = true
  vpc_security_group_ids = ["${aws_security_group.ec2-sg.id}"]
  subnet_ids              = module.subnets.public_subnet_ids

  tags = {
    Terraform   = "true"
    Environment = "${var.environment}"
  }

}