// 現在の設定
let currentConfig = {
    jobColor: '#3498db',
    maxLength: 200
};

// 入力UIを開く
function openInput(data) {
    const container = document.getElementById('input-container');
    const inputIcon = document.getElementById('input-icon');
    const jobLabel = document.getElementById('job-label');
    const playerName = document.getElementById('player-name');
    const maxCountEl = document.getElementById('max-count');
    const textarea = document.getElementById('message-input');
    const jobInfo = document.querySelector('.job-info');
    
    // 設定を保存
    currentConfig.jobColor = data.jobColor || '#3498db';
    currentConfig.maxLength = data.maxLength || 200;
    
    // UIを更新
    inputIcon.className = data.jobIcon || 'fa-solid fa-bullhorn';
    inputIcon.style.color = currentConfig.jobColor;
    jobLabel.textContent = data.jobLabel || '一般';
    jobLabel.style.color = currentConfig.jobColor;
    playerName.textContent = data.playerName || 'プレイヤー';
    maxCountEl.textContent = currentConfig.maxLength;
    textarea.maxLength = currentConfig.maxLength;
    textarea.value = '';
    
    // 色変数を設定
    document.documentElement.style.setProperty('--job-color', currentConfig.jobColor);
    jobInfo.style.borderLeftColor = currentConfig.jobColor;
    
    // 文字数カウントリセット
    updateCharCount();
    
    // 表示
    container.classList.remove('hidden');
    textarea.focus();
}

// 入力UIを閉じる
function closeInput() {
    const container = document.getElementById('input-container');
    container.classList.add('hidden');
    
    // NUIに通知
    fetch('https://ng-announcement/close', {
        method: 'POST',
        body: JSON.stringify({})
    });
}

// 文字数カウント更新
function updateCharCount() {
    const textarea = document.getElementById('message-input');
    const currentCount = document.getElementById('current-count');
    const charCount = document.querySelector('.char-count');
    
    const count = textarea.value.length;
    currentCount.textContent = count;
    
    // 色を変更
    charCount.classList.remove('warning', 'danger');
    if (count >= currentConfig.maxLength) {
        charCount.classList.add('danger');
    } else if (count >= currentConfig.maxLength * 0.8) {
        charCount.classList.add('warning');
    }
}

// お知らせ送信
function submitAnnouncement() {
    const textarea = document.getElementById('message-input');
    const message = textarea.value.trim();
    
    if (!message) {
        return;
    }
    
    // NUIに送信
    fetch('https://ng-announcement/submit', {
        method: 'POST',
        body: JSON.stringify({ message: message })
    });
}

// お知らせを表示
function showAnnouncement(data) {
    const container = document.getElementById('announcement-container');
    
    // 要素を作成
    const announcement = document.createElement('div');
    announcement.className = 'announcement';
    announcement.style.setProperty('--job-color', data.jobColor || '#3498db');
    announcement.style.setProperty('--duration', (data.duration || 15000) + 'ms');
    
    // 現在時刻
    const now = new Date();
    const timeStr = now.getHours().toString().padStart(2, '0') + ':' + 
                   now.getMinutes().toString().padStart(2, '0');
    
    announcement.innerHTML = `
        <div class="announcement-header">
            <i class="${data.jobIcon || 'fa-solid fa-bullhorn'}"></i>
            <span class="job-title">${data.jobLabel || '一般'}の${data.playerName || 'プレイヤー'}からのお知らせ</span>
        </div>
        <div class="announcement-body">
            <p class="message">${escapeHtml(data.message || '')}</p>
        </div>
        <div class="announcement-footer">
            <div class="progress-bar">
                <div class="progress"></div>
            </div>
            <span class="time">${timeStr}</span>
        </div>
    `;
    
    // 効果音を再生
    playNotificationSound();
    
    // 追加
    container.appendChild(announcement);
    
    // 自動削除
    const duration = data.duration || 15000;
    setTimeout(() => {
        announcement.classList.add('hiding');
        setTimeout(() => {
            if (announcement.parentNode) {
                announcement.parentNode.removeChild(announcement);
            }
        }, 400);
    }, duration);
}

// 効果音再生
function playNotificationSound() {
    const sound = document.getElementById('notification-sound');
    if (sound) {
        sound.currentTime = 0;
        sound.volume = 0.1;
        sound.play().catch(() => {
            // 自動再生がブロックされた場合は無視
        });
    }
}

// HTMLエスケープ
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// NUIメッセージリスナー
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch (data.action) {
        case 'openInput':
            openInput(data);
            break;
            
        case 'closeInput':
            document.getElementById('input-container').classList.add('hidden');
            break;
            
        case 'showAnnouncement':
            showAnnouncement(data);
            break;
    }
});

// キーボードイベント
document.addEventListener('keydown', function(event) {
    const container = document.getElementById('input-container');
    
    if (container.classList.contains('hidden')) return;
    
    // ESCで閉じる
    if (event.key === 'Escape') {
        closeInput();
    }
    
    // Ctrl+Enterで送信
    if (event.key === 'Enter' && event.ctrlKey) {
        submitAnnouncement();
    }
});

// テキストエリアの入力監視
document.getElementById('message-input').addEventListener('input', updateCharCount);
