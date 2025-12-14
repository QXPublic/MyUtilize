调整 Linux 内核

安装 XanMod 内核：

1、安装必要的基础工具
```
apt update && apt upgrade -y
apt install wget curl gnupg git -y
```
2、手动导入密钥
```
# 1. 从公钥服务器拉取指定密钥
gpg --keyserver keyserver.ubuntu.com --recv-keys 86F7D09EE734E623

# 2. 将密钥导出到 apt 需要的路径
gpg --export 86F7D09EE734E623 | tee /usr/share/keyrings/xanmod-archive-keyring.gpg > /dev/null

# 3. 再次更新软件源
apt update
```
3、安装内核
```
apt install linux-xanmod-x64v3 -y
```
重启验证
```
reboot
uname -r
```
开启 BBR 及网络栈优化
```
cat > /etc/sysctl.conf << EOF
# 系统文件描述符限制
fs.file-max = 1000000
fs.inotify.max_user_instances = 8192

# 开启 BBR
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# TCP 窗口与缓冲区优化
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1

# 减少 TIME_WAIT，加快连接回收
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30

# 防御与连接保持
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
EOF
```
应用配置

```sysctl -p
```




