local QBCore = exports['qb-core']:GetCoreObject()
local activeStations = {}

-- 指紋採取機のアクティブ状態を通知
RegisterNetEvent('ng-fingerprint:server:notifyStationActive', function(stationId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- 警察ジョブチェック
    if not Player.PlayerData.job or not table.contains(Config.PoliceJobs, Player.PlayerData.job.name) then
        return
    end
    
    -- ステーション状態を更新
    activeStations[stationId] = {
        policeId = src,
        inUse = true,
        startTime = os.time()
    }
    
    -- 全クライアントに状態を即座に通知
    TriggerClientEvent('ng-fingerprint:client:updateStationStatus', -1, stationId, {
        inUse = true,
        policeId = src
    })
    
    print('^3[ng-fingerprint]^7 ステーション ' .. stationId .. ' がアクティブになりました (警察: ' .. src .. ')')
end)

-- 指紋採取処理
RegisterNetEvent('ng-fingerprint:server:collectFingerprint', function(stationId, suspectId)
    local src = source
    local station = activeStations[stationId]
    
    if not station or not station.inUse then
        return
    end
    
    local SuspectPlayer = QBCore.Functions.GetPlayer(suspectId)
    local PolicePlayer = QBCore.Functions.GetPlayer(station.policeId)
    
    if not SuspectPlayer or not PolicePlayer then
        return
    end
    
    -- 容疑者の指紋データを取得
    local fingerprintData = {
        serverId = suspectId,
        fingerprint = SuspectPlayer.PlayerData.metadata.fingerprint or 'UNKNOWN',
        playerName = SuspectPlayer.PlayerData.charinfo.firstname .. ' ' .. SuspectPlayer.PlayerData.charinfo.lastname,
        bloodtype = SuspectPlayer.PlayerData.metadata.bloodtype or 'O+',
        citizenid = SuspectPlayer.PlayerData.citizenid
    }
    
    -- 警察プレイヤーに指紋データを送信
    TriggerClientEvent('ng-fingerprint:client:receiveFingerprintData', station.policeId, fingerprintData, stationId)
    
    -- 容疑者に通知
    TriggerClientEvent('QBCore:Notify', src, '指紋が採取されました', 'info')
end)

-- セッション終了処理
RegisterNetEvent('ng-fingerprint:server:endSession', function(stationId)
    local src = source
    
    if activeStations[stationId] and activeStations[stationId].policeId == src then
        activeStations[stationId] = nil
        
        -- 全クライアントに状態を通知
        TriggerClientEvent('ng-fingerprint:client:updateStationStatus', -1, stationId, {
            inUse = false,
            policeId = nil
        })
    end
end)

-- 証拠袋アイテム使用
QBCore.Functions.CreateUseableItem(Config.EvidenceBag.ItemName, function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then
        return
    end
    
    -- 警察ジョブチェック
    if not Player.PlayerData.job or not table.contains(Config.PoliceJobs, Player.PlayerData.job.name) then
        TriggerClientEvent('QBCore:Notify', source, Config.Lang['no_permission'], 'error')
        return
    end
    
    -- アイテムのメタデータをチェック
    if not item.metadata then
        TriggerClientEvent('QBCore:Notify', source, 'メタデータが見つかりません', 'error')
        return
    end
    
    -- 指紋タイプかどうかチェック
    if not item.metadata.type or item.metadata.type ~= Config.EvidenceBag.FingerprintType then
        TriggerClientEvent('QBCore:Notify', source, 'これは指紋の証拠袋ではありません (タイプ: ' .. tostring(item.metadata.type) .. ')', 'error')
        return
    end
    
    -- 指紋データが存在するかチェック
    if not item.metadata.fingerprint then
        TriggerClientEvent('QBCore:Notify', source, '指紋データが見つかりません', 'error')
        return
    end
    
    -- クライアントに証拠袋データを送信
    TriggerClientEvent('ng-fingerprint:client:useEvidenceBag', source, {
        metadata = item.metadata
    })
end)

-- プレイヤー切断時のセッションクリーンアップ
AddEventHandler('playerDropped', function(reason)
    local src = source
    
    -- 該当プレイヤーがアクティブなセッションを持っているかチェック
    for stationId, station in pairs(activeStations) do
        if station.policeId == src then
            activeStations[stationId] = nil
            -- 全クライアントに状態を通知
            TriggerClientEvent('ng-fingerprint:client:updateStationStatus', -1, stationId, {
                inUse = false,
                policeId = nil
            })
            break
        end
    end
end)

-- スクリプト開始時の処理
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('^2[ng-fingerprint]^7 指紋採取システムが開始されました')
        print('^3[ng-fingerprint]^7 指紋採取機が設置されました: ' .. #Config.FingerprintStations .. '箇所')
    end
end)

-- スクリプト停止時の処理
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- 全てのアクティブセッションを終了
        for stationId, _ in pairs(activeStations) do
            TriggerClientEvent('ng-fingerprint:client:updateStationStatus', -1, stationId, {
                inUse = false,
                policeId = nil
            })
        end
        activeStations = {}
        print('^2[ng-fingerprint]^7 指紋採取システムが停止されました')
    end
end)

-- ヘルパー関数
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end