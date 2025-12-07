local QBCore = exports['qb-core']:GetCoreObject()
local fingerprintStations = {}
local collectedFingerprints = {}
local isUsingStation = false
local currentStation = nil

-- リソース開始時に指紋採取機を生成
CreateThread(function()
    for i, station in pairs(Config.FingerprintStations) do
        -- オブジェクトを生成
        local model = GetHashKey(station.model)
        RequestModel(model)
        
        while not HasModelLoaded(model) do
            Wait(100)
        end
        
        local obj = CreateObject(model, station.coords.x, station.coords.y, station.coords.z, false, false, false)
        SetEntityHeading(obj, station.heading)
        FreezeEntityPosition(obj, true)
        SetEntityInvincible(obj, true)
        
        -- ステーション情報を保存
        fingerprintStations[i] = {
            object = obj,
            coords = station.coords,
            name = station.name,
            inUse = false,
            policeId = nil,
            suspectId = nil
        }
        
        -- ターゲット設定
        exports['qb-target']:AddTargetEntity(obj, {
            options = {
                {
                    type = "client",
                    event = "ng-fingerprint:client:useStation",
                    icon = "fas fa-fingerprint",
                    label = station.name,
                    stationId = i,
                    canInteract = function()
                        return true
                    end,
                }
            },
            distance = station.interactionDistance
        })
    end
end)

-- 指紋採取機使用
RegisterNetEvent('ng-fingerprint:client:useStation', function(data)
    local stationId = data.stationId
    local station = fingerprintStations[stationId]
    local PlayerData = QBCore.Functions.GetPlayerData()
    local myServerId = GetPlayerServerId(PlayerId())
    
    if not station then return end
    
    -- 警察かどうかチェック
    local isPolice = PlayerData.job and table.contains(Config.PoliceJobs, PlayerData.job.name)
    
    if isPolice then
        -- 警察の場合：セッション開始/終了
        if station.inUse and station.policeId == myServerId then
            -- 既に自分が使用中の場合はメニューを再表示
            ShowFingerprintUI()
        elseif station.inUse and station.policeId ~= myServerId then
            -- 他の警察が使用中
            lib.notify({
                title = 'エラー',
                description = Config.Lang['station_in_use'],
                type = 'error'
            })
        else
            -- 新規セッション開始
            StartPoliceSession(stationId)
        end
    else
        -- 一般プレイヤーの場合：指紋を自動採取
        if station.inUse and station.policeId then
            -- 警察がアクティブな場合、自動的に指紋を採取
            TriggerServerEvent('ng-fingerprint:server:collectFingerprint', stationId, myServerId)
            
            lib.notify({
                title = '指紋採取',
                description = '指紋が採取されました',
                type = 'success'
            })
        else
            lib.notify({
                title = 'エラー',
                description = Config.Lang['police_required'],
                type = 'error'
            })
        end
    end
end)

-- 警察セッション開始
function StartPoliceSession(stationId)
    local station = fingerprintStations[stationId]
    local myServerId = GetPlayerServerId(PlayerId())
    
    -- ローカル状態を即座に更新
    station.inUse = true
    station.policeId = myServerId
    currentStation = stationId
    collectedFingerprints = {}
    
    -- サーバーに状態を通知（他のクライアントにも同期）
    TriggerServerEvent('ng-fingerprint:server:notifyStationActive', stationId)
    
    lib.notify({
        title = '指紋採取',
        description = Config.Lang['collection_started'] .. '\n他のプレイヤーに機械を触ってもらってください',
        type = 'success'
    })
    
    -- 指紋リストUIを表示
    ShowFingerprintUI()
end

-- 削除：StartSuspectScan関数は不要になったため削除

-- 指紋データ受信（警察用）
RegisterNetEvent('ng-fingerprint:client:receiveFingerprintData', function(data, stationId)
    if currentStation ~= stationId then return end
    
    -- 指紋リストに追加
    table.insert(collectedFingerprints, {
        serverId = data.serverId,
        fingerprint = data.fingerprint,
        playerName = data.playerName,
        timestamp = GetGameTimer(),
        bloodtype = data.bloodtype or '不明'
    })
    
    -- 最大数を超えた場合、古いものを削除
    if #collectedFingerprints > Config.FingerprintSettings.MaxFingerprints then
        table.remove(collectedFingerprints, 1)
    end
    
    lib.notify({
        title = '指紋採取',
        description = Config.Lang['fingerprint_collected'] .. ': ' .. data.playerName,
        type = 'success'
    })
    
    -- UIが開いている場合は更新
    if currentStation then
        ShowFingerprintUI()
    end
end)

-- 指紋採取機の状態更新通知
RegisterNetEvent('ng-fingerprint:client:updateStationStatus', function(stationId, status)
    if fingerprintStations[stationId] then
        fingerprintStations[stationId].inUse = status.inUse
        fingerprintStations[stationId].policeId = status.policeId
        
        print('^3[ng-fingerprint]^7 ステーション ' .. stationId .. ' 状態更新: inUse=' .. tostring(status.inUse) .. ', policeId=' .. tostring(status.policeId))
    end
end)

-- 指紋UI表示
function ShowFingerprintUI()
    local menuOptions = {}
    
    if #collectedFingerprints == 0 then
        menuOptions[#menuOptions + 1] = {
            title = Config.Lang['no_fingerprints'],
            description = '採取された指紋がありません',
            disabled = true
        }
    else
        for i, fingerprint in pairs(collectedFingerprints) do
            menuOptions[#menuOptions + 1] = {
                title = fingerprint.playerName,
                description = '指紋: ' .. fingerprint.fingerprint .. '\n血液型: ' .. fingerprint.bloodtype,
                onSelect = function()
                    CopyFingerprintToClipboard(fingerprint.fingerprint)
                end
            }
        end
    end
    
    -- セッション終了ボタン
    menuOptions[#menuOptions + 1] = {
        title = '指紋採取を終了',
        description = '現在の指紋採取セッションを終了します',
        onSelect = function()
            EndPoliceSession()
        end
    }
    
    lib.registerContext({
        id = 'fingerprint_menu',
        title = '指紋採取システム (' .. #collectedFingerprints .. '/' .. Config.FingerprintSettings.MaxFingerprints .. ')',
        options = menuOptions,
        onExit = function()
            -- UIを閉じた時にセッションを終了
            EndPoliceSession()
        end
    })
    
    lib.showContext('fingerprint_menu')
end

-- 警察セッション終了
function EndPoliceSession()
    if not currentStation then return end
    
    local station = fingerprintStations[currentStation]
    local stationId = currentStation
    
    -- ローカル状態をリセット
    station.inUse = false
    station.policeId = nil
    station.suspectId = nil
    
    -- サーバーに終了を通知
    TriggerServerEvent('ng-fingerprint:server:endSession', stationId)
    
    currentStation = nil
    collectedFingerprints = {}
    
    lib.hideContext('fingerprint_menu')
    
    lib.notify({
        title = '指紋採取',
        description = '指紋採取セッションを終了しました',
        type = 'info'
    })
end

-- 指紋をクリップボードにコピー
function CopyFingerprintToClipboard(fingerprint)
    lib.setClipboard(fingerprint)
    lib.notify({
        title = '指紋採取',
        description = Config.Lang['fingerprint_copied'],
        type = 'success'
    })
    
    -- UIを閉じずに再表示
    if currentStation then
        ShowFingerprintUI()
    end
end

-- 証拠袋使用
RegisterNetEvent('ng-fingerprint:client:useEvidenceBag', function(data)
    if not data or not data.metadata then
        lib.notify({
            title = 'エラー',
            description = Config.Lang['invalid_evidence'],
            type = 'error'
        })
        return
    end
    
    local metadata = data.metadata
    
    if metadata.type ~= Config.EvidenceBag.FingerprintType then
        lib.notify({
            title = 'エラー',
            description = 'これは指紋の証拠袋ではありません',
            type = 'error'
        })
        return
    end
    
    -- 証拠袋の指紋を表示
    lib.registerContext({
        id = 'evidence_bag_menu',
        title = '証拠袋の指紋',
        options = {
            {
                title = metadata.label or 'Fingerprint',
                description = '場所: ' .. (metadata.street or '不明') .. '\n指紋: ' .. (metadata.fingerprint or '不明'),
                onSelect = function()
                    if metadata.fingerprint then
                        CopyFingerprintToClipboard(metadata.fingerprint)
                    end
                end
            }
        }
    })
    
    lib.showContext('evidence_bag_menu')
    
    lib.notify({
        title = '証拠袋',
        description = Config.Lang['evidence_bag_used'],
        type = 'info'
    })
end)

-- リソース停止時にオブジェクトを削除
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, station in pairs(fingerprintStations) do
            if DoesEntityExist(station.object) then
                DeleteObject(station.object)
            end
        end
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

-- 場所情報取得（サーバーからの要求）
RegisterNetEvent('ng-fingerprint:client:getLocation', function(callback)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local crossingName = GetStreetNameFromHashKey(crossingHash)
    
    local location = streetName
    if crossingName and crossingName ~= "" then
        location = streetName .. " & " .. crossingName
    end
    
    if callback then
        callback(location)
    end
end)