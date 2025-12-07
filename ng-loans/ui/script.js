// グローバル変数
let loanData = [];
let vehicleData = [];
let selectedVehicle = null;
let selectedLoan = null;
let config = {
    standardLoan: {
        interestRate: 0.05,
        maxDays: 7
    },
    vehicleLoan: {
        interestRate: 0.03,
        maxDays: 14
    }
};
// データ更新状態を追跡する変数
let isLoading = {
    loans: false,
    vehicles: false,
    repay: false
};

// イベントリスナー
document.addEventListener('DOMContentLoaded', function() {
    // タブ切り替え
    const tabButtons = document.querySelectorAll('.tab-button');
    tabButtons.forEach(button => {
        button.addEventListener('click', function() {
            const tabId = this.getAttribute('data-tab');
            switchTab(tabId);
        });
    });
    
    // 閉じるボタン
    document.getElementById('close-button').addEventListener('click', closeUI);
    
    // ローン申請関連
    document.getElementById('loan-amount').addEventListener('input', updateLoanSummary);
    document.getElementById('loan-days').addEventListener('input', updateLoanSummary);
    document.getElementById('apply-loan-btn').addEventListener('click', applyForLoan);
    
    // 車両担保ローン関連
    document.getElementById('back-to-vehicles-btn').addEventListener('click', backToVehicleList);
    document.getElementById('vehicle-loan-amount').addEventListener('input', updateVehicleLoanSummary);
    document.getElementById('vehicle-loan-days').addEventListener('input', updateVehicleLoanSummary);
    document.getElementById('apply-vehicle-loan-btn').addEventListener('click', applyForVehicleLoan);
    
    // 返済関連
    document.getElementById('back-to-loans-btn').addEventListener('click', backToLoanList);
    document.getElementById('repay-amount').addEventListener('input', updateRepaymentSummary);
    document.getElementById('repay-loan-btn').addEventListener('click', repayLoan);
    
    // 初期計算
    updateLoanSummary();
    updateVehicleLoanSummary();

    document.getElementById('reload-loans-btn').addEventListener('click', function() {
        reloadData('loans');
    });

    document.getElementById('reload-vehicles-btn').addEventListener('click', function() {
        reloadData('vehicles');
    });

    document.getElementById('reload-repay-btn').addEventListener('click', function() {
        reloadData('loans'); // 返済タブもローンデータを使用するため
    });
});

// NUIメッセージリスナー
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'show') {
        document.getElementById('loan-container').style.display = 'block';
        
        // データの保存
        if (data.data) {
            if (data.data.loans) loanData = data.data.loans;
            if (data.data.vehicles) vehicleData = data.data.vehicles;
            if (data.data.config) config = data.data.config;
            
            // UIの更新
            updateLoansDisplay();
            updateVehicleList();
            updateRepaymentList();
            
            // タブの切り替え
            if (data.data.activeTab) {
                switchTab(data.data.activeTab);
            }
        }
    } else if (data.action === 'hide') {
        document.getElementById('loan-container').style.display = 'none';
    } else if (data.action === 'updateLoans') {
        loanData = data.loans;
        updateLoansDisplay();
        updateRepaymentList();
        
        // ローディング状態をリセット
        isLoading.loans = false;
        isLoading.repay = false;
        document.getElementById('reload-loans-btn').classList.remove('loading');
        document.getElementById('reload-repay-btn').classList.remove('loading');
        
        // 更新完了通知
        showNotification('ローンデータが更新されました', 'success');
    } else if (data.action === 'updateVehicles') {
        vehicleData = data.vehicles;
        updateVehicleList();
        
        // ローディング状態をリセット
        isLoading.vehicles = false;
        document.getElementById('reload-vehicles-btn').classList.remove('loading');
        
        // 更新完了通知
        showNotification('車両データが更新されました', 'success');
    }
});

