resource "aws_security_group" "redis_sg" {
  name        = "${var.project_name}-${var.environment}-redis-sg"
  description = "Allow Redis access"
  vpc_id      = var.vpc_id
   # Allow Redis access from EKS nodes
  dynamic "ingress" {
    for_each = var.eks_node_security_group_id != "" ? [1] : []
    content {
      description     = "Redis from EKS nodes"
      from_port       = 6379
      to_port         = 6379
      protocol        = "tcp"
      security_groups = [var.eks_node_security_group_id]
    }
  }

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_subnet_group" "redis_subnet" {
  name       = "${var.project_name}-${var.environment}-redis-subnet"
  subnet_ids = var.subnet_ids
  tags = {
    Name = "${var.project_name}-${var.environment}-redis-subnet"
  }
}

# resource "aws_elasticache_cluster" "redis" {
#   cluster_id           = "${var.project_name}-${var.environment}-redis"
#   engine               = "redis"
#   node_type            = var.node_type
#   num_cache_nodes      = 1
#   port                 = 6379
#   parameter_group_name = "default.redis7"
#   subnet_group_name    = aws_elasticache_subnet_group.redis_subnet.name
#   security_group_ids   = [aws_security_group.redis_sg.id]
# }


resource "aws_elasticache_replication_group" "redis" {

  replication_group_id       = "${var.name}-redis"
  description                = "Redis replication group"

  engine                     = "redis"
  engine_version             = "7.0"

  node_type                  = var.node_type

  num_cache_clusters         = var.num_cache_nodes

  port                       = 6379

  automatic_failover_enabled = false
  multi_az_enabled           = false

  subnet_group_name          = aws_elasticache_subnet_group.redis.name

  security_group_ids         = [aws_security_group.redis.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  tags = {
    Name = "${var.name}-redis"
  }

}