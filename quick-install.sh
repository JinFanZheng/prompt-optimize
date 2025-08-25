#!/bin/bash

# 提示词优化工具 - 快速安装脚本
# 从GitHub直接下载并安装/升级

set -e

# 配置变量
GITHUB_REPO="JinFanZheng/prompt-optimize"
GITHUB_RAW="https://raw.githubusercontent.com/${GITHUB_REPO}/main"
RELEASES_API="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
TEMP_DIR="/tmp/prompt-optimize-install"
APP_NAME="prompt-optimize"

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

# 检测架构
detect_arch() {
    case $(uname -m) in
        x86_64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        *) print_error "不支持的架构"; exit 1 ;;
    esac
}

# 检查是否为root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "请以root用户运行"
        exit 1
    fi
}

# 下载文件
download_file() {
    local url="$1"
    local dest="$2"
    print_info "下载: $(basename "$dest")"
    
    if command -v curl &> /dev/null; then
        if curl -L --connect-timeout 10 --max-time 300 --retry 3 --progress-bar "$url" -o "$dest"; then
            print_success "下载完成: $(basename "$dest")"
        else
            print_error "下载失败: $(basename "$dest")"
            exit 1
        fi
    elif command -v wget &> /dev/null; then
        if wget --timeout=10 --tries=3 --progress=bar --show-progress "$url" -O "$dest"; then
            print_success "下载完成: $(basename "$dest")"
        else
            print_error "下载失败: $(basename "$dest")"
            exit 1
        fi
    else
        print_error "需要curl或wget"
        exit 1
    fi
}

# 获取最新的release版本
get_latest_release() {
    local arch=$(detect_arch)
    print_info "获取最新版本..."
    
    # 尝试从GitHub Releases获取
    if command -v curl &> /dev/null; then
        local release_info=$(curl -s "$RELEASES_API" 2>/dev/null || echo "")
        if [ -n "$release_info" ] && [ "$release_info" != "Not Found" ]; then
            # 解析JSON获取assets中的下载链接
            local download_url=""
            if command -v jq &> /dev/null; then
                # 如果有jq，使用jq解析
                download_url=$(echo "$release_info" | jq -r ".assets[] | select(.name | contains(\"linux-${arch}\") and (contains(\".tar.gz\") | not) and (contains(\".zip\") | not)) | .browser_download_url" | head -1)
            else
                # 没有jq，使用grep解析
                download_url=$(echo "$release_info" | grep -o "https://github.com/${GITHUB_REPO}/releases/download/[^\"]*prompt-optimize-linux-${arch}\"" | sed 's/"$//' | head -1)
                if [ -z "$download_url" ]; then
                    # 尝试匹配不同的文件名格式
                    download_url=$(echo "$release_info" | grep -o "https://github.com/${GITHUB_REPO}/releases/download/[^\"]*linux-${arch}[^\"]*" | grep -v "\.tar\.gz" | grep -v "\.zip" | head -1)
                fi
            fi
            
            if [ -n "$download_url" ] && [ "$download_url" != "null" ]; then
                echo "$download_url"
                return 0
            fi
        fi
    fi
    
    # 如果没有找到release，返回空（使用源码方式）
    echo ""
}

# 主安装函数
main() {
    echo "🚀 提示词优化工具 - 快速安装"
    echo "================================"
    
    check_root
    
    local arch=$(detect_arch)
    print_info "系统架构: $arch"
    
    # 创建临时目录
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # 尝试获取release版本
    local release_url=$(get_latest_release)
    
    if [ -n "$release_url" ]; then
        print_info "使用预编译版本"
        download_file "$release_url" "${APP_NAME}"
        chmod +x "${APP_NAME}"
    else
        print_info "使用源码构建方式"
        
        # 检查Go环境
        if ! command -v go &> /dev/null; then
            print_error "需要Go环境，请先安装Go"
            print_info "Ubuntu: sudo apt install golang-go"
            print_info "CentOS: sudo yum install golang"
            exit 1
        fi
        
        # 下载源码
        print_info "下载源码..."
        if command -v git &> /dev/null; then
            git clone "https://github.com/${GITHUB_REPO}.git" .
        else
            # 下载zip包
            download_file "https://github.com/${GITHUB_REPO}/archive/main.zip" "source.zip"
            if command -v unzip &> /dev/null; then
                unzip -q source.zip
                mv "${GITHUB_REPO##*/}-main"/* .
            else
                print_error "需要unzip或git"
                exit 1
            fi
        fi
        
        # 构建
        print_info "构建应用..."
        go mod tidy
        env GOOS=linux GOARCH="$arch" go build -ldflags="-w -s" -o "${APP_NAME}" .
    fi
    
    # 下载安装脚本
    download_file "${GITHUB_RAW}/install.sh" "install.sh"
    chmod +x install.sh
    
    # 下载Caddy配置
    download_file "${GITHUB_RAW}/caddy-site.conf" "caddy-site.conf" || true
    
    # 创建dist目录结构（为了兼容install.sh）
    mkdir -p "dist/linux-${arch}"
    cp "${APP_NAME}" "dist/linux-${arch}/"
    
    # 执行安装
    print_info "执行安装..."
    ./install.sh
    
    # 清理
    cd /
    rm -rf "$TEMP_DIR"
    
    print_success "安装完成！"
    print_warning "请配置API_KEY: sudo nano /etc/${APP_NAME}/env"
    print_info "启动服务: sudo systemctl start ${APP_NAME}"
}

main "$@"