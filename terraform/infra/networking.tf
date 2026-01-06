module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name   = var.vpc_name
  region = var.region
  cidr   = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_vpn_gateway     = false

  tags = var.tags

  public_subnet_tags = merge(var.tags, {
    Name                     = "${var.vpc_name}-public-subnet",
    "kubernetes.io/role/elb" = "1"
  })
  private_subnet_tags = merge(var.tags, {
    Name                              = "${var.vpc_name}-private-subnet",
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_lb" "alb" {
  name                       = "load-balancer"
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = module.vpc.public_subnets
  enable_deletion_protection = false
  tags                       = var.tags
}
