#!/bin/bash

# 提示词优化工具 - 一键安装/升级脚本
# Prompt Optimization Tool - One-click Installation/Upgrade Script

set -e

# 配置变量
SCRIPT_VERSION="1.0.0"
APP_NAME="prompt-optimize"
SERVICE_NAME="prompt-optimize"
SERVICE_USER="www-data"
APP_DIR="/opt/${APP_NAME}"
CONFIG_DIR="/etc/${APP_NAME}"
LOG_DIR="/var/log/${APP_NAME}"

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

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "请以 root 用户身份运行此脚本"
        echo "使用命令: sudo $0 $@"
        exit 1
    fi
}

# 检测系统架构
detect_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            print_error "不支持的系统架构: $arch"
            exit 1
            ;;
    esac
}

# 检查必要的命令
check_dependencies() {
    print_info "检查系统依赖..."
    
    local missing_deps=()
    
    # 检查 systemctl
    if ! command -v systemctl &> /dev/null; then
        missing_deps+=("systemd")
    fi
    
    # 检查 curl（用于下载）
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "缺少必要的依赖: ${missing_deps[*]}"
        print_info "在 Ubuntu/Debian 上安装: sudo apt update && sudo apt install -y ${missing_deps[*]}"
        print_info "在 CentOS/RHEL 上安装: sudo yum install -y ${missing_deps[*]}"
        exit 1
    fi
    
    print_success "系统依赖检查通过"
}

# 检查现有安装
check_existing_installation() {
    if systemctl is-active --quiet ${SERVICE_NAME}; then
        print_warning "检测到现有的 ${APP_NAME} 服务正在运行"
        return 0
    elif [ -f "${APP_DIR}/${APP_NAME}" ]; then
        print_warning "检测到现有的 ${APP_NAME} 安装"
        return 0
    else
        return 1
    fi
}

# 停止现有服务
stop_existing_service() {
    print_info "停止现有服务..."
    systemctl stop ${SERVICE_NAME} || true
    print_success "服务已停止"
}

# 创建用户和目录
setup_directories() {
    print_info "设置目录和用户..."
    
    # 创建服务用户（如果不存在）
    if ! id -u ${SERVICE_USER} &> /dev/null; then
        useradd --system --no-create-home --shell /bin/false ${SERVICE_USER}
        print_success "创建服务用户: ${SERVICE_USER}"
    fi
    
    # 创建目录
    mkdir -p ${APP_DIR}
    mkdir -p ${CONFIG_DIR}
    mkdir -p ${LOG_DIR}
    
    # 设置权限
    chown -R ${SERVICE_USER}:${SERVICE_USER} ${APP_DIR}
    chown -R ${SERVICE_USER}:${SERVICE_USER} ${LOG_DIR}
    
    print_success "目录设置完成"
}

# 安装应用
install_application() {
    local arch=$(detect_arch)
    local binary_path="dist/linux-${arch}/${APP_NAME}"
    
    print_info "安装 ${APP_NAME} (架构: ${arch})..."
    
    # 检查二进制文件是否存在
    if [ ! -f "${binary_path}" ]; then
        print_error "找不到二进制文件: ${binary_path}"
        print_info "请先运行 './build.sh' 来构建应用程序"
        exit 1
    fi
    
    # 复制二进制文件
    cp "${binary_path}" "${APP_DIR}/${APP_NAME}"
    chmod +x "${APP_DIR}/${APP_NAME}"
    chown ${SERVICE_USER}:${SERVICE_USER} "${APP_DIR}/${APP_NAME}"
    
    print_success "应用程序安装完成"
}

# 创建配置文件
create_config() {
    print_info "创建配置文件..."
    
    # 检查是否已有配置文件
    if [ -f "${CONFIG_DIR}/env" ]; then
        print_warning "配置文件已存在，创建备份..."
        cp "${CONFIG_DIR}/env" "${CONFIG_DIR}/env.backup.$(date +%Y%m%d_%H%M%S)"
    else
        # 创建新的配置文件
        cat > ${CONFIG_DIR}/env << EOF
# 提示词优化工具环境配置
# Prompt Optimization Tool Environment Configuration

# OpenAI API 配置 (必须设置)
API_KEY=your_api_key_here
BASE_URL=https://api.openai.com/v1
MODEL=gpt-3.5-turbo

# 服务器配置
PORT=8080
GIN_MODE=release

# 日志配置
LOG_LEVEL=info
EOF
        print_success "配置文件创建完成"
        print_warning "请编辑 ${CONFIG_DIR}/env 设置您的 API_KEY"
    fi
}

