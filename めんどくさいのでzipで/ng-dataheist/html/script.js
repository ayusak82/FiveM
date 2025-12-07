let hackingContainer = document.getElementById('hacking-container');
let wordContainer = document.getElementById('word-container');
let typingInput = document.getElementById('typing-input');
let timerValue = document.getElementById('timer-value');
let progressValue = document.getElementById('progress-value');
let progressFill = document.getElementById('progress-fill');
let resultMessage = document.getElementById('result-message');

let words = [];
let currentWordIndex = 0;
let timer = 0;
let timerInterval = null;
let hackingCompleted = false;
let difficulty = {
    wordCount: 5,
    wordLength: {min: 3, max: 6},
    timeLimit: 20
};

// タイピングゲームの初期化
function initHacking(config) {
    difficulty = config;
    words = generateRandomWords(difficulty.wordCount, difficulty.wordLength);
    currentWordIndex = 0;
    timer = difficulty.timeLimit;
    hackingCompleted = false;
    
    // 単語の表示
    displayWords();
    
    // タイマーの開始
    startTimer();
    
    // 入力フィールドをクリア
    typingInput.value = '';
    typingInput.focus();
    
    // 結果メッセージをクリア
    resultMessage.textContent = '';
    resultMessage.className = '';
    
    // 進行状況の更新
    updateProgress();
    
    // ハッキングコンテナを表示
    hackingContainer.classList.remove('hidden');
}

// ランダムな単語の生成
function generateRandomWords(count, lengthRange) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    const result = [];
    
    for (let i = 0; i < count; i++) {
        const length = Math.floor(Math.random() * (lengthRange.max - lengthRange.min + 1)) + lengthRange.min;
        let word = '';
        
        for (let j = 0; j < length; j++) {
            const randomIndex = Math.floor(Math.random() * chars.length);
            word += chars[randomIndex];
        }
        
        result.push(word);
    }
    
    return result;
}

// 単語の表示
function displayWords() {
    wordContainer.innerHTML = '';
    
    words.forEach((word, index) => {
        const wordElement = document.createElement('div');
        wordElement.classList.add('word');
        wordElement.textContent = word;
        
        if (index === currentWordIndex) {
            wordElement.classList.add('current');
        } else if (index < currentWordIndex) {
            wordElement.classList.add('completed');
        }
        
        wordContainer.appendChild(wordElement);
    });
}

// タイマーの開始
function startTimer() {
    if (timerInterval) {
        clearInterval(timerInterval);
    }
    
    timerValue.textContent = timer;
    
    timerInterval = setInterval(() => {
        timer--;
        timerValue.textContent = timer;
        
        if (timer <= 0) {
            clearInterval(timerInterval);
            gameOver(false);
        }
    }, 1000);
}

// 進行状況の更新
function updateProgress() {
    const progress = (currentWordIndex / words.length) * 100;
    progressValue.textContent = `${Math.floor(progress)}%`;
    progressFill.style.width = `${progress}%`;
}

// ゲーム終了
function gameOver(success) {
    clearInterval(timerInterval);
    hackingCompleted = true;
    
    if (success) {
        resultMessage.textContent = 'ハッキング成功！';
        resultMessage.className = 'success';
    } else {
        resultMessage.textContent = 'ハッキング失敗！';
        resultMessage.className = 'error';
    }
    
    setTimeout(() => {
        hackingContainer.classList.add('hidden');
        fetch('https://ng-dataheist/hackingResult', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                success: success
            })
        });
    }, 2000);
}

// コピー＆ペーストの防止
typingInput.addEventListener('paste', (e) => {
    e.preventDefault();
    return false;
});

typingInput.addEventListener('copy', (e) => {
    e.preventDefault();
    return false;
});

typingInput.addEventListener('cut', (e) => {
    e.preventDefault();
    return false;
});

// 入力イベントのハンドリング
typingInput.addEventListener('input', (e) => {
    if (hackingCompleted) return;
    
    const currentWord = words[currentWordIndex];
    const inputValue = e.target.value.trim();
    
    if (inputValue === currentWord) {
        currentWordIndex++;
        e.target.value = '';
        
        if (currentWordIndex >= words.length) {
            gameOver(true);
        } else {
            displayWords();
            updateProgress();
        }
    }
});

// ハッキングの開始メッセージを受信
window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (data.action === 'openHacking') {
        initHacking(data.difficulty);
    }
});

// キーイベントの処理（ESCでNUIを閉じる）
document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        hackingContainer.classList.add('hidden');
        fetch('https://ng-dataheist/hackingResult', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                success: false
            })
        });
    }
});