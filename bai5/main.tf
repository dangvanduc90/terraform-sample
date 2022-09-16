provider "aws" {
  region     = "us-east-2"
  access_key = var.access_key
  secret_key = var.secret_key
}

variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}

locals {
  project                = "terraform-series"
  aws_availability_zones = data.aws_availability_zones.available.names
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "dangvanduc90/vpc/aws"
  version = "1.0.0"

  vpc_cidr_block    = "10.0.0.0/16"
  private_subnet    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnet     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zone = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

output "aws_availability_zones" {
  value = data.aws_availability_zones.available.names
}

module "networking" {
  source                 = "./modules/networking"
  aws_availability_zones = local.aws_availability_zones
  project                = local.project
  vpc_cidr               = "10.0.0.0/16"
  private_subnets        = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets         = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  database_subnets       = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]
}

module "database" {
  source  = "./modules/database"
  project = local.project
  vpc     = module.networking.vpc
  sg      = module.networking.sg
}

module "autoscaling" {
  source                 = "./modules/autoscaling"
  aws_availability_zones = local.aws_availability_zones
  project                = local.project
  vpc                    = module.networking.vpc
  sg                     = module.networking.sg
  db_config              = module.database.config
}
