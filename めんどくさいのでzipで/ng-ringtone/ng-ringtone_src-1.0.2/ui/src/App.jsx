import { useEffect, useRef, useState } from 'react';
import RingtoneItem from './components/RingtoneItem';
import VolumeSlider from './components/VolumeSlider';
import Frame from './components/Frame';
import './App.css';

const devMode = !window.invokeNative;

const App = () => {
    const [theme, setTheme] = useState('light');
    const [ringtones, setRingtones] = useState([]);
    const [currentRingtone, setCurrentRingtone] = useState(null);
    const [isPlaying, setIsPlaying] = useState(false);
    const [isMuted, setIsMuted] = useState(false);
    const [message, setMessage] = useState('');
    const [showMessage, setShowMessage] = useState(false);
    const [messageType, setMessageType] = useState('info');
    const [activeTab, setActiveTab] = useState('saved'); // 'saved', 'custom'
    const [newRingtoneName, setNewRingtoneName] = useState('');
    const [newRingtoneUrl, setNewRingtoneUrl] = useState('');
    const [volumeSelf, setVolumeSelf] = useState(1.0);
    const [volumeOthers, setVolumeOthers] = useState(0.7);
    const [editingRingtone, setEditingRingtone] = useState(null);
    const [isRefreshing, setIsRefreshing] = useState(false);
    const [playingRingtoneId, setPlayingRingtoneId] = useState(null);
    
    const appDiv = useRef(null);

    const { setPopUp, fetchNui, sendNotification, getSettings, onSettingsChange } = window;

    // 初期データのロード
    useEffect(() => {
        //console.log("App.jsx が初期化されました");
        
        if (devMode) {
            // 開発モードの場合、表示を有効にする
            document.getElementsByTagName('html')[0].style.visibility = 'visible';
            document.getElementsByTagName('body')[0].style.visibility = 'visible';
            // 開発モード用のダミーデータ
            setNewRingtoneUrl('https://example.com/default-ringtone.mp3');
            setPresetRingtones([
                { name: "クラシック", url: "https://example.com/classic.mp3" },
                { name: "デジタル", url: "https://example.com/digital.mp3" },
                { name: "レトロ", url: "https://example.com/retro.mp3" }
            ]);
            setRingtones([
                { id: 1, name: "お気に入り1", url: "https://example.com/favorite1.mp3", is_default: 1, is_muted: 0, volume_self: 0.8, volume_others: 0.6 },
                { id: 2, name: "お気に入り2", url: "https://example.com/favorite2.mp3", is_default: 0, is_muted: 0, volume_self: 1.0, volume_others: 0.7 }
            ]);
            setCurrentRingtone({ id: 1, name: "お気に入り1", url: "https://example.com/favorite1.mp3", is_default: 1, is_muted: 0, volume_self: 0.8, volume_others: 0.6 });
            return;
        } else {
            // テーマ設定を取得
            getSettings().then((settings) => setTheme(settings.display.theme));
            onSettingsChange((settings) => setTheme(settings.display.theme));
            
            //console.log("初期データをロード中...");
            
            // リングトーンの取得（シンプルな方法）
            fetchNui('getRingtones').then((response) => {
                //console.log("リングトーン取得結果:", response);
                if (response && response.ringtones) {
                    //console.log(`${response.ringtones.length}件のリングトーンを読み込みました`);
                    setRingtones(response.ringtones);
                    
                    // デフォルトリングトーンを検索して設定
                    const defaultRingtone = response.ringtones.find(r => r.is_default === 1);
                    if (defaultRingtone) {
                        //console.log("デフォルトリングトーンを設定:", defaultRingtone.name);
                        setCurrentRingtone(defaultRingtone);
                        setIsMuted(defaultRingtone.is_muted === 1);
                        // 音量も設定
                        if (defaultRingtone.volume_self !== undefined) {
                            setVolumeSelf(defaultRingtone.volume_self);
                        }
                        if (defaultRingtone.volume_others !== undefined) {
                            setVolumeOthers(defaultRingtone.volume_others);
                        }
                    }
                }
            }).catch(error => {
                console.error("リングトーン取得エラー:", error);
            });
            
            // 現在のリングトーンを取得
            fetchNui('getCurrentRingtone').then((ringtone) => {
                //console.log("現在のリングトーン:", ringtone);
                if (ringtone) {
                    setCurrentRingtone(ringtone);
                    setIsMuted(ringtone.is_muted === 1);
                    // 音量も設定
                    if (ringtone.volume_self !== undefined) {
                        setVolumeSelf(ringtone.volume_self);
                    }
                    if (ringtone.volume_others !== undefined) {
                        setVolumeOthers(ringtone.volume_others);
                    }
                }
            }).catch(error => {
                console.error("現在のリングトーン取得エラー:", error);
            });
        }
    }, []);

    // NUIメッセージハンドラー
    useEffect(() => {
        const handleNuiMessage = (event) => {
            const data = event.data;
            //console.log("NUI メッセージ受信:", data);
            
            // リングトーンリスト更新処理
            if (data && data.action === "updateRingtoneList" && Array.isArray(data.ringtones)) {
                //console.log(`リングトーン一覧更新: ${data.ringtones.length}件のデータ`);
                setRingtones(data.ringtones);
                
                // データが更新されたらデフォルトリングトーンも更新
                const defaultRingtone = data.ringtones.find(r => r.is_default === 1);
                if (defaultRingtone) {
                    //console.log("UIデフォルトリングトーン更新:", defaultRingtone.name);
                    setCurrentRingtone(prevRingtone => {
                        // 現在のリングトーンがない、またはIDが一致する場合に更新
                        if (!prevRingtone || prevRingtone.id === defaultRingtone.id) {
                            return defaultRingtone;
                        }
                        return prevRingtone;
                    });
                }
                
                if (isRefreshing) {
                    setIsRefreshing(false);
                    displayMessage('リスト更新完了', 'success');
                }
            }
            
            // 通知メッセージ処理
            if (data && data.action === "notification") {
                displayMessage(data.message, data.type || 'info');
            }
        };
        
        window.addEventListener('message', handleNuiMessage);
        return () => window.removeEventListener('message', handleNuiMessage);
    }, [isRefreshing]);

    // メッセージ表示関数
    const displayMessage = (msg, type = 'info') => {
        setMessage(msg);
        setMessageType(type);
        setShowMessage(true);
        
        // 3秒後にメッセージを非表示
        setTimeout(() => {
            setShowMessage(false);
        }, 3000);
    };

    // リングトーン直接取得（確実な方法）
    const fetchRingtonesDirectly = async () => {
        setIsRefreshing(true);
        displayMessage('リストを直接取得中...', 'info');
        
        try {
            //console.log("リングトーンを直接取得中...");
            const response = await fetchNui('getRingtones');
            //console.log("取得結果:", response);
            
            if (response && response.ringtones) {
                //console.log(`${response.ringtones.length}件のリングトーンを取得しました`);
                setRingtones(response.ringtones);
                
                // デフォルトリングトーンを検索して設定
                const defaultRingtone = response.ringtones.find(r => r.is_default === 1);
                if (defaultRingtone) {
                    //console.log("デフォルトリングトーンを更新:", defaultRingtone.name);
                    setCurrentRingtone(defaultRingtone);
                }
                
                displayMessage(`${response.ringtones.length}件のリングトーンを読み込みました`, 'success');
            } else {
                displayMessage('リングトーンデータが取得できませんでした', 'error');
            }
        } catch (error) {
            console.error("データ取得エラー:", error);
            displayMessage('データ取得中にエラーが発生しました', 'error');
        } finally {
            setIsRefreshing(false);
        }
    };

    // リングトーン保存
    const handleSaveRingtone = () => {
        if (!newRingtoneUrl || !newRingtoneUrl.trim()) {
            displayMessage('有効なURLを入力してください', 'error');
            return;
        }
        
        if (!newRingtoneName || !newRingtoneName.trim()) {
            displayMessage('名前を入力してください', 'error');
            return;
        }
    
        const ringtoneData = {
            name: newRingtoneName,
            url: newRingtoneUrl,
            is_default: ringtones.length === 0 ? 1 : 0
            // volume_self と volume_others を削除
        };
    
        //console.log("リングトーンを保存:", ringtoneData);
        displayMessage('リングトーンを保存中...', 'info');
        
        fetchNui('saveRingtone', ringtoneData)
            .then((response) => {
                //console.log("保存応答:", response);
                
                if (response && response.success) {
                    displayMessage(response.message || 'リングトーンを保存しました', 'success');
                    // 入力フィールドをリセット
                    setNewRingtoneName('');
                    setNewRingtoneUrl('');
                    // 保存が完了したら「保存済み」タブに切り替え
                    setActiveTab('saved');
                    // リストを更新
                    setTimeout(() => fetchRingtonesDirectly(), 500);
                } else {
                    displayMessage(response.message || 'リングトーンの保存に失敗しました', 'error');
                }
            })
            .catch((error) => {
                console.error("保存エラー:", error);
                displayMessage('リングトーンの保存中にエラーが発生しました', 'error');
            });
    };
    
    // リングトーン更新
    const handleUpdateRingtone = () => {
        if (!editingRingtone) return;
        
        //console.log("リングトーンを更新:", editingRingtone);
        
        // 入力チェック
        if (!editingRingtone.url || !editingRingtone.url.trim()) {
            displayMessage('有効なURLを入力してください', 'error');
            return;
        }
        
        if (!editingRingtone.name || !editingRingtone.name.trim()) {
            displayMessage('名前を入力してください', 'error');
            return;
        }
        
        // 更新するリングトーンから音量関連のプロパティを削除
        const updatedRingtone = {
            id: editingRingtone.id,
            name: editingRingtone.name,
            url: editingRingtone.url,
            is_default: editingRingtone.is_default
            // volume_self と volume_others を削除
        };
        
        displayMessage('リングトーンを更新中...', 'info');
        
        fetchNui('updateRingtone', updatedRingtone)
            .then((response) => {
                //console.log("更新応答:", response);
                
                if (response && response.success) {
                    displayMessage(response.message || 'リングトーンを更新しました', 'success');
                    
                    // 編集モードを終了して保存済みタブに戻る
                    setEditingRingtone(null);
                    setActiveTab('saved');
                    
                    // リストを更新
                    setTimeout(() => fetchRingtonesDirectly(), 500);
                } else {
                    displayMessage(response.message || 'リングトーンの更新に失敗しました', 'error');
                }
            })
            .catch((error) => {
                console.error("更新エラー:", error);
                displayMessage('リングトーンの更新中にエラーが発生しました', 'error');
            });
    };
    
    // リングトーン削除
    const handleDeleteRingtone = (id) => {
        setPopUp({
            title: 'リングトーンを削除',
            description: 'このリングトーンを削除しますか？',
            buttons: [
                {
                    title: 'キャンセル',
                    color: 'red'
                },
                {
                    title: '削除',
                    color: 'blue',
                    cb: () => {
                        //console.log(`リングトーンを削除: ID=${id}`);
                        
                        // 数値IDを確実に送信
                        fetchNui('deleteRingtone', parseInt(id, 10))
                            .then((response) => {
                                //console.log("削除応答:", response);
                                
                                if (response && response.success) {
                                    displayMessage('リングトーンを削除しました', 'success');
                                    
                                    // 直接リングトーンリストから削除
                                    setRingtones(ringtones.filter(r => r.id !== id));
                                    
                                    // サーバーからも最新データを取得
                                    setTimeout(() => {
                                        fetchRingtonesDirectly();
                                    }, 500);
                                } else {
                                    displayMessage('削除できませんでした。もう一度お試しください。', 'error');
                                }
                            })
                            .catch((error) => {
                                console.error("削除エラー:", error);
                                displayMessage('リングトーンの削除に失敗しました', 'error');
                            });
                    }
                }
            ]
        });
    };
    
    // リングトーンプレビュー
    const handlePreviewRingtone = (url = null, ringtoneId = null) => {
        const previewUrl = url || (editingRingtone ? editingRingtone.url : newRingtoneUrl);
        
        if (!previewUrl || !previewUrl.trim()) {
            displayMessage('有効なURLを入力してください', 'error');
            return;
        }
        
        // 同じリングトーンが再生中の場合は停止
        if (playingRingtoneId === ringtoneId || (playingRingtoneId === null && isPlaying)) {
            //console.log("再生中のプレビューを停止");
            fetchNui('stopPreview')
                .then(() => {
                    setIsPlaying(false);
                    setPlayingRingtoneId(null);
                })
                .catch(error => {
                    console.error("プレビュー停止エラー:", error);
                    // エラーが発生しても状態をリセット
                    setIsPlaying(false);
                    setPlayingRingtoneId(null);
                });
        } else {
            // 別のプレビューが再生中なら、まず停止してから再生
            const startNewPreview = () => {
                //console.log(`プレビューを開始: ${previewUrl}`);
                fetchNui('previewRingtone', { url: previewUrl })
                    .then(() => {
                        setIsPlaying(true);
                        setPlayingRingtoneId(ringtoneId);
                        
                        // 10秒後に自動停止
                        setTimeout(() => {
                            // 同じIDのリングトーンがまだ再生中の場合のみ停止
                            if (playingRingtoneId === ringtoneId) {
                                //console.log("プレビューを自動停止");
                                fetchNui('stopPreview').then(() => {
                                    setIsPlaying(false);
                                    setPlayingRingtoneId(null);
                                }).catch(() => {
                                    // エラーが発生しても状態をリセット
                                    setIsPlaying(false);
                                    setPlayingRingtoneId(null);
                                });
                            }
                        }, 10000);
                    })
                    .catch(error => {
                        console.error("プレビュー開始エラー:", error);
                        displayMessage('プレビューの再生に失敗しました', 'error');
                    });
            };
            
            // すでに何かが再生中なら、まず停止
            if (isPlaying) {
                fetchNui('stopPreview')
                    .then(() => {
                        // 停止成功後に新しいプレビューを開始
                        startNewPreview();
                    })
                    .catch(() => {
                        // エラーが発生しても新しいプレビューを試みる
                        startNewPreview();
                    });
            } else {
                // 何も再生中でなければそのまま開始
                startNewPreview();
            }
        }
    };


    // デフォルトリングトーンに設定
    const handleSetAsDefault = (ringtone) => {
        //console.log(`デフォルトリングトーンに設定: ${ringtone.name} (ID=${ringtone.id})`);
        
        // 既にデフォルトの場合は何もしない
        if (ringtone.is_default === 1) {
            displayMessage('既にデフォルトに設定されています', 'info');
            return;
        }
        
        // 選択したリングトーンをデフォルトに設定
        const updatedRingtone = { ...ringtone, is_default: 1 };
        
        // UI上で即座に反映（他のリングトーンのデフォルト設定を解除）
        const updatedRingtones = ringtones.map(r => {
            if (r.id === ringtone.id) {
                return { ...r, is_default: 1 };
            } else if (r.is_default === 1) {
                return { ...r, is_default: 0 };
            }
            return r;
        });
        
        // まずUIを更新
        setRingtones(updatedRingtones);
        setCurrentRingtone(updatedRingtone);
        
        // サーバーに更新を送信
        //console.log("デフォルト設定をサーバーに送信:", updatedRingtone);
        
        fetchNui('updateRingtone', updatedRingtone)
            .then((response) => {
                //console.log("デフォルト設定応答:", response);
                
                if (response.success) {
                    displayMessage('デフォルトリングトーンを設定しました', 'success');
                    
                    // サーバーから最新データを取得（少し遅延させて確実に更新が反映されるようにする）
                    setTimeout(() => {
                        fetchRingtonesDirectly();
                    }, 500);
                } else {
                    displayMessage(response.message || 'エラーが発生しました', 'error');
                    // 失敗した場合は元に戻す
                    fetchRingtonesDirectly();
                }
            })
            .catch((error) => {
                console.error("デフォルト設定エラー:", error);
                displayMessage('デフォルト設定に失敗しました', 'error');
                // エラーの場合も元に戻す
                fetchRingtonesDirectly();
            });
    };
    
    // ミュート切り替え - 全体のみに変更
    const handleToggleMute = () => {
        // 全体のミュート設定を切り替え
        const newMuteState = !isMuted;
        //console.log(`全体ミュート切替: ${newMuteState ? 'ON' : 'OFF'}`);
        
        fetchNui('toggleMute', { isMuted: newMuteState })
            .then((response) => {
                //console.log("全体ミュート切替応答:", response);
                
                if (response.success) {
                    setIsMuted(newMuteState);
                    displayMessage(newMuteState ? 'すべての着信音をミュートしました' : 'ミュートを解除しました', 'success');
                } else {
                    displayMessage(response.message || 'エラーが発生しました', 'error');
                }
            })
            .catch((error) => {
                console.error("全体ミュート切替エラー:", error);
                displayMessage('ミュート設定の変更に失敗しました', 'error');
            });
    };

    // 自分の音量設定の更新
    const handleSelfVolumeChange = (value) => {
        // 自分の音量設定を更新
        //console.log(`自分の音量更新: ${value}`);
        
        setVolumeSelf(value);
        
        // 変更をサーバーに送信
        fetchNui('updateGlobalVolume', {
            volumeSelf: value,
            volumeOthers: volumeOthers
        }).then((response) => {
            //console.log("音量設定更新応答:", response);
            if (!response.success) {
                displayMessage('音量設定の更新に失敗しました', 'error');
            }
        }).catch((error) => {
            console.error("音量更新エラー:", error);
            displayMessage('音量設定の更新に失敗しました', 'error');
        });
    };

    // 周りの音量設定の更新
    const handleOthersVolumeChange = (value) => {
        // 周りの音量設定を更新
        //console.log(`周りの音量更新: ${value}`);
        
        setVolumeOthers(value);
        
        // 変更をサーバーに送信
        fetchNui('updateGlobalVolume', {
            volumeSelf: volumeSelf,
            volumeOthers: value
        }).then((response) => {
            //console.log("音量設定更新応答:", response);
            if (!response.success) {
                displayMessage('音量設定の更新に失敗しました', 'error');
            }
        }).catch((error) => {
            console.error("音量更新エラー:", error);
            displayMessage('音量設定の更新に失敗しました', 'error');
        });
    };

    // 設定をデータベースから再読み込み
    const handleRefreshSettings = async () => {
        displayMessage('設定を再読み込み中...', 'info');
        
        try {
            // サーバーから最新の設定を取得
            const response = await fetchNui('refreshSettings');
            
            if (response && response.success) {
                // 取得した設定を適用
                if (response.volumeSelf !== undefined) setVolumeSelf(response.volumeSelf);
                if (response.volumeOthers !== undefined) setVolumeOthers(response.volumeOthers);
                if (response.isMuted !== undefined) setIsMuted(response.isMuted);
                
                displayMessage('設定を再読み込みしました', 'success');
            } else {
                displayMessage('設定の再読み込みに失敗しました', 'error');
            }
        } catch (error) {
            console.error("設定再読み込みエラー:", error);
            displayMessage('設定の再読み込み中にエラーが発生しました', 'error');
        }
    };

    // リングトーンの編集を開始
    const handleEditRingtone = (ringtone) => {
        //console.log(`リングトーン編集開始: ${ringtone.name}`);
        setEditingRingtone({...ringtone});
        setActiveTab('edit');
    };

    return (
        <AppProvider>
            <div className='app' ref={appDiv} data-theme={theme}>
                <div className='app-wrapper'>
                    <div className='header'>
                        <div className='title'>リングトーン設定</div>
                        <div className='subtitle'>着信音をカスタマイズ</div>
                    </div>

                    {/* タブメニュー */}
                    <div className='tab-menu'>
                        <button 
                            className={`tab-button ${activeTab === 'saved' ? 'active' : ''}`}
                            onClick={() => setActiveTab('saved')}
                        >
                            保存済み
                        </button>
                        <button 
                            className={`tab-button ${activeTab === 'custom' ? 'active' : ''}`}
                            onClick={() => setActiveTab('custom')}
                        >
                            追加
                        </button>
                        <button 
                            className={`tab-button ${activeTab === 'control' ? 'active' : ''}`}
                            onClick={() => setActiveTab('control')}
                        >
                            設定
                        </button>
                        <button 
                            className={`tab-button ${activeTab === 'guide' ? 'active' : ''}`}
                            onClick={() => setActiveTab('guide')}
                        >
                            使い方
                        </button>
                    </div>

                    {/* 保存済みタブ */}
                    {activeTab === 'saved' && (
                        <div className='presets-container'>
                            <div className="refresh-button-container">
                                <button 
                                    className={`refresh-button ${isRefreshing ? 'loading' : ''}`}
                                    onClick={fetchRingtonesDirectly}
                                    disabled={isRefreshing}
                                >
                                    {isRefreshing ? '更新中...' : 'リストを更新'}
                                    {isRefreshing ? (
                                        <span className="loading-spinner"></span>
                                    ) : (
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" className="refresh-icon">
                                            <path d="M21 12C21 16.9706 16.9706 21 12 21C7.02944 21 3 16.9706 3 12C3 7.02944 7.02944 3 12 3" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
                                            <path d="M12 3L16 7M16 3L12 7" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                                        </svg>
                                    )}
                                </button>
                            </div>
                            
                            {/* デバッグ情報 */}
                            <div style={{padding: '0.5rem', fontSize: '0.8rem', color: 'gray', marginBottom: '1rem'}}>
                                リングトーン件数: {ringtones ? ringtones.length : 0}件
                            </div>
                            
                            {/* リングトーンリスト */}
                            {ringtones && ringtones.length > 0 ? (
                                ringtones.map((ringtone) => (
                                    <div key={ringtone.id} className={`ringtone-item-extended ${ringtone.is_default === 1 ? 'default' : ''}`}>
                                        <div className="ringtone-info">
                                            <div className="ringtone-name">
                                                {ringtone.name}
                                                {ringtone.is_default === 1 && <span className="default-badge">デフォルト</span>}
                                            </div>
                                            <div className="ringtone-url">{ringtone.url && ringtone.url.substring(0, 40)}{ringtone.url && ringtone.url.length > 40 ? '...' : ''}</div>
                                        </div>
                                        <div className="ringtone-actions">
                                            <button className="icon-button" onClick={() => handlePreviewRingtone(ringtone.url, ringtone.id)}>
                                                {playingRingtoneId === ringtone.id ? '■' : '▶'}
                                            </button>
                                            <button className="icon-button" onClick={() => handleEditRingtone(ringtone)}>
                                                ✏️
                                            </button>
                                            <button 
                                                className={`icon-button ${ringtone.is_default === 1 ? 'active' : ''}`} 
                                                onClick={() => handleSetAsDefault(ringtone)}
                                                disabled={ringtone.is_default === 1}
                                            >
                                                ★
                                            </button>
                                            <button className="icon-button delete" onClick={() => handleDeleteRingtone(ringtone.id)}>
                                                🗑️
                                            </button>
                                        </div>
                                    </div>
                                ))
                            ) : (
                                <div className="empty-state">
                                    保存されたリングトーンはありません。<br />
                                    「追加」タブから新しいリングトーンを追加してください。
                                </div>
                            )}
                        </div>
                    )}

                    {/* コントロールタブ - 自分の音量設定とミュート設定 */}
                    {activeTab === 'control' && (
                        <div className='control-container'>
                            <div className="settings-header">
                                <h2 className="section-title">音量設定</h2>
                                <button 
                                    className="refresh-settings-button"
                                    onClick={handleRefreshSettings}
                                >
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                                        <path d="M21 12C21 16.9706 16.9706 21 12 21C7.02944 21 3 16.9706 3 12C3 7.02944 7.02944 3 12 3" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
                                        <path d="M12 3L16 7M16 3L12 7" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                                    </svg>
                                    設定を再読み込み
                                </button>
                            </div>
                            
                            <div className="volume-control-container">
                                <div className="volume-label">自分の着信音量: {Math.round(volumeSelf * 100)}%</div>
                                <VolumeSlider 
                                    value={volumeSelf} 
                                    onChange={(value) => handleSelfVolumeChange(value)} 
                                />
                            </div>
                            
                            <div className='help-text'>
                                自分に聞こえる着信音の音量を調整します。
                            </div>
                            
                            <div className="volume-control-container">
                                <div className="volume-label">周りの着信音量: {Math.round(volumeOthers * 100)}%</div>
                                <VolumeSlider 
                                    value={volumeOthers} 
                                    onChange={(value) => handleOthersVolumeChange(value)} 
                                />
                            </div>
                            
                            <div className='help-text'>
                                周囲のプレイヤーの着信音が自分に聞こえる音量を調整します。
                            </div>
                            
                            <h2 className="section-title">ミュート設定</h2>
                            
                            <button 
                                className={`mute-button ${isMuted ? 'muted' : ''}`}
                                onClick={() => handleToggleMute()}
                            >
                                {isMuted ? 'ミュート解除' : '全ミュート'}
                            </button>
                            
                            <div className='help-text'>
                                ミュートを有効にすると、すべての着信音が無音になります。
                            </div>
                        </div>
                    )}

                    {/* 追加タブ - 変更なし */}
                    {activeTab === 'custom' && (
                        <div className='custom-container'>
                            <input 
                                className='ringtone-input'
                                type='text'
                                placeholder='リングトーン名'
                                value={newRingtoneName}
                                onChange={(e) => setNewRingtoneName(e.target.value)}
                            />
                            
                            <input 
                                className='ringtone-input'
                                type='text'
                                placeholder='リングトーンのURL'
                                value={newRingtoneUrl}
                                onChange={(e) => setNewRingtoneUrl(e.target.value)}
                            />
                            
                            <div className='button-wrapper'>
                                <button onClick={handleSaveRingtone}>
                                    保存
                                </button>
                            </div>
                            
                            <div className='help-text'>
                                MP3またはWAVファイルのURLを入力してください。
                                <br />
                                変更したリングトーンは周囲のプレイヤーにも聞こえます。
                            </div>
                        </div>
                    )}

                    {/* 編集タブ */}
                    {activeTab === 'edit' && editingRingtone && (
                        <div className='custom-container'>
                            <input 
                                className='ringtone-input'
                                type='text'
                                placeholder='リングトーン名'
                                value={editingRingtone.name}
                                onChange={(e) => setEditingRingtone({...editingRingtone, name: e.target.value})}
                            />
                            
                            <input 
                                className='ringtone-input'
                                type='text'
                                placeholder='リングトーンのURL'
                                value={editingRingtone.url}
                                onChange={(e) => setEditingRingtone({...editingRingtone, url: e.target.value})}
                            />
                            
                            <div className='button-wrapper'>
                                <button onClick={handleUpdateRingtone}>
                                    更新
                                </button>
                                <button className="cancel-button" onClick={() => {
                                    setEditingRingtone(null);
                                    setActiveTab('saved');
                                }}>
                                    キャンセル
                                </button>
                            </div>
                        </div>
                    )}

                    {/* 使い方タブ */}
                    {activeTab === 'guide' && (
                        <div className='guide-container'>
                            <div className='guide-section'>
                                <h3 className='guide-title'>📱 着信音の設定方法</h3>
                                <div className='guide-content'>
                                    <p className='guide-step'>1. Phoneの「設定」アプリを開く</p>
                                    <p className='guide-step'>2. 「サウンドと触覚」をタップ</p>
                                    <p className='guide-step'>3. 「着信音」をタップ</p>
                                    <p className='guide-step'>4. 一番下までスクロールして「Custom_ringtone」を選択</p>
                                </div>
                            </div>

                            <div className='guide-section'>
                                <h3 className='guide-title'>🎵 カスタム着信音の追加</h3>
                                <div className='guide-content'>
                                    <p className='guide-step'>1. 「追加」タブを開く</p>
                                    <p className='guide-step'>2. リングトーン名を入力（例: お気に入りの曲）</p>
                                    <p className='guide-step'>3. MP3またはWAVファイルのURLを入力</p>
                                    <p className='guide-step'>4. 「保存」ボタンをクリック</p>
                                    <p className='guide-step'>5. 「保存済み」タブで★マークをクリックしてデフォルトに設定</p>
                                </div>
                            </div>

                            <div className='guide-section'>
                                <h3 className='guide-title'>🔊 音量設定</h3>
                                <div className='guide-content'>
                                    <p className='guide-step'><strong>自分の着信音量:</strong> 自分に聞こえる着信音の音量</p>
                                    <p className='guide-step'><strong>周りの着信音量:</strong> 他のプレイヤーの着信音が聞こえる音量</p>
                                    <p className='guide-step'>スライダーを動かして好みの音量に調整できます</p>
                                </div>
                            </div>

                            <div className='guide-section'>
                                <h3 className='guide-title'>🔇 ミュート機能</h3>
                                <div className='guide-content'>
                                    <p className='guide-step'>「設定」タブの「全ミュート」ボタンで、すべての着信音を無音にできます</p>
                                    <p className='guide-step'>ミュート中は自分の着信音も他人の着信音も聞こえません</p>
                                </div>
                            </div>

                            <div className='guide-section'>
                                <h3 className='guide-title'>💡 ヒント</h3>
                                <div className='guide-content'>
                                    <p className='guide-step'>• プレビューボタン（▶）で着信音を試聴できます</p>
                                    <p className='guide-step'>• 設定は自動的にデータベースに保存されます</p>
                                    <p className='guide-step'>• 「設定を再読み込み」ボタンで最新の設定を取得できます</p>
                                    <p className='guide-step'>• 着信音は周囲20m以内のプレイヤーに聞こえます</p>
                                </div>
                            </div>
                        </div>
                    )}

                    {/* メッセージ表示 */}
                    {showMessage && (
                        <div className={`message-container ${messageType}`}>
                            {message}
                        </div>
                    )}
                </div>
            </div>
        </AppProvider>
    );
};

const AppProvider = ({ children }) => {
    if (devMode) {
        return (
            <div className='dev-wrapper'>
                <Frame>{children}</Frame>
            </div>
        );
    } else return children;
};

export default App;