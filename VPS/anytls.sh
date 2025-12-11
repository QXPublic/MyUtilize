#!/bin/bash

# ====================================================
# AnyTLS 一键安装管理脚本 (基于 anytls-go)
# 功能：自动安装、随机配置、系统服务管理、交互面板
# ====================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

# 变量
SERVICE_NAME="anytls"
BIN_PATH="/usr/local/bin/anytls-server"
CONF_FILE="/etc/anytls/config.env"
GITHUB_REPO="anytls/anytls-go"

# 检查是否为 Root 用户
[[ $EUID -ne 0 ]] && echo -e "${RED}错误：${PLAIN} 必须使用 root 用户运行此脚本！\n" && exit 1

# 检查系统架构
check_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)  FILE_ARCH="amd64" ;;
        aarch64) FILE_ARCH="arm64" ;;
        *)       echo -e "${RED}不支持的架构: $ARCH${PLAIN}"; exit 1 ;;
    esac
}

# 生成随机密码
generate_password() {
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16
}

# 生成随机端口
generate_port() {
    shuf -i 10000-65000 -n 1
}

# 安装依赖
install_base() {
    if [[ -f /etc/redhat-release ]]; then
        yum install -y wget curl unzip tar
    else
        apt update && apt install -y wget curl unzip tar
    fi
}

# 安装主逻辑
install_anytls() {
    install_base
    check_arch
    
    echo -e "${GREEN}正在获取最新版本信息...${PLAIN}"
    # 获取最新 Release 版本号
    LATEST_TAG=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [[ -z "$LATEST_TAG" ]]; then
        echo -e "${RED}获取版本失败，请检查网络连接。${PLAIN}"
        exit 1
    fi

    echo -e "${GREEN}检测到最新版本: ${LATEST_TAG}${PLAIN}"
    
    # 构造下载链接 (anytls-go 的发布文件名格式通常为 anytls_{ver}_{os}_{arch}.zip)
    # 注意：版本号在文件名中通常不带 'v'，例如 v0.0.8 -> 0.0.8
    VERSION_NUM=${LATEST_TAG#v}
    DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${LATEST_TAG}/anytls_${VERSION_NUM}_linux_${FILE_ARCH}.zip"
    
    echo -e "${GREEN}正在下载...${PLAIN}"
    wget -O /tmp/anytls.zip "$DOWNLOAD_URL"
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}下载失败！${PLAIN}"
        exit 1
    fi

    echo -e "${GREEN}正在安装...${PLAIN}"
    unzip -o /tmp/anytls.zip -d /tmp/anytls_dist
    # 移动二进制文件
    mv /tmp/anytls_dist/anytls-server "$BIN_PATH"
    chmod +x "$BIN_PATH"
    rm -rf /tmp/anytls.zip /tmp/anytls_dist

    # 配置参数
    echo -e "${YELLOW}请设置配置信息（回车自动生成随机值）${PLAIN}"
    
    read -p "请输入端口 [10000-65000]: " USER_PORT
    [[ -z "$USER_PORT" ]] && USER_PORT=$(generate_port)
    
    read -p "请输入密码: " USER_PASS
    [[ -z "$USER_PASS" ]] && USER_PASS=$(generate_password)

    mkdir -p /etc/anytls
    
    # 保存配置
    cat > "$CONF_FILE" <<EOF
ANYTLS_PORT=$USER_PORT
ANYTLS_PASSWORD=$USER_PASS
EOF

    # 创建 Systemd 服务
    cat > /etc/systemd/system/anytls.service <<EOF
[Unit]
Description=AnyTLS Server Service
After=network.target

[Service]
Type=simple
EnvironmentFile=$CONF_FILE
ExecStart=$BIN_PATH -l 0.0.0.0:\${ANYTLS_PORT} -p \${ANYTLS_PASSWORD}
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable anytls
    systemctl restart anytls
    
    echo -e "${GREEN}AnyTLS 安装并启动成功！${PLAIN}"
    show_info
}

# 卸载
uninstall_anytls() {
    systemctl stop anytls
    systemctl disable anytls
    rm -f /etc/systemd/system/anytls.service
    rm -f "$BIN_PATH"
    rm -rf /etc/anytls
    systemctl daemon-reload
    echo -e "${GREEN}AnyTLS 已彻底卸载。${PLAIN}"
}

# 显示配置信息
show_info() {
    if [[ ! -f "$CONF_FILE" ]]; then
        echo -e "${RED}未检测到安装配置！${PLAIN}"
        return
    fi
    
    source "$CONF_FILE"
    IP=$(curl -s4 ipv4.icanhazip.com)
    
    echo -e ""
    echo -e "=================================="
    echo -e "       AnyTLS 配置信息"
    echo -e "=================================="
    echo -e "地址 (IP): ${GREEN}${IP}${PLAIN}"
    echo -e "端口 (Port): ${GREEN}${ANYTLS_PORT}${PLAIN}"
    echo -e "密码 (Password): ${GREEN}${ANYTLS_PASSWORD}${PLAIN}"
    echo -e "=================================="
    echo -e "客户端配置参考:"
    echo -e "Shadowrocket / NekoBox / Sing-box"
    echo -e "=================================="
    echo -e ""
}

# 修改配置
modify_config() {
    read -p "请输入新端口 [随机]: " NEW_PORT
    [[ -z "$NEW_PORT" ]] && NEW_PORT=$(generate_port)
    
    read -p "请输入新密码 [随机]: " NEW_PASS
    [[ -z "$NEW_PASS" ]] && NEW_PASS=$(generate_password)
    
    cat > "$CONF_FILE" <<EOF
ANYTLS_PORT=$NEW_PORT
ANYTLS_PASSWORD=$NEW_PASS
EOF
    systemctl restart anytls
    echo -e "${GREEN}配置已更新并重启服务！${PLAIN}"
    show_info
}

# 主菜单
menu() {
    clear
    echo -e "#################################################"
    echo -e "#            AnyTLS 一键安装管理脚本            #"
    echo -e "#################################################"
    echo -e "# 1. 安装 AnyTLS"
    echo -e "# 2. 卸载 AnyTLS"
    echo -e "-------------------------------------------------"
    echo -e "# 3. 启动服务"
    echo -e "# 4. 停止服务"
    echo -e "# 5. 重启服务"
    echo -e "-------------------------------------------------"
    echo -e "# 6. 查看配置信息"
    echo -e "# 7. 修改端口/密码"
    echo -e "-------------------------------------------------"
    echo -e "# 0. 退出脚本"
    echo -e "#################################################"
    read -p "请输入选项: " num
    
    case "$num" in
        1) install_anytls ;;
        2) uninstall_anytls ;;
        3) systemctl start anytls && echo -e "${GREEN}已启动${PLAIN}" ;;
        4) systemctl stop anytls && echo -e "${GREEN}已停止${PLAIN}" ;;
        5) systemctl restart anytls && echo -e "${GREEN}已重启${PLAIN}" ;;
        6) show_info ;;
        7) modify_config ;;
        0) exit 0 ;;
        *) echo -e "${RED}请输入正确的数字${PLAIN}" ;;
    esac
}

# 运行菜单
if [[ $# > 0 ]]; then
    case $1 in
        install) install_anytls ;;
        uninstall) uninstall_anytls ;;
        *) menu ;;
    esac
else
    menu
fi
