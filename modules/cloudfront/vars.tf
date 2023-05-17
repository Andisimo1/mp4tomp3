variable "bucketName" {}
variable "bucket_name" {}
variable "bucket_arn" {}
variable "certificateArn" {
  default = "arn:aws:acm:us-east-1:366915744137:certificate/e064aa5e-fd71-4662-835f-242935736e2a"
}

variable "cloudFrontComment" {
  default = "CloudFront distribution"
}

variable "cloudFrontDefaultRootObject" {
  default = "index.html"
}

variable "cloudFrontCertificateVersion" {
  default = "TLSv1.2_2021"
}

variable "hostedZoneId" {
  default = "Z04545712VDTBF0N6KJBF"
}