// ============================================
// ガチャアニメーション表示
// ============================================
function showGachaAnimation() {
    const animationDiv = document.getElementById('gachaAnimation');
    const rouletteItems = document.getElementById('rouletteItems');
    
    const vehicleEmojis = ['🚗', '🚙', '🚕', '🚌', '🏎️', '🚓', '🚑', '🚒', '🚐', '🚚', '🚛', '🏍️'];
    rouletteItems.innerHTML = '';
    
    for (let i = 0; i < 20; i++) {
        const item = document.createElement('div');
        item.className = 'roulette-item';
        item.textContent = vehicleEmojis[i % vehicleEmojis.length];
        rouletteItems.appendChild(item);
    }
    
    animationDiv.classList.remove('hidden');
    setTimeout(() => {
        animationDiv.classList.add('show');
    }, 10);
}

function hideGachaAnimation() {
    const animationDiv = document.getElementById('gachaAnimation');
    animationDiv.classList.remove('show');
    
    setTimeout(() => {
        animationDiv.classList.add('hidden');
    }, 300);
}

// ============================================
// 紙吹雪生成関数
// ============================================
function createConfetti(containerId) {
    const container = document.getElementById(containerId);
    if (!container) return;
    
    const colors = ['#ff0000', '#00ff00', '#0000ff', '#ffff00', '#ff00ff', '#00ffff', '#ffa500', '#ff1493'];
    
    for (let i = 0; i < 50; i++) {
        setTimeout(() => {
            const confetti = document.createElement('div');
            confetti.className = 'confetti';
            confetti.style.left = Math.random() * 100 + '%';
            confetti.style.background = colors[Math.floor(Math.random() * colors.length)];
            confetti.style.animationDelay = Math.random() * 0.5 + 's';
            confetti.style.animationDuration = (Math.random() * 2 + 2) + 's';
            container.appendChild(confetti);
            
            setTimeout(() => confetti.remove(), 3000);
        }, i * 50);
    }
}

// ============================================
// レアリティクラス設定
// ============================================
function setRarityClass(element, rarity) {
    element.className = element.className.replace(/\b(common|rare|superrare|ultrarare)\b/g, '');
    
    switch(rarity.toLowerCase()) {
        case 'common':
            element.classList.add('common');
            break;
        case 'rare':
            element.classList.add('rare');
            break;
        case 'superrare':
            element.classList.add('superrare');
            break;
        case 'ultrarare':
            element.classList.add('ultrarare');
            break;
        default:
            element.classList.add('common');
    }
}

// ============================================
// 単発ガチャ結果表示
// ============================================
function showGachaResult(vehicle) {
    const resultDiv = document.getElementById('gachaResult');
    const rarityBadge = document.getElementById('rarityBadge');
    const rarityText = document.getElementById('rarityText');
    const vehicleName = document.getElementById('vehicleName');
    const vehiclePlate = document.getElementById('vehiclePlate');
    
    rarityText.textContent = vehicle.rarityLabel || vehicle.rarity;
    vehicleName.textContent = vehicle.label;
    vehiclePlate.textContent = 'プレート: ' + vehicle.plate;
    
    setRarityClass(rarityBadge, vehicle.rarity);
    
    resultDiv.classList.remove('hidden');
    setTimeout(() => {
        resultDiv.classList.add('show');
    }, 10);
    
    createConfetti('confettiContainer');
    
    if (vehicle.rarity.toLowerCase() === 'ultrarare') {
        setTimeout(() => createConfetti('confettiContainer'), 1000);
        setTimeout(() => createConfetti('confettiContainer'), 2000);
    }
}

function hideGachaResult() {
    const resultDiv = document.getElementById('gachaResult');
    resultDiv.classList.remove('show');
    
    setTimeout(() => {
        resultDiv.classList.add('hidden');
        document.getElementById('confettiContainer').innerHTML = '';
    }, 300);
}

// ============================================
// 10連ガチャ結果表示
// ============================================
function showMultiGachaResult(vehicles) {
    const resultDiv = document.getElementById('multiGachaResult');
    const vehicleGrid = document.getElementById('multiVehicleGrid');
    
    vehicleGrid.innerHTML = '';
    
    vehicles.forEach((vehicle, index) => {
        const card = document.createElement('div');
        card.className = 'multi-vehicle-card';
        
        const badge = document.createElement('div');
        badge.className = 'multi-rarity-badge rarity-badge';
        badge.textContent = vehicle.rarityLabel || vehicle.rarity;
        setRarityClass(badge, vehicle.rarity);
        
        const icon = document.createElement('div');
        icon.className = 'multi-vehicle-icon';
        icon.textContent = '🚗';
        
        const name = document.createElement('div');
        name.className = 'multi-vehicle-name';
        name.textContent = vehicle.label;
        
        const plate = document.createElement('div');
        plate.className = 'multi-vehicle-plate';
        plate.textContent = vehicle.plate;
        
        card.appendChild(badge);
        card.appendChild(icon);
        card.appendChild(name);
        card.appendChild(plate);
        
        vehicleGrid.appendChild(card);
    });
    
    resultDiv.classList.remove('hidden');
    setTimeout(() => {
        resultDiv.classList.add('show');
    }, 10);
    
    // 紙吹雪エフェクト
    createConfetti('multiConfettiContainer');
    
    // UltraRareが含まれている場合は追加の紙吹雪
    const hasUltraRare = vehicles.some(v => v.rarity.toLowerCase() === 'ultrarare');
    if (hasUltraRare) {
        setTimeout(() => createConfetti('multiConfettiContainer'), 1000);
        setTimeout(() => createConfetti('multiConfettiContainer'), 2000);
        setTimeout(() => createConfetti('multiConfettiContainer'), 3000);
    }
}

function hideMultiGachaResult() {
    const resultDiv = document.getElementById('multiGachaResult');
    resultDiv.classList.remove('show');
    
    setTimeout(() => {
        resultDiv.classList.add('hidden');
        document.getElementById('multiConfettiContainer').innerHTML = '';
    }, 300);
}

// ============================================
// NUIメッセージリスナー
// ============================================
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.type === 'showGachaAnimation') {
        showGachaAnimation();
    } else if (data.type === 'hideGachaAnimation') {
        hideGachaAnimation();
    } else if (data.type === 'showGachaResult') {
        showGachaResult(data.vehicle);
    } else if (data.type === 'hideGachaResult') {
        hideGachaResult();
    } else if (data.type === 'showMultiGachaResult') {
        showMultiGachaResult(data.vehicles);
    } else if (data.type === 'hideMultiGachaResult') {
        hideMultiGachaResult();
    }
});

// ============================================
// ESCキーで閉じる
// ============================================
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        hideGachaAnimation();
        hideGachaResult();
        hideMultiGachaResult();
        
        fetch('https://ng-vehiclegacha/closeUI', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        });
    }
});
