// V2 版本全局变量
let isOptimizing = false;
let currentStructuredResponse = null;
let supportedModels = [];

// DOM元素
const userInput = document.getElementById('userInput');
const optimizeBtn = document.getElementById('optimizeBtn');
const batchGenerateBtn = document.getElementById('batchGenerateBtn');
const loadingSpinner = document.getElementById('loadingSpinner');
const btnText = document.getElementById('btnText');
const batchBtnText = document.getElementById('batchBtnText');
const placeholder = document.getElementById('placeholder');
const resultTabs = document.getElementById('resultTabs');
const resultTabHeaders = document.getElementById('resultTabHeaders');
const resultTabContent = document.getElementById('resultTabContent');
const error = document.getElementById('error');
const errorMessage = document.getElementById('errorMessage');
const inputCount = document.getElementById('inputCount');

// 配置元素
const modelSelection = document.getElementById('modelSelection');
const complexityLevel = document.getElementById('complexityLevel');
const taskType = document.getElementById('taskType');
const language = document.getElementById('language');
const generateMulti = document.getElementById('generateMulti');
const selectAllModels = document.getElementById('selectAllModels');
const clearAllModels = document.getElementById('clearAllModels');

// 结果显示元素
const optimizedPrompt = document.getElementById('optimizedPrompt');
const usageGuide = document.getElementById('usageGuide');
const testCases = document.getElementById('testCases');
const optimizationNotes = document.getElementById('optimizationNotes');
const mainWordCount = document.getElementById('mainWordCount');
const mainComplexity = document.getElementById('mainComplexity');
const exportBtn = document.getElementById('exportBtn');

// 事件监听器
document.addEventListener('DOMContentLoaded', function() {
    // 加载支持的模型
    loadSupportedModels();
    
    // 基础事件监听
    optimizeBtn.addEventListener('click', handleOptimize);
    batchGenerateBtn.addEventListener('click', handleBatchGenerate);
    userInput.addEventListener('input', handleInputChange);
    exportBtn.addEventListener('click', handleExport);
    
    // 模型选择事件
    selectAllModels.addEventListener('click', selectAllModelsHandler);
    clearAllModels.addEventListener('click', clearAllModelsHandler);
    
    // 复制按钮事件（委托）
    document.addEventListener('click', function(e) {
        if (e.target.classList.contains('copy-btn') || e.target.closest('.copy-btn')) {
            const btn = e.target.classList.contains('copy-btn') ? e.target : e.target.closest('.copy-btn');
            handleCopy(btn.dataset.type, btn);
        }
    });
    
    // 初始化字符计数
    handleInputChange();
    
    // 键盘快捷键
    userInput.addEventListener('keydown', function(e) {
        if (e.ctrlKey && e.key === 'Enter') {
            handleOptimize();
        }
    });
    
    // 生成多模型选项变化
    generateMulti.addEventListener('change', function() {
        if (this.checked) {
            selectAllModelsHandler();
        }
    });
});

// 加载支持的模型
async function loadSupportedModels() {
    try {
        const response = await fetch('/api/v2/models');
        const data = await response.json();
        supportedModels = data.models;
        updateModelSelection();
    } catch (err) {
        console.error('加载模型列表失败:', err);
        // 使用默认模型列表
        supportedModels = [
            { id: 'claude', name: 'Claude 4', description: 'Sonnet/Opus' },
            { id: 'gpt', name: 'GPT-4', description: '4.1/4o' },
            { id: 'gemini', name: 'Gemini', description: '2.5 Pro' },
            { id: 'deepseek', name: 'DeepSeek', description: 'R1' }
        ];
        updateModelSelection();
    }
}

