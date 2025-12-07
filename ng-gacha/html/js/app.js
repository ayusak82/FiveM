/**
 * ng-gacha - JavaScript Application
 * Author: NCCGr
 * Contact: Discord: ayusak
 */

// State
let currentGacha = null;
let currentBalance = { money: 0, bank: 0, coins: 0 };
let config = {};
let availableItems = [];
let selectedPrizeIndex = null;
let isPulling = false;

// DOM Elements
const gachaContainer = document.getElementById('gachaContainer');
const createOverlay = document.getElementById('createOverlay');
const resultOverlay = document.getElementById('resultOverlay');
const multiResultOverlay = document.getElementById('multiResultOverlay');
const itemSelectorOverlay = document.getElementById('itemSelectorOverlay');

// Initialize particles
function createParticles() {
    const container = document.getElementById('particles');
    if (!container) return;
    
    container.innerHTML = '';
    for (let i = 0; i < 30; i++) {
        const particle = document.createElement('div');
        particle.className = 'particle';
        particle.style.left = Math.random() * 100 + '%';
        particle.style.top = Math.random() * 100 + '%';
        particle.style.animationDelay = Math.random() * 6 + 's';
        particle.style.animationDuration = (4 + Math.random() * 4) + 's';
        
        const colors = ['#00f5ff', '#ff00e5', '#ffd700'];
        particle.style.background = colors[Math.floor(Math.random() * colors.length)];
        
        container.appendChild(particle);
    }
}

// Get item image URL (QBCore inventory)
function getItemImageUrl(itemName) {
    return `nui://qb-inventory/html/images/${itemName}.png`;
}

// Format number
function formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

// Update Balance Display
function updateBalanceDisplay() {
    document.getElementById('balanceMoney').textContent = formatNumber(currentBalance.money);
    document.getElementById('balanceCoins').textContent = formatNumber(currentBalance.coins);
}

// Update Pity Display
function updatePityDisplay(current, max) {
    const pityCounter = document.getElementById('pityCounter');
    if (max <= 0) {
        pityCounter.style.display = 'none';
        return;
    }
    
    pityCounter.style.display = 'block';
    document.getElementById('pityText').textContent = `${current} / ${max}`;
    
    const percentage = Math.min((current / max) * 100, 100);
    document.getElementById('pityFill').style.width = percentage + '%';
}

// Render Capsules
function renderCapsules(prizes) {
    const container = document.getElementById('capsulesContainer');
    container.innerHTML = '';
    
    const positions = [
        { top: '30%', left: '20%' },
        { top: '50%', left: '60%' },
        { top: '25%', left: '55%' },
        { top: '60%', left: '25%' },
        { top: '45%', left: '40%' },
        { top: '35%', left: '35%' },
        { top: '65%', left: '50%' }
    ];
    
    prizes.slice(0, 7).forEach((prize, index) => {
        const capsule = document.createElement('div');
        capsule.className = `capsule ${prize.rarity}`;
        capsule.style.top = positions[index % positions.length].top;
        capsule.style.left = positions[index % positions.length].left;
        capsule.style.animationDelay = (index * 0.3) + 's';
        container.appendChild(capsule);
    });
}

// Render Prize List
function renderPrizeList(prizes) {
    const container = document.getElementById('prizeItems');
    container.innerHTML = '';
    
    document.getElementById('prizeHeader').textContent = `📦 景品一覧 - 全${prizes.length}種`;
    
    // Sort by probability (rare first)
    const sortedPrizes = [...prizes].sort((a, b) => a.probability - b.probability);
    
    sortedPrizes.forEach(prize => {
        const item = document.createElement('div');
        item.className = `prize-item ${prize.rarity}`;
        
        const isJackpot = prize.is_jackpot;
        const jackpotBadge = isJackpot ? '<span class="rarity-badge legendary">JACKPOT</span>' : '';
        
        item.innerHTML = `
            <div class="prize-icon">
                <img src="${getItemImageUrl(prize.item_name)}" alt="${prize.item_label}" onerror="this.src='nui://qb-inventory/html/images/placeholder.png'">
            </div>
            <div class="prize-info">
                <div class="prize-name">${prize.item_label}${jackpotBadge}</div>
                <div class="prize-count">×${prize.item_count}</div>
            </div>
            <div class="prize-prob">${prize.probability}%</div>
        `;
        
        container.appendChild(item);
    });
}

