// ========================
// グローバル変数
// ========================

let isRecording = false;
let recordingTimer = null;
let recordingStartTime = null;
let recordingDuration = 10; // デフォルト10秒
let currentTapeName = '';
let audioContext = null;
let mediaRecorder = null;
let audioChunks = [];

// 実際の音声録音用の新しい変数
let audioStream = null;
let recordedBlobs = [];

// ========================
// DOMコンテンツ読み込み完了時の初期化
// ========================

document.addEventListener('DOMContentLoaded', function() {
    console.log('[ng-voicerecorder] NUI初期化完了');
    
    // MediaRecorder APIサポートチェック
    if (checkMediaRecorderSupport()) {
        console.log('[ng-voicerecorder] リアル音声録音機能が利用可能です');
    } else {
        console.warn('[ng-voicerecorder] シミュレーションモードで動作します');
    }
    
    // イベントリスナー設定
    setupEventListeners();
    
    // 初期状態でUIを非表示
    hideAllUI();
});

// ========================
// イベントリスナー設定
// ========================

function setupEventListeners() {
    // 停止ボタン
    const stopBtn = document.getElementById('stopRecordingBtn');
    if (stopBtn) {
        stopBtn.addEventListener('click', stopRecording);
    }
    
    // キーボードイベント（ESCキーで閉じる）
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            if (isRecording) {
                stopRecording();
            } else {
                closeUI();
            }
        }
    });
    
    // 音声再生完了イベント
    const audioPlayer = document.getElementById('audioPlayer');
    if (audioPlayer) {
        audioPlayer.addEventListener('ended', function() {
            console.log('[ng-voicerecorder] 音声再生完了');
        });
        
        audioPlayer.addEventListener('error', function(e) {
            console.error('[ng-voicerecorder] 音声再生エラー:', e);
            showNotification('音声再生に失敗しました', 'error');
        });
    }
}

// ========================
// NUIメッセージハンドラー
// ========================

window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch (data.action) {
        case 'showRecording':
            showRecordingUI(data.tapeName, data.recordingTime);
            break;
            
        case 'playAudio':
            playAudio(data.audioData, data.volume);
            break;
            
        case 'showLoading':
            showLoading(data.message);
            break;
            
        case 'hideLoading':
            hideLoading();
            break;
            
        case 'showNotification':
            showNotification(data.message, data.type);
            break;
            
        case 'recordingComplete':
            // このハンドラは主にUI操作用。録音完了の詳細な処理は
            // 別の専用リスナーで行われるため、ここでは無害に無視します。
            // （重複ログを避けるために追加）
            break;
        default:
            console.warn('[ng-voicerecorder] 不明なアクション:', data.action);
    }
});

// ========================
// 録音UI表示・制御
// ========================

function showRecordingUI(tapeName, duration) {
    console.log('[ng-voicerecorder] 録音UI表示:', tapeName, duration);
    
    currentTapeName = tapeName;
    recordingDuration = duration || 10;
    
    // UI要素更新
    const tapeNameElement = document.getElementById('tapeName');
    const totalTimeElement = document.getElementById('totalTime');
    
    if (tapeNameElement) {
        tapeNameElement.textContent = tapeName;
    }
    
    if (totalTimeElement) {
        totalTimeElement.textContent = formatTime(recordingDuration);
    }
    
    // 録音コンテナ表示
    const container = document.getElementById('recordingContainer');
    if (container) {
        container.classList.remove('hidden');
    }
    
    // 録音開始
    startRecording();
}

function startRecording() {
    if (isRecording) return;
    
    console.log('[ng-voicerecorder] 録音開始');
    isRecording = true;
    recordingStartTime = Date.now();
    
    // 実際の音声録音を初期化
    initializeRealRecording()
        .then(function(success) {
            if (success) {
                // 録音開始
                if (startRealRecording()) {
                    currentRecordingId = Date.now() + "_" + Math.random().toString(36).substring(2, 15);
                    
                    // タイマー開始
                    startRecordingTimer();
                    
                    // 録音時間後に自動停止
                    setTimeout(function() {
                        if (isRecording) {
                            stopRecording();
                        }
                    }, recordingDuration * 1000);
                } else {
                    isRecording = false;
                    hideRecordingUI();
                }
            } else {
                isRecording = false;
                hideRecordingUI();
            }
        });
}

function stopRecording() {
    if (!isRecording) return;
    
    console.log('[ng-voicerecorder] 録音停止');
    isRecording = false;
    
    // タイマー停止
    if (recordingTimer) {
        clearInterval(recordingTimer);
        recordingTimer = null;
    }
    
    // 実際の音声録音停止
    stopRealRecording();
    
    // UIを閉じる（録音完了後の処理はhandleRecordingCompleteで行われる）
    setTimeout(function() {
        hideRecordingUI();
        closeUI(); // UIフォーカスを解除
    }, 500); // 録音完了処理のための短い遅延
}

function startRecordingTimer() {
    let elapsedTime = 0;
    
    recordingTimer = setInterval(function() {
        elapsedTime = Math.floor((Date.now() - recordingStartTime) / 1000);
        
        // UI更新
        updateRecordingProgress(elapsedTime);
        
        // 最大時間に達したら自動停止
        if (elapsedTime >= recordingDuration) {
            stopRecording();
        }
    }, 100);
}

function updateRecordingProgress(elapsedTime) {
    // 進行バー更新
    const progressBar = document.getElementById('progressBar');
    if (progressBar) {
        const progress = (elapsedTime / recordingDuration) * 100;
        progressBar.style.width = Math.min(progress, 100) + '%';
    }
    
    // 時間表示更新
    const currentTimeElement = document.getElementById('currentTime');
    if (currentTimeElement) {
        currentTimeElement.textContent = formatTime(elapsedTime);
    }
}

function hideRecordingUI() {
    const container = document.getElementById('recordingContainer');
    if (container) {
        container.classList.add('hidden');
    }
    
    // 進行状況リセット
    const progressBar = document.getElementById('progressBar');
    if (progressBar) {
        progressBar.style.width = '0%';
    }
    
    const currentTimeElement = document.getElementById('currentTime');
    if (currentTimeElement) {
        currentTimeElement.textContent = '00:00';
    }
}

// ========================
// 実際の音声録音実装
// ========================

function initializeRealRecording() {
    console.log('[ng-voicerecorder] 実際の音声録音を初期化');
    
    // マイクへのアクセス許可を要求
    const constraints = {
        audio: {
            echoCancellation: true,
            noiseSuppression: true,
            autoGainControl: true,
            sampleRate: 44100
        },
        video: false // 音声のみ
    };
    
    return navigator.mediaDevices.getUserMedia(constraints)
        .then(function(stream) {
            console.log('[ng-voicerecorder] マイクアクセス成功');
            audioStream = stream;
            
            // MediaRecorderのサポート形式をチェック
            let options = {};
            if (MediaRecorder.isTypeSupported('audio/opus')) {
                options = { mimeType: 'audio/opus' };
            } else if (MediaRecorder.isTypeSupported('audio/webm;codecs=opus')) {
                options = { mimeType: 'audio/webm;codecs=opus' };
            } else if (MediaRecorder.isTypeSupported('audio/webm')) {
                options = { mimeType: 'audio/webm' };
            } else if (MediaRecorder.isTypeSupported('audio/mp4')) {
                options = { mimeType: 'audio/mp4' };
            } else {
                console.warn('[ng-voicerecorder] サポートされた音声形式がありません');
                options = {};
            }
            
            console.log('[ng-voicerecorder] 使用する音声形式:', options.mimeType || 'デフォルト');
            
            // MediaRecorderを作成
            mediaRecorder = new MediaRecorder(stream, options);
            recordedBlobs = [];
            
            // イベントリスナー設定
            mediaRecorder.ondataavailable = function(event) {
                if (event.data && event.data.size > 0) {
                    recordedBlobs.push(event.data);
                    console.log('[ng-voicerecorder] 音声データ受信:', event.data.size, 'bytes');
                }
            };
            
            mediaRecorder.onstart = function() {
                console.log('[ng-voicerecorder] MediaRecorder開始');
                recordedBlobs = [];
            };
            
            mediaRecorder.onstop = function() {
                console.log('[ng-voicerecorder] MediaRecorder停止');
                handleRecordingComplete();
            };
            
            mediaRecorder.onerror = function(event) {
                console.error('[ng-voicerecorder] MediaRecorderエラー:', event.error);
                showNotification('録音中にエラーが発生しました', 'error');
            };
            
            return true;
        })
        .catch(function(error) {
            console.error('[ng-voicerecorder] マイクアクセスエラー:', error);
            
            let errorMessage = 'マイクへのアクセスに失敗しました';
            if (error.name === 'NotAllowedError') {
                errorMessage = 'マイクの使用が許可されていません';
            } else if (error.name === 'NotFoundError') {
                errorMessage = 'マイクが見つかりません';
            } else if (error.name === 'NotSupportedError') {
                errorMessage = 'ブラウザが音声録音をサポートしていません';
            }
            
            showNotification(errorMessage, 'error');
            return false;
        });
}

function startRealRecording() {
    if (!mediaRecorder) {
        console.error('[ng-voicerecorder] MediaRecorderが初期化されていません');
        return false;
    }
    
    if (mediaRecorder.state === 'recording') {
        console.warn('[ng-voicerecorder] 既に録音中です');
        return false;
    }
    
    try {
        // 録音開始（100msごとにデータを取得）
        mediaRecorder.start(100);
        console.log('[ng-voicerecorder] 録音開始 - 状態:', mediaRecorder.state);
        return true;
    } catch (error) {
        console.error('[ng-voicerecorder] 録音開始エラー:', error);
        showNotification('録音の開始に失敗しました', 'error');
        return false;
    }
}

function stopRealRecording() {
    if (!mediaRecorder) {
        console.error('[ng-voicerecorder] MediaRecorderが存在しません');
        return;
    }
    
    if (mediaRecorder.state === 'recording') {
        mediaRecorder.stop();
        console.log('[ng-voicerecorder] 録音停止要求');
    }
    
    // ストリームも停止
    if (audioStream) {
        audioStream.getTracks().forEach(track => {
            track.stop();
            console.log('[ng-voicerecorder] 音声トラック停止');
        });
        audioStream = null;
    }
}

function handleRecordingComplete() {
    if (recordedBlobs.length === 0) {
        console.warn('[ng-voicerecorder] 録音データがありません');
        showNotification('録音データが取得できませんでした', 'error');
        return;
    }
    
    console.log('[ng-voicerecorder] 録音完了 - Blobデータ数:', recordedBlobs.length);
    
    // Blobを結合
    const fullBlob = new Blob(recordedBlobs, { type: recordedBlobs[0].type });
    console.log('[ng-voicerecorder] 結合されたBlob:', fullBlob.size, 'bytes, タイプ:', fullBlob.type);
    
    // Base64に変換
    convertBlobToBase64(fullBlob)
        .then(function(base64Data) {
            console.log('[ng-voicerecorder] Base64変換完了:', base64Data.length, '文字');
            
            // NUICallback形式でサーバーに送信
            const recordingData = {
                tapeName: currentTapeName,
                audioData: base64Data,
                mimeType: fullBlob.type,
                size: fullBlob.size
            };
            
            console.log('[ng-voicerecorder] NUIコールバックでサーバーにデータ送信');
            console.log('[ng-voicerecorder] 送信データサイズ:', JSON.stringify(recordingData).length, '文字');
            
            // NUIコールバック経由でLuaに送信
            fetch('https://ng-voicerecorder/saveRecording', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(recordingData)
            })
            .then(response => {
                console.log('[ng-voicerecorder] レスポンス状態:', response.status);
                console.log('[ng-voicerecorder] レスポンスOK:', response.ok);
                
                // レスポンスが空の場合の処理
                if (response.status === 200) {
                    return response.text().then(text => {
                        console.log('[ng-voicerecorder] レスポンステキスト:', text);
                        return text ? JSON.parse(text) : {status: 'ok'};
                    });
                } else {
                    throw new Error('HTTP Error: ' + response.status);
                }
            })
            .then(data => {
                console.log('[ng-voicerecorder] サーバーレスポンス:', data);
                if (data.status === 'ok') {
                    console.log('[ng-voicerecorder] 録音データ送信成功');
                } else {
                    console.warn('[ng-voicerecorder] サーバーエラー:', data.message);
                }
            })
            .catch(err => {
                console.error('[ng-voicerecorder] NUIコールバックエラー:', err);
                console.error('[ng-voicerecorder] エラー詳細:', err.message);
            });
            
        })
        .catch(function(error) {
            console.error('[ng-voicerecorder] Base64変換エラー:', error);
            showNotification('録音データの処理に失敗しました', 'error');
        });
}