// 更新模型选择界面
function updateModelSelection() {
    const container = modelSelection;
    container.innerHTML = '';
    
    supportedModels.forEach(model => {
        const div = document.createElement('div');
        div.className = 'form-control';
        div.innerHTML = `
            <label class="label cursor-pointer">
                <div class="flex items-center gap-2">
                    <input type="checkbox" class="checkbox checkbox-primary model-checkbox" value="${model.id}" />
                    <span class="label-text">${model.name}</span>
                </div>
                <div class="text-xs opacity-60">${model.description}</div>
            </label>
        `;
        container.appendChild(div);
    });
}

// 处理输入变化
function handleInputChange() {
    const inputValue = userInput.value;
    const charCount = inputValue.length;
    
    inputCount.textContent = `${charCount} 字符`;
    
    const hasInput = inputValue.trim() !== '';
    optimizeBtn.disabled = !hasInput || isOptimizing;
    batchGenerateBtn.disabled = !hasInput || isOptimizing;
}

// 获取选中的模型
function getSelectedModels() {
    const checkboxes = document.querySelectorAll('.model-checkbox:checked');
    return Array.from(checkboxes).map(cb => cb.value);
}

// 构建请求数据
function buildRequestData(isBatchGenerate = false) {
    const selectedModels = getSelectedModels();
    
    return {
        input: userInput.value.trim(),
        target_models: selectedModels,
        complexity_level: complexityLevel.value,
        task_type: taskType.value,
        language: language.value,
        generate_multi: isBatchGenerate || generateMulti.checked
    };
}

// 处理单次优化请求
async function handleOptimize() {
    if (isOptimizing || !userInput.value.trim()) return;
    
    const selectedModels = getSelectedModels();
    if (selectedModels.length === 0) {
        showError('请至少选择一个目标AI模型');
        return;
    }
    
    try {
        setLoadingState(true, 'optimize');
        hideAllResults();
        
        const requestData = buildRequestData(false);
        
        const response = await fetch('/api/v2/optimize', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(requestData)
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            throw new Error(data.error || `服务器错误: ${response.status}`);
        }
        
        if (data.error) {
            throw new Error(data.error);
        }
        
        // 显示结构化结果
        showStructuredResult(data.result);
        
    } catch (err) {
        console.error('优化失败:', err);
        showError(err.message || '优化过程中发生未知错误');
    } finally {
        setLoadingState(false, 'optimize');
    }
}

// 处理批量生成请求
async function handleBatchGenerate() {
    if (isOptimizing || !userInput.value.trim()) return;
    
    const selectedModels = getSelectedModels();
    if (selectedModels.length === 0) {
        showError('请至少选择一个目标AI模型');
        return;
    }
    
    try {
        setLoadingState(true, 'batch');
        hideAllResults();
        
        const requestData = buildRequestData(true);
        
        const response = await fetch('/api/v2/generate-multi', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(requestData)
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            throw new Error(data.error || `服务器错误: ${response.status}`);
        }
        
        if (data.error) {
            throw new Error(data.error);
        }
        
        // 显示批量生成结果
        showStructuredResult(data.result, true);
        
    } catch (err) {
        console.error('批量生成失败:', err);
        showError(err.message || '批量生成过程中发生未知错误');
    } finally {
        setLoadingState(false, 'batch');
    }
}

// 设置加载状态
function setLoadingState(loading, type = 'optimize') {
    isOptimizing = loading;
    
    if (loading) {
        loadingSpinner.classList.remove('hidden');
        optimizeBtn.disabled = true;
        batchGenerateBtn.disabled = true;
        
        if (type === 'optimize') {
            btnText.textContent = '优化中...';
        } else if (type === 'batch') {
            batchBtnText.textContent = '生成中...';
        }
    } else {
        loadingSpinner.classList.add('hidden');
        btnText.textContent = '开始优化';
        batchBtnText.textContent = '批量生成';
        
        const hasInput = userInput.value.trim() !== '';
        optimizeBtn.disabled = !hasInput;
        batchGenerateBtn.disabled = !hasInput;
    }
}

// 隐藏所有结果
function hideAllResults() {
    placeholder.classList.add('hidden');
    resultTabs.classList.add('hidden');
    error.classList.add('hidden');
}