// データをリロードする関数
function reloadData(dataType) {
    // すでに更新中の場合は何もしない
    if (isLoading[dataType]) return;
    
    // 更新中の状態にする
    isLoading[dataType] = true;
    
    // ボタンの見た目を更新中に変更
    const buttonId = 'reload-' + (dataType === 'repay' ? 'repay' : dataType) + '-btn';
    const button = document.getElementById(buttonId);
    button.classList.add('loading');
    
    if (dataType === 'loans' || dataType === 'repay') {
        // ローンデータのリロード
        fetch('https://ng-loans/reloadLoans', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        })
        .then(response => {
            // 成功メッセージをUIに表示（オプション）
            showNotification('ローンデータを更新しています...', 'info');
        })
        .catch(error => {
            console.error('Error reloading loan data:', error);
            showNotification('ローンデータの更新に失敗しました', 'error');
        })
        .finally(() => {
            // 3秒後にローディング状態を解除（データが戻ってくるのを待つ）
            setTimeout(() => {
                isLoading[dataType] = false;
                button.classList.remove('loading');
            }, 3000);
        });
    } else if (dataType === 'vehicles') {
        // 車両データのリロード
        fetch('https://ng-loans/reloadVehicles', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        })
        .then(response => {
            showNotification('車両データを更新しています...', 'info');
        })
        .catch(error => {
            console.error('Error reloading vehicle data:', error);
            showNotification('車両データの更新に失敗しました', 'error');
        })
        .finally(() => {
            // 3秒後にローディング状態を解除
            setTimeout(() => {
                isLoading[dataType] = false;
                button.classList.remove('loading');
            }, 3000);
        });
    }
}

// 通知を表示する関数
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = 'ui-notification ' + type;
    notification.innerHTML = `
        <div class="notification-content">
            <i class="fas ${type === 'error' ? 'fa-exclamation-circle' : 'fa-info-circle'}"></i>
            <span>${message}</span>
        </div>
    `;
    
    document.body.appendChild(notification);
    
    // アニメーション用のクラスを追加
    setTimeout(() => {
        notification.classList.add('show');
    }, 10);
    
    // 3秒後に通知を削除
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => {
            notification.remove();
        }, 300);
    }, 3000);
}

// UIを閉じる
function closeUI() {
    fetch('https://ng-loans/closeUI', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

// タブ切り替え
function switchTab(tabId) {
    // タブボタンのアクティブ状態を更新
    document.querySelectorAll('.tab-button').forEach(button => {
        if (button.getAttribute('data-tab') === tabId) {
            button.classList.add('active');
        } else {
            button.classList.remove('active');
        }
    });
    
    // タブペインの表示を切り替え
    document.querySelectorAll('.tab-pane').forEach(pane => {
        if (pane.id === tabId) {
            pane.classList.add('active');
        } else {
            pane.classList.remove('active');
        }
    });
}

// ローン情報表示の更新
function updateLoansDisplay() {
    const loanList = document.getElementById('loan-info-list');
    
    if (loanData.length === 0) {
        loanList.innerHTML = '<div class="no-loans">現在アクティブなローンはありません。</div>';
        return;
    }
    
    loanList.innerHTML = '';
    
    loanData.forEach(loan => {
        const isVehicleLoan = loan.vehicleData !== undefined && loan.vehicleData !== null;
        const loanType = isVehicleLoan ? '車両担保ローン' : '通常ローン';
        const loanTypeClass = isVehicleLoan ? 'vehicle' : 'standard';
        
        // 返済率の計算
        const repaymentRate = 1 - (loan.remaining / loan.amount);
        
        // 期日の計算
        const dueDate = new Date(loan.due_date);
        const today = new Date();
        const timeDiff = dueDate.getTime() - today.getTime();
        const daysLeft = Math.ceil(timeDiff / (1000 * 3600 * 24));
        const isOverdue = daysLeft < 0;
        
        let loanCardHTML = `
            <div class="loan-card">
                <div class="loan-card-header">
                    <div class="loan-card-title">$${loan.amount.toLocaleString()}</div>
                    <div class="loan-type ${loanTypeClass}">${loanType}</div>
                </div>
                <div class="loan-progress">
                    <div class="progress-bar" style="width: ${repaymentRate * 100}%"></div>
                </div>
                <div class="loan-status">
                    <div>返済率: ${Math.round(repaymentRate * 100)}%</div>
                    <div>残り: $${loan.remaining.toLocaleString()}</div>
                </div>
                <div class="loan-info">
                    <div class="loan-info-item">
                        <div>借入日:</div>
                        <div class="loan-info-value">${formatDate(loan.date_taken)}</div>
                    </div>
                    <div class="loan-info-item">
                        <div>返済期限:</div>
                        <div class="loan-info-value">${formatDate(loan.due_date)}</div>
                    </div>
                    <div class="loan-info-item">
                        <div>利率:</div>
                        <div class="loan-info-value">${(loan.interest * 100).toFixed(1)}%</div>
                    </div>
                    <div class="loan-info-item">
                        <div>残り日数:</div>
                        <div class="loan-info-value ${isOverdue ? 'overdue' : ''}">${isOverdue ? `${Math.abs(daysLeft)}日延滞` : `${daysLeft}日`}</div>
                    </div>
        `;
        
        // 車両担保ローンの場合、車両情報を追加
        if (isVehicleLoan) {
            loanCardHTML += `
                    <div class="loan-info-item">
                        <div>担保車両:</div>
                        <div class="loan-info-value">${loan.vehicleData.vehicle_model}</div>
                    </div>
                    <div class="loan-info-item">
                        <div>車両番号:</div>
                        <div class="loan-info-value">${loan.vehicleData.plate}</div>
                    </div>
            `;
            
            // 延滞警告
            if (isOverdue) {
                loanCardHTML += `
                    <div class="loan-warning">
                        <i class="fas fa-exclamation-triangle"></i>
                        7日以上の延滞で車両が没収されます！
                    </div>
                `;
            }
        }
        
        loanCardHTML += `
                </div>
                <div class="loan-actions">
                    <button class="loan-action-btn" onclick="selectLoanForRepayment(${loan.id})">
                        <i class="fas fa-money-bill"></i>
                        返済する
                    </button>
                </div>
            </div>
        `;
        
        loanList.innerHTML += loanCardHTML;
    });
}

// 車両リストの更新
function updateVehicleList() {
    const vehicleList = document.getElementById('vehicle-list');
    
    if (vehicleData.length === 0) {
        vehicleList.innerHTML = '<div class="no-vehicles">利用可能な車両がありません。</div>';
        return;
    }
    
    vehicleList.innerHTML = '';
    
    vehicleData.forEach(vehicle => {
        const vehicleCard = document.createElement('div');
        vehicleCard.className = 'vehicle-card';
        vehicleCard.onclick = () => selectVehicle(vehicle);
        
        vehicleCard.innerHTML = `
            <div class="vehicle-card-header">${vehicle.vehicle}</div>
            <div class="vehicle-info">
                <div class="vehicle-info-item">
                    <div>車両番号:</div>
                    <div>${vehicle.plate}</div>
                </div>
                <div class="vehicle-info-item">
                    <div>最大ローン額:</div>
                    <div>$${vehicle.maxLoan.toLocaleString()}</div>
                </div>
            </div>
        `;
        
        vehicleList.appendChild(vehicleCard);
    });
}

// 返済可能なローンリストの更新
function updateRepaymentList() {
    const repayLoanList = document.getElementById('repay-loan-list');
    
    if (loanData.length === 0) {
        repayLoanList.innerHTML = '<div class="no-loans">返済可能なローンはありません。</div>';
        return;
    }
    
    repayLoanList.innerHTML = '';
    
    loanData.forEach(loan => {
        const isVehicleLoan = loan.vehicleData !== undefined && loan.vehicleData !== null;
        const loanType = isVehicleLoan ? '車両担保ローン' : '通常ローン';
        const loanTypeClass = isVehicleLoan ? 'vehicle' : 'standard';
        
        // 期日の計算
        const dueDate = new Date(loan.due_date);
        const today = new Date();
        const timeDiff = dueDate.getTime() - today.getTime();
        const daysLeft = Math.ceil(timeDiff / (1000 * 3600 * 24));
        const isOverdue = daysLeft < 0;
        
        const loanCard = document.createElement('div');
        loanCard.className = 'loan-card';
        loanCard.onclick = () => selectLoanForRepayment(loan.id);
        
        loanCard.innerHTML = `
            <div class="loan-card-header">
                <div class="loan-card-title">$${loan.amount.toLocaleString()}</div>
                <div class="loan-type ${loanTypeClass}">${loanType}</div>
            </div>
            <div class="loan-info">
                <div class="loan-info-item">
                    <div>残額:</div>
                    <div class="loan-info-value">$${loan.remaining.toLocaleString()}</div>
                </div>
                <div class="loan-info-item">
                    <div>返済期限:</div>
                    <div class="loan-info-value">${formatDate(loan.due_date)}</div>
                </div>
                <div class="loan-info-item">
                    <div>残り日数:</div>
                    <div class="loan-info-value ${isOverdue ? 'overdue' : ''}">${isOverdue ? `${Math.abs(daysLeft)}日延滞` : `${daysLeft}日`}</div>
                </div>
            </div>
        `;
        
        repayLoanList.appendChild(loanCard);
    });
}

// 車両を選択
function selectVehicle(vehicle) {
    selectedVehicle = vehicle;
    
    // フォームの表示
    document.getElementById('vehicle-selection').style.display = 'none';
    document.getElementById('vehicle-loan-form').style.display = 'block';
    
    // 選択した車両の情報を表示
    document.getElementById('selected-vehicle-info').innerHTML = `
        <h4>${vehicle.vehicle}</h4>
        <div class="vehicle-info">
            <div class="vehicle-info-item">
                <div>車両番号:</div>
                <div>${vehicle.plate}</div>
            </div>
            <div class="vehicle-info-item">
                <div>最大ローン額:</div>
                <div>$${vehicle.maxLoan.toLocaleString()}</div>
            </div>
        </div>
    `;
    
    // 金額入力制限の更新
    const amountInput = document.getElementById('vehicle-loan-amount');
    amountInput.max = vehicle.maxLoan;
    amountInput.value = Math.min(amountInput.value, vehicle.maxLoan);
    document.getElementById('vehicle-amount-hint').textContent = `$1,000 から $${vehicle.maxLoan.toLocaleString()} まで`;
    
    // 概要の更新
    updateVehicleLoanSummary();
}

// 返済用ローンを選択
function selectLoanForRepayment(loanId) {
    const loan = loanData.find(l => l.id === loanId);
    if (!loan) return;
    
    selectedLoan = loan;
    
    // フォームの表示
    document.getElementById('repay-loan-list').style.display = 'none';
    document.getElementById('repay-form').style.display = 'block';
    
    // 選択したローンの情報を表示
    const isVehicleLoan = loan.vehicleData !== undefined && loan.vehicleData !== null;
    const loanType = isVehicleLoan ? '車両担保ローン' : '通常ローン';
    
    let selectedLoanInfo = `
        <h4>${loanType} - $${loan.amount.toLocaleString()}</h4>
        <div class="loan-info">
            <div class="loan-info-item">
                <div>残額:</div>
                <div>$${loan.remaining.toLocaleString()}</div>
            </div>
            <div class="loan-info-item">
                <div>返済期限:</div>
                <div>${formatDate(loan.due_date)}</div>
            </div>
    `;
    
    if (isVehicleLoan) {
        selectedLoanInfo += `
            <div class="loan-info-item">
                <div>担保車両:</div>
                <div>${loan.vehicleData.vehicle_model}</div>
            </div>
            <div class="loan-info-item">
                <div>車両番号:</div>
                <div>${loan.vehicleData.plate}</div>
            </div>
        `;
    }
    
    selectedLoanInfo += `</div>`;
    
    document.getElementById('selected-loan-info').innerHTML = selectedLoanInfo;
    
    // 金額入力制限の更新
    const amountInput = document.getElementById('repay-amount');
    amountInput.max = loan.remaining;
    amountInput.value = loan.remaining;
    document.getElementById('repay-amount-hint').textContent = `$1 から $${loan.remaining.toLocaleString()} まで`;
    
    // 概要の更新
    updateRepaymentSummary();
    
    // タブ切り替え
    switchTab('repay');
}

// 車両選択画面に戻る
function backToVehicleList() {
    document.getElementById('vehicle-selection').style.display = 'block';
    document.getElementById('vehicle-loan-form').style.display = 'none';
    selectedVehicle = null;
}

// ローン選択画面に戻る
function backToLoanList() {
    document.getElementById('repay-loan-list').style.display = 'grid';
    document.getElementById('repay-form').style.display = 'none';
    selectedLoan = null;
}

// 通常ローン概要の更新
function updateLoanSummary() {
    const amount = parseInt(document.getElementById('loan-amount').value) || 0;
    const days = parseInt(document.getElementById('loan-days').value) || 0;
    
    const interestRate = config.standardLoan.interestRate;
    const interest = amount * interestRate;
    const total = amount + interest;
    
    document.getElementById('summary-amount').textContent = '$' + amount.toLocaleString();
    document.getElementById('summary-rate').textContent = (interestRate * 100).toFixed(1) + '%';
    document.getElementById('summary-interest').textContent = '$' + interest.toLocaleString();
    document.getElementById('summary-total').textContent = '$' + total.toLocaleString();
    document.getElementById('summary-days').textContent = days + '日';
}

// 車両担保ローン概要の更新
function updateVehicleLoanSummary() {
    const amount = parseInt(document.getElementById('vehicle-loan-amount').value) || 0;
    const days = parseInt(document.getElementById('vehicle-loan-days').value) || 0;
    
    const interestRate = config.vehicleLoan.interestRate;
    const interest = amount * interestRate;
    const total = amount + interest;
    
    document.getElementById('v-summary-amount').textContent = '$' + amount.toLocaleString();
    document.getElementById('v-summary-rate').textContent = (interestRate * 100).toFixed(1) + '%';
    document.getElementById('v-summary-interest').textContent = '$' + interest.toLocaleString();
    document.getElementById('v-summary-total').textContent = '$' + total.toLocaleString();
    document.getElementById('v-summary-days').textContent = days + '日';
}

// 返済概要の更新
function updateRepaymentSummary() {
    if (!selectedLoan) return;
    
    const amount = parseInt(document.getElementById('repay-amount').value) || 0;
    const remaining = selectedLoan.remaining - amount;
    
    document.getElementById('r-summary-current').textContent = '$' + selectedLoan.remaining.toLocaleString();
    document.getElementById('r-summary-payment').textContent = '$' + amount.toLocaleString();
    document.getElementById('r-summary-remaining').textContent = '$' + remaining.toLocaleString();
}

// ローン申請
function applyForLoan() {
    const amount = parseInt(document.getElementById('loan-amount').value) || 0;
    const days = parseInt(document.getElementById('loan-days').value) || 0;
    
    if (amount < config.standardLoan.minAmount || amount > config.standardLoan.maxAmount) {
        alert(`申請金額は $${config.standardLoan.minAmount.toLocaleString()} から $${config.standardLoan.maxAmount.toLocaleString()} の間である必要があります。`);
        return;
    }
    
    if (days <= 0 || days > config.standardLoan.maxDays) {
        alert(`返済期間は 1日 から ${config.standardLoan.maxDays}日 の間である必要があります。`);
        return;
    }
    
    fetch('https://ng-loans/applyLoan', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ amount, days })
    });
}

