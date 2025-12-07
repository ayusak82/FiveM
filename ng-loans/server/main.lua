local QBCore = exports['qb-core']:GetCoreObject()

-- テーブルの初期化
MySQL.ready(function()
    -- 一般ローンテーブル
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS ]]..Config.DatabaseTables.loans..[[ (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50) NOT NULL,
            amount INT NOT NULL,
            remaining INT NOT NULL,
            interest FLOAT NOT NULL,
            date_taken TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            due_date TIMESTAMP NOT NULL,
            status INT DEFAULT 0
        )
    ]], {})

    -- 車両担保ローンテーブル
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS ]]..Config.DatabaseTables.vehicleLoans..[[ (
            id INT AUTO_INCREMENT PRIMARY KEY,
            loan_id INT NOT NULL,
            plate VARCHAR(8) NOT NULL,
            vehicle_model VARCHAR(50) NOT NULL,
            FOREIGN KEY (loan_id) REFERENCES ]]..Config.DatabaseTables.loans..[[ (id) ON DELETE CASCADE
        )
    ]], {})
end)

-- プレイヤーがログインしたときにローン情報をクライアントに送信
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        -- 少し遅延を入れて、他のリソースがロードされる時間を確保
        Wait(1000)
        SendPlayerLoanData(src, Player.PlayerData.citizenid)
    end
end)

-- プレイヤー再接続時のイベントハンドラを追加
AddEventHandler('playerJoining', function()
    local src = source
    -- プレイヤーデータが読み込まれるまで少し待機
    Wait(3000)
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        SendPlayerLoanData(src, Player.PlayerData.citizenid)
    end
end)

