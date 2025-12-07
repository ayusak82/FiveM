local QBCore = exports['qb-core']:GetCoreObject()

-- グローバル変数
local lastRobberyTime = 0
local robberyInProgress = false
local robberyStarted = false
local robbedTrollysState = {} -- トロリー盗難状態管理
local trollyLockState = {} -- トロリーロック状態管理（新追加）

-- デバッグ出力関数
local function DebugPrint(...)
    if Config.Debug and Config.Debug.enabled then
        print('[ng-hangar-robbery] ' .. string.format(...))
    end
end

-- 警察官数チェック
local function GetCopCount()
    local count = 0
    local players = QBCore.Functions.GetQBPlayers()
    for _, player in pairs(players) do
        if player.PlayerData.job.type == 'leo' and player.PlayerData.job.onduty then
            count = count + 1
        end
    end
    return count
end

-- クールダウンチェック
local function CanStartRobbery()
    local currentTime = os.time() * 1000
    return (currentTime - lastRobberyTime) >= Config.Cooldown.duration
end

-- 残り時間計算
local function GetRemainingCooldown()
    local currentTime = os.time() * 1000
    local remainingTime = Config.Cooldown.duration - (currentTime - lastRobberyTime)
    return math.max(0, remainingTime)
end

-- 時間フォーマット
local function FormatTime(milliseconds)
    local seconds = math.floor(milliseconds / 1000)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    
    if hours > 0 then
        return string.format("%d時間%d分", hours, minutes % 60)
    elseif minutes > 0 then
        return string.format("%d分%d秒", minutes, seconds % 60)
    else
        return string.format("%d秒", seconds)
    end
end

-- 強盗受注
RegisterNetEvent('ng-hangar-robbery:server:startJob', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- 警察官数チェック
    local copCount = GetCopCount()
    if copCount < Config.Requirements.minCops then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '強盗受注',
            description = string.format(Config.Notifications.notEnoughCops, Config.Requirements.minCops),
            type = 'error'
        })
        return
    end
    
    -- クールダウンチェック
    if not CanStartRobbery() then
        local remainingTime = GetRemainingCooldown()
        TriggerClientEvent('ox_lib:notify', src, {
            title = '強盗受注',
            description = Config.Notifications.jobOnCooldown .. '\n残り時間: ' .. FormatTime(remainingTime),
            type = 'error'
        })
        return
    end
    
    -- 進行中チェック
    if robberyInProgress then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '強盗受注',
            description = '現在他のプレイヤーが強盗を実行中です',
            type = 'error'
        })
        return
    end
    
    -- 強盗開始
    robberyInProgress = true
    robberyStarted = false
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = '強盗受注',
        description = Config.Notifications.jobStart,
        type = 'success'
    })
    
    TriggerClientEvent('ng-hangar-robbery:client:startRobbery', src)
end)

-- 強盗開始（侵入検知時）
RegisterNetEvent('ng-hangar-robbery:server:robberyDetected', function()
    local src = source
    
    if robberyStarted then return end
    
    robberyStarted = true
    lastRobberyTime = os.time() * 1000
    robbedTrollysState = {} -- トロリー状態をリセット
    trollyLockState = {} -- ロック状態をリセット（新追加）
    
    -- ps-dispatch通報
    if GetResourceState('ps-dispatch') == 'started' then
        TriggerClientEvent('ng-hangar-robbery:client:callPolice', src)
    end
    
    -- 全プレイヤーにプロップ生成指示
    local players = QBCore.Functions.GetQBPlayers()
    for _, player in pairs(players) do
        if player.PlayerData.source == src then
            -- 受注者：NPCとプロップ両方生成
            TriggerClientEvent('ng-hangar-robbery:client:spawnGuards', player.PlayerData.source, true)
        else
            -- 他のプレイヤー：プロップのみ生成
            TriggerClientEvent('ng-hangar-robbery:client:spawnGuards', player.PlayerData.source, false)
        end
    end
    
    DebugPrint('強盗が開始されました - プレイヤー: %s', GetPlayerName(src))
end)

-- 強盗完了
RegisterNetEvent('ng-hangar-robbery:server:robberyComplete', function()
    local src = source
    
    robberyInProgress = false
    robberyStarted = false
    robbedTrollysState = {} -- 状態をリセット
    trollyLockState = {} -- ロック状態をリセット（新追加）
    
    -- 全クライアントにNPC削除指示
    TriggerClientEvent('ng-hangar-robbery:client:cleanupGuards', -1)
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = '強盗完了',
        description = Config.Notifications.robberyComplete,
        type = 'success'
    })
    
    DebugPrint('強盗が完了しました - プレイヤー: %s', GetPlayerName(src))
