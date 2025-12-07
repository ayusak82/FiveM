// タイピングゲーム

let typingTarget = '';
let typingCorrectChars = 0;
let typingTotalChars = 0;

// タイピングゲーム初期化
function initTypingGame() {
    // ランダムな文字列を生成
    typingTarget = generateRandomString(getRandomInt(15, 25));
    typingCorrectChars = 0;
    typingTotalChars = 0;

    // 表示
    document.getElementById('typing-target').textContent = typingTarget;
    document.getElementById('typing-accuracy').textContent = '100';

    // 入力フィールドをクリア
    const input = document.getElementById('typing-input');
    input.value = '';
    input.focus();

    // イベントリスナー
    input.addEventListener('input', handleTypingInput);
}

// ランダム文字列生成
function generateRandomString(length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
        result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
}

// 入力処理
function handleTypingInput(event) {
    const input = event.target.value.toUpperCase();
    typingTotalChars = input.length;

    // 正確性チェック
    typingCorrectChars = 0;
    for (let i = 0; i < input.length; i++) {
        if (i < typingTarget.length && input[i] === typingTarget[i]) {
            typingCorrectChars++;
        }
    }

    // 正確性を表示
    const accuracy = typingTotalChars > 0 
        ? Math.round((typingCorrectChars / typingTotalChars) * 100) 
        : 100;
    document.getElementById('typing-accuracy').textContent = accuracy;

    // 完了チェック
    if (input === typingTarget) {
        // スコア計算（正確性とスピード）
        const timeUsed = gameData.timeLimit - timeRemaining;
        const speedBonus = Math.max(0, 50 - timeUsed * 2); // 速いほどボーナス
        const score = Math.min(100, accuracy * 0.7 + speedBonus);

        // 入力を無効化
        event.target.removeEventListener('input', handleTypingInput);
        event.target.disabled = true;

        // 少し待ってから終了
        setTimeout(() => {
            endGame(true, Math.round(score));
        }, 500);
    }
}
