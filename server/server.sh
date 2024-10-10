#!/bin/bash

CERTPATH=/root/certs

# 更新软件源
apt-get update

# 安装curl
apt-get install curl

# 启用 BBR TCP 拥塞控制算法
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

# 输入域名
read -p "Please enter your domain : " DOMAINNAME

# 安装nginx
apt-get install nginx

cat > /etc/nginx/conf.d/${DOMAINNAME}.conf << EOF
server {
    listen 443 ssl;	
    listen [::]:443 ssl;
	
	server_name ${DOMAINNAME};  #你的域名
	ssl_certificate       ${CERTPATH}/${DOMAINNAME}/fullchain.crt;  #证书位置
	ssl_certificate_key   ${CERTPATH}/${DOMAINNAME}/private.key;  #私钥位置
	
	ssl_session_timeout 1d;
	ssl_session_cache shared:MozSSL:10m;
	ssl_session_tickets off;
	ssl_protocols    TLSv1.2 TLSv1.3;
	ssl_prefer_server_ciphers off;

	location / {
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		proxy_set_header Host \$http_host;
		proxy_redirect off;
		proxy_pass http://127.0.0.1:${FILEBROWSERPORT};
	}

	# location /ray {   #分流路径
		# proxy_redirect off;
		# proxy_pass http://127.0.0.1:1000; #Xray端口
		# proxy_http_version 1.1;
		# proxy_set_header Upgrade \$http_upgrade;
		# proxy_set_header Connection "upgrade";
		# proxy_set_header Host \$host;
		# proxy_set_header X-Real-IP \$remote_addr;
		# proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
	# }
}

server {
	listen 80;
	location /.well-known/ {
		   root /var/www/html;
		}
	location / {
			rewrite ^(.*)\$ https://\$host\$1 permanent;
		}
}
EOF

systemctl reload nginx

# 证书路径
mkdir -p ${CERTPATH}/${DOMAINNAME}
# 安装acme
curl https://get.acme.sh | sh -s email=luntan609@hotmail.com
# 添加软链接
ln -s /root/.acme.sh/acme.sh /usr/local/bin/acme.sh
# 切换CA机构
acme.sh --set-default-ca --server letsencrypt
# 申请证书
acme.sh --issue -d ${DOMAINNAME} -w /var/www/html -k ec-256
# 安装证书
acme.sh --install-cert -d ${DOMAINNAME} \
--key-file       ${CERTPATH}/${DOMAINNAME}/private.key  \
--fullchain-file ${CERTPATH}/${DOMAINNAME}/fullchain.crt \
--reloadcmd      "systemctl force-reload nginx"