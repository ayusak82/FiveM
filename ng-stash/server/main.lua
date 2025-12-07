-- データベーステーブルの作成
MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ng_stashes` (
            `id` varchar(50) NOT NULL,
            `label` varchar(50) NOT NULL,
            `job` varchar(50) NOT NULL,
            `type` varchar(50) NOT NULL,
            `coords` longtext NOT NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

-- スタッシュデータのキャッシュ
local stashCache = {}

-- スタッシュ数のチェック
local function countJobStashes(job)
    local count = 0
    for _, stash in pairs(stashCache) do
        if stash.job == job then
            count = count + 1
        end
    end
    return count
end

-- スタッシュデータの読み込み
local function loadStashes()
    print('^2[Stash] Loading stashes from database...^7')
    local results = MySQL.query.await('SELECT * FROM ng_stashes')
    if not results then 
        print('^1[Stash] No stashes found in database^7')
        return 
    end

    print('^2[Stash] Found ' .. #results .. ' stashes^7')
    for _, stash in ipairs(results) do
        local success, coords = pcall(json.decode, stash.coords)
        if not success then
            print('^1[Stash] Error decoding coords for stash: ' .. stash.id .. '^7')
            goto continue
        end

        stash.coords = coords
        stashCache[stash.id] = stash
        
        -- ox_inventoryにスタッシュを登録
        exports.ox_inventory:RegisterStash(
            stash.id,
            stash.label,
            Config.StashTypes[stash.type].slots,
            Config.StashTypes[stash.type].weight,
            nil
        )

        print('^2[Stash] Loaded stash: ' .. stash.id .. '^7')
        ::continue::
    end
end

-- 起動時にスタッシュを読み込み
CreateThread(function()
    Wait(1000) -- データベース接続を待機
    loadStashes()
end)

-- QBCoreの初期化
local QBCore = exports['qb-core']:GetCoreObject()

-- 管理者権限チェック関数
local function isAdmin(source)
    if not source then return false end
    return IsPlayerAceAllowed(source, 'command.admin')
end

-- 管理者権限チェックのコールバック登録
lib.callback.register('ng-stash:server:isAdmin', function(source)
    return isAdmin(source)
end)

-- プレイヤーのジョブ情報を取得
lib.callback.register('ng-stash:server:getJob', function(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    
    return {
        name = player.PlayerData.job.name,
        grade = {
            level = player.PlayerData.job.grade.level
        }
    }
end)

-- スタッシュの作成
lib.callback.register('ng-stash:server:createStash', function(source, job, type, label, coords)
    -- 入力チェック
    if not Config.StashTypes[type] then
        return false, '無効な保管庫タイプです'
    end
    
    if not Config.AllowedJobs[job] then
        return false, '権限がありません'
    end

    -- プレイヤーの権限チェック
    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        return false, 'プレイヤーが見つかりません'
    end

    if player.PlayerData.job.grade.level < Config.AllowedJobs[job].minGrade then
        return false, string.format('この操作には%d以上の階級が必要です', Config.AllowedJobs[job].minGrade)
    end

    -- スタッシュ数の制限チェック
    local currentCount = countJobStashes(job)
    local maxStashes = Config.AllowedJobs[job].maxStashes

    if currentCount >= maxStashes then
        return false, string.format('作成可能な保管庫の上限（%d個）に達しています', maxStashes)
    end

    -- スタッシュIDの生成
    local id = string.format('%s_%s_%s', job, type, os.time())
    
    -- データの準備
    local parameters = {
        id = id,
        label = label,
        job = job,
        type = type,
        coords = json.encode(coords)
    }

    -- データベースに保存
    local success = MySQL.transaction.await({
        {
            query = 'INSERT INTO ng_stashes (id, label, job, type, coords) VALUES (?, ?, ?, ?, ?)',
            values = { id, label, job, type, json.encode(coords) }
        }
    })

    if not success then
        return false, 'データベースエラーが発生しました'
    end

    -- キャッシュに追加
    stashCache[id] = {
        id = id,
        label = label,
        job = job,
        type = type,
        coords = coords
    }
    
    -- ox_inventoryにスタッシュを登録
    exports.ox_inventory:RegisterStash(
        id,
        label,
        Config.StashTypes[type].slots,
        Config.StashTypes[type].weight,
        nil
    )
    
    -- 全クライアントに同期
    TriggerClientEvent('ng-stash:client:syncStash', -1, 'create', stashCache[id])
    
    return true, '保管庫を作成しました', stashCache[id]
end)

-- スタッシュ一覧の取得
lib.callback.register('ng-stash:server:getStashes', function(source, job, isAdmin)
    local stashes = {}
    
    for _, stash in pairs(stashCache) do
        if isAdmin or stash.job == job then
            stashes[#stashes + 1] = stash
        end
    end
    
    return stashes
end)

-- 全スタッシュ情報の取得（管理者用）
lib.callback.register('ng-stash:server:getAllStashes', function(source)
    if not isAdmin(source) then return {} end
    
    local stashes = {}
    for _, stash in pairs(stashCache) do
        table.insert(stashes, stash)
    end
    
    return stashes
end)

-- スタッシュの削除
lib.callback.register('ng-stash:server:deleteStash', function(source, stashId)
    local stash = stashCache[stashId]
    if not stash then
        return false, '保管庫が見つかりません'
    end

    -- トランザクション処理
    local success = MySQL.transaction.await({
        {
            query = 'DELETE FROM ng_stashes WHERE id = ?',
            values = { stashId }
        }
    })

    if not success then
        return false, 'データベースエラーが発生しました'
    end

    -- インベントリデータの削除
    exports.ox_inventory:ClearInventory(stashId)
    
    -- 削除前にデータを保持
    local deletedStash = table.clone(stash)
    
    -- キャッシュから削除
    stashCache[stashId] = nil
    
    -- 全クライアントに同期（即時）
    TriggerClientEvent('ng-stash:client:syncStash', -1, 'delete', {id = stashId, job = deletedStash.job})
    
    return true, '保管庫を削除しました'
end)

-- クライアントに現在のスタッシュ数を返すコールバックを追加
lib.callback.register('ng-stash:server:getStashCount', function(source, job)
    return countJobStashes(job)
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local source = source
    TriggerClientEvent('ng-stash:client:initializeStashes', source)
end)

-- リソース起動時のスタッシュ登録
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        print('^2[Stash] Resource starting...^7')
        Wait(2000) -- データベース接続を確実に待機
        loadStashes()
        
        -- クライアントに通知
        TriggerClientEvent('ng-stash:client:resourceStarted', -1)
    end
end)

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for id, _ in pairs(stashCache) do
            exports.ox_inventory:ClearInventory(id)
        end
    end
end)