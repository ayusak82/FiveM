// グローバル変数
let currentGame = null;
let gameTimer = null;
let timeRemaining = 0;
let gameScore = 0;
let isGameActive = false;

// 化学物質精製ゲーム変数
let selectedIngredients = [];
let targetRecipe = [];
let currentTemperature = 50;
let mixingProgress = 0;

// 機械部品組み立てゲーム変数
let blueprintPattern = [];
let availableParts = [];
let assemblyGrid = [];
let draggedPart = null;

// DOM要素
const gameContainer = document.getElementById('gameContainer');
const chemicalGame = document.getElementById('chemicalGame');
const mechanicalGame = document.getElementById('mechanicalGame');
const resultModal = document.getElementById('resultModal');
const loadingScreen = document.getElementById('loadingScreen');

// イベントリスナー設定
document.addEventListener('DOMContentLoaded', function() {
    setupEventListeners();
});

// NUIメッセージリスナー
window.addEventListener('message', function(event) {
    if (event.data.action === 'startGame') {
        startGame(event.data.gameType, event.data.config);
    }
});

// イベントリスナー設定
function setupEventListeners() {
    // 閉じるボタン
    document.getElementById('closeButton').addEventListener('click', closeGame);
    
    // 結果モーダルのOKボタン
    document.getElementById('resultOkButton').addEventListener('click', function() {
        hideModal();
        closeGame();
    });
    
    // 化学物質精製ゲーム
    setupChemicalGameListeners();
    
    // 機械部品組み立てゲーム
    setupMechanicalGameListeners();
    
    // ESCキーで閉じる
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape' && isGameActive) {
            closeGame();
        }
    });
}

// ゲーム開始
function startGame(gameType, config) {
    currentGame = gameType;
    gameScore = 0;
    isGameActive = true;
    
    // ローディング表示
    showLoading();
    
    setTimeout(() => {
        hideLoading();
        
        if (gameType === 'chemical') {
            initChemicalGame(config);
        } else if (gameType === 'mechanical') {
            initMechanicalGame(config);
        }
        
        showGameContainer();
        startTimer(config.timeLimit);
    }, 1000);
}

// 化学物質精製ゲーム初期化
function initChemicalGame(config) {
    chemicalGame.classList.remove('hidden');
    mechanicalGame.classList.add('hidden');
    
    // 変数リセット
    selectedIngredients = [];
    mixingProgress = 0;
    currentTemperature = 50;
    
    // 目標レシピ生成
    generateTargetRecipe();
    
    // UI更新
    updateChemicalUI();
    updateProgressDisplay('chemical', 0);
}

// 機械部品組み立てゲーム初期化
function initMechanicalGame(config) {
    mechanicalGame.classList.remove('hidden');
    chemicalGame.classList.add('hidden');
    
    // 変数リセット
    assemblyGrid = [];
    availableParts = [];
    
    // ブループリントと部品生成
    generateBlueprint();
    generateParts();
    
    // UI更新
    updateMechanicalUI();
    updateProgressDisplay('mechanical', 0);
}

// 化学物質精製ゲームのイベントリスナー
function setupChemicalGameListeners() {
    // 試薬選択
    document.querySelectorAll('.ingredient-slot').forEach(slot => {
        slot.addEventListener('click', function() {
            const ingredient = this.dataset.ingredient;
            selectIngredient(ingredient, this);
        });
    });
    
    // 温度調整
    const tempSlider = document.getElementById('temperatureSlider');
    tempSlider.addEventListener('input', function() {
        currentTemperature = parseInt(this.value);
        document.getElementById('temperatureValue').textContent = currentTemperature + '°C';
        updateBeakerTemperature();
    });
    
    // 混合ボタン
    document.getElementById('mixButton').addEventListener('click', startMixing);
}

// 試薬選択
function selectIngredient(ingredient, element) {
    if (selectedIngredients.includes(ingredient)) {
        // 既に選択されている場合は削除
        selectedIngredients = selectedIngredients.filter(item => item !== ingredient);
        element.classList.remove('selected');
    } else {
        // 新規選択（最大3つまで）
        if (selectedIngredients.length < 3) {
            selectedIngredients.push(ingredient);
            element.classList.add('selected');
        }
    }
    
    updateLiquidColor();
}

// 液体の色更新
function updateLiquidColor() {
    const liquid = document.getElementById('mainLiquid');
    let color = '#ff6b6b'; // デフォルト赤
    
    if (selectedIngredients.length === 0) {
        liquid.style.height = '0%';
        return;
    }
    
    // 選択された試薬に基づいて色を決定
    if (selectedIngredients.includes('red') && selectedIngredients.includes('blue')) {
        color = '#8e44ad'; // 紫
    } else if (selectedIngredients.includes('red') && selectedIngredients.includes('yellow')) {
        color = '#e67e22'; // オレンジ
    } else if (selectedIngredients.includes('blue') && selectedIngredients.includes('yellow')) {
        color = '#27ae60'; // 緑
    } else if (selectedIngredients.includes('red')) {
        color = '#e74c3c'; // 赤
    } else if (selectedIngredients.includes('blue')) {
        color = '#3498db'; // 青
    } else if (selectedIngredients.includes('yellow')) {
        color = '#f39c12'; // 黄
    }
    
    liquid.style.background = `linear-gradient(180deg, ${color}, ${color}dd)`;
    liquid.style.height = Math.min(selectedIngredients.length * 30, 80) + '%';
}

// ビーカーの温度表現更新
function updateBeakerTemperature() {
    const beaker = document.getElementById('mainBeaker');
    if (currentTemperature > 70) {
        beaker.style.boxShadow = '0 0 30px rgba(255, 100, 100, 0.5)';
    } else if (currentTemperature < 30) {
        beaker.style.boxShadow = '0 0 30px rgba(100, 100, 255, 0.5)';
    } else {
        beaker.style.boxShadow = '0 0 20px rgba(74, 144, 226, 0.3)';
    }
}

// 目標レシピ生成
function generateTargetRecipe() {
    const recipes = [
        ['red', 'blue'],
        ['blue', 'yellow'],
        ['red', 'yellow'],
        ['red', 'blue', 'yellow']
    ];
    
    targetRecipe = recipes[Math.floor(Math.random() * recipes.length)];
    
    // UI更新
    const recipeContainer = document.getElementById('targetRecipe');
    recipeContainer.innerHTML = '';
    
    targetRecipe.forEach(ingredient => {
        const item = document.createElement('div');
        item.className = 'recipe-item';
        item.innerHTML = `
            <div class="recipe-color ${ingredient}-ingredient"></div>
            <span>${getIngredientName(ingredient)}</span>
        `;
        recipeContainer.appendChild(item);
    });
}

// 試薬名取得
function getIngredientName(ingredient) {
    const names = {
        'red': '赤色試薬',
        'blue': '青色試薬',
        'yellow': '黄色試薬'
    };
    return names[ingredient] || ingredient;
}

// 混合開始
function startMixing() {
    if (selectedIngredients.length === 0) return;
    
    const button = document.getElementById('mixButton');
    button.disabled = true;
    button.textContent = '混合中...';
    
    // 混合プログレス
    let progress = 0;
    const mixInterval = setInterval(() => {
        progress += 2;
        mixingProgress = progress;
        updateProgressDisplay('chemical', progress);
        
        if (progress >= 100) {
            clearInterval(mixInterval);
            completeMixing();
        }
    }, 100);
}

// 混合完了
function completeMixing() {
    const button = document.getElementById('mixButton');
    button.disabled = false;
    button.textContent = '混合開始';
    
    // 成功判定
    const isCorrectRecipe = arraysEqual(selectedIngredients.sort(), targetRecipe.sort());
    const isCorrectTemperature = currentTemperature >= 45 && currentTemperature <= 55;
    
    const success = isCorrectRecipe && isCorrectTemperature;
    const points = success ? 100 : (isCorrectRecipe ? 50 : 25);
    
    gameScore += points;
    document.getElementById('currentScore').textContent = gameScore;
    
    if (success) {
        showResult(true, `完璧な混合です！正しいレシピと温度で成功しました。`, gameScore);
    } else if (isCorrectRecipe) {
        showResult(false, `レシピは正しいですが、温度が適切ではありませんでした。`, gameScore);
    } else {
        showResult(false, `レシピが間違っています。もう一度確認してください。`, gameScore);
    }
}

// 機械部品組み立てゲームのイベントリスナー
function setupMechanicalGameListeners() {
    // ドラッグ&ドロップは動的に設定
}

// ブループリント生成
function generateBlueprint() {
    const patterns = [
        ['A', 'B', 'C', 'D', 'B', 'A', 'D', 'C', 'A', 'B', 'C', 'D', 'D', 'C', 'B', 'A'],
        ['X', 'Y', 'X', 'Y', 'Y', 'X', 'Y', 'X', 'X', 'Y', 'X', 'Y', 'Y', 'X', 'Y', 'X'],
        ['1', '2', '3', '1', '2', '3', '1', '2', '3', '1', '2', '3', '1', '2', '3', '1']
    ];
    
    blueprintPattern = patterns[Math.floor(Math.random() * patterns.length)];
}

// 部品生成
function generateParts() {
    const uniqueParts = [...new Set(blueprintPattern)];
    availableParts = [];
    
    // 各部品タイプを複数個生成
    uniqueParts.forEach(part => {
        const count = Math.floor(blueprintPattern.filter(p => p === part).length * 1.5);
        for (let i = 0; i < count; i++) {
            availableParts.push(part);
        }
    });
    
    // シャッフル
    availableParts = shuffleArray(availableParts);
}

// 配列シャッフル
function shuffleArray(array) {
    const newArray = [...array];
    for (let i = newArray.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [newArray[i], newArray[j]] = [newArray[j], newArray[i]];
    }
    return newArray;
}

// 機械部品組み立てUI更新
function updateMechanicalUI() {
    // ブループリント表示
    const blueprint = document.getElementById('blueprint');
    blueprint.innerHTML = '';
    
    blueprintPattern.forEach((part, index) => {
        const cell = document.createElement('div');
        cell.className = 'blueprint-cell';
        cell.textContent = part;
        blueprint.appendChild(cell);
    });
    
    // 部品在庫表示
    const partsContainer = document.getElementById('partsContainer');
    partsContainer.innerHTML = '';
    
    availableParts.forEach((part, index) => {
        const partElement = document.createElement('div');
        partElement.className = 'part-item';
        partElement.textContent = part;
        partElement.draggable = true;
        partElement.dataset.partType = part;
        partElement.dataset.partIndex = index;
        
        // ドラッグイベント
        partElement.addEventListener('dragstart', handleDragStart);
        partElement.addEventListener('dragend', handleDragEnd);
        
        partsContainer.appendChild(partElement);
    });
    
    // 組み立てグリッド表示
    const assemblyGrid = document.getElementById('assemblyGrid');
    assemblyGrid.innerHTML = '';
    
    for (let i = 0; i < 16; i++) {
        const cell = document.createElement('div');
        cell.className = 'assembly-cell';
        cell.dataset.cellIndex = i;
        
        // ドロップイベント
        cell.addEventListener('dragover', handleDragOver);
        cell.addEventListener('drop', handleDrop);
        cell.addEventListener('dragleave', handleDragLeave);
        
        assemblyGrid.appendChild(cell);
    }
}

// ドラッグ開始
function handleDragStart(event) {
    draggedPart = event.target;
    event.target.classList.add('dragging');
    event.dataTransfer.effectAllowed = 'move';
}

// ドラッグ終了
function handleDragEnd(event) {
    event.target.classList.remove('dragging');
    draggedPart = null;
}

// ドラッグオーバー
function handleDragOver(event) {
    event.preventDefault();
    event.dataTransfer.dropEffect = 'move';
    event.target.classList.add('drag-over');
}

// ドラッグ離脱
function handleDragLeave(event) {
    event.target.classList.remove('drag-over');
}

// ドロップ
function handleDrop(event) {
    event.preventDefault();
    event.target.classList.remove('drag-over');
    
    if (!draggedPart || event.target.classList.contains('occupied')) {
        return;
    }
    
    const cellIndex = parseInt(event.target.dataset.cellIndex);
    const partType = draggedPart.dataset.partType;
    const partIndex = parseInt(draggedPart.dataset.partIndex);
    
    // 部品を配置
    event.target.textContent = partType;
    event.target.classList.add('occupied');
    event.target.dataset.partType = partType;
    
    // 部品在庫から削除
    draggedPart.remove();
    availableParts.splice(partIndex, 1);
    
    // プログレス更新
    checkAssemblyProgress();
}

