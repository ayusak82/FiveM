// レースゲーム

let racingPlayerX = 50; // パーセント
let racingObstacles = [];
let racingDistance = 0;
let racingScore = 0;
let racingSpeed = 2;
let racingInterval = null;
let racingKeyListener = null;
let racingGameOver = false;

const RACING_LANES = [25, 50, 75]; // 3つのレーン（パーセント）
const RACING_PLAYER_SPEED = 15; // 移動速度

// レースゲーム初期化
function initRacingGame() {
    racingPlayerX = 50;
    racingObstacles = [];
    racingDistance = 0;
    racingScore = 0;
    racingSpeed = 2;
    racingGameOver = false;

    // スコアと距離を表示
    document.getElementById('racing-distance').textContent = '0';
    document.getElementById('racing-score').textContent = '0';

    // プレイヤーを配置
    const player = document.getElementById('racing-player');
    player.style.left = racingPlayerX + '%';

    // 障害物コンテナをクリア
    document.getElementById('racing-obstacles').innerHTML = '';

    // キーリスナーを追加
    racingKeyListener = handleRacingKey.bind(this);
    document.addEventListener('keydown', racingKeyListener);

    // ゲームループ開始
    startRacingGameLoop();
}

// ゲームループ開始
function startRacingGameLoop() {
    let lastObstacleTime = Date.now();
    let lastSpeedIncrease = Date.now();

    racingInterval = setInterval(() => {
        if (racingGameOver) return;

        const currentTime = Date.now();

        // 障害物を生成（1-2秒ごと）
        if (currentTime - lastObstacleTime > getRandomInt(1000, 2000)) {
            createRacingObstacle();
            lastObstacleTime = currentTime;
        }

        // 速度を徐々に上げる（5秒ごと）
        if (currentTime - lastSpeedIncrease > 5000) {
            racingSpeed += 0.5;
            lastSpeedIncrease = currentTime;
        }

        // 障害物を移動
        updateRacingObstacles();

        // 距離とスコアを更新
        racingDistance += racingSpeed;
        racingScore = Math.floor(racingDistance / 10);
        document.getElementById('racing-distance').textContent = Math.floor(racingDistance);
        document.getElementById('racing-score').textContent = racingScore;

        // 衝突判定
        checkRacingCollision();
    }, 50);
}

// 障害物を生成
function createRacingObstacle() {
    const lane = RACING_LANES[getRandomInt(0, RACING_LANES.length - 1)];
    const obstacle = document.createElement('div');
    obstacle.className = 'racing-obstacle';
    obstacle.style.left = lane + '%';
    obstacle.style.top = '-50px';
    obstacle.style.transform = 'translateX(-50%)';

    const obstacleData = {
        element: obstacle,
        x: lane,
        y: -50
    };

    racingObstacles.push(obstacleData);
    document.getElementById('racing-obstacles').appendChild(obstacle);
}

// 障害物を更新
function updateRacingObstacles() {
    racingObstacles.forEach((obstacle, index) => {
        obstacle.y += racingSpeed;
        obstacle.element.style.top = obstacle.y + 'px';

        // 画面外に出たら削除
        if (obstacle.y > 450) {
            obstacle.element.remove();
            racingObstacles.splice(index, 1);
        }
    });
}

// 衝突判定
function checkRacingCollision() {
    const playerElement = document.getElementById('racing-player');
    const playerRect = playerElement.getBoundingClientRect();

    racingObstacles.forEach(obstacle => {
        const obstacleRect = obstacle.element.getBoundingClientRect();

        // 簡易的な衝突判定
        if (
            playerRect.left < obstacleRect.right &&
            playerRect.right > obstacleRect.left &&
            playerRect.top < obstacleRect.bottom &&
            playerRect.bottom > obstacleRect.top
        ) {
            // 衝突！
            gameOverRacing();
        }
    });
}

// キー入力処理
function handleRacingKey(event) {
    if (racingGameOver) return;

    const player = document.getElementById('racing-player');

    switch(event.key) {
        case 'ArrowLeft':
            event.preventDefault();
            // 左のレーンに移動
            const currentIndex = RACING_LANES.indexOf(racingPlayerX);
            if (currentIndex > 0) {
                racingPlayerX = RACING_LANES[currentIndex - 1];
                player.style.left = racingPlayerX + '%';
            }
            break;
        case 'ArrowRight':
            event.preventDefault();
            // 右のレーンに移動
            const currentIndexRight = RACING_LANES.indexOf(racingPlayerX);
            if (currentIndexRight < RACING_LANES.length - 1) {
                racingPlayerX = RACING_LANES[currentIndexRight + 1];
                player.style.left = racingPlayerX + '%';
            }
            break;
    }
}

// ゲームオーバー
function gameOverRacing() {
    racingGameOver = true;
    cleanupRacingGame();

    // スコア計算（距離に基づく）
    const maxDistance = 1000; // 最大距離の目安
    const score = Math.min(100, (racingDistance / maxDistance) * 100);

    setTimeout(() => {
        endGame(true, Math.round(score));
    }, 500);
}

// クリーンアップ
function cleanupRacingGame() {
    if (racingInterval) {
        clearInterval(racingInterval);
        racingInterval = null;
    }

    if (racingKeyListener) {
        document.removeEventListener('keydown', racingKeyListener);
        racingKeyListener = null;
    }

    // 全障害物を削除
    racingObstacles.forEach(obstacle => {
        if (obstacle.element && obstacle.element.parentNode) {
            obstacle.element.remove();
        }
    });
    racingObstacles = [];
}
