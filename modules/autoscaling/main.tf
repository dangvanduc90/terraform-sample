data "aws_ami" "ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}

resource "aws_launch_template" "web" {
  name_prefix   = "web-"
  image_id      = data.aws_ami.ami.id
  instance_type = "t2.micro"
  monitoring {
    enabled = true
  }
  vpc_security_group_ids = [var.sg.web]
  user_data              = filebase64("${path.module}/run.sh")

  iam_instance_profile {
    name = module.iam_instance_profile.name
  }
}

module "iam_instance_profile" {
  source  = "terraform-in-action/iip/aws"
  version = "0.1.0"
  # insert the 1 required variable here
  actions = ["logs:*", "rds:*"]
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "7.0.0"
  # insert the 4 required variables here
  name               = "${var.project}-alb"
  load_balancer_type = "application"
  vpc_id             = var.vpc.vpc_id
  subnets            = var.vpc.public_subnets
  security_groups    = [var.sg.lb]
  target_groups = [
    {
      name_prefix      = "web"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    }
  ]
  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]
}


resource "aws_autoscaling_group" "web" {
  name                = "${var.project}-asg"
  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = var.vpc.private_subnets
  target_group_arns   = module.alb.target_group_arns
  force_delete        = true
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }
}
