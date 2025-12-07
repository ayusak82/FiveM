// グローバル変数
let currentDate = new Date();
let selectedDate = null;
let selectedEmployee = null;
let managementData = [];
let playerData = null;
let config = null;
let currentWorkStatus = {};
let resourceName = 'ng-attendance'; // デフォルトリソース名

// 初期化
document.addEventListener('DOMContentLoaded', function() {
    // リソース名を初期化時に取得
    resourceName = getResourceName();
    
    initializeUI();
    setupEventListeners();
    startTimeUpdate();
});

// リソース名取得関数
function getResourceName() {
    try {
        // FiveMのグローバル関数を使用
        if (window.invokeNative) {
            return window.invokeNative('_GET_CURRENT_RESOURCE_NAME') || 'ng-attendance';
        }
        // 代替方法: URLから取得
        if (window.location && window.location.pathname) {
            const pathParts = window.location.pathname.split('/');
            if (pathParts.length > 1 && pathParts[1] !== '') {
                return pathParts[1];
            }
        }
        // 最終的なフォールバック
        return 'ng-attendance';
    } catch (error) {
        console.error('Error getting resource name:', error);
        return 'ng-attendance';
    }
}

// UI初期化
function initializeUI() {
    updateCurrentTime();
    generateCalendar();
    
    // デバッグログ
    debugLog('UI initialized');
}

// イベントリスナー設定
function setupEventListeners() {
    // 閉じるボタン
    document.getElementById('close-btn').addEventListener('click', closeUI);
    
    // タブ切り替え
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            switchTab(this.dataset.tab);
        });
    });
    
    // カレンダーナビゲーション
    document.getElementById('prev-month').addEventListener('click', previousMonth);
    document.getElementById('next-month').addEventListener('click', nextMonth);
    
    // 従業員検索
    document.getElementById('employee-search').addEventListener('input', function() {
        searchEmployee(this.value);
    });
    
    // ESCキーで閉じる
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            closeUI();
        }
    });
}

// 現在時刻更新
function updateCurrentTime() {
    const now = new Date();
    const timeStr = now.toLocaleTimeString('ja-JP', { 
        hour12: false,
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
    });
    const dateStr = now.toLocaleDateString('ja-JP', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit'
    });

    document.getElementById('current-time').textContent = timeStr;
    document.getElementById('current-date').textContent = dateStr;
}

// 時刻更新タイマー開始
function startTimeUpdate() {
    setInterval(updateCurrentTime, 1000);
}

// タブ切り替え
function switchTab(tabName) {
    // すべてのタブボタンから active クラスを削除
    document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
    // すべてのタブコンテンツを非表示
    document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
    
    // クリックされたタブボタンに active クラスを追加
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
    // 対応するタブコンテンツを表示
    document.getElementById(tabName + '-tab').classList.add('active');
    
    // 管理画面タブの場合、データを取得
    if (tabName === 'management' && playerData) {
        fetchManagementData(playerData.job.name);
    }
}

// カレンダー生成
function generateCalendar() {
    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();
    
    document.getElementById('calendar-title').textContent = 
        `${year}年 ${month + 1}月`;

    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);
    const startDate = new Date(firstDay);
    startDate.setDate(startDate.getDate() - firstDay.getDay());

    const calendarGrid = document.getElementById('calendar-grid');
    calendarGrid.innerHTML = '';

    // 曜日ヘッダー
    const dayHeaders = ['日', '月', '火', '水', '木', '金', '土'];
    dayHeaders.forEach(day => {
        const dayElement = document.createElement('div');
        dayElement.className = 'calendar-day-header';
        dayElement.textContent = day;
        calendarGrid.appendChild(dayElement);
    });

    // カレンダーの日付
    const currentDateForCalendar = new Date(startDate);
    for (let i = 0; i < 42; i++) {
        const dayElement = document.createElement('div');
        dayElement.className = 'calendar-day';
        dayElement.textContent = currentDateForCalendar.getDate();

        if (currentDateForCalendar.getMonth() !== month) {
            dayElement.classList.add('other-month');
        }

        const dateStr = formatDateForDB(currentDateForCalendar);
        dayElement.addEventListener('click', () => selectDate(dateStr, dayElement));
        
        calendarGrid.appendChild(dayElement);
        currentDateForCalendar.setDate(currentDateForCalendar.getDate() + 1);
    }
    
    // 選択された従業員の月次記録を取得
    if (selectedEmployee) {
        fetchMonthlyRecords(selectedEmployee, year, month + 1);
    }
}

