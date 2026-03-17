output "redis_endpoint" {
  description = "Redis Endpoint"
  value = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "reader_endpoint" {
  description = "Redis Endpoint"
  value = aws_elasticache_replication_group.redis.reader_endpoint_address
}
output "redis_port" {
  description = "Redis Port"
  value = aws_elasticache_replication_group.redis.port
}