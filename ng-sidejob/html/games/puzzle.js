// パズルゲーム（テトリス風）

let puzzleBoard = [];
let puzzleCurrentPiece = null;
let puzzleCurrentX = 0;
let puzzleCurrentY = 0;
let puzzleScore = 0;
let puzzleLines = 0;
let puzzleInterval = null;
let puzzleKeyListener = null;

const BOARD_WIDTH = 10;
const BOARD_HEIGHT = 20;

// テトリミノの形状
const PIECES = [
    [[1, 1, 1, 1]], // I
    [[1, 1], [1, 1]], // O
    [[1, 1, 1], [0, 1, 0]], // T
    [[1, 1, 1], [1, 0, 0]], // L
    [[1, 1, 1], [0, 0, 1]], // J
    [[1, 1, 0], [0, 1, 1]], // S
    [[0, 1, 1], [1, 1, 0]]  // Z
];

// パズルゲーム初期化
function initPuzzleGame() {
    puzzleScore = 0;
    puzzleLines = 0;

    // ボードを初期化
    puzzleBoard = Array(BOARD_HEIGHT).fill(null).map(() => Array(BOARD_WIDTH).fill(0));

    // スコアとラインを表示
    document.getElementById('puzzle-score').textContent = '0';
    document.getElementById('puzzle-lines').textContent = '0';

    // ボードを描画
    renderPuzzleBoard();

    // 最初のピースを生成
    spawnNewPiece();

    // キーリスナーを追加
    puzzleKeyListener = handlePuzzleKey.bind(this);
    document.addEventListener('keydown', puzzleKeyListener);

    // 自動落下開始
    startPuzzleAutoFall();
}

// ボードを描画
function renderPuzzleBoard() {
    const boardElement = document.getElementById('puzzle-board');
    boardElement.innerHTML = '';

    for (let y = 0; y < BOARD_HEIGHT; y++) {
        for (let x = 0; x < BOARD_WIDTH; x++) {
            const cell = document.createElement('div');
            cell.className = 'puzzle-cell';
            cell.dataset.x = x;
            cell.dataset.y = y;

            if (puzzleBoard[y][x] === 1) {
                cell.classList.add('filled');
            }

            boardElement.appendChild(cell);
        }
    }

    // 現在のピースを描画
    if (puzzleCurrentPiece) {
        drawCurrentPiece();
    }
}

// 現在のピースを描画
function drawCurrentPiece() {
    const piece = puzzleCurrentPiece;
    for (let y = 0; y < piece.length; y++) {
        for (let x = 0; x < piece[y].length; x++) {
            if (piece[y][x] === 1) {
                const boardX = puzzleCurrentX + x;
                const boardY = puzzleCurrentY + y;
                if (boardY >= 0 && boardY < BOARD_HEIGHT && boardX >= 0 && boardX < BOARD_WIDTH) {
                    const cell = document.querySelector(`[data-x="${boardX}"][data-y="${boardY}"]`);
                    if (cell) {
                        cell.classList.add('active');
                    }
                }
            }
        }
    }
}

// 新しいピースを生成
function spawnNewPiece() {
    puzzleCurrentPiece = PIECES[getRandomInt(0, PIECES.length - 1)];
    puzzleCurrentX = Math.floor(BOARD_WIDTH / 2) - Math.floor(puzzleCurrentPiece[0].length / 2);
    puzzleCurrentY = 0;

    // 配置できるかチェック
    if (!canPlacePiece(puzzleCurrentX, puzzleCurrentY, puzzleCurrentPiece)) {
        // ゲームオーバー
        endPuzzleGame();
        return;
    }

    renderPuzzleBoard();
}

// ピースを配置できるかチェック
function canPlacePiece(x, y, piece) {
    for (let py = 0; py < piece.length; py++) {
        for (let px = 0; px < piece[py].length; px++) {
            if (piece[py][px] === 1) {
                const boardX = x + px;
                const boardY = y + py;

                if (boardX < 0 || boardX >= BOARD_WIDTH || boardY >= BOARD_HEIGHT) {
                    return false;
                }

                if (boardY >= 0 && puzzleBoard[boardY][boardX] === 1) {
                    return false;
                }
            }
        }
    }
    return true;
}

