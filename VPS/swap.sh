#!/usr/bin/env bash

# 使用 tput 获取颜色代码，更具可移植性
Green=$(tput setaf 2)
Red=$(tput setaf 1)
Font=$(tput sgr0)

# 定义 swap 文件的路径
SWAP_FILE="/swapfile"

# 1. 检查 root 权限
if [[ $EUID -ne 0 ]]; then
    echo -e "${Red}错误：此脚本必须以 root 身份运行！${Font}"
    exit 1
fi

# 2. 添加 Swap 的功能函数
add_swap() {
    # 检查 swap 文件是否已存在
    if [ -f "$SWAP_FILE" ]; then
        echo -e "${Red}错误：$SWAP_FILE 文件已存在。如果需要重新设置，请先删除它。${Font}"
        return 1
    fi
    
    # 提示用户输入大小，并进行验证
    while true; do
        read -p "请输入需要添加的 Swap 大小 (单位: MB): " swap_size
        # 使用正则表达式验证输入是否为正整数
        if [[ "$swap_size" =~ ^[1-9][0-9]*$ ]]; then
            break
        else
            echo -e "${Red}输入无效，请输入一个大于 0 的纯数字。${Font}"
        fi
    done

    echo -e "${Green}正在创建大小为 ${swap_size}MB 的 Swap 文件...${Font}"
    # 使用 dd 命令创建，兼容性最好
    dd if=/dev/zero of="$SWAP_FILE" bs=1M count="$swap_size" status=progress
    
    echo "设置文件权限..."
    chmod 600 "$SWAP_FILE"
    
    echo "格式化为 Swap..."
    mkswap "$SWAP_FILE"
    
    echo "启用 Swap..."
    swapon "$SWAP_FILE"
    
    # 检查 /etc/fstab 中是否已有该条目，防止重复添加
    if ! grep -q "$SWAP_FILE" /etc/fstab; then
        echo "将 Swap 信息写入 /etc/fstab 以便开机自启..."
        echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
    fi
    
    echo -e "\n${Green}Swap 添加成功！${Font}"
    echo "当前 Swap 信息："
    swapon --show
    echo "当前内存信息："
    free -h
}

# 3. 删除 Swap 的功能函数
del_swap() {
    # 检查 swap 文件是否存在
    if [ ! -f "$SWAP_FILE" ]; then
        echo -e "${Red}错误：$SWAP_FILE 文件未找到，无需删除。${Font}"
        return 1
    fi

    echo "正在停止 Swap..."
    # 精确关闭指定的 swap 文件
    swapoff "$SWAP_FILE"
    
    echo "正在从 /etc/fstab 中移除条目..."
    # 使用更精确的 sed 命令，只删除匹配行首的内容
    sed -i "\|^$SWAP_FILE|d" /etc/fstab
    
    echo "正在删除 Swap 文件..."
    rm -f "$SWAP_FILE"
    
    echo -e "\n${Green}Swap 已成功删除！${Font}"
    echo "当前内存信息："
    free -h
}

# 4. 主菜单 (使用 while 循环)
main() {
    while true; do
        clear
        echo "============================================="
        echo -e "${Green}      Linux VPS Swap 一键管理脚本      ${Font}"
        echo "============================================="
        echo " 1. 添加 Swap"
        echo " 2. 删除 Swap"
        echo " 3. 退出脚本"
        echo "---------------------------------------------"
        read -p "请输入数字 [1-3]: " choice
        
        case "$choice" in
            1)
                add_swap
                read -p "按 [Enter] 键返回主菜单..."
                ;;
            2)
                del_swap
                read -p "按 [Enter] 键返回主菜单..."
                ;;
            3)
                echo "脚本已退出。"
                exit 0
                ;;
            *)
                echo -e "\n${Red}输入错误，请输入 1, 2 或 3。${Font}"
                sleep 2
                ;;
        esac
    done
}

# 运行主函数
main
