// 全局变量
let isOptimizing = false;

// DOM元素
const userInput = document.getElementById('userInput');
const optimizeBtn = document.getElementById('optimizeBtn');
const loadingSpinner = document.getElementById('loadingSpinner');
const btnText = document.getElementById('btnText');
const placeholder = document.getElementById('placeholder');
const result = document.getElementById('result');
const error = document.getElementById('error');
const optimizedPrompt = document.getElementById('optimizedPrompt');
const copyBtn = document.getElementById('copyBtn');
const copyText = document.getElementById('copyText');
const copiedText = document.getElementById('copiedText');
const errorMessage = document.getElementById('errorMessage');

// 事件监听器
document.addEventListener('DOMContentLoaded', function() {
    // 优化按钮点击事件
    optimizeBtn.addEventListener('click', handleOptimize);
    
    // 复制按钮点击事件
    copyBtn.addEventListener('click', handleCopy);
    
    // 输入框变化事件
    userInput.addEventListener('input', handleInputChange);
    
    // 回车键支持（Ctrl+Enter提交）
    userInput.addEventListener('keydown', function(e) {
        if (e.ctrlKey && e.key === 'Enter') {
            handleOptimize();
        }
    });
});

// 处理输入变化
function handleInputChange() {
    const inputValue = userInput.value.trim();
    optimizeBtn.disabled = inputValue === '' || isOptimizing;
}

// 处理优化请求
async function handleOptimize() {
    const inputValue = userInput.value.trim();
    
    if (!inputValue) {
        showError('请输入您的提示词需求');
        return;
    }
    
    if (isOptimizing) {
        return;
    }
    
    try {
        // 设置加载状态
        setLoadingState(true);
        hideAllResults();
        
        // 发送请求
        const response = await fetch('/api/optimize', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                input: inputValue
            })
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            throw new Error(data.error || `服务器错误: ${response.status}`);
        }
        
        if (data.error) {
            throw new Error(data.error);
        }
        
        // 显示结果
        showResult(data.result);
        
    } catch (err) {
        console.error('优化失败:', err);
        showError(err.message || '优化过程中发生未知错误');
    } finally {
        setLoadingState(false);
    }
}

// 处理复制功能
async function handleCopy() {
    try {
        const text = optimizedPrompt.textContent;
        
        if (!text) {
            return;
        }
        
        // 使用现代 Clipboard API
        if (navigator.clipboard && window.isSecureContext) {
            await navigator.clipboard.writeText(text);
        } else {
            // 降级到传统方法
            const textArea = document.createElement('textarea');
            textArea.value = text;
            textArea.style.position = 'fixed';
            textArea.style.left = '-999999px';
            textArea.style.top = '-999999px';
            document.body.appendChild(textArea);
            textArea.focus();
            textArea.select();
            document.execCommand('copy');
            textArea.remove();
        }
        
        // 显示复制成功状态
        showCopySuccess();
        
    } catch (err) {
        console.error('复制失败:', err);
        showError('复制失败，请手动选择文本复制');
    }
}

// 显示复制成功状态
function showCopySuccess() {
    copyText.classList.add('hidden');
    copiedText.classList.remove('hidden');
    
    setTimeout(() => {
        copyText.classList.remove('hidden');
        copiedText.classList.add('hidden');
    }, 2000);
}

// 设置加载状态
function setLoadingState(loading) {
    isOptimizing = loading;
    
    if (loading) {
        loadingSpinner.classList.remove('hidden');
        btnText.textContent = '优化中...';
        optimizeBtn.disabled = true;
        optimizeBtn.classList.add('loading-text');
    } else {
        loadingSpinner.classList.add('hidden');
        btnText.textContent = '开始优化';
        optimizeBtn.disabled = userInput.value.trim() === '';
        optimizeBtn.classList.remove('loading-text');
    }
}

// 隐藏所有结果
function hideAllResults() {
    placeholder.classList.add('hidden');
    result.classList.add('hidden');
    error.classList.add('hidden');
}

// 显示优化结果
function showResult(resultText) {
    hideAllResults();
    optimizedPrompt.textContent = resultText;
    result.classList.remove('hidden');
    
    // 滚动到结果区域
    result.scrollIntoView({ 
        behavior: 'smooth', 
        block: 'nearest' 
    });
}

// 显示错误信息
function showError(message) {
    hideAllResults();
    errorMessage.textContent = message;
    error.classList.remove('hidden');
}

// 工具函数：防抖
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// 工具函数：格式化文本
function formatText(text) {
    return text.replace(/\n\n/g, '\n\n').trim();
}

// 页面可见性检测（防止在后台标签页中执行不必要的操作）
document.addEventListener('visibilitychange', function() {
    if (document.hidden && isOptimizing) {
        // 页面隐藏时的处理逻辑
        console.log('页面已隐藏，优化任务继续进行...');
    }
});

// 错误处理
window.addEventListener('error', function(e) {
    console.error('全局错误:', e.error);
    if (isOptimizing) {
        showError('发生未知错误，请刷新页面后重试');
        setLoadingState(false);
    }
});

// 网络状态检测
window.addEventListener('online', function() {
    console.log('网络已连接');
});

window.addEventListener('offline', function() {
    console.log('网络已断开');
    if (isOptimizing) {
        showError('网络连接已断开，请检查网络后重试');
        setLoadingState(false);
    }
});