// ピースを固定
function lockPiece() {
    const piece = puzzleCurrentPiece;
    for (let y = 0; y < piece.length; y++) {
        for (let x = 0; x < piece[y].length; x++) {
            if (piece[y][x] === 1) {
                const boardY = puzzleCurrentY + y;
                const boardX = puzzleCurrentX + x;
                if (boardY >= 0 && boardY < BOARD_HEIGHT) {
                    puzzleBoard[boardY][boardX] = 1;
                }
            }
        }
    }

    // ラインをチェック
    checkLines();

    // 新しいピースを生成
    spawnNewPiece();
}

// ラインをチェック
function checkLines() {
    let linesCleared = 0;

    for (let y = BOARD_HEIGHT - 1; y >= 0; y--) {
        if (puzzleBoard[y].every(cell => cell === 1)) {
            // ラインを削除
            puzzleBoard.splice(y, 1);
            puzzleBoard.unshift(Array(BOARD_WIDTH).fill(0));
            linesCleared++;
            y++; // 同じ行を再チェック
        }
    }

    if (linesCleared > 0) {
        puzzleLines += linesCleared;
        puzzleScore += linesCleared * 100 * linesCleared; // コンボボーナス

        document.getElementById('puzzle-lines').textContent = puzzleLines;
        document.getElementById('puzzle-score').textContent = puzzleScore;
    }
}

// 自動落下開始
function startPuzzleAutoFall() {
    puzzleInterval = setInterval(() => {
        movePieceDown();
    }, 1000);
}

// ピースを下に移動
function movePieceDown() {
    if (canPlacePiece(puzzleCurrentX, puzzleCurrentY + 1, puzzleCurrentPiece)) {
        puzzleCurrentY++;
        renderPuzzleBoard();
    } else {
        lockPiece();
    }
}

// ピースを回転
function rotatePiece() {
    const rotated = puzzleCurrentPiece[0].map((_, i) =>
        puzzleCurrentPiece.map(row => row[i]).reverse()
    );

    if (canPlacePiece(puzzleCurrentX, puzzleCurrentY, rotated)) {
        puzzleCurrentPiece = rotated;
        renderPuzzleBoard();
    }
}

// キー入力処理
function handlePuzzleKey(event) {
    if (!puzzleCurrentPiece) return;

    switch(event.key) {
        case 'ArrowLeft':
            event.preventDefault();
            if (canPlacePiece(puzzleCurrentX - 1, puzzleCurrentY, puzzleCurrentPiece)) {
                puzzleCurrentX--;
                renderPuzzleBoard();
            }
            break;
        case 'ArrowRight':
            event.preventDefault();
            if (canPlacePiece(puzzleCurrentX + 1, puzzleCurrentY, puzzleCurrentPiece)) {
                puzzleCurrentX++;
                renderPuzzleBoard();
            }
            break;
        case 'ArrowDown':
            event.preventDefault();
            movePieceDown();
            break;
        case 'ArrowUp':
            event.preventDefault();
            rotatePiece();
            break;
    }
}

// ゲーム終了
function endPuzzleGame() {
    cleanupPuzzleGame();

    // スコア計算（ライン数とスコアに基づく）
    const lineScore = Math.min(50, puzzleLines * 5);
    const pointScore = Math.min(50, puzzleScore / 100);
    const finalScore = Math.round(lineScore + pointScore);

    setTimeout(() => {
        endGame(true, finalScore);
    }, 500);
}

// クリーンアップ
function cleanupPuzzleGame() {
    if (puzzleInterval) {
        clearInterval(puzzleInterval);
        puzzleInterval = null;
    }

    if (puzzleKeyListener) {
        document.removeEventListener('keydown', puzzleKeyListener);
        puzzleKeyListener = null;
    }
}
