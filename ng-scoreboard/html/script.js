document.addEventListener('DOMContentLoaded', function() {
    // 初期データ
    let currentData = {
        totalPlayers: 0,
        maxPlayers: 0,
        restartInfo: {
            countdown: "00:00",
            nextTime: "00:00"
        },
        jobCounts: [],
        playersList: [],
        robberies: []
    };

    // メッセージイベントのリスナー
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        if (data.type === 'toggle') {
            if (data.isOpen) {
                document.getElementById('scoreboard').classList.remove('hidden');
            } else {
                document.getElementById('scoreboard').classList.add('hidden');
            }
        } else if (data.type === 'updateData') {
            // データを保存
            currentData = {
                totalPlayers: data.totalPlayers,
                maxPlayers: data.maxPlayers,
                restartInfo: data.restartInfo,
                jobCounts: data.jobCounts,
                playersList: data.playersList,
                robberies: data.robberies
            };
            
            // UI更新
            updateServerInfo();
            updateRobberyList();
            updatePlayersList();
            updateJobsList();
        }
    });
    
    // サーバー情報を更新
    function updateServerInfo() {
        document.getElementById('player-count').textContent = `${currentData.totalPlayers}/${currentData.maxPlayers}`;
        document.getElementById('next-restart-time').textContent = currentData.restartInfo.nextTime;
        document.getElementById('restart-countdown').textContent = currentData.restartInfo.countdown;
    }
    
    // 強盗リストを更新
    function updateRobberyList() {
        const robberyList = document.getElementById('robbery-list');
        robberyList.innerHTML = '';
        
        // jobCountsから警察の人数を取得
        let policeCount = 0;
        currentData.jobCounts.forEach(job => {
            if (job.jobName === 'police') {
                policeCount = job.count;
            }
        });
        
        currentData.robberies.forEach(robbery => {
            const robberyItem = document.createElement('div');
            robberyItem.className = 'robbery-item';
            
            const isAvailable = policeCount >= robbery.requiredPolice;
            const statusIcon = isAvailable ? 'fa-check' : 'fa-times';
            const statusColor = isAvailable ? '#4caf50' : '#f44336';
            
            robberyItem.innerHTML = `
                <div class="name">${robbery.name}</div>
                <div class="status">
                    <span class="police-count">${policeCount}/${robbery.requiredPolice}</span>
                    <i class="fas ${statusIcon}" style="color: ${statusColor}"></i>
                </div>
            `;
            
            robberyList.appendChild(robberyItem);
        });
    }
    
    // プレイヤーリストを更新
    function updatePlayersList() {
        const playersContainer = document.getElementById('players-container');
        playersContainer.innerHTML = '';
        
        // プレイヤーリストを表示
        currentData.playersList.forEach(player => {
            const playerItem = document.createElement('div');
            playerItem.className = 'player-item';
            
            // カスタム名が設定されている場合は表示を変更
            let nameDisplay = player.name;
            let nameClass = 'player-name';
            
            // 自分自身の場合は編集ボタンを表示
            let editButton = '';
            if (player.isSelf) {
                // 自分の名前に編集ボタンを追加
                editButton = `<i class="fas fa-edit edit-name-btn" data-id="${player.id}" data-cid="${player.citizenid}"></i>`;
                nameClass += ' self-name';
            }
            
            // カスタム名が設定されている場合、表示を変更
            if (player.hasCustomName) {
                nameClass += ' custom-name';
                
                // 本名を薄いテキストで表示（ツールチップとして）
                if (player.realName) {
                    nameDisplay += `<span class="real-name-tooltip">(${player.realName})</span>`;
                }
            }
            
            playerItem.innerHTML = `
                <div class="player-info">
                    <span class="${nameClass}">${nameDisplay} ${editButton}</span>
                    <span class="player-id">ID: ${player.id} | CID: ${player.citizenid}</span>
                    <span class="player-phone" data-phone="${player.phone}">TEL: <span class="clickable-phone">${player.phone}</span></span>
                </div>
                <div class="player-job">${player.job} - ${player.grade}</div>
            `;
            
            playersContainer.appendChild(playerItem);
        });
    }
    
    // ジョブリストを更新
    function updateJobsList() {
        const jobList = document.getElementById('job-list');
        jobList.innerHTML = '';
        
        // ジョブ一覧を表示（Config.Jobsの順番で表示）
        currentData.jobCounts.forEach(job => {
            const jobItem = document.createElement('div');
            jobItem.className = 'job-item';
            
            // ジョブ名（日本語表示名）を表示
            jobItem.innerHTML = `
                <div class="job-name">${job.name}</div>
                <div class="job-count">${job.count}</div>
            `;
            
            jobList.appendChild(jobItem);
        });
    }
    
    // 名前編集モーダルを表示
    function showNameEditModal() {
        // すでにモーダルが存在する場合は削除
        let existingModal = document.getElementById('name-edit-modal');
        if (existingModal) {
            existingModal.remove();
        }
        
        // 現在の名前を取得
        fetch('https://ng-scoreboard/getCurrentName', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        })
        .then(response => response.json())
        .then(nameData => {
            // モーダルを作成
            const modal = document.createElement('div');
            modal.id = 'name-edit-modal';
            modal.className = 'modal';
            
            modal.innerHTML = `
                <div class="modal-content">
                    <div class="modal-header">
                        <h3>名前を変更</h3>
                        <span class="modal-close">&times;</span>
                    </div>
                    <div class="modal-body">
                        <p>他のプレイヤーに表示される名前を設定します。</p>
                        <div class="input-group">
                            <label for="lastname-input">姓</label>
                            <input type="text" id="lastname-input" placeholder="姓を入力..." maxlength="25" value="${nameData.lastname || ''}">
                        </div>
                        <div class="input-group">
                            <label for="firstname-input">名</label>
                            <input type="text" id="firstname-input" placeholder="名を入力..." maxlength="25" value="${nameData.firstname || ''}">
                        </div>
                        <div class="name-requirements">
                            <p>※ 姓・名それぞれ1文字以上25文字以下で入力してください</p>
                            <p>※ 特殊文字（<、>、$、;）は使用できません</p>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button id="cancel-name-edit" class="btn btn-cancel">キャンセル</button>
                        <button id="save-custom-name" class="btn btn-save">保存</button>
                    </div>
                </div>
            `;
            
            document.body.appendChild(modal);
            
            // モーダルを表示
            setTimeout(() => {
                modal.classList.add('show');
                document.getElementById('lastname-input').focus();
            }, 10);
            
            // 閉じるボタンのイベント
            document.querySelector('.modal-close').addEventListener('click', closeNameEditModal);
            document.getElementById('cancel-name-edit').addEventListener('click', closeNameEditModal);
            
            // 保存ボタンのイベント
            document.getElementById('save-custom-name').addEventListener('click', saveCustomName);
            
            // Enter キーで保存
            document.getElementById('firstname-input').addEventListener('keyup', function(event) {
                if (event.key === 'Enter') {
                    saveCustomName();
                }
            });
            document.getElementById('lastname-input').addEventListener('keyup', function(event) {
                if (event.key === 'Enter') {
                    document.getElementById('firstname-input').focus();
                }
            });
        })
        .catch(error => {
            console.error('Error:', error);
        });
    }
    
    // 名前編集モーダルを閉じる
    function closeNameEditModal() {
        const modal = document.getElementById('name-edit-modal');
        if (modal) {
            modal.classList.remove('show');
            setTimeout(() => {
                modal.remove();
            }, 300);
        }
    }
    
    // カスタム名を保存
    function saveCustomName() {
        const lastnameInput = document.getElementById('lastname-input');
        const firstnameInput = document.getElementById('firstname-input');
        const lastname = lastnameInput.value.trim();
        const firstname = firstnameInput.value.trim();
        
        // バリデーション
        let hasError = false;
        
        if (lastname.length < 1) {
            lastnameInput.classList.add('input-error');
            setTimeout(() => {
                lastnameInput.classList.remove('input-error');
            }, 500);
            hasError = true;
        }
        
        if (firstname.length < 1) {
            firstnameInput.classList.add('input-error');
            setTimeout(() => {
                firstnameInput.classList.remove('input-error');
            }, 500);
            hasError = true;
        }
        
        if (hasError) return;
        
        // サーバーに送信
        fetch('https://ng-scoreboard/setCustomName', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                lastname: lastname,
                firstname: firstname
            })
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                // 成功したらモーダルを閉じる
                closeNameEditModal();
            } else {
                // エラーがある場合は表示
                lastnameInput.classList.add('input-error');
                firstnameInput.classList.add('input-error');
                setTimeout(() => {
                    lastnameInput.classList.remove('input-error');
                    firstnameInput.classList.remove('input-error');
                }, 500);
            }
        })
        .catch(error => {
            console.error('Error:', error);
            // エラーがある場合は表示
            lastnameInput.classList.add('input-error');
            firstnameInput.classList.add('input-error');
            setTimeout(() => {
                lastnameInput.classList.remove('input-error');
                firstnameInput.classList.remove('input-error');
            }, 500);
        });
    }
    
    // タブ切り替え
    const tabItems = document.querySelectorAll('.tab-item');
    tabItems.forEach(item => {
        item.addEventListener('click', function() {
            // アクティブなタブを切り替え
            document.querySelectorAll('.tab-item').forEach(tab => tab.classList.remove('active'));
            this.classList.add('active');
            
            // タブコンテンツを切り替え
            const tabId = this.getAttribute('data-tab');
            document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
            document.getElementById(tabId).classList.add('active');
        });
    });
    
    // 閉じるボタンのイベントリスナー
    document.getElementById('close-btn').addEventListener('click', function() {
        document.getElementById('scoreboard').classList.add('hidden');
        fetch('https://ng-scoreboard/close', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        })
        .then(response => response.json())
        .catch(error => console.error('Error:', error));
    });
    
    // ESCキーでも閉じられるようにする
    document.addEventListener('keyup', function(event) {
        if (event.key === 'Escape') {
            // 名前編集モーダルが開いている場合はモーダルを閉じる
            const modal = document.getElementById('name-edit-modal');
            if (modal && modal.classList.contains('show')) {
                closeNameEditModal();
                return;
            }
            
            // スコアボードを閉じる
            document.getElementById('scoreboard').classList.add('hidden');
            fetch('https://ng-scoreboard/close', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({})
            })
            .then(response => response.json())
            .catch(error => console.error('Error:', error));
        }
    });
    
    // プレイヤーコンテナのクリックイベントを委任（電話番号と名前編集ボタン）
    document.getElementById('players-container').addEventListener('click', function(event) {
        // 電話番号クリックの処理
        const phoneElement = event.target.closest('.clickable-phone');
        if (phoneElement) {
            const phoneNumber = phoneElement.textContent;
            // 不明の場合は何もしない
            if (phoneNumber === '不明') return;
            
            // スコアボードを閉じる
            document.getElementById('scoreboard').classList.add('hidden');
            fetch('https://ng-scoreboard/close', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({})
            })
            .then(response => response.json())
            .catch(error => console.error('Error:', error));
            
            // 電話をかける
            fetch('https://ng-scoreboard/callNumber', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    number: phoneNumber
                })
            })
            .then(response => response.json())
            .catch(error => console.error('Error:', error));
            return;
        }
        
        // 名前編集ボタンクリックの処理
        const editButton = event.target.closest('.edit-name-btn');
        if (editButton) {
            showNameEditModal();
        }
    });
});