-- ローン情報をクライアントに送信する関数
function SendPlayerLoanData(src, citizenid)
    if not src or not citizenid then
        print("Error in SendPlayerLoanData: Invalid source or citizenid")
        return
    end
    
    print("Fetching loan data for player: " .. citizenid)
    
    -- アクティブなローンを取得
    MySQL.Async.fetchAll('SELECT * FROM '..Config.DatabaseTables.loans..' WHERE citizenid = ? AND status = ?', {
        citizenid, 
        Config.LoanStatus.ACTIVE
    }, function(results)
        -- エラー処理を追加
        if not results then
            print("Error fetching loans for player: " .. citizenid)
            TriggerClientEvent('ng-loans:client:receiveLoanData', src, {})
            return
        end
        
        if #results > 0 then
            local loans = {}
            local processed = 0
            
            for _, loan in ipairs(results) do
                -- データの整合性チェック
                if loan.id then
                    -- 車両担保情報を取得
                    MySQL.Async.fetchAll('SELECT * FROM '..Config.DatabaseTables.vehicleLoans..' WHERE loan_id = ?', {
                        loan.id
                    }, function(vehicleData)
                        -- vehicleDataのnilチェック
                        if vehicleData then
                            loan.vehicleData = vehicleData[1] or nil
                        else
                            loan.vehicleData = nil
                        end
                        
                        table.insert(loans, loan)
                        processed = processed + 1
                        
                        -- 全てのローン情報が集まったらクライアントに送信
                        if processed == #results then
                            print("Sending " .. #loans .. " loans to player: " .. citizenid)
                            TriggerClientEvent('ng-loans:client:receiveLoanData', src, loans)
                        end
                    end)
                else
                    processed = processed + 1
                    print("Invalid loan data found for player: " .. citizenid)
                    
                    if processed == #results then
                        TriggerClientEvent('ng-loans:client:receiveLoanData', src, loans)
                    end
                end
            end
        else
            -- ローンがない場合は空の配列を送信
            print("No active loans found for player: " .. citizenid)
            TriggerClientEvent('ng-loans:client:receiveLoanData', src, {})
        end
    end)
end

-- 車両の担保設定時に状態を更新する関数
function SetVehicleAsCollateral(plate, isCollateral)
    local updateData = {}
    
    if isCollateral then
        -- 担保設定時：ガレージにロックし、レッカー業者に没収されている状態に設定
        updateData = {
            in_garage = 1,      -- ガレージ内に
            impound = 1,        -- レッカー(没収)状態
            state = 0           -- 状態を「使用不可」に
        }
    else
        -- 担保解除時：通常状態に戻す
        updateData = {
            in_garage = 1,      -- ガレージ内に（そのまま）
            impound = 0,        -- レッカー解除
            state = 1           -- 状態を「使用可能」に
        }
    end
    
    -- SQLクエリの構築
    local query = 'UPDATE player_vehicles SET in_garage = ?, impound = ?, state = ? WHERE plate = ?'
    local params = {updateData.in_garage, updateData.impound, updateData.state, plate}
    
    MySQL.Async.execute(query, params, function(rowsChanged)
        if rowsChanged > 0 then
            print('車両 ' .. plate .. ' の担保状態を更新しました: ' .. (isCollateral and '担保設定' or '担保解除'))
        else
            print('車両 ' .. plate .. ' の状態更新に失敗しました')
        end
    end)
end

-- 新規ローン作成リクエスト処理
RegisterNetEvent('ng-loans:server:requestLoan', function(amount, days)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local loanConfig = Config.Loans.standard
    
    -- 金額の検証
    if amount < loanConfig.minAmount or amount > loanConfig.maxAmount then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '申請エラー',
            description = '申請額は'..loanConfig.minAmount..'ドルから'..loanConfig.maxAmount..'ドルの間である必要があります。',
            type = 'error'
        })
        return
    end
    
    -- 日数の検証
    if days <= 0 or days > loanConfig.maxDays then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '申請エラー',
            description = '返済期間は1日から'..loanConfig.maxDays..'日の間である必要があります。',
            type = 'error'
        })
        return
    end
    
    -- 既存のアクティブなローン数をチェック
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM '..Config.DatabaseTables.loans..' WHERE citizenid = ? AND status = ?', {
        citizenid,
        Config.LoanStatus.ACTIVE
    }, function(count)
        if count and count >= 3 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = '申請エラー',
                description = 'すでに3つのアクティブなローンがあります。新しいローンを申請する前に既存のローンを返済してください。',
                type = 'error'
            })
            return
        end
        
        -- ローンの作成処理
        local dueDate = os.time() + (days * 86400) -- 現在時刻 + 日数 * 1日の秒数
        
        MySQL.Async.insert('INSERT INTO '..Config.DatabaseTables.loans..' (citizenid, amount, remaining, interest, due_date, status) VALUES (?, ?, ?, ?, FROM_UNIXTIME(?), ?)', {
            citizenid,
            amount,
            amount,
            loanConfig.interestRate,
            dueDate,
            Config.LoanStatus.ACTIVE
        }, function(loanId)
            if loanId and loanId > 0 then
                -- お金を追加
                Player.Functions.AddMoney('bank', amount, 'loan-received')
                
                -- 通知
                TriggerClientEvent('ox_lib:notify', src, {
                    title = Config.Notifications.loanCreated.title,
                    description = string.format(Config.Notifications.loanCreated.description, amount),
                    type = Config.Notifications.loanCreated.type
                })
                
                -- 更新されたローン情報を送信
                SendPlayerLoanData(src, citizenid)
            end
        end)
    end)
end)

