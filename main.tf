provider "aws" {
  region = "eu-central-1"
}
module "eks_module" {
  source = "./eks"
}
module "rds_module" {
  source  = "./rds"
  vpc_id  = module.eks_module.id_vpc
  sg_id   = module.eks_module.id_sg
# provide subnet ids from eks module
  subnet_ids = [module.eks_module.subnets_id,
  module.eks_module.subnets_id2,
  ]
}