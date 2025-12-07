// DOM要素
const container = document.getElementById('lottery-container');
const startScreen = document.getElementById('startScreen');
const animationScreen = document.getElementById('animationScreen');
const resultScreen = document.getElementById('resultScreen');
const playBtn = document.getElementById('playBtn');
const closeBtn = document.getElementById('closeBtn');
const finishBtn = document.getElementById('finishBtn');
const continueBtn = document.getElementById('continueBtn');
const winAmountElement = document.getElementById('winAmount');
const ticketCountElement = document.getElementById('ticketCount');

let isProcessing = false;
let resourceName = 'ng-lottery';

// 初期化
window.addEventListener('DOMContentLoaded', () => {
    // リソース名を一度だけ取得
    if (window.GetParentResourceName) {
        resourceName = window.GetParentResourceName();
    }
});

// NUIメッセージ受信
window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (data.action === 'open') {
        openUI();
    } else if (data.action === 'close') {
        closeUI();
    } else if (data.action === 'showResult') {
        showResult(data.amount, data.hasMoreTickets, data.ticketCount);
    } else if (data.action === 'resetForContinue') {
        resetForContinue();
    }
});

// UI表示
function openUI() {
    container.classList.remove('hidden');
    resetScreens();
    showScreen('start');
}

// UI非表示
function closeUI() {
    container.classList.add('hidden');
    resetScreens();
    isProcessing = false;
    
    // FiveMに通知
    sendNUICallback('closeUI', {});
}

// NUIコールバック送信
function sendNUICallback(endpoint, data) {
    const xhr = new XMLHttpRequest();
    xhr.open('POST', `https://${resourceName}/${endpoint}`, true);
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.send(JSON.stringify(data));
}

// 画面切り替え
function showScreen(screenName) {
    // すべての画面を非表示
    startScreen.style.display = 'none';
    animationScreen.style.display = 'none';
    resultScreen.style.display = 'none';
    
    // 指定された画面を表示
    if (screenName === 'start') {
        startScreen.style.display = 'block';
        startScreen.classList.add('active');
    } else if (screenName === 'animation') {
        animationScreen.style.display = 'block';
        animationScreen.classList.add('active');
    } else if (screenName === 'result') {
        resultScreen.style.display = 'block';
        resultScreen.classList.add('active');
    }
}

// 画面リセット
function resetScreens() {
    showScreen('start');
    winAmountElement.textContent = '0';
    continueBtn.style.display = 'none';
}

// 結果表示
function showResult(amount, hasMoreTickets, ticketCount) {
    // 金額を即座に表示
    const winAmount = parseInt(amount) || 0;
    winAmountElement.textContent = winAmount.toLocaleString();
    
    // 続けて引くボタンの表示/非表示
    if (hasMoreTickets && ticketCount > 0) {
        continueBtn.style.display = 'inline-block';
        ticketCountElement.textContent = `(残り${ticketCount}枚)`;
    } else {
        continueBtn.style.display = 'none';
    }
    
    // 結果画面に切り替え
    setTimeout(() => {
        showScreen('result');
        isProcessing = false;
    }, 500);
}

// 続けて引くためのリセット
function resetForContinue() {
    isProcessing = false;
    showScreen('start');
}

// 宝くじを引く
playBtn.onclick = function() {
    if (isProcessing) return;
    
    isProcessing = true;
    showScreen('animation');
    
    // サーバーに通知
    sendNUICallback('startLottery', {});
};

// 続けて引く
continueBtn.onclick = function() {
    if (isProcessing) return;
    
    // 続けて引く処理
    sendNUICallback('continueDrawing', {});
};

// 閉じるボタン
closeBtn.onclick = function() {
    if (!isProcessing) {
        closeUI();
    }
};

// 完了ボタン
finishBtn.onclick = function() {
    closeUI();
};

// ESCキー
document.onkeyup = function(event) {
    if (event.key === 'Escape' && !isProcessing) {
        closeUI();
    }
};