// Render History
function renderHistory(history) {
    const container = document.getElementById('historyItems');
    container.innerHTML = '';
    
    if (!history || history.length === 0) {
        container.innerHTML = '<div style="text-align: center; padding: 20px; color: #666;">履歴がありません</div>';
        return;
    }
    
    history.forEach(record => {
        const item = document.createElement('div');
        item.className = `history-item ${record.rarity}`;
        
        const date = new Date(record.pulled_at);
        const timeStr = date.toLocaleString('ja-JP', { 
            month: 'numeric', 
            day: 'numeric', 
            hour: '2-digit', 
            minute: '2-digit' 
        });
        
        item.innerHTML = `
            <div class="history-item-image">
                <img src="${getItemImageUrl(record.item_name)}" alt="${record.item_label}" onerror="this.src='nui://qb-inventory/html/images/placeholder.png'">
            </div>
            <div class="history-item-info">
                <div class="history-item-name">${record.item_label} ×${record.item_count}</div>
                <div class="history-item-time">${timeStr}</div>
            </div>
        `;
        
        container.appendChild(item);
    });
}

// Open Gacha UI
function openGacha(data) {
    currentGacha = data.gacha;
    currentBalance = data.balance;
    config = data.config;
    
    // Show background effects
    document.querySelector('.bg-effects').style.display = 'block';
    document.getElementById('particles').style.display = 'block';
    
    // Update UI
    document.getElementById('gachaTitle').textContent = `🎰 ${currentGacha.name}`;
    
    const priceType = currentGacha.price_type;
    let priceIcon = '💰';
    if (priceType === 'bank') priceIcon = '🏦';
    else if (priceType === 'coin') priceIcon = '🎫';
    
    document.getElementById('priceIcon').textContent = priceIcon;
    document.getElementById('priceText').textContent = `${formatNumber(currentGacha.price)} / 回`;
    
    // Multi pull button
    const btnMulti = document.getElementById('btnMulti');
    if (config.multiPull && config.multiPull.enabled) {
        btnMulti.style.display = 'block';
        btnMulti.textContent = `${config.multiPull.count}連ガチャ`;
    } else {
        btnMulti.style.display = 'none';
    }
    
    updateBalanceDisplay();
    updatePityDisplay(currentGacha.current_pity || 0, currentGacha.pity_count);
    renderCapsules(currentGacha.prizes);
    renderPrizeList(currentGacha.prizes);
    
    gachaContainer.style.display = 'flex';
    createParticles();
}

// Open Create UI
function openCreate(data) {
    availableItems = data.items || [];
    config = data.config || {};
    
    // Show background effects
    document.querySelector('.bg-effects').style.display = 'block';
    document.getElementById('particles').style.display = 'block';
    
    // Reset form
    document.getElementById('createName').value = '';
    document.getElementById('createDesc').value = '';
    document.getElementById('createPrice').value = config.defaults?.price || 500;
    document.getElementById('createPriceType').value = 'money';
    document.getElementById('createPity').value = config.defaults?.pityCount || 100;
    
    // Reset color theme
    document.querySelectorAll('.color-theme').forEach(t => t.classList.remove('selected'));
    document.querySelector('.color-theme.cyan')?.classList.add('selected');
    
    // Clear prizes
    document.getElementById('prizeListEdit').innerHTML = '';
    updateProbTotal();
    
    createOverlay.style.display = 'flex';
    createOverlay.classList.add('show');
    createParticles();
}

// Close UI
function closeUI() {
    gachaContainer.style.display = 'none';
    createOverlay.style.display = 'none';
    createOverlay.classList.remove('show');
    resultOverlay.classList.remove('show');
    multiResultOverlay.classList.remove('show');
    currentGacha = null;
    
    // Hide background effects
    document.querySelector('.bg-effects').style.display = 'none';
    document.getElementById('particles').style.display = 'none';
}

