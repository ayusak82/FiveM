local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local isNearNPC = false
local loanData = {}
local playerVehicles = {}
local uiVisible = false
local uiInitialized = false

-- 初期化
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    
    -- ローンデータをリクエスト
    Wait(1000) -- サーバー側の準備のために少し待機
    TriggerServerEvent('ng-loans:server:requestLoanData')
end)

-- 新しいイベントを追加：ローンデータをリクエスト
RegisterNetEvent('ng-loans:client:requestLoanData', function()
    TriggerServerEvent('ng-loans:server:requestLoanData')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

-- ローンNPCの設置
CreateThread(function()
    -- NPCの生成
    RequestModel(GetHashKey(Config.LoanNPC.model))
    while not HasModelLoaded(GetHashKey(Config.LoanNPC.model)) do
        Wait(1)
    end
    
    -- NPCを作成
    local npcPed = CreatePed(4, GetHashKey(Config.LoanNPC.model), Config.LoanNPC.position.x, Config.LoanNPC.position.y, Config.LoanNPC.position.z - 1.0, Config.LoanNPC.position.w, false, true)
    FreezeEntityPosition(npcPed, true)
    SetEntityInvincible(npcPed, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    
    -- アニメーション設定
    if Config.LoanNPC.scenario then
        TaskStartScenarioInPlace(npcPed, Config.LoanNPC.scenario, 0, true)
    end
    
    -- ターゲットの設定
    exports['qb-target']:AddTargetEntity(npcPed, {
        options = {
            {
                type = "client",
                event = "ng-loans:client:openLoanMenu",
                icon = "fas fa-money-bill",
                label = Config.LoanNPC.label,
            }
        },
        distance = 3.0
    })
    
    -- 距離チェック
    CreateThread(function()
        while true do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local npcCoords = vector3(Config.LoanNPC.position.x, Config.LoanNPC.position.y, Config.LoanNPC.position.z)
            local distance = #(playerCoords - npcCoords)
            
            isNearNPC = distance < 10.0
            
            Wait(1000)
        end
    end)
end)

-- ローンメニューを開く
RegisterNetEvent('ng-loans:client:openLoanMenu', function()
    local options = {
        {
            title = "ローンサービス",
            description = "金融サービスを利用する",
            onSelect = function()
                OpenMainLoanMenu()
            end,
            icon = "fas fa-money-bill-wave"
        }
    }
    
    lib.registerContext({
        id = 'loan_service_menu',
        title = '市役所ローンサービス',
        options = options
    })
    
    lib.showContext('loan_service_menu')
end)

-- メインローンメニュー
function OpenMainLoanMenu()
    local options = {
        {
            title = "ローン申請",
            description = "新しくローンを申請する",
            onSelect = function()
                OpenLoanApplicationMenu()
            end,
            icon = "fas fa-hand-holding-usd"
        },
        {
            title = "車両担保ローン",
            description = "車両を担保にローンを申請する",
            onSelect = function()
                OpenVehicleLoanMenu()
            end,
            icon = "fas fa-car"
        },
        {
            title = "ローン返済",
            description = "現在のローンを返済する",
            onSelect = function()
                OpenLoanRepaymentMenu()
            end,
            icon = "fas fa-money-check"
        },
        {
            title = "ローン情報",
            description = "現在のローン情報を確認する",
            onSelect = function()
                OpenLoanInfoMenu()
            end,
            icon = "fas fa-info-circle"
        },
        {
            title = "ウェブインターフェース",
            description = "高度なウェブインターフェースを開く",
            onSelect = function()
                TriggerEvent('ng-loans:client:openAdvancedUI', 'loans')
            end,
            icon = "fas fa-desktop"
        }
    }
    
    lib.registerContext({
        id = 'main_loan_menu',
        title = 'ローンサービス',
        options = options
    })
    
    lib.showContext('main_loan_menu')
end

-- ローン申請メニュー
function OpenLoanApplicationMenu()
    local input = lib.inputDialog('ローン申請', {
        {type = 'number', label = '申請金額 ($)', description = Config.Loans.standard.minAmount..'ドルから'..Config.Loans.standard.maxAmount..'ドルまで', icon = 'dollar-sign', min = Config.Loans.standard.minAmount, max = Config.Loans.standard.maxAmount, default = Config.Loans.standard.minAmount},
        {type = 'number', label = '返済期間 (日)', description = '1日から'..Config.Loans.standard.maxDays..'日まで', icon = 'calendar', min = 1, max = Config.Loans.standard.maxDays, default = Config.Loans.standard.maxDays}
    })
    
    if input then
        local amount = input[1]
        local days = input[2]
        
        -- 確認ダイアログ
        local interest = amount * Config.Loans.standard.interestRate
        local totalRepayment = amount + interest
        
        local alert = lib.alertDialog({
            header = 'ローン申請確認',
            content = string.format([[
                申請金額: $%s
                利息 (%.1f%%): $%s
                返済総額: $%s
                返済期間: %s日
                
                期日内に返済できない場合、延滞利息が日割りで発生します。この条件でローンを申請しますか？
            ]], amount, Config.Loans.standard.interestRate * 100, interest, totalRepayment, days),
            centered = true,
            cancel = true
        })
        
        if alert == 'confirm' then
            TriggerServerEvent('ng-loans:server:requestLoan', amount, days)
        end
    end
end

-- 車両担保ローンメニュー
function OpenVehicleLoanMenu()
    -- サーバーに車両リストをリクエスト
    TriggerServerEvent('ng-loans:server:getPlayerVehicles')
end

-- 車両リスト受信イベント
RegisterNetEvent('ng-loans:client:receivePlayerVehicles', function(vehicles)
    playerVehicles = vehicles
    
    -- UI表示中の場合、UI側に更新を通知
    if uiVisible then
        SendNUIMessage({
            action = "updateVehicles",
            vehicles = playerVehicles
        })
    end
    
    -- 以下は既存のコード
    if #vehicles == 0 then
        lib.notify({
            title = '車両なし',
            description = '担保に設定できる車両がありません。',
            type = 'error'
        })
        return
    end
    
    local options = {}
    
    for i, vehicle in ipairs(vehicles) do
        local vehicleLabel = GetLabelText(GetDisplayNameFromVehicleModel(GetHashKey(vehicle.vehicle)))
        if vehicleLabel == "NULL" then vehicleLabel = vehicle.vehicle end
        
        table.insert(options, {
            title = vehicleLabel,
            description = '車両番号: '..vehicle.plate..' | 最大ローン額: $'..vehicle.maxLoan,
            onSelect = function()
                OpenVehicleLoanApplication(vehicle)
            end,
            metadata = {
                {label = '車両モデル', value = vehicle.vehicle},
                {label = '車両番号', value = vehicle.plate},
                {label = '最大ローン額', value = '$'..vehicle.maxLoan}
            }
        })
    end
    
    lib.registerContext({
        id = 'vehicle_loan_menu',
        title = '車両担保ローン',
        options = options
    })
    
    lib.showContext('vehicle_loan_menu')
end)

-- 車両担保ローン申請画面
function OpenVehicleLoanApplication(vehicle)
    local vehicleLabel = GetLabelText(GetDisplayNameFromVehicleModel(GetHashKey(vehicle.vehicle)))
    if vehicleLabel == "NULL" then vehicleLabel = vehicle.vehicle end
    
    local input = lib.inputDialog(vehicleLabel..' - 担保ローン申請', {
        {type = 'number', label = '申請金額 ($)', description = '最大 $'..vehicle.maxLoan..'まで', icon = 'dollar-sign', min = 1000, max = vehicle.maxLoan, default = math.floor(vehicle.maxLoan / 2)},
        {type = 'number', label = '返済期間 (日)', description = '1日から'..Config.Loans.vehicle.maxDays..'日まで', icon = 'calendar', min = 1, max = Config.Loans.vehicle.maxDays, default = 7}
    })
    
    if input then
        local amount = input[1]
        local days = input[2]
        
        -- 確認ダイアログ
        local interest = amount * Config.Loans.vehicle.interestRate
        local totalRepayment = amount + interest
        
        local alert = lib.alertDialog({
            header = '車両担保ローン申請確認',
            content = string.format([[
                車両: %s (%s)
                申請金額: $%s
                利息 (%.1f%%): $%s
                返済総額: $%s
                返済期間: %s日
                
                期日内に返済できない場合、車両が没収される可能性があります。この条件でローンを申請しますか？
            ]], vehicleLabel, vehicle.plate, amount, Config.Loans.vehicle.interestRate * 100, interest, totalRepayment, days),
            centered = true,
            cancel = true
        })
        
        if alert == 'confirm' then
            TriggerServerEvent('ng-loans:server:requestVehicleLoan', vehicle.plate, vehicle.vehicle, amount, days)
        end
    end
end

-- ローン返済メニュー
function OpenLoanRepaymentMenu()
    if #loanData == 0 then
        lib.notify({
            title = 'ローンなし',
            description = '現在アクティブなローンはありません。',
            type = 'error'
        })
        return
    end
    
    local options = {}
    
    for _, loan in ipairs(loanData) do
        local loanType = "通常ローン"
        local metadata = {
            {label = '残額', value = '$'..loan.remaining},
            {label = '返済期限', value = FormatDate(loan.due_date)}
        }
        
        -- 車両担保ローンの場合、追加情報を表示
        if loan.vehicleData then
            loanType = "車両担保ローン"
            local vehicleLabel = GetLabelText(GetDisplayNameFromVehicleModel(GetHashKey(loan.vehicleData.vehicle_model)))
            if vehicleLabel == "NULL" then vehicleLabel = loan.vehicleData.vehicle_model end
            
            table.insert(metadata, {label = '担保車両', value = vehicleLabel})
            table.insert(metadata, {label = '車両番号', value = loan.vehicleData.plate})
        end
        
        table.insert(options, {
            title = loanType..' - $'..loan.amount,
            description = '残額: $'..loan.remaining..' | 返済期限: '..FormatDate(loan.due_date),
            onSelect = function()
                OpenLoanRepaymentAmount(loan)
            end,
            metadata = metadata
        })
    end
    
    lib.registerContext({
        id = 'loan_repayment_menu',
        title = 'ローン返済',
        options = options
    })
    
    lib.showContext('loan_repayment_menu')
end

-- ローン返済額入力画面
function OpenLoanRepaymentAmount(loan)
    local loanType = loan.vehicleData and "車両担保ローン" or "通常ローン"
    
    local input = lib.inputDialog(loanType..' - 返済', {
        {type = 'number', label = '返済額 ($)', description = '最大 $'..loan.remaining..'まで', icon = 'dollar-sign', min = 1, max = loan.remaining, default = loan.remaining}
    })
    
    if input then
        local amount = input[1]
        
        -- 確認ダイアログ
        local alert = lib.alertDialog({
            header = 'ローン返済確認',
            content = string.format([[
                返済額: $%s
                返済後残額: $%s
                
                この金額を返済しますか？
            ]], amount, loan.remaining - amount),
            centered = true,
            cancel = true
        })
        
        if alert == 'confirm' then
            TriggerServerEvent('ng-loans:server:repayLoan', loan.id, amount)
        end
    end
end

-- ローン情報メニュー
function OpenLoanInfoMenu()
    if #loanData == 0 then
        lib.notify({
            title = 'ローン情報',
            description = '現在アクティブなローンはありません。',
            type = 'info'
        })
        return
    end
    
    local options = {}
    
    for _, loan in ipairs(loanData) do
        local loanType = "通常ローン"
        local metadata = {
            {label = '借入額', value = '$'..loan.amount},
            {label = '残額', value = '$'..loan.remaining},
            {label = '利率', value = (loan.interest * 100)..'%'},
            {label = '借入日', value = FormatDate(loan.date_taken)},
            {label = '返済期限', value = FormatDate(loan.due_date)}
        }
        
        -- 日付の差分を計算 (FiveM環境に合わせて簡略化)
        local daysLeft = 0 -- デフォルト値
        local dueDate = loan.due_date
        if type(dueDate) == 'string' then
            -- 日付文字列からおおよその残り日数を計算
            local year, month, day = dueDate:match("(%d+)-(%d+)-(%d+)")
            if year and month and day then
                -- 現在の日付
                local curTime = GetGameTimer() / 1000 / 60 / 60 / 24 -- 日単位の概算時間
                local dueTime = tonumber(day) -- 簡略化のため日のみ使用
                daysLeft = dueTime - math.floor(curTime % 30) -- 月を30日固定と仮定
            end
        end
        
        if daysLeft < 0 then
            table.insert(metadata, {label = '延滞日数', value = math.abs(daysLeft)..'日', color = 'red'})
        else
            table.insert(metadata, {label = '残り日数', value = daysLeft..'日'})
        end
        
        -- 車両担保ローンの場合、追加情報を表示
        if loan.vehicleData then
            loanType = "車両担保ローン"
            local vehicleLabel = GetLabelText(GetDisplayNameFromVehicleModel(GetHashKey(loan.vehicleData.vehicle_model)))
            if vehicleLabel == "NULL" then vehicleLabel = loan.vehicleData.vehicle_model end
            
            table.insert(metadata, {label = '担保車両', value = vehicleLabel})
            table.insert(metadata, {label = '車両番号', value = loan.vehicleData.plate})
            
            -- 延滞警告
            if daysLeft < 0 then
                table.insert(metadata, {label = '注意', value = '7日以上の延滞で車両没収', color = 'red'})
            end
        end
        
        table.insert(options, {
            title = loanType..' - $'..loan.amount,
            description = '残額: $'..loan.remaining..' | 返済期限: '..FormatDate(loan.due_date),
            metadata = metadata
        })
    end
    
    lib.registerContext({
        id = 'loan_info_menu',
        title = 'ローン情報',
        options = options
    })
    
    lib.showContext('loan_info_menu')
end

-- サーバーからローンデータを受信
RegisterNetEvent('ng-loans:client:receiveLoanData', function(loans)
    loanData = loans or {}
    print("Received " .. #loanData .. " loans from server")
    
    -- ローンデータを受信したらUIが初期化されていないなら通知
    if not uiInitialized and #loanData > 0 then
        lib.notify({
            title = 'ローン情報',
            description = #loanData .. ' 件のローンデータを読み込みました',
            type = 'info'
        })
        uiInitialized = true
    end
    
    -- UI表示中の場合、UI側に更新を通知
    if uiVisible then
        SendNUIMessage({
            action = "updateLoans",
            loans = loanData
        })
    end
end)

-- クライアント側で車両クラスを取得するイベント
RegisterNetEvent('ng-loans:client:getVehicleClass', function(model)
    local vehicleHash = GetHashKey(model)
    local vehicleClass = 1 -- デフォルトはセダン
    
    if IsModelInCdimage(vehicleHash) then
        vehicleClass = GetVehicleClassFromName(vehicleHash)
    end
    
    TriggerServerEvent('ng-loans:server:setVehicleClass', model, vehicleClass)
end)

-- 日付フォーマット関数
function FormatDate(dateString)
    if type(dateString) == 'string' then
        local year, month, day, hour, min, sec = dateString:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
        if year and month and day then
            return string.format("%04d/%02d/%02d %02d:%02d", year, month, day, hour or 0, min or 0)
        end
    elseif type(dateString) == 'number' then
        -- FiveMでは直接os.date('*t', timestamp)が使えない場合があるため、別の方法で表示
        return "期限あり" -- 単純化のため、一時的に固定文字列を返す
    end
    return "不明な日付"
end

-- UI関連の機能
-- UIを表示
function ShowLoanUI(data)
    SendNUIMessage({
        action = "show",
        data = data
    })
    SetNuiFocus(true, true)
    uiVisible = true
end

-- UIを非表示
function HideLoanUI()
    SendNUIMessage({
        action = "hide"
    })
    SetNuiFocus(false, false)
    uiVisible = false
end

-- NUI Callback: UIを閉じる
RegisterNUICallback('closeUI', function(data, cb)
    HideLoanUI()
    cb('ok')
end)

-- NUI Callback: ローン申請
RegisterNUICallback('applyLoan', function(data, cb)
    TriggerServerEvent('ng-loans:server:requestLoan', data.amount, data.days)
    cb('ok')
end)

-- NUI Callback: 車両担保ローン申請
RegisterNUICallback('applyVehicleLoan', function(data, cb)
    TriggerServerEvent('ng-loans:server:requestVehicleLoan', data.plate, data.model, data.amount, data.days)
    cb('ok')
end)

-- NUI Callback: ローン返済
RegisterNUICallback('repayLoan', function(data, cb)
    TriggerServerEvent('ng-loans:server:repayLoan', data.loanId, data.amount)
    cb('ok')
end)

-- NUI Callback: プレイヤーの車両リストを取得
RegisterNUICallback('getPlayerVehicles', function(data, cb)
    TriggerServerEvent('ng-loans:server:getPlayerVehicles')
    -- コールバックは車両データ受信イベントで呼び出す
end)

-- 高度なUIを表示するイベント
RegisterNetEvent('ng-loans:client:openAdvancedUI', function(tab)
    tab = tab or 'loans'
    
    -- ローンデータと車両データを送信
    ShowLoanUI({
        loans = loanData,
        vehicles = playerVehicles,
        activeTab = tab,
        config = {
            standardLoan = Config.Loans.standard,
            vehicleLoan = Config.Loans.vehicle
        }
    })
end)

-- NUI Callback: ローンデータをリロード
RegisterNUICallback('reloadLoans', function(data, cb)
    TriggerServerEvent('ng-loans:server:requestLoanData')
    cb('ok')
end)

-- NUI Callback: 車両データをリロード
RegisterNUICallback('reloadVehicles', function(data, cb)
    TriggerServerEvent('ng-loans:server:getPlayerVehicles')
    cb('ok')
end)

-- ESCキーでUIを閉じる
CreateThread(function()
    while true do
        if uiVisible then
            if IsControlJustPressed(0, 177) then -- 177 = ESCキー
                HideLoanUI()
            end
        end
        Wait(0)
    end
end)

-- 新しい関数: フレーム開始時にデータをリクエスト
CreateThread(function()
    -- リソース起動時、少し待ってからデータをリクエスト
    Wait(3000)
    TriggerServerEvent('ng-loans:server:requestLoanData')
    
    -- 5分ごとにデータを更新 (自動更新)
    while true do
        Wait(300000) -- 5分 = 300000ms
        if isNearNPC then -- NPCの近くにいる場合のみ更新
            TriggerServerEvent('ng-loans:server:requestLoanData')
        end
    end
end)