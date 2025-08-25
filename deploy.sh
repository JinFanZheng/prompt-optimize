#!/bin/bash

# 服务器部署脚本
# Server deployment script for prompt optimization tool

set -e

# 配置变量
APP_NAME="prompt-optimize"
SERVICE_NAME="prompt-optimize"
SERVICE_USER="www-data"
APP_DIR="/opt/${APP_NAME}"
CONFIG_DIR="/etc/${APP_NAME}"
LOG_DIR="/var/log/${APP_NAME}"

echo "🚀 开始部署提示词优化工具到服务器..."

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请以 root 用户身份运行此脚本"
    exit 1
fi

# 创建应用目录
echo "📁 创建应用目录..."
mkdir -p ${APP_DIR}
mkdir -p ${CONFIG_DIR}
mkdir -p ${LOG_DIR}

# 停止现有服务（如果存在）
echo "🛑 停止现有服务..."
systemctl stop ${SERVICE_NAME} || true

# 复制二进制文件
echo "📋 复制应用文件..."
if [ -f "./${APP_NAME}" ]; then
    cp ./${APP_NAME} ${APP_DIR}/
    chmod +x ${APP_DIR}/${APP_NAME}
    chown ${SERVICE_USER}:${SERVICE_USER} ${APP_DIR}/${APP_NAME}
else
    echo "❌ 找不到应用二进制文件，请先运行构建脚本"
    exit 1
fi

# 设置目录权限
chown -R ${SERVICE_USER}:${SERVICE_USER} ${APP_DIR}
chown -R ${SERVICE_USER}:${SERVICE_USER} ${LOG_DIR}

# 创建环境配置文件模板
echo "📝 创建环境配置文件..."
cat > ${CONFIG_DIR}/env << EOF
# 提示词优化工具环境配置
# Prompt Optimization Tool Environment Configuration

# OpenAI API 配置
API_KEY=your_api_key_here
BASE_URL=https://api.openai.com/v1
MODEL=gpt-3.5-turbo

# 服务器配置
PORT=8080
GIN_MODE=release

# 日志配置
LOG_LEVEL=info
EOF

# 创建 systemd 服务文件
echo "⚙️ 创建系统服务..."
cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=Prompt Optimization Tool
After=network.target

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_USER}
WorkingDirectory=${APP_DIR}
ExecStart=${APP_DIR}/${APP_NAME}
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

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 并启用服务
echo "🔄 重新加载 systemd..."
systemctl daemon-reload
systemctl enable ${SERVICE_NAME}

# 提示用户配置环境变量
echo ""
echo "⚠️  请配置环境变量后再启动服务："
echo "   编辑文件: ${CONFIG_DIR}/env"
echo "   设置您的 API_KEY 等配置"
echo ""
echo "📋 完成配置后，使用以下命令："
echo "   启动服务: systemctl start ${SERVICE_NAME}"
echo "   查看状态: systemctl status ${SERVICE_NAME}"
echo "   查看日志: journalctl -u ${SERVICE_NAME} -f"
echo ""
echo "✅ 部署完成！"