##################
# RDS MySQL single instance
##################

resource "aws_db_instance" "gtp_prod_mysql" {
  engine                          = "mysql"
  identifier                      = "gtpprodmysql"
  allocated_storage               = 5 # Real prod: 500
  engine_version                  = "8.0.32"
  instance_class                  = "db.t3.micro" # Real prod: db.m5d.xlarge
  port                            = 3306
  username                        = ""
  password                        = ""
  parameter_group_name            = "default.mysql8.0"
  backup_window                   = "18:00-23:00"
  backup_retention_period         = 7
  db_subnet_group_name            = module.vpc.database_subnet_group_name
  vpc_security_group_ids          = [aws_security_group.gtp_prod_mysql.id]
  skip_final_snapshot             = true
  enabled_cloudwatch_logs_exports = ["audit", "error", "slowquery"]
  publicly_accessible             = false
  tags = {
    Tier = "Database"
  }
}

provider "mysql" {
  endpoint = aws_db_instance.gtp_prod_mysql.endpoint
  username = aws_db_instance.gtp_prod_mysql.username
  password = aws_db_instance.gtp_prod_mysql.password
}

resource "mysql_database" "gtp_prod_app" {
  name = "gtp"
}

resource "mysql_user" "gtp" {
  user               = "gtp"
  host               = "10.165.%.%"
  plaintext_password = "pass098TT"
}

resource "mysql_grant" "gtp" {
  user       = mysql_user.gtp.user
  host       = mysql_user.gtp.host
  database   = mysql_database.gtp_prod_app.name
  privileges = ["ALL PRIVILEGES"]
}
