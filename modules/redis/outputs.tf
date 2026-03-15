output "redis_endpoint" {
  description = "Redis Endpoint"
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}
output "redis_port" {
  description = "Redis Port"
  value = aws_elasticache_cluster.redis.cache_nodes[0].port
}