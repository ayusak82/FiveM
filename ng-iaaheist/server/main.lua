local QBCore = exports['qb-core']:GetCoreObject()

-- グローバル変数
local globalHeistActive = false -- グローバル強盗状態
local heistParticipants = {} -- 強盗参加者リスト
local heistCooldown = 0 -- グローバルクールダウン
local heistStartedBy = nil -- 強盗開始者
local hackedDataPoints = {} -- ハッキング済みデータポイント
local spawnedNPCs = {} -- スポーン済みNPC

-- データベース初期化
CreateThread(function()
    MySQL.ready(function()
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `ng_iaaheist` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `citizenid` varchar(50) NOT NULL,
                `total_heists` int(11) DEFAULT 0,
                `total_earned` int(11) DEFAULT 0,
                `last_heist` timestamp NULL DEFAULT NULL,
                PRIMARY KEY (`id`),
                UNIQUE KEY `citizenid` (`citizenid`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]], {})
    end)
end)

-- グローバル強盗状態チェック
QBCore.Functions.CreateCallback('ng-iaaheist:server:GetHeistStatus', function(source, cb)
    cb({
        active = globalHeistActive,
        participants = heistParticipants,
        startedBy = heistStartedBy,
        hackedDataPoints = hackedDataPoints
    })
end)

-- 強盗開始
RegisterNetEvent('ng-iaaheist:server:StartHeist', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- グローバルクールダウンチェック
    if heistCooldown > os.time() then
        local remaining = heistCooldown - os.time()
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'クールダウン中',
            description = '次の強盗まで ' .. math.ceil(remaining / 60) .. ' 分待ってください',
            type = 'error'
        })
        return
    end
    
    -- 既に強盗が進行中かチェック
    if globalHeistActive then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'エラー',
            description = '既に強盗が進行中です',
            type = 'error'
        })
        return
    end
    
    -- 最低プレイヤー数チェック
    local onlinePlayers = #QBCore.Functions.GetPlayers()
    if onlinePlayers < Config.MinPlayers then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'エラー',
            description = '最低 ' .. Config.MinPlayers .. ' 人のプレイヤーが必要です',
            type = 'error'
        })
        return
    end
    
    -- 必要アイテムチェック
    local hasLaptop = Player.Functions.GetItemByName(Config.Items.requiredItem)
    if not hasLaptop then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'アイテム不足',
            description = 'ハッキング用ラップトップが必要です',
            type = 'error'
        })
        return
    end
    
    -- グローバル強盗開始
    globalHeistActive = true
    heistStartedBy = {
        source = src,
        citizenid = citizenid,
        name = Player.PlayerData.name,
        startTime = os.time()
    }
    heistParticipants = {}
    hackedDataPoints = {} -- ハッキング状態をリセット
    spawnedNPCs = {} -- NPC状態をリセット
    
    -- 全プレイヤーに強盗開始を通知
    TriggerClientEvent('ng-iaaheist:client:GlobalHeistStarted', -1)
    
    -- ログ記録
    if Config.Debug then
        print('[ng-iaaheist] Global heist started by: ' .. Player.PlayerData.name .. ' (' .. citizenid .. ')')
    end
end)

-- 強盗参加
RegisterNetEvent('ng-iaaheist:server:JoinHeist', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    if not globalHeistActive then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- 既に参加しているかチェック
    if heistParticipants[citizenid] then
        return -- 既に参加済み
    end
    
    -- 参加者リストに追加
    heistParticipants[citizenid] = {
        source = src,
        name = Player.PlayerData.name,
        joinTime = os.time(),
        dataCollected = 0
    }
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'IAA強盗',
        description = '強盗に参加しました',
        type = 'inform'
    })
    
    if Config.Debug then
        print('[ng-iaaheist] Player joined heist: ' .. Player.PlayerData.name)
    end
end)

-- アイテム所持チェック
QBCore.Functions.CreateCallback('ng-iaaheist:server:HasItem', function(source, cb, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false)
        return
    end
    
    local hasItem = Player.Functions.GetItemByName(item)
    cb(hasItem and hasItem.amount > 0)
end)

