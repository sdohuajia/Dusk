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
    if ! sudo apt update && sudo apt upgrade -y && sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip build-essential libclang-dev -y; then
        echo "安装软件包失败。"  # 错误信息
        exit 1
    fi

    # 下载并运行 node-installer.sh
    echo "下载并运行 node-installer.sh..."
    if ! curl --proto '=https' --tlsv1.2 -sSfL https://github.com/dusk-network/node-installer/releases/download/v0.3.3/node-installer.sh | sudo sh; then
        echo "下载或运行 node-installer.sh 失败。"  # 错误信息
        exit 1
    fi

    # 运行 ruskreset 命令
    echo "运行 ruskreset..."
    if ! ruskreset; then
        echo "运行 ruskreset 失败。"  # 错误信息
        exit 1
    fi

    # 安装 Rust 和 Cargo
    echo "检查是否已安装 Rust 和 Cargo..."
    if ! command -v rustc &> /dev/null; then
        echo "未检测到 Rust，正在安装 Rust 和 Cargo..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
        source $HOME/.cargo/env
        export PATH="$HOME/.cargo/bin:$PATH"
    else
        echo "Rust 和 Cargo 已安装，跳过安装。"
    fi

    # 检查并删除 rusk 目录（如果存在）
    if [ -d "rusk" ]; then
        echo "rusk 目录已存在，正在删除..."
        rm -rf rusk
    fi

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

    # 执行 rusk-wallet
    rusk-wallet

    # 执行给定钱包的共识密钥
    rusk-wallet export -d /opt/dusk/conf -n consensus.keys

    # 为共识密钥创建加密，设置环境变量
    sh /opt/dusk/bin/setup_consensus_pwd.sh

    # 启动 rusk 服务
    echo "启动 rusk 服务..."
    if ! service rusk start; then
        echo "启动 rusk 服务失败。"  # 错误信息
        exit 1
    fi
    echo "rusk 服务已成功启动。"

    # 等待用户按任意键以返回主菜单
    read -p "按任意键返回主菜单..."
}

# 质押 Dusk 函数
function stake_dusk() {
    read -p "请输入质押金额（默认最低 1000 Dusk）: " amt
    amt=${amt:-1000}  # 如果用户没有输入，则使用默认值 1000

    if ! rusk-wallet moonlight-stake --amt "$amt"; then
        echo "质押 Dusk 失败。"  # 错误信息
        exit 1
    fi
    echo "成功质押 $amt Dusk。"

    # 等待用户按任意键以返回主菜单
    read -p "按任意键返回主菜单..."
}

# 检查质押信息函数
function check_stake_info() {
    echo "检查质押信息..."
    if ! rusk-wallet stake-info; then
        echo "检查质押信息失败。"  # 错误信息
        exit 1
    fi
}

# 查看收益函数
function view_rewards() {
    echo "查看收益..."
    if ! rusk-wallet stake-info --reward; then
        echo "查看收益失败。"  # 错误信息
        exit 1
    fi

    # 等待用户按任意键以返回主菜单
    read -p "按任意键返回主菜单..."
}

# 查看日志函数
function view_logs() {
    echo "查看 rusk 日志..."
    tail -F /var/log/rusk.log -n 50

    # 等待用户按任意键以返回主菜单
    read -p "按任意键返回主菜单..."
}

# 查看区块高度函数
function view_block_height() {
    echo "查看区块高度..."
    # 执行 ruskquery block-height 命令
    if ! ruskquery block-height; then
        echo "查看区块高度失败，命令可能未正确执行。"  # 错误信息
    fi

    # 等待用户按任意键以返回主菜单
    read -p "按任意键返回主菜单..."
}

# 升级版本函数
function upgrade_version() {
    echo "升级版本到 0.3.4..."
    # 升级版本
    if ! curl --proto '=https' --tlsv1.2 -sSfL https://github.com/dusk-network/node-installer/releases/download/v0.3.4/node-installer.sh | sudo sh; then
        echo "升级失败。"  # 错误信息
        exit 1
    fi
    # 启动 rusk 服务
    if ! service rusk start; then
        echo "启动 rusk 服务失败。"  # 错误信息
        exit 1
    fi
    echo "rusk 服务已成功启动。"
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
        echo "1. 启动节点"
        echo "2. 查看区块高度"
        echo "3. 质押 Dusk"
        echo "4. 查看日志"
        echo "5. 检查质押信息"
        echo "6. 查看收益"
        echo "7. 升级版本到 0.3.4"
        echo "8. 退出"
        
        read -p "请输入选项: " choice
        case $choice in
            1)
                start_node  # 调用启动节点函数
                ;;
            2)
                view_block_height  # 调用查看区块高度函数
                ;;
            3)
                stake_dusk  # 调用质押 Dusk 函数
                ;;
            4)
                view_logs  # 调用查看日志函数
                ;;
            5)
                check_stake_info  # 调用检查质押信息函数
                ;;
            6)
                view_rewards  # 调用查看收益函数
                ;;
            7)
                upgrade_version  # 调用升级版本函数
                ;;
            8)
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