// 日付選択
function selectDate(dateStr, element) {
    // 前の選択を解除
    document.querySelectorAll('.calendar-day.selected').forEach(el => {
        el.classList.remove('selected');
    });

    // 新しい日付を選択
    element.classList.add('selected');
    selectedDate = dateStr;
    
    // 従業員が選択されている場合、その日の記録を取得
    if (selectedEmployee) {
        fetchEmployeeRecords(selectedEmployee, selectedDate);
    }
    
    post('selectDate', { date: selectedDate });
}

// 月移動
function previousMonth() {
    currentDate.setMonth(currentDate.getMonth() - 1);
    generateCalendar();
}

function nextMonth() {
    currentDate.setMonth(currentDate.getMonth() + 1);
    generateCalendar();
}

// 従業員選択
function selectEmployee(employee, cardElement) {
    // 前の選択を解除
    document.querySelectorAll('.employee-card.selected').forEach(card => {
        card.classList.remove('selected');
    });
    
    // 新しい選択
    cardElement.classList.add('selected');
    selectedEmployee = employee.citizenid;
    
    document.getElementById('selected-employee').textContent = 
        `${employee.name} (${employee.citizenid})`;
    
    // 総出勤時間を更新
    document.getElementById('total-work-hours').textContent = `${employee.totalHours}時間 0分`;
    
    // カレンダーを再生成（選択した従業員の記録を反映）
    generateCalendar();
    
    // 現在選択されている日付があれば、その記録を取得
    if (selectedDate) {
        fetchEmployeeRecords(selectedEmployee, selectedDate);
    }
    
    post('selectEmployee', { citizenid: selectedEmployee });
}

// 従業員検索
function searchEmployee(query) {
    const cards = document.querySelectorAll('.employee-card');
    let visibleCount = 0;
    
    cards.forEach(card => {
        const text = card.textContent.toLowerCase();
        if (query === '' || text.includes(query.toLowerCase())) {
            card.style.display = 'block';
            visibleCount++;
        } else {
            card.style.display = 'none';
        }
    });
    
    // 検索結果数を更新
    const titleElement = document.getElementById('employee-list-title');
    const baseTitle = '勤務記録のある全従業員';
    if (query === '') {
        titleElement.textContent = `${baseTitle} (${managementData.length}名)`;
    } else {
        titleElement.textContent = `${baseTitle} (${visibleCount}/${managementData.length}名)`;
    }
}

// 管理画面データ取得
function fetchManagementData(job) {
    post('getManagementData', { job: job });
}

// 従業員記録取得
function fetchEmployeeRecords(citizenid, date) {
    post('getEmployeeRecords', { citizenid: citizenid, date: date });
}

// 月次記録取得
function fetchMonthlyRecords(citizenid, year, month) {
    post('getMonthlyRecords', { citizenid: citizenid, year: year, month: month });
}

// 勤務状況取得
function fetchWorkStatus() {
    post('getWorkStatus', {});
}

// UI閉じる
function closeUI() {
    post('closeUI', {});
}

// NUIメッセージ受信
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (!data || !data.action) {
        return;
    }
    
    try {
        switch(data.action) {
            case 'openUI':
                openUI(data.data);
                break;
            case 'closeUI':
                document.getElementById('attendance-ui').style.display = 'none';
                break;
            case 'updateWorkStatus':
                updateWorkStatus(data.data);
                break;
            case 'updateManagementData':
                updateManagementData(data.data);
                break;
            case 'updateEmployeeRecords':
                updateEmployeeRecords(data.data);
                break;
            case 'updateMonthlyRecords':
                updateMonthlyRecords(data.data);
                break;
            case 'updateEmployeeList':
                updateEmployeeList(data.data);
                break;
            default:
                debugLog(`Unknown action: ${data.action}`);
        }
    } catch (error) {
        console.error('Error handling message:', error);
        debugLog(`Error handling message: ${error.message}`);
    }
});