// Pull Gacha
async function pullGacha(count) {
    if (isPulling || !currentGacha) return;
    
    isPulling = true;
    
    // Disable buttons
    document.getElementById('btnSingle').disabled = true;
    document.getElementById('btnMulti').disabled = true;
    
    // Start animation
    document.getElementById('machineBody').classList.add('pulling');
    
    // Request pull from client
    try {
        const response = await fetch(`https://${GetParentResourceName()}/pullGacha`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ count: count })
        });
        
        const result = await response.json();
        
        // Stop animation
        document.getElementById('machineBody').classList.remove('pulling');
        
        if (result.success && result.items && result.items.length > 0) {
            if (count === 1) {
                showSingleResult(result.items[0]);
            } else {
                showMultiResult(result.items);
            }
        }
    } catch (error) {
        console.error('Pull error:', error);
        document.getElementById('machineBody').classList.remove('pulling');
    }
    
    // Re-enable buttons
    document.getElementById('btnSingle').disabled = false;
    document.getElementById('btnMulti').disabled = false;
    isPulling = false;
}

// Show Single Result
function showSingleResult(item) {
    const capsule = document.getElementById('resultCapsule');
    const itemImage = document.getElementById('resultItemImage');
    const rarity = document.getElementById('resultRarity');
    const itemName = document.getElementById('resultItemName');
    const itemCount = document.getElementById('resultItemCount');
    const legendaryEffects = document.getElementById('legendaryEffects');
    
    // Reset animations
    capsule.className = 'result-capsule ' + item.rarity;
    rarity.className = 'result-rarity ' + item.rarity;
    rarity.textContent = item.rarity.toUpperCase();
    
    itemImage.src = getItemImageUrl(item.item_name);
    itemImage.onerror = function() { this.src = 'nui://qb-inventory/html/images/placeholder.png'; };
    
    itemName.textContent = item.item_label;
    itemCount.textContent = `×${item.item_count} 獲得!`;
    
    // Legendary effects
    if (item.rarity === 'legendary' || item.is_jackpot) {
        legendaryEffects.classList.add('show');
    } else {
        legendaryEffects.classList.remove('show');
    }
    
    resultOverlay.classList.add('show');
}

// Show Multi Result
function showMultiResult(items) {
    const container = document.getElementById('multiResultItems');
    container.innerHTML = '';
    
    items.forEach((item, index) => {
        const div = document.createElement('div');
        div.className = `multi-result-item ${item.rarity}`;
        div.style.animationDelay = (index * 0.1) + 's';
        
        div.innerHTML = `
            <div class="multi-item-image">
                <img src="${getItemImageUrl(item.item_name)}" alt="${item.item_label}" onerror="this.src='nui://qb-inventory/html/images/placeholder.png'">
            </div>
            <div class="multi-item-name">${item.item_label}</div>
            <div class="multi-item-count">×${item.item_count}</div>
        `;
        
        container.appendChild(div);
    });
    
    multiResultOverlay.classList.add('show');
}

// Close Result
function closeResult() {
    resultOverlay.classList.remove('show');
    document.getElementById('legendaryEffects').classList.remove('show');
}

// Close Multi Result
function closeMultiResult() {
    multiResultOverlay.classList.remove('show');
}

// Update Probability Total
function updateProbTotal() {
    const prizeItems = document.querySelectorAll('#prizeListEdit .prize-edit-item');
    let total = 0;
    
    prizeItems.forEach(item => {
        const probInput = item.querySelector('input[data-field="probability"]');
        if (probInput) {
            total += parseFloat(probInput.value) || 0;
        }
    });
    
    const probTotalEl = document.getElementById('probTotal');
    probTotalEl.textContent = `${total.toFixed(1)}% / 100%`;
    
    if (Math.abs(total - 100) < 0.1) {
        probTotalEl.classList.add('valid');
        probTotalEl.classList.remove('invalid');
    } else {
        probTotalEl.classList.remove('valid');
        probTotalEl.classList.add('invalid');
    }
}

