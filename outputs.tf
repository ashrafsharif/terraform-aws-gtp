output "app_name" {
  value = aws_codedeploy_app.gtp_prod_app.name
}

output "mysql_rds_endpoint" {
  value = aws_db_instance.gtp_prod_mysql.endpoint
}

output "app_endpoint" {
  value = aws_lb.gtp_prod_app.dns_name
}

output "primary_redis_endpoint" {
  value = aws_elasticache_replication_group.gtp_prod_app.primary_endpoint_address
}

output "reader_redis_endpoint" {
  value = aws_elasticache_replication_group.gtp_prod_app.reader_endpoint_address
}
