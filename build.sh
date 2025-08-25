#!/bin/bash

# 提示词优化工具构建脚本
# Build script for prompt optimization tool

set -e

echo "🚀 开始构建提示词优化工具..."

# 设置变量
APP_NAME="prompt-optimize"
BUILD_DIR="build"
DIST_DIR="dist"

# 清理旧的构建文件
echo "🧹 清理旧的构建文件..."
rm -rf ${BUILD_DIR}
rm -rf ${DIST_DIR}
mkdir -p ${BUILD_DIR}
mkdir -p ${DIST_DIR}

# 构建 Linux 版本
echo "🐧 构建 Linux amd64 版本..."
env GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o ${BUILD_DIR}/${APP_NAME}-linux-amd64 .

# 构建 Linux ARM64 版本（适用于一些云服务器）
echo "🐧 构建 Linux arm64 版本..."
env GOOS=linux GOARCH=arm64 go build -ldflags="-w -s" -o ${BUILD_DIR}/${APP_NAME}-linux-arm64 .

# 构建本地版本（用于测试）
echo "💻 构建本地版本..."
go build -ldflags="-w -s" -o ${BUILD_DIR}/${APP_NAME} .

# 创建部署包
echo "📦 创建部署包..."

# Linux amd64 部署包
mkdir -p ${DIST_DIR}/linux-amd64
cp ${BUILD_DIR}/${APP_NAME}-linux-amd64 ${DIST_DIR}/linux-amd64/${APP_NAME}
chmod +x ${DIST_DIR}/linux-amd64/${APP_NAME}

# Linux arm64 部署包
mkdir -p ${DIST_DIR}/linux-arm64
cp ${BUILD_DIR}/${APP_NAME}-linux-arm64 ${DIST_DIR}/linux-arm64/${APP_NAME}
chmod +x ${DIST_DIR}/linux-arm64/${APP_NAME}

echo "✅ 构建完成！"
echo ""
echo "📋 构建结果:"
echo "  - Linux amd64: ${DIST_DIR}/linux-amd64/${APP_NAME}"
echo "  - Linux arm64: ${DIST_DIR}/linux-arm64/${APP_NAME}"
echo "  - 本地测试版: ${BUILD_DIR}/${APP_NAME}"
echo ""
echo "📝 部署说明:"
echo "  1. 将对应架构的二进制文件上传到服务器"
echo "  2. 设置环境变量: API_KEY, BASE_URL, MODEL"
echo "  3. 运行: ./${APP_NAME}"
echo "  4. 使用 Caddy 反向代理到应用端口（默认8080）"