// UI開く
function openUI(data) {
    playerData = data.playerData;
    config = data.config;
    
    document.getElementById('attendance-ui').style.display = 'flex';
    
    // 管理画面タブの表示/非表示
    const managementBtn = document.getElementById('management-tab-btn');
    if (playerData && playerData.job && config.jobs[playerData.job.name]) {
        const jobConfig = config.jobs[playerData.job.name];
        
        // isboss = trueの場合のみ管理画面を表示
        if (playerData.job.isboss === true) {
            managementBtn.style.display = 'block';
            document.getElementById('boss-job-title').textContent = 
                `${jobConfig.label} - 管理者`;
        } else {
            managementBtn.style.display = 'none';
        }
    }
    
    // 勤務状況を取得
    fetchWorkStatus();
}

// 勤務状況更新（複数ジョブ対応）
function updateWorkStatus(workStatus) {
    try {
        if (!workStatus) {
            debugLog('Work status data is null or undefined');
            return;
        }
        
        currentWorkStatus = workStatus;
        
        // 現在のジョブ
        const currentJobElement = document.getElementById('current-job');
        if (currentJobElement) {
            currentJobElement.textContent = workStatus.currentJob || 'なし';
        }
        
        // 勤務状態（複数ジョブ対応）
        const statusElement = document.getElementById('work-status');
        const jobStatusElement = document.getElementById('job-status');
        
        if (workStatus.totalActiveSessions > 0) {
            if (statusElement) {
                statusElement.textContent = `勤務中 (${workStatus.totalActiveSessions}ジョブ)`;
                statusElement.className = 'status-value status-active';
            }
            
            // アクティブなジョブリストを表示
            let jobsText = '';
            for (const jobName in workStatus.activeJobs) {
                const job = workStatus.activeJobs[jobName];
                if (jobsText) jobsText += ', ';
                jobsText += jobName;
            }
            
            if (jobStatusElement) {
                jobStatusElement.textContent = `${jobsText}として勤務中です`;
            }
            
            // 最初のアクティブジョブの情報を表示（複数ある場合は最初のもの）
            const firstActiveJob = Object.values(workStatus.activeJobs)[0];
            if (firstActiveJob && firstActiveJob.clockIn) {
                const clockInTime = formatDateTime(firstActiveJob.clockIn);
                const workStartElement = document.getElementById('work-start');
                if (workStartElement) {
                    workStartElement.textContent = clockInTime;
                }
                
                // 勤務時間計算
                const startTime = new Date(firstActiveJob.clockIn);
                const now = new Date();
                const diffMinutes = Math.floor((now - startTime) / (1000 * 60));
                const hours = Math.floor(diffMinutes / 60);
                const minutes = diffMinutes % 60;
                
                const workDurationElement = document.getElementById('work-duration');
                if (workDurationElement) {
                    workDurationElement.textContent = `${hours}時間 ${minutes}分`;
                }
            }
            
            // 複数ジョブの詳細を表示
            updateMultiJobDetails(workStatus.activeJobs);
            
        } else {
            if (statusElement) {
                statusElement.textContent = '非勤務';
                statusElement.className = 'status-value status-inactive';
            }
            if (jobStatusElement) {
                jobStatusElement.textContent = '現在は非勤務です';
            }
            
            const workStartElement = document.getElementById('work-start');
            const workDurationElement = document.getElementById('work-duration');
            
            if (workStartElement) workStartElement.textContent = '--:--:--';
            if (workDurationElement) workDurationElement.textContent = '0時間 0分';
            
            // 複数ジョブ詳細をクリア
            clearMultiJobDetails();
        }
    } catch (error) {
        console.error('Error updating work status:', error);
        debugLog(`Error updating work status: ${error.message}`);
    }
}

