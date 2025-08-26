package main

import (
	"context"
	"embed"
	"encoding/json"
	"fmt"
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

//go:embed prompt-v2.txt
var metaPromptV2 string

// V1 结构体
type OptimizeRequest struct {
	Input string `json:"input" binding:"required"`
}

type OptimizeResponse struct {
	Result string `json:"result"`
	Error  string `json:"error,omitempty"`
}

// V2 结构体
type OptimizeRequestV2 struct {
	Input           string   `json:"input" binding:"required"`
	TargetModels    []string `json:"target_models"`
	ComplexityLevel string   `json:"complexity_level"`
	TaskType        string   `json:"task_type"`
	GenerateMulti   bool     `json:"generate_multi"`
	Language        string   `json:"language"`
}

type TestCase struct {
	Input            string `json:"input"`
	ExpectedBehavior string `json:"expected_behavior"`
}

type ModelVersions struct {
	Claude   string `json:"claude"`
	GPT      string `json:"gpt"`
	Gemini   string `json:"gemini"`
	DeepSeek string `json:"deepseek"`
}

type Metadata struct {
	ComplexityLevel  string   `json:"complexity_level"`
	TaskType         string   `json:"task_type"`
	EstimatedTokens  int      `json:"estimated_tokens"`
	TargetModels     []string `json:"target_models"`
	TechniquesUsed   []string `json:"techniques_used"`
}

type StructuredResponse struct {
	OptimizedPrompt   string        `json:"optimized_prompt"`
	UsageGuide        string        `json:"usage_guide"`
	TestCases         []TestCase    `json:"test_cases"`
	ModelVersions     ModelVersions `json:"model_versions"`
	OptimizationNotes string        `json:"optimization_notes"`
	Metadata          Metadata      `json:"metadata"`
}

type OptimizeResponseV2 struct {
	Result StructuredResponse `json:"result,omitempty"`
	Error  string             `json:"error,omitempty"`
}

type ModelInfo struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Supported   bool   `json:"supported"`
}

type ModelsResponse struct {
	Models []ModelInfo `json:"models"`
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

	// V1 路由（保持兼容）
	router.GET("/", func(c *gin.Context) {
		c.HTML(http.StatusOK, "index.html", gin.H{
			"title": "提示词优化工具",
		})
	})

	// V2 路由
	router.GET("/v2", func(c *gin.Context) {
		c.HTML(http.StatusOK, "index-v2.html", gin.H{
			"title": "提示词优化工具 V2",
		})
	})

	// V1 API（保持兼容）
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

	// V2 API
	router.POST("/api/v2/optimize", func(c *gin.Context) {
		handleOptimizeV2(c, config)
	})

	router.POST("/api/v2/generate-multi", func(c *gin.Context) {
		handleGenerateMulti(c, config)
	})

	router.GET("/api/v2/models", handleGetModels)

	// 健康检查
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	log.Printf("服务器启动在端口 %s", config.Port)
	log.Printf("V1 版本: http://localhost:%s/", config.Port)
	log.Printf("V2 版本: http://localhost:%s/v2", config.Port)
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

// V2 优化处理函数
func handleOptimizeV2(c *gin.Context, config *Config) {
	var req OptimizeRequestV2
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, OptimizeResponseV2{
			Error: "无效的请求参数: " + err.Error(),
		})
		return
	}

	// 设置默认值
	if req.Language == "" {
		req.Language = "chinese"
	}
	if req.ComplexityLevel == "" {
		req.ComplexityLevel = "medium"
	}
	if req.TaskType == "" {
		req.TaskType = "general"
	}

	result, err := optimizePromptV2(config, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, OptimizeResponseV2{
			Error: "优化失败: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, OptimizeResponseV2{
		Result: result,
	})
}

// 批量生成多模型版本
func handleGenerateMulti(c *gin.Context, config *Config) {
	var req OptimizeRequestV2
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, OptimizeResponseV2{
			Error: "无效的请求参数: " + err.Error(),
		})
		return
	}

	// 强制开启多模型生成
	req.GenerateMulti = true
	if len(req.TargetModels) == 0 {
		req.TargetModels = []string{"claude", "gpt", "gemini", "deepseek"}
	}

	result, err := optimizePromptV2(config, req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, OptimizeResponseV2{
			Error: "批量生成失败: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, OptimizeResponseV2{
		Result: result,
	})
}

