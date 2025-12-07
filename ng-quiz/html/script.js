// グローバル変数
let currentQuizData = null;
let currentQuestion = null;

/* デバッグ用ログ関数
function debugLog(message) {
    console.log(`[ng-quiz HTML] ${message}`);
}
*/

// NUIメッセージリスナー
window.addEventListener('message', function(event) {
    const data = event.data;
    //debugLog(`メッセージ受信: ${data.action}`);
    
    switch(data.action) {
        case 'showQuizSelector':
            showQuizSelector(data.quizzes, data.ui);
            break;
        case 'showQuestion':
            showQuestion(data.question, data.questionNumber, data.totalQuestions, data.quizName);
            break;
        case 'showResult':
            showResult(data.isCorrect, data.correctAnswer, data.userAnswer);
            break;
        case 'showFinalResult':
            showFinalResult(data.success, data.correctAnswers, data.totalQuestions, data.quizName, data.reward);
            break;
        case 'hideUI':
            hideAllScreens();
            break;
    }
});

// クイズ選択画面を表示
function showQuizSelector(quizzes, ui) {
    //debugLog('クイズ選択画面を表示');
    hideAllScreens();
    
    // タイトルと説明を設定
    document.getElementById('selectorTitle').textContent = ui.title;
    document.getElementById('selectorDescription').textContent = ui.description;
    
    // クイズリストを生成
    const quizList = document.getElementById('quizList');
    quizList.innerHTML = '';
    
    quizzes.forEach(quiz => {
        const quizItem = document.createElement('div');
        quizItem.className = 'quiz-item';
        
        // クリックイベントを追加
        quizItem.addEventListener('click', function() {
            //debugLog(`クイズ選択: ${quiz.id}`);
            selectQuiz(quiz.id);
        });
        
        quizItem.innerHTML = `
            <div class="quiz-item-header">
                <span class="quiz-icon">${quiz.icon}</span>
                <h4>${quiz.name}</h4>
                <span class="quiz-difficulty">${quiz.difficulty}</span>
            </div>
            <p>${quiz.description}</p>
            <p style="margin-top: 10px; font-size: 12px; opacity: 0.8;">
                問題数: ${quiz.questions.length}問
            </p>
        `;
        
        quizList.appendChild(quizItem);
    });
    
    document.getElementById('quizSelector').classList.remove('hidden');
}

// クイズを選択
function selectQuiz(quizId) {
    //debugLog(`selectQuiz関数実行: ${quizId}`);
    
    // FiveMのNUIコールバックを送信（常に送信）
    fetch(`https://ng-quiz/selectQuiz`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ quizId: quizId })
    }).then(response => {
        //debugLog('selectQuiz送信完了');
        return response.text();
    }).then(data => {
        //debugLog('selectQuiz応答: ' + data);
    }).catch(error => {
        //debugLog('selectQuizエラー: ' + error);
    });
}

// 問題を表示
function showQuestion(question, questionNumber, totalQuestions, quizName) {
    //debugLog(`問題表示: ${questionNumber}/${totalQuestions}`);
    hideAllScreens();
    
    currentQuestion = question;
    
    // クイズ情報を設定
    document.getElementById('quizName').textContent = quizName;
    document.getElementById('questionProgress').textContent = `問題 ${questionNumber}/${totalQuestions}`;
    document.getElementById('questionText').textContent = question.question;
    
    // 選択肢を生成
    const optionsList = document.getElementById('optionsList');
    optionsList.innerHTML = '';
    
    question.options.forEach(option => {
        const optionItem = document.createElement('div');
        optionItem.className = 'option-item';
        
        // クリックイベントを追加
        optionItem.addEventListener('click', function() {
            //debugLog(`回答選択: ${option.value}`);
            answerQuestion(option.value);
        });
        
        optionItem.textContent = option.label;
        optionsList.appendChild(optionItem);
    });
    
    document.getElementById('quizScreen').classList.remove('hidden');
}

// 回答を送信
function answerQuestion(answer) {
    //debugLog(`answerQuestion関数実行: ${answer}`);
    
    // 選択肢をクリック不可にする
    const options = document.querySelectorAll('.option-item');
    options.forEach(option => {
        option.style.pointerEvents = 'none';
        option.style.opacity = '0.6';
    });
    
    // FiveMのNUIコールバックを送信（常に送信）
    fetch(`https://ng-quiz/answerQuestion`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ answer: answer })
    }).then(response => {
        //debugLog('answerQuestion送信完了');
        return response.text();
    }).then(data => {
        //debugLog('answerQuestion応答: ' + data);
    }).catch(error => {
        //debugLog('answerQuestionエラー: ' + error);
    });
}

