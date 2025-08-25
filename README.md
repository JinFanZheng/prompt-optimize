# 🚀 提示词优化工具

基于 Go + Gin + HTML + DaisyUI 开发的 AI 提示词优化工具，集成 OpenAI API，提供专业的提示词优化服务。

## ✨ 功能特性

- 🧠 **智能分析**: 深度理解用户需求，分析提示词核心要素
- 🔧 **专业优化**: 基于最新的 AI 提示词工程技术
- 🚀 **即时生成**: 快速生成高质量的优化提示词
- 📱 **响应式设计**: 支持桌面和移动设备
- 🔒 **安全可靠**: 内置安全头设置和内容安全策略
- 🐳 **易于部署**: 单一二进制文件，支持多架构

## 🛠️ 技术栈

- **后端**: Go + Gin
- **前端**: HTML + DaisyUI + TailwindCSS
- **AI 集成**: OpenAI API / 兼容接口
- **部署**: Caddy + Linux
- **构建**: 嵌入式静态资源

## 🚀 快速开始

### 环境要求

- Go 1.21+
- 有效的 OpenAI API Key 或兼容的 API 服务

### 本地开发

1. **克隆项目**
   ```bash
   git clone https://github.com/JinFanZheng/prompt-optimize.git
   cd prompt-optimize
   ```

2. **安装依赖**
   ```bash
   go mod tidy
   ```

3. **配置环境变量**
   ```bash
   cp .env.example .env
   # 编辑 .env 文件，设置您的 API_KEY
   ```

4. **运行项目**
   ```bash
   # 设置环境变量
   export API_KEY="your-api-key-here"
   export BASE_URL="https://api.openai.com/v1"
   export MODEL="gpt-3.5-turbo"
   
   # 运行
   go run main.go
   ```

5. **访问应用**
   
   打开浏览器访问: http://localhost:8080

### 生产部署

#### 🚀 一键安装/升级（推荐）

**在目标服务器上运行一行命令即可完成安装：**

```bash
# 方式1: 使用curl（推荐）
curl -fsSL https://raw.githubusercontent.com/JinFanZheng/prompt-optimize/main/quick-install.sh | sudo bash

# 方式2: 使用wget
wget -qO- https://raw.githubusercontent.com/JinFanZheng/prompt-optimize/main/quick-install.sh | sudo bash
```

#### ⚙️ 远程部署脚本

如果你可以SSH到服务器，可以使用远程部署脚本：

```bash
# 基本用法
./remote-deploy.sh your-server.com

# 指定SSH参数
./remote-deploy.sh -u ubuntu -p 2222 your-server.com

# 使用SSH密钥
./remote-deploy.sh --key ~/.ssh/id_rsa your-server.com

# 模拟运行
./remote-deploy.sh --dry-run your-server.com
```

#### 🔄 升级现有安装

```bash
# 本地升级（在服务器上运行）
sudo ./upgrade.sh

# 远程升级（从本地运行）
./remote-deploy.sh your-server.com
```

#### 手动构建部署

#### 1. 构建应用

```bash
# 构建 Linux 版本
./build.sh
```

构建完成后，在 `dist` 目录下会生成对应架构的可执行文件。

#### 2. 服务器部署

将构建好的二进制文件上传到服务器：

```bash
# 上传二进制文件
scp dist/linux-amd64/prompt-optimize user@your-server:/path/to/app/

# 上传部署脚本
scp deploy.sh user@your-server:/path/to/app/

# 在服务器上运行部署脚本
sudo ./deploy.sh
```

#### 3. 配置环境变量

编辑配置文件：

```bash
sudo nano /etc/prompt-optimize/env
```

设置您的 API 配置：

```env
API_KEY=your_api_key_here
BASE_URL=https://api.openai.com/v1
MODEL=gpt-3.5-turbo
PORT=8080
GIN_MODE=release
```

#### 4. 启动服务

```bash
# 启动服务
sudo systemctl start prompt-optimize

# 设置开机自启
sudo systemctl enable prompt-optimize

# 查看服务状态
sudo systemctl status prompt-optimize

# 查看日志
sudo journalctl -u prompt-optimize -f
```

#### 5. 配置 Caddy（一键配置）

**🚀 一键配置Caddy和域名：**

```bash
# 下载并运行Caddy配置脚本
curl -fsSL https://raw.githubusercontent.com/JinFanZheng/prompt-optimize/main/setup-caddy.sh | sudo bash -s prompt.example.com

# 或者交互式配置
curl -fsSL https://raw.githubusercontent.com/JinFanZheng/prompt-optimize/main/setup-caddy.sh | sudo bash
```

**手动配置（如果需要）：**

1. **安装 Caddy**（如果未安装）
   ```bash
   sudo apt update
   sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
   curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
   curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
   sudo apt update
   sudo apt install caddy
   ```

2. **配置域名**
   ```bash
   # 编辑站点配置
   sudo nano /etc/caddy/conf.d/prompt-optimize.conf
   # 将 your-domain.com 替换为您的实际域名
   ```

3. **重新加载配置**
   ```bash
   sudo systemctl reload caddy
   ```

## 🔧 配置选项

| 环境变量 | 说明 | 默认值 |
|---------|------|--------|
| `API_KEY` | OpenAI API 密钥 | **必须设置** |
| `BASE_URL` | API 基础 URL | `https://api.openai.com/v1` |
| `MODEL` | 使用的模型 | `gpt-3.5-turbo` |
| `PORT` | 应用端口 | `8080` |
| `GIN_MODE` | Gin 运行模式 | `release` |

## 📡 API 接口

### POST /api/optimize

优化提示词接口

**请求体：**
```json
{
  "input": "用户的提示词需求描述"
}
```

**响应：**
```json
{
  "result": "优化后的提示词内容",
  "error": "错误信息（如有）"
}
```

### GET /health

健康检查接口

**响应：**
```json
{
  "status": "ok"
}
```

## 🔒 安全特性

- ✅ HTTPS 强制重定向
- ✅ 安全响应头设置
- ✅ 内容安全策略 (CSP)
- ✅ XSS 防护
- ✅ 点击劫持防护
- ✅ MIME 类型嗅探防护

## 🧪 测试

```bash
# 运行测试
go test ./...

# 测试 API 接口
curl -X POST http://localhost:8080/api/optimize \
  -H "Content-Type: application/json" \
  -d '{"input": "帮我优化一个写作助手的提示词"}'
```

## 📋 项目结构

```
prompt-optimize/
├── main.go              # 主程序文件
├── prompt.txt           # 元提示词文件
├── go.mod              # Go 模块定义
├── build.sh            # 构建脚本
├── deploy.sh           # 部署脚本
├── Caddyfile           # Caddy 配置
├── .env.example        # 环境变量示例
├── static/             # 静态资源
│   ├── css/
│   │   └── style.css
│   └── js/
│       └── app.js
├── templates/          # HTML 模板
│   └── index.html
├── build/              # 构建输出（构建后生成）
└── dist/               # 发布文件（构建后生成）
    ├── linux-amd64/
    └── linux-arm64/
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

## 📞 支持

如果您在使用过程中遇到任何问题，请：

1. 查看 [Issues](https://github.com/JinFanZheng/prompt-optimize/issues)
2. 提交新的 Issue
3. 查看部署日志：`sudo journalctl -u prompt-optimize -f`