-- データポイントハッキング
RegisterNetEvent('ng-iaaheist:server:HackDataPoint', function(pointId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    if not globalHeistActive then return end
    if hackedDataPoints[pointId] then return end -- 既にハッキング済み
    
    local citizenid = Player.PlayerData.citizenid
    
    -- 参加者でない場合は参加させる
    if not heistParticipants[citizenid] then
        heistParticipants[citizenid] = {
            source = src,
            name = Player.PlayerData.name,
            joinTime = os.time(),
            dataCollected = 0
        }
    end
    
    -- ハッキング状態を記録
    hackedDataPoints[pointId] = {
        hackedBy = citizenid,
        playerName = Player.PlayerData.name,
        timestamp = os.time()
    }
    
    -- 全プレイヤーにハッキング状態を同期
    TriggerClientEvent('ng-iaaheist:client:SyncDataPoint', -1, pointId, true)
    
    if Config.Debug then
        print('[ng-iaaheist] Data point ' .. pointId .. ' hacked by: ' .. Player.PlayerData.name)
    end
end)

-- データアイテム付与
RegisterNetEvent('ng-iaaheist:server:GiveData', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    if not globalHeistActive then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- 参加者でない場合は参加させる
    if not heistParticipants[citizenid] then
        heistParticipants[citizenid] = {
            source = src,
            name = Player.PlayerData.name,
            joinTime = os.time(),
            dataCollected = 0
        }
    end
    
    -- データアイテム付与
    local added = Player.Functions.AddItem(Config.Items.dataItem, 1, false, {
        description = 'IAA機密データ',
        type = 'heist_data',
        timestamp = os.time()
    })
    
    if added then
        heistParticipants[citizenid].dataCollected = heistParticipants[citizenid].dataCollected + 1
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.Items.dataItem], 'add', 1)
        
        if Config.Debug then
            print('[ng-iaaheist] Data given to: ' .. Player.PlayerData.name .. ' (Total: ' .. heistParticipants[citizenid].dataCollected .. ')')
        end
    end
end)

-- NPC同期システム
RegisterNetEvent('ng-iaaheist:server:RequestNPCSync', function()
    local src = source
    if not globalHeistActive then return end
    
    -- 既存のNPC情報を送信
    TriggerClientEvent('ng-iaaheist:client:SyncNPCs', src, spawnedNPCs)
end)

-- データ数取得
QBCore.Functions.CreateCallback('ng-iaaheist:server:GetDataCount', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(0)
        return
    end
    
    local dataItem = Player.Functions.GetItemByName(Config.Items.dataItem)
    cb(dataItem and dataItem.amount or 0)
end)

-- ミッション完了（脱出時）
RegisterNetEvent('ng-iaaheist:server:CompleteHeist', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    if not globalHeistActive then return end
    
    local citizenid = Player.PlayerData.citizenid
    local dataItem = Player.Functions.GetItemByName(Config.Items.dataItem)
    local dataCount = dataItem and dataItem.amount or 0
    
    -- 参加者リストに記録
    if not heistParticipants[citizenid] then
        heistParticipants[citizenid] = {
            source = src,
            name = Player.PlayerData.name,
            joinTime = os.time(),
            dataCollected = 0
        }
    end
    
    -- 統計更新
    if dataCount > 0 then
        UpdatePlayerStats(citizenid, 0) -- 報酬なしで回数のみ記録
    end
    
    -- クライアントに通知
    TriggerClientEvent('ng-iaaheist:client:HeistCompleted', src, dataCount)
    
    if Config.Debug then
        print('[ng-iaaheist] Player completed heist: ' .. Player.PlayerData.name .. ' | Data collected: ' .. dataCount)
    end
end)

-- グローバル強盗終了
RegisterNetEvent('ng-iaaheist:server:EndGlobalHeist', function()
    local src = source
    
    -- 開始者のみが終了できる（または管理者）
    if heistStartedBy and heistStartedBy.source == src then
        EndGlobalHeist()
    end
end)