// 回答結果を表示
function showResult(isCorrect, correctAnswer, userAnswer) {
    //debugLog(`結果表示: ${isCorrect ? '正解' : '不正解'}`);
    hideAllScreens();
    
    const resultContent = document.getElementById('resultContent');
    const resultIcon = isCorrect ? 
        '<div class="result-icon result-correct"><i class="fas fa-check-circle"></i></div>' :
        '<div class="result-icon result-incorrect"><i class="fas fa-times-circle"></i></div>';
    
    const resultText = isCorrect ? '正解です！' : '不正解です...';
    const resultClass = isCorrect ? 'result-correct' : 'result-incorrect';
    
    resultContent.innerHTML = `
        ${resultIcon}
        <div class="result-text ${resultClass}">${resultText}</div>
        <div class="answer-info">
            <p><strong>あなたの回答:</strong> ${userAnswer}</p>
            <p><strong>正解:</strong> ${correctAnswer}</p>
        </div>
    `;
    
    document.getElementById('resultScreen').classList.remove('hidden');
}

// 最終結果を表示
function showFinalResult(success, correctAnswers, totalQuestions, quizName, reward) {
    //debugLog(`最終結果表示: ${success ? '成功' : '失敗'} - ${correctAnswers}/${totalQuestions}`);
    hideAllScreens();
    
    const finalResultContent = document.getElementById('finalResultContent');
    const successIcon = success ? 
        '<div class="final-result-icon success-icon pulse-animation"><i class="fas fa-trophy"></i></div>' :
        '<div class="final-result-icon failure-icon"><i class="fas fa-sad-tear"></i></div>';
    
    const resultTitle = success ? 'おめでとうございます！' : '残念...';
    const resultMessage = success ? 
        '全問正解です！素晴らしい結果です！' : 
        'もう一度挑戦してみてください！';
    
    let rewardHTML = '';
    if (success && reward) {
        rewardHTML = `
            <div class="reward-info">
                <div class="reward-title">🎁 獲得報酬</div>
                <p>称号: ${reward.title}</p>
                ${reward.money ? `<p>報酬金: $${reward.money}</p>` : ''}
                ${reward.item ? `<p>アイテム: ${reward.item}</p>` : ''}
            </div>
        `;
    }
    
    finalResultContent.innerHTML = `
        ${successIcon}
        <h3 style="margin-bottom: 10px;">${resultTitle}</h3>
        <p style="margin-bottom: 20px;">${resultMessage}</p>
        <div class="score-display">
            ${correctAnswers}/${totalQuestions} 問正解
        </div>
        <p style="margin-bottom: 10px; opacity: 0.8;">クイズ: ${quizName}</p>
        ${rewardHTML}
        <div class="auto-close-text">
            <p>5秒後に自動的に閉じます...</p>
        </div>
    `;
    
    document.getElementById('finalResultScreen').classList.remove('hidden');
}

// 全画面を非表示
function hideAllScreens() {
    //debugLog('全画面を非表示にします');
    document.getElementById('quizSelector').classList.add('hidden');
    document.getElementById('quizScreen').classList.add('hidden');
    document.getElementById('resultScreen').classList.add('hidden');
    document.getElementById('finalResultScreen').classList.add('hidden');
}

// UIを閉じる
function closeUI() {
    //debugLog('closeUI関数実行');
    
    // 常に送信
    fetch(`https://ng-quiz/closeUI`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    }).then(response => {
        //debugLog('closeUI送信完了');
        return response.text();
    }).then(data => {
        //debugLog('closeUI応答: ' + data);
    }).catch(error => {
        //debugLog('closeUIエラー: ' + error);
        // エラーでも画面を閉じる
        hideAllScreens();
    });
}

// リソース名を取得する関数
function getResourceName() {
    if (window.invokeNative) {
        return GetParentResourceName();
    }
    return 'ng-quiz';
}

// GetParentResourceName関数（FiveM用）
function GetParentResourceName() {
    let resourceName = 'ng-quiz';
    try {
        if (window.location && window.location.hostname) {
            const pathParts = window.location.pathname.split('/');
            if (pathParts.length > 1 && pathParts[1]) {
                resourceName = pathParts[1];
            }
        }
    } catch (e) {
        //debugLog('リソース名取得エラー: ' + e);
    }
    return resourceName;
}

// ESCキーイベント
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        //debugLog('ESCキーが押されました');
        closeUI();
    }
});

// マウスイベントの伝播を防ぐ
document.addEventListener('click', function(event) {
    event.stopPropagation();
});

// ページ読み込み完了時の処理
document.addEventListener('DOMContentLoaded', function() {
    //debugLog('HTML DOM読み込み完了');
    
    // 閉じるボタンのイベントリスナーを設定
    const closeButtons = document.querySelectorAll('.close-btn');
    closeButtons.forEach(button => {
        button.addEventListener('click', function(event) {
            event.preventDefault();
            event.stopPropagation();
            //debugLog('閉じるボタンがクリックされました');
            closeUI();
        });
    });
});

// ウィンドウフォーカス時の処理
window.addEventListener('focus', function() {
    //debugLog('UIウィンドウがフォーカスされました');
});

// エラーハンドリング
window.addEventListener('error', function(event) {
    //debugLog('JavaScriptエラー: ' + event.error);
});

//debugLog('script.js読み込み完了');