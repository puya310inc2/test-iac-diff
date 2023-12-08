terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0.0"
    }
  }
 
  required_version = ">= 0.15"
}

provider "aws" {
  profile = "default"
  region  =  var.aws_region
}


########################
# Bucket creation
########################
resource "aws_s3_bucket" "my_protected_bucket" {
  bucket = var.bucket_name
}

##########################
# Bucket private access
##########################
resource "aws_s3_bucket_acl" "my_protected_bucket_acl" {
  bucket = aws_s3_bucket.my_protected_bucket.id
  acl    = "private"
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
}

resource "aws_security_group" "snyk_rds_sg" {
  name   = "snyk_rds_sg"
  vpc_id = var.vpc_id

  tags = merge(var.default_tags, {
    Name = "snyk_rds_sg_${var.environment}"
  })

  # HTTP access from anywhere
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Resource to avoid error "AccessControlListNotSupported: The bucket does not allow ACLs"
resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.my_protected_bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
}




#############################
# Enable bucket versioning
#############################
resource "aws_s3_bucket_versioning" "my_protected_bucket_versioning" {
  bucket = aws_s3_bucket.my_protected_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}



########################
# Disabling bucket
# public access
########################
resource "aws_s3_bucket_public_access_block" "my_protected_bucket_access" {
  bucket = aws_s3_bucket.my_protected_bucket.id

  # Block public access
  block_public_acls   = false
  block_public_policy = false
  ignore_public_acls = true
  restrict_public_buckets = true
}
