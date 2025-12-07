let selectedItem = null;
let shopConfig = null;
let cartItems = []; // カートアイテムを格納する配列

// ショップのUIを表示
function showShopUI() {
    document.getElementById('weaponshop-container').classList.add('visible');
}

// 通知を表示
function showNotification(message, type = 'info') {
    const notification = document.getElementById('notification');
    const notificationMessage = document.getElementById('notification-message');
    const notificationIcon = document.getElementById('notification-icon').querySelector('i');
    
    notification.className = ''; // クラスをリセット
    notification.classList.add(`notification-${type}`);
    
    notificationMessage.textContent = message;
    
    if (type === 'success') {
        notificationIcon.className = 'fas fa-check-circle';
    } else if (type === 'error') {
        notificationIcon.className = 'fas fa-exclamation-circle';
    } else {
        notificationIcon.className = 'fas fa-info-circle';
    }
    
    notification.classList.remove('hidden');
    
    // 3秒後に通知を非表示
    setTimeout(() => {
        notification.classList.add('hidden');
    }, 3000);
}

// アイテムリストを表示
function renderItemsList(items) {
    const container = document.getElementById('items-container');
    container.innerHTML = '';
    
    items.forEach(item => {
        const itemCard = document.createElement('div');
        itemCard.className = 'item-card';
        itemCard.dataset.itemName = item.name;
        
        // ox_inventoryからアイテム画像のURLを取得
        const itemImageUrl = getItemImageUrl(item.name);
        
        itemCard.innerHTML = `
            <img src="${itemImageUrl}" class="item-image" alt="${item.label}" onerror="handleImageError(this)">
            <div class="item-name">${item.label}</div>
            <div class="item-price">$${item.price.toLocaleString()}</div>
        `;
        
        // アイテムクリック時のイベント
        itemCard.addEventListener('click', () => {
            // 選択状態のクラスを切り替え
            document.querySelectorAll('.item-card').forEach(card => {
                card.classList.remove('selected');
            });
            itemCard.classList.add('selected');
            
            // 選択されたアイテム情報を表示
            displayItemDetails(item);
            selectedItem = item;
        });
        
        container.appendChild(itemCard);
    });
}

// ox_inventoryからアイテム画像のURLを取得
function getItemImageUrl(itemName) {
    // 武器の場合
    if (itemName.startsWith('WEAPON_')) {
        return `nui://ox_inventory/web/images/${itemName.toLowerCase()}.png`;
    } 
    // 弾薬の場合
    else if (itemName.startsWith('ammo-')) {
        // 弾薬タイプを抽出（例：ammo-9 → 9）
        const ammoType = itemName.split('-')[1];
        
        // よくある弾薬タイプの名前マッピング
        const ammoNameMap = {
            '9': 'ammo-9',
            '22': 'ammo-22',
            '38': 'ammo-38',
            '44': 'ammo-44',
            '45': 'ammo-45',
            '50': 'ammo-50',
            '357': 'ammo-357',
            '44': '44magnum',
            '38': '38special',
            '762': 'ammo-rifle2',
            '556': 'ammo-rifle',
            '12g': 'shotgun'
        };
        
        // マッピングに存在する場合はそれを使用、それ以外はデフォルトの弾薬画像
        if (ammoNameMap[ammoType]) {
            return `nui://ox_inventory/web/images/${ammoNameMap[ammoType]}.png`;
        } else {
            return `nui://ox_inventory/web/images/ammo.png`;
        }
    }
    // その他のアイテム
    else {
        return `nui://ox_inventory/web/images/${itemName}.png`;
    }
}

// 画像読み込みエラー時の処理
function handleImageError(img) {
    console.log(`画像の読み込みに失敗しました: ${img.src}`);
    
    // まず、別の弾薬画像をチェック
    if (img.src.includes('ammo') || img.src.includes('mm.png')) {
        img.src = `nui://ox_inventory/web/images/ammo.png`;
        // 2回目のエラーを防ぐためにフォールバック
        img.onerror = function() {
            img.src = 'https://via.placeholder.com/80?text=No+Image';
            img.onerror = null;
        };
    } else {
        // 弾薬以外の画像はフォールバック画像を設定
        img.src = 'https://via.placeholder.com/80?text=No+Image';
        // エラーハンドラを削除して無限ループを防止
        img.onerror = null;
    }
}

// 選択されたアイテムの詳細を表示
function displayItemDetails(item) {
    const infoContainer = document.getElementById('selected-item-info');
    const addToCartContainer = document.getElementById('add-to-cart');
    const purchaseOptions = document.getElementById('purchase-options');
    
    // アイテム情報を表示
    infoContainer.innerHTML = `
        <img src="${getItemImageUrl(item.name)}" class="selected-item-image" alt="${item.label}" onerror="handleImageError(this)">
        <h2>${item.label}</h2>
        <p>${item.description}</p>
        <p class="item-detail-price">価格: <span>$${item.price.toLocaleString()}</span></p>
    `;
    
    // 数量を1にリセット
    document.getElementById('item-quantity').value = 1;
    
    // カートに追加ボタンを表示
    addToCartContainer.style.display = 'block';
    
    // カートが空でなければカートとチェックアウトを表示
    if (cartItems.length > 0) {
        document.getElementById('cart-container').style.display = 'block';
        purchaseOptions.style.display = 'block';
    } else {
        document.getElementById('cart-container').style.display = 'none';
        purchaseOptions.style.display = 'none';
    }
    
    // 支払い方法のボタン表示を制御
    document.getElementById('pay-cash').style.display = shopConfig.paymentMethods.cash ? 'flex' : 'none';
    document.getElementById('pay-bank').style.display = shopConfig.paymentMethods.bank ? 'flex' : 'none';
}

// NUI Callbackのセットアップ
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'open') {
        // ショップ設定を保存
        shopConfig = {
            title: data.config.title,
            subtitle: data.config.subtitle,
            logo: data.config.logo,
            colorTheme: data.config.colorTheme,
            paymentMethods: data.paymentMethods
        };
        
        // テーマカラーを設定
        document.documentElement.style.setProperty('--theme-color', shopConfig.colorTheme);
        document.documentElement.style.setProperty('--theme-color-hover', shopConfig.colorTheme.replace('0.8', '0.9'));
        
        // ショップタイトルと説明を設定
        document.getElementById('title').textContent = shopConfig.title;
        document.getElementById('subtitle').textContent = shopConfig.subtitle;
        document.getElementById('shop-logo').src = shopConfig.logo;
        
        // アイテムリストを表示
        renderItemsList(data.items);
        
        // UIを表示
        showShopUI();
    } else if (data.action === 'close') {
        document.getElementById('weaponshop-container').classList.remove('visible');
    }
});

// 閉じるボタンのイベント
document.getElementById('close-button').addEventListener('click', function() {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
    document.getElementById('weaponshop-container').classList.remove('visible');
});

// ESCキーでUIを閉じる
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        });
        document.getElementById('weaponshop-container').classList.remove('visible');
    }
});

// 現金支払いボタンのイベント
document.getElementById('pay-cash').addEventListener('click', function() {
    if (!selectedItem) return;
    
    purchaseItem('cash');
});

// 銀行支払いボタンのイベント
document.getElementById('pay-bank').addEventListener('click', function() {
    if (!selectedItem) return;
    
    purchaseItem('bank');
});

// アイテム購入処理
function purchaseItem(paymentMethod) {
    if (!selectedItem) return;
    
    fetch(`https://${GetParentResourceName()}/buyItem`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            item: selectedItem,
            paymentMethod: paymentMethod
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.status === 'success') {
            showNotification(data.message, 'success');
        } else {
            showNotification(data.message, 'error');
        }
    })
    .catch(error => {
        showNotification('エラーが発生しました', 'error');
        console.error('Error:', error);
    });
}

// カートにアイテムを追加
function addToCart() {
    if (!selectedItem) return;
    
    const quantity = parseInt(document.getElementById('item-quantity').value);
    if (isNaN(quantity) || quantity < 1) {
        showNotification('有効な数量を入力してください', 'error');
        return;
    }
    
    // 既にカートに同じアイテムがあるか確認
    const existingItemIndex = cartItems.findIndex(item => item.name === selectedItem.name);
    
    if (existingItemIndex !== -1) {
        // 既存のアイテムの数量を更新
        cartItems[existingItemIndex].quantity += quantity;
        showNotification(`${selectedItem.label}の数量を更新しました`, 'success');
    } else {
        // 新しいアイテムとしてカートに追加
        cartItems.push({
            ...selectedItem,
            quantity: quantity
        });
        showNotification(`${selectedItem.label}をカートに追加しました`, 'success');
    }
    
    // カートの表示を更新
    renderCart();
    
    // カートとチェックアウトオプションを表示
    document.getElementById('cart-container').style.display = 'block';
    document.getElementById('purchase-options').style.display = 'block';
}

// カートから商品を削除
function removeFromCart(index) {
    if (index >= 0 && index < cartItems.length) {
        const removedItem = cartItems[index];
        cartItems.splice(index, 1);
        showNotification(`${removedItem.label}をカートから削除しました`, 'info');
        
        // カートの表示を更新
        renderCart();
        
        // カートが空になった場合、カートとチェックアウトオプションを非表示
        if (cartItems.length === 0) {
            document.getElementById('cart-container').style.display = 'none';
            document.getElementById('purchase-options').style.display = 'none';
        }
    }
}

