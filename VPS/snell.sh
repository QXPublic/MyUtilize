#!/usr/bin/env bash

# 在遇到错误时立即退出
set -e
# 管道中的任何一个命令失败，则整个管道失败
set -o pipefail

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Snell Server 管理脚本 (优化版)
#=================================================

# --- 全局变量和配置 ---
readonly sh_ver="1.8.4-optimized"
readonly snell_v2_version="2.0.6"
readonly snell_v3_version="3.0.1"
readonly snell_v4_version="4.1.1"
readonly snell_v5_version="5.0.0"

readonly snell_dir="/etc/snell/"
readonly snell_bin="/usr/local/bin/snell-server"
readonly snell_conf="/etc/snell/config.conf"
readonly snell_version_file="/etc/snell/ver.txt"
readonly sysctl_conf="/etc/sysctl.d/local.conf"
readonly cache_file="/tmp/snell_version_cache"

# --- 颜色定义 ---
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
Yellow_font_prefix="\033[0;33m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Yellow_font_prefix}[注意]${Font_color_suffix}"

# --- 核心功能函数 ---

# 检查是否为 Root 用户
checkRoot(){
	[[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号，无法继续操作！" && exit 1
}

# 检查系统类型
checkSys(){
	if [[ -f /etc/os-release ]]; then
		source /etc/os-release
		if [[ $ID == "debian" || $ID_LIKE == "debian" ]]; then
			release="debian"
		elif [[ $ID == "centos" || $ID_LIKE == "rhel" || $ID_LIKE == "fedora" ]]; then
			release="centos"
		else
			echo -e "${Error} 不支持的操作系统: $ID"
			exit 1
		fi
	else
		echo -e "${Error} 无法检测到操作系统版本！"
		exit 1
	fi
}

# 检查并安装依赖
installDependencies(){
	local deps=("wget" "unzip" "curl" "jq" "ss")
	local missing_deps=()
	for cmd in "${deps[@]}"; do
		if ! command -v "$cmd" &> /dev/null; then
			missing_deps+=("$cmd")
		fi
	done

	if [[ ${#missing_deps[@]} -gt 0 ]]; then
		echo -e "${Info} 正在安装缺失的依赖: ${missing_deps[*]}"
		if [[ ${release} == "centos" ]]; then
			yum update && yum install -y "${missing_deps[@]}"
		else
			apt-get update && apt-get install -y "${missing_deps[@]}"
		fi
	fi
	echo -e "${Info} 依赖检查完成。"
}


# 检查系统架构
getSysArch() {
	local uname_arch
	uname_arch=$(uname -m)
	case "$uname_arch" in
		"i686" | "i386") arch="i386" ;;
		*"armv7"* | "armv6l") arch="armv7l" ;;
		*"armv8"* | "aarch64") arch="aarch64" ;;
		*) arch="amd64" ;;
	esac
}

# 优化 sysctl 配置
optimize_sysctl() {
	declare -A sysctl_settings=(
		["fs.file-max"]="51200"
		["net.core.rmem_max"]="67108864"
		["net.core.wmem_max"]="67108864"
		["net.core.netdev_max_backlog"]="4096"
		["net.core.somaxconn"]="4096"
		["net.ipv4.tcp_syncookies"]="1"
		["net.ipv4.tcp_tw_reuse"]="1"
		["net.ipv4.tcp_fin_timeout"]="30"
		["net.ipv4.tcp_keepalive_time"]="1200"
		["net.ipv4.ip_local_port_range"]="10000 65000"
		["net.ipv4.tcp_max_syn_backlog"]="4096"
		["net.ipv4.tcp_max_tw_buckets"]="5000"
		["net.ipv4.tcp_fastopen"]="3"
		["net.ipv4.tcp_mtu_probing"]="1"
		["net.ipv4.tcp_congestion_control"]="bbr"
		["net.core.default_qdisc"]="fq"
	)

	touch "${sysctl_conf}"
	echo -e "${Info} 正在优化网络参数..."
	for key in "${!sysctl_settings[@]}"; do
		local value="${sysctl_settings[$key]}"
		if grep -q "^\s*${key}\s*=" "${sysctl_conf}"; then
			# 如果存在则修改
			sed -i "s/^\s*${key}\s*=.*/${key} = ${value}/" "${sysctl_conf}"
		else
			# 如果不存在则追加
			echo "${key} = ${value}" >> "${sysctl_conf}"
		fi
	done
	sysctl --system >/dev/null 2>&1
}


# 开启 TCP Fast Open
enableTCPFastOpen() {
	local kernel_major
	kernel_major=$(uname -r | cut -d. -f1)
	if [[ "$kernel_major" -ge 3 ]]; then
		echo 3 > /proc/sys/net/ipv4/tcp_fastopen
		optimize_sysctl
	else
		echo -e "${Error} 系统内核版本过低，无法支持 TCP Fast Open！"
	fi
}

# 检查 Snell 是否安装
checkInstalledStatus(){
	[[ ! -f ${snell_bin} ]] && echo -e "${Error} Snell Server 没有安装，请检查！" && exit 1
}

# 检查 Snell 运行状态
checkStatus(){
	if systemctl is-active --quiet snell-server.service; then
		status="running"
	else
		status="stopped"
	fi
}

# 获取 Snell 下载链接
getSnellDownloadUrl(){
	local version=$1
	snell_url="https://dl.nssurge.com/snell/snell-server-v${version}-linux-${arch}.zip"
}

# 通用下载并安装 Snell 函数
downloadSnell(){
	local version=$1
	local version_type=$2

	echo -e "${Info} 开始下载 ${Yellow_font_prefix}${version_type}${Font_color_suffix} (v${version})..."
	
	if [[ $version_type =~ "v2" || $version_type =~ "v3" ]]; then
		# v2 和 v3 使用 GitHub 备份源
		snell_url="https://raw.githubusercontent.com/xOS/Others/master/snell/v${version}/snell-server-v${version}-linux-${arch}.zip"
	else
		getSnellDownloadUrl "${version}"
		# 检查官方链接是否有效
		if ! curl -s --head --fail --max-time 10 "${snell_url}" > /dev/null; then
			echo -e "${Error} Snell Server ${version_type} 下载链接无效 (404)！"
			return 1
		fi
	fi
	
	wget -O "snell.zip" "${snell_url}"
	unzip -o "snell.zip"
	rm -f "snell.zip"
	
	if [[ ! -f "snell-server" ]]; then
		echo -e "${Error} Snell Server 解压失败！"
		return 1
	fi
	
	chmod +x snell-server
	mv -f snell-server "${snell_bin}"
	echo "v${version}" > "${snell_version_file}"
	echo -e "${Info} Snell Server 主程序安装成功！"
}


# --- 配置设置函数 ---

# 设置端口
setPort(){
	while true; do
		read -e -p "请输入 Snell Server 端口 [1-65535] (默认: 2345): " port
		[[ -z "${port}" ]] && port="2345"
		if [[ $port -ge 1 && $port -le 65535 ]] && ! ss -tuln | grep -q ":${port}\s"; then
			break
		else
			echo -e "${Error} 端口无效或已被占用，请重新输入。"
		fi
	done
}

# 设置密钥
setPSK(){
	read -e -p "请输入 Snell Server 密钥 (留空则随机生成): " psk
	[[ -z "${psk}" ]] && psk=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)
}

