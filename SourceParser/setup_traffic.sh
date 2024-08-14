#!/bin/bash

# 定义网络接口
INTERFACE="eth0"

# 更新和升级系统
echo "更新和升级系统..."
apt update && apt upgrade -y

# 安装 Caddy
echo "安装 Caddy..."
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo tee /etc/apt/trusted.gpg.d/caddy-stable.asc >/dev/null
echo "deb [trusted=yes] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install caddy -y

# 编写服务文件
echo "编写服务配置..."
cat <<EOF >/etc/systemd/system/traffic.service
[Unit]
Description=traffic
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/
ExecStart=/root/traffic.sh ${INTERFACE}
Restart=on-failure
RestartSec=30s

[Install]
WantedBy=multi-user.target
EOF

# 编写运行程序
echo "编写运行脚本..."
cat <<'EOF' >/root/traffic.sh
#!/bin/sh

if [ "$1" == "--help" ];then
  cat << HELP
$0 网卡名称
--help 打印帮助菜单
HELP
fi

if [ -z "$1" ];then
  interface="eth0"
else
  interface=$1
fi

if [ "$(cat /proc/uptime | awk '{print $1}' | sed 's/\..*//g')" -lt "120" ]; then
  [ -n "$(cat ./all)" ] && expr "$(cat ./all)" + "$(cat ./all-now)" > ./all || echo "1" > ./all
  [ -n "$(cat ./tx)" ] && expr "$(cat ./tx)" + "$(cat ./tx-now)" > ./tx || echo "1" > ./tx
  [ -n "$(cat ./rx)" ] && expr "$(cat ./rx)" + "$(cat ./rx-now)" > ./rx || echo "1" > ./rx
else
  [ -z "$(cat ./all)" ] && echo "1" > ./all
  [ -z "$(cat ./tx)" ] && echo "1" > ./tx
  [ -z "$(cat ./rx)" ] && echo "1" > ./rx
fi

nohup caddy file-server --browse --listen :49155 &

calculate() {
  str=`expr $str + 2`
  str=`expr $str / 4`
  value="$info"B
  [ $str = 1 ] && value=`expr $info / 1024`KB
  [ $str = 2 ] && value=`expr $info / 1024 / 1024`MB
  [ $str = 3 ] && value=`expr $info / 1024 / 1024 / 1024`GB
  [ $str = 4 ] && value=`expr $info / 1024 / 1024 / 1024 / 1024`TB
  [ $str = 5 ] && value=`expr $info / 1024 / 1024 / 1024 / 1024 / 1024`PB
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
  MEM=$(expr $MEM_USER \* 100 / $MEM_TOTAL )

  clear
  echo "网卡流量监控"
  echo "----------------------------------------"
  echo "网卡: $interface"
  echo "发送: ${NIC_TX_ALL}  接收: ${NIC_RX_ALL}  总流量: ${NIC_ALL}"
  echo "CPU使用率:${CPU}%  内存使用率: ${MEM}%"
  echo "{" > ./traffic
  echo "  \"in\": \"${NIC_RX_ALL}\"," >> ./traffic
  echo "  \"out\": \"${NIC_TX_ALL}\"," >> ./traffic
  echo "  \"all\": \"${NIC_ALL}\"," >> ./traffic
  echo "  \"cpu\": \"${CPU}%\"," >> ./traffic
  echo "  \"mem\": \"${MEM}%\"," >> ./traffic
  echo "  \"last_exec_time\": \"$(date '+%Y-%m-%d %H:%M:%S')\"" >> ./traffic
  echo "}" >> ./traffic

  sleep 10
done
EOF

# 设置脚本权限
chmod +x /root/traffic.sh

# 启动并启用服务
echo "启动并启用服务..."
systemctl enable --now traffic.service

echo "所有步骤完成。一键搭建脚本执行完毕。可通过systemctl status traffic查看服务状态"