// Add Prize Item
function addPrizeItem(itemName = '', itemLabel = 'アイテムを選択', count = 1, rarity = 'common', probability = 0, isJackpot = false) {
    const container = document.getElementById('prizeListEdit');
    
    const div = document.createElement('div');
    div.className = 'prize-edit-item';
    div.innerHTML = `
        <select data-field="rarity">
            <option value="common" ${rarity === 'common' ? 'selected' : ''}>Common</option>
            <option value="uncommon" ${rarity === 'uncommon' ? 'selected' : ''}>Uncommon</option>
            <option value="rare" ${rarity === 'rare' ? 'selected' : ''}>Rare</option>
            <option value="epic" ${rarity === 'epic' ? 'selected' : ''}>Epic</option>
            <option value="legendary" ${rarity === 'legendary' ? 'selected' : ''}>Legendary</option>
        </select>
        <button class="item-select-btn" data-item-name="${itemName}">${itemLabel}</button>
        <input type="number" data-field="count" placeholder="個数" value="${count}" min="1" max="100">
        <input type="number" data-field="probability" placeholder="確率%" value="${probability}" min="0.01" max="100" step="0.01">
        <label style="display: flex; align-items: center; gap: 5px; font-size: 0.75rem; color: #888;">
            <input type="checkbox" data-field="jackpot" ${isJackpot ? 'checked' : ''}> JP
        </label>
        <button class="btn-remove-prize">✕</button>
    `;
    
    // Item select button
    div.querySelector('.item-select-btn').addEventListener('click', function() {
        selectedPrizeIndex = Array.from(container.children).indexOf(div);
        openItemSelector();
    });
    
    // Remove button
    div.querySelector('.btn-remove-prize').addEventListener('click', function() {
        div.remove();
        updateProbTotal();
    });
    
    // Probability input
    div.querySelector('input[data-field="probability"]').addEventListener('input', updateProbTotal);
    
    container.appendChild(div);
    updateProbTotal();
}

// Open Item Selector
function openItemSelector() {
    renderItemSelector(availableItems);
    itemSelectorOverlay.style.display = 'flex';
    itemSelectorOverlay.classList.add('show');
}

// Close Item Selector
function closeItemSelector() {
    itemSelectorOverlay.style.display = 'none';
    itemSelectorOverlay.classList.remove('show');
    selectedPrizeIndex = null;
}

// Render Item Selector
function renderItemSelector(items) {
    const container = document.getElementById('itemSelectorList');
    container.innerHTML = '';
    
    items.forEach(item => {
        const div = document.createElement('div');
        div.className = 'item-selector-item';
        div.innerHTML = `
            <img src="${getItemImageUrl(item.name)}" alt="${item.label}" onerror="this.src='nui://qb-inventory/html/images/placeholder.png'">
            <span>${item.label}</span>
        `;
        
        div.addEventListener('click', function() {
            selectItem(item);
        });
        
        container.appendChild(div);
    });
}

// Select Item
function selectItem(item) {
    if (selectedPrizeIndex === null) return;
    
    const container = document.getElementById('prizeListEdit');
    const prizeItem = container.children[selectedPrizeIndex];
    
    if (prizeItem) {
        const btn = prizeItem.querySelector('.item-select-btn');
        btn.textContent = item.label;
        btn.dataset.itemName = item.name;
    }
    
    closeItemSelector();
}

// Get Create Data
function getCreateData() {
    const name = document.getElementById('createName').value.trim();
    const description = document.getElementById('createDesc').value.trim();
    const price = parseInt(document.getElementById('createPrice').value) || 500;
    const priceType = document.getElementById('createPriceType').value;
    const pityCount = parseInt(document.getElementById('createPity').value) || 0;
    
    const colorTheme = document.querySelector('.color-theme.selected')?.dataset.theme || 'cyan';
    
    const prizes = [];
    document.querySelectorAll('#prizeListEdit .prize-edit-item').forEach(item => {
        const itemBtn = item.querySelector('.item-select-btn');
        const itemName = itemBtn?.dataset.itemName;
        
        if (itemName) {
            prizes.push({
                itemName: itemName,
                itemLabel: itemBtn.textContent,
                itemCount: parseInt(item.querySelector('input[data-field="count"]').value) || 1,
                rarity: item.querySelector('select[data-field="rarity"]').value,
                probability: parseFloat(item.querySelector('input[data-field="probability"]').value) || 0,
                isJackpot: item.querySelector('input[data-field="jackpot"]').checked
            });
        }
    });
    
    return { name, description, price, priceType, pityCount, colorTheme, prizes };
}

