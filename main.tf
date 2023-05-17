provider "aws" {
  region = "eu-central-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
  }
}

module "s3" {
  source = "./modules/s3"
}

module "cognito" {
  source     = "./modules/cognito"
  userPoolId = module.cognito.userPoolId
  clientId   = module.cognito.clientId
}

module "uploadIndex" {
  source           = "./modules/index"
  region           = "eu-central-1"
  clientId         = module.cognito.clientId
  identity_pool_id = module.cognito.identity_pool_id
  userPoolId       = module.cognito.userPoolId
  bucketName       = module.s3.bucket_name
  depends_on       = [module.s3, module.cognito]
}

module "cloudfront" {
  source      = "./modules/cloudfront"
  bucket_name = module.s3.bucket_name
  bucket_arn  = module.s3.bucket_arn
  bucketName  = module.s3.bucketName
  depends_on  = [module.uploadIndex]
}

module "queque" {
  source = "./modules/queque"
}

module "firstlambda" {
  source     = "./modules/firstlambda"
  bucketName = module.s3.bucket_name
  bucket_arn = module.s3.bucket_arn
  queueUrl   = module.queque.queueUrl
  depends_on = [module.cloudfront, module.queque]
}

module "secondlambda" {
  source        = "./modules/secondlambda"
  bucketName    = module.s3.bucket_name
  bucket_arn    = module.s3.bucket_arn
  queueArn      = module.queque.queueArn
  function_name = module.firstlambda.function_name
  function_arn  = module.firstlambda.function_arn
  depends_on    = [module.cloudfront, module.queque, module.firstlambda]
}