// カート内のアイテム数量を更新
function updateCartItemQuantity(index, change) {
    if (index >= 0 && index < cartItems.length) {
        const newQuantity = cartItems[index].quantity + change;
        
        if (newQuantity <= 0) {
            // 数量が0以下になったらアイテムを削除
            removeFromCart(index);
        } else {
            cartItems[index].quantity = newQuantity;
            renderCart();
        }
    }
}

// カートの内容を表示
function renderCart() {
    const cartContainer = document.getElementById('cart-items');
    cartContainer.innerHTML = '';
    
    let totalPrice = 0;
    
    cartItems.forEach((item, index) => {
        const itemPrice = item.price * item.quantity;
        totalPrice += itemPrice;
        
        const cartItemEl = document.createElement('div');
        cartItemEl.className = 'cart-item';
        
        cartItemEl.innerHTML = `
            <img src="${getItemImageUrl(item.name)}" class="cart-item-image" alt="${item.label}" onerror="handleImageError(this)">
            <div class="cart-item-info">
                <div class="cart-item-name">${item.label}</div>
                <div class="cart-item-price">$${item.price.toLocaleString()} × ${item.quantity} = $${itemPrice.toLocaleString()}</div>
            </div>
            <div class="cart-item-quantity">
                <button class="cart-quantity-btn decrease-btn" data-index="${index}"><i class="fas fa-minus"></i></button>
                <span class="cart-quantity-value">${item.quantity}</span>
                <button class="cart-quantity-btn increase-btn" data-index="${index}"><i class="fas fa-plus"></i></button>
            </div>
            <button class="cart-item-remove" data-index="${index}"><i class="fas fa-trash-alt"></i></button>
        `;
        
        cartContainer.appendChild(cartItemEl);
    });
    
    // 合計金額を更新
    document.getElementById('total-price').textContent = totalPrice.toLocaleString();
    
    // カートアイテムのボタンにイベントリスナーを追加
    document.querySelectorAll('.decrease-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const index = parseInt(this.dataset.index);
            updateCartItemQuantity(index, -1);
        });
    });
    
    document.querySelectorAll('.increase-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const index = parseInt(this.dataset.index);
            updateCartItemQuantity(index, 1);
        });
    });
    
    document.querySelectorAll('.cart-item-remove').forEach(btn => {
        btn.addEventListener('click', function() {
            const index = parseInt(this.dataset.index);
            removeFromCart(index);
        });
    });
}

// アイテム購入処理を更新（カートの中身を購入）
function purchaseItem(paymentMethod) {
    if (cartItems.length === 0) {
        showNotification('カートが空です', 'error');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/buyItems`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            items: cartItems,
            paymentMethod: paymentMethod
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.status === 'success') {
            showNotification(data.message, 'success');
            // 購入成功したらカートを空にする
            cartItems = [];
            renderCart();
            // カートとチェックアウトオプションを非表示
            document.getElementById('cart-container').style.display = 'none';
            document.getElementById('purchase-options').style.display = 'none';
        } else {
            showNotification(data.message, 'error');
        }
    })
    .catch(error => {
        showNotification('エラーが発生しました', 'error');
        console.error('Error:', error);
    });
}

// 数量増減ボタンのイベント
document.getElementById('decrease-quantity').addEventListener('click', function() {
    const quantityInput = document.getElementById('item-quantity');
    let value = parseInt(quantityInput.value);
    if (value > 1) {
        quantityInput.value = value - 1;
    }
});

document.getElementById('increase-quantity').addEventListener('click', function() {
    const quantityInput = document.getElementById('item-quantity');
    let value = parseInt(quantityInput.value);
    quantityInput.value = value + 1;
});

// カートに追加ボタンのイベント
document.getElementById('add-cart-btn').addEventListener('click', function() {
    addToCart();
});

// 数量入力のバリデーション
document.getElementById('item-quantity').addEventListener('input', function() {
    let value = parseInt(this.value);
    if (isNaN(value) || value < 1) {
        this.value = 1;
    } else if (value > 100) {
        this.value = 100;
    }
});

// ドキュメントの読み込み完了時
document.addEventListener('DOMContentLoaded', function() {
    // テーマカラーを初期設定
    document.documentElement.style.setProperty('--theme-color', 'rgba(200, 50, 50, 0.8)');
    document.documentElement.style.setProperty('--theme-color-hover', 'rgba(220, 70, 70, 0.8)');
});