function convertBlobToBase64(blob) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = function() {
            // "data:audio/webm;base64," の部分を除去してBase64部分のみを取得
            const base64 = reader.result.split(',')[1];
            resolve(base64);
        };
        reader.onerror = reject;
        reader.readAsDataURL(blob);
    });
}

// ========================
// NUI コールバック（修正版）
// ========================

// NUIコールバック登録用のヘルパー関数
function registerNUICallback(event, callback) {
    window.addEventListener('message', function(e) {
        if (e.data.type === event) {
            callback(e.data.data, function(response) {
                fetch(`https://ng-voicerecorder/${event}`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(response)
                });
            });
        }
    });
}

// 録音完了イベントを受信
window.addEventListener('message', function(event) {
    if (event.data.action === 'recordingComplete') {
        const data = event.data;
        console.log('[ng-voicerecorder] 録音完了通知受信:', data.success);
        
        if (data.success) {
            showNotification('録音が完了しました！', 'success');
        } else {
            showNotification(data.message || '録音に失敗しました', 'error');
        }
        
        // UIを閉じる
        setTimeout(function() {
            closeUI();
        }, 1000);
    }
});

// ========================
// 音声再生機能
// ========================

function playAudio(audioData, volume) {
    console.log('[ng-voicerecorder] 音声再生要求:', typeof audioData, 'ボリューム:', volume);
    
    // デバッグデータの場合
    if (audioData === 'debug_audio_data') {
        showNotification('デバッグモード: 音声再生シミュレーション', 'success');
        return;
    }
    
    // ダミーデータの場合
    if (audioData === 'dummy_audio_data_base64') {
        showNotification('音声を再生中... (シミュレーション)', 'info');
        return;
    }
    
    // URL の場合
    if (typeof audioData === 'string' && (audioData.startsWith('http://') || audioData.startsWith('https://'))) {
        playAudioFromUrl(audioData, volume);
        return;
    }

    // 実際のBase64データの場合
    if (typeof audioData === 'string' && audioData.length > 100) {
        playRealAudio(audioData, 'audio/opus', volume);
        return;
    }

    console.warn('[ng-voicerecorder] 不明な音声データ形式:', audioData);
    showNotification('音声データが無効です', 'error');
}

function playAudioFromUrl(url, volume) {
    const audioPlayer = document.getElementById('audioPlayer');
    if (!audioPlayer) return;
    try {
        audioPlayer.pause();
        audioPlayer.src = url;
        audioPlayer.crossOrigin = 'anonymous';
        audioPlayer.volume = Math.max(0, Math.min(1, volume || 1));
        audioPlayer.play().then(() => {
            console.log('[ng-voicerecorder] 外部URL の音声再生開始:', url);
        }).catch(err => {
            console.error('[ng-voicerecorder] 外部URL 再生失敗:', err);
            showNotification('音声の再生に失敗しました', 'error');
        });
    } catch (err) {
        console.error('[ng-voicerecorder] playAudioFromUrl エラー:', err);
        showNotification('音声の再生に失敗しました', 'error');
    }
}

