#!/bin/bash

# 远程部署脚本 - 通过SSH自动构建并部署到服务器
# Remote Deployment Script - Build and deploy to server via SSH

set -e

# 配置变量
SCRIPT_VERSION="1.0.0"
DEFAULT_USER="root"
DEFAULT_PORT="22"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 显示使用帮助
show_help() {
    cat << EOF
🚀 提示词优化工具远程部署脚本 v${SCRIPT_VERSION}

用法: $0 [选项] <服务器地址>

参数:
  <服务器地址>        目标服务器的IP地址或域名

选项:
  -u, --user USER     SSH用户名 (默认: ${DEFAULT_USER})
  -p, --port PORT     SSH端口 (默认: ${DEFAULT_PORT})
  -k, --key PATH      SSH私钥路径
  --skip-build        跳过本地构建
  --dry-run           模拟运行，不实际执行部署
  -h, --help          显示此帮助信息
  -v, --version       显示版本信息

示例:
  $0 192.168.1.100
  $0 -u ubuntu -p 2222 example.com
  $0 --key ~/.ssh/id_rsa --user root server.example.com

环境变量:
  SSH_USER           SSH用户名
  SSH_PORT           SSH端口
  SSH_KEY            SSH私钥路径
EOF
}

# 解析命令行参数
parse_arguments() {
    local user="${SSH_USER:-${DEFAULT_USER}}"
    local port="${SSH_PORT:-${DEFAULT_PORT}}"
    local ssh_key="${SSH_KEY:-}"
    local server=""
    local skip_build=false
    local dry_run=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--user)
                user="$2"
                shift 2
                ;;
            -p|--port)
                port="$2"
                shift 2
                ;;
            -k|--key)
                ssh_key="$2"
                shift 2
                ;;
            --skip-build)
                skip_build=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "远程部署脚本 v${SCRIPT_VERSION}"
                exit 0
                ;;
            -*)
                print_error "未知选项: $1"
                echo "使用 $0 --help 查看帮助"
                exit 1
                ;;
            *)
                if [ -z "$server" ]; then
                    server="$1"
                else
                    print_error "多余的参数: $1"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    if [ -z "$server" ]; then
        print_error "请提供服务器地址"
        echo "使用 $0 --help 查看帮助"
        exit 1
    fi
    
    # 导出变量供其他函数使用
    export SSH_SERVER="$server"
    export SSH_USER="$user"
    export SSH_PORT="$port"
    export SSH_KEY="$ssh_key"
    export SKIP_BUILD="$skip_build"
    export DRY_RUN="$dry_run"
}

# 构建SSH命令
build_ssh_cmd() {
    local ssh_cmd="ssh"
    
    if [ -n "$SSH_KEY" ]; then
        ssh_cmd="$ssh_cmd -i $SSH_KEY"
    fi
    
    ssh_cmd="$ssh_cmd -p $SSH_PORT"
    ssh_cmd="$ssh_cmd $SSH_USER@$SSH_SERVER"
    
    echo "$ssh_cmd"
}

# 构建SCP命令
build_scp_cmd() {
    local scp_cmd="scp"
    
    if [ -n "$SSH_KEY" ]; then
        scp_cmd="$scp_cmd -i $SSH_KEY"
    fi
    
    scp_cmd="$scp_cmd -P $SSH_PORT"
    
    echo "$scp_cmd"
}

# 测试SSH连接
test_ssh_connection() {
    print_info "测试SSH连接到 $SSH_USER@$SSH_SERVER:$SSH_PORT ..."
    
    local ssh_cmd=$(build_ssh_cmd)
    
    if $DRY_RUN; then
        print_info "[DRY RUN] 会执行: $ssh_cmd 'echo \"SSH连接测试成功\"'"
        return 0
    fi
    
    if $ssh_cmd 'echo "SSH连接测试成功"' 2>/dev/null; then
        print_success "SSH连接正常"
        return 0
    else
        print_error "SSH连接失败，请检查："
        echo "  - 服务器地址是否正确"
        echo "  - SSH端口是否正确"
        echo "  - SSH用户名是否正确"
        echo "  - SSH密钥或密码是否正确"
        echo "  - 服务器SSH服务是否正在运行"
        return 1
    fi
}

# 本地构建
build_locally() {
    if $SKIP_BUILD; then
        print_info "跳过本地构建"
        return 0
    fi
    
    print_info "开始本地构建..."
    
    if $DRY_RUN; then
        print_info "[DRY RUN] 会执行本地构建命令"
        return 0
    fi
    
    if [ ! -f "./build.sh" ]; then
        print_error "找不到构建脚本 ./build.sh"
        exit 1
    fi
    
    # 执行构建
    ./build.sh
    
    print_success "本地构建完成"
}

