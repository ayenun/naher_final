provider "aws" {
  region = "us-east-1"
}
resource "aws_vpc" "naher_final_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "naher_finalVPC"
  }
}
resource "aws_internet_gateway" "naher_final_igw" {
  vpc_id = aws_vpc.naher_final_vpc.id
  tags = {
    Name = "naher_finalIGW"
  }
}
resource "aws_route_table" "naher_final_rt" {
  vpc_id = aws_vpc.naher_final_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.naher_final_igw.id
  }
  tags = {
    Name = "naher_finalRouteTable"
  }
}
resource "aws_subnet" "naher_final_subnet1" {
  vpc_id                  = aws_vpc.naher_final_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "naher_finalSubnet1"
  }
}
resource "aws_subnet" "naher_final_subnet2" {
  vpc_id                  = aws_vpc.naher_final_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "naher_finalSubnet2"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.naher_final_subnet1.id
  route_table_id = aws_route_table.naher_final_rt.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.naher_final_subnet2.id
  route_table_id = aws_route_table.naher_final_rt.id
}
resource "aws_security_group" "naher_final_sg" {
  name        = "naher_finalSecurityGroup"
  description = "Security group for Fargate containers"
  vpc_id      = aws_vpc.naher_final_vpc.id
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_ecs_cluster" "naher_final_cluster" {
  name = "naher_finalCluster"
}
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecsExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
# AWS CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "/ecs/naher_finalTask"
  retention_in_days = 30
}
# Define the ECS Task Definition with updated log configuration
resource "aws_ecs_task_definition" "naher_final_task" {
  family                   = "naher_finalTask"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  container_definitions    = jsonencode([
    {
      name      = "naher_finalContainer"
      image     = "851725496132.dkr.ecr.us-east-1.amazonaws.com/naher_final_final:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}
# Create the ECS Service
resource "aws_ecs_service" "naher_final_final_service" {
  name            = "naher_final_finalService"
  cluster         = aws_ecs_cluster.naher_final_final_cluster.id
  task_definition = aws_ecs_task_definition.naher_final_final_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    assign_public_ip = true
    subnets          = [aws_subnet.naher_final_final_subnet1.id, aws_subnet.naher_final_final_subnet2.id]
    security_groups  = [aws_security_group.naher_final_final_sg.id]
  }
}
# Create an Application Load Balancer
resource "aws_lb" "naher_final_final_alb" {
  name               = "naher_final_finalALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.naher_final_final_sg.id]
  subnets            = [aws_subnet.naher_final_final_subnet1.id, aws_subnet.naher_final_final_subnet2.id]
}
resource "aws_lb_target_group" "naher_final_final_tg" {
  name     = "naher_final_finalTG"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.naher_final_final_vpc.id
}
resource "aws_lb_listener" "naher_final_final_listener" {
  load_balancer_arn = aws_lb.naher_final_final_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.naher_final_tg.arn
  }
}