end)

-- 強盗放棄処理
RegisterNetEvent('ng-hangar-robbery:server:abandonRobbery', function()
    local src = source
    
    if not robberyInProgress then return end
    
    robberyInProgress = false
    robberyStarted = false
    robbedTrollysState = {} -- 状態をリセット
    trollyLockState = {} -- ロック状態をリセット（新追加）
    lastRobberyTime = os.time() * 1000 -- クールダウン開始
    
    -- 全クライアントにNPC削除指示
    TriggerClientEvent('ng-hangar-robbery:client:cleanupGuards', -1)
    
    -- 放棄通知をクライアントに送信
    TriggerClientEvent('ng-hangar-robbery:client:robberyAbandoned', src)
    
    DebugPrint('強盗が放棄されました - プレイヤー: %s', GetPlayerName(src))
end)

-- トロリーロック試行（新機能）
QBCore.Functions.CreateCallback('ng-hangar-robbery:server:tryLockTrolly', function(source, cb, trollyIndex)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player or not robberyInProgress then
        cb(false, nil)
        return
    end
    
    -- 既に回収済みかチェック
    if robbedTrollysState[trollyIndex] then
        cb(false, nil)
        return
    end
    
    -- 既にロックされているかチェック
    if trollyLockState[trollyIndex] then
        local lockedByName = trollyLockState[trollyIndex].playerName
        cb(false, lockedByName)
        return
    end
    
    -- ロックを設定
    trollyLockState[trollyIndex] = {
        playerId = src,
        playerName = GetPlayerName(src),
        lockTime = os.time()
    }
    
    -- 全クライアントにロック状態を同期
    TriggerClientEvent('ng-hangar-robbery:client:syncTrollyLock', -1, trollyIndex, true, GetPlayerName(src))
    
    DebugPrint('トロリー%d がロックされました - プレイヤー: %s', trollyIndex, GetPlayerName(src))
    
    cb(true, nil)
end)

-- トロリーアンロック（新機能）
RegisterNetEvent('ng-hangar-robbery:server:unlockTrolly', function(trollyIndex)
    local src = source
    
    if not robberyInProgress then return end
    
    -- ロック状態をチェック（自分がロックしたもののみ解除可能）
    if trollyLockState[trollyIndex] and trollyLockState[trollyIndex].playerId == src then
        trollyLockState[trollyIndex] = nil
        
        -- 全クライアントにロック解除を同期
        TriggerClientEvent('ng-hangar-robbery:client:syncTrollyLock', -1, trollyIndex, false, nil)
        
        DebugPrint('トロリー%d のロックが解除されました - プレイヤー: %s', trollyIndex, GetPlayerName(src))
    end
end)

-- トロリーアイテム取得
RegisterNetEvent('ng-hangar-robbery:server:giveTrollyItems', function(trollyData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player or not robberyInProgress then return end
    
    -- トロリーから複数アイテムを取得
    for _, itemData in ipairs(trollyData.items) do
        local itemName = itemData.name
        local itemCount = itemData.count
        
        if exports.ox_inventory:CanCarryItem(src, itemName, itemCount) then
            exports.ox_inventory:AddItem(src, itemName, itemCount)
            
            TriggerClientEvent('ox_lib:notify', src, {
                title = '強盗',
                description = 'アイテムを入手しました: ' .. itemName .. ' x' .. itemCount,
                type = 'success'
            })
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = '強盗',
                description = 'インベントリがいっぱいです: ' .. itemName,
                type = 'error'
            })
        end
    end
end)

-- トロリー回収状態同期
RegisterNetEvent('ng-hangar-robbery:server:trollyRobbed', function(index)
    local src = source
    
    if not robberyInProgress then return end
    
    robbedTrollysState[index] = true
    trollyLockState[index] = nil -- 回収完了時はロックも解除（新追加）
    
    -- 全プレイヤーに盗難状態を同期
    TriggerClientEvent('ng-hangar-robbery:client:syncTrollyRobbed', -1, index)
    
    DebugPrint('トロリー%d が回収されました - プレイヤー: %s', index, GetPlayerName(src))
end)

-- プレイヤー切断時のロック解除処理（新機能）
AddEventHandler('playerDropped', function(reason)
    local src = source
    
    -- 切断したプレイヤーがロックしていたトロリーがあれば解除
    for trollyIndex, lockData in pairs(trollyLockState) do
        if lockData.playerId == src then
            trollyLockState[trollyIndex] = nil
            
            -- 全クライアントにロック解除を同期
            TriggerClientEvent('ng-hangar-robbery:client:syncTrollyLock', -1, trollyIndex, false, nil)
            
            DebugPrint('プレイヤー切断によりトロリー%d のロックが解除されました - プレイヤー: %s', trollyIndex, GetPlayerName(src))
        end
    end
end)

