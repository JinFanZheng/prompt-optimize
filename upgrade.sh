#!/bin/bash

# 提示词优化工具 - 升级脚本
# Prompt Optimization Tool - Upgrade Script

set -e

# 配置变量
SCRIPT_VERSION="1.0.0"
APP_NAME="prompt-optimize"
SERVICE_NAME="prompt-optimize"
APP_DIR="/opt/${APP_NAME}"
CONFIG_DIR="/etc/${APP_NAME}"
BACKUP_DIR="/opt/${APP_NAME}/backups"

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

# 检查现有安装
check_existing_installation() {
    print_info "检查现有安装..."
    
    if [ ! -f "${APP_DIR}/${APP_NAME}" ]; then
        print_error "未找到现有安装，请先使用 install.sh 进行安装"
        exit 1
    fi
    
    if [ ! -f "/etc/systemd/system/${SERVICE_NAME}.service" ]; then
        print_error "未找到系统服务，请先使用 install.sh 进行安装"
        exit 1
    fi
    
    print_success "检测到现有安装"
}

# 获取当前版本信息
get_current_version() {
    print_info "获取当前版本信息..."
    
    if systemctl is-active --quiet ${SERVICE_NAME}; then
        echo "  - 服务状态: 运行中"
    else
        echo "  - 服务状态: 已停止"
    fi
    
    # 获取二进制文件信息
    if [ -f "${APP_DIR}/${APP_NAME}" ]; then
        local file_date=$(stat -c %y "${APP_DIR}/${APP_NAME}" 2>/dev/null || stat -f "%Sm" "${APP_DIR}/${APP_NAME}" 2>/dev/null || echo "未知")
        echo "  - 当前二进制文件时间: $file_date"
    fi
    
    # 检查配置文件
    if [ -f "${CONFIG_DIR}/env" ]; then
        echo "  - 配置文件: 存在"
    else
        print_warning "配置文件不存在"
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

# 创建备份
create_backup() {
    print_info "创建备份..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${BACKUP_DIR}/${timestamp}"
    
    mkdir -p "${backup_path}"
    
    # 备份二进制文件
    if [ -f "${APP_DIR}/${APP_NAME}" ]; then
        cp "${APP_DIR}/${APP_NAME}" "${backup_path}/${APP_NAME}.backup"
        print_success "二进制文件已备份"
    fi
    
    # 备份配置文件
    if [ -f "${CONFIG_DIR}/env" ]; then
        cp "${CONFIG_DIR}/env" "${backup_path}/env.backup"
        print_success "配置文件已备份"
    fi
    
    # 备份系统服务文件
    if [ -f "/etc/systemd/system/${SERVICE_NAME}.service" ]; then
        cp "/etc/systemd/system/${SERVICE_NAME}.service" "${backup_path}/${SERVICE_NAME}.service.backup"
        print_success "系统服务文件已备份"
    fi
    
    print_success "备份完成: ${backup_path}"
    export BACKUP_PATH="${backup_path}"
}

# 停止服务
stop_service() {
    print_info "停止服务..."
    
    if systemctl is-active --quiet ${SERVICE_NAME}; then
        systemctl stop ${SERVICE_NAME}
        print_success "服务已停止"
    else
        print_info "服务已经停止"
    fi
}

# 升级应用
upgrade_application() {
    local arch=$(detect_arch)
    local binary_path="dist/linux-${arch}/${APP_NAME}"
    
    print_info "升级 ${APP_NAME} (架构: ${arch})..."
    
    # 检查新的二进制文件是否存在
    if [ ! -f "${binary_path}" ]; then
        print_error "找不到新的二进制文件: ${binary_path}"
        print_info "请先运行 './build.sh' 来构建新版本"
        exit 1
    fi
    
    # 比较文件
    if [ -f "${APP_DIR}/${APP_NAME}" ]; then
        local old_md5=$(md5sum "${APP_DIR}/${APP_NAME}" | cut -d' ' -f1)
        local new_md5=$(md5sum "${binary_path}" | cut -d' ' -f1)
        
        if [ "$old_md5" = "$new_md5" ]; then
            print_warning "新版本与当前版本相同，无需升级"
            read -p "是否强制升级? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_info "升级已取消"
                exit 0
            fi
        else
            print_info "检测到新版本，继续升级..."
        fi
    fi
    
    # 替换二进制文件
    cp "${binary_path}" "${APP_DIR}/${APP_NAME}"
    chmod +x "${APP_DIR}/${APP_NAME}"
    chown prompt-optimize:prompt-optimize "${APP_DIR}/${APP_NAME}" 2>/dev/null || chown www-data:www-data "${APP_DIR}/${APP_NAME}"
    
    print_success "应用程序升级完成"
}

# 更新系统服务（如果需要）
update_systemd_service() {
    print_info "检查系统服务配置..."
    
    # 如果有新的服务配置，可以在这里更新
    # 目前保持现有配置不变
    
    # 重新加载 systemd
    systemctl daemon-reload
    
    print_success "系统服务配置已更新"
}

# 启动服务
start_service() {
    print_info "启动服务..."
    
    systemctl start ${SERVICE_NAME}
    
    # 等待服务启动
    sleep 3
    
    if systemctl is-active --quiet ${SERVICE_NAME}; then
        print_success "服务启动成功！"
        
        # 测试健康检查
        if curl -s http://localhost:8092/health > /dev/null; then
            print_success "健康检查通过"
        else
            print_warning "健康检查失败，请检查日志"
            print_info "查看日志: sudo journalctl -u ${SERVICE_NAME} -n 20"
        fi
    else
        print_error "服务启动失败"
        print_error "正在回滚到备份版本..."
        
        # 回滚
        rollback_from_backup
        exit 1
    fi
}

# 从备份回滚
rollback_from_backup() {
    if [ -n "${BACKUP_PATH}" ] && [ -f "${BACKUP_PATH}/${APP_NAME}.backup" ]; then
        print_warning "正在回滚..."
        
        cp "${BACKUP_PATH}/${APP_NAME}.backup" "${APP_DIR}/${APP_NAME}"
        chmod +x "${APP_DIR}/${APP_NAME}"
        chown prompt-optimize:prompt-optimize "${APP_DIR}/${APP_NAME}" 2>/dev/null || chown www-data:www-data "${APP_DIR}/${APP_NAME}"
        
        systemctl start ${SERVICE_NAME}
        
        if systemctl is-active --quiet ${SERVICE_NAME}; then
            print_success "回滚成功，服务已恢复"
        else
            print_error "回滚失败，请手动检查"
        fi
    else
        print_error "没有可用的备份文件"
    fi
}

# 清理旧备份
cleanup_old_backups() {
    print_info "清理旧备份文件..."
    
    if [ -d "${BACKUP_DIR}" ]; then
        # 保留最近的5个备份
        local backup_count=$(ls -1 "${BACKUP_DIR}" | wc -l)
        if [ "$backup_count" -gt 5 ]; then
            local to_delete=$((backup_count - 5))
            ls -1t "${BACKUP_DIR}" | tail -n $to_delete | while read backup; do
                rm -rf "${BACKUP_DIR}/$backup"
                print_info "删除旧备份: $backup"
            done
        fi
    fi
    
    print_success "备份清理完成"
}

# 显示升级信息
show_upgrade_info() {
    print_success "🎉 升级完成！"
    echo
    echo "📋 服务信息:"
    echo "  - 服务状态: $(systemctl is-active ${SERVICE_NAME})"
    echo "  - 备份路径: ${BACKUP_PATH}"
    echo
    echo "🔧 常用命令:"
    echo "  - 查看状态: sudo systemctl status ${SERVICE_NAME}"
    echo "  - 查看日志: sudo journalctl -u ${SERVICE_NAME} -f"
    echo "  - 重启服务: sudo systemctl restart ${SERVICE_NAME}"
    echo
    echo "🌐 访问地址:"
    echo "  - 本地访问: http://localhost:8092"
    echo "  - 健康检查: http://localhost:8092/health"
    echo
    if [ -n "${BACKUP_PATH}" ]; then
        echo "🔄 如需回滚:"
        echo "  1. sudo systemctl stop ${SERVICE_NAME}"
        echo "  2. sudo cp ${BACKUP_PATH}/${APP_NAME}.backup ${APP_DIR}/${APP_NAME}"
        echo "  3. sudo systemctl start ${SERVICE_NAME}"
    fi
}

# 显示帮助
show_help() {
    cat << EOF
🔄 提示词优化工具升级脚本 v${SCRIPT_VERSION}

用法: $0 [选项]

选项:
  --force           强制升级，即使版本相同
  --skip-backup     跳过备份创建
  --dry-run         模拟运行，显示将要执行的操作
  -h, --help        显示此帮助信息
  -v, --version     显示版本信息

示例:
  $0                # 正常升级
  $0 --force        # 强制升级
  $0 --dry-run      # 模拟运行

注意:
  - 请确保在运行此脚本前已执行 ./build.sh
  - 升级前会自动创建备份
  - 如果升级失败，会自动回滚到备份版本
EOF
}

# 主函数
main() {
    local force_upgrade=false
    local skip_backup=false
    local dry_run=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force_upgrade=true
                shift
                ;;
            --skip-backup)
                skip_backup=true
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
                echo "升级脚本 v${SCRIPT_VERSION}"
                exit 0
                ;;
            *)
                print_error "未知选项: $1"
                echo "使用 $0 --help 查看帮助"
                exit 1
                ;;
        esac
    done
    
    echo "🔄 提示词优化工具升级脚本 v${SCRIPT_VERSION}"
    echo "======================================"
    echo
    
    if $dry_run; then
        print_warning "⚠️  模拟运行模式 - 不会实际执行操作"
        echo
    fi
    
    # 检查权限和现有安装
    check_root
    check_existing_installation
    get_current_version
    
    echo
    if ! $dry_run; then
        read -p "确认升级吗? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "升级已取消"
            exit 0
        fi
    fi
    
    # 执行升级步骤
    if ! $skip_backup; then
        create_backup
    fi
    
    if ! $dry_run; then
        stop_service
        upgrade_application
        update_systemd_service
        start_service
        cleanup_old_backups
        show_upgrade_info
    else
        print_info "[DRY RUN] 会执行以下步骤:"
        echo "  1. 停止服务"
        echo "  2. 升级应用程序"
        echo "  3. 更新系统服务"
        echo "  4. 启动服务"
        echo "  5. 清理旧备份"
    fi
}

# 脚本参数处理
case "${1:-}" in
    --help|-h)
        show_help
        exit 0
        ;;
    --version|-v)
        echo "升级脚本 v${SCRIPT_VERSION}"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac