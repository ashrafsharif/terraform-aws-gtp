#!/bin/bash

# user-data-app.sh - provision app server for GTP

## Specify access key ID and secret to export logs to CloudWatch
AWS_CLOUDWATCH_ACCESS_KEY_ID=''
AWS_CLOUDWATCH_SECRET_ACCESS=''

## The following steps are for RHEL 9
## -- start --
## ami-04ba270ccd8098407 - RHEL 9 - ap-southeast-1 (owner: amazon)

# set SELinux to permissive
sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config

# configure epel & remi for php & redis
sudo dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
sudo dnf -y install https://rpms.remirepo.net/enterprise/remi-release-9.rpm
sudo dnf config-manager --set-enabled remi

# install php8.2 and nginx 1.20
sudo dnf -y module switch-to php:remi-8.2
sudo dnf -y install openssl git vim wget ruby curl sysstat net-tools bind-utils mysql redis php-common php php-pecl-translit php-mbstring php-pecl-zip php-json \
    php-pecl-mcrypt php-pecl-memcache php-opcache php-xml php-phpiredis \
    php-pecl-ssh2 php-devel php-mysqlnd php-pecl-http php-bcmath php-pecl-igbinary php-pecl-raphf \
    php-cli php-gd php-xmlrpc php-pecl-redis5 php-pdo php-pecl-msgpack php-fpm \
    nginx nginx-mod-* nginx-all-modules

# configure php-fpm
sudo systemctl start php-fpm
sudo systemctl enable php-fpm
sudo touch /.user-data-app.phpfpm.complete

# generate ssl key and cert
sudo mkdir -p /etc/pki/nginx/private
sudo openssl req -subj '/CN=GTP/O=ACE Group/C=MY' \
    -new -newkey rsa:2048 -sha256 -keyout /etc/pki/nginx/private/server.key \
    -days 3650 -nodes -x509 -out /etc/pki/nginx/server.crt

# configure nginx to use ssl
# uncomments tls lines inside nginx.conf
sudo sed '58,81s/^#//' -i.ori1 /etc/nginx/nginx.conf
# removes http2 since AWS LB only support http1
sudo sed 's/ http2//g' -i.ori2 /etc/nginx/nginx.conf
# nginx config for gtp
sudo wget https://gist.githubusercontent.com/ashrafsharif/ad83ebefcbbd277153eede87e4abd5ef/raw/de16e999f6d50862012a2ec5ff8b2437964571df/gtp.nginx.conf -O /etc/nginx/conf.d/gtp.conf

sudo systemctl start nginx
sudo systemctl enable nginx
sudo touch /.user-data-app.nginx.complete

# install codedeploy agent
sudo wget https://aws-codedeploy-ap-southeast-1.s3.ap-southeast-1.amazonaws.com/latest/install
sudo chmod 755 install
sudo ./install auto
sudo systemctl enable codedeploy-agent
sudo touch /.user-data-app.codedeploy.complete

# install cloudwatch agent
sudo curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O
sudo python ./awslogs-agent-setup.py --region ap-southeast-1
cat >/var/awslogs/etc/awslogs.conf <<EOF
[/var/log/nginx/access.log]
datetime_format = %d/%b/%Y:%H:%M:%S %z
file = /var/log/nginx/access.log
buffer_duration = 5000
log_stream_name = access.log
initial_position = end_of_file
log_group_name = /gtp/app/nginx/logs

[/var/log/nginx/error.log]
datetime_format = %Y/%m/%d %H:%M:%S
file = /var/log/nginx/error.log
buffer_duration = 5000
log_stream_name = error.log
initial_position = end_of_file
log_group_name = /gtp/app/nginx/logs
EOF
sudo chmod 600 /var/awslogs/etc/awslogs.conf
cat >/root/.aws/credentials <<EOF
[default]
aws_access_key_id = $AWS_CLOUDWATCH_ACCESS_KEY_ID
aws_secret_access_key = $AWS_CLOUDWATCH_SECRET_ACCESS
EOF
sudo chmod 600 /root/.aws/credentials

sudo systemctl start awslogs
sudo systemctl enable awslogs
sudo touch /.user-data-app.cloudwatch.complete

cd /usr/share/nginx/html
sudo git clone https://github.com/ashrafsharif/sampleapp-wordpress
sudo mkdir -p /usr/share/nginx/html/gtp
sudo cp -Rf /usr/share/nginx/html/sampleapp-wordpress/* /usr/share/nginx/html/gtp/
sudo touch /.user-data-app.git.complete

# create a flag file indicating deployment is complete
sudo touch /.user-data-app.all.complete

## -- end --