# 设置 OBFS
setObfs(){
	echo "请选择 OBFS 模式: 1. TLS  2. HTTP  3. 关闭"
	read -e -p "(默认: 3.关闭): " obfs_choice
	case "$obfs_choice" in
		1) obfs="tls"; setHost ;;
		2) obfs="http"; setHost ;;
		*) obfs="off"; host="" ;;
	esac
}

# 设置 OBFS 域名
setHost(){
	read -e -p "请输入 OBFS 域名 (默认: icloud.com): " host
	[[ -z "${host}" ]] && host="icloud.com"
}

# 设置 TCP Fast Open
setTFO(){
	read -e -p "是否开启 TCP Fast Open? [Y/n]: " tfo_choice
	if [[ ${tfo_choice,,} == "n" ]]; then
		tfo="false"
	else
		tfo="true"
		enableTCPFastOpen
	fi
}

# 设置 DNS
setDNS(){
	read -e -p "请输入 DNS (多条以逗号隔开, 默认: 1.1.1.1,8.8.8.8): " dns
	[[ -z "${dns}" ]] && dns="1.1.1.1, 8.8.8.8, 2001:4860:4860::8888"
}

# 写入配置文件
writeConfig(){
	if [[ -f "${snell_conf}" ]]; then
		mv "${snell_conf}" "${snell_conf}.bak.$(date +%Y%m%d_%H%M%S)"
		echo -e "${Info} 旧配置文件已备份。"
	fi

	cat > "${snell_conf}" << EOF
[snell-server]
listen = ::0:${port}
ipv6 = true
psk = ${psk}
obfs = ${obfs}
$(if [[ ${obfs} != "off" ]]; then echo "obfs-host = ${host}"; fi)
tfo = ${tfo}
dns = ${dns}
version = ${ver}
EOF
}

# 读取配置文件
readConfig(){
	[[ ! -f ${snell_conf} ]] && echo -e "${Error} Snell 配置文件不存在！" && exit 1
	port=$(grep -E '^listen\s*=' ${snell_conf} | awk -F ':' '{print $NF}' | xargs)
	psk=$(grep -E '^psk\s*=' ${snell_conf} | awk -F '= ' '{print $NF}')
	obfs=$(grep -E '^obfs\s*=' ${snell_conf} | awk -F '= ' '{print $NF}')
	host=$(grep -E '^obfs-host\s*=' ${snell_conf} | awk -F '= ' '{print $NF}')
	tfo=$(grep -E '^tfo\s*=' ${snell_conf} | awk -F '= ' '{print $NF}')
	dns=$(grep -E '^dns\s*=' ${snell_conf} | awk -F '= ' '{print $NF}')
	ver=$(grep -E '^version\s*=' ${snell_conf} | awk -F '= ' '{print $NF}')
}

# 配置服务
setupService(){
	cat > /etc/systemd/system/snell-server.service <<'EOF'
[Unit]
Description=Snell Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
LimitNOFILE=51200
ExecStart=/usr/local/bin/snell-server -c /etc/snell/config.conf

[Install]
WantedBy=multi-user.target
EOF
	systemctl daemon-reload
	systemctl enable --now snell-server
	echo -e "${Info} Snell Server 服务配置完成！"
}

# --- 主要操作函数 ---

# 通用的安装流程
do_install(){
	local version_code=$1
	local version_tag=""
	local download_version=""

	case "$version_code" in
		2) version_tag="v2"; download_version="${snell_v2_version}" ;;
		3) version_tag="v3"; download_version="${snell_v3_version}" ;;
		4) version_tag="v4"; download_version="${snell_v4_version}" ;;
		5) version_tag="v5"; download_version="${snell_v5_version}" ;;
		*) echo -e "${Error} 无效的版本选择！"; exit 1 ;;
	esac
	ver=${version_code} # 全局变量，用于写入配置

	checkRoot
	[[ -f ${snell_bin} ]] && echo -e "${Error} 检测到 Snell Server 已安装！" && exit 1

	echo -e "${Info} 开始配置 Snell ${version_tag}..."
	setPort
	setPSK
	setObfs
	setTFO
	[[ ${ver} -ge 4 ]] && setDNS

	echo -e "${Info} 开始安装依赖..."
	installDependencies
	
	echo -e "${Info} 开始下载安装主程序..."
	if ! downloadSnell "${download_version}" "${version_tag}"; then
		echo -e "${Error} 主程序下载失败，安装中止。"
		exit 1
	fi

	echo -e "${Info} 开始写入配置文件..."
	writeConfig
	
	echo -e "${Info} 开始配置并启动服务..."
	setupService

	echo -e "${Info} Snell ${version_tag} 安装成功！"
	sleep 2
	viewConfig
}

# 安装 Snell
installSnell() {
	echo "请选择要安装的 Snell 版本 [2-5]"
	echo " 2. v2   3. v3   4. v4   5. v5"
	read -e -p "(默认: 4): " ver_choice
	[[ -z "${ver_choice}" ]] && ver_choice="4"
	
	do_install "${ver_choice}"
}

# 卸载 Snell
uninstallSnell(){
	checkInstalledStatus
	read -e -p "确定要卸载 Snell Server? [y/N]: " confirm
	if [[ ${confirm,,} == "y" ]]; then
		systemctl stop snell-server
		systemctl disable snell-server
		rm -f /etc/systemd/system/snell-server.service
		rm -f "${snell_bin}"
		# 保留配置文件
		echo -e "${Info} Snell Server 卸载完成！配置文件保留在 ${snell_dir}"
	else
		echo "卸载已取消。"
	fi
	beforeStartMenu
}

# 启动 Snell
startSnell(){
	checkInstalledStatus
	systemctl start snell-server
	echo -e "${Info} Snell Server 已启动。"
	beforeStartMenu
}

# 停止 Snell
stopSnell(){
	checkInstalledStatus
	systemctl stop snell-server
	echo -e "${Info} Snell Server 已停止。"
	beforeStartMenu
}

# 重启 Snell
restartSnell(){
	checkInstalledStatus
	systemctl restart snell-server
	echo -e "${Info} Snell Server 已重启。"
	beforeStartMenu
}

# 查看配置信息
viewConfig(){
	checkInstalledStatus
	readConfig
	local ipv4 ipv6
	ipv4=$(curl -s -4 --max-time 2 ip.sb)
	ipv6=$(curl -s -6 --max-time 2 ip.sb)
	
	clear && echo
	echo -e "--- Snell Server 配置信息 ---"
	[[ -n "$ipv4" ]] && echo -e " IPv4 地址 : ${Green_font_prefix}${ipv4}${Font_color_suffix}"
	[[ -n "$ipv6" ]] && echo -e " IPv6 地址 : ${Green_font_prefix}${ipv6}${Font_color_suffix}"
	echo -e " 端口      : ${Green_font_prefix}${port}${Font_color_suffix}"
	echo -e " 密钥      : ${Green_font_prefix}${psk}${Font_color_suffix}"
	echo -e " OBFS 模式 : ${Green_font_prefix}${obfs}${Font_color_suffix}"
	[[ "$obfs" != "off" ]] && echo -e " OBFS 域名 : ${Green_font_prefix}${host}${Font_color_suffix}"
	echo -e " TFO       : ${Green_font_prefix}${tfo}${Font_color_suffix}"
	[[ ${ver} -ge 4 ]] && echo -e " DNS       : ${Green_font_prefix}${dns}${Font_color_suffix}"
	echo -e " 版本      : ${Green_font_prefix}${ver}${Font_color_suffix}"
	echo "--------------------------------"

	local ip_addr=${ipv4:-"[$ipv6]"}
	local surge_conf="$(uname -n) = snell, ${ip_addr}, ${port}, psk=${psk}, version=${ver}, tfo=${tfo}, reuse=true, ecn=true"
	if [[ "$obfs" != "off" ]]; then
		surge_conf+=", obfs=${obfs}, obfs-host=${host}"
	fi
	echo -e "${Info} Surge 配置:"
	echo -e "${Green_background_prefix}${surge_conf}${Font_color_suffix}"
	echo "--------------------------------"
	beforeStartMenu
}

# 查看运行状态
viewStatus(){
	checkInstalledStatus
	systemctl status snell-server
	beforeStartMenu
}

# 更新脚本
updateShell(){
	echo -e "当前版本为 [ ${sh_ver} ]，开始检测最新版本..."
	local shell_url="https://raw.githubusercontent.com/xOS/Snell/master/Snell.sh"
	local sh_new_ver
	sh_new_ver=$(curl -s "${shell_url}" | grep 'sh_ver="' | awk -F'"' '{print $2}')
	
	if [[ -z ${sh_new_ver} ]]; then
		echo -e "${Error} 检测最新版本失败！"
	elif [[ ${sh_new_ver} != ${sh_ver} ]]; then
		echo -e "发现新版本 [ ${sh_new_ver} ]，是否更新？[Y/n]"
		read -p "(默认: y):" yn
		if [[ ${yn,,} != "n" ]]; then
			wget -O "$0" "${shell_url}"
			echo -e "脚本已更新为最新版本 [ ${sh_new_ver} ]！正在执行新脚本..."
			sleep 2
			exec bash "$0"
		else
			echo "已取消更新。"
		fi
	else
		echo -e "当前已是最新版本 [ ${sh_new_ver} ]！"
	fi
	beforeStartMenu
}


# --- 主菜单 ---

# 返回主菜单前提示
beforeStartMenu() {
	echo && read -n 1 -s -r -p "按任意键返回主菜单..."
	startMenu
}

# 主菜单
startMenu(){
	clear
	getSysArch
	
	local is_installed=false
	if [[ -f ${snell_bin} ]]; then
		is_installed=true
		checkStatus
	fi

	echo "=============================="
	echo "Snell Server 管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}"
	echo "=============================="
	
	if ${is_installed}; then
		local current_ver
		current_ver=$(grep -E '^version\s*=' "${snell_conf}" | awk '{print $NF}')
		echo -e " 当前状态: ${Green_font_prefix}已安装 (v${current_ver})${Font_color_suffix} | 运行状态: ${status}"
	else
		echo -e " 当前状态: ${Red_font_prefix}未安装${Font_color_suffix}"
	fi
	echo "------------------------------"

	# 动态构建菜单
	local menu_options=()
	if ${is_installed}; then
		menu_options+=(" 1. 查看配置信息" " 2. 修改配置 (待实现)" " 3. 重启 Snell" " 4. 停止 Snell" " 5. 卸载 Snell")
	else
		menu_options+=(" 1. 安装 Snell Server")
	fi
	menu_options+=(" 8. 查看运行状态" " 9. 更新脚本" " 0. 退出脚本")

	# 显示菜单
	for option in "${menu_options[@]}"; do
		echo "${Green_font_prefix}${option}${Font_color_suffix}"
	done
	echo "=============================="

	read -e -p "请输入数字: " num

	if ${is_installed}; then
		case "$num" in
			1) viewConfig ;;
			3) restartSnell ;;
			4) stopSnell ;;
			5) uninstallSnell ;;
			8) viewStatus ;;
			9) updateShell ;;
			0) exit 0 ;;
			*) echo "无效输入" && sleep 1 && startMenu ;;
		esac
	else
		case "$num" in
			1) installSnell ;;
			8) viewStatus 2>/dev/null || (echo -e "${Error} Snell 未安装" && sleep 2 && startMenu) ;;
			9) updateShell ;;
			0) exit 0 ;;
			*) echo "无效输入" && sleep 1 && startMenu ;;
		esac
	fi
}

# --- 脚本入口 ---
checkRoot
checkSys
startMenu "$@"