// 显示结构化结果
function showStructuredResult(result, isBatchMode = false) {
    currentStructuredResponse = result;
    hideAllResults();
    
    // 显示主要结果
    displayMainResult(result);
    
    // 如果有模型特化版本，显示相应标签页
    if (hasModelVersions(result)) {
        displayModelVersions(result);
    }
    
    // 显示结果区域
    resultTabs.classList.remove('hidden');
    
    // 滚动到结果区域
    resultTabs.scrollIntoView({ 
        behavior: 'smooth', 
        block: 'nearest' 
    });
}

// 显示主要结果
function displayMainResult(result) {
    // 渲染优化后的提示词
    if (result.optimized_prompt) {
        optimizedPrompt.innerHTML = renderMarkdown(result.optimized_prompt);
    }
    
    // 显示使用指南
    if (result.usage_guide) {
        usageGuide.innerHTML = renderMarkdown(result.usage_guide);
    }
    
    // 显示测试用例
    if (result.test_cases && result.test_cases.length > 0) {
        displayTestCases(result.test_cases);
    }
    
    // 显示优化说明
    if (result.optimization_notes) {
        optimizationNotes.innerHTML = renderMarkdown(result.optimization_notes);
    }
    
    // 更新元数据
    if (result.metadata) {
        updateMetadata(result.metadata);
    }
}

// 显示测试用例
function displayTestCases(cases) {
    const container = testCases;
    container.innerHTML = '';
    
    cases.forEach((testCase, index) => {
        const div = document.createElement('div');
        div.className = 'bg-base-100 rounded-lg p-4 mb-3';
        div.innerHTML = `
            <div class="font-semibold text-sm mb-2">测试用例 ${index + 1}</div>
            <div class="mb-2">
                <span class="badge badge-info badge-sm">输入</span>
                <div class="mt-1 text-sm opacity-80">${escapeHtml(testCase.input)}</div>
            </div>
            <div>
                <span class="badge badge-success badge-sm">预期行为</span>
                <div class="mt-1 text-sm opacity-80">${escapeHtml(testCase.expected_behavior)}</div>
            </div>
        `;
        container.appendChild(div);
    });
}

// 更新元数据显示
function updateMetadata(metadata) {
    if (metadata.complexity_level) {
        mainComplexity.textContent = getComplexityLabel(metadata.complexity_level);
        mainComplexity.className = `badge badge-outline ${getComplexityColor(metadata.complexity_level)}`;
    }
    
    if (metadata.estimated_tokens) {
        const plainText = extractPlainText(currentStructuredResponse.optimized_prompt);
        mainWordCount.textContent = `约 ${metadata.estimated_tokens} tokens, ${plainText.length} 字符`;
    }
}

// 检查是否有模型版本
function hasModelVersions(result) {
    if (!result.model_versions) return false;
    
    return Object.values(result.model_versions).some(version => version && version.trim() !== '');
}

// 显示模型版本标签页
function displayModelVersions(result) {
    const modelVersions = result.model_versions;
    const tabHeaders = resultTabHeaders;
    const tabContent = resultTabContent;
    
    // 为每个有内容的模型版本创建标签页
    Object.entries(modelVersions).forEach(([modelId, content]) => {
        if (content && content.trim() !== '') {
            const modelInfo = supportedModels.find(m => m.id === modelId);
            const modelName = modelInfo ? modelInfo.name : modelId.toUpperCase();
            
            // 添加标签头
            const tabHeader = document.createElement('a');
            tabHeader.className = 'tab';
            tabHeader.dataset.tab = modelId;
            tabHeader.textContent = modelName;
            tabHeader.addEventListener('click', () => switchTab(modelId));
            tabHeaders.appendChild(tabHeader);
            
            // 添加标签内容
            const tabPane = document.createElement('div');
            tabPane.className = 'tab-pane';
            tabPane.id = modelId;
            tabPane.innerHTML = `
                <div class="bg-base-100 rounded-lg border">
                    <div class="flex justify-between items-center p-4 border-b">
                        <div class="flex items-center gap-2">
                            <span class="badge badge-primary">${modelName} 专用版本</span>
                        </div>
                        <div class="flex gap-2">
                            <button class="btn btn-outline btn-sm copy-btn" data-type="model" data-model="${modelId}">
                                <span class="copy-text">复制</span>
                                <span class="copied-text hidden">已复制</span>
                            </button>
                        </div>
                    </div>
                    <div class="p-4">
                        <div class="prose prose-sm max-w-none">${renderMarkdown(content)}</div>
                    </div>
                </div>
            `;
            tabContent.appendChild(tabPane);
        }
    });
}