-- 車両担保ローン作成リクエスト処理
RegisterNetEvent('ng-loans:server:requestVehicleLoan', function(plate, model, amount, days)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local loanConfig = Config.Loans.vehicle
    
    -- 車両の所有権確認
    MySQL.Async.fetchSingle('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?', {
        plate,
        citizenid
    }, function(vehicle)
        if not vehicle then
            TriggerClientEvent('ox_lib:notify', src, Config.Notifications.vehicleNotOwned)
            return
        end
        
        -- 車両が既に担保設定されているか、レッカー状態か確認
        if vehicle.impound == 1 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = '担保設定エラー',
                description = 'この車両は現在レッカー状態のため担保にできません。',
                type = 'error'
            })
            return
        end
        
        -- 既に担保設定されていないか確認
        MySQL.Async.fetchScalar([[
            SELECT vl.id FROM ]]..Config.DatabaseTables.vehicleLoans..[[ vl
            JOIN ]]..Config.DatabaseTables.loans..[[ l ON vl.loan_id = l.id
            WHERE vl.plate = ? AND l.status = ?
        ]], {
            plate,
            Config.LoanStatus.ACTIVE
        }, function(existingLoan)
            if existingLoan then
                TriggerClientEvent('ox_lib:notify', src, Config.Notifications.vehicleAlreadyLoaned)
                return
            end
            
            -- 車両クラスに基づく最大ローン額の確認
            local vehicleClass = GetVehicleClassFromModel(model)
            local maxLoanForClass = Config.Loans.vehicle.vehicleClasses[vehicleClass] or 0
            
            if amount <= 0 or amount > maxLoanForClass then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = '申請エラー',
                    description = 'この車両で借りられる最大額は'..maxLoanForClass..'ドルです。',
                    type = 'error'
                })
                return
            end
            
            -- 日数の検証
            if days <= 0 or days > loanConfig.maxDays then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = '申請エラー',
                    description = '返済期間は1日から'..loanConfig.maxDays..'日の間である必要があります。',
                    type = 'error'
                })
                return
            end
            
            -- ローンの作成処理
            local dueDate = os.time() + (days * 86400)
            
            MySQL.Async.insert('INSERT INTO '..Config.DatabaseTables.loans..' (citizenid, amount, remaining, interest, due_date, status) VALUES (?, ?, ?, ?, FROM_UNIXTIME(?), ?)', {
                citizenid,
                amount,
                amount,
                loanConfig.interestRate,
                dueDate,
                Config.LoanStatus.ACTIVE
            }, function(loanId)
                if loanId and loanId > 0 then
                    -- 車両担保情報を登録
                    MySQL.Async.insert('INSERT INTO '..Config.DatabaseTables.vehicleLoans..' (loan_id, plate, vehicle_model) VALUES (?, ?, ?)', {
                        loanId,
                        plate,
                        model
                    }, function()
                        -- 車両の状態を更新（担保設定状態に）
                        SetVehicleAsCollateral(plate, true)
                        
                        -- お金を追加
                        Player.Functions.AddMoney('bank', amount, 'vehicle-loan-received')
                        
                        -- 通知
                        TriggerClientEvent('ox_lib:notify', src, {
                            title = Config.Notifications.vehicleLoanCreated.title,
                            description = string.format(Config.Notifications.vehicleLoanCreated.description, amount),
                            type = Config.Notifications.vehicleLoanCreated.type
                        })
                        
                        -- 更新されたローン情報を送信
                        SendPlayerLoanData(src, citizenid)
                    end)
                end
            end)
        end)
    end)
end)

