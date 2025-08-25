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
const copyOptimizedBtn = document.getElementById('copyOptimizedBtn');
const copyOptimizedText = document.getElementById('copyOptimizedText');
const copiedOptimizedText = document.getElementById('copiedOptimizedText');
const copyMarkdownBtn = document.getElementById('copyMarkdownBtn');
const copyMarkdownText = document.getElementById('copyMarkdownText');
const copiedMarkdownText = document.getElementById('copiedMarkdownText');
const downloadBtn = document.getElementById('downloadBtn');
const wordCount = document.getElementById('wordCount');
const inputCount = document.getElementById('inputCount');
const errorMessage = document.getElementById('errorMessage');

// 存储原始响应数据
let currentResponse = {
    original: '',
    rendered: ''
};

// 事件监听器
document.addEventListener('DOMContentLoaded', function() {
    // 优化按钮点击事件
    optimizeBtn.addEventListener('click', handleOptimize);
    
    // 复制按钮点击事件
    copyOptimizedBtn.addEventListener('click', () => handleCopy('optimized'));
    copyMarkdownBtn.addEventListener('click', () => handleCopy('markdown'));
    
    // 下载按钮点击事件
    downloadBtn.addEventListener('click', handleDownload);
    
    // 输入框变化事件
    userInput.addEventListener('input', handleInputChange);
    
    // 初始化字符计数
    handleInputChange();
    
    // 回车键支持（Ctrl+Enter提交）
    userInput.addEventListener('keydown', function(e) {
        if (e.ctrlKey && e.key === 'Enter') {
            handleOptimize();
        }
    });
});

// 处理输入变化
function handleInputChange() {
    const inputValue = userInput.value;
    const charCount = inputValue.length;
    
    inputCount.textContent = `${charCount} 字符`;
    optimizeBtn.disabled = inputValue.trim() === '' || isOptimizing;
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
async function handleCopy(type = 'optimized') {
    try {
        let text = '';
        let copyBtn, copyText, copiedText;
        
        if (type === 'optimized') {
            // 复制纯文本版本（去除markdown格式）
            text = extractPlainText(currentResponse.original);
            copyBtn = copyOptimizedBtn;
            copyText = copyOptimizedText;
            copiedText = copiedOptimizedText;
        } else if (type === 'markdown') {
            // 复制原始markdown文本
            text = currentResponse.original;
            copyBtn = copyMarkdownBtn;
            copyText = copyMarkdownText;
            copiedText = copiedMarkdownText;
        }
        
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
        showCopySuccess(copyText, copiedText);
        
    } catch (err) {
        console.error('复制失败:', err);
        showError('复制失败，请手动选择文本复制');
    }
}

// 处理下载功能
function handleDownload() {
    if (!currentResponse.original) {
        return;
    }
    
    const filename = `prompt_${new Date().toISOString().slice(0, 19).replace(/[:-]/g, '')}.md`;
    const blob = new Blob([currentResponse.original], { type: 'text/markdown;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

// 显示复制成功状态
function showCopySuccess(copyText, copiedText) {
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
    
    // 存储原始数据
    currentResponse.original = resultText;
    
    // 渲染Markdown
    currentResponse.rendered = renderMarkdown(resultText);
    optimizedPrompt.innerHTML = currentResponse.rendered;
    
    // 更新字数统计
    updateWordCount(resultText);
    
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

// Markdown渲染函数
function renderMarkdown(text) {
    // 配置marked选项
    marked.setOptions({
        breaks: true,
        gfm: true,
        sanitize: false
    });
    
    // 渲染markdown
    const html = marked.parse(text);
    
    // 使用DOMPurify清理HTML（防止XSS）
    const cleanHtml = DOMPurify.sanitize(html);
    
    return cleanHtml;
}

// 提取纯文本（去除markdown格式）
function extractPlainText(markdownText) {
    // 先渲染为HTML
    const html = marked.parse(markdownText);
    
    // 创建临时DOM元素来提取纯文本
    const tempDiv = document.createElement('div');
    tempDiv.innerHTML = html;
    
    // 获取纯文本并清理空行
    let plainText = tempDiv.textContent || tempDiv.innerText || '';
    
    // 清理多余的空行和空格
    plainText = plainText
        .replace(/\n\s*\n\s*\n/g, '\n\n')  // 多个空行合并为两个
        .replace(/^\s+|\s+$/gm, '')        // 去除行首尾空格
        .trim();                           // 去除整体首尾空格
    
    return plainText;
}

// 更新字数统计
function updateWordCount(text) {
    const plainText = extractPlainText(text);
    const charCount = plainText.length;
    const wordCount = plainText.split(/\s+/).filter(word => word.length > 0).length;
    
    document.getElementById('wordCount').textContent = `${charCount} 字符, ${wordCount} 单词`;
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