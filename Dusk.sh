#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/Dusk.sh"

# 确保脚本以 root 权限运行
if [ "$(id -u)" -ne "0" ]; then
  echo "请以 root 用户或使用 sudo 运行此脚本"
  exit 1
fi

# 启动节点函数
function start_node() {
    echo "启动节点..."
    
    # 更新系统并安装必要的软件包
    echo "更新系统并安装必要的软件包..."
    if ! sudo apt update && sudo apt upgrade -y && sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip -y; then
        echo "安装软件包失败。"  # 错误信息
        exit 1
    fi

    # 检测 Docker 是否已安装
    if ! command -v docker &> /dev/null
    then
        echo "Docker 未安装，正在安装 Docker..."

        # 添加 Docker 的官方 GPG 密钥
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

        # 添加 Docker 的稳定版仓库
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

        # 再次更新包索引
        sudo apt-get update

        # 安装 Docker
        sudo apt-get install -y docker-ce

        echo "Docker 安装完成！"
    else
        echo "Docker 已安装，版本为: $(docker --version)"
    fi

    # 克隆 rusk 仓库
    echo "克隆 rusk 仓库..."
    if ! git clone https://github.com/dusk-network/rusk.git; then
        echo "克隆 rusk 仓库失败。"  # 错误信息
        exit 1
    fi

    echo "rusk 仓库克隆完成！"

    # 进入 rusk 目录
    cd rusk || { echo "进入 rusk 目录失败。"; exit 1; }

    # 构建 Docker 镜像
    if ! docker build -t rusk .; then
        echo "构建 Docker 镜像失败。"  # 错误信息
        exit 1
    fi

    echo "Docker 镜像构建完成！"

    # 运行 Docker 容器
    if ! docker run -d --name rusk_container -p 9001:9000/udp -p 8081:8080/tcp rusk; then
        echo "运行 Docker 容器失败。"  # 错误信息
        exit 1
    fi

    echo "Docker 容器运行成功！"
}

# 查看日志函数
function view_logs() {
    echo "查看日志..."
    # 查看 Docker 容器的日志
    if ! docker logs rusk_container; then
        echo "查看日志失败，容器可能未运行。"  # 错误信息
    fi
}

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "脚本由大赌社区哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "如有问题，可联系推特，仅此只有一个号"
        echo "新建了一个电报群，方便大家交流：t.me/Sdohua"
        echo "================================================================"
        echo "退出脚本，请按键盘 ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1. 启动节点（构建 Docker 镜像并运行容器）"
        echo "2. 查看日志"
        echo "3. 退出"
        
        read -p "请输入选项: " choice
        case $choice in
            1)
                start_node  # 调用启动节点函数
                ;;
            2)
                view_logs  # 调用查看日志函数
                ;;
            3)
                echo "退出脚本..."
                exit 0
                ;;
            *)
                echo "无效选项，请重试。"
                ;;
        esac
        read -p "按任意键继续..."
    done
}

# 调用主菜单函数
main_menu