-- ローン返済処理
RegisterNetEvent('ng-loans:server:repayLoan', function(loanId, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- ローン情報を取得
    MySQL.Async.fetchSingle('SELECT * FROM '..Config.DatabaseTables.loans..' WHERE id = ? AND status = ?', {
        loanId,
        Config.LoanStatus.ACTIVE
    }, function(loan)
        if not loan then
            TriggerClientEvent('ox_lib:notify', src, {
                title = '返済エラー',
                description = '指定されたローンは存在しないか、すでに返済済みです。',
                type = 'error'
            })
            return
        end
        
        -- プレイヤーの所有確認
        if loan.citizenid ~= Player.PlayerData.citizenid then
            TriggerClientEvent('ox_lib:notify', src, {
                title = '返済エラー',
                description = 'このローンはあなたのものではありません。',
                type = 'error'
            })
            return
        end
        
        -- 返済額の検証
        if amount <= 0 or amount > loan.remaining then
            TriggerClientEvent('ox_lib:notify', src, {
                title = '返済エラー',
                description = '有効な返済額を入力してください。',
                type = 'error'
            })
            return
        end
        
        -- 残高の確認
        if Player.PlayerData.money.bank < amount then
            TriggerClientEvent('ox_lib:notify', src, Config.Notifications.insufficientFunds)
            return
        end
        
        -- 返済処理
        Player.Functions.RemoveMoney('bank', amount, 'loan-repayment')
        
        local newRemaining = loan.remaining - amount
        local newStatus = newRemaining <= 0 and Config.LoanStatus.PAID or Config.LoanStatus.ACTIVE
        
        MySQL.Async.execute('UPDATE '..Config.DatabaseTables.loans..' SET remaining = ?, status = ? WHERE id = ?', {
            newRemaining,
            newStatus,
            loanId
        }, function()
            -- 完済の場合
            if newStatus == Config.LoanStatus.PAID then
                -- 車両担保の場合、車両状態を通常に戻す
                MySQL.Async.fetchSingle('SELECT * FROM '..Config.DatabaseTables.vehicleLoans..' WHERE loan_id = ?', {
                    loanId
                }, function(vehicleLoan)
                    if vehicleLoan then
                        -- 車両の状態を元に戻す（担保解除）
                        SetVehicleAsCollateral(vehicleLoan.plate, false)
                        
                        TriggerClientEvent('ox_lib:notify', src, {
                            title = "車両担保解除",
                            description = "ローンが完済され、車両の担保が解除されました。",
                            type = "success"
                        })
                    end
                    
                    TriggerClientEvent('ox_lib:notify', src, Config.Notifications.loanRepaid)
                end)
            else
                TriggerClientEvent('ox_lib:notify', src, {
                    title = "ローン返済",
                    description = string.format("%s ドル返済しました。残り %s ドルです。", amount, newRemaining),
                    type = "success"
                })
            end
            
            -- 更新されたローン情報を送信
            SendPlayerLoanData(src, Player.PlayerData.citizenid)
        end)
    end)
end)

-- プレイヤーの全車両取得リクエスト処理
RegisterNetEvent('ng-loans:server:getPlayerVehicles', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    MySQL.Async.fetchAll('SELECT * FROM player_vehicles WHERE citizenid = ?', {
        Player.PlayerData.citizenid
    }, function(vehicles)
        if vehicles and #vehicles > 0 then
            -- 担保設定されている車両を確認
            MySQL.Async.fetchAll([[
                SELECT vl.plate FROM ]]..Config.DatabaseTables.vehicleLoans..[[ vl
                JOIN ]]..Config.DatabaseTables.loans..[[ l ON vl.loan_id = l.id
                WHERE l.status = ?
            ]], {
                Config.LoanStatus.ACTIVE
            }, function(loanedVehicles)
                local loanedPlates = {}
                if loanedVehicles then
                    for _, v in ipairs(loanedVehicles) do
                        loanedPlates[v.plate] = true
                    end
                end
                
                -- 車両情報に担保設定情報を追加
                for _, vehicle in ipairs(vehicles) do
                    -- 車両クラスと最大ローン額を追加
                    local vehicleClass = GetVehicleClassFromModel(vehicle.vehicle)
                    vehicle.maxLoan = Config.Loans.vehicle.vehicleClasses[vehicleClass] or 0
                    
                    -- 担保設定状態を示す
                    if loanedPlates[vehicle.plate] then
                        -- すでに担保設定されている車両は使用不可にする
                        vehicle.impound = 1
                    end
                end
                
                TriggerClientEvent('ng-loans:client:receivePlayerVehicles', src, vehicles)
            end)
        else
            TriggerClientEvent('ng-loans:client:receivePlayerVehicles', src, {})
        end
    end)
end)

-- QBCoreのvehicles.luaから車両クラスを取得する関数
function GetVehicleClassFromModel(model)
    -- モデル名が空か無効な場合は、デフォルト値を返す
    if model == nil or model == '' then
        print("Warning: Empty vehicle model passed to GetVehicleClassFromModel")
        return 1 -- デフォルトはセダン
    end
    
    -- 小文字に変換（QB-Coreは通常小文字でキーを保存している）
    local modelLower = string.lower(model)
    
    -- QB-Coreの共有車両データから情報を取得
    local QBCore = exports['qb-core']:GetCoreObject()
    local vehicles = QBCore.Shared.Vehicles
    
    -- 車両データを見つける
    if vehicles and vehicles[modelLower] then
        -- クラス情報を取得
        local vehicleClass = vehicles[modelLower].category
        
        -- カテゴリからクラスを取得（QB-Coreのカテゴリ名をFiveM車両クラスにマッピング）
        local categoryToClass = {
            ["compacts"] = 0,
            ["sedans"] = 1,
            ["suvs"] = 2,
            ["coupes"] = 3,
            ["muscle"] = 4,
            ["sportsclassics"] = 5,
            ["sports"] = 6,
            ["super"] = 7,
            ["motorcycles"] = 8,
            ["offroad"] = 9,
            ["industrial"] = 10,
            ["utility"] = 11,
            ["vans"] = 12,
            ["cycles"] = 13,
            ["boats"] = 14,
            ["helicopters"] = 15,
            ["planes"] = 16,
            ["service"] = 17,
            ["emergency"] = 18,
            ["military"] = 19,
            ["commercial"] = 20,
            ["trains"] = 21
        }
        
        -- カテゴリが見つかった場合はマッピングしたクラスを返す、見つからない場合はデフォルト値
        if vehicleClass and categoryToClass[vehicleClass] then
            return categoryToClass[vehicleClass]
        end
    end
    
    -- QB-Coreで見つからない場合、Config.Loans.vehicle.vehicleClassesのキーで確認
    -- このマッピングはすでに正しいクラス番号を使用していると仮定
    local highestValue = 0
    local bestClass = 1 -- デフォルトはセダン
    
    -- クラスごとの最大値から最適なクラスを推測
    for class, maxLoan in pairs(Config.Loans.vehicle.vehicleClasses) do
        -- より高価な車両カテゴリの方が適切かもしれない
        if maxLoan > highestValue then
            highestValue = maxLoan
            bestClass = class
        end
    end
    
    -- クラス番号を返す（セダンがデフォルト）
    print("Vehicle model " .. model .. " not found in QB-Core, using default class: " .. bestClass)
    return 1 -- セダンをデフォルトとして返す
end

-- クライアントから返された車両クラス情報を処理するイベントは必要なくなるため削除してもOK
-- ただし、互換性のために残しておくこともできる
RegisterNetEvent('ng-loans:server:setVehicleClass', function(model, vehicleClass)
    -- このイベントは使用しなくなったが、エラー防止のために残す
    print("Note: Using QB-Core vehicle data instead of client response")
end)

-- 毎日のローン処理（遅延利息の適用、担保車両の没収など）
function ProcessDailyLoans()
    -- 返済期限を過ぎたローンを取得
    MySQL.Async.fetchAll('SELECT * FROM '..Config.DatabaseTables.loans..' WHERE status = ? AND due_date < NOW()', {
        Config.LoanStatus.ACTIVE
    }, function(overdueLoans)
        for _, loan in ipairs(overdueLoans) do
            -- 車両担保ローンかどうかを確認
            MySQL.Async.fetchSingle('SELECT * FROM '..Config.DatabaseTables.vehicleLoans..' WHERE loan_id = ?', {
                loan.id
            }, function(vehicleLoan)
                if vehicleLoan then
                    -- 車両担保ローンの場合、延滞から7日経過したら没収処理
                    local dueDate = os.time()
                    if type(loan.due_date) == 'string' then
                        local year, month, day = loan.due_date:match("(%d+)-(%d+)-(%d+)")
                        if year and month and day then
                            dueDate = os.time({year=tonumber(year), month=tonumber(month), day=tonumber(day)})
                        end
                    end
                    
                    local currentTime = os.time()
                    local daysSinceOverdue = math.floor((currentTime - dueDate) / 86400)
                    
                    if daysSinceOverdue >= 7 then
                        -- 車両の没収処理
                        MySQL.Async.execute('UPDATE '..Config.DatabaseTables.loans..' SET status = ? WHERE id = ?', {
                            Config.LoanStatus.SEIZED,
                            loan.id
                        })
                        
                        -- 車両所有権の移転（ここでは所有者変更または削除）
                        MySQL.Async.execute('DELETE FROM player_vehicles WHERE plate = ?', {
                            vehicleLoan.plate
                        })
                        
                        -- プレイヤーへの通知
                        local Player = QBCore.Functions.GetPlayerByCitizenId(loan.citizenid)
                        if Player then
                            TriggerClientEvent('ox_lib:notify', Player.PlayerData.source, Config.Notifications.vehicleSeized)
                        end
                    else
                        -- 延滞利息の適用
                        ApplyLateFees(loan, Config.Loans.vehicle.lateFeeDailyRate)
                    end
                else
                    -- 通常ローンの場合、単に延滞利息を適用
                    ApplyLateFees(loan, Config.Loans.standard.lateFeeDailyRate)
                end
            end)
        end
    end)
    
    -- 返済期限が近いローンの警告通知
    MySQL.Async.fetchAll([[
        SELECT l.* FROM ]]..Config.DatabaseTables.loans..[[ l
        WHERE l.status = ? AND l.due_date BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 2 DAY)
    ]], {
        Config.LoanStatus.ACTIVE
    }, function(warningLoans)
        for _, loan in ipairs(warningLoans) do
            -- プレイヤーIDから直接プレイヤーを探す
            local Player = QBCore.Functions.GetPlayerByCitizenId(loan.citizenid)
            if Player then
                TriggerClientEvent('ox_lib:notify', Player.PlayerData.source, Config.Notifications.loanDefaultWarning)
            end
        end
    end)