# 创建系统服务
create_systemd_service() {
    print_info "创建系统服务..."
    
    cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=Prompt Optimization Tool
Documentation=https://github.com/JinFanZheng/prompt-optimize
After=network.target

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_USER}
WorkingDirectory=${APP_DIR}
ExecStart=${APP_DIR}/${APP_NAME}
ExecReload=/bin/kill -HUP \$MAINPID
EnvironmentFile=${CONFIG_DIR}/env
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${SERVICE_NAME}

# 安全设置
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=${LOG_DIR}
PrivateTmp=true

# 资源限制
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载 systemd
    systemctl daemon-reload
    systemctl enable ${SERVICE_NAME}
    
    print_success "系统服务创建完成"
}

# 创建Caddy配置（可选）
setup_caddy_config() {
    if [ -f "caddy-site.conf" ]; then
        print_info "设置 Caddy 配置..."
        
        # 创建 Caddy 配置目录
        mkdir -p /etc/caddy/conf.d
        
        # 复制配置文件
        cp caddy-site.conf /etc/caddy/conf.d/${APP_NAME}.conf
        
        print_success "Caddy 配置文件已复制到 /etc/caddy/conf.d/${APP_NAME}.conf"
        print_warning "请手动编辑配置文件并替换域名，然后重新加载 Caddy 配置"
        print_info "编辑命令: sudo nano /etc/caddy/conf.d/${APP_NAME}.conf"
        print_info "重载命令: sudo systemctl reload caddy"
    fi
}

# 启动服务
start_service() {
    print_info "启动服务..."
    
    # 检查配置
    if grep -q "your_api_key_here" "${CONFIG_DIR}/env"; then
        print_warning "请先配置您的 API_KEY，然后手动启动服务"
        print_info "配置文件: ${CONFIG_DIR}/env"
        print_info "启动命令: sudo systemctl start ${SERVICE_NAME}"
        return
    fi
    
    # 启动服务
    systemctl start ${SERVICE_NAME}
    
    # 等待服务启动
    sleep 3
    
    if systemctl is-active --quiet ${SERVICE_NAME}; then
        print_success "服务启动成功！"
        
        # 测试健康检查
        if curl -s http://localhost:8080/health > /dev/null; then
            print_success "健康检查通过"
        else
            print_warning "健康检查失败，请检查日志"
        fi
    else
        print_error "服务启动失败"
        print_info "查看日志: sudo journalctl -u ${SERVICE_NAME} -n 20"
        exit 1
    fi
}

# 显示安装信息
show_installation_info() {
    print_success "🎉 安装完成！"
    echo
    echo "📋 服务信息:"
    echo "  - 服务名称: ${SERVICE_NAME}"
    echo "  - 应用目录: ${APP_DIR}"
    echo "  - 配置文件: ${CONFIG_DIR}/env"
    echo "  - 日志目录: ${LOG_DIR}"
    echo
    echo "🔧 常用命令:"
    echo "  - 启动服务: sudo systemctl start ${SERVICE_NAME}"
    echo "  - 停止服务: sudo systemctl stop ${SERVICE_NAME}"
    echo "  - 重启服务: sudo systemctl restart ${SERVICE_NAME}"
    echo "  - 查看状态: sudo systemctl status ${SERVICE_NAME}"
    echo "  - 查看日志: sudo journalctl -u ${SERVICE_NAME} -f"
    echo
    echo "🌐 访问地址:"
    echo "  - 本地访问: http://localhost:8080"
    echo "  - 健康检查: http://localhost:8080/health"
    echo
    if grep -q "your_api_key_here" "${CONFIG_DIR}/env"; then
        print_warning "⚠️  请配置您的 API_KEY："
        echo "  1. 编辑配置文件: sudo nano ${CONFIG_DIR}/env"
        echo "  2. 设置 API_KEY=your_actual_api_key"
        echo "  3. 启动服务: sudo systemctl start ${SERVICE_NAME}"
    fi
}

# 主函数
main() {
    echo "🚀 提示词优化工具安装脚本 v${SCRIPT_VERSION}"
    echo "========================================"
    echo
    
    # 检查权限
    check_root
    
    # 检查依赖
    check_dependencies
    
    # 检查现有安装
    if check_existing_installation; then
        print_info "这将更新现有安装"
        read -p "继续吗? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "安装已取消"
            exit 0
        fi
        stop_existing_service
    fi
    
    # 执行安装步骤
    setup_directories
    install_application
    create_config
    create_systemd_service
    setup_caddy_config
    start_service
    show_installation_info
}

# 脚本参数处理
case "${1:-}" in
    --help|-h)
        echo "用法: $0 [选项]"
        echo
        echo "选项:"
        echo "  --help, -h    显示此帮助信息"
        echo "  --version, -v 显示版本信息"
        echo
        echo "环境变量:"
        echo "  SKIP_START=1  跳过服务启动"
        exit 0
        ;;
    --version|-v)
        echo "提示词优化工具安装脚本 v${SCRIPT_VERSION}"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac