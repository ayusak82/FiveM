// グローバル変数
let currentData = null;
let selectedRecipe = null;
let activeCrafts = {};
let updateInterval = null;

// DOM要素の取得
const app = document.getElementById('app');
const stationName = document.getElementById('stationName');
const playerLevel = document.getElementById('playerLevel');
const xpProgress = document.getElementById('xpProgress');
const xpText = document.getElementById('xpText');
const closeBtn = document.getElementById('closeBtn');
const searchInput = document.getElementById('searchInput');
const recipeList = document.getElementById('recipeList');
const recipeDetail = document.getElementById('recipeDetail');
const activeCraftList = document.getElementById('activeCraftList');
const activeCraftCount = document.getElementById('activeCraftCount');

// モーダル要素
const craftModal = document.getElementById('craftModal');
const confirmModal = document.getElementById('confirmModal');
const modalClose = document.getElementById('modalClose');
const modalTitle = document.getElementById('modalTitle');
const modalIcon = document.getElementById('modalIcon');
const modalItemName = document.getElementById('modalItemName');
const craftQuantity = document.getElementById('craftQuantity');
const decreaseQty = document.getElementById('decreaseQty');
const increaseQty = document.getElementById('increaseQty');
const totalIngredients = document.getElementById('totalIngredients');
const totalTime = document.getElementById('totalTime');
const totalXP = document.getElementById('totalXP');
const startCraft = document.getElementById('startCraft');
const cancelCraft = document.getElementById('cancelCraft');

// 確認モーダル
const confirmMessage = document.getElementById('confirmMessage');
const confirmYes = document.getElementById('confirmYes');
const confirmNo = document.getElementById('confirmNo');

// イベントリスナー
document.addEventListener('DOMContentLoaded', function() {
    initializeEventListeners();
});

// イベントリスナーの初期化
function initializeEventListeners() {
    // 閉じるボタン
    closeBtn.addEventListener('click', closeUI);
    modalClose.addEventListener('click', closeCraftModal);
    
    // 検索機能
    searchInput.addEventListener('input', filterRecipes);
    
    // 数量コントロール
    decreaseQty.addEventListener('click', () => adjustQuantity(-1));
    increaseQty.addEventListener('click', () => adjustQuantity(1));
    craftQuantity.addEventListener('input', updateTotalRequirements);
    
    // クラフトモーダル
    startCraft.addEventListener('click', startCrafting);
    cancelCraft.addEventListener('click', closeCraftModal);
    
    // 確認モーダル
    confirmYes.addEventListener('click', handleConfirmYes);
    confirmNo.addEventListener('click', closeConfirmModal);
    
    // ESCキーでモーダルを閉じる
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            if (!confirmModal.classList.contains('hidden')) {
                closeConfirmModal();
            } else if (!craftModal.classList.contains('hidden')) {
                closeCraftModal();
            } else {
                closeUI();
            }
        }
    });
}

// NUIメッセージの処理
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch (data.action) {
        case 'openUI':
            openUI(data.data);
            break;
        case 'closeUI':
            closeUI();
            break;
        case 'updateProgress':
            updateCraftProgress(data.data.craftId, data.data.progress);
            break;
        case 'updateActiveCrafts':
            updateActiveCrafts(data.data.activeCrafts);
            break;
        case 'updatePlayerInfo':
            updatePlayerInfo(data.data);
            break;
        case 'updatePlayerItems':
            updatePlayerItems(data.data.playerItems);
            break;
        case 'updateData':
            updateUIData(data.data);
            break;
    }
});

// UIを開く
function openUI(data) {
    // 既存の更新間隔を停止
    stopUpdateInterval();
    
    currentData = data;
    app.classList.remove('hidden');
    
    // ステーション名を設定
    stationName.textContent = data.station.label;
    
    // プレイヤー情報を更新
    updatePlayerInfo({
        level: data.playerLevel,
        xp: 0,
        totalXP: 0,
        nextLevelXP: 1000
    });
    
    // レシピリストを生成
    generateRecipeList(data.recipes);
    
    // アクティブクラフトを更新
    updateActiveCrafts(data.activeCrafts || {});
    
    // カテゴリボタンを生成
    generateCategoryButtons(data.recipes);
    
    // 更新間隔を開始
    startUpdateInterval();
    
    console.log('UI opened with data:', data);
}

// UIを閉じる
function closeUI() {
    // 更新間隔を即座に停止
    stopUpdateInterval();
    
    // UI要素を隠す
    app.classList.add('hidden');
    
    // データをクリア
    currentData = null;
    selectedRecipe = null;
    activeCrafts = {};
    
    // NUIにクローズ通知（一度だけ送信）
    sendToLua('closeUI', {});
}

// Luaへのメッセージ送信関数
function sendToLua(action, data) {
    // UIが閉じられている場合は送信しない
    if (app.classList.contains('hidden') && action !== 'closeUI') {
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(data)
    }).catch(error => {
        console.warn(`Failed to send ${action} to Lua:`, error.message);
    });
}

// レシピリストの生成
function generateRecipeList(recipes) {
    recipeList.innerHTML = '';
    
    recipes.forEach(recipe => {
        const recipeItem = document.createElement('div');
        recipeItem.className = 'recipe-item';
        recipeItem.dataset.recipeName = recipe.name;
        recipeItem.dataset.category = recipe.category;
        
        // レベル不足の場合は無効化
        if (currentData.playerLevel < recipe.requiredLevel) {
            recipeItem.classList.add('disabled');
        }
        
        recipeItem.innerHTML = `
            <div class="recipe-icon">
                <i class="${recipe.icon || 'fas fa-cube'}"></i>
            </div>
            <div class="recipe-info">
                <h4>${recipe.label}</h4>
                <div class="recipe-meta">
                    <div class="level-req">
                        <i class="fas fa-star"></i>
                        <span>Lv.${recipe.requiredLevel}</span>
                    </div>
                    <div class="xp-reward">
                        <i class="fas fa-trophy"></i>
                        <span>${recipe.xpReward} XP</span>
                    </div>
                </div>
            </div>
        `;
        
        recipeItem.addEventListener('click', () => selectRecipe(recipe));
        recipeList.appendChild(recipeItem);
    });
}

// カテゴリボタンの生成
function generateCategoryButtons(recipes) {
    const categoriesContainer = document.querySelector('.recipe-categories');
    const categories = ['all', ...new Set(recipes.map(recipe => recipe.category))];
    
    categoriesContainer.innerHTML = '';
    
    categories.forEach(category => {
        const button = document.createElement('button');
        button.className = 'category-btn';
        button.dataset.category = category;
        
        if (category === 'all') {
            button.classList.add('active');
            button.innerHTML = '<i class="fas fa-th"></i> すべて';
        } else {
            button.innerHTML = `<i class="fas fa-cube"></i> ${getCategoryLabel(category)}`;
        }
        
        button.addEventListener('click', () => filterByCategory(category));
        categoriesContainer.appendChild(button);
    });
}

// カテゴリラベルの取得
function getCategoryLabel(category) {
    const labels = {
        'weapons': '武器',
        'weapon_parts': '武器パーツ',
        'electronics': '電子機器',
        'tools': '道具',
        'food': '料理',
        'drinks': '飲み物'
    };
    return labels[category] || category;
}