-- グローバル強盗終了処理
function EndGlobalHeist()
    if not globalHeistActive then return end
    
    -- グローバルクールダウン設定
    heistCooldown = os.time() + (Config.HeistCooldown * 60)
    
    -- 参加者ログ
    if Config.Debug then
        print('[ng-iaaheist] Global heist ended. Participants:')
        for citizenid, participant in pairs(heistParticipants) do
            print('  - ' .. participant.name .. ' (' .. citizenid .. ') - Data: ' .. participant.dataCollected)
        end
    end
    
    -- ディスコードログ
    SendGlobalHeistLog()
    
    -- 全プレイヤーにNPCクリーンアップを指示
    TriggerClientEvent('ng-iaaheist:client:CleanupAllNPCs', -1)
    
    -- 状態リセット
    globalHeistActive = false
    heistStartedBy = nil
    heistParticipants = {}
    hackedDataPoints = {}
    spawnedNPCs = {}
    
    -- 全プレイヤーに終了通知
    TriggerClientEvent('ng-iaaheist:client:GlobalHeistEnded', -1)
    
    if Config.Debug then
        print('[ng-iaaheist] Global heist system reset')
    end
end

-- 自動終了タイマー（30分後）
CreateThread(function()
    while true do
        Wait(60000) -- 1分ごとにチェック
        
        if globalHeistActive and heistStartedBy then
            local elapsed = os.time() - heistStartedBy.startTime
            if elapsed > 1800 then -- 30分経過
                print('[ng-iaaheist] Auto-ending heist due to timeout')
                EndGlobalHeist()
            end
        end
    end
end)

-- プレイヤー統計更新
function UpdatePlayerStats(citizenid, earned)
    MySQL.insert('INSERT INTO ng_iaaheist (citizenid, total_heists, total_earned, last_heist) VALUES (?, 1, ?, NOW()) ON DUPLICATE KEY UPDATE total_heists = total_heists + 1, total_earned = total_earned + ?, last_heist = NOW()', {
        citizenid,
        earned,
        earned
    })
end

-- 統計取得コールバック
QBCore.Functions.CreateCallback('ng-iaaheist:server:GetStats', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(nil)
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.single('SELECT * FROM ng_iaaheist WHERE citizenid = ?', {citizenid}, function(result)
        if result then
            cb({
                totalHeists = result.total_heists,
                totalEarned = result.total_earned,
                lastHeist = result.last_heist
            })
        else
            cb({
                totalHeists = 0,
                totalEarned = 0,
                lastHeist = nil
            })
        end
    end)
end)

-- プレイヤー切断時のクリーンアップ
RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        local citizenid = Player.PlayerData.citizenid
        if heistParticipants[citizenid] then
            heistParticipants[citizenid] = nil
        end
        
        -- 開始者が切断した場合は強盗終了
        if heistStartedBy and heistStartedBy.source == source then
            print('[ng-iaaheist] Heist starter disconnected, ending global heist')
            EndGlobalHeist()
        end
    end
end)

-- アイテム使用可能性チェック
QBCore.Functions.CreateUseableItem(Config.Items.requiredItem, function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'ハッキングラップトップ',
        description = 'IAA強盗で使用できるハッキング用ラップトップです',
        type = 'inform'
    })
end)

