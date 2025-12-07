// 変数
let isVisible = false;

// UI初期化
window.addEventListener('load', function() {
    // イベントリスナー
    document.getElementById('closeBtn').addEventListener('click', closeUI);
    document.getElementById('selectCitizen').addEventListener('click', function() {
        selectPack('citizen');
    });
    document.getElementById('selectCriminal').addEventListener('click', function() {
        selectPack('criminal');
    });

    // ESCキーでUIを閉じる
    document.addEventListener('keyup', function(event) {
        if (event.key === 'Escape' && isVisible) {
            closeUI();
        }
    });
});

// NUIメッセージ受信
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'toggle') {
        if (data.show) {
            showUI(data);
        } else {
            hideUI();
        }
    }
});

// アイテムリストを生成する関数
function generateItemList(items, elementId) {
    const container = document.getElementById(elementId);
    container.innerHTML = ''; // リストをクリア
    
    items.forEach(item => {
        const li = document.createElement('li');
        
        // 現金の場合は特別な表示にする
        if (item.name === 'cash') {
            li.textContent = `${item.label} $${item.amount.toLocaleString()}`;
        } else {
            li.textContent = `${item.label} x${item.amount}`;
        }
        
        container.appendChild(li);
    });
}

// UI表示
function showUI(data) {
    isVisible = true;
    
    // タイトルと説明を設定
    if (data.title) document.getElementById('title').textContent = data.title;
    if (data.citizenPackName) document.getElementById('citizenPackName').textContent = data.citizenPackName;
    if (data.criminalPackName) document.getElementById('criminalPackName').textContent = data.criminalPackName;
    if (data.citizenDesc) document.getElementById('citizenDesc').textContent = data.citizenDesc;
    if (data.criminalDesc) document.getElementById('criminalDesc').textContent = data.criminalDesc;
    
    // アイテムリストを生成
    if (data.citizenItems) generateItemList(data.citizenItems, 'citizenItems');
    if (data.criminalItems) generateItemList(data.criminalItems, 'criminalItems');
    
    // UIを表示
    document.getElementById('container').classList.remove('hidden');
}

// UI非表示
function hideUI() {
    isVisible = false;
    document.getElementById('container').classList.add('hidden');
}

// UIを閉じる
function closeUI() {
    hideUI();
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

// パック選択
function selectPack(packType) {
    fetch(`https://${GetParentResourceName()}/selectPack`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            packType: packType
        })
    });
}