// 複数ジョブの詳細表示
function updateMultiJobDetails(activeJobs) {
    let detailsContainer = document.getElementById('multi-job-details');
    
    // コンテナが存在しない場合は作成
    if (!detailsContainer) {
        detailsContainer = document.createElement('div');
        detailsContainer.id = 'multi-job-details';
        detailsContainer.className = 'multi-job-details';
        
        // 勤務状況セクションに追加
        const statusSection = document.querySelector('.status-section');
        if (statusSection) {
            statusSection.appendChild(detailsContainer);
        }
    }
    
    let html = '<h4>アクティブなジョブ:</h4>';
    
    for (const jobName in activeJobs) {
        const job = activeJobs[jobName];
        const startTime = new Date(job.clockIn);
        const now = new Date();
        const diffMinutes = Math.floor((now - startTime) / (1000 * 60));
        const hours = Math.floor(diffMinutes / 60);
        const minutes = diffMinutes % 60;
        
        html += `
            <div class="job-detail">
                <div class="job-name">${jobName}</div>
                <div class="job-info">
                    <span class="job-start">開始: ${formatDateTime(job.clockIn)}</span>
                    <span class="job-duration">経過: ${hours}時間 ${minutes}分</span>
                </div>
            </div>
        `;
    }
    
    detailsContainer.innerHTML = html;
}

// 複数ジョブ詳細をクリア
function clearMultiJobDetails() {
    const detailsContainer = document.getElementById('multi-job-details');
    if (detailsContainer) {
        detailsContainer.innerHTML = '';
    }
}

// 管理画面データ更新
function updateManagementData(employees) {
    managementData = employees;
    
    const employeeGrid = document.getElementById('employee-grid');
    employeeGrid.innerHTML = '';
    
    if (employees.length === 0) {
        employeeGrid.innerHTML = '<div class="no-data">勤務記録のある従業員がいません</div>';
        return;
    }
    
    employees.forEach(employee => {
        const card = document.createElement('div');
        
        // 最近勤務していない場合の視覚的表示
        const lastWorkedDate = new Date(employee.lastWorked);
        const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
        const isRecent = lastWorkedDate > weekAgo;
        
        card.className = isRecent ? 'employee-card' : 'employee-card inactive';
        
        // 月ごとの勤務時間を表示するHTML
        let monthlyHoursHTML = '';
        if (employee.monthlyBreakdown) {
            monthlyHoursHTML = '<div class="monthly-hours-summary">';
            const sortedMonths = Object.keys(employee.monthlyBreakdown).sort().reverse();
            sortedMonths.slice(0, 3).forEach(monthKey => {
                const monthData = employee.monthlyBreakdown[monthKey];
                const monthName = `${monthData.year}年${monthData.month}月`;
                monthlyHoursHTML += `<div class="month-hour-item">
                    <span class="month-label">${monthName}:</span>
                    <span class="month-hours">${monthData.totalHours}時間</span>
                </div>`;
            });
            monthlyHoursHTML += '</div>';
        }
        
        // ジョブリスト（複数ジョブ対応）
        let jobsListHTML = '';
        if (employee.jobs && employee.jobs.length > 0) {
            jobsListHTML = '<div class="employee-jobs-list">' + 
                employee.jobs.map(job => `<span class="job-badge">${job}</span>`).join('') + 
                '</div>';
        } else if (employee.jobsList) {
            jobsListHTML = `<div class="employee-job-text">${employee.jobsList}</div>`;
        }
        
        card.innerHTML = `
            <h5>${employee.name}</h5>
            <p>${employee.citizenid}</p>
            ${jobsListHTML}
            <p>合計: ${employee.totalHours}時間 | ${employee.totalDays}日</p>
            <p class="last-worked">最終: ${formatDate(employee.lastWorked)}</p>
            ${monthlyHoursHTML}
        `;
        
        card.addEventListener('click', () => selectEmployee(employee, card));
        employeeGrid.appendChild(card);
    });
    
    // 従業員数を更新
    document.getElementById('employee-list-title').textContent = 
        `勤務記録のある全従業員 (${employees.length}名)`;
}

