// リズムゲーム

let rhythmNotes = [];
let rhythmScore = 0;
let rhythmCombo = 0;
let rhythmInterval = null;
let rhythmKeyListener = null;

// リズムゲーム初期化
function initRhythmGame() {
    rhythmScore = 0;
    rhythmCombo = 0;
    rhythmNotes = [];

    // スコアとコンボを表示
    document.getElementById('rhythm-score').textContent = '0';
    document.getElementById('rhythm-combo').textContent = '0';

    // ノートコンテナをクリア
    document.getElementById('rhythm-notes').innerHTML = '';

    // キーリスナーを追加
    rhythmKeyListener = handleRhythmKey.bind(this);
    document.addEventListener('keydown', rhythmKeyListener);

    // ノートを生成開始
    startGeneratingNotes();
}

// ノート生成開始
function startGeneratingNotes() {
    let noteCount = 0;
    const maxNotes = 20; // 最大ノート数

    rhythmInterval = setInterval(() => {
        if (noteCount >= maxNotes || timeRemaining <= 0) {
            clearInterval(rhythmInterval);
            return;
        }

        createNote();
        noteCount++;
    }, 1500); // 1.5秒ごとにノート生成
}

// ノートを作成
function createNote() {
    const notesContainer = document.getElementById('rhythm-notes');
    const note = document.createElement('div');
    note.className = 'rhythm-note';
    note.style.top = '0px';
    
    const noteData = {
        element: note,
        startTime: Date.now(),
        hit: false
    };
    
    rhythmNotes.push(noteData);
    notesContainer.appendChild(note);

    // ノートを下に移動
    animateNote(noteData);
}

// ノートをアニメーション
function animateNote(noteData) {
    const duration = 3000; // 3秒で下まで移動
    const startTime = noteData.startTime;
    const targetPosition = 220; // ターゲットの位置（bottom: 20px + 80px target height = 100px from bottom, so 300 - 80 = 220）

    function animate() {
        if (noteData.hit) return;

        const elapsed = Date.now() - startTime;
        const progress = Math.min(elapsed / duration, 1);
        const currentTop = progress * targetPosition;

        noteData.element.style.top = currentTop + 'px';

        if (progress < 1) {
            requestAnimationFrame(animate);
        } else {
            // ノートがターゲットを通過（ミス）
            if (!noteData.hit) {
                missNote(noteData);
            }
        }
    }

    animate();
}

// キー入力処理
function handleRhythmKey(event) {
    if (event.code === 'Space') {
        event.preventDefault();
        checkNoteHit();
    }
}

// ノートヒット判定
function checkNoteHit() {
    // 最も古いノートをチェック
    const activeNotes = rhythmNotes.filter(n => !n.hit);
    if (activeNotes.length === 0) return;

    const note = activeNotes[0];
    const elapsed = Date.now() - note.startTime;
    const targetTime = 2500; // ターゲットに到達する時間（3000msの約83%）

    // タイミング判定（±300ms）
    const timingDiff = Math.abs(elapsed - targetTime);

    if (timingDiff < 300) {
        // ヒット成功
        hitNote(note, timingDiff);
    } else if (elapsed > targetTime + 300) {
        // 遅すぎる（ミス）
        missNote(note);
    }
    // 早すぎる場合は何もしない
}

// ノートヒット成功
function hitNote(noteData, timingDiff) {
    noteData.hit = true;
    noteData.element.remove();

    // スコア計算（タイミングが良いほど高得点）
    let points = 100;
    if (timingDiff < 100) {
        points = 150; // Perfect
    } else if (timingDiff < 200) {
        points = 120; // Great
    }

    rhythmScore += points;
    rhythmCombo++;

    // コンボボーナス
    if (rhythmCombo > 5) {
        rhythmScore += rhythmCombo * 10;
    }

    // 表示更新
    document.getElementById('rhythm-score').textContent = rhythmScore;
    document.getElementById('rhythm-combo').textContent = rhythmCombo;

    // 配列から削除
    const index = rhythmNotes.indexOf(noteData);
    if (index > -1) {
        rhythmNotes.splice(index, 1);
    }
}

// ノートミス
function missNote(noteData) {
    noteData.hit = true;
    noteData.element.remove();

    // コンボリセット
    rhythmCombo = 0;
    document.getElementById('rhythm-combo').textContent = '0';

    // 配列から削除
    const index = rhythmNotes.indexOf(noteData);
    if (index > -1) {
        rhythmNotes.splice(index, 1);
    }
}

// クリーンアップ
function cleanupRhythmGame() {
    if (rhythmInterval) {
        clearInterval(rhythmInterval);
        rhythmInterval = null;
    }

    if (rhythmKeyListener) {
        document.removeEventListener('keydown', rhythmKeyListener);
        rhythmKeyListener = null;
    }

    // 全ノートを削除
    rhythmNotes.forEach(note => {
        if (note.element && note.element.parentNode) {
            note.element.remove();
        }
    });
    rhythmNotes = [];
}

// ゲーム終了時のスコア計算
// この関数はscript.jsのendGame前に呼ばれる想定
function getRhythmGameScore() {
    // 最大スコアを計算（20ノート × 150点 + コンボボーナス）
    const maxPossibleScore = 20 * 150 + 500; // 概算
    const score = Math.min(100, (rhythmScore / maxPossibleScore) * 100);
    return Math.round(score);
}
