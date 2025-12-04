```
cat > install_docker_v2.sh << 'EOF'
#!/bin/bash

echo ">>> 0. 检查并安装必要工具 (curl)..."
if command -v apt-get >/dev/null; then
    apt-get update && apt-get install -y curl
elif command -v yum >/dev/null; then
    yum install -y curl
fi

echo ">>> 1. 开始安装 Docker..."
curl -fsSL https://get.docker.com | bash

echo ">>> 2. 配置小内存优化 (日志限制 + 禁用Userland Proxy)..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<JSON
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "live-restore": true,
  "userland-proxy": false
}
JSON

echo ">>> 3. 重启 Docker 生效..."
systemctl enable docker
systemctl restart docker

echo ">>> 4. 验证安装..."
docker info | grep -i "Storage Driver"
docker info | grep -i "Live Restore"

echo ">>> ✅ 安装完成！日志限制已生效。"
EOF

# 赋予权限并运行
chmod +x install_docker_v2.sh && ./install_docker_v2.sh

```
