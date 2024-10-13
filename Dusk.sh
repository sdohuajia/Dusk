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
    if ! sudo apt update && sudo apt upgrade -y && sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libclang-dev -y; then
        echo "安装软件包失败。"  # 错误信息
        exit 1
    fi

    # 下载并运行 node-installer.sh
    echo "下载并运行 node-installer.sh..."
    if ! curl --proto '=https' --tlsv1.2 -sSfL https://github.com/dusk-network/node-installer/releases/download/v0.3.2/node-installer.sh | sudo sh; then
        echo "下载或运行 node-installer.sh 失败。"  # 错误信息
        exit 1
    fi

    # 安装 Rust 和 Cargo
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source $HOME/.cargo/env

    # 克隆 rusk 仓库
    echo "克隆 rusk 仓库..."
    if ! git clone https://github.com/dusk-network/rusk.git; then
        echo "克隆 rusk 仓库失败。"  # 错误信息
        exit 1
    fi

    echo "rusk 仓库克隆完成！"

    # 进入 rusk 目录并安装 rusk-wallet
    cd rusk/rusk-wallet || { echo "进入 rusk-wallet 目录失败。"; exit 1; }
    make install || { echo "安装失败。"; exit 1; }

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
