// グローバル変数
let currentGame = null;
let gameData = null;
let timerInterval = null;
let timeRemaining = 0;

// NUIメッセージリスナー
window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.action) {
        case 'startGame':
            startGame(data.gameType, data.gameData);
            break;
        case 'forceClose':
            closeGame(false);
            break;
    }
});

// ゲーム開始
function startGame(gameType, data) {
    currentGame = gameType;
    gameData = data;
    timeRemaining = data.timeLimit;

    // コンテナを表示
    document.getElementById('container').classList.remove('hidden');

    // タイトル設定
    document.getElementById('game-title').textContent = data.name;

    // 全ゲームを非表示
    document.querySelectorAll('.game').forEach(game => {
        game.classList.add('hidden');
    });

    // 該当ゲームを表示
    const gameElement = document.getElementById(`${gameType}-game`);
    if (gameElement) {
        gameElement.classList.remove('hidden');
    }

    // タイマー開始
    startTimer();

    // ゲーム初期化
    switch(gameType) {
        case 'typing':
            initTypingGame();
            break;
        case 'color':
            initColorGame();
            break;
        case 'memory':
            initMemoryGame();
            break;
        case 'rhythm':
            initRhythmGame();
            break;
        case 'puzzle':
            initPuzzleGame();
            break;
        case 'racing':
            initRacingGame();
            break;
    }
}

// タイマー開始
function startTimer() {
    updateTimerDisplay();
    
    timerInterval = setInterval(() => {
        timeRemaining--;
        updateTimerDisplay();

        if (timeRemaining <= 0) {
            endGame(false);
        }
    }, 1000);
}

// タイマー表示更新
function updateTimerDisplay() {
    const minutes = Math.floor(timeRemaining / 60);
    const seconds = timeRemaining % 60;
    document.getElementById('timer').textContent = 
        `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
}

// ゲーム終了
function endGame(success, score = 0) {
    // タイマー停止
    if (timerInterval) {
        clearInterval(timerInterval);
        timerInterval = null;
    }

    // 結果を送信
    fetch(`https://${GetParentResourceName()}/gameResult`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            success: success,
            gameType: currentGame,
            score: score
        })
    });

    // UI閉じる
    closeGame(success);
}

// ゲームを閉じる
function closeGame(success) {
    document.getElementById('container').classList.add('hidden');

    // 入力フィールドをクリア
    const inputs = document.querySelectorAll('input');
    inputs.forEach(input => {
        input.value = '';
        input.blur();
    });

    // ゲーム固有のクリーンアップ
    if (currentGame) {
        switch(currentGame) {
            case 'rhythm':
                cleanupRhythmGame();
                break;
            case 'puzzle':
                cleanupPuzzleGame();
                break;
            case 'racing':
                cleanupRacingGame();
                break;
        }
    }

    currentGame = null;
    gameData = null;

    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

// 中止ボタン
document.getElementById('quit-btn').addEventListener('click', function() {
    endGame(false, 0);
});

// ESCキーで閉じる
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        endGame(false, 0);
    }
});

// リソース名取得
function GetParentResourceName() {
    return 'ng-sidejob';
}

// ユーティリティ関数
function getRandomInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

function shuffleArray(array) {
    const newArray = [...array];
    for (let i = newArray.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [newArray[i], newArray[j]] = [newArray[j], newArray[i]];
    }
    return newArray;
}