// カテゴリフィルター
function filterByCategory(category) {
    // アクティブボタンを更新
    document.querySelectorAll('.category-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelector(`[data-category="${category}"]`).classList.add('active');
    
    // レシピをフィルター
    const recipeItems = document.querySelectorAll('.recipe-item');
    recipeItems.forEach(item => {
        if (category === 'all' || item.dataset.category === category) {
            item.style.display = 'flex';
        } else {
            item.style.display = 'none';
        }
    });
}

// レシピ検索
function filterRecipes() {
    const searchTerm = searchInput.value.toLowerCase();
    const recipeItems = document.querySelectorAll('.recipe-item');
    
    recipeItems.forEach(item => {
        const recipeName = item.querySelector('h4').textContent.toLowerCase();
        if (recipeName.includes(searchTerm)) {
            item.style.display = 'flex';
        } else {
            item.style.display = 'none';
        }
    });
}

// レシピ選択
function selectRecipe(recipe) {
    // 選択状態を更新
    document.querySelectorAll('.recipe-item').forEach(item => {
        item.classList.remove('selected');
    });
    document.querySelector(`[data-recipe-name="${recipe.name}"]`).classList.add('selected');
    
    selectedRecipe = recipe;
    showRecipeDetails(recipe);
}

// レシピ詳細表示
function showRecipeDetails(recipe) {
    if (!recipe) return;
    
    // レシピ詳細を取得
    sendToLua('getRecipeDetails', { recipeName: recipe.name });
    
    // レスポンスを受け取るための一時的な処理
    setTimeout(() => {
        // フォールバック表示
        displayRecipeDetailsFallback(recipe);
    }, 500);
}

// フォールバック用のレシピ詳細表示
function displayRecipeDetailsFallback(recipe) {
    recipeDetail.innerHTML = `
        <div class="recipe-detail-content">
            <div class="recipe-header">
                <div class="recipe-detail-icon">
                    <i class="${recipe.icon || 'fas fa-cube'}"></i>
                </div>
                <div class="recipe-title">
                    <h2>${recipe.label}</h2>
                    <div class="recipe-stats">
                        <div class="stat-item">
                            <i class="fas fa-clock"></i>
                            <span>${recipe.craftTime}秒</span>
                        </div>
                        <div class="stat-item">
                            <i class="fas fa-star"></i>
                            <span>レベル ${recipe.requiredLevel}</span>
                        </div>
                        <div class="stat-item">
                            <i class="fas fa-trophy"></i>
                            <span>${recipe.xpReward} XP</span>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="ingredients-section">
                <h3>必要な材料</h3>
                <div class="ingredients-grid">
                    ${recipe.ingredients.map(ingredient => `
                        <div class="ingredient-item">
                            <div class="ingredient-icon">
                                <i class="fas fa-cube"></i>
                            </div>
                            <div class="ingredient-details">
                                <div class="ingredient-name">${ingredient.item}</div>
                                <div class="ingredient-amount">${ingredient.amount}</div>
                            </div>
                        </div>
                    `).join('')}
                </div>
            </div>
            
            <div class="craft-actions">
                <button class="btn btn-primary" onclick="openCraftModal()">
                    <i class="fas fa-play"></i>
                    クラフト開始
                </button>
            </div>
        </div>
    `;
}

// レシピ詳細の表示（サーバーからのデータ使用）
function displayRecipeDetails(recipe, canCraft, ingredients) {
    recipeDetail.innerHTML = `
        <div class="recipe-detail-content">
            <div class="recipe-header">
                <div class="recipe-detail-icon">
                    <i class="${recipe.icon || 'fas fa-cube'}"></i>
                </div>
                <div class="recipe-title">
                    <h2>${recipe.label}</h2>
                    <div class="recipe-stats">
                        <div class="stat-item">
                            <i class="fas fa-clock"></i>
                            <span>${recipe.craftTime}秒</span>
                        </div>
                        <div class="stat-item">
                            <i class="fas fa-star"></i>
                            <span>レベル ${recipe.requiredLevel}</span>
                        </div>
                        <div class="stat-item">
                            <i class="fas fa-trophy"></i>
                            <span>${recipe.xpReward} XP</span>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="ingredients-section">
                <h3>必要な材料</h3>
                <div class="ingredients-grid">
                    ${Object.entries(ingredients).map(([itemName, info]) => `
                        <div class="ingredient-item ${info.sufficient ? 'sufficient' : 'insufficient'}">
                            <div class="ingredient-icon">
                                <i class="fas fa-cube"></i>
                            </div>
                            <div class="ingredient-details">
                                <div class="ingredient-name">${itemName}</div>
                                <div class="ingredient-amount">${info.available} / ${info.required}</div>
                            </div>
                        </div>
                    `).join('')}
                </div>
            </div>
            
            <div class="craft-actions">
                <button class="btn btn-primary" ${!canCraft ? 'disabled' : ''} onclick="openCraftModal()">
                    <i class="fas fa-play"></i>
                    クラフト開始
                </button>
            </div>
        </div>
    `;
}

// クラフトモーダルを開く
function openCraftModal() {
    if (!selectedRecipe) return;
    
    craftModal.classList.remove('hidden');
    modalTitle.textContent = 'クラフト開始';
    modalIcon.className = selectedRecipe.icon || 'fas fa-cube';
    modalItemName.textContent = selectedRecipe.label;
    
    // 数量を1にリセット
    craftQuantity.value = 1;
    updateTotalRequirements();
}

// クラフトモーダルを閉じる
function closeCraftModal() {
    craftModal.classList.add('hidden');
}

// 数量調整
function adjustQuantity(delta) {
    const current = parseInt(craftQuantity.value) || 1;
    const newValue = Math.max(1, Math.min(99, current + delta));
    craftQuantity.value = newValue;
    updateTotalRequirements();
}

// 合計必要材料の更新
function updateTotalRequirements() {
    if (!selectedRecipe) return;
    
    const quantity = parseInt(craftQuantity.value) || 1;
    
    // 必要材料の表示
    totalIngredients.innerHTML = selectedRecipe.ingredients.map(ingredient => `
        <div class="ingredient-item">
            <div class="ingredient-icon">
                <i class="fas fa-cube"></i>
            </div>
            <div class="ingredient-details">
                <div class="ingredient-name">${ingredient.item}</div>
                <div class="ingredient-amount">${ingredient.amount * quantity}</div>
            </div>
        </div>
    `).join('');
    
    // 時間とXPの更新
    const totalCraftTime = selectedRecipe.craftTime * quantity;
    const totalXPValue = selectedRecipe.xpReward * quantity;
    
    totalTime.textContent = `${totalCraftTime}秒`;
    totalXP.textContent = `${totalXPValue} XP`;
}

// クラフト開始
function startCrafting() {
    if (!selectedRecipe) return;
    
    const quantity = parseInt(craftQuantity.value) || 1;
    
    sendToLua('startCraft', {
        recipe: selectedRecipe,
        quantity: quantity
    });
    
    closeCraftModal();
    
    // アクティブクラフトを更新
    setTimeout(() => {
        requestActiveCraftsUpdate();
    }, 1000);
}

// アクティブクラフトの更新
function updateActiveCrafts(crafts) {
    activeCrafts = crafts || {};
    const craftCount = Object.keys(activeCrafts).length;
    
    activeCraftCount.textContent = craftCount;
    
    if (craftCount === 0) {
        activeCraftList.innerHTML = `
            <div class="no-active-crafts">
                <i class="fas fa-clock"></i>
                <p>進行中のクラフトはありません</p>
            </div>
        `;
        return;
    }
    
    activeCraftList.innerHTML = Object.entries(activeCrafts).map(([craftId, craft]) => `
        <div class="active-craft-item" data-craft-id="${craftId}">
            <div class="craft-item-header">
                <div class="craft-item-name">${craft.recipe.label}</div>
                <div class="craft-item-quantity">x${craft.quantity}</div>
                <button class="craft-cancel-btn" onclick="cancelActiveCraft('${craftId}')">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <div class="craft-progress">
                <div class="craft-progress-bar" style="width: ${(craft.progress * 100)}%"></div>
            </div>
            <div class="craft-time-remaining">
                ${Math.ceil((1 - craft.progress) * (craft.endTime - craft.startTime) / 1000)}秒 残り
            </div>
        </div>
    `).join('');
}

// クラフト進行状況の更新
function updateCraftProgress(craftId, progress) {
    const craftItem = document.querySelector(`[data-craft-id="${craftId}"]`);
    if (craftItem) {
        const progressBar = craftItem.querySelector('.craft-progress-bar');
        const timeRemaining = craftItem.querySelector('.craft-time-remaining');
        
        progressBar.style.width = `${(progress * 100)}%`;
        
        if (activeCrafts[craftId]) {
            const remaining = Math.ceil((1 - progress) * (activeCrafts[craftId].endTime - activeCrafts[craftId].startTime) / 1000);
            timeRemaining.textContent = `${Math.max(0, remaining)}秒 残り`;
        }
    }
}

// アクティブクラフトのキャンセル
function cancelActiveCraft(craftId) {
    confirmMessage.textContent = 'このクラフトをキャンセルしますか？材料の一部が失われる可能性があります。';
    confirmModal.classList.remove('hidden');
    
    // 確認ボタンのイベントを設定
    confirmModal.dataset.action = 'cancelCraft';
    confirmModal.dataset.craftId = craftId;
}

// 確認モーダルの処理
function handleConfirmYes() {
    const action = confirmModal.dataset.action;
    const craftId = confirmModal.dataset.craftId;
    
    if (action === 'cancelCraft') {
        sendToLua('cancelCraft', { craftId: craftId });
        
        setTimeout(() => {
            requestActiveCraftsUpdate();
        }, 500);
    }
    
    closeConfirmModal();
}

// 確認モーダルを閉じる
function closeConfirmModal() {
    confirmModal.classList.add('hidden');
    confirmModal.dataset.action = '';
    confirmModal.dataset.craftId = '';
}

// プレイヤー情報の更新
function updatePlayerInfo(info) {
    playerLevel.textContent = info.level;
    
    if (info.nextLevelXP) {
        const xpPercent = (info.xp / info.nextLevelXP) * 100;
        xpProgress.style.width = `${xpPercent}%`;
        xpText.textContent = `${info.xp} / ${info.nextLevelXP}`;
    }
}

// プレイヤーアイテムの更新
function updatePlayerItems(items) {
    // 現在選択されているレシピがある場合は詳細を更新
    if (selectedRecipe) {
        showRecipeDetails(selectedRecipe);
    }
}

// UIデータの更新
function updateUIData(newData) {
    currentData = newData;
    
    // 必要に応じて各種要素を更新
    if (newData.recipes) {
        generateRecipeList(newData.recipes);
    }
    
    if (newData.activeCrafts) {
        updateActiveCrafts(newData.activeCrafts);
    }
    
    if (newData.playerLevel !== undefined) {
        updatePlayerInfo({
            level: newData.playerLevel,
            xp: newData.playerXP || 0,
            nextLevelXP: newData.nextLevelXP || 1000
        });
    }
}

// アクティブクラフト更新の要求
function requestActiveCraftsUpdate() {
    // UIが開いていない場合は何もしない
    if (!currentData || app.classList.contains('hidden')) {
        return;
    }
    
    sendToLua('updateActiveCrafts', {});
}

// プレイヤー情報更新の要求
function requestPlayerInfoUpdate() {
    // UIが開いていない場合は何もしない
    if (!currentData || app.classList.contains('hidden')) {
        return;
    }
    
    sendToLua('updatePlayerInfo', {});
}

// 更新間隔の開始
function startUpdateInterval() {
    if (updateInterval) {
        clearInterval(updateInterval);
    }
    
    // 最初の更新は少し遅らせる
    setTimeout(() => {
        if (currentData && !app.classList.contains('hidden')) {
            requestActiveCraftsUpdate();
            requestPlayerInfoUpdate();
        }
    }, 1000);
    
    updateInterval = setInterval(() => {
        if (currentData && !app.classList.contains('hidden')) {
            requestActiveCraftsUpdate();
            requestPlayerInfoUpdate();
        }
    }, 5000); // 5秒ごとに更新
}

// 更新間隔の停止
function stopUpdateInterval() {
    if (updateInterval) {
        clearInterval(updateInterval);
        updateInterval = null;
    }
}

// FiveM環境での親リソース名取得
function GetParentResourceName() {
    if (window.invokeNative) {
        return window.invokeNative('type', 'GetCurrentResourceName', 'string');
    }
    return 'ng-craft';
}

// NUIコールバックのハンドリング（サーバーからのレスポンス用）
window.addEventListener('message', function(event) {
    const data = event.data;
    
    // レシピ詳細のレスポンス処理
    if (data.type === 'recipeDetails') {
        if (data.error) {
            console.error('Recipe details error:', data.error);
        } else {
            displayRecipeDetails(data.recipe, data.canCraft, data.ingredients);
        }
    }
});

// デバッグ用
if (window.location.hostname === 'localhost') {
    // ローカル開発環境での動作テスト用
    console.log('Running in development mode');
}