# 上传文件到服务器
upload_files() {
    print_info "上传文件到服务器..."
    
    local scp_cmd=$(build_scp_cmd)
    local temp_dir="/tmp/prompt-optimize-deploy"
    
    if $DRY_RUN; then
        print_info "[DRY RUN] 会上传以下文件："
        echo "  - dist/linux-amd64/prompt-optimize"
        echo "  - dist/linux-arm64/prompt-optimize"
        echo "  - install.sh"
        echo "  - caddy-site.conf"
        return 0
    fi
    
    # 检查构建文件
    if [ ! -f "dist/linux-amd64/prompt-optimize" ] && [ ! -f "dist/linux-arm64/prompt-optimize" ]; then
        print_error "找不到构建输出文件，请先运行构建"
        exit 1
    fi
    
    # 在服务器上创建临时目录
    local ssh_cmd=$(build_ssh_cmd)
    $ssh_cmd "mkdir -p $temp_dir"
    
    # 上传文件
    $scp_cmd -r dist/ $SSH_USER@$SSH_SERVER:$temp_dir/
    $scp_cmd install.sh $SSH_USER@$SSH_SERVER:$temp_dir/
    
    # 上传可选文件
    if [ -f "caddy-site.conf" ]; then
        $scp_cmd caddy-site.conf $SSH_USER@$SSH_SERVER:$temp_dir/
    fi
    
    print_success "文件上传完成"
}

# 远程执行安装
remote_install() {
    print_info "在服务器上执行安装..."
    
    local ssh_cmd=$(build_ssh_cmd)
    local temp_dir="/tmp/prompt-optimize-deploy"
    
    if $DRY_RUN; then
        print_info "[DRY RUN] 会在服务器上执行安装脚本"
        return 0
    fi
    
    # 执行远程安装命令
    $ssh_cmd << EOF
set -e
cd $temp_dir

# 设置权限
chmod +x install.sh

# 执行安装
sudo ./install.sh

# 清理临时文件
cd /
rm -rf $temp_dir

echo "远程安装完成！"
EOF
    
    print_success "远程安装完成"
}

# 验证部署
verify_deployment() {
    print_info "验证部署状态..."
    
    local ssh_cmd=$(build_ssh_cmd)
    
    if $DRY_RUN; then
        print_info "[DRY RUN] 会验证服务状态"
        return 0
    fi
    
    # 检查服务状态
    $ssh_cmd << 'EOF'
echo "🔍 检查服务状态..."
sudo systemctl status prompt-optimize --no-pager -l || true

echo
echo "🌐 测试健康检查..."
if curl -s http://localhost:8092/health > /dev/null; then
    echo "✅ 健康检查通过"
else
    echo "❌ 健康检查失败"
    echo "📋 查看日志："
    sudo journalctl -u prompt-optimize -n 10 --no-pager || true
fi
EOF
    
    print_success "部署验证完成"
}

# 显示部署后信息
show_post_deployment_info() {
    print_success "🎉 远程部署完成！"
    echo
    echo "🌐 服务器信息:"
    echo "  - 服务器: $SSH_SERVER"
    echo "  - 用户: $SSH_USER"
    echo "  - 端口: $SSH_PORT"
    echo
    echo "🔧 远程管理命令:"
    local ssh_cmd=$(build_ssh_cmd)
    echo "  - SSH连接: $ssh_cmd"
    echo "  - 查看状态: $ssh_cmd 'sudo systemctl status prompt-optimize'"
    echo "  - 查看日志: $ssh_cmd 'sudo journalctl -u prompt-optimize -f'"
    echo "  - 重启服务: $ssh_cmd 'sudo systemctl restart prompt-optimize'"
    echo
    echo "📝 配置文件: /etc/prompt-optimize/env"
    echo "🔧 如需配置API_KEY: $ssh_cmd 'sudo nano /etc/prompt-optimize/env'"
}

# 主函数
main() {
    echo "🚀 提示词优化工具远程部署脚本 v${SCRIPT_VERSION}"
    echo "======================================================"
    echo
    
    # 解析参数
    parse_arguments "$@"
    
    if $DRY_RUN; then
        print_warning "⚠️  模拟运行模式 - 不会实际执行操作"
        echo
    fi
    
    # 显示配置信息
    print_info "部署配置:"
    echo "  - 目标服务器: $SSH_SERVER"
    echo "  - SSH用户: $SSH_USER"
    echo "  - SSH端口: $SSH_PORT"
    [ -n "$SSH_KEY" ] && echo "  - SSH密钥: $SSH_KEY"
    echo "  - 跳过构建: $SKIP_BUILD"
    echo
    
    # 确认继续
    if ! $DRY_RUN; then
        read -p "确认部署到上述服务器吗? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "部署已取消"
            exit 0
        fi
    fi
    
    # 执行部署步骤
    test_ssh_connection || exit 1
    build_locally
    upload_files
    remote_install
    verify_deployment
    show_post_deployment_info
}

# 执行主函数
main "$@"