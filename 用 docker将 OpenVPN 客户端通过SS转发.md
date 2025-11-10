用 docker将 OpenVPN 客户端通过SS转发，实现 vps-docker-ss-openvpn-外部网站

1、创建一个目录并进入
```
mkdir openvpn-ss-gateway && cd openvpn-ss-gateway

```
2、创建 docker-compose.yml 文件

这是整个项目的核心。在 openvpn-ss-gateway 目录中，创建一个名为 docker-compose.yml 的文件，并填入以下内容。
```
vim docker-compose.yml
```
将以下配置粘贴到文件中：（./client.ovpn为 ovpn 配置的实际路径）
```
version: '3.8'

services:
  openvpn-client:
    image: dperson/openvpn-client # <-- 这里更换为新的、可用的镜像
    container_name: openvpn-client
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    volumes:
      - ./client.ovpn:/vpn/vpn.conf # 将您的 ovpn 文件映射到容器内
    dns:
      - 8.8.8.8
      - 1.1.1.1
    ports: # <-- 注意：端口映射需要移到这里！
     - "127.0.0.1:8388:8388/tcp" #只绑定到 127.0.0.1，仅供 VPS 本地访问
     - "127.0.0.1:8388:8388/udp"
    restart: unless-stopped

  ss-server:
    image: shadowsocks/shadowsocks-libev # SS 镜像保持不变，它很稳定
    container_name: ss-server
    # 【关键】使用 openvpn-client 容器的网络，这是实现流量转发的核心
    network_mode: "service:openvpn-client" 
    environment:
      - PASSWORD=your_strong_password_here # <-- 请务必修改为您自己的强密码
      - METHOD=aes-256-gcm # 加密方式，建议使用这个
      # 注意：由于共享网络，SS 服务器的端口和地址无需在此处指定
    depends_on:
      - openvpn-client
    restart: unless-stopped
```
停止现有服务：如果之前的容器仍在运行，请先停止并移除它们。
```
docker compose down
```
应用新配置：使用上面修改后的 docker-compose.yml 文件，重新启动服务。
```
docker compose up -d
```
实例配置(本地访问）
```
{
  "protocol": "shadowsocks",
  "settings": {
    "servers": [
      {
        "address": "127.0.0.1",
        "port": 8388,
        "password": "your_strong_password_here",
        "method": "aes-256-gcm"
      }
    ]
  }
```
