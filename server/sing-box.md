### Install

```
bash <(curl -fsSL https://sing-box.app/deb-install.sh)
```

### Config

```
cat /etc/sing-box/config.json << EOF
{
  "inbounds": [
    {
      "type": "trojan",
      "listen": "::",
      "listen_port": 8080,
      "users": [
        {
          "name": "example",
          "password": "password"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "example.org",
        "key_path": "/path/to/key.pem",
        "certificate_path": "/path/to/certificate.pem"
      },
      "multiplex": {
        "enabled": true
      }
    }
  ]
}
EOF
```

### Systemd

```
# 开启开机启动
systemctl enable sing-box
# 关闭开机启动
systemctl disable sing-box
# 启动
systemctl start sing-box
# 停止
systemctl stop sing-box
# 杀死进程
systemctl kill sing-box
# 重启
systemctl restart sing-box
# 全部日志
journalctl -u sing-box --output cat -e
# 最新日志
journalctl -u sing-box --output cat -f
```