// Submit Create
async function submitCreate() {
    const data = getCreateData();
    
    try {
        const response = await fetch(`https://${GetParentResourceName()}/createGacha`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
        
        const result = await response.json();
        
        if (result.success) {
            closeUI();
        }
    } catch (error) {
        console.error('Create error:', error);
    }
}

// Load History
async function loadHistory() {
    if (!currentGacha) return;
    
    try {
        const response = await fetch(`https://${GetParentResourceName()}/getHistory`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ gachaId: currentGacha.id })
        });
        
        const result = await response.json();
        
        if (result.success) {
            renderHistory(result.history);
        }
    } catch (error) {
        console.error('History error:', error);
    }
}

// Event Listeners
document.getElementById('btnClose').addEventListener('click', function() {
    fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' });
});

document.getElementById('btnSingle').addEventListener('click', function() {
    pullGacha(1);
});

document.getElementById('btnMulti').addEventListener('click', function() {
    pullGacha(config.multiPull?.count || 10);
});

document.getElementById('btnAgain').addEventListener('click', function() {
    closeResult();
    setTimeout(() => pullGacha(1), 300);
});

document.getElementById('btnBack').addEventListener('click', closeResult);

document.getElementById('btnMultiAgain').addEventListener('click', function() {
    closeMultiResult();
    setTimeout(() => pullGacha(config.multiPull?.count || 10), 300);
});

document.getElementById('btnMultiBack').addEventListener('click', closeMultiResult);

document.getElementById('btnCreateClose').addEventListener('click', function() {
    fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' });
});

document.getElementById('btnCreateCancel').addEventListener('click', function() {
    fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' });
});

document.getElementById('btnCreateSubmit').addEventListener('click', submitCreate);

document.getElementById('btnAddPrize').addEventListener('click', function() {
    addPrizeItem();
});

document.getElementById('btnItemSelectorClose').addEventListener('click', closeItemSelector);

document.getElementById('itemSearch').addEventListener('input', function() {
    const query = this.value.toLowerCase();
    const filtered = availableItems.filter(item => 
        item.label.toLowerCase().includes(query) || 
        item.name.toLowerCase().includes(query)
    );
    renderItemSelector(filtered);
});

// Color theme selection
document.querySelectorAll('.color-theme').forEach(theme => {
    theme.addEventListener('click', function() {
        document.querySelectorAll('.color-theme').forEach(t => t.classList.remove('selected'));
        this.classList.add('selected');
    });
});

// Tab navigation
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', function() {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        this.classList.add('active');
        
        const tab = this.dataset.tab;
        if (tab === 'prizes') {
            document.getElementById('prizeItems').style.display = 'block';
            document.getElementById('historyItems').style.display = 'none';
            document.getElementById('prizeHeader').textContent = `📦 景品一覧 - 全${currentGacha?.prizes?.length || 0}種`;
        } else if (tab === 'history') {
            document.getElementById('prizeItems').style.display = 'none';
            document.getElementById('historyItems').style.display = 'block';
            document.getElementById('prizeHeader').textContent = '📜 履歴';
            loadHistory();
        }
    });
});

// Keyboard
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        if (itemSelectorOverlay.classList.contains('show')) {
            closeItemSelector();
        } else if (resultOverlay.classList.contains('show')) {
            closeResult();
        } else if (multiResultOverlay.classList.contains('show')) {
            closeMultiResult();
        } else {
            fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' });
        }
    }
});

// NUI Message Handler
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch (data.action) {
        case 'openGacha':
            openGacha(data);
            break;
            
        case 'openCreate':
            openCreate(data);
            break;
            
        case 'close':
            closeUI();
            break;
            
        case 'updateBalance':
            currentBalance = data.balance;
            updateBalanceDisplay();
            break;
            
        case 'updatePity':
            updatePityDisplay(data.pityCount, data.pityMax);
            break;
    }
});

// Initialize
createParticles();

// Ensure UI is hidden on load
document.addEventListener('DOMContentLoaded', function() {
    closeUI();
});