-- 古いロックの自動解除（新機能 - 安全装置）
CreateThread(function()
    while true do
        Wait(30000) -- 30秒ごとにチェック
        
        if robberyInProgress then
            local currentTime = os.time()
            
            for trollyIndex, lockData in pairs(trollyLockState) do
                -- 5分以上古いロックは自動解除
                if currentTime - lockData.lockTime > 300 then
                    trollyLockState[trollyIndex] = nil
                    
                    -- 全クライアントにロック解除を同期
                    TriggerClientEvent('ng-hangar-robbery:client:syncTrollyLock', -1, trollyIndex, false, nil)
                    
                    DebugPrint('古いロックを自動解除しました - トロリー%d, プレイヤー: %s', trollyIndex, lockData.playerName)
                end
            end
        end
    end
end)

-- 強盗状態リセット（警察専用コマンド）
RegisterNetEvent('ng-hangar-robbery:server:policeReset', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- 警察職業チェック
    if Player.PlayerData.job.type ~= 'leo' or not Player.PlayerData.job.onduty then
        TriggerClientEvent('ox_lib:notify', src, {
            title = '権限エラー',
            description = '警察官のみが実行できるコマンドです',
            type = 'error'
        })
        return
    end
    
    -- 強盗状態リセット
    robberyInProgress = false
    robberyStarted = false
    robbedTrollysState = {} -- 状態をリセット
    trollyLockState = {} -- ロック状態をリセット（新追加）
    lastRobberyTime = 0
    
    TriggerClientEvent('ng-hangar-robbery:client:cleanupGuards', -1)
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = '強盗システム',
        description = '格納庫強盗の状態をリセットしました',
        type = 'success'
    })
    
    -- 全警察官に通知
    local players = QBCore.Functions.GetQBPlayers()
    for _, player in pairs(players) do
        if player.PlayerData.job.type == 'leo' and player.PlayerData.job.onduty then
            TriggerClientEvent('ox_lib:notify', player.PlayerData.source, {
                title = '格納庫強盗',
                description = GetPlayerName(src) .. ' により強盗状態がリセットされました',
                type = 'inform'
            })
        end
    end
    
    DebugPrint('強盗状態がリセットされました - 警察官: %s', GetPlayerName(src))
end)

-- 強盗状態確認（修正版）
QBCore.Functions.CreateCallback('ng-hangar-robbery:server:getRobberyState', function(source, cb)
    cb({
        robberyInProgress = robberyInProgress,
        robberyStarted = robberyStarted,
        robbedTrollys = robbedTrollysState,
        trollyLocks = trollyLockState -- ロック状態も送信（新追加）
    })
end)

-- クールダウン状態確認
QBCore.Functions.CreateCallback('ng-hangar-robbery:server:canStartRobbery', function(source, cb)
    local canStart = CanStartRobbery() and not robberyInProgress
    local remainingTime = canStart and 0 or GetRemainingCooldown()
    local copCount = GetCopCount()
    
    -- デバッグ情報
    if Config.Debug and Config.Debug.enabled and Config.Debug.cooldown then
        local currentTime = os.time() * 1000
        local timeSinceLastRobbery = currentTime - lastRobberyTime
        
        DebugPrint('クールダウン状態確認:')
        DebugPrint('  - 現在時刻: %d', currentTime)
        DebugPrint('  - 最後の強盗時刻: %d', lastRobberyTime)
        DebugPrint('  - 経過時間: %d ms', timeSinceLastRobbery)
        DebugPrint('  - クールダウン期間: %d ms', Config.Cooldown.duration)
        DebugPrint('  - 開始可能: %s', tostring(canStart))
        DebugPrint('  - 残り時間: %d ms', remainingTime)
    end
    
    cb({
        canStart = canStart,
        remainingTime = remainingTime,
        formattedTime = FormatTime(remainingTime),
        copCount = copCount,
        requiredCops = Config.Requirements.minCops,
        robberyInProgress = robberyInProgress
    })
end)

-- サーバー起動時の初期化
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        DebugPrint('サーバーサイドが開始されました')
        robberyInProgress = false
        robberyStarted = false
        robbedTrollysState = {} -- 状態をリセット
        trollyLockState = {} -- ロック状態をリセット（新追加）
        lastRobberyTime = 0
    end
end)

-- サーバー停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        TriggerClientEvent('ng-hangar-robbery:client:cleanupGuards', -1)
        DebugPrint('サーバーサイドが停止されました')
    end
end)