-- グローバル強盗ログ機能
function SendGlobalHeistLog()
    local webhook = GetConvar('ng_iaaheist_webhook', '')
    if webhook == '' then return end
    
    local participantList = ""
    local totalData = 0
    
    for citizenid, participant in pairs(heistParticipants) do
        participantList = participantList .. participant.name .. " (" .. participant.dataCollected .. "個), "
        totalData = totalData + participant.dataCollected
    end
    
    if participantList ~= "" then
        participantList = string.sub(participantList, 1, -3) -- 最後のカンマと空白を削除
    else
        participantList = "なし"
    end
    
    local embed = {
        {
            color = 3066993,
            title = "グローバルIAA強盗完了",
            description = "グローバルIAA強盗が完了しました",
            fields = {
                {
                    name = "開始者",
                    value = heistStartedBy and (heistStartedBy.name .. " (" .. heistStartedBy.citizenid .. ")") or "不明",
                    inline = true
                },
                {
                    name = "参加者数",
                    value = tostring(table.count(heistParticipants)) .. "人",
                    inline = true
                },
                {
                    name = "総回収データ数",
                    value = totalData .. "個",
                    inline = true
                },
                {
                    name = "参加者リスト",
                    value = participantList,
                    inline = false
                },
                {
                    name = "時刻",
                    value = os.date("%Y-%m-%d %H:%M:%S"),
                    inline = false
                }
            },
            footer = {
                text = "ng-iaaheist"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    
    PerformHttpRequest(webhook, function(err, text, headers) 
        if Config.Debug then
            print('[ng-iaaheist] Global heist Discord log sent')
        end
    end, 'POST', json.encode({
        username = "IAA強盗システム",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- table.count ヘルパー関数
function table.count(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- 管理者コマンド
QBCore.Commands.Add('iaaheist-reset', 'IAA強盗をリセット', {}, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- 管理者権限チェック
    if not QBCore.Functions.HasPermission(source, 'admin') then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'エラー',
            description = '管理者権限が必要です',
            type = 'error'
        })
        return
    end
    
    -- グローバル強盗終了
    EndGlobalHeist()
    
    -- クールダウンもリセット
    heistCooldown = 0
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = '完了',
        description = 'IAA強盗システムをリセットしました',
        type = 'success'
    })
    
    if Config.Debug then
        print('[ng-iaaheist] System reset by admin: ' .. Player.PlayerData.name)
    end
end)

-- 統計表示コマンド
QBCore.Commands.Add('iaaheist-stats', 'IAA強盗の統計を表示', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    QBCore.Functions.CreateCallback('ng-iaaheist:server:GetStats', function(stats)
        if stats then
            local lastHeistText = stats.lastHeist and os.date("%Y-%m-%d %H:%M", stats.lastHeist) or "なし"
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'IAA強盗統計',
                description = '総強盗回数: ' .. stats.totalHeists .. '\n最後の強盗: ' .. lastHeistText,
                type = 'inform',
                duration = 10000
            })
        end
    end)(source)
end)

-- サーバー開始時の初期化
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        print('^2[ng-iaaheist]^7 グローバルIAA強盗システムが開始されました')
        
        -- 強制的にNPCクリーンアップ（リソース再起動時）
        TriggerClientEvent('ng-iaaheist:client:ForceCleanupNPCs', -1)
        
        -- 状態をリセット
        globalHeistActive = false
        heistStartedBy = nil
        heistParticipants = {}
        hackedDataPoints = {}
        spawnedNPCs = {}
        
        -- アイテム登録チェック
        if QBCore.Shared.Items[Config.Items.requiredItem] then
            print('^2[ng-iaaheist]^7 必要アイテム (' .. Config.Items.requiredItem .. ') が見つかりました')
        else
            print('^1[ng-iaaheist]^7 警告: 必要アイテム (' .. Config.Items.requiredItem .. ') が見つかりません')
        end
        
        if QBCore.Shared.Items[Config.Items.dataItem] then
            print('^2[ng-iaaheist]^7 データアイテム (' .. Config.Items.dataItem .. ') が見つかりました')
        else
            print('^1[ng-iaaheist]^7 警告: データアイテム (' .. Config.Items.dataItem .. ') が見つかりません')
        end
    end
end)

-- サーバー停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- NPCクリーンアップ指示
        TriggerClientEvent('ng-iaaheist:client:ForceCleanupNPCs', -1)
        
        globalHeistActive = false
        heistParticipants = {}
        heistStartedBy = nil
        hackedDataPoints = {}
        spawnedNPCs = {}
        print('^1[ng-iaaheist]^7 グローバルIAA強盗システムが停止されました')
    end
end)