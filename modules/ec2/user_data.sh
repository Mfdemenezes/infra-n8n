#!/bin/bash
yum update -y
yum install -y httpd
mkdir -p /var/www/html
echo "Instância ${project_name} foi criada com sucesso!" > /var/www/html/index.html
systemctl enable httpd --now
