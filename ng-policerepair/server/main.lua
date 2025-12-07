local QBCore = exports['qb-core']:GetCoreObject()

-- デバッグログ関数
local function DebugLog(message)
    if Config.Debug then
        print('^3[ng-policerepair DEBUG] ^7' .. message)
    end
end

-- 車両修理イベント
RegisterServerEvent('ng-policerepair:server:repairVehicle')
AddEventHandler('ng-policerepair:server:repairVehicle', function(netId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then 
        DebugLog('エラー: プレイヤーデータが見つかりません')
        return 
    end
    
    -- 職業チェック
    local allowedJob = false
    for _, job in ipairs(Config.AllowedJobs) do
        if Player.PlayerData.job.name == job then
            allowedJob = true
            break
        end
    end
    
    if not allowedJob then
        DebugLog('エラー: 職業チェック失敗 - ' .. tostring(Player.PlayerData.job.name))
        TriggerClientEvent('ng-policerepair:client:repairComplete', src, false, Config.Notifications.noJob)
        return
    end
    
    -- 車両の存在確認
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then
        DebugLog('エラー: 車両が存在しません')
        TriggerClientEvent('ng-policerepair:client:repairComplete', src, false, Config.Notifications.noVehicle)
        return
    end
    
    -- 警察口座から直接支払い（qb-banking使用）
    DebugLog('警察口座から支払い処理開始...')
    
    local paymentSuccess = false
    if GetResourceState('qb-banking') == 'started' then
        -- qb-bankingが利用可能な場合
        paymentSuccess = exports['qb-banking']:RemoveMoney('police', Config.RepairCost, 'Police Vehicle Repair')
        DebugLog('qb-banking支払い結果: ' .. tostring(paymentSuccess))
    else
        DebugLog('qb-bankingが利用できません、データベース経由で処理')
        -- qb-bankingが利用できない場合、データベース経由
        local result = MySQL.Sync.fetchAll('SELECT amount FROM bank_accounts WHERE account_name = ?', {'police'})
        if result and result[1] and result[1].amount >= Config.RepairCost then
            local updateResult = MySQL.Sync.execute('UPDATE bank_accounts SET amount = amount - ? WHERE account_name = ?', {
                Config.RepairCost, 'police'
            })
            paymentSuccess = updateResult > 0
        end
    end
    
    if not paymentSuccess then
        DebugLog('エラー: 支払い処理に失敗しました')
        TriggerClientEvent('ng-policerepair:client:repairComplete', src, false, string.format(Config.Notifications.noMoney, Config.RepairCost))
        return
    end
    
    DebugLog('支払い処理完了: $' .. Config.RepairCost .. ' が警察口座から引き落とされました')
    
    -- jobアカウントに送金（設定されている場合のみ）
    if Config.AdminAccount and Config.AdminAccount ~= '' then
        AddMoneyToAdmin(Config.RepairCost, 'ポリス車両修理収入')
    else
        DebugLog('送金先アカウントが設定されていません。送金をスキップします。')
    end
    
    -- 車両修理実行
    TriggerClientEvent('ng-policerepair:client:executeRepair', -1, netId)
    
    -- 修理完了通知
    TriggerClientEvent('ng-policerepair:client:repairComplete', src, true, Config.Notifications.success)
    
    -- ログ記録
    print(string.format('[ng-policerepair] プレイヤー %s (%s) が車両を修理しました。費用: $%s', 
        Player.PlayerData.name, Player.PlayerData.citizenid, Config.RepairCost))
end)

-- jobアカウントに送金する関数
function AddMoneyToAdmin(amount, reason)
    DebugLog('jobアカウントへの送金処理開始...')
    
    if GetResourceState('qb-banking') == 'started' then
        -- qb-bankingを使用してjobアカウントに送金
        DebugLog('qb-bankingを使用して' .. Config.AdminAccount .. 'アカウントに送金中...')
        
        local success = exports['qb-banking']:AddMoney(Config.AdminAccount, amount, reason)
        
        if success then
            DebugLog(string.format('%s アカウントに $%s を送金しました（qb-banking経由）', Config.AdminAccount, amount))
        else
            DebugLog(string.format('qb-bankingでの送金に失敗、データベース経由を試行中...'))
            -- qb-bankingが失敗した場合、データベース直接処理
            MySQL.Async.execute('UPDATE bank_accounts SET amount = amount + ? WHERE account_name = ?', {
                amount,
                Config.AdminAccount
            }, function(affectedRows)
                if affectedRows > 0 then
                    DebugLog(string.format('%s アカウントに $%s を送金しました（データベース経由）', Config.AdminAccount, amount))
                else
                    DebugLog(string.format('エラー: %s アカウントが見つかりません', Config.AdminAccount))
                    
                    -- アカウントが存在しない場合、作成を試行
                    if Config.Debug then
                        DebugLog('アカウント作成を試行中...')
                        MySQL.Async.execute('INSERT INTO bank_accounts (account_name, amount, account_type) VALUES (?, ?, ?)', {
                            Config.AdminAccount,
                            amount,
                            'business'
                        }, function(insertId)
                            if insertId then
                                DebugLog(string.format('%s アカウントを作成し、$%s を入金しました', Config.AdminAccount, amount))
                            else
                                DebugLog('アカウント作成に失敗しました')
                            end
                        end)
                    end
                end
            end)
        end
    else
        -- qb-bankingが利用できない場合、データベース直接処理
        DebugLog('qb-bankingが利用できません。データベース経由で送金中...')
        MySQL.Async.execute('UPDATE bank_accounts SET amount = amount + ? WHERE account_name = ?', {
            amount,
            Config.AdminAccount
        }, function(affectedRows)
            if affectedRows > 0 then
                DebugLog(string.format('%s アカウントに $%s を送金しました（データベース経由）', Config.AdminAccount, amount))
            else
                DebugLog(string.format('エラー: %s アカウントが見つかりません', Config.AdminAccount))
                
                -- デバッグモードの場合、利用可能なアカウントを表示
                if Config.Debug then
                    MySQL.Async.fetchAll('SELECT account_name, amount FROM bank_accounts WHERE account_type = ? LIMIT 10', {'business'}, function(accounts)
                        if accounts then
                            DebugLog('利用可能なbusinessアカウント:')
                            for _, account in ipairs(accounts) do
                                DebugLog(string.format('- %s: $%s', account.account_name, account.amount))
                            end
                        end
                    end)
                end
            end
        end)
    end
end

-- 車両修理実行（全クライアントに送信）
RegisterNetEvent('ng-policerepair:client:executeRepair')
AddEventHandler('ng-policerepair:client:executeRepair', function(netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) then
        -- 車両の修理
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleUndriveable(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, false)
        
        -- 燃料を満タンにする（ox_fuelがある場合）
        if GetResourceState('ox_fuel') == 'started' then
            exports.ox_fuel:SetFuel(vehicle, 100.0)
        end
        
        DebugLog('車両修理実行完了: NetID ' .. netId)
    end
end)

-- サーバー起動時のメッセージ
CreateThread(function()
    Wait(1000) -- 他のリソースの読み込み待ち
    print('^2[ng-policerepair] ^7スクリプトが正常に開始されました')
    print('^2[ng-policerepair] ^7修理費用: ^3$' .. Config.RepairCost)
    print('^2[ng-policerepair] ^7管理者アカウント: ^3' .. Config.AdminAccount)
    print('^2[ng-policerepair] ^7許可された職業: ^3' .. table.concat(Config.AllowedJobs, ', '))
    
    -- qb-bankingの状態をチェック
    if GetResourceState('qb-banking') == 'started' then
        print('^2[ng-policerepair] ^7qb-bankingが正常に読み込まれています')
        
        -- デバッグモードの場合、警察口座をテスト
        if Config.Debug then
            print('^3[ng-policerepair] ^7警察口座の存在確認中...')
            local testResult = pcall(function()
                return exports['qb-banking']:GetAccount('police')
            end)
            if testResult then
                print('^2[ng-policerepair] ^7qb-bankingのexportが正常に動作しています')
            else
                print('^1[ng-policerepair] ^7警告: qb-bankingのexportでエラーが発生しました')
            end
        end
    else
        print('^1[ng-policerepair] ^7警告: qb-bankingが開始されていません')
    end
    
    if Config.Debug then
        print('^3[ng-policerepair] ^7デバッグモードが有効です')
    end
end)