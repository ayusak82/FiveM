// 記憶ゲーム

let memoryItems = [];
let memorySelectedItems = [];
let memoryCorrectCount = 0;
let memoryPhase = 'memorize'; // 'memorize' or 'recall'

const itemEmojis = [
    '🍎', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🍒',
    '🥕', '🌽', '🥦', '🍅', '🥔', '🧅', '🥒', '🌶️',
    '🔧', '🔨', '⚙️', '🔩', '⚡', '🔋', '💡', '🔌',
    '📦', '📋', '📌', '📎', '✂️', '📏', '📐', '🖊️'
];

// 記憶ゲーム初期化
function initMemoryGame() {
    memorySelectedItems = [];
    memoryCorrectCount = 0;
    memoryPhase = 'memorize';

    // ランダムなアイテムを選択（6-8個）
    const itemCount = getRandomInt(6, 8);
    memoryItems = shuffleArray(itemEmojis).slice(0, itemCount);

    // 表示エリアをクリア
    const display = document.getElementById('memory-display');
    display.innerHTML = '';

    // アイテムを表示
    memoryItems.forEach(item => {
        const itemDiv = document.createElement('div');
        itemDiv.className = 'memory-item';
        itemDiv.textContent = item;
        display.appendChild(itemDiv);
    });

    // 指示を更新
    document.getElementById('memory-instruction').textContent = 
        `これらのアイテムを記憶してください（${Math.min(5, timeRemaining)}秒）`;

    // 選択肢を非表示
    document.getElementById('memory-choices').classList.add('hidden');

    // スコアをリセット
    document.getElementById('memory-score').textContent = '0';

    // 5秒後に記憶フェーズ終了
    setTimeout(() => {
        startRecallPhase();
    }, Math.min(5000, timeRemaining * 1000));
}

// 思い出しフェーズ開始
function startRecallPhase() {
    memoryPhase = 'recall';

    // アイテムを非表示
    const display = document.getElementById('memory-display');
    display.innerHTML = '';

    // 指示を更新
    document.getElementById('memory-instruction').textContent = 
        '表示されていたアイテムを選択してください';

    // 選択肢を生成
    generateMemoryChoices();

    // 選択肢を表示
    document.getElementById('memory-choices').classList.remove('hidden');
}

// 選択肢を生成
function generateMemoryChoices() {
    const choicesContainer = document.getElementById('memory-choices');
    choicesContainer.innerHTML = '';

    // 正解のアイテム + ダミーアイテム
    const dummyCount = 8 - memoryItems.length;
    const dummyItems = shuffleArray(
        itemEmojis.filter(item => !memoryItems.includes(item))
    ).slice(0, dummyCount);

    const allChoices = shuffleArray([...memoryItems, ...dummyItems]);

    allChoices.forEach(item => {
        const choiceDiv = document.createElement('div');
        choiceDiv.className = 'memory-choice';
        choiceDiv.textContent = item;
        choiceDiv.dataset.item = item;
        choiceDiv.addEventListener('click', () => handleMemoryChoice(item, choiceDiv));
        choicesContainer.appendChild(choiceDiv);
    });
}

// 選択処理
function handleMemoryChoice(item, choiceElement) {
    // 既に選択済みの場合は解除
    if (memorySelectedItems.includes(item)) {
        memorySelectedItems = memorySelectedItems.filter(i => i !== item);
        choiceElement.classList.remove('selected');
        return;
    }

    // 選択
    memorySelectedItems.push(item);
    choiceElement.classList.add('selected');

    // 全て選択したかチェック
    if (memorySelectedItems.length === memoryItems.length) {
        completeMemoryGame();
    }
}

// ゲーム完了
function completeMemoryGame() {
    // 正解数をカウント
    memoryCorrectCount = 0;
    memorySelectedItems.forEach(item => {
        if (memoryItems.includes(item)) {
            memoryCorrectCount++;
        }
    });

    // スコアを表示
    document.getElementById('memory-score').textContent = 
        `${memoryCorrectCount} / ${memoryItems.length}`;

    // スコア計算
    const accuracy = (memoryCorrectCount / memoryItems.length) * 100;
    const timeBonus = (timeRemaining / gameData.timeLimit) * 20;
    const score = Math.min(100, accuracy * 0.8 + timeBonus);

    // 少し待ってから終了
    setTimeout(() => {
        endGame(true, Math.round(score));
    }, 1500);
}
