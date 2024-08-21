#!/bin/bash

# 检查是否以 root 用户身份运行
if [ "$(id -u)" -ne 0 ]; then
  echo "请以 root 身份或使用 sudo 运行此脚本"
  exit 1
fi

# 更新并升级系统
apt update && apt upgrade -y

# 安装 Caddy
# 添加 Caddy 的 GPG 密钥
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | tee /etc/apt/trusted.gpg.d/caddy-stable.asc >/dev/null
# 添加 Caddy 的 apt 仓库
echo "deb [trusted=yes] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main" | tee /etc/apt/sources.list.d/caddy-stable.list

# 更新仓库并安装 Caddy
apt update
apt install caddy -y

# 创建 traffic 的 systemd 服务文件
cat << 'EOF' > /etc/systemd/system/traffic.service
[Unit]
Description=网络流量监控服务
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/
ExecStart=/root/traffic.sh
Restart=on-failure
RestartSec=30s

[Install]
WantedBy=multi-user.target
EOF

# 创建 traffic.sh 脚本
cat << 'EOF' > /root/traffic.sh
#!/bin/sh

# 如果传入 --help 参数，显示帮助信息
if [ "$1" == "--help" ];then
  cat << EOL
$0 网卡名称
--help 打印帮助菜单
EOL
  exit 0
fi

# 如果没有指定网卡名称，尝试自动检测网卡
if [ -z "$1" ];then
  if command -v ip > /dev/null; then
    interface=$(ip a | grep mtu | awk -F ': ' '{print $2}' | head -n 2 | tail -n +2 | awk -F ' ' '{print $1}')
  else
    interface=eth0
  fi
else
  interface=$1
fi

# 检查系统启动时间，决定是否累加流量数据
if [ "$(awk '{print $1}' /proc/uptime | cut -d. -f1)" -lt 120 ]; then
  [ -n "$(cat ./all)" ] && expr "$(cat ./all)" + "$(cat ./all-now)" > ./all || echo "1" > ./all
  [ -n "$(cat ./tx)" ] && expr "$(cat ./tx)" + "$(cat ./tx-now)" > ./tx || echo "1" > ./tx
  [ -n "$(cat ./rx)" ] && expr "$(cat ./rx)" + "$(cat ./rx-now)" > ./rx || echo "1" > ./rx
else
  [ -z "$(cat ./all)" ] && echo "1" > ./all
  [ -z "$(cat ./tx)" ] && echo "1" > ./tx
  [ -z "$(cat ./rx)" ] && echo "1" > ./rx
fi

# 启动 Caddy 文件服务器
nohup caddy file-server --browse --listen :49155 &

# 计算文件大小的函数
calculate() {
  str=$(expr $str + 2)
  str=$(expr $str / 4)
  if [ $str = 0 ]; then
    value="${info}B"
  elif [ $str = 1 ]; then
    value=$(expr $info / 1024)KB
  elif [ $str = 2 ]; then
    value=$(expr $info / 1024 / 1024)MB
  elif [ $str = 3 ]; then
    value=$(expr $info / 1024 / 1024 / 1024)GB
  elif [ $str = 4 ]; then
    value=$(expr $info / 1024 / 1024 / 1024 / 1024)TB
  elif [ $str = 5 ]; then
    value=$(expr $info / 1024 / 1024 / 1024 / 1024 / 1024)PB
  fi
}

START_TIME=$(date +%s)

while true; do
  CURRENT_TIME=$(date +%s)
  TIME_PASSED=$((CURRENT_TIME - START_TIME))

  NIC_RX=$(cat "/sys/class/net/${interface}/statistics/rx_bytes")
  NIC_TX=$(cat "/sys/class/net/${interface}/statistics/tx_bytes")
  NIC=$(expr $NIC_RX + $NIC_TX)
  echo ${NIC} > ./all-now
  echo ${NIC_TX} > ./tx-now
  echo ${NIC_RX} > ./rx-now
  rx=$(cat ./rx)
  tx=$(cat ./tx)
  all=$(cat ./all)
  NIC_RX_ALL=$(expr ${NIC_RX} + ${rx})
  NIC_TX_ALL=$(expr ${NIC_TX} + ${tx})
  NIC_ALL=$(expr ${NIC} + ${all})
  str=${#NIC_RX_ALL} && info=${NIC_RX_ALL} && calculate && NIC_RX_ALL=$value
  str=${#NIC_TX_ALL} && info=${NIC_TX_ALL} && calculate && NIC_TX_ALL=$value
  str=${#NIC_ALL} && info=${NIC_ALL} && calculate && NIC_ALL=$value

  CPU_USAGE=$(top -b -n 1 | grep Cpu | awk '{print $2}' | cut -f 1 -d "%" | sed 's/\..*//g')
  CPU_SYS=$(top -b -n 1 | grep Cpu | awk '{print $4}' | cut -f 1 -d "%" | sed 's/\..*//g')
  CPU=$(expr $CPU_USAGE + $CPU_SYS)

  MEM_TOTAL=$(free -m | awk -F '[ :]+' 'NR==2{print $2}')
  MEM_USER=$(free -m | awk -F '[ :]+' 'NR==2{print $3}')
  MEM=$(expr $MEM_USER \* 100 / $MEM_TOTAL)

  clear
  echo "网卡流量监控"
  echo "----------------------------------------"
  echo "网卡: $interface"
  echo "发送: ${NIC_TX_ALL}  接收: ${NIC_RX_ALL}  总流量: ${NIC_ALL}"
  echo "CPU使用率:${CPU}%  内存使用率: ${MEM}%"
  echo "{" > ./traffic
  echo "  \"in\": \"${NIC_RX_ALL}\","  >> ./traffic
  echo "  \"out\": \"${NIC_TX_ALL}\"," >> ./traffic
  echo "  \"all\": \"${NIC_ALL}\"," >> ./traffic
  echo "  \"cpu\": \"${CPU}%\"," >> ./traffic
  echo "  \"mem\": \"${MEM}%\"," >> ./traffic
  echo "  \"last_exec_time\": \"$(date '+%Y-%m-%d %H:%M:%S')\"" >> ./traffic
  echo "}" >> ./traffic

  sleep 10
done
EOF

# 使脚本可执行
chmod +x /root/traffic.sh

# 启用并启动 traffic 服务
systemctl enable --now traffic

# 设置时区为亚洲/上海
timedatectl set-timezone Asia/Shanghai
#后台运行
nohup bash /root/traffic.sh &
echo "设置完成。流量监控服务已启用。可以通过 bash /root/traffic.sh 来直接运行"
