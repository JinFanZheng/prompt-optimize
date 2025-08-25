package main

import (
	"testing"
)

func TestLoadConfig(t *testing.T) {
	// 设置测试环境变量
	t.Setenv("API_KEY", "test-key")
	t.Setenv("BASE_URL", "https://api.test.com/v1")
	t.Setenv("MODEL", "test-model")
	t.Setenv("PORT", "9090")

	config := loadConfig()

	if config.APIKey != "test-key" {
		t.Errorf("Expected API_KEY to be 'test-key', got %s", config.APIKey)
	}

	if config.BaseURL != "https://api.test.com/v1" {
		t.Errorf("Expected BASE_URL to be 'https://api.test.com/v1', got %s", config.BaseURL)
	}

	if config.Model != "test-model" {
		t.Errorf("Expected MODEL to be 'test-model', got %s", config.Model)
	}

	if config.Port != "9090" {
		t.Errorf("Expected PORT to be '9090', got %s", config.Port)
	}
}

func TestLoadConfigDefaults(t *testing.T) {
	// 设置最小必需环境变量
	t.Setenv("API_KEY", "test-key")

	config := loadConfig()

	if config.BaseURL != "https://api.openai.com/v1" {
		t.Errorf("Expected default BASE_URL to be 'https://api.openai.com/v1', got %s", config.BaseURL)
	}

	if config.Model != "gpt-3.5-turbo" {
		t.Errorf("Expected default MODEL to be 'gpt-3.5-turbo', got %s", config.Model)
	}

	if config.Port != "8080" {
		t.Errorf("Expected default PORT to be '8080', got %s", config.Port)
	}
}