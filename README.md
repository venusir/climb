## Server

### Prepare

```
# 更新软件源
apt-get update && apt-get upgrade

# 安装curl
apt-get install curl -y

# 启用 BBR TCP 拥塞控制算法
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
```

### FileBrowser

```
# 安装 filebrowser
curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

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

# 设置用户目录
filebrowser -d /etc/filebrowser/filebrowser.db config set --scope /root/filebrowser

# 显示用户
filebrowser -d /etc/filebrowser/filebrowser.db users ls

# 添加用户
filebrowser -d /etc/filebrowser/filebrowser.db users add username password

# 删除用户
filebrowser -d /etc/filebrowser/filebrowser.db users rm username

# 更新密码
filebrowser -d /etc/filebrowser/filebrowser.db users update username -p password
```

```
# 配置systemctl启动
cat > /etc/systemd/system/filebrowser.service << EOF
[Unit]
Description=File browser
After=network.target

[Service]
ExecStart=/usr/local/bin/filebrowser -d /etc/filebrowser.db

[Install]
WantedBy=multi-user.target
EOF
```

```
# 重载 systemd
systemctl daemon-reload

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

### Nginx

```
# 安装nginx
apt-get install nginx -y

# 创建nginx配置
cat > /etc/nginx/conf.d/venusir.cc.conf << "EOF"
server {
	listen 443 ssl;
	listen [::]:443 ssl;
	
	server_name venusir.cc;  #你的域名
	ssl_certificate       /root/certs/venusir.cc/fullchain.pem;  #证书位置
	ssl_certificate_key   /root/certs/venusir.cc/private.pem;    #私钥位置
	
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
EOF
```

### Certificate
```
# 创建证书路径
mkdir -p /root/certs/venusir.cc

# 安装acme
curl https://get.acme.sh | sh -s email=luntan609@hotmail.com

# 添加软链接
ln -s /root/.acme.sh/acme.sh /usr/local/bin/acme.sh

# 切换CA机构
acme.sh --set-default-ca --server letsencrypt

# 申请证书
acme.sh --issue -d venusir.cc -w /var/www/html -k ec-256

# 安装证书
acme.sh --install-cert -d venusir.cc \
--key-file       /root/certs/venusir.cc/private.pem  \
--fullchain-file /root/certs/venusir.cc/fullchain.pem \
--reloadcmd      "systemctl force-reload nginx"
```

## Client

### PVE-LXC

#### 开启Tun
> 在 pve 宿主中, 确认 `/dev/net/tun` 存在并获取对应的信息, 具体命令和返回如下

```
root@pve:~# ls -al /dev/net/tun
crw-rw-rw- 1 root root 10, 200 Jun 30 23:08 /dev/net/tun
```

> 记录其中的 `10, 200` 这两个数字, 后面需要用到.
> 然后修改 `/etc/pve/lxc/CTID.conf` 文件, 新增如下两行

```
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
```

> 上面的 `10:200` 需要和前面使用 `ls -al /dev/net/tun` 获取的结果对应起来.

#### 开启IP转发

> 开启 lxc 的 IP 转发功能

> 编辑 `/etc/sysctl.conf` 文件, 将以下两行的注释去掉. 如果没有这两行, 需要添加

```
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
```

> 编辑完成后, 使用 `sysctl` 命令 reload

```
sysctl -p /etc/sysctl.conf
```