// 車両担保ローン申請
function applyForVehicleLoan() {
    if (!selectedVehicle) return;
    
    const amount = parseInt(document.getElementById('vehicle-loan-amount').value) || 0;
    const days = parseInt(document.getElementById('vehicle-loan-days').value) || 0;
    
    if (amount <= 0 || amount > selectedVehicle.maxLoan) {
        alert(`申請金額は $1,000 から $${selectedVehicle.maxLoan.toLocaleString()} の間である必要があります。`);
        return;
    }
    
    if (days <= 0 || days > config.vehicleLoan.maxDays) {
        alert(`返済期間は 1日 から ${config.vehicleLoan.maxDays}日 の間である必要があります。`);
        return;
    }
    
    fetch('https://ng-loans/applyVehicleLoan', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            plate: selectedVehicle.plate,
            model: selectedVehicle.vehicle,
            amount,
            days
        })
    });
}

// ローン返済
function repayLoan() {
    if (!selectedLoan) return;
    
    const amount = parseInt(document.getElementById('repay-amount').value) || 0;
    
    if (amount <= 0 || amount > selectedLoan.remaining) {
        alert(`返済額は $1 から $${selectedLoan.remaining.toLocaleString()} の間である必要があります。`);
        return;
    }
    
    fetch('https://ng-loans/repayLoan', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            loanId: selectedLoan.id,
            amount
        })
    });
}

// 日付フォーマット
function formatDate(dateString) {
    if (!dateString) return '不明';
    
    const date = new Date(dateString);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    
    return `${year}/${month}/${day} ${hours}:${minutes}`;
}

// 通貨フォーマット
function formatCurrency(amount) {
    return '$' + amount.toLocaleString();
}