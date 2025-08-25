# 🚀 部署指南

## 修复构建问题

构建脚本已修复，现在会自动下载依赖。重新运行：

```bash
./build.sh
```

## Caddy配置集成

由于服务器已有Caddy配置，有以下几种方式添加新站点：

### 方式1：编辑现有Caddyfile

编辑现有的Caddyfile，添加新站点配置：

```bash
sudo nano /etc/caddy/Caddyfile
```

将 `caddy-site.conf` 中的内容复制到Caddyfile的末尾，记得替换域名。

### 方式2：使用import指令（推荐）

如果现有Caddyfile支持import，可以：

```bash
# 复制配置文件到Caddy配置目录
sudo cp caddy-site.conf /etc/caddy/sites-available/prompt-optimize.conf

# 编辑主Caddyfile，添加import指令
echo "import sites-available/prompt-optimize.conf" | sudo tee -a /etc/caddy/Caddyfile
```

### 方式3：独立配置目录

如果使用目录化配置：

```bash
# 创建sites配置目录
sudo mkdir -p /etc/caddy/conf.d

# 复制配置文件
sudo cp caddy-site.conf /etc/caddy/conf.d/prompt-optimize.conf

# 在主Caddyfile中添加
echo "import conf.d/*.conf" | sudo tee -a /etc/caddy/Caddyfile
```

### 重新加载Caddy配置

添加配置后，重新加载Caddy：

```bash
# 检查配置语法
sudo caddy validate --config /etc/caddy/Caddyfile

# 重新加载配置
sudo systemctl reload caddy

# 查看状态
sudo systemctl status caddy
```

## 完整部署流程

```bash
# 1. 构建应用
./build.sh

# 2. 上传文件到服务器
scp dist/linux-amd64/prompt-optimize user@server:/tmp/
scp deploy.sh user@server:/tmp/
scp caddy-site.conf user@server:/tmp/

# 3. 在服务器上部署
ssh user@server
cd /tmp
sudo ./deploy.sh

# 4. 配置环境变量
sudo nano /etc/prompt-optimize/env
# 设置：API_KEY=your_api_key_here

# 5. 配置Caddy（选择上述方式之一）
sudo cp caddy-site.conf /etc/caddy/conf.d/prompt-optimize.conf
sudo nano /etc/caddy/conf.d/prompt-optimize.conf  # 替换域名
echo "import conf.d/*.conf" | sudo tee -a /etc/caddy/Caddyfile

# 6. 启动服务
sudo systemctl start prompt-optimize
sudo systemctl reload caddy

# 7. 验证部署
curl http://localhost:8080/health
curl https://your-domain.com/health
```

## 验证部署

```bash
# 检查应用状态
sudo systemctl status prompt-optimize
sudo journalctl -u prompt-optimize -n 20

# 检查Caddy状态
sudo systemctl status caddy
sudo journalctl -u caddy -n 20

# 测试API
curl -X POST https://your-domain.com/api/optimize \
  -H "Content-Type: application/json" \
  -d '{"input": "测试提示词优化"}'
```