# resource "aws_security_group" "ALB_sec_group" {
#   vpc_id = aws_vpc.recipe.id
#   name   = "ALB"

#   ingress {
#     description      = "HTTPS"
#     from_port        = 443
#     to_port          = 443
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "private" {
#   vpc_id = aws_vpc.recipe.id
#   name   = "private"
#   ingress {
#     description     = "HTTP"
#     from_port       = 80
#     to_port         = 80
#     protocol        = "tcp"
#     security_groups = [aws_security_group.ALB_sec_group.id]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }  
# }



# # resource "aws_security_group" "public_sec_group" {
# #   vpc_id = aws_vpc.recipe.id
# #   name   = "public"

# #   ingress {
# #     description      = "HTTP"
# #     from_port        = 80
# #     to_port          = 80
# #     protocol         = "tcp"
# #     cidr_blocks      = ["0.0.0.0/0"]
# #     ipv6_cidr_blocks = ["::/0"]
# #   }
# # }

# # resource "aws_security_group" "ssm_sec_group" {
# #   vpc_id = aws_vpc.main.id
# #   name   = "ssm"

# #   ingress {
# #     description = "HTTP"
# #     from_port   = 80
# #     to_port     = 80
# #     protocol    = "tcp"
# #     cidr_blocks = ["10.0.0.0/16"]
# #   }

# #   ingress {
# #     description = "HTTPs"
# #     from_port   = 443
# #     to_port     = 443
# #     protocol    = "tcp"
# #     cidr_blocks = ["10.0.0.0/16"]
# #   }


# #   egress {
# #     from_port   = 0
# #     to_port     = 0
# #     protocol    = "-1"
# #     cidr_blocks = ["0.0.0.0/0"]
# #   }
# # }