// 获取支持的模型列表
func handleGetModels(c *gin.Context) {
	models := []ModelInfo{
		{
			ID:          "claude",
			Name:        "Claude 4 (Sonnet/Opus)",
			Description: "Anthropic的Claude 4模型，擅长复杂推理和对话",
			Supported:   true,
		},
		{
			ID:          "gpt",
			Name:        "GPT-4.1/GPT-4o",
			Description: "OpenAI的GPT-4系列模型，全能型AI助手",
			Supported:   true,
		},
		{
			ID:          "gemini",
			Name:        "Gemini 2.5 Pro",
			Description: "Google的Gemini模型，支持大上下文窗口",
			Supported:   true,
		},
		{
			ID:          "deepseek",
			Name:        "DeepSeek R1",
			Description: "DeepSeek的推理模型，擅长数学和逻辑推理",
			Supported:   true,
		},
	}

	c.JSON(http.StatusOK, ModelsResponse{
		Models: models,
	})
}

func optimizePromptV2(config *Config, req OptimizeRequestV2) (StructuredResponse, error) {
	// 构建提示词
	prompt := buildPromptV2(req)

	// 创建 OpenAI 客户端
	clientConfig := openai.DefaultConfig(config.APIKey)
	if config.BaseURL != "" {
		clientConfig.BaseURL = config.BaseURL
	}
	client := openai.NewClientWithConfig(clientConfig)

	// 创建请求
	chatReq := openai.ChatCompletionRequest{
		Model: config.Model,
		Messages: []openai.ChatCompletionMessage{
			{
				Role:    openai.ChatMessageRoleUser,
				Content: prompt,
			},
		},
		MaxTokens:   12000,
		Temperature: 0.7,
	}

	// 发送请求
	resp, err := client.CreateChatCompletion(context.Background(), chatReq)
	if err != nil {
		return StructuredResponse{}, err
	}

	if len(resp.Choices) == 0 {
		return StructuredResponse{}, fmt.Errorf("没有收到响应")
	}

	responseText := resp.Choices[0].Message.Content

	// 解析JSON响应
	var structuredResp StructuredResponse
	err = json.Unmarshal([]byte(responseText), &structuredResp)
	if err != nil {
		// 如果JSON解析失败，尝试提取JSON部分
		jsonStart := strings.Index(responseText, "{")
		jsonEnd := strings.LastIndex(responseText, "}")
		if jsonStart >= 0 && jsonEnd > jsonStart {
			jsonPart := responseText[jsonStart : jsonEnd+1]
			err = json.Unmarshal([]byte(jsonPart), &structuredResp)
		}
		
		if err != nil {
			// 如果仍然失败，返回一个基本的结构化响应
			return StructuredResponse{
				OptimizedPrompt:   responseText,
				UsageGuide:        "原始AI响应，可能未按预期格式返回",
				TestCases:         []TestCase{},
				ModelVersions:     ModelVersions{},
				OptimizationNotes: "响应解析失败，显示原始内容",
				Metadata: Metadata{
					ComplexityLevel: req.ComplexityLevel,
					TaskType:        req.TaskType,
					EstimatedTokens: len(responseText) / 4, // 粗略估算
					TargetModels:    req.TargetModels,
					TechniquesUsed:  []string{"基础优化"},
				},
			}, nil
		}
	}

	return structuredResp, nil
}

func buildPromptV2(req OptimizeRequestV2) string {
	// 替换元提示词中的占位符
	prompt := strings.ReplaceAll(metaPromptV2, "{{input}}", req.Input)

	// 根据请求参数调整提示词
	additions := []string{}

	if req.Language != "" && req.Language != "chinese" {
		additions = append(additions, fmt.Sprintf("请使用%s语言回复", req.Language))
	}

	if len(req.TargetModels) > 0 {
		modelList := strings.Join(req.TargetModels, "、")
		additions = append(additions, fmt.Sprintf("请为以下AI模型生成特化版本：%s", modelList))
	}

	if req.ComplexityLevel != "" {
		additions = append(additions, fmt.Sprintf("复杂度级别：%s", req.ComplexityLevel))
	}

	if req.TaskType != "" {
		additions = append(additions, fmt.Sprintf("任务类型：%s", req.TaskType))
	}

	if req.GenerateMulti {
		additions = append(additions, "请生成多个AI模型的特化版本")
	}

	if len(additions) > 0 {
		prompt += "\n\n**额外要求：**\n"
		for _, addition := range additions {
			prompt += "- " + addition + "\n"
		}
	}

	return prompt
}
