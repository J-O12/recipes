resource "aws_s3_bucket" "recipe-static-website-joel" {
  bucket = "recipe-static-website-joel"

  tags = {
    Name = "Test bucket"
  }
}

resource "aws_s3_bucket_website_configuration" "website-config" {
  bucket = aws_s3_bucket.recipe-static-website-joel.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "recipe-controls" {
  bucket = aws_s3_bucket.recipe-static-website-joel.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "recipe-access" {
  bucket = aws_s3_bucket.recipe-static-website-joel.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.recipe-static-website-joel.id
  versioning_configuration {
    status = "Disabled"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "recipe_policy" {
  bucket = aws_s3_bucket.recipe-static-website-joel.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.recipe-static-website-joel.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.s3_distribution.id}"
          }
        }
      }
    ]
  })
}


# cloudfront
resource "aws_cloudfront_origin_access_control" "recipe-origin" {
  name                              = "recipe-OAC"
  description                       = "recipe Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

locals {
  s3_origin_id = "RecipeOrigin"
}

data "aws_cloudfront_cache_policy" "recipe-cache-policy" {
  name = "Managed-CachingOptimized"
}

# Find a certificate issued by (not imported into) ACM
# data "aws_acm_certificate" "joeloike" {
#   domain      = "joeloike.com"
#   types       = ["AMAZON_ISSUED"]
#   most_recent = true
# }

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.recipe-static-website-joel.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.recipe-origin.id
    origin_id                = local.s3_origin_id

  }

  enabled         = true
  is_ipv6_enabled = true
  #   comment             = "Some comment"
  default_root_object = "index.html"



  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
    cache_policy_id  = data.aws_cloudfront_cache_policy.recipe-cache-policy.id



    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }


  price_class = "PriceClass_100"

  http_version = "http2"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      #   locations        = ["US", "CA", "GB", "DE"]
    }
  }
  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 403
    response_code         = 200
    response_page_path    = "/"
  }



  viewer_certificate {
    # cloudfront_default_certificate = true
    acm_certificate_arn = var.certificate-arn
    ssl_support_method  = "sni-only"
  }

}


# resource "aws_s3_bucket_acl" "recipe_acl" {
#   bucket = aws_s3_bucket.recipe-static-website-joel.id
#   acl    = "bucket-owner-full-control"
# }


# resource "aws_s3_bucket_cors_configuration" "example" {
#   bucket = aws_s3_bucket.lambda-s3.id

#   cors_rule {
#     allowed_headers = ["*"]
#     allowed_methods = ["PUT", "POST"]
#     allowed_origins = ["https://s3-website-test.hashicorp.com"]
#     expose_headers  = ["ETag"]
#     max_age_seconds = 3000
#   }

#   cors_rule {
#     allowed_methods = ["GET"]
#     allowed_origins = ["*"]
#   }
# }


# resource "aws_s3_bucket_acl" "example" {
# #   depends_on = [
# #     # aws_s3_bucket_ownership_controls.example,
# #     aws_s3_bucket_public_access_block.recipe-access,
# #   ]

#   bucket = aws_s3_bucket.recipe-static-website-joel.id
#   acl    = "private"
# }




# resource "aws_s3_bucket_object_lock_configuration" "example" {
#   bucket = aws_s3_bucket.lambda-s3.id
# object_lock_enabled = "Enabled"
# }





# # #--- Configuration for Lambda ----

# # data "archive_file" "test-lambda" {
# #   type        = "zip"
# #   source_file = "function.py"
# #   output_path = "${path.module}/New_terraform/function.zip"
# # }

# # resource "aws_lambda_function" "test_lambda" {
# #   # If the file is not in the current working directory you will need to include a
# #   # path.module in the filename.
# #   filename      = "${path.module}/New_terraform/function.zip"
# #   function_name = "first-lambda"
# #   role          = aws_iam_role.lambda_role.arn
# #   handler       = "function.lambda_handler"

# #   source_code_hash = data.archive_file.test-lambda.output_base64sha256

# #   runtime = "python3.9"

# #   architectures = ["arm64"]

# #   # vpc_config {
# #   #   vpc_id = aws_vpc.main.id
# #   #   subnet_ids = [aws_subnet.public-1.id]
# #   #   security_groups = [aws_security_group.public_sec_group.id]
# #   # }
# # }


# # # resource "aws_iam_policy" "lambda_logs_policy" {
# # #   name        = "LambdaLogsPolicy"
# # #   description = "Allows Lambda functions to write logs to CloudWatch Logs"

# # #   policy = jsonencode({
# # #     "Version": "2012-10-17",
# # #     "Statement": [
# # #         {
# # #             "Effect": "Allow",
# # #             "Action": "logs:CreateLogGroup",
# # #             "Resource": "*"
# # #         },
# # #         {
# # #             "Effect": "Allow",
# # #             "Action": [
# # #                 "logs:CreateLogStream",
# # #                 "logs:PutLogEvents"
# # #             ],
# # #             "Resource": "arn:aws:logs:*:*:*"
# # #         }
# # #     ]
# # # }
# # # )
# # # }

# # resource "aws_iam_role" "lambda_role" {
# #   name = "lambda-role"
# #   assume_role_policy = jsonencode({
# #     "Version"   : "2012-10-17",
# #     "Statement" : [
# #       {
# #         "Effect"    : "Allow",
# #         "Principal" : {
# #           "Service" : "lambda.amazonaws.com"
# #         },
# #         "Action"    : "sts:AssumeRole"
# #       }
# #     ]
# #   })
# # }

# # resource "aws_iam_policy_attachment" "lambda_logs_attachment1" {
# #   name       = "LambdaLogsAttachment"
# #   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# #   roles      = [aws_iam_role.lambda_role.name]
# # }


# # resource "aws_iam_policy_attachment" "lambda_logs_attachment2" {
# #   name       = "LambdaLogsAttachment"
# #   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonS3ObjectLambdaExecutionRolePolicy"
# #   roles      = [aws_iam_role.lambda_role.name]
# # }



# output "CloudFrontDistributionUrl" {
#   description = "URL of the CloudFront distribution to access your frontend"
#   value       = aws_cloudfront_distribution.s3_distribution.domain_name
#   export_name = ${var.stack_name}-CloudFrontDistributionUrl
# }

# output "CloudFrontDistributionId" {
#   description = "The CloudFront Distribution ID"
#   value       = aws_cloudfront_distribution.s3_distribution.id
#   export_name = "recipe_CloudFrontDistributionId"
# }

# output "APIDNSName" {
#   description = "Public DNS Name of the EC2 instance with your API"
#   value       = aws_instance.api_instance.public_dns
#   export_name = "recipe-PublicDNSName"
# }
