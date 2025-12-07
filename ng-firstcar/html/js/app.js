// html/js/app.js を修正
let selectedVehicleIndex = null;
let vehiclesData = [];

// メッセージリスナー
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'open') {
        vehiclesData = data.vehicles;
        renderVehicles();
        document.getElementById('container').classList.remove('hidden');
    }
});

// 車両リストをレンダリング
function renderVehicles() {
    const container = document.querySelector('.vehicles-container');
    container.innerHTML = '';
    
    vehiclesData.forEach((vehicle, index) => {
        const card = document.createElement('div');
        card.className = 'vehicle-card';
        card.dataset.index = index;
        
        card.innerHTML = `
            <div class="vehicle-image" style="background-image: url('images/${vehicle.image}')"></div>
            <div class="vehicle-name">${vehicle.label}</div>
            <div class="vehicle-description">${vehicle.description}</div>
            <div class="vehicle-category">カテゴリー: ${vehicle.category}</div>
        `;
        
        card.addEventListener('click', () => selectVehicle(index));
        container.appendChild(card);
    });
}

// 車両選択時の処理
function selectVehicle(index) {
    // 以前の選択をクリア
    const cards = document.querySelectorAll('.vehicle-card');
    cards.forEach(card => card.classList.remove('selected'));
    
    // 新しい選択を設定
    cards[index].classList.add('selected');
    selectedVehicleIndex = index;
    
    // 選択ボタンを有効化
    document.getElementById('select-btn').disabled = false;
}

// UIを閉じる
function closeUI() {
    document.getElementById('container').classList.add('hidden');
    
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    })
    .catch(error => console.error('Error closing UI:', error));
}

// 車両を選択して決定
function confirmSelection() {
    if (selectedVehicleIndex === null) return;
    
    document.getElementById('container').classList.add('hidden');
    
    fetch(`https://${GetParentResourceName()}/selectVehicle`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            index: selectedVehicleIndex + 1 // Luaの配列は1から始まるため +1
        })
    })
    .catch(error => console.error('Error selecting vehicle:', error));
}

// イベントリスナー
document.getElementById('close-btn').addEventListener('click', closeUI);
document.getElementById('select-btn').addEventListener('click', confirmSelection);

// ESCキーでUIを閉じる
document.addEventListener('keyup', function(event) {
    if (event.key === 'Escape') {
        closeUI();
    }
});