function playRealAudio(base64Data, mimeType, volume) {
    console.log('[ng-voicerecorder] 実際の音声再生:', mimeType, 'ボリューム:', volume);
    
    const audioPlayer = document.getElementById('audioPlayer');
    if (!audioPlayer) {
        console.error('[ng-voicerecorder] audioPlayer要素が見つかりません');
        return;
    }
    
    try {
        // Base64データからBlobを作成
        const binaryString = atob(base64Data);
        const bytes = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i++) {
            bytes[i] = binaryString.charCodeAt(i);
        }
        const blob = new Blob([bytes], { type: mimeType || 'audio/opus' });
        
        // Object URLを作成
        const audioUrl = URL.createObjectURL(blob);
        
        // 音量設定
        audioPlayer.volume = Math.max(0, Math.min(1, volume || 1));
        
        // 音声再生
        audioPlayer.src = audioUrl;
        audioPlayer.play()
            .then(function() {
                console.log('[ng-voicerecorder] 音声再生開始');
            })
            .catch(function(error) {
                console.error('[ng-voicerecorder] 音声再生失敗:', error);
                showNotification('音声の再生に失敗しました', 'error');
            });
        
        // 再生終了後にURLを解放
        audioPlayer.onended = function() {
            URL.revokeObjectURL(audioUrl);
            console.log('[ng-voicerecorder] 音声再生完了、URL解放');
        };
        
    } catch (error) {
        console.error('[ng-voicerecorder] 音声データ処理エラー:', error);
        showNotification('音声データの処理に失敗しました', 'error');
    }
}

// ========================
// ローディング画面
// ========================

function showLoading(message) {
    const container = document.getElementById('loadingContainer');
    const text = document.querySelector('.loading-text');
    
    if (container) {
        container.classList.remove('hidden');
    }
    
    if (text && message) {
        text.textContent = message;
    }
}

function hideLoading() {
    const container = document.getElementById('loadingContainer');
    if (container) {
        container.classList.add('hidden');
    }
}

// ========================
// 通知システム
// ========================

function showNotification(message, type) {
    const container = document.getElementById('notificationContainer');
    if (!container) return;
    
    const notification = document.createElement('div');
    notification.className = `notification ${type || 'info'}`;
    notification.textContent = message;
    
    container.appendChild(notification);
    
    // 5秒後に自動削除
    setTimeout(function() {
        if (notification.parentNode) {
            notification.parentNode.removeChild(notification);
        }
    }, 5000);
    
    console.log('[ng-voicerecorder] 通知表示:', message, type);
}

// ========================
// ユーティリティ関数
// ========================

function formatTime(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
}

function hideAllUI() {
    const containers = [
        'recordingContainer',
        'loadingContainer'
    ];
    
    containers.forEach(function(id) {
        const element = document.getElementById(id);
        if (element) {
            element.classList.add('hidden');
        }
    });
}

function closeUI() {
    // 録音中の場合は停止
    if (isRecording) {
        stopRecording();
        return;
    }
    
    // UI非表示
    hideAllUI();
    
    // NUIコールバックでLuaに通知
    fetch('https://ng-voicerecorder/closeUI', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    }).catch(err => console.error('[ng-voicerecorder] UI閉じるエラー:', err));
}

// ========================
// MediaRecorder API サポートチェック
// ========================

function checkMediaRecorderSupport() {
    if (typeof MediaRecorder === 'undefined') {
        console.error('[ng-voicerecorder] MediaRecorder APIがサポートされていません');
        showNotification('このブラウザは音声録音をサポートしていません', 'error');
        return false;
    }
    
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        console.error('[ng-voicerecorder] getUserMedia APIがサポートされていません');
        showNotification('このブラウザはマイクアクセスをサポートしていません', 'error');
        return false;
    }
    
    console.log('[ng-voicerecorder] MediaRecorder API サポート確認済み');
    return true;
}

// ========================
// エラーハンドリング
// ========================

window.addEventListener('error', function(event) {
    console.error('[ng-voicerecorder] JavaScriptエラー:', event.error);
    showNotification('予期せぬエラーが発生しました', 'error');
});

// ========================
// デバッグ関数（開発用）
// ========================

window.ngVoiceRecorderDebug = {
    showRecording: function(name, duration) {
        showRecordingUI(name || 'テストテープ', duration || 10);
    },
    
    playAudio: function(volume) {
        playAudio('debug_audio_data', volume || 1.0);
    },
    
    showNotification: function(message, type) {
        showNotification(message || 'テスト通知', type || 'info');
    },
    
    getState: function() {
        return {
            isRecording: isRecording,
            currentTapeName: currentTapeName,
            recordingDuration: recordingDuration,
            mediaRecorderState: mediaRecorder ? mediaRecorder.state : 'null'
        };
    }
};

console.log('[ng-voicerecorder] script.js 初期化完了 - 実際の音声録音対応版');