end

-- 延滞利息を適用する関数
function ApplyLateFees(loan, dailyRate)
    local lateInterest = loan.remaining * dailyRate
    local newRemaining = loan.remaining + lateInterest
    
    MySQL.Async.execute('UPDATE '..Config.DatabaseTables.loans..' SET remaining = ? WHERE id = ?', {
        newRemaining,
        loan.id
    })
    
    -- プレイヤーへの通知
    local Player = QBCore.Functions.GetPlayerByCitizenId(loan.citizenid)
    if Player then
        TriggerClientEvent('ox_lib:notify', Player.PlayerData.source, {
            title = "延滞利息適用",
            description = string.format("ローン返済が遅れているため、%s ドルの延滞利息が発生しました。", lateInterest),
            type = "error"
        })
    end
end

-- クライアントからのローンデータリクエストを処理
RegisterNetEvent('ng-loans:server:requestLoanData', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        print("Received loan data request from player: " .. Player.PlayerData.citizenid)
        SendPlayerLoanData(src, Player.PlayerData.citizenid)
    else
        print("Invalid player requested loan data, source: " .. src)
    end
end)

-- 1時間ごとにローン処理を実行
CreateThread(function()
    while true do
        ProcessDailyLoans()
        Wait(3600000) -- 1時間 = 3600000ミリ秒
    end
end)

-- サーバー再起動後のデータリロードと強制更新用コマンドを追加
QBCore.Commands.Add('reloadloans', 'ローンデータを再読込します', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        SendPlayerLoanData(src, Player.PlayerData.citizenid)
        TriggerClientEvent('ox_lib:notify', src, {
            title = "ローンデータ更新",
            description = "ローン情報を再読込しました",
            type = "success"
        })
    end
end)