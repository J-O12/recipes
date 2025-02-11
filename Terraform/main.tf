# resource "aws_s3_bucket" "recipe-static-website-joel" {
#   bucket = "recipe-static-website-joel"

#   tags = {
#     Name = "Test bucket"
#   }
# }

# resource "aws_s3_bucket_website_configuration" "website-config" {
#   bucket = aws_s3_bucket.recipe-static-website-joel.id

#   index_document {
#     suffix = "index.html"
#   }
# }

# resource "aws_s3_bucket_ownership_controls" "recipe-controls" {
#   bucket = aws_s3_bucket.recipe-static-website-joel.id
#   rule {
#     object_ownership = "BucketOwnerEnforced"
#   }
# }

# resource "aws_s3_bucket_public_access_block" "recipe-access" {
#   bucket = aws_s3_bucket.recipe-static-website-joel.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# resource "aws_s3_bucket_versioning" "versioning_example" {
#   bucket = aws_s3_bucket.recipe-static-website-joel.id
#   versioning_configuration {
#     status = "Disabled"
#   }
# }

# data "aws_caller_identity" "current" {}

# resource "aws_s3_bucket_policy" "recipe_policy" {
#   bucket = aws_s3_bucket.recipe-static-website-joel.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "AllowCloudFrontAccess"
#         Effect = "Allow"
#         Principal = {
#           Service = "cloudfront.amazonaws.com"
#         }
#         Action   = "s3:GetObject"
#         Resource = "${aws_s3_bucket.recipe-static-website-joel.arn}/*"
#         Condition = {
#           StringEquals = {
#             "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.s3_distribution.id}"
#           }
#         }
#       }
#     ]
#   })
# }


# # cloudfront
# resource "aws_cloudfront_origin_access_control" "recipe-origin" {
#   name                              = "recipe-OAC"
#   description                       = "recipe Policy"
#   origin_access_control_origin_type = "s3"
#   signing_behavior                  = "always"
#   signing_protocol                  = "sigv4"
# }

# locals {
#   s3_origin_id = "RecipeOrigin"
# }

# data "aws_cloudfront_cache_policy" "recipe-cache-policy" {
#   name = "Managed-CachingOptimized"
# }


# resource "aws_cloudfront_distribution" "s3_distribution" {
#   origin {
#     domain_name              = aws_s3_bucket.recipe-static-website-joel.bucket_regional_domain_name
#     origin_access_control_id = aws_cloudfront_origin_access_control.recipe-origin.id
#     origin_id                = local.s3_origin_id

#   }

#   enabled         = true
#   is_ipv6_enabled = true
#   #   comment             = "Some comment"
#   default_root_object = "index.html"



#   default_cache_behavior {
#     allowed_methods  = ["GET", "HEAD"]
#     cached_methods   = ["GET", "HEAD"]
#     target_origin_id = local.s3_origin_id
#     cache_policy_id  = data.aws_cloudfront_cache_policy.recipe-cache-policy.id



#     viewer_protocol_policy = "redirect-to-https"
#     min_ttl                = 0
#     default_ttl            = 3600
#     max_ttl                = 86400
#   }


#   price_class = "PriceClass_100"

#   http_version = "http2"

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#       #   locations        = ["US", "CA", "GB", "DE"]
#     }
#   }
#   custom_error_response {
#     error_caching_min_ttl = 0
#     error_code            = 403
#     response_code         = 200
#     response_page_path    = "/"
#   }



#   viewer_certificate {
#     # cloudfront_default_certificate = true
#     acm_certificate_arn = var.certificate-arn
#     ssl_support_method  = "sni-only"
#   }

# }

