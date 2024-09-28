#!/bin/bash

# 证书路径
FILEBROWSERPORT=65480
CERTPATH=/etc/cert
mkdir -p /etc/cert

# 输入域名
read -p "Please enter your domain : " DOMAINNAMW
# 输入Cloudflare Token
read -p "Please enter your Cloudflare Token : " CFTOKEN
# 输入Cloudflare Account
read -p "Please enter your Cloudflare Account : " CFACCOUNT

export CF_Token="${CFTOKEN}"
export CF_Account_ID="${CFACCOUNT}"

# 更新软件源
apt-get update

# 安装curl
apt-get install curl

# 启用 BBR TCP 拥塞控制算法
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

# 安装x-ui面板
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)

# 只能在用IP:端口访问XUI面板并修改监听地址，监听端口及路径后才能使用域名经nginx代理访问

# 安装nginx
apt-get install nginx

cat > /etc/nginx/conf.d/${DOMAINNAMW}.conf << EOF
server {
    listen 443 ssl;	
    listen [::]:443 ssl;
	
	server_name ${DOMAINNAMW};  #你的域名
	ssl_certificate       ${CERTPATH}/${DOMAINNAMW}.crt;  #证书位置
	ssl_certificate_key   ${CERTPATH}/${DOMAINNAMW}.key;  #私钥位置
	
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
	
	location /xui {   #xui路径
		proxy_redirect off;
		proxy_pass http://127.0.0.1:54321;  #xui监听端口
		proxy_http_version 1.1;
		proxy_set_header Host \$host;
	}
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

# 安装acme
curl https://get.acme.sh | sh
# 添加软链接
ln -s  /root/.acme.sh/acme.sh /usr/local/bin/acme.sh
# 切换CA机构
acme.sh --set-default-ca --server letsencrypt
# 申请证书
acme.sh  --issue --dns dns_cf -d ${DOMAINNAMW} -d *.${DOMAINNAMW} -k ec-256
# 安装证书
acme.sh --install-cert -d ${DOMAINNAMW} --ecc --key-file ${CERTPATH}/${DOMAINNAMW}.key  --fullchain-file ${CERTPATH}/${DOMAINNAMW}.crt --reloadcmd "systemctl force-reload nginx"

# 安装Docker
curl -sSL https://get.docker.com/ | sh

# 安装filebrowser网盘 https://filebrowser.org/
docker run --name filebrowser \
    -v /srv/filebrowser:/srv \
    -v /srv/filebrowser/filebrowser.db:/database/filebrowser.db \
    -v /srv/filebrowser/settings.json:/config/settings.json \
    -e PUID=1000 \
    -e PGID=1000 \
    -p ${FILEBROWSERPORT}:80 \
    -d filebrowser/filebrowser:latest