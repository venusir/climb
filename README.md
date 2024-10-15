# Server

* 更新软件源

```
apt-get update
```

* 安装curl

```
apt-get install curl -y
```

* 启用 BBR TCP 拥塞控制算法

```
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
```

* 安装nginx

```
apt-get install nginx -y
```

* 证书路径

```
mkdir -p /root/certs
```

* 安装acme

```
curl https://get.acme.sh | sh -s email=luntan609@hotmail.com
```

* 添加软链接

```
ln -s /root/.acme.sh/acme.sh /usr/local/bin/acme.sh
```

* 切换CA机构

```
acme.sh --set-default-ca --server letsencrypt
```

* 申请证书

```
acme.sh --issue -d example.com -w /var/www/html -k ec-256
```

* 安装证书

```
acme.sh --install-cert -d example.com \
--key-file       /root/certs/example.com/private.key  \
--fullchain-file /root/certs/example.com/fullchain.crt \
--reloadcmd      "systemctl force-reload nginx"
```

* 创建nginx配置

```
nano /etc/nginx/conf.d/example.com.conf
```

* 编辑nginx配置

```
server {
	listen 443 ssl;
	listen [::]:443 ssl;
	
	server_name example.com;  #你的域名
	ssl_certificate       /root/certs/example.com/fullchain.crt;  #证书位置
	ssl_certificate_key   /root/certs/example.com/private.key;    #私钥位置
	
	ssl_session_timeout 1d;
	ssl_session_cache shared:MozSSL:10m;
	ssl_session_tickets off;
	ssl_protocols    TLSv1.2 TLSv1.3;
	ssl_prefer_server_ciphers off;

	location / {
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header Host $http_host;
		proxy_redirect off;
		proxy_pass http://127.0.0.1:5212;

		# 如果您要使用本地存储策略，请将下一行注释符删除，并更改大小为理论最大文件尺寸
		# client_max_body_size 20000m;
	}

	# location /ray {   #分流路径
		# proxy_redirect off;
		# proxy_pass http://127.0.0.1:10000;
		# proxy_http_version 1.1;
		# proxy_set_header Upgrade $http_upgrade;
		# proxy_set_header Connection "upgrade";
		# proxy_set_header Host $host;
		# proxy_set_header X-Real-IP $remote_addr;
		# proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	# }
}

server {
	listen 80;
	location /.well-known/ {
		   root /var/www/html;
		}
	location / {
			rewrite ^(.*)$ https://$host$1 permanent;
		}
}
```