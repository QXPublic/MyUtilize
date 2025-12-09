调整 Linux 内核
编辑 sysctl 文件：
```
# 缩短 TCP 连接存活时间，防止死连接堆积
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 2
net.ipv4.tcp_fin_timeout = 15

# 开启 BBR
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

```
