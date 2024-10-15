## Server

### 准备工作
* 更新软件源

```
apt-get update && apt-get upgrade
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

### 安装FileBrowser

* 安装 filebrowser

```
curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
```

* 配置

```
# 创建文件夹
mkdir -p /etc/filebrowser
mkdir -p /var/filebrowser
mkdir -p /root/filebrowser

# 创建配置文件
touch /etc/filebrowser/filebrowser.db
touch /var/filebrowser/log.log

# 初始化配置
filebrowser -d /etc/filebrowser/filebrowser.db config init
# 查看配置
filebrowser -d /etc/filebrowser/filebrowser.db config cat

# 设置监听端口（默认8080）
filebrowser -d /etc/filebrowser/filebrowser.db config set --port 8080
# 设置监听地址（默认127.0.0.1）
filebrowser -d /etc/filebrowser/filebrowser.db config set --address 127.0.0.1
# 设置文件存放路径
filebrowser -d /etc/filebrowser/filebrowser.db config set --root /root/filebrowser
# 设置数据库文件
filebrowser -d /etc/filebrowser/filebrowser.db config set --database /etc/filebrowser/filebrowser.db
# 设置日志文件（默认stdout）
filebrowser -d /etc/filebrowser/filebrowser.db config set --log /var/filebrowser/log.log
# 设置语言（默认英文）
filebrowser -d /etc/filebrowser/filebrowser.db config set --locale zh-cn
# 添加用户
filebrowser -d /etc/filebrowser/filebrowser.db users add username password
```

* 启动

```
filebrowser -d /etc/filebrowser.db
```

* 配置systemctl启动

```
nano /etc/systemd/system/filebrowser.service
```

```
[Unit]
Description=File browser
After=network.target

[Service]
ExecStart=/usr/local/bin/filebrowser -d /etc/filebrowser.db

[Install]
WantedBy=multi-user.target
```

```
# 重载 systemd
systemctl daemon-reload
```

* 服务管理

```
# 运行
systemctl start filebrowser
# 重启
systemctl restart filebrowser
# 停止运行
systemctl stop filebrowser
# 开机启动
systemctl enable filebrowser
# 取消开机启动
systemctl disable filebrowser
# 查看运行状态
systemctl status filebrowser
```

### 安装Nginx

* 安装nginx

```
apt-get install nginx -y
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

### 证书申请

* 创建证书路径

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