// 従業員選択（月ごとの総出勤時間対応）
function selectEmployee(employee, cardElement) {
    // 前の選択を解除
    document.querySelectorAll('.employee-card.selected').forEach(card => {
        card.classList.remove('selected');
    });
    
    // 新しい選択
    cardElement.classList.add('selected');
    selectedEmployee = employee.citizenid;
    
    document.getElementById('selected-employee').textContent = 
        `${employee.name} (${employee.citizenid})`;
    
    // 総出勤時間を更新（過去3ヶ月の合計）
    document.getElementById('total-work-hours').textContent = `${employee.totalHours}時間 ${employee.totalMinutes ? employee.totalMinutes % 60 : 0}分`;
    
    // 月ごとの詳細を表示
    displayMonthlyBreakdown(employee);
    
    // カレンダーを再生成（選択した従業員の記録を反映）
    generateCalendar();
    
    // 現在選択されている日付があれば、その記録を取得
    if (selectedDate) {
        fetchEmployeeRecords(selectedEmployee, selectedDate);
    }
    
    post('selectEmployee', { citizenid: selectedEmployee });
}

// 月ごとの勤務時間詳細を表示
function displayMonthlyBreakdown(employee) {
    // 月ごとの詳細表示エリアを作成または取得
    let monthlyDetailDiv = document.getElementById('monthly-detail');
    
    if (!monthlyDetailDiv) {
        // 存在しない場合は作成
        monthlyDetailDiv = document.createElement('div');
        monthlyDetailDiv.id = 'monthly-detail';
        monthlyDetailDiv.className = 'monthly-detail-section';
        
        // 総出勤時間の後に挿入
        const totalHoursDiv = document.querySelector('.total-hours');
        if (totalHoursDiv && totalHoursDiv.parentNode) {
            totalHoursDiv.parentNode.insertBefore(monthlyDetailDiv, totalHoursDiv.nextSibling);
        }
    }
    
    // 月ごとの内訳を表示
    if (employee.monthlyBreakdown) {
        let html = '<h4>月別勤務時間</h4><div class="monthly-breakdown">';
        
        const sortedMonths = Object.keys(employee.monthlyBreakdown).sort().reverse();
        sortedMonths.forEach(monthKey => {
            const monthData = employee.monthlyBreakdown[monthKey];
            const monthName = `${monthData.year}年${monthData.month}月`;
            
            html += `
                <div class="monthly-item">
                    <div class="monthly-header">
                        <span class="monthly-name">${monthName}</span>
                        <span class="monthly-hours">${monthData.totalHours}時間${monthData.totalMinutes % 60}分</span>
                    </div>`;
            
            // ジョブごとの内訳（あれば）
            if (monthData.jobs) {
                html += '<div class="monthly-jobs">';
                for (const [job, jobData] of Object.entries(monthData.jobs)) {
                    const jobHours = Math.floor(jobData.minutes / 60);
                    const jobMinutes = jobData.minutes % 60;
                    html += `<span class="job-time">${job}: ${jobHours}時間${jobMinutes}分</span>`;
                }
                html += '</div>';
            }
            
            html += '</div>';
        });
        
        html += '</div>';
        monthlyDetailDiv.innerHTML = html;
        monthlyDetailDiv.style.display = 'block';
    } else {
        monthlyDetailDiv.style.display = 'none';
    }
}

