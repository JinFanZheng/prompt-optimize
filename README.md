# 🚀 提示词优化工具

基于 Go + Gin + HTML + DaisyUI 开发的 AI 提示词优化工具，集成 OpenAI API，提供专业的提示词优化服务。

## 🆕 V2.0 新版本发布！

### 🌟 V2.0 重大更新
- **🤖 多模型支持**: 支持 Claude 4、GPT-4、Gemini 2.5、DeepSeek R1 等主流AI模型
- **📊 结构化输出**: 返回JSON格式的结构化数据，包含使用指南、测试用例和优化说明
- **⚡ 批量生成**: 一键生成多个AI模型的专用优化版本
- **🎛️ 高级配置**: 支持复杂度级别、任务类型等详细配置选项
- **📋 使用指南**: 自动生成详细的使用说明和测试建议
- **💡 优化说明**: 提供技术详解和优化思路说明

### 📍 版本访问
- **V1 版本**: `http://your-domain.com/` (保持兼容)
- **V2 版本**: `http://your-domain.com/v2` (全新功能)

## ✨ 功能特性

### V1 版本功能
- 🧠 **智能分析**: 深度理解用户需求，分析提示词核心要素
- 🔧 **专业优化**: 基于最新的 AI 提示词工程技术
- 🚀 **即时生成**: 快速生成高质量的优化提示词
- 📱 **响应式设计**: 支持桌面和移动设备

### V2 版本新增功能
- 🤖 **多模型支持**: Claude、GPT、Gemini、DeepSeek 四大主流模型
- 📊 **结构化数据**: JSON格式输出，便于程序化处理
- ⚡ **批量处理**: 一次生成多个模型的专用版本
- 🎯 **精准配置**: 复杂度、任务类型、语言等详细选项
- 📋 **完整指南**: 使用说明、测试用例、优化技术详解
- 🔄 **版本切换**: 随时在V1和V2之间切换使用

### 通用功能
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
   
   打开浏览器访问: http://localhost:8092

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
PORT=8092
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
| `PORT` | 应用端口 | `8092` |
| `GIN_MODE` | Gin 运行模式 | `release` |

## 📡 API 接口

### V1 API (兼容版本)

#### POST /api/optimize

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

### V2 API (新版本功能)

#### POST /api/v2/optimize

结构化优化提示词接口

**请求体：**
```json
{
  "input": "用户的提示词需求描述",
  "target_models": ["claude", "gpt"],
  "complexity_level": "medium",
  "task_type": "general",
  "language": "chinese",
  "generate_multi": false
}
```

**响应：**
```json
{
  "result": {
    "optimized_prompt": "优化后的完整提示词",
    "usage_guide": "使用指南和关键优化点",
    "test_cases": [
      {
        "input": "测试输入示例",
        "expected_behavior": "预期行为描述"
      }
    ],
    "model_versions": {
      "claude": "Claude专用优化版本",
      "gpt": "GPT专用优化版本",
      "gemini": "",
      "deepseek": ""
    },
    "optimization_notes": "优化技术说明和应用的方法",
    "metadata": {
      "complexity_level": "medium",
      "task_type": "general", 
      "estimated_tokens": 1200,
      "target_models": ["claude", "gpt"],
      "techniques_used": ["Chain-of-Thought", "Self-Consistency"]
    }
  },
  "error": "错误信息（如有）"
}
```

#### POST /api/v2/generate-multi

批量生成多模型版本

**请求体：**
```json
{
  "input": "用户的提示词需求描述",
  "target_models": ["claude", "gpt", "gemini", "deepseek"],
  "complexity_level": "complex",
  "task_type": "technical",
  "language": "chinese"
}
```

**响应格式同上，但会为所有指定模型生成专用版本**

#### GET /api/v2/models

获取支持的AI模型列表

**响应：**
```json
{
  "models": [
    {
      "id": "claude",
      "name": "Claude 4 (Sonnet/Opus)",
      "description": "Anthropic的Claude 4模型，擅长复杂推理和对话",
      "supported": true
    },
    {
      "id": "gpt", 
      "name": "GPT-4.1/GPT-4o",
      "description": "OpenAI的GPT-4系列模型，全能型AI助手",
      "supported": true
    }
  ]
}
```

### 通用接口

#### GET /health

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
curl -X POST http://localhost:8092/api/optimize \
  -H "Content-Type: application/json" \
  -d '{"input": "帮我优化一个写作助手的提示词"}'
```

## 📋 项目结构

```
prompt-optimize/
├── main.go              # 主程序文件（包含V1和V2版本）
├── prompt.txt           # V1元提示词文件
├── prompt-v2.txt        # V2结构化元提示词文件
├── go.mod              # Go 模块定义
├── build.sh            # 构建脚本
├── deploy.sh           # 部署脚本
├── Caddyfile           # Caddy 配置
├── .env.example        # 环境变量示例
├── static/             # 静态资源
│   ├── css/
│   │   ├── style.css      # V1样式文件
│   │   └── style-v2.css   # V2样式文件
│   └── js/
│       ├── app.js         # V1前端逻辑
│       └── app-v2.js      # V2前端逻辑
├── templates/          # HTML 模板
│   ├── index.html         # V1界面模板
│   └── index-v2.html      # V2界面模板
├── build/              # 构建输出（构建后生成）
└── dist/               # 发布文件（构建后生成）
    ├── linux-amd64/
    └── linux-arm64/
```

## 🔄 版本对比

| 功能 | V1版本 | V2版本 |
|------|--------|--------|
| 基础优化 | ✅ | ✅ |
| 多模型支持 | ❌ | ✅ |
| 结构化输出 | ❌ | ✅ |
| 批量生成 | ❌ | ✅ |
| 使用指南 | ❌ | ✅ |
| 测试用例 | ❌ | ✅ |
| 优化说明 | ❌ | ✅ |
| 高级配置 | ❌ | ✅ |
| 导出功能 | ❌ | ✅ |
| API兼容性 | V1 API | V1 + V2 API |

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

## 📞 支持

如果您在使用过程中遇到任何问题，请：

1. 查看 [Issues](https://github.com/JinFanZheng/prompt-optimize/issues)
2. 提交新的 Issue
3. 查看部署日志：`sudo journalctl -u prompt-optimize -f`