// 切换标签页
function switchTab(tabId) {
    // 更新标签头状态
    document.querySelectorAll('.tab').forEach(tab => {
        tab.classList.remove('tab-active');
    });
    document.querySelector(`[data-tab="${tabId}"]`).classList.add('tab-active');
    
    // 显示对应内容
    document.querySelectorAll('.tab-pane').forEach(pane => {
        pane.classList.remove('active');
    });
    document.getElementById(tabId).classList.add('active');
}

// 处理复制功能
async function handleCopy(type, btn) {
    try {
        let text = '';
        
        if (type === 'optimized') {
            text = extractPlainText(currentStructuredResponse.optimized_prompt);
        } else if (type === 'raw') {
            text = currentStructuredResponse.optimized_prompt;
        } else if (type === 'model') {
            const modelId = btn.dataset.model;
            text = currentStructuredResponse.model_versions[modelId];
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
        showCopySuccess(btn);
        
    } catch (err) {
        console.error('复制失败:', err);
        showError('复制失败，请手动选择文本复制');
    }
}

// 显示复制成功状态
function showCopySuccess(btn) {
    const copyText = btn.querySelector('.copy-text');
    const copiedText = btn.querySelector('.copied-text');
    
    copyText.classList.add('hidden');
    copiedText.classList.remove('hidden');
    
    setTimeout(() => {
        copyText.classList.remove('hidden');
        copiedText.classList.add('hidden');
    }, 2000);
}

// 处理导出功能
function handleExport() {
    if (!currentStructuredResponse) return;
    
    // 创建导出数据
    const exportData = {
        timestamp: new Date().toISOString(),
        input: userInput.value,
        configuration: {
            complexity_level: complexityLevel.value,
            task_type: taskType.value,
            language: language.value,
            target_models: getSelectedModels()
        },
        result: currentStructuredResponse
    };
    
    // 创建文件并下载
    const filename = `prompt_optimization_${new Date().toISOString().slice(0, 19).replace(/[:-]/g, '')}.json`;
    const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

// 模型选择处理
function selectAllModelsHandler() {
    document.querySelectorAll('.model-checkbox').forEach(cb => {
        cb.checked = true;
    });
}

function clearAllModelsHandler() {
    document.querySelectorAll('.model-checkbox').forEach(cb => {
        cb.checked = false;
    });
    generateMulti.checked = false;
}

// 显示错误信息
function showError(message) {
    hideAllResults();
    errorMessage.textContent = message;
    error.classList.remove('hidden');
}

// 工具函数

// Markdown渲染函数
function renderMarkdown(text) {
    if (!text) return '';
    
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
    if (!markdownText) return '';
    
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

// HTML转义
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// 获取复杂度标签
function getComplexityLabel(level) {
    const labels = {
        simple: '简单',
        medium: '中等',
        complex: '复杂'
    };
    return labels[level] || level;
}

// 获取复杂度颜色
function getComplexityColor(level) {
    const colors = {
        simple: 'badge-success',
        medium: 'badge-warning',
        complex: 'badge-error'
    };
    return colors[level] || 'badge-info';
}

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