// 従業員記録更新（複数ジョブ対応）
function updateEmployeeRecords(records) {
    const recordSummary = document.getElementById('record-summary');
    
    if (records.length === 0) {
        document.getElementById('clock-in-time').textContent = '記録なし';
        document.getElementById('clock-out-time').textContent = '記録なし';
        recordSummary.style.display = 'none';
        return;
    }
    
    // 複数ジョブの記録がある場合の表示
    if (records.length === 1) {
        const record = records[0];
        
        document.getElementById('clock-in-time').textContent = 
            record.clock_in ? formatDateTime(record.clock_in) : '記録なし';
        document.getElementById('clock-out-time').textContent = 
            record.clock_out ? formatDateTime(record.clock_out) : '退勤中';
        
        // 詳細情報を表示
        document.getElementById('daily-duration').textContent = 
            formatMinutes(record.total_minutes || 0);
        document.getElementById('daily-grade').textContent = 
            record.job_grade || '-';
            
    } else {
        // 複数ジョブの場合は合計情報を表示
        let totalMinutes = 0;
        let earliestClockIn = null;
        let latestClockOut = null;
        let jobsList = [];
        
        records.forEach(record => {
            totalMinutes += record.total_minutes || 0;
            jobsList.push(record.job);
            
            if (record.clock_in) {
                const clockInTime = new Date(record.clock_in);
                if (!earliestClockIn || clockInTime < earliestClockIn) {
                    earliestClockIn = clockInTime;
                }
            }
            
            if (record.clock_out) {
                const clockOutTime = new Date(record.clock_out);
                if (!latestClockOut || clockOutTime > latestClockOut) {
                    latestClockOut = clockOutTime;
                }
            }
        });
        
        document.getElementById('clock-in-time').textContent = 
            earliestClockIn ? formatDateTime(earliestClockIn.toISOString()) : '記録なし';
        document.getElementById('clock-out-time').textContent = 
            latestClockOut ? formatDateTime(latestClockOut.toISOString()) : '一部退勤中';
        
        // 詳細情報を表示
        document.getElementById('daily-duration').textContent = 
            formatMinutes(totalMinutes);
        document.getElementById('daily-grade').textContent = 
            jobsList.join(', ');
    }
    
    recordSummary.style.display = 'block';
}

// 月次記録更新（複数ジョブ対応）
function updateMonthlyRecords(monthlyData) {
    // カレンダーの日付に has-record クラスを追加
    document.querySelectorAll('.calendar-day').forEach(dayElement => {
        dayElement.classList.remove('has-record');
        
        if (!dayElement.classList.contains('other-month')) {
            const day = parseInt(dayElement.textContent);
            const year = currentDate.getFullYear();
            const month = currentDate.getMonth() + 1;
            const dateStr = `${year}-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}`;
            
            // 複数ジョブの記録がある場合もチェック
            if (monthlyData[dateStr]) {
                dayElement.classList.add('has-record');
                
                // 複数ジョブの場合、ツールチップやタイトルに詳細を追加
                if (typeof monthlyData[dateStr] === 'object') {
                    const jobNames = Object.keys(monthlyData[dateStr]);
                    if (jobNames.length > 1) {
                        dayElement.title = `勤務記録あり: ${jobNames.join(', ')}`;
                        dayElement.classList.add('multi-job-record');
                    } else {
                        dayElement.title = `勤務記録あり: ${jobNames[0]}`;
                    }
                } else {
                    dayElement.title = '勤務記録あり';
                }
            }
        }
    });
}

// 従業員リスト更新（検索結果）
function updateEmployeeList(filteredData) {
    managementData = filteredData;
    updateManagementData(filteredData);
}

// ヘルパー関数
function formatDateTime(dateTimeStr) {
    const date = new Date(dateTimeStr);
    return date.toLocaleString('ja-JP', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false
    });
}

function formatDate(dateStr) {
    const date = new Date(dateStr);
    return date.toLocaleDateString('ja-JP', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit'
    });
}

function formatDateForDB(date) {
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
}

function formatMinutes(minutes) {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return `${hours}時間 ${mins}分`;
}

function debugLog(message) {
    post('debugLog', { message: message });
}

function post(action, data) {
    fetch(`https://${resourceName}/${action}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data)
    }).then(resp => {
        // レスポンスが空でない場合のみJSONパース
        const contentType = resp.headers.get('content-type');
        if (contentType && contentType.includes('application/json')) {
            return resp.json();
        } else {
            return resp.text();
        }
    }).then(resp => {
        // レスポンス処理（必要に応じて）
        if (typeof resp === 'object') {
            // JSON レスポンスの場合
            debugLog(`Response from ${action}: ${JSON.stringify(resp)}`);
        }
    }).catch(error => {
        console.error(`Error in ${action}:`, error);
        debugLog(`Error in ${action}: ${error.message}`);
    });
}

// FiveM専用関数（後方互換性のため残す）
function GetParentResourceName() {
    return resourceName;
}