#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Snell Server 管理脚本
#	Author: 翠花
#	WebSite: https://about.nange.cn
#=================================================

sh_ver="1.8.4"
snell_v2_version="2.0.6"
snell_v3_version="3.0.1"
snell_v4_version="4.1.1"
snell_v5_version="5.0.0"
script_dir=$(cd "$(dirname "$0")"; pwd)
script_path=$(echo -e "${script_dir}"|awk -F "$0" '{print $1}')
snell_dir="/etc/snell/"
snell_bin="/usr/local/bin/snell-server"
snell_conf="/etc/snell/config.conf"
snell_version_file="/etc/snell/ver.txt"
sysctl_conf="/etc/sysctl.d/local.conf"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m" && Yellow_font_prefix="\033[0;33m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Yellow_font_prefix}[注意]${Font_color_suffix}"

# 检查是否为 Root 用户
checkRoot(){
	[[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}

# 检查系统类型
checkSys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
}

# 检查依赖
checkDependencies(){
    local deps=("wget" "unzip" "ss")
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${Error} 缺少依赖: $cmd，正在尝试安装..."
            if [[ -f /etc/debian_version ]]; then
                apt-get update && apt-get install -y "$cmd"
            elif [[ -f /etc/redhat-release ]]; then
                yum install -y "$cmd"
            else
                echo -e "${Error} 不支持的系统，无法自动安装 $cmd"
                exit 1
            fi
        fi
    done
    echo -e "${Info} 依赖检查完成"
}

# 安装依赖
installDependencies(){
	if [[ ${release} == "centos" ]]; then
		yum update
		yum install gzip wget curl unzip jq -y
	else
		apt-get update
		apt-get install gzip wget curl unzip jq -y
	fi
	sysctl -w net.core.rmem_max=26214400
	sysctl -w net.core.rmem_default=26214400
	\cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	echo -e "${Info} 依赖安装完成"
}

# 检查系统架构
sysArch() {
    uname=$(uname -m)
    if [[ "$uname" == "i686" ]] || [[ "$uname" == "i386" ]]; then
        arch="i386"
    elif [[ "$uname" == *"armv7"* ]] || [[ "$uname" == "armv6l" ]]; then
        arch="armv7l"
    elif [[ "$uname" == *"armv8"* ]] || [[ "$uname" == "aarch64" ]]; then
        arch="aarch64"
    else
        arch="amd64"
    fi    
}

# 开启 TCP Fast Open
enableTCPFastOpen() {
	kernel=$(uname -r | awk -F . '{print $1}')
	if [ "$kernel" -ge 3 ]; then
		echo 3 >/proc/sys/net/ipv4/tcp_fastopen
		[[ ! -e $sysctl_conf ]] && echo "fs.file-max = 51200
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 65536
net.core.wmem_default = 65536
net.core.netdev_max_backlog = 4096
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_ecn=1
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control = bbr" >>/etc/sysctl.d/local.conf && sysctl --system >/dev/null 2>&1
	else
		echo -e "$Error 系统内核版本过低，无法支持 TCP Fast Open！"
	fi
}

# 检查 Snell 是否安装
checkInstalledStatus(){
	[[ ! -e ${snell_bin} ]] && echo -e "${Error} Snell Server 没有安装，请检查！" && exit 1
}

# 检查 Snell 运行状态
checkStatus(){
    if systemctl is-active snell-server.service &> /dev/null; then
        status="running"
    else
        status="stopped"
    fi
}

# 版本号比较函数（优先正式版）
compareVersions(){
    local version1="$1"
    local version2="$2"
    
    # 移除版本号前缀 v
    version1=$(echo "$version1" | sed 's/^v//')
    version2=$(echo "$version2" | sed 's/^v//')
    
    # 如果版本号完全相同
    if [[ "$version1" == "$version2" ]]; then
        return 1  # 相等
    fi
    
    # 提取基础版本号（去除测试版后缀）
    local base_version1=$(echo "$version1" | sed 's/[a-z].*//')
    local base_version2=$(echo "$version2" | sed 's/[a-z].*//')
    
    # 检查是否为测试版
    local is_beta1=false
    local is_beta2=false
    [[ "$version1" =~ [a-z] ]] && is_beta1=true
    [[ "$version2" =~ [a-z] ]] && is_beta2=true
    
    # 如果基础版本号相同
    if [[ "$base_version1" == "$base_version2" ]]; then
        # 优先选择正式版
        if [[ "$is_beta1" == true && "$is_beta2" == false ]]; then
            return 2  # version1 < version2(正式版优先)
        elif [[ "$is_beta1" == false && "$is_beta2" == true ]]; then
            return 0  # version1 > version2(正式版优先)
        fi
        # 如果都是测试版或都是正式版，使用字母序比较
        if [[ "$version1" < "$version2" ]]; then
            return 2
        else
            return 0
        fi
    fi
    
    # 基础版本号不同时，使用 sort -V 进行版本号比较
    if printf '%s\n' "$base_version1" "$base_version2" | sort -V | head -1 | grep -q "^$base_version1$"; then
        return 2  # version1 < version2
    else
        return 0  # version1 > version2
    fi
}

# 验证版本 URL 是否有效
validateVersionUrl(){
    local version="$1"
    getSnellDownloadUrl "$version"
    
    # 使用 HEAD 请求检查 URL 是否有效
    if curl -I -s --max-time 10 "$snell_url" | head -1 | grep -q "200 OK"; then
        return 0  # URL 有效
    else
        return 1  # URL 无效
    fi
}

# 检查版本更新
checkVersionUpdate(){
    local show_info=${1:-false}  # 是否显示详细信息，默认为静默
    update_available=false
    current_installed_version=""
    latest_available_version=""
    best_version=""
    
    if [[ -e ${snell_bin} && -e ${snell_conf} ]]; then
        current_ver=$(cat ${snell_conf}|grep 'version = '|awk -F 'version = ' '{print $NF}')
        
        # v2 和 v3 不支持版本检查，直接返回
        if [[ "$current_ver" == "2" || "$current_ver" == "3" ]]; then
            update_available=false
            return 0
        fi
        
        if [[ -e ${snell_version_file} ]]; then
            installed_version=$(cat ${snell_version_file} | sed 's/^v//')
            current_installed_version="$installed_version"
            
            # 根据当前版本确定对应的脚本版本和网页版本
            case "$current_ver" in
                "4")
                    script_version=${snell_v4_version}
                    web_version=$(getLatestVersionFromWeb "v4")
                    ;;
                "5")
                    script_version=${snell_v5_version}
                    web_version=$(getLatestVersionFromWeb "v5")
                    ;;
                *)
                    script_version=""
                    web_version=""
                    ;;
            esac
            
            # 优先使用脚本内置版本，除非网页版本更新
            best_version="$installed_version"
            version_source="已安装"
            
            # 首先比较脚本内置版本
            if [[ -n "$script_version" ]]; then
                compareVersions "$best_version" "$script_version"
                case $? in
                    2)  # best_version < script_version
                        # 验证脚本内置版本的 URL 是否有效
                        if validateVersionUrl "$script_version"; then
                            best_version="$script_version"
                            version_source="脚本内置"
                        else
                            [[ "$show_info" == true ]] && echo -e "${Tip} 脚本内置版本 v${script_version} 的下载链接无效，跳过"
                        fi
                        ;;
                esac
            fi
            
            # 然后比较网页版本，只有当网页版本比当前最佳版本更新时才采用
            if [[ -n "$web_version" ]]; then
                compareVersions "$best_version" "$web_version"
                case $? in
                    2)  # best_version < web_version
                        # 验证网页版本的 URL 是否有效
                        if validateVersionUrl "$web_version"; then
                            best_version="$web_version"
                            version_source="官方网页"
                        else
                            [[ "$show_info" == true ]] && echo -e "${Tip} 网页版本 v${web_version} 的下载链接无效，使用脚本内置版本"
                        fi
                        ;;
                    1|0)  # best_version >= web_version
                        # 脚本内置版本优先，无需显示
                        ;;
                esac
            fi
            
            latest_available_version="$best_version"
            
            # 如果最佳版本与当前安装版本不同，则有更新可用
            compareVersions "$installed_version" "$best_version"
            if [[ $? -eq 2 ]]; then
                update_available=true
                if [[ "$show_info" == true ]]; then
                    echo -e "${Info} 发现更新：当前版本 v${installed_version} -> 最新版本 v${best_version}"
                    echo -e "${Info} 更新版本来源：${version_source}"
                fi
            fi
        fi
    fi
}


# 获取 Snell 下载链接
getSnellDownloadUrl(){
	sysArch
	local version=$1
	snell_url="https://dl.nssurge.com/snell/snell-server-v${version}-linux-${arch}.zip"
}



# 下载并安装 Snell v2（备用源）
# 下载并安装 Snell v2（GitHub 备份源）
downloadSnellV2() {
    downloadSnellFromGitHub "${snell_v2_version}" "v2 GitHub备份源版"
}

# 下载并安装 Snell v3（GitHub 备份源）
downloadSnellV3() {
    downloadSnellFromGitHub "${snell_v3_version}" "v3 GitHub备份源版"
}

# 通用下载并安装 Snell 函数（GitHub 备份源）
downloadSnellFromGitHub(){
    local version=$1
    local version_type=$2
    
    echo -e "${Info} 试图请求 ${Yellow_font_prefix}${version_type}${Font_color_suffix} Snell Server ……"
    
    local backup_url="https://raw.githubusercontent.com/xOS/Others/master/snell/v${version}/snell-server-v${version}-linux-${arch}.zip"
    
    wget --no-check-certificate -N "${backup_url}"
    if [[ ! -e "snell-server-v${version}-linux-${arch}.zip" ]]; then
        echo -e "${Error} Snell Server ${Yellow_font_prefix}${version_type}${Font_color_suffix} 下载失败！"
        return 1
    fi
    
    unzip -o "snell-server-v${version}-linux-${arch}.zip"
    if [[ ! -e "snell-server" ]]; then
        echo -e "${Error} Snell Server ${Yellow_font_prefix}${version_type}${Font_color_suffix} 解压失败！"
        return 1
    fi
    
    rm -rf "snell-server-v${version}-linux-${arch}.zip"
    chmod +x snell-server
    mv -f snell-server "${snell_bin}"
    echo "v${version}" > "${snell_version_file}"
    echo -e "${Info} Snell Server 主程序下载安装完毕！"
    return 0
}

# 下载并安装 Snell v4（官方源）
downloadSnellV4(){
	downloadSnell "${snell_v4_version}" "v4 官网源版"
}

# 下载并安装 Snell v5（官方源）
downloadSnellV5(){
	downloadSnell "${snell_v5_version}" "v5 官网源版"
}

# 通用下载并安装 Snell 函数（带回退机制）
downloadSnell(){
	local version=$1
	local version_type=$2
	local allow_fallback=${3:-false}
	local fallback_version=$4
	
	echo -e "${Info} 试图请求 ${Yellow_font_prefix}${version_type}${Font_color_suffix} Snell Server ……"
	getSnellDownloadUrl "${version}"
	
	# 首先检查 URL 是否有效
	if ! curl -I -s --max-time 10 "$snell_url" | head -1 | grep -q "200 OK"; then
		echo -e "${Error} Snell Server ${Yellow_font_prefix}${version_type}${Font_color_suffix} 下载链接无效 (404)！"
		
		# 如果允许回退且提供了回退版本
		if [[ "$allow_fallback" == true && -n "$fallback_version" ]]; then
			echo -e "${Info} 尝试回退到已安装版本 v${fallback_version}..."
			getSnellDownloadUrl "${fallback_version}"
			if curl -I -s --max-time 10 "$snell_url" | head -1 | grep -q "200 OK"; then
				version="$fallback_version"
				echo -e "${Info} 回退成功，使用版本 v${version}"
			else
				echo -e "${Error} 回退版本也无法下载！"
				return 1
			fi
		else
			return 1
		fi
	fi
	
	wget --no-check-certificate -N "${snell_url}"
	if [[ ! -e "snell-server-v${version}-linux-${arch}.zip" ]]; then
		echo -e "${Error} Snell Server ${Yellow_font_prefix}${version_type}${Font_color_suffix} 下载失败！"
		return 1 && exit 1
	else
		unzip -o "snell-server-v${version}-linux-${arch}.zip"
	fi
	if [[ ! -e "snell-server" ]]; then
		echo -e "${Error} Snell Server ${Yellow_font_prefix}${version_type}${Font_color_suffix} 解压失败！"
		return 1 && exit 1
	else
		rm -rf "snell-server-v${version}-linux-${arch}.zip"
		chmod +x snell-server
		mv -f snell-server "${snell_bin}"
		echo "v${version}" > ${snell_version_file}
		echo -e "${Info} Snell Server 主程序下载安装完毕！"
		return 0
	fi
}

# 安装 Snell
installSnell() {
	if [[ ! -e "${snell_dir}" ]]; then
		mkdir "${snell_dir}"
	else
		[[ -e "${snell_bin}" ]] && rm -rf "${snell_bin}"
	fi
	echo -e "选择安装版本${Yellow_font_prefix}[2-5]${Font_color_suffix} 
==================================
${Green_font_prefix} 2.${Font_color_suffix} v2  ${Green_font_prefix} 3.${Font_color_suffix} v3  ${Green_font_prefix} 4.${Font_color_suffix} v4  ${Green_font_prefix} 5.${Font_color_suffix} v5
=================================="
	read -e -p "(默认：4.v4)：" ver
	[[ -z "${ver}" ]] && ver="4"
	if [[ ${ver} == "2" ]]; then
		installSnellV2
	elif [[ ${ver} == "3" ]]; then
		installSnellV3
	elif [[ ${ver} == "4" ]]; then
		installSnellV4
	elif [[ ${ver} == "5" ]]; then
		installSnellV5
	else
		installSnellV4
	fi
}

# 配置服务
setupService(){
	echo '
[Unit]
Description=Snell Service
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service
[Service]
LimitNOFILE=32767 
Type=simple
User=root
Restart=on-failure
RestartSec=5s
ExecStartPre=/bin/sh -c 'ulimit -n 51200'
ExecStart=/usr/local/bin/snell-server -c /etc/snell/config.conf
[Install]
WantedBy=multi-user.target' > /etc/systemd/system/snell-server.service
	systemctl enable --now snell-server
	echo -e "${Info} Snell Server 服务配置完成！"
}

# 写入配置文件
writeConfig(){
    if [[ -f "${snell_conf}" ]]; then
        cp "${snell_conf}" "${snell_conf}.bak.$(date +%Y%m%d_%H%M%S)"
        echo -e "${Info} 已备份旧配置文件到 ${snell_conf}.bak"
    fi
    cat > "${snell_conf}" << EOF
[snell-server]
listen = ::0:${port}
ipv6 = ${ipv6}
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
	[[ ! -e ${snell_conf} ]] && echo -e "${Error} Snell Server 配置文件不存在！" && exit 1
	ipv6=$(cat ${snell_conf}|grep 'ipv6 = '|awk -F 'ipv6 = ' '{print $NF}')
	port=$(grep -E '^listen\s*=' ${snell_conf} | awk -F ':' '{print $NF}' | xargs)
	psk=$(cat ${snell_conf}|grep 'psk = '|awk -F 'psk = ' '{print $NF}')
	obfs=$(cat ${snell_conf}|grep 'obfs = '|awk -F 'obfs = ' '{print $NF}')
	host=$(cat ${snell_conf}|grep 'obfs-host = '|awk -F 'obfs-host = ' '{print $NF}')
	tfo=$(cat ${snell_conf}|grep 'tfo = '|awk -F 'tfo = ' '{print $NF}')
	dns=$(cat ${snell_conf}|grep 'dns = '|awk -F 'dns = ' '{print $NF}')
	ver=$(cat ${snell_conf}|grep 'version = '|awk -F 'version = ' '{print $NF}')
}

# 设置端口
setPort(){
    while true; do
        echo -e "${Tip} 本步骤不涉及系统防火墙端口操作，请手动放行相应端口！"
        echo -e "请输入 Snell Server 端口${Yellow_font_prefix}[1-65535]${Font_color_suffix}"
        read -e -p "(默认: 2345):" port
        [[ -z "${port}" ]] && port="2345"
        if [[ $port =~ ^[0-9]+$ ]] && [[ $port -ge 1 && $port -le 65535 ]]; then
            if ss -tuln | grep -q ":$port "; then
                echo -e "${Error} 端口 $port 已被占用，请选择其他端口。"
            else
                echo && echo "=============================="
                echo -e "端口 : ${Red_background_prefix} ${port} ${Font_color_suffix}"
                echo "==============================" && echo
                break
            fi
        else
            echo "输入错误, 请输入正确的端口号。"
			sleep 2s
			setPort
        fi
    done
}


# 设置 IPv6
setIpv6(){
	echo -e "是否开启 IPv6 解析？
==================================
${Green_font_prefix} 1.${Font_color_suffix} 开启  ${Green_font_prefix} 2.${Font_color_suffix} 关闭
=================================="
	read -e -p "(默认：2.关闭)：" ipv6
	[[ -z "${ipv6}" ]] && ipv6="false"
	if [[ ${ipv6} == "1" ]]; then
		ipv6=true
	else
		ipv6=false
	fi
	echo && echo "=================================="
	echo -e "IPv6 解析 开启状态：${Red_background_prefix} ${ipv6} ${Font_color_suffix}"
	echo "==================================" && echo
}

# 设置密钥
setPSK(){
	echo "请输入 Snell Server 密钥 [0-9][a-z][A-Z] "
	read -e -p "(默认: 随机生成):" psk
	[[ -z "${psk}" ]] && psk=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)
	echo && echo "=============================="
	echo -e "密钥 : ${Red_background_prefix} ${psk} ${Font_color_suffix}"
	echo "==============================" && echo
}

# 设置 OBFS
setObfs(){
    echo -e "配置 OBFS，${Tip} 无特殊作用不建议启用该项。
==================================
${Green_font_prefix} 1.${Font_color_suffix} TLS  ${Green_font_prefix} 2.${Font_color_suffix} HTTP ${Green_font_prefix} 3.${Font_color_suffix} 关闭
=================================="
    read -e -p "(默认：3.关闭)：" obfs
    [[ -z "${obfs}" ]] && obfs="3"
    if [[ ${obfs} == "1" ]]; then
        obfs="tls"
        setHost  # 强制设置 OBFS 域名
    elif [[ ${obfs} == "2" ]]; then
        obfs="http"
        setHost  # 强制设置 OBFS 域名
    elif [[ ${obfs} == "3" ]]; then
        obfs="off"
        host=""  # 清空 host
    else
        obfs="off"
        host=""  # 清空 host
    fi
    echo && echo "=================================="
    echo -e "OBFS 状态：${Red_background_prefix} ${obfs} ${Font_color_suffix}"
    if [[ ${obfs} != "off" ]]; then
        echo -e "OBFS 域名：${Red_background_prefix} ${host} ${Font_color_suffix}"
    fi
    echo "==================================" && echo
}


# 设置协议版本
setVer(){
	echo -e "配置 Snell Server 协议版本${Yellow_font_prefix}[2-5]${Font_color_suffix} 
==================================
${Green_font_prefix} 2.${Font_color_suffix} v2 ${Green_font_prefix} 3.${Font_color_suffix} v3 ${Green_font_prefix} 4.${Font_color_suffix} v4 ${Green_font_prefix} 5.${Font_color_suffix} v5
=================================="
	read -e -p "(默认：4.v4)：" ver
	[[ -z "${ver}" ]] && ver="4"
	if [[ ${ver} == "2" ]]; then
		ver=2
	elif [[ ${ver} == "3" ]]; then
		ver=3
	elif [[ ${ver} == "4" ]]; then
		ver=4
	elif [[ ${ver} == "5" ]]; then
		ver=5
	else
		ver=4
	fi
	echo && echo "=================================="
	echo -e "Snell Server 协议版本：${Red_background_prefix} ${ver} ${Font_color_suffix}"
	echo "==================================" && echo
}

# 设置 OBFS 域名
setHost(){
	echo "请输入 Snell Server 域名，v4 版本及以上如无特别需求可忽略。"
	read -e -p "(默认: icloud.com):" host
	[[ -z "${host}" ]] && host=icloud.com
	echo && echo "=============================="
	echo -e "域名 : ${Red_background_prefix} ${host} ${Font_color_suffix}"
	echo "==============================" && echo
}

# 设置 TCP Fast Open
setTFO(){
	echo -e "是否开启 TCP Fast Open？
==================================
${Green_font_prefix} 1.${Font_color_suffix} 开启  ${Green_font_prefix} 2.${Font_color_suffix} 关闭
=================================="
	read -e -p "(默认：1.开启)：" tfo
	[[ -z "${tfo}" ]] && tfo="1"
	if [[ ${tfo} == "1" ]]; then
		tfo=true
		enableTCPFastOpen
	else
		tfo=false
	fi
	echo && echo "=================================="
	echo -e "TCP Fast Open 开启状态：${Red_background_prefix} ${tfo} ${Font_color_suffix}"
	echo "==================================" && echo
}

# 设置 DNS
setDNS(){
	echo -e "${Tip} 请输入正确格式的 DNS，多条记录以英文逗号隔开，仅支持 v4.1.0b1 版本及以上。"
	read -e -p "(默认值：1.1.1.1, 8.8.8.8, 2001:4860:4860::8888)：" dns
	[[ -z "${dns}" ]] && dns="1.1.1.1, 8.8.8.8, 2001:4860:4860::8888"
	echo && echo "=================================="
	echo -e "当前 DNS 为：${Red_background_prefix} ${dns} ${Font_color_suffix}"
	echo "==================================" && echo
}

# 修改配置
setConfig(){
    checkInstalledStatus
    echo && echo -e "请输入要操作配置项的序号，然后回车
==============================
 ${Green_font_prefix}1.${Font_color_suffix} 修改 端口
 ${Green_font_prefix}2.${Font_color_suffix} 修改 密钥
 ${Green_font_prefix}3.${Font_color_suffix} 配置 OBFS
 ${Green_font_prefix}4.${Font_color_suffix} 配置 OBFS 域名
 ${Green_font_prefix}5.${Font_color_suffix} 开关 IPv6 解析
 ${Green_font_prefix}6.${Font_color_suffix} 开关 TCP Fast Open
 ${Green_font_prefix}7.${Font_color_suffix} 配置 DNS
 ${Green_font_prefix}8.${Font_color_suffix} 配置 Snell Server 协议版本
==============================
 ${Green_font_prefix}9.${Font_color_suffix} 修改 全部配置" && echo
    read -e -p "(默认: 取消):" modify
    [[ -z "${modify}" ]] && echo "已取消..." && exit 1
    if [[ "${modify}" == "1" ]]; then
        readConfig
        setPort
        writeConfig
        restartSnell
    elif [[ "${modify}" == "2" ]]; then
        readConfig
        setPSK
        writeConfig
        restartSnell
    elif [[ "${modify}" == "3" ]]; then
        readConfig
        setObfs  # 在 setObfs 中已处理 host
        writeConfig
        restartSnell
    elif [[ "${modify}" == "4" ]]; then
        readConfig
        if [[ ${obfs} == "off" ]]; then
            echo -e "${Error} OBFS 当前为 off，无法修改 OBFS 域名。"
        else
            setHost
            writeConfig
            restartSnell
        fi
    elif [[ "${modify}" == "5" ]]; then
        readConfig
        setIpv6
        writeConfig
        restartSnell
    elif [[ "${modify}" == "6" ]]; then
        readConfig
        setTFO
        writeConfig
        restartSnell
    elif [[ "${modify}" == "7" ]]; then
        readConfig
        setDNS
        writeConfig
        restartSnell
    elif [[ "${modify}" == "8" ]]; then
        readConfig
        setVer
        writeConfig
        restartSnell
    elif [[ "${modify}" == "9" ]]; then
        setPort
        setPSK
        setObfs  # 在 setObfs 中已处理 host
        setIpv6
        setTFO
        setDNS
        setVer
        writeConfig
        restartSnell
    else
        echo -e "${Error} 请输入正确数字${Yellow_font_prefix}[1-9]${Font_color_suffix}"
        sleep 2s
        setConfig
    fi
    sleep 3s
    startMenu
}


# 安装 Snell v2
installSnellV2(){
	checkRoot
	[[ -e ${snell_bin} ]] && echo -e "${Error} 检测到 Snell Server 已安装！" && exit 1
	echo -e "${Info} 开始设置 配置..."
	setPort
	setPSK
	setObfs
	setIpv6
	setTFO
	echo -e "${Info} 开始安装/配置 依赖..."
	checkDependencies
	installDependencies
	echo -e "${Info} 开始下载/安装..."
	downloadSnellV2
	echo -e "${Info} 开始安装 服务脚本..."
	setupService
	echo -e "${Info} 开始写入 配置文件..."
	writeConfig
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	startSnell
	echo -e "${Info} 启动完成，查看配置..."
    viewConfig
}

# 安装 Snell v3
installSnellV3(){
	checkRoot
	[[ -e ${snell_bin} ]] && echo -e "${Error} 检测到 Snell Server 已安装！" && exit 1
	echo -e "${Info} 开始设置 配置..."
	setPort
	setPSK
	setObfs
	setIpv6
	setTFO
	echo -e "${Info} 开始安装/配置 依赖..."
	checkDependencies
	installDependencies
	echo -e "${Info} 开始下载/安装..."
	downloadSnellV3
	echo -e "${Info} 开始安装 服务脚本..."
	setupService
	echo -e "${Info} 开始写入 配置文件..."
	writeConfig
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	startSnell
	echo -e "${Info} 启动完成，查看配置..."
    viewConfig
}

# 安装 Snell v4
installSnellV4(){
	checkRoot
	[[ -e ${snell_bin} ]] && echo -e "${Error} 检测到 Snell Server 已安装，请先卸载旧版再安装新版!" && exit 1
	echo -e "${Info} 开始设置 配置..."
	setPort
	setPSK
	setObfs
	setIpv6
	setTFO
	setDNS
	echo -e "${Info} 开始安装/配置 依赖..."
	checkDependencies
	installDependencies
	echo -e "${Info} 开始下载/安装..."
	downloadSnellV4
	echo -e "${Info} 开始安装 服务脚本..."
	setupService
	echo -e "${Info} 开始写入 配置文件..."
	writeConfig
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	startSnell
	echo -e "${Info} 启动完成，查看配置..."
    viewConfig
}

# 安装 Snell v5
installSnellV5(){
	checkRoot
	[[ -e ${snell_bin} ]] && echo -e "${Error} 检测到 Snell Server 已安装，请先卸载旧版再安装新版!" && exit 1
	echo -e "${Info} 开始设置 配置..."
	setPort
	setPSK
	setObfs
	setIpv6
	setTFO
	setDNS
	echo -e "${Info} 开始安装/配置 依赖..."
	checkDependencies
	installDependencies
	echo -e "${Info} 开始下载/安装..."
	downloadSnellV5
	echo -e "${Info} 开始安装 服务脚本..."
	setupService
	echo -e "${Info} 开始写入 配置文件..."
	writeConfig
	echo -e "${Info} 所有步骤 安装完毕，开始启动..."
	startSnell
	echo -e "${Info} 启动完成，查看配置..."
    viewConfig
}

# 启动 Snell
startSnell(){
    checkInstalledStatus
    checkStatus
    if [[ "$status" == "running" ]]; then
        echo -e "${Info} Snell Server 已在运行！"
    else
        systemctl start snell-server
        checkStatus
        if [[ "$status" == "running" ]]; then
            echo -e "${Info} Snell Server 启动成功！"
        else
            echo -e "${Error} Snell Server 启动失败！"
            exit 1
        fi
    fi
}

# 停止 Snell
stopSnell(){
	checkInstalledStatus
	checkStatus
	[[ !"$status" == "running" ]] && echo -e "${Error} Snell Server 没有运行，请检查！" && exit 1
	systemctl stop snell-server
	echo -e "${Info} Snell Server 停止成功！"
    sleep 3s
    startMenu
}

# 重启 Snell
restartSnell(){
	checkInstalledStatus
	systemctl restart snell-server
	echo -e "${Info} Snell Server 重启完毕!"
	sleep 3s
    startMenu
}

# 更新 Snell（占位，待实现）
updateSnell(){
	checkInstalledStatus
	echo -e "${Info} Snell Server 更新完毕！"
    sleep 3s
    startMenu
}

# v4 更新到 v5
updateV4toV5(){
	checkInstalledStatus
	readConfig
	
	# 检查当前版本是否为 v4
	if [[ "$ver" != "4" ]]; then
		echo -e "${Error} 当前版本不是 v4，无法使用此功能！当前版本：v${ver}"
		sleep 3s
		startMenu
		return 1
	fi
	
	echo -e "${Info} 即将将 Snell Server 从 v4 更新到 v5 版本"
	echo -e "确定要更新吗？(y/N)"
	read -e -p "(默认: n):" confirm
	[[ -z "${confirm}" ]] && confirm="n"
	
	if [[ ${confirm} != [Yy] ]]; then
		echo -e "${Info} 已取消更新"
		sleep 2s
		startMenu
		return 0
	fi
	
	echo -e "${Info} 开始更新 Snell Server v4 到 v5..."
	
	# 停止服务
	echo -e "${Info} 停止 Snell Server 服务..."
	systemctl stop snell-server
	
	# 备份当前二进制文件
	if [[ -e "${snell_bin}" ]]; then
		echo -e "${Info} 备份当前程序文件..."
		cp "${snell_bin}" "${snell_bin}.v4.backup.$(date +%Y%m%d_%H%M%S)"
	fi
	
	# 获取当前安装的 v4 版本作为回退版本
	current_v4_version=$(cat ${snell_version_file} | sed 's/^v//')
	
	# 获取最新的 v5 版本号（优先使用网页版本，然后是脚本内置版本）
	web_v5_version=$(getLatestVersionFromWeb "v5")
	script_v5_version="${snell_v5_version}"
	
	# 选择最新的 v5 版本
	target_v5_version=""
	if [[ -n "$web_v5_version" ]]; then
		if validateVersionUrl "$web_v5_version"; then
			target_v5_version="$web_v5_version"
			echo -e "${Info} 使用网页获取的 v5 版本: v${target_v5_version}"
		fi
	fi
	
	# 如果网页版本无效，尝试脚本内置版本
	if [[ -z "$target_v5_version" && -n "$script_v5_version" ]]; then
		if validateVersionUrl "$script_v5_version"; then
			target_v5_version="$script_v5_version"
			echo -e "${Info} 使用脚本内置的 v5 版本: v${target_v5_version}"
		fi
	fi
	
	# 如果都无效，取消更新
	if [[ -z "$target_v5_version" ]]; then
		echo -e "${Error} 无法找到有效的 v5 版本进行更新"
		systemctl start snell-server
		sleep 3s
		startMenu
		return 1
	fi
	
	# 下载并安装 v5，启用回退机制
	echo -e "${Info} 开始下载 v5 版本..."
	downloadSnell "${target_v5_version}" "v5 版本" true "${current_v4_version}"
	
	if [[ $? -eq 0 ]]; then
		# 更新配置文件中的版本号
		echo -e "${Info} 更新配置文件版本号..."
		sed -i "s/version = 4/version = 5/g" "${snell_conf}"
		
		# 重新加载 systemd 并启动服务
		echo -e "${Info} 重启 Snell Server 服务..."
		systemctl daemon-reload
		systemctl start snell-server
		
		# 检查服务状态
		sleep 2
		checkStatus
		if [[ "$status" == "running" ]]; then
			actual_version=$(cat ${snell_version_file} | sed 's/^v//')
			echo -e "${Info} v4 到 v5 更新成功！"
			echo -e "${Info} 当前版本：v${actual_version}"
			
			# 如果实际版本是 v4（说明回退了），更新配置文件版本号
			if [[ "$actual_version" =~ ^4\. ]]; then
				sed -i "s/version = 5/version = 4/g" "${snell_conf}"
				echo -e "${Tip} 注意：由于下载链接问题，已回退到 v4 版本"
			fi
		else
			echo -e "${Error} 服务启动失败，正在回滚..."
			# 回滚到 v4
			backup_file=$(ls -t "${snell_bin}".v4.backup.* 2>/dev/null | head -1)
			if [[ -n "$backup_file" && -e "$backup_file" ]]; then
				cp "$backup_file" "${snell_bin}"
				echo "v${current_v4_version}" > ${snell_version_file}
				sed -i "s/version = 5/version = 4/g" "${snell_conf}"
				systemctl start snell-server
				echo -e "${Info} 已回滚到 v4 版本"
			fi
		fi
	else
		echo -e "${Error} v5 下载失败，保持 v4 版本"
		systemctl start snell-server
	fi
	
	sleep 3s
	startMenu
}

# 更新 Snell Server 到最新版本
updateSnellServer(){
    checkInstalledStatus
    readConfig
    
    echo -e "${Info} 准备更新 Snell Server..."
    
    # 显示详细的版本检查信息
    echo -e "${Info} 正在检查版本信息..."
    updateBuiltinVersions true
    checkVersionUpdate true
    
    # 检查是否有更新可用
    force_checked=false
    if [[ "$update_available" != true ]]; then
        echo -e "${Info} 当前已是最新版本，无需更新！"
        echo -e "${Info} 当前版本: ${Green_font_prefix}v${current_installed_version}${Font_color_suffix}"
        echo
        echo -e "${Tip} 是否要强制重新检查最新版本？(y/N)"
        read -e -p "(默认: n):" force_check
        [[ -z "${force_check}" ]] && force_check="n"
        
        if [[ ${force_check} == [Yy] ]]; then
            echo -e "${Info} 强制重新检查最新版本..."
            # 清除缓存并重新检查
            rm -f /tmp/snell_version_cache
            updateBuiltinVersions true
            checkVersionUpdate true
            force_checked=true
            
            # 重新检查后如果有更新，继续更新流程
            if [[ "$update_available" == true ]]; then
                echo -e "${Info} 检测到新版本，继续更新流程..."
            else
                echo -e "${Info} 重新检查后仍为最新版本"
                sleep 3s
                startMenu
                return 0
            fi
        else
            sleep 3s
            startMenu
            return 0
        fi
    fi
    
    # 显示版本信息
    echo -e "${Info} 当前版本: ${Yellow_font_prefix}v${current_installed_version}${Font_color_suffix}"
    echo -e "${Info} 最新版本: ${Green_font_prefix}v${latest_available_version}${Font_color_suffix}"
    echo -e "确定要更新吗？(Y/n)"
    read -e -p "(默认: y):" confirm
    [[ -z "${confirm}" ]] && confirm="y"
    
    if [[ ${confirm} == [Nn] ]]; then
        echo -e "${Info} 已取消更新"
        sleep 2s
        startMenu
        return 0
    fi
    
    echo -e "${Info} 开始更新 Snell Server 到最新版本..."
    
    # 停止服务
    echo -e "${Info} 停止 Snell Server 服务..."
    systemctl stop snell-server
    
    # 备份当前二进制文件
    if [[ -e "${snell_bin}" ]]; then
        echo -e "${Info} 备份当前程序文件..."
        cp "${snell_bin}" "${snell_bin}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # 根据版本选择下载函数，启用回退机制
    echo -e "${Info} 开始下载最新版本..."
    case "$ver" in
        "4")
            downloadSnell "${latest_available_version}" "v4 最新版" true "${current_installed_version}"
            ;;
        "5")
            downloadSnell "${latest_available_version}" "v5 最新版" true "${current_installed_version}"
            ;;
        *)
            echo -e "${Error} 不支持的版本: v${ver}"
            systemctl start snell-server
            sleep 3s
            startMenu
            return 1
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        # 重新加载 systemd 并启动服务
        echo -e "${Info} 重启 Snell Server 服务..."
        systemctl daemon-reload
        systemctl start snell-server
        
        # 检查服务状态
        sleep 2
        checkStatus
        if [[ "$status" == "running" ]]; then
            actual_version=$(cat ${snell_version_file} | sed 's/^v//')
            echo -e "${Info} Snell Server 更新成功！"
            echo -e "${Info} 当前版本：v${actual_version}"
            
            # 如果实际更新版本与预期不同，给出提示
            if [[ "$actual_version" != "$latest_available_version" ]]; then
                echo -e "${Tip} 注意：由于下载链接问题，已回退到 v${actual_version} 版本"
            fi
        else
            echo -e "${Error} 服务启动失败，正在回滚..."
            # 回滚到备份版本
            backup_file=$(ls -t "${snell_bin}".backup.* 2>/dev/null | head -1)
            if [[ -n "$backup_file" && -e "$backup_file" ]]; then
                cp "$backup_file" "${snell_bin}"
                echo "v${current_installed_version}" > ${snell_version_file}
                systemctl start snell-server
                echo -e "${Info} 已回滚到备份版本 v${current_installed_version}"
            fi
        fi
    else
        echo -e "${Error} 下载失败，启动原版本"
        systemctl start snell-server
    fi
    
    sleep 3s
    startMenu
}

# 自动获取 Snell 最新版本号
getLatestVersionFromWeb(){
    local version_type=$1
    local release_page="https://kb.nssurge.com/surge-knowledge-base/zh/release-notes/snell"
    
    page_content=$(curl -s -L --max-time 10 "$release_page" 2>/dev/null)
    
    if [[ -z "$page_content" ]]; then
        return 1
    fi
    
    if [[ "$version_type" == "v4" ]]; then
        latest_v4=$(echo "$page_content" | grep -oE "snell-server-v4\.[0-9]+\.[0-9]+-linux" | head -1 | sed 's/snell-server-v//g' | sed 's/-linux//g')
        if [[ -n "$latest_v4" ]]; then
            echo "$latest_v4"
            return 0
        fi
    elif [[ "$version_type" == "v5" ]]; then
        latest_v5=$(echo "$page_content" | grep -oE "snell-server-v5\.[0-9]+\.[0-9]+[a-z]*[0-9]*-linux" | head -1 | sed 's/snell-server-v//g' | sed 's/-linux//g')
        if [[ -n "$latest_v5" ]]; then
            echo "$latest_v5"
            return 0
        fi
    fi
    
    return 1
}

# 更新脚本内置版本号（带缓存机制，但保持脚本版本优先级）
updateBuiltinVersions(){
    local show_info=${1:-false}  # 是否显示详细信息，默认为静默
    local cache_file="/tmp/snell_version_cache"
    local cache_time=3600
    local current_time=$(date +%s)
    
    # v2 和 v3 始终使用固定版本，无需检查
    web_v2_newer=false
    web_v3_newer=false
    
    # 检查缓存是否存在且有效
    if [[ -f "$cache_file" ]]; then
        local cache_timestamp=$(head -1 "$cache_file" 2>/dev/null)
        if [[ -n "$cache_timestamp" && $((current_time - cache_timestamp)) -lt $cache_time ]]; then
            local cached_v4=$(sed -n '2p' "$cache_file" 2>/dev/null)
            local cached_v5=$(sed -n '3p' "$cache_file" 2>/dev/null)
            if [[ -n "$cached_v4" && -n "$cached_v5" ]]; then
                # 检查网页版本是否比脚本内置版本更新
                compareVersions "${snell_v4_version}" "$cached_v4"
                if [[ $? -eq 2 ]]; then
                    web_v4_newer=true
                else
                    web_v4_newer=false
                fi
                
                compareVersions "${snell_v5_version}" "$cached_v5"
                if [[ $? -eq 2 ]]; then
                    web_v5_newer=true
                else
                    web_v5_newer=false
                fi
                
                return 0
            fi
        fi
    fi
    
    [[ "$show_info" == true ]] && echo -e "${Info} 正在检查官方最新版本..."
    
    # 获取最新的 v4 版本
    local latest_v4_web
    latest_v4_web=$(getLatestVersionFromWeb "v4")
    if [[ $? -eq 0 && -n "$latest_v4_web" ]]; then
        # 比较网页版本和脚本内置版本
        compareVersions "${snell_v4_version}" "$latest_v4_web"
        if [[ $? -eq 2 ]]; then
            web_v4_newer=true
        else
            web_v4_newer=false
        fi
    else
        web_v4_newer=false
        latest_v4_web="${snell_v4_version}"
    fi
    
    # 获取最新的 v5 版本
    local latest_v5_web
    latest_v5_web=$(getLatestVersionFromWeb "v5")
    if [[ $? -eq 0 && -n "$latest_v5_web" ]]; then
        # 比较网页版本和脚本内置版本
        compareVersions "${snell_v5_version}" "$latest_v5_web"
        if [[ $? -eq 2 ]]; then
            web_v5_newer=true
        else
            web_v5_newer=false
        fi
    else
        web_v5_newer=false
        latest_v5_web="${snell_v5_version}"
    fi
    
    # 更新缓存（只缓存 v4 和 v5）
    echo "$current_time" > "$cache_file"
    echo "$latest_v4_web" >> "$cache_file"
    echo "$latest_v5_web" >> "$cache_file"
}

# 强制检查最新版本（清除缓存）
forceCheckVersions(){
    echo -e "${Info} 强制检查 Snell 最新版本..."
    
    rm -f "/tmp/snell_version_cache"
    updateBuiltinVersions true
    
    echo -e "${Info} 版本检查完成！"
    echo -e "${Info} 脚本内置 v4 版本: ${Green_font_prefix}${snell_v4_version}${Font_color_suffix}"
    echo -e "${Info} 脚本内置 v5 版本: ${Green_font_prefix}${snell_v5_version}${Font_color_suffix}"
    
    # 获取网页版本进行对比
    web_v4=$(getLatestVersionFromWeb "v4")
    web_v5=$(getLatestVersionFromWeb "v5")
    
    if [[ -n "$web_v4" ]]; then
        echo -e "${Info} 网页获取 v4 版本: ${Yellow_font_prefix}${web_v4}${Font_color_suffix}"
        compareVersions "${snell_v4_version}" "$web_v4"
        case $? in
            1) echo -e "${Info} v4 版本状态: 脚本内置版本与网页版本相同" ;;
            0) echo -e "${Info} v4 版本状态: 脚本内置版本比网页版本更新" ;;
            2) echo -e "${Tip} v4 版本状态: 网页版本比脚本内置版本更新" ;;
        esac
    fi
    
    if [[ -n "$web_v5" ]]; then
        echo -e "${Info} 网页获取 v5 版本: ${Yellow_font_prefix}${web_v5}${Font_color_suffix}"
        compareVersions "${snell_v5_version}" "$web_v5"
        case $? in
            1) echo -e "${Info} v5 版本状态: 脚本内置版本与网页版本相同" ;;
            0) echo -e "${Info} v5 版本状态: 脚本内置版本比网页版本更新" ;;
            2) echo -e "${Tip} v5 版本状态: 网页版本比脚本内置版本更新" ;;
        esac
    fi
    
    sleep 3s
    startMenu
}

# 卸载 Snell
uninstallSnell(){
	checkInstalledStatus
	echo "确定要卸载 Snell Server ? (y/N)"
	echo
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		systemctl stop snell-server
        systemctl disable snell-server
		echo -e "${Info} 移除主程序..."
		rm -rf "${snell_bin}"
		echo -e "${Info} 配置文件暂保留..."
		echo && echo "Snell Server 卸载完成！" && echo
	else
		echo && echo "卸载已取消..." && echo
	fi
    sleep 3s
    startMenu
}

# 获取 IPv4 地址
getIpv4(){
	ipv4=$(wget -qO- -4 -t1 -T2 ipinfo.io/ip)
	if [[ -z "${ipv4}" ]]; then
		ipv4=$(wget -qO- -4 -t1 -T2 api.ip.sb/ip)
		if [[ -z "${ipv4}" ]]; then
			ipv4=$(wget -qO- -4 -t1 -T2 members.3322.org/dyndns/getip)
			if [[ -z "${ipv4}" ]]; then
				ipv4="IPv4_Error"
			fi
		fi
	fi
}

# 获取 IPv6 地址
getIpv6(){
	ip6=$(wget -qO- -6 -t1 -T2 ifconfig.co)
	if [[ -z "${ip6}" ]]; then
		ip6="IPv6_Error"
	fi
}

# 查看配置信息
viewConfig(){
    checkInstalledStatus
    readConfig
    getIpv4
    getIpv6
    clear && echo
    echo -e "Snell Server 配置信息："
    echo -e "—————————————————————————"
    if [[ "${ipv4}" != "IPv4_Error" ]]; then
        echo -e " IPv4 地址\t: ${Green_font_prefix}${ipv4}${Font_color_suffix}"
    fi
    if [[ "${ip6}" != "IPv6_Error" ]]; then
        echo -e " IPv6 地址\t: ${Green_font_prefix}${ip6}${Font_color_suffix}"
    fi
    echo -e " 端口\t\t: ${Green_font_prefix}${port}${Font_color_suffix}"
    echo -e " 密钥\t\t: ${Green_font_prefix}${psk}${Font_color_suffix}"
    echo -e " OBFS\t\t: ${Green_font_prefix}${obfs}${Font_color_suffix}"
    echo -e " 域名\t\t: ${Green_font_prefix}${host}${Font_color_suffix}"
    echo -e " IPv6\t\t: ${Green_font_prefix}${ipv6}${Font_color_suffix}"
    echo -e " TFO\t\t: ${Green_font_prefix}${tfo}${Font_color_suffix}"
    echo -e " DNS\t\t: ${Green_font_prefix}${dns}${Font_color_suffix}"
    echo -e " 版本\t\t: ${Green_font_prefix}${ver}${Font_color_suffix}"
    echo -e "—————————————————————————"
    echo -e "${Info} Surge 配置："
    if [[ "${ipv4}" != "IPv4_Error" ]]; then
        if [[ "${obfs}" == "off" ]]; then
            echo -e "$(uname -n) = snell, ${ipv4}, ${port}, psk=${psk}, version=${ver}, tfo=${tfo}, reuse=true, ecn=true"
        else
            echo -e "$(uname -n) = snell, ${ipv4}, ${port}, psk=${psk}, version=${ver}, tfo=${tfo}, obfs=${obfs}, obfs-host=${host}, reuse=true, ecn=true"
        fi
    elif [[ "${ip6}" != "IPv6_Error" ]]; then
        if [[ "${obfs}" == "off" ]]; then
            echo -e "$(uname -n) = snell, [${ip6}], ${port}, psk=${psk}, version=${ver}, tfo=${tfo}, reuse=true, ecn=true"
        else
            echo -e "$(uname -n) = snell, [${ip6}], ${port}, psk=${psk}, version=${ver}, tfo=${tfo}, obfs=${obfs}, obfs-host=${host}, reuse=true, ecn=true"
        fi
    else
        echo -e "${Error} 无法获取 IP 地址！"
    fi
    echo -e "—————————————————————————"
    beforeStartMenu
}


# 查看运行状态
viewStatus(){
	echo -e "${Info} 获取 Snell Server 活动日志 ……"
	echo -e "${Tip} 返回主菜单请按 q ！"
	systemctl status snell-server
	startMenu
}

# 检查地理位置（用于更新脚本源选择）
geo_check() {
    api_list="https://blog.cloudflare.com/cdn-cgi/trace https://dash.cloudflare.com/cdn-cgi/trace https://cf-ns.com/cdn-cgi/trace"
    ua="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36"
    set -- $api_list
    for url in $api_list; do
        text="$(curl -A "$ua" -m 10 -s $url)"
        endpoint="$(echo $text | sed -n 's/.*h=\([^ ]*\).*/\1/p')"
        if echo $text | grep -qw 'CN'; then
            isCN=true
            break
        elif echo $url | grep -q $endpoint; then
            break
        fi
    done
}

# 更新脚本
updateShell(){
    geo_check
    if [ ! -z "$isCN" ]; then
        shell_url="https://gitee.com/ten/Snell/raw/master/Snell.sh"
    else
        shell_url="https://raw.githubusercontent.com/xOS/Snell/master/Snell.sh"
    fi

    echo -e "当前版本为 [ ${sh_ver} ]，开始检测最新版本..."
    sh_new_ver=$(wget --no-check-certificate -qO- "$shell_url"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1)
    [[ -z ${sh_new_ver} ]] && echo -e "${Error} 检测最新版本失败！" && startMenu
    if [[ ${sh_new_ver} != ${sh_ver} ]]; then
        echo -e "发现新版本[ ${sh_new_ver} ]，是否更新？[Y/n]"
        read -p "(默认: y):" yn
        [[ -z "${yn}" ]] && yn="y"
        if [[ ${yn} == [Yy] ]]; then
            wget -O snell.sh --no-check-certificate "$shell_url" && chmod +x snell.sh
            echo -e "脚本已更新为最新版本[ ${sh_new_ver} ]！"
            echo -e "3s后执行新脚本"
            sleep 3s
            exec bash snell.sh
        else
            echo && echo "	已取消..." && echo
            sleep 3s
            startMenu
        fi
    else
        echo -e "当前已是最新版本[ ${sh_new_ver} ]！"
        sleep 3s
        startMenu
    fi
}


# 返回主菜单前提示
beforeStartMenu() {
    echo && echo -n -e "${Yellow_font_prefix}* 按回车返回主菜单 *${Font_color_suffix}" && read temp
    startMenu
}

# 显示版本检查进度
showVersionCheckProgress(){
    local check_duration=${1:-3}  # 检查预期耗时，默认3秒
    echo -e "${Info} 正在检查 Snell 版本信息..."
    echo -n "检查进度: "
    
    # 根据检查时间动态调整进度条
    local steps=30
    local step_time=$(echo "scale=2; $check_duration / $steps" | bc 2>/dev/null || echo "0.1")
    
    for i in $(seq 1 $steps); do
        echo -n -e "${Green_font_prefix}█${Font_color_suffix}"
        sleep $step_time
    done
    echo -e " ${Green_font_prefix}完成${Font_color_suffix}"
    echo -e "${Info} 版本检查完成，正在加载主菜单..."
    sleep 0.3
}

# 检查是否需要进行版本检查
shouldCheckVersion(){
    local check_interval=3600  # 1小时 = 3600秒
    local last_check_file="/tmp/snell_last_check"
    local current_time=$(date +%s)
    
    # 如果没有安装 Snell，不需要检查
    if [[ ! -e ${snell_bin} || ! -e ${snell_conf} ]]; then
        return 1  # 不需要检查
    fi
    
    # 如果检查记录文件不存在，说明是第一次检查
    if [[ ! -f "$last_check_file" ]]; then
        echo "$current_time" > "$last_check_file"
        return 0  # 需要检查
    fi
    
    # 读取上次检查时间
    local last_check_time
    last_check_time=$(cat "$last_check_file" 2>/dev/null)
    
    # 如果文件内容无效，重新记录并检查
    if [[ ! "$last_check_time" =~ ^[0-9]+$ ]]; then
        echo "$current_time" > "$last_check_file"
        return 0  # 需要检查
    fi
    
    # 计算时间差
    local time_diff=$((current_time - last_check_time))
    
    # 如果超过1小时，需要检查
    if [[ $time_diff -ge $check_interval ]]; then
        echo "$current_time" > "$last_check_file"
        return 0  # 需要检查
    fi
    
    return 1  # 不需要检查
}

# 检查版本更新（带进度显示）
checkVersionUpdateWithProgress(){
    # 先检查是否需要进行版本检查
    if shouldCheckVersion; then
        echo -e "${Info} 正在检查 Snell 版本信息..."
        
        # 显示绿色进度条
        (
            echo -n "检查进度: "
            for i in {1..30}; do
                echo -n -e "${Green_font_prefix}█${Font_color_suffix}"
                sleep 0.1
            done
            echo -e " ${Green_font_prefix}完成${Font_color_suffix}"
        ) &
        progress_pid=$!
        
        # 在后台进行版本检查
        updateBuiltinVersions false >/dev/null 2>&1
        checkVersionUpdate false >/dev/null 2>&1
        
        # 等待进度条完成
        wait $progress_pid
        
        echo -e "${Info} 版本检查完成，正在加载主菜单..."
        sleep 0.5
        clear
    else
        # 静默进行版本检查（使用缓存）
        if [[ -e ${snell_bin} && -e ${snell_conf} ]]; then
            updateBuiltinVersions false >/dev/null 2>&1
            checkVersionUpdate false >/dev/null 2>&1
        fi
    fi
}

# 主菜单
startMenu(){
    clear
    checkRoot
    checkSys
    sysArch
    action=$1
    
    # 检查版本更新（在显示菜单前）
    checkVersionUpdateWithProgress
    
    # 检查是否安装了 v4 版本，需要显示 v4 到 v5 更新选项
    show_v4_to_v5_option=false
    show_update_option=false
    
    if [[ -e ${snell_bin} && -e ${snell_conf} ]]; then
        current_ver=$(cat ${snell_conf}|grep 'version = '|awk -F 'version = ' '{print $NF}')
        if [[ "$current_ver" == "4" ]]; then
            show_v4_to_v5_option=true
        fi
        # 只有 v4 和 v5 显示更新选项，v2 和 v3 不显示
        if [[ "$current_ver" == "4" || "$current_ver" == "5" ]]; then
            show_update_option=true
        fi
    fi
    
    echo && echo -e "  
==============================
Snell Server 管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
==============================
 ${Green_font_prefix} 0.${Font_color_suffix} 更新脚本
——————————————————————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 Snell Server
 ${Green_font_prefix} 2.${Font_color_suffix} 卸载 Snell Server"
    
    # 根据不同情况显示更新选项
    if [[ "$show_v4_to_v5_option" == true ]]; then
        # v4 版本，同时显示两个更新选项
        if [[ "$update_available" == true ]]; then
            echo -e " ${Green_font_prefix} 3.${Font_color_suffix} 更新 Snell Server ${Yellow_font_prefix}(可更新)${Font_color_suffix}"
        else
            echo -e " ${Green_font_prefix} 3.${Font_color_suffix} 更新 Snell Server"
        fi
        echo -e " ${Green_font_prefix} 4.${Font_color_suffix} v4 更新到 v5
——————————————————————————————
 ${Green_font_prefix} 5.${Font_color_suffix} 启动 Snell Server
 ${Green_font_prefix} 6.${Font_color_suffix} 停止 Snell Server
 ${Green_font_prefix} 7.${Font_color_suffix} 重启 Snell Server
——————————————————————————————
 ${Green_font_prefix} 8.${Font_color_suffix} 设置 配置信息
 ${Green_font_prefix} 9.${Font_color_suffix} 查看 配置信息
 ${Green_font_prefix}10.${Font_color_suffix} 查看 运行状态
——————————————————————————————
 ${Green_font_prefix}00.${Font_color_suffix} 退出脚本"
        menu_max=10
    elif [[ "$show_update_option" == true ]]; then
        if [[ "$update_available" == true ]]; then
            echo -e " ${Green_font_prefix} 3.${Font_color_suffix} 更新 Snell Server ${Yellow_font_prefix}(可更新)${Font_color_suffix}"
        else
            echo -e " ${Green_font_prefix} 3.${Font_color_suffix} 更新 Snell Server"
        fi
        echo -e "——————————————————————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 启动 Snell Server
 ${Green_font_prefix} 5.${Font_color_suffix} 停止 Snell Server
 ${Green_font_prefix} 6.${Font_color_suffix} 重启 Snell Server
——————————————————————————————
 ${Green_font_prefix} 7.${Font_color_suffix} 设置 配置信息
 ${Green_font_prefix} 8.${Font_color_suffix} 查看 配置信息
 ${Green_font_prefix} 9.${Font_color_suffix} 查看 运行状态
——————————————————————————————
 ${Green_font_prefix}00.${Font_color_suffix} 退出脚本"
        menu_max=9
    else
        echo -e "——————————————————————————————
 ${Green_font_prefix} 3.${Font_color_suffix} 启动 Snell Server
 ${Green_font_prefix} 4.${Font_color_suffix} 停止 Snell Server
 ${Green_font_prefix} 5.${Font_color_suffix} 重启 Snell Server
——————————————————————————————
 ${Green_font_prefix} 6.${Font_color_suffix} 设置 配置信息
 ${Green_font_prefix} 7.${Font_color_suffix} 查看 配置信息
 ${Green_font_prefix} 8.${Font_color_suffix} 查看 运行状态
——————————————————————————————
 ${Green_font_prefix}00.${Font_color_suffix} 退出脚本"
        menu_max=8
    fi
    
    echo "==============================" && echo
    if [[ -e ${snell_bin} ]]; then
        checkStatus
        if [[ "$status" == "running" ]]; then
            echo -e " 当前状态: ${Green_font_prefix}已安装${Yellow_font_prefix}[v$(cat ${snell_conf}|grep 'version = '|awk -F 'version = ' '{print $NF}')]${Font_color_suffix}并${Green_font_prefix}已启动${Font_color_suffix}"
        else
            echo -e " 当前状态: ${Green_font_prefix}已安装${Yellow_font_prefix}[v$(cat ${snell_conf}|grep 'version = '|awk -F 'version = ' '{print $NF}')]${Font_color_suffix}但${Red_font_prefix}未启动${Font_color_suffix}"
        fi
    else
        echo -e " 当前状态: ${Red_font_prefix}未安装${Font_color_suffix}"
    fi
    echo
    
    if [[ "$show_v4_to_v5_option" == true ]]; then
        read -e -p " 请输入数字[0-10]:" num
    elif [[ "$show_update_option" == true ]]; then
        read -e -p " 请输入数字[0-9]:" num
    else
        read -e -p " 请输入数字[0-8]:" num
    fi
    
    # 根据不同菜单模式处理用户输入
    if [[ "$show_v4_to_v5_option" == true ]]; then
        case "$num" in
            0)
            updateShell
            ;;
            1)
            installSnell
            ;;
            2)
            uninstallSnell
            ;;
            3)
            updateSnellServer
            ;;
            4)
            updateV4toV5
            ;;
            5)
            startSnell
            ;;
            6)
            stopSnell
            ;;
            7)
            restartSnell
            ;;
            8)
            setConfig
            ;;
            9)
            viewConfig
            ;;
            10)
            viewStatus
            ;;
            00)
            exit 1
            ;;
            *)
            echo -e "请输入正确数字${Yellow_font_prefix}[0-10]${Font_color_suffix}"
            sleep 2s
            startMenu
            ;;
        esac
    elif [[ "$show_update_option" == true ]]; then
        case "$num" in
            0)
            updateShell
            ;;
            1)
            installSnell
            ;;
            2)
            uninstallSnell
            ;;
            3)
            updateSnellServer
            ;;
            4)
            startSnell
            ;;
            5)
            stopSnell
            ;;
            6)
            restartSnell
            ;;
            7)
            setConfig
            ;;
            8)
            viewConfig
            ;;
            9)
            viewStatus
            ;;
            00)
            exit 1
            ;;
            *)
            echo -e "请输入正确数字${Yellow_font_prefix}[0-9]${Font_color_suffix}"
            sleep 2s
            startMenu
            ;;
        esac
    else
        case "$num" in
            0)
            updateShell
            ;;
            1)
            installSnell
            ;;
            2)
            uninstallSnell
            ;;
            3)
            startSnell
            ;;
            4)
            stopSnell
            ;;
            5)
            restartSnell
            ;;
            6)
            setConfig
            ;;
            7)
            viewConfig
            ;;
            8)
            viewStatus
            ;;
            00)
            exit 1
            ;;
            *)
            echo -e "请输入正确数字${Yellow_font_prefix}[0-8]${Font_color_suffix}"
            sleep 2s
            startMenu
            ;;
        esac
    fi
}

startMenu
