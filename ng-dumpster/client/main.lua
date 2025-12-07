local QBCore = exports['qb-core']:GetCoreObject()

-- クールダウンレスポンスの状態管理
local cooldownResponse = {
    checked = false,
    canSearch = false,
    timeRemaining = nil
}

-- クライアント側でもエンティティハンドルベースのクールダウンを追跡
local searchedEntities = {}

-- クールダウンレスポンスイベント（1回のみ登録）
RegisterNetEvent('ng-dumpster:client:CooldownResponse', function(allowed, timeRemaining)
    cooldownResponse.checked = true
    cooldownResponse.canSearch = allowed
    cooldownResponse.timeRemaining = timeRemaining
end)

-- リソース起動時
CreateThread(function()
    -- ox_targetでゴミ箱を設定
    exports.ox_target:addModel(Config.DumpsterModels, {
        {
            name = 'search_dumpster',
            icon = 'fas fa-dumpster',
            label = Config.Locale.target_label,
            distance = Config.TargetDistance,
            onSelect = function(data)
                SearchDumpster(data.entity)
            end
        }
    })
end)

-- ゴミ箱を漁る関数（改善版）
function SearchDumpster(entity)
    local playerPed = PlayerPedId()
    
    -- エンティティの有効性チェック
    if not DoesEntityExist(entity) then
        lib.notify({
            title = Config.Locale.search_dumpster,
            description = 'ゴミ箱が見つかりません',
            type = 'error'
        })
        return
    end
    
    -- エンティティハンドルでのクライアント側クールダウンチェック
    local entityHandle = entity
    if searchedEntities[entityHandle] then
        local currentTime = GetGameTimer()
        if currentTime < searchedEntities[entityHandle] then
            local remainingMs = searchedEntities[entityHandle] - currentTime
            local remainingMin = math.floor(remainingMs / 60000)
            local remainingSec = math.floor((remainingMs % 60000) / 1000)
            lib.notify({
                title = Config.Locale.search_dumpster,
                description = Config.Locale.cooldown .. string.format(' (残り: %d分%d秒)', remainingMin, remainingSec),
                type = 'error'
            })
            return
        else
            -- 期限切れの場合は削除
            searchedEntities[entityHandle] = nil
        end
    end
    
    -- ゴミ箱の座標とモデルを取得（ユニークIDとして使用）
    local coords = GetEntityCoords(entity)
    local model = GetEntityModel(entity)
    
    -- ユニークIDを生成（座標を整数に丸めてモデルハッシュと組み合わせる）
    -- より広い範囲（約1m以内）を同一のゴミ箱として認識
    local dumpsterId = string.format("%d_%.0f_%.0f_%.0f", model, coords.x, coords.y, coords.z)
    
    -- レスポンス状態をリセット
    cooldownResponse.checked = false
    cooldownResponse.canSearch = false
    cooldownResponse.timeRemaining = nil
    
    -- サーバーにクールダウンチェックをリクエスト
    TriggerServerEvent('ng-dumpster:server:CheckCooldown', dumpsterId)
    
    -- レスポンス待機（最大3秒）
    local timeout = 0
    while not cooldownResponse.checked and timeout < 30 do
        Wait(100)
        timeout = timeout + 1
    end
    
    -- タイムアウトまたは使用不可の場合
    if not cooldownResponse.checked then
        lib.notify({
            title = Config.Locale.search_dumpster,
            description = 'サーバーからの応答がありません',
            type = 'error'
        })
        return
    end
    
    if not cooldownResponse.canSearch then
        lib.notify({
            title = Config.Locale.search_dumpster,
            description = Config.Locale.cooldown .. ' (残り: ' .. (cooldownResponse.timeRemaining or '不明') .. ')',
            type = 'error'
        })
        return
    end
    
    -- アニメーション読み込み
    RequestAnimDict(Config.Animation.dict)
    while not HasAnimDictLoaded(Config.Animation.dict) do
        Wait(10)
    end
    
    -- アニメーション再生
    TaskPlayAnim(playerPed, Config.Animation.dict, Config.Animation.anim, 8.0, -8.0, -1, Config.Animation.flags, 0, false, false, false)
    
    -- プログレスバー
    if lib.progressBar({
        duration = Config.SearchTime,
        label = Config.Locale.searching,
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    }) then
        -- 完了時
        ClearPedTasks(playerPed)
        
        -- クライアント側のエンティティハンドルクールダウンを設定
        searchedEntities[entityHandle] = GetGameTimer() + Config.Cooldown
        
        -- サーバーに報酬リクエスト（ユニークIDを送信）
        TriggerServerEvent('ng-dumpster:server:GetReward', dumpsterId)
    else
        -- キャンセル時
        ClearPedTasks(playerPed)
        lib.notify({
            title = Config.Locale.search_dumpster,
            description = 'キャンセルしました',
            type = 'error'
        })
    end
end

-- 報酬通知を受け取る（改善版）
RegisterNetEvent('ng-dumpster:client:RewardNotify', function(rewardType, rewardData)
    if rewardType == 'item' then
        lib.notify({
            title = Config.Locale.search_dumpster,
            description = rewardData.label .. ' x' .. rewardData.amount .. Config.Locale.found_item,
            type = 'success'
        })
    elseif rewardType == 'cash' then
        lib.notify({
            title = Config.Locale.search_dumpster,
            description = rewardData.amount .. Config.Locale.found_cash,
            type = 'success'
        })
    elseif rewardType == 'nothing' then
        lib.notify({
            title = Config.Locale.search_dumpster,
            description = Config.Locale.found_nothing,
            type = 'error'
        })
    elseif rewardType == 'cooldown' then
        lib.notify({
            title = Config.Locale.search_dumpster,
            description = Config.Locale.cooldown .. ' (残り: ' .. rewardData.time .. ')',
            type = 'error'
        })
    end
end)

-- クライアント側エンティティクールダウンのクリーンアップ
CreateThread(function()
    while true do
        Wait(60000) -- 1分ごと
        local currentTime = GetGameTimer()
        local cleaned = 0
        
        for handle, expireTime in pairs(searchedEntities) do
            if currentTime >= expireTime or not DoesEntityExist(handle) then
                searchedEntities[handle] = nil
                cleaned = cleaned + 1
            end
        end
    end
end)
