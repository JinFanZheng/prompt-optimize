package main

import (
	"context"
	"embed"
	"html/template"
	"io/fs"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/sashabaranov/go-openai"
)

//go:embed static/* templates/*
var embedFS embed.FS

//go:embed prompt.txt
var metaPrompt string

type OptimizeRequest struct {
	Input string `json:"input" binding:"required"`
}

type OptimizeResponse struct {
	Result string `json:"result"`
	Error  string `json:"error,omitempty"`
}

type Config struct {
	APIKey  string
	BaseURL string
	Model   string
	Port    string
}

func loadConfig() *Config {
	config := &Config{
		APIKey:  os.Getenv("API_KEY"),
		BaseURL: os.Getenv("BASE_URL"),
		Model:   os.Getenv("MODEL"),
		Port:    os.Getenv("PORT"),
	}

	if config.APIKey == "" {
		log.Fatal("API_KEY environment variable is required")
	}

	if config.BaseURL == "" {
		config.BaseURL = "https://api.openai.com/v1"
	}

	if config.Model == "" {
		config.Model = "gpt-3.5-turbo"
	}

	if config.Port == "" {
		config.Port = "8092"
	}

	return config
}

func main() {
	config := loadConfig()

	// 设置 Gin 模式
	if os.Getenv("GIN_MODE") == "" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.Default()

	// 设置静态文件服务
	staticFS, err := fs.Sub(embedFS, "static")
	if err != nil {
		log.Fatal("Failed to get static files:", err)
	}
	router.StaticFS("/static", http.FS(staticFS))

	// 设置模板
	tmpl, err := template.ParseFS(embedFS, "templates/*.html")
	if err != nil {
		log.Fatal("Failed to parse templates:", err)
	}
	router.SetHTMLTemplate(tmpl)

	// 路由设置
	router.GET("/", func(c *gin.Context) {
		c.HTML(http.StatusOK, "index.html", gin.H{
			"title": "提示词优化工具",
		})
	})

	router.POST("/api/optimize", func(c *gin.Context) {
		var req OptimizeRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, OptimizeResponse{
				Error: "无效的请求参数",
			})
			return
		}

		result, err := optimizePrompt(config, req.Input)
		if err != nil {
			c.JSON(http.StatusInternalServerError, OptimizeResponse{
				Error: "优化失败: " + err.Error(),
			})
			return
		}

		c.JSON(http.StatusOK, OptimizeResponse{
			Result: result,
		})
	})

	// 健康检查
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	log.Printf("服务器启动在端口 %s", config.Port)
	log.Fatal(router.Run(":" + config.Port))
}

func optimizePrompt(config *Config, userInput string) (string, error) {
	// 替换元提示词中的 {{input}} 占位符
	prompt := strings.ReplaceAll(metaPrompt, "{{input}}", userInput)

	// 创建 OpenAI 客户端
	clientConfig := openai.DefaultConfig(config.APIKey)
	if config.BaseURL != "" {
		clientConfig.BaseURL = config.BaseURL
	}
	client := openai.NewClientWithConfig(clientConfig)

	// 创建请求
	req := openai.ChatCompletionRequest{
		Model: config.Model,
		Messages: []openai.ChatCompletionMessage{
			{
				Role:    openai.ChatMessageRoleUser,
				Content: prompt,
			},
		},
		MaxTokens:   10240,
		Temperature: 0.7,
	}

	// 发送请求
	resp, err := client.CreateChatCompletion(context.Background(), req)
	if err != nil {
		return "", err
	}

	if len(resp.Choices) == 0 {
		return "", nil
	}

	return resp.Choices[0].Message.Content, nil
}
