#####################
# ElastiCache Redis
#####################

resource "aws_elasticache_subnet_group" "gtp_prod_redis" {
  name       = "gtp-prod-redis"
  subnet_ids = [data.aws_subnets.private.ids[0], data.aws_subnets.private.ids[1]]

  tags = {
    Name = "Redis Elasticache subnet group for Production"
  }
}

resource "aws_elasticache_replication_group" "gtp_prod_redis" {
  multi_az_enabled            = true
  automatic_failover_enabled  = true
  preferred_cache_cluster_azs = ["ap-southeast-1a", "ap-southeast-1b"]
  replication_group_id        = "gtp-prod-redis-rep-group-1"
  engine                      = "redis"
  engine_version              = "6.2"
  description                 = "2-node Redis replication with single shard primary and single read replica"
  node_type                   = "cache.t4g.small" # Real prod: "cache.r6g.2xlarge"
  num_cache_clusters          = 2
  parameter_group_name        = "default.redis6.x"
  apply_immediately           = true
  auto_minor_version_upgrade  = false
  subnet_group_name           = aws_elasticache_subnet_group.gtp_prod_redis.name
  maintenance_window          = "sat:21:01-sat:23:00" # 9 PM UTC = 5 AM MYT
  snapshot_window             = "20:00-21:00"         # 8 PM UTC = 4 AM MYT
  snapshot_retention_limit    = 7
  port                        = 6379
  security_group_ids          = [aws_security_group.gtp_prod_redis.id]

  tags = {
    Tier = "Database"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.gtp_prod_app_redis.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }
}
