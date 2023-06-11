data "aws_caller_identity" "current" {}

data "aws_vpc" "current" {
  default = true
}

data "aws_subnets" "default_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.current.id]
  }
}

output "default_vpc" {
    value = data.aws_vpc.current.id
}

output "aws_subnets" {
    value = data.aws_subnets.default_vpc.ids
}

resource "aws_security_group" "allow_http_80" {
  name        = "allow_http_80"
  description = "Allow HTTP inbound traffic"
  vpc_id      = data.aws_vpc.current.id

  ingress {
    description      = "HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_http_80"
  }
}

resource "aws_cloudwatch_log_group" "log_group_helloworld" {
  name = "/ecs/helloworld"
}

resource "aws_ecs_cluster" "container-dev" {
  name = "container-dev"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "helloworld" {
  family = "helloworld"
  container_definitions = file("task-definition.json")
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  execution_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
  cpu = 256
  memory = 512
}

resource "aws_ecs_service" "helloworld-service" {
  name            = "helloworld-service"
  cluster         = aws_ecs_cluster.container-dev.id
  task_definition = aws_ecs_task_definition.helloworld.arn
  desired_count   = 1
  network_configuration {
    subnets         = data.aws_subnets.default_vpc.ids
    security_groups = [aws_security_group.allow_http_80.id]
    assign_public_ip = true
  }
  launch_type = "FARGATE"
  force_new_deployment = true
}
