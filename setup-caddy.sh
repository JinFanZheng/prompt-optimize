#!/bin/bash

# Caddy 域名配置脚本 - 一键设置提示词优化工具域名
# Caddy Domain Configuration Script for Prompt Optimization Tool

set -e

# 配置变量
SCRIPT_VERSION="1.0.0"
APP_NAME="prompt-optimize"
CADDY_CONF_DIR="/etc/caddy"
CADDY_SITES_DIR="${CADDY_CONF_DIR}/conf.d"
SITE_CONF_FILE="${CADDY_SITES_DIR}/${APP_NAME}.conf"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# 显示帮助
show_help() {
    cat << EOF
🌐 Caddy域名配置脚本 v${SCRIPT_VERSION}

用法: $0 [选项] [域名]

参数:
  [域名]              要配置的域名 (可选，如不提供将交互式询问)

选项:
  --port PORT         应用端口 (默认: 8080)
  --email EMAIL       Let's Encrypt 邮箱地址
  --no-ssl            不启用SSL/TLS (仅HTTP)
  --backup            备份现有配置
  --remove            移除配置
  --dry-run           模拟运行
  -h, --help          显示此帮助信息
  -v, --version       显示版本信息

示例:
  $0 prompt.example.com
  $0 --email admin@example.com ai-tool.mydomain.com
  $0 --port 8888 --no-ssl test.local
  $0 --remove         # 移除配置
  $0 --backup         # 仅备份配置

功能:
  - 自动检测Caddy安装
  - 智能配置域名和SSL证书
  - 支持多域名和子域名
  - 自动备份现有配置
  - 配置验证和语法检查
  - 一键移除配置
EOF
}

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "请以root用户身份运行此脚本"
        echo "使用命令: sudo $0 $@"
        exit 1
    fi
}

# 检查Caddy是否安装
check_caddy() {
    print_info "检查Caddy安装..."
    
    if ! command -v caddy &> /dev/null; then
        print_error "未检测到Caddy，正在安装..."
        install_caddy
    fi
    
    if ! systemctl is-enabled caddy &> /dev/null; then
        print_warning "Caddy服务未启用，正在启用..."
        systemctl enable caddy
    fi
    
    print_success "Caddy检查完成"
}

# 安装Caddy
install_caddy() {
    print_info "安装Caddy..."
    
    # 检测系统类型
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu
        apt update
        apt install -y debian-keyring debian-archive-keyring apt-transport-https
        curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
        curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
        apt update
        apt install -y caddy
    elif [ -f /etc/redhat-release ]; then
        # RHEL/CentOS
        yum install -y yum-plugin-copr
        yum copr enable -y @caddy/caddy
        yum install -y caddy
    else
        print_error "不支持的系统，请手动安装Caddy"
        exit 1
    fi
    
    # 启动Caddy
    systemctl enable caddy
    systemctl start caddy
    
    print_success "Caddy安装完成"
}

# 创建配置目录
setup_directories() {
    print_info "设置配置目录..."
    
    mkdir -p "$CADDY_SITES_DIR"
    mkdir -p "/var/log/caddy"
    
    # 确保主配置文件存在并包含import指令
    if [ ! -f "${CADDY_CONF_DIR}/Caddyfile" ]; then
        echo "# Caddy 主配置文件" > "${CADDY_CONF_DIR}/Caddyfile"
        echo "import conf.d/*.conf" >> "${CADDY_CONF_DIR}/Caddyfile"
    elif ! grep -q "import conf.d/\*.conf" "${CADDY_CONF_DIR}/Caddyfile"; then
        echo "" >> "${CADDY_CONF_DIR}/Caddyfile"
        echo "# 导入站点配置" >> "${CADDY_CONF_DIR}/Caddyfile"
        echo "import conf.d/*.conf" >> "${CADDY_CONF_DIR}/Caddyfile"
    fi
    
    print_success "配置目录设置完成"
}

# 备份现有配置
backup_config() {
    if [ -f "$SITE_CONF_FILE" ]; then
        local backup_file="${SITE_CONF_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$SITE_CONF_FILE" "$backup_file"
        print_success "配置已备份到: $backup_file"
    fi
}

# 获取域名
get_domain() {
    local domain="$1"
    
    if [ -z "$domain" ]; then
        echo
        print_info "请输入您的域名配置："
        echo "  例如: prompt.example.com"
        echo "  例如: ai-tool.mydomain.org"
        echo "  例如: localhost (测试用)"
        echo
        read -p "域名: " domain
        
        if [ -z "$domain" ]; then
            print_error "域名不能为空"
            exit 1
        fi
    fi
    
    echo "$domain"
}

