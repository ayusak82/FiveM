// 色合わせゲーム

let colorSequence = [];
let colorCurrentIndex = 0;
let colorCorrectClicks = 0;
let colorTotalClicks = 0;

const colors = [
    { name: 'red', hex: '#f44336' },
    { name: 'blue', hex: '#2196f3' },
    { name: 'green', hex: '#4caf50' },
    { name: 'yellow', hex: '#ffeb3b' },
    { name: 'purple', hex: '#9c27b0' },
    { name: 'orange', hex: '#ff9800' },
    { name: 'pink', hex: '#e91e63' },
    { name: 'cyan', hex: '#00bcd4' }
];

// 色合わせゲーム初期化
function initColorGame() {
    colorCurrentIndex = 0;
    colorCorrectClicks = 0;
    colorTotalClicks = 0;

    // ランダムな色のシーケンスを生成（8-12個）
    const sequenceLength = getRandomInt(8, 12);
    colorSequence = [];
    for (let i = 0; i < sequenceLength; i++) {
        colorSequence.push(colors[getRandomInt(0, colors.length - 1)]);
    }

    // グリッドを生成
    generateColorGrid();

    // 最初のターゲット色を表示
    updateColorTarget();

    // 進行度を更新
    updateColorProgress();
}

// グリッドを生成
function generateColorGrid() {
    const grid = document.getElementById('color-grid');
    grid.innerHTML = '';

    // ランダムな色のボックスを16個生成
    const gridColors = [];
    for (let i = 0; i < 16; i++) {
        gridColors.push(colors[getRandomInt(0, colors.length - 1)]);
    }

    gridColors.forEach((color, index) => {
        const box = document.createElement('div');
        box.className = 'color-box';
        box.style.backgroundColor = color.hex;
        box.dataset.colorName = color.name;
        box.addEventListener('click', () => handleColorClick(color, box));
        grid.appendChild(box);
    });
}

// ターゲット色を更新
function updateColorTarget() {
    if (colorCurrentIndex < colorSequence.length) {
        const targetColor = colorSequence[colorCurrentIndex];
        const display = document.getElementById('color-target');
        display.style.backgroundColor = targetColor.hex;
    }
}

// 進行度を更新
function updateColorProgress() {
    document.getElementById('color-progress').textContent = colorCurrentIndex;
    document.getElementById('color-total').textContent = colorSequence.length;
}

// クリック処理
function handleColorClick(clickedColor, boxElement) {
    colorTotalClicks++;
    const targetColor = colorSequence[colorCurrentIndex];

    if (clickedColor.name === targetColor.name) {
        // 正解
        colorCorrectClicks++;
        colorCurrentIndex++;

        // 視覚的フィードバック
        boxElement.classList.add('correct');
        setTimeout(() => {
            boxElement.classList.remove('correct');
        }, 300);

        // 進行度を更新
        updateColorProgress();

        // 次のターゲット
        if (colorCurrentIndex < colorSequence.length) {
            updateColorTarget();
            // 新しいグリッドを生成
            setTimeout(() => {
                generateColorGrid();
            }, 300);
        } else {
            // ゲーム完了
            completeColorGame();
        }
    } else {
        // 不正解
        boxElement.classList.add('wrong');
        setTimeout(() => {
            boxElement.classList.remove('wrong');
        }, 300);
    }
}

// ゲーム完了
function completeColorGame() {
    // スコア計算
    const accuracy = (colorCorrectClicks / colorTotalClicks) * 100;
    const timeBonus = (timeRemaining / gameData.timeLimit) * 30; // 残り時間ボーナス
    const score = Math.min(100, accuracy * 0.7 + timeBonus);

    setTimeout(() => {
        endGame(true, Math.round(score));
    }, 500);
}
