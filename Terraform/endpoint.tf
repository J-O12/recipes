# resource "aws_vpc_endpoint" "ec2-messages" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.ap-southeast-2.ec2messages"
#   vpc_endpoint_type = "Interface"
#   security_group_ids = [
#     aws_security_group.ssm_sec_group.id
#   ]
#   subnet_ids          = [aws_subnet.private-1.id, aws_subnet.private-2.id]
#   private_dns_enabled = true
# }

# resource "aws_vpc_endpoint" "ssm" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.ap-southeast-2.ssm"
#   vpc_endpoint_type = "Interface"
#   security_group_ids = [
#     aws_security_group.ssm_sec_group.id
#   ]
#   subnet_ids          = [aws_subnet.private-1.id, aws_subnet.private-2.id]
#   private_dns_enabled = true
# }


# resource "aws_vpc_endpoint" "ssm-messages" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.ap-southeast-2.ssmmessages"
#   vpc_endpoint_type = "Interface"
#   security_group_ids = [
#     aws_security_group.ssm_sec_group.id
#   ]
#   subnet_ids          = [aws_subnet.private-1.id, aws_subnet.private-2.id]
#   private_dns_enabled = true
# }