// 組み立て進捗チェック
function checkAssemblyProgress() {
    const assemblyCells = document.querySelectorAll('.assembly-cell');
    let correctPlacements = 0;
    
    assemblyCells.forEach((cell, index) => {
        if (cell.classList.contains('occupied')) {
            const placedPart = cell.dataset.partType;
            const expectedPart = blueprintPattern[index];
            
            if (placedPart === expectedPart) {
                correctPlacements++;
                cell.style.borderColor = '#00ff88';
            } else {
                cell.style.borderColor = '#ff4757';
            }
        }
    });
    
    const progress = (correctPlacements / blueprintPattern.length) * 100;
    updateProgressDisplay('mechanical', progress);
    
    // ゲーム完了チェック
    if (correctPlacements === blueprintPattern.length) {
        gameScore = 100;
        document.getElementById('currentScore').textContent = gameScore;
        showResult(true, '完璧な組み立てです！すべての部品が正しく配置されました。', gameScore);
    }
}

// タイマー開始
function startTimer(duration) {
    timeRemaining = duration;
    updateTimerDisplay();
    
    gameTimer = setInterval(() => {
        timeRemaining--;
        updateTimerDisplay();
        
        if (timeRemaining <= 0) {
            clearInterval(gameTimer);
            timeUp();
        }
    }, 1000);
}

// タイマー表示更新
function updateTimerDisplay() {
    const progress = (timeRemaining / (currentGame === 'chemical' ? 30 : 45)) * 100;
    const timerFill = document.getElementById(currentGame + 'Timer');
    const timeText = document.getElementById(currentGame + 'TimeText');
    
    if (timerFill && timeText) {
        timerFill.style.width = progress + '%';
        timeText.textContent = timeRemaining;
        
        // 残り時間が少ない場合の警告色
        if (timeRemaining <= 10) {
            timerFill.style.background = 'linear-gradient(90deg, #ff4757, #ff3742)';
        }
    }
}

// 時間切れ
function timeUp() {
    isGameActive = false;
    showResult(false, '時間切れです。もう少しでした！', gameScore);
}

// プログレス表示更新
function updateProgressDisplay(gameType, progress) {
    const progressFill = document.getElementById(gameType + 'Progress');
    const progressText = document.getElementById(gameType + 'ProgressText');
    
    if (progressFill && progressText) {
        progressFill.style.width = progress + '%';
        progressText.textContent = Math.round(progress) + '%';
    }
}

// 結果表示
function showResult(success, message, score) {
    clearInterval(gameTimer);
    isGameActive = false;
    
    document.getElementById('resultTitle').textContent = success ? '成功！' : '失敗';
    document.getElementById('resultMessage').textContent = message;
    document.getElementById('resultScore').textContent = `スコア: ${score}`;
    
    showModal();
    
    // NUIに結果送信
    fetch(`https://${GetParentResourceName()}/gameResult`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            success: success,
            score: score,
            gameType: currentGame
        })
    });
}

// UI表示/非表示
function showGameContainer() {
    gameContainer.classList.remove('hidden');
}

function hideGameContainer() {
    gameContainer.classList.add('hidden');
}

function showModal() {
    resultModal.classList.remove('hidden');
}

function hideModal() {
    resultModal.classList.add('hidden');
}

function showLoading() {
    loadingScreen.classList.remove('hidden');
}

function hideLoading() {
    loadingScreen.classList.add('hidden');
}

// ゲーム終了
function closeGame() {
    clearInterval(gameTimer);
    isGameActive = false;
    
    hideGameContainer();
    hideModal();
    
    // NUIを閉じる
    fetch(`https://${GetParentResourceName()}/closeGame`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    });
}

// 化学物質精製UI更新
function updateChemicalUI() {
    // 試薬選択をリセット
    document.querySelectorAll('.ingredient-slot').forEach(slot => {
        slot.classList.remove('selected');
    });
    
    // ビーカーをリセット
    const liquid = document.getElementById('mainLiquid');
    liquid.style.height = '0%';
    
    // スライダーをリセット
    document.getElementById('temperatureSlider').value = 50;
    document.getElementById('temperatureValue').textContent = '50°C';
    updateBeakerTemperature();
}

// 配列比較ユーティリティ
function arraysEqual(a, b) {
    if (a.length !== b.length) return false;
    for (let i = 0; i < a.length; i++) {
        if (a[i] !== b[i]) return false;
    }
    return true;
}

// リソース名取得（FiveM用）
function GetParentResourceName() {
    return window.location.hostname === 'nui-game-internal' ? 'ng-underground' : 'ng-underground';
}