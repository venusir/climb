# Server

* �������Դ

```
apt-get update
```

* ��װcurl

```
apt-get install curl -y
```

* ���� BBR TCP ӵ�������㷨

```
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
```

* ��װnginx

```
apt-get install nginx -y
```

* ֤��·��

```
mkdir -p /root/certs
```

* ��װacme

```
curl https://get.acme.sh | sh -s email=luntan609@hotmail.com
```

* ���������

```
ln -s /root/.acme.sh/acme.sh /usr/local/bin/acme.sh
```

* �л�CA����

```
acme.sh --set-default-ca --server letsencrypt
```

* ����֤��

```
acme.sh --issue -d example.com -w /var/www/html -k ec-256
```

* ��װ֤��

```
acme.sh --install-cert -d example.com \
--key-file       /root/certs/example.com/private.key  \
--fullchain-file /root/certs/example.com/fullchain.crt \
--reloadcmd      "systemctl force-reload nginx"
```

* ����nginx����

```
nano /etc/nginx/conf.d/example.com.conf
```

* �༭nginx����

```
server {
	listen 443 ssl;
	listen [::]:443 ssl;
	
	server_name example.com;  #�������
	ssl_certificate       /root/certs/example.com/fullchain.crt;  #֤��λ��
	ssl_certificate_key   /root/certs/example.com/private.key;    #˽Կλ��
	
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

		# �����Ҫʹ�ñ��ش洢���ԣ��뽫��һ��ע�ͷ�ɾ���������Ĵ�СΪ��������ļ��ߴ�
		# client_max_body_size 20000m;
	}

	# location /ray {   #����·��
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