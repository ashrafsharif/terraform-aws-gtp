# terraform-aws-gtp

## Deployment Instructions

1) Install [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) and [git](https://github.com/git-guides/install-git) on your workstation.

2) Clone this repo into your workstation. Example on Linux:

```bash
git clone https://github.com/ashrafsharif/terraform-aws-gtp
```

3) Navigate to the directory:

```bash
cd terraform-aws-gtp
```

4) Specify the required values in the following files and lines:

  4.1) AWS access key and secret - `main.tf` on line 3 & 4 (the account should have all the AWS privileges):
  
  ```ruby
  access_key = ""
  secret_key = ""
  ```
  
  4.2) AWS key pair - `main.tf` on line 70:
  
  ```ruby
  key_name = "my-aws-keypair"
  ```
  
  4.3) AWS CloudWatch access key and secret - `user-data-app.sh` on line 6 & 7 (you may use the same value as specified at 4.1):
  
  ```bash
  AWS_CLOUDWATCH_ACCESS_KEY_ID=''
  AWS_CLOUDWATCH_SECRET_ACCESS=''
  ```
  
  4.4) AWS RDS MySQL admin username and password - `mysql.tf` on line 12 & 13:
  
  ```ruby
  username                        = "dbadmin"
  password                        = "mySuperSecretP455"
  ```
  
5) Optionally, you may change the VPC details like VPC name, CIDR, subnets under `main.tf` line 26 - 33.

6) Optionally, you may change the MySQL details like mysql user, host and password at `mysql.tf` line 38 - 40.

7) Under the `terraform-aws-gtp` directory, initialize Terraform modules:

```
terraform init
```

8) Start the deployment:

```
terraform plan # make sure no error in the planning stage
terraform apply # type 'yes' in the prompt
```

## Testing 

You shall see the following output after the Terraform deployment completes:

```ruby
app_endpoint = "gtp-prod-app-lb-1797944393.ap-southeast-1.elb.amazonaws.com"
app_name = "gtp-prod-app"
primary_redis_endpoint = "gtp-prod-redis-rep-group-1.u2yh4k.ng.0001.apse1.cache.amazonaws.com"
rds_endpoint = "gtpprodmysql.cdw9q2wnb00s.ap-southeast-1.rds.amazonaws.com:3306"
reader_redis_endpoint = "gtp-prod-redis-rep-group-1-ro.u2yh4k.ng.0001.apse1.cache.amazonaws.com"
```

Open your browser and go to the `app_endpoint`, suffixed it with `/gtp`, for example: `http://gtp-prod-app-lb-1797944393.ap-southeast-1.elb.amazonaws.com/gtp`. You shall see a Wordpress installation page. This indicates the ASG and ELB are working, plus php-fpm and nginx. The sample app is staged from this repo: https://github.com/ashrafsharif/sampleapp-wordpress during deployment. See `user-data-app.sh` line 95-99.

To test MySQL and Redis, you have to SSH to both EC2 instances and update the following file `/usr/share/nginx/html/gtp/test/index.php` and specify the values on line 3 to 8 accordingly:

```php
$redis_host ="gtp-prod-redis-rep-group-1.u2yh4k.ng.0001.apse1.cache.amazonaws.com"; // primary_redis_endpoint
$redis_port ="6379";         // redis port as in redis.tf line 22
$mysql_host = "gtpprodmysql.cdw9q2wnb00s.ap-southeast-1.rds.amazonaws.com"; // rds_endpoint (without the port)
$mysql_user = "gtp";         // user as in mysql.tf line 38-40
$mysql_pass = "pass098TT";   // password as in mysql.tf line 38-40
$mysql_db = "gtp";           // db name as in mysql.tf line 34
```

Save the file and you should be able to access `http://gtp-prod-app-lb-1797944393.ap-southeast-1.elb.amazonaws.com/gtp/test/index.php`. It will perform a simple connectivity test to the specified MySQL and Redis endpoints.