# 验证域名格式
validate_domain() {
    local domain="$1"
    
    # 基本域名格式检查
    if [[ ! "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$ ]] && [[ "$domain" != "localhost" ]]; then
        print_error "无效的域名格式: $domain"
        exit 1
    fi
    
    print_success "域名格式验证通过"
}

# 检测应用是否运行
check_app_running() {
    local port="$1"
    
    if ! systemctl is-active --quiet "$APP_NAME"; then
        print_warning "${APP_NAME} 服务未运行"
        read -p "是否现在启动服务? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            systemctl start "$APP_NAME" || {
                print_error "无法启动 ${APP_NAME} 服务"
                print_info "请检查服务配置: systemctl status $APP_NAME"
                exit 1
            }
        fi
    fi
    
    # 检查端口是否监听
    if ! netstat -tuln 2>/dev/null | grep -q ":$port " && ! ss -tuln 2>/dev/null | grep -q ":$port "; then
        print_warning "端口 $port 未监听，请检查应用配置"
    fi
}

# 生成Caddy配置
generate_caddy_config() {
    local domain="$1"
    local port="$2"
    local email="$3"
    local no_ssl="$4"
    
    print_info "生成Caddy配置..."
    
    cat > "$SITE_CONF_FILE" << EOF
# 提示词优化工具 - Caddy配置
# Generated by setup-caddy.sh v${SCRIPT_VERSION}
# Generated at: $(date)

EOF

    # SSL配置
    if [ "$no_ssl" = "true" ] || [ "$domain" = "localhost" ]; then
        cat >> "$SITE_CONF_FILE" << EOF
http://$domain {
EOF
    else
        if [ -n "$email" ]; then
            cat >> "$SITE_CONF_FILE" << EOF
{
    email $email
}

$domain {
EOF
        else
            cat >> "$SITE_CONF_FILE" << EOF
$domain {
EOF
        fi
    fi

    # 主要配置
    cat >> "$SITE_CONF_FILE" << EOF
    # 反向代理到应用
    reverse_proxy localhost:$port {
        header_up Host {host}
        header_up X-Real-IP {remote}
        header_up X-Forwarded-For {remote}
        header_up X-Forwarded-Proto {scheme}
    }

    # 启用日志记录
    log {
        output file /var/log/caddy/${APP_NAME}.log {
            roll_size 10MB
            roll_keep 5
        }
        format json
        level INFO
    }

    # 启用压缩
    encode gzip zstd

    # 安全头设置
    header {
        # HSTS
        Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
        
        # XSS防护
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        X-XSS-Protection "1; mode=block"
        
        # 内容安全策略
        Content-Security-Policy "default-src 'self'; style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; script-src 'self' 'unsafe-inline' https://cdn.tailwindcss.com; font-src 'self' https://cdn.jsdelivr.net; img-src 'self' data:; connect-src 'self'"
        
        # 其他安全头
        Referrer-Policy "strict-origin-when-cross-origin"
        Permissions-Policy "geolocation=(), microphone=(), camera=()"
        
        # 隐藏服务器信息
        -Server
    }

    # 静态文件缓存
    @static path *.css *.js *.png *.jpg *.jpeg *.gif *.ico *.svg *.woff *.woff2 *.ttf *.eot
    header @static {
        Cache-Control "public, max-age=31536000, immutable"
    }

    # API请求不缓存
    @api path /api/*
    header @api {
        Cache-Control "no-cache, no-store, must-revalidate"
        Pragma "no-cache"
        Expires "0"
    }

    # 健康检查端点
    respond /health 200 {
        body "OK"
    }
}
EOF

    print_success "配置文件生成完成: $SITE_CONF_FILE"
}

# 验证配置
validate_config() {
    print_info "验证Caddy配置..."
    
    if caddy validate --config "${CADDY_CONF_DIR}/Caddyfile" 2>/dev/null; then
        print_success "配置验证通过"
    else
        print_error "配置验证失败"
        print_info "请检查配置文件: $SITE_CONF_FILE"
        caddy validate --config "${CADDY_CONF_DIR}/Caddyfile"
        exit 1
    fi
}

# 重新加载Caddy
reload_caddy() {
    print_info "重新加载Caddy配置..."
    
    if systemctl reload caddy; then
        print_success "Caddy配置已重新加载"
    else
        print_error "重新加载失败"
        print_info "查看错误: systemctl status caddy"
        exit 1
    fi
}

# 移除配置
remove_config() {
    print_info "移除Caddy配置..."
    
    if [ -f "$SITE_CONF_FILE" ]; then
        backup_config
        rm -f "$SITE_CONF_FILE"
        reload_caddy
        print_success "配置已移除并备份"
    else
        print_info "配置文件不存在"
    fi
}

# 测试配置
test_config() {
    local domain="$1"
    local no_ssl="$2"
    
    print_info "测试配置..."
    
    local protocol="https"
    if [ "$no_ssl" = "true" ] || [ "$domain" = "localhost" ]; then
        protocol="http"
    fi
    
    sleep 3  # 等待服务启动
    
    if curl -s -f "${protocol}://${domain}/health" > /dev/null; then
        print_success "配置测试成功！"
        echo "🌐 访问地址: ${protocol}://${domain}"
    else
        print_warning "健康检查失败，但这可能是正常的"
        echo "🌐 请尝试访问: ${protocol}://${domain}"
    fi
}

# 显示配置信息
show_config_info() {
    local domain="$1"
    local port="$2"
    local no_ssl="$3"
    
    local protocol="https"
    if [ "$no_ssl" = "true" ] || [ "$domain" = "localhost" ]; then
        protocol="http"
    fi
    
    print_success "🎉 Caddy配置完成！"
    echo
    echo "📋 配置信息:"
    echo "  - 域名: $domain"
    echo "  - 协议: $protocol"
    echo "  - 后端端口: $port"
    echo "  - 配置文件: $SITE_CONF_FILE"
    echo "  - 日志文件: /var/log/caddy/${APP_NAME}.log"
    echo
    echo "🌐 访问地址: ${protocol}://${domain}"
    echo
    echo "🔧 管理命令:"
    echo "  - 查看状态: sudo systemctl status caddy"
    echo "  - 重新加载: sudo systemctl reload caddy"
    echo "  - 查看日志: sudo tail -f /var/log/caddy/${APP_NAME}.log"
    echo "  - 移除配置: sudo $0 --remove"
    echo
    if [ "$protocol" = "https" ] && [ "$domain" != "localhost" ]; then
        echo "🔒 SSL证书:"
        echo "  - 自动申请Let's Encrypt证书"
        echo "  - 证书会在90天内自动续期"
        echo
        print_warning "如果是新域名，请确保DNS已正确解析到此服务器IP"
    fi
}

# 主函数
main() {
    local domain=""
    local port="8080"
    local email=""
    local no_ssl="false"
    local do_backup="false"
    local do_remove="false"
    local dry_run="false"
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --port)
                port="$2"
                shift 2
                ;;
            --email)
                email="$2"
                shift 2
                ;;
            --no-ssl)
                no_ssl="true"
                shift
                ;;
            --backup)
                do_backup="true"
                shift
                ;;
            --remove)
                do_remove="true"
                shift
                ;;
            --dry-run)
                dry_run="true"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "Caddy配置脚本 v${SCRIPT_VERSION}"
                exit 0
                ;;
            -*)
                print_error "未知选项: $1"
                echo "使用 $0 --help 查看帮助"
                exit 1
                ;;
            *)
                if [ -z "$domain" ]; then
                    domain="$1"
                else
                    print_error "多余的参数: $1"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    echo "🌐 Caddy域名配置脚本 v${SCRIPT_VERSION}"
    echo "================================="
    echo
    
    check_root
    
    # 处理特殊操作
    if [ "$do_remove" = "true" ]; then
        remove_config
        exit 0
    fi
    
    if [ "$do_backup" = "true" ]; then
        backup_config
        exit 0
    fi
    
    if [ "$dry_run" = "true" ]; then
        print_warning "模拟运行模式"
        echo
    fi
    
    # 主要配置流程
    check_caddy
    setup_directories
    
    domain=$(get_domain "$domain")
    validate_domain "$domain"
    
    if [ "$dry_run" = "false" ]; then
        backup_config
        check_app_running "$port"
        generate_caddy_config "$domain" "$port" "$email" "$no_ssl"
        validate_config
        reload_caddy
        test_config "$domain" "$no_ssl"
        show_config_info "$domain" "$port" "$no_ssl"
    else
        print_info "[DRY RUN] 会生成域名 $domain 的配置"
        print_info "[DRY RUN] 端口: $port, SSL: $([[ $no_ssl == "true" ]] && echo "否" || echo "是")"
    fi
}

main "$@"