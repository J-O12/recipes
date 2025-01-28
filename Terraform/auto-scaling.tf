resource "aws_launch_template" "ASG_template" {
  name = "ASG_template"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 8
      volume_type = "gp3"
      iops        = 3000

    }


  }

  user_data = base64encode(templatefile("${path.module}/userdata.tpl", {
    GitRepoURL = "https://github.com/J-O12/chapter3.git"
  }))

  iam_instance_profile {
    name = aws_iam_instance_profile.asg_profile.name
  }

  image_id = var.image-id

  instance_type = var.instance-type

  # key_name = var.key_name

  network_interfaces {
    security_groups = [aws_security_group.private.id]
  }
}


resource "aws_autoscaling_group" "Recipe-ASG" {
  name                      = "asg"
  max_size                  = 2
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 2
  force_delete              = true
  launch_template {
    id      = aws_launch_template.ASG_template.id
    version = aws_launch_template.ASG_template.latest_version
  }
  vpc_zone_identifier = [aws_subnet.private-sub-1.id, aws_subnet.private-sub-2.id]
  target_group_arns   = [aws_lb_target_group.Recipe-group.arn]
  depends_on          = [aws_launch_template.ASG_template, aws_security_group.private, aws_security_group.ALB_sec_group, aws_route_table_association.route_table_associations]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  initial_lifecycle_hook {
    name                 = "foobar"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 2000
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  }
}

output "target_group_arn" {
  value = aws_lb_target_group.Recipe-group.arn
}



resource "aws_autoscaling_policy" "asg_policy" {
  name                   = "asg_policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.Recipe-ASG.name
}

resource "aws_iam_instance_profile" "asg_profile" {
  name = "asg_profile"
  #   role = var.role
  role = aws_iam_role.recipe-role.name
}

resource "aws_iam_policy" "ec2-dynamo-policy" {
  name        = "ec2-dynamo-policy"
  path        = "/"
  description = "Ec2-dynamoDB policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:Scan",
          "dynamodb:DeleteItem",
        ]
        Effect   = "Allow"
        Resource = "${aws_dynamodb_table.RecipesTable.arn}"
      },
    ]
  })
}
resource "aws_iam_policy" "ec2-TestAutoScalingEvent-policy" {
  name        = "ec2-TestAutoScalingEvent-policy"
  path        = "/"
  description = "Policy for testing scaling event"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:CompleteLifecycleAction"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:autoscaling:*:351575047322:autoScalingGroup:*:autoScalingGroupName/asg"
      },
    ]
  })
}
resource "aws_iam_policy_attachment" "recipe-policy-attach" {
  for_each = {
    dynamo_policy          = aws_iam_policy.ec2-dynamo-policy.arn
    autoscaling_event      = aws_iam_policy.ec2-TestAutoScalingEvent-policy.arn
    ssm_managed_instance   = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  name       = "recipe-policy-attachment-${each.key}"
  roles      = [aws_iam_role.recipe-role.name]
  policy_arn = each.value
}



resource "aws_iam_role" "recipe-role" {
  name = "ec2-dynamo-role"
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

# Create a new load balancer
resource "aws_lb" "Recipe-ALB" {
  name               = "Recipe-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ALB_sec_group.id]
  subnets            = [aws_subnet.public-sub-1.id, aws_subnet.public-sub-2.id]

}

resource "aws_lb_target_group" "Recipe-group" {
  name     = "tf-example-lb-tg"
  port     = "80"
  protocol = "HTTP"
  vpc_id   = aws_vpc.recipe.id


  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/health"
  }
}

data "aws_acm_certificate" "api-joeloike" {
  domain      = "api.joeloike.com"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

resource "aws_lb_listener" "Recipe-listener" {
  load_balancer_arn = aws_lb.Recipe-ALB.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.api-joeloike.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Recipe-group.arn
  }
  lifecycle {
    replace_triggered_by = [aws_lb_target_group.Recipe-group]
  }
}
