local QBCore = exports['qb-core']:GetCoreObject()
local isInsideRecyclingCenter = false
local currentWarehouse = nil
local currentRoom = nil
local activeJob = false
local pickupBlips = {}
local pickupPoints = {}
local collectedPickups = {}
local deliveryBlip = nil
local isOnCooldown = false
local carryingBox = false
local inMarkerZone = false
local currentZone = nil

-- レベルシステム変数
local playerLevel = 1
local playerExp = 0
local requiredExp = 100
local speedBonus = 0.0
local collectionBonus = 1.0

-- 重量チェック関数
local function CheckPlayerWeight()
    return lib.callback.await('ng-recycling:server:checkWeight', false)
end

-- 重量警告表示
local function ShowWeightWarning(weightInfo)
    if weightInfo.percentage >= 90 then
        lib.notify({
            title = 'インベントリ警告',
            description = 'インベントリがほぼ満杯です (' .. weightInfo.percentage .. '%)\n報酬を受け取れない可能性があります',
            type = 'warning',
            duration = 5000
        })
    elseif weightInfo.percentage >= 80 then
        lib.notify({
            title = 'インベントリ注意',
            description = 'インベントリの使用率: ' .. weightInfo.percentage .. '%',
            type = 'info',
            duration = 3000
        })
    end
end

-- リサイクルセンターの入口・出口ポイント作成
local function CreateEntrancePoint()
    for k, v in pairs(Config.EntranceLocations) do
        -- ブリップ作成
        if v.blip then
            local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
            SetBlipSprite(blip, v.blip.sprite)
            SetBlipColour(blip, v.blip.color)
            SetBlipScale(blip, v.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(v.blip.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end

-- リサイクルセンター内部の作成
local function SetupInterior()
    -- IPLロード
    RequestIpl(Config.RecyclingInterior.ipl)
end

-- ルーム選択メニューを表示
local function OpenRoomSelectionMenu()
    -- 利用可能なルーム一覧を取得
    local availableRooms = lib.callback.await('ng-recycling:server:getAvailableRooms', false)
    
    -- メニューオプションの作成
    local options = {}
    for _, room in ipairs(availableRooms) do
        local status = room.isAvailable and "利用可能" or "満員"
        local label = room.label .. " (" .. room.playerCount .. "/" .. room.maxPlayers .. ") - " .. status
        
        table.insert(options, {
            title = label,
            description = "このルームに入る",
            disabled = not room.isAvailable,
            onSelect = function()
                EnterRecyclingCenter(currentWarehouse, room.id)
            end
        })
    end

    -- キャンセルオプション
    table.insert(options, {
        title = "キャンセル",
        description = "ルーム選択をキャンセル",
        onSelect = function() end
    })
    
    -- メニュー表示
    lib.registerContext({
        id = 'recycling_room_menu',
        title = 'リサイクルセンター ルーム選択',
        options = options
    })
    
    lib.showContext('recycling_room_menu')
end

-- プレイヤーのレベル情報を取得
local function LoadPlayerLevel()
    local levelData = lib.callback.await('ng-recycling:server:getPlayerLevel', false)
    if levelData then
        playerLevel = levelData.level
        playerExp = levelData.experience
        requiredExp = levelData.requiredExp
        speedBonus = levelData.speedBonus
        collectionBonus = levelData.collectionBonus
    end
end

-- レベル情報を更新（サーバーから受信）
RegisterNetEvent('ng-recycling:client:updateLevel', function(level, exp, reqExp)
    playerLevel = level
    playerExp = exp
    requiredExp = reqExp
    
    -- ボーナスを再計算（クライアント側で計算）
    speedBonus = (level - 1) * 0.01
    if speedBonus > 0.5 then speedBonus = 0.5 end
    
    collectionBonus = 1.0 + (level - 1) * 0.02
    if collectionBonus > 2.0 then collectionBonus = 2.0 end
end)

-- レベル情報表示メニュー
local function ShowLevelInfo()
    lib.registerContext({
        id = 'recycling_level_info',
        title = 'リサイクル作業 - レベル情報',
        options = {
            {
                title = '現在のレベル',
                description = 'レベル ' .. playerLevel .. ' / 50',
                icon = 'star'
            },
            {
                title = '経験値',
                description = playerExp .. ' / ' .. requiredExp .. ' XP (' .. math.floor((playerExp / requiredExp) * 100) .. '%)',
                icon = 'chart-bar',
                progress = math.floor((playerExp / requiredExp) * 100)
            },
            {
                title = '採取量ボーナス',
                description = math.floor(collectionBonus * 100) .. '% (最大200%)',
                icon = 'box'
            },
            {
                title = '取得速度向上',
                description = math.floor(speedBonus * 100) .. '% 短縮 (最大50%)',
                icon = 'gauge-high'
            },
            {
                title = '次のレベルまで',
                description = (requiredExp - playerExp) .. ' XP',
                icon = 'arrow-up'
            }
        }
    })
    
    lib.showContext('recycling_level_info')
end

-- リサイクルセンターに入る
function EnterRecyclingCenter(locationId, roomId)
    -- すでに中にいる場合は処理しない
    if isInsideRecyclingCenter then return end
    
    -- ルームIDがない場合はルーム選択メニューを表示
    if not roomId then
        currentWarehouse = locationId
        OpenRoomSelectionMenu()
        return
    end
    
    isInsideRecyclingCenter = true
    currentWarehouse = locationId
    currentRoom = roomId
    
    -- サーバーにルーム入室を通知
    TriggerServerEvent('ng-recycling:server:enterRoom', roomId)
    
    -- 内部へテレポート
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(10)
    end
    
    SetEntityCoords(PlayerPedId(), Config.RecyclingInterior.coords.x, Config.RecyclingInterior.coords.y, Config.RecyclingInterior.coords.z)
    SetEntityHeading(PlayerPedId(), Config.RecyclingInterior.heading)
    Wait(100)
    
    DoScreenFadeIn(500)
    
    -- 重量チェックと入室通知
    CreateThread(function()
        Wait(1000) -- 少し待ってから重量チェック
        local weightInfo = CheckPlayerWeight()
        if weightInfo then
            ShowWeightWarning(weightInfo)
        end
    end)
    
    -- レベル情報を読み込み
    LoadPlayerLevel()
    
    -- 通知
    lib.notify({
        title = 'リサイクルセンター',
        description = 'ルーム ' .. roomId .. ' に入りました。受付で作業を開始できます。\n現在のレベル: Lv.' .. playerLevel,
        type = 'info'
    })
end

-- ルームに入室した際のコールバック
RegisterNetEvent('ng-recycling:client:roomEntered', function(roomId)
    -- ルーム入室時の追加処理があれば追加
end)

-- リサイクルセンターから出る
function ExitRecyclingCenter()
    if not isInsideRecyclingCenter then return end
    
    -- アクティブなジョブがある場合はキャンセル
    if activeJob then
        CancelRecyclingJob()
    end
    
    local exitLocation = Config.EntranceLocations[currentWarehouse]
    local roomId = currentRoom
    
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(10)
    end
    
    -- ルームから退出
    TriggerServerEvent('ng-recycling:server:exitRoom', roomId)
    
    -- キャリー状態を解除
    if carryingBox then
        StopCarryingBox()
    end
    
    -- 外部へテレポート
    SetEntityCoords(PlayerPedId(), exitLocation.coords.x, exitLocation.coords.y, exitLocation.coords.z)
    SetEntityHeading(PlayerPedId(), exitLocation.heading)
    Wait(100)
    
    DoScreenFadeIn(500)
    
    isInsideRecyclingCenter = false
    currentWarehouse = nil
    currentRoom = nil
    
    -- 通知
    lib.notify({
        title = 'リサイクルセンター',
        description = 'リサイクルセンターから退出しました。',
        type = 'info'
    })
end

-- リサイクル作業の開始
function StartRecyclingJob()
    if activeJob or isOnCooldown then return end
    
    -- 作業開始前に重量チェック
    local weightInfo = CheckPlayerWeight()
    if weightInfo and weightInfo.percentage >= 95 then
        lib.notify({
            title = 'インベントリ満杯',
            description = 'インベントリがほぼ満杯です (' .. weightInfo.percentage .. '%)\n作業を開始する前にアイテムを整理することをお勧めします',
            type = 'warning',
            duration = 8000
        })
        
        -- 確認ダイアログを表示
        local input = lib.inputDialog('重量警告', {
            {type = 'checkbox', label = 'インベントリがほぼ満杯ですが作業を続行しますか？報酬を受け取れない可能性があります。', required = true}
        })
        
        if not input or not input[1] then
            lib.notify({
                title = 'リサイクル作業',
                description = '作業開始がキャンセルされました。',
                type = 'info'
            })
            return
        end
    end
    
    activeJob = true
    pickupPoints = {}
    collectedPickups = {}
    
    -- ランダムな収集ポイントを選択
    local shuffledLocations = {}
    
    -- シャッフルのための場所リスト作成
    for i, v in ipairs(Config.PickupLocations) do
        shuffledLocations[i] = i
    end
    
    -- ランダムに並べ替え
    for i = #shuffledLocations, 2, -1 do
        local j = math.random(i)
        shuffledLocations[i], shuffledLocations[j] = shuffledLocations[j], shuffledLocations[i]
    end
    
    -- 必要な数だけ選択
    for i = 1, Config.PickupsPerJob do
        local locationIndex = shuffledLocations[i]
        local location = Config.PickupLocations[locationIndex]
        
        local pickupData = {
            coords = location.coords,
            heading = location.heading,
            collected = false,
            index = i
        }
        
        table.insert(pickupPoints, pickupData)
        
        -- ブリップ作成
        local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
        SetBlipSprite(blip, 1)
        SetBlipColour(blip, 5)
        SetBlipScale(blip, 0.8)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("収集ポイント " .. i)
        EndTextCommandSetBlipName(blip)
        
        pickupBlips[i] = blip
    end
    
    -- 納品場所のブリップ作成
    deliveryBlip = AddBlipForCoord(Config.DeliveryLocation.coords.x, Config.DeliveryLocation.coords.y, Config.DeliveryLocation.coords.z)
    SetBlipSprite(deliveryBlip, 1)
    SetBlipColour(deliveryBlip, 3)
    SetBlipScale(deliveryBlip, 1.0)
    SetBlipRoute(deliveryBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("納品場所")
    EndTextCommandSetBlipName(deliveryBlip)
    
    -- 通知
    lib.notify({
        title = 'リサイクル作業',
        description = '作業を開始しました。マーカーの場所から荷物を回収してください。',
        type = 'success'
    })
end

-- 荷物を持つアニメーション開始
function StartCarryingBox()
    carryingBox = true
    
    local ped = PlayerPedId()
    local dict = "anim@heists@box_carry@"
    
    -- アニメーション辞書のロード
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(10)
        end
    end
    
    -- 荷物を持つアニメーションを開始
    TaskPlayAnim(ped, dict, "idle", 8.0, 8.0, -1, 51, 0, false, false, false)
    
    -- 荷物オブジェクト作成
    local boneIndex = GetPedBoneIndex(ped, 60309)
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, -0.5)
    
    local boxProp = CreateObject(GetHashKey("prop_cs_cardbox_01"), coords.x, coords.y, coords.z, true, true, true)
    AttachEntityToEntity(boxProp, ped, boneIndex, 0.025, 0.08, 0.255, -145.0, 290.0, 0.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(GetHashKey("prop_cs_cardbox_01"))
    
    -- 荷物オブジェクトを保存
    carryBoxProp = boxProp
    
    -- 移動速度制限
    SetPedMoveRateOverride(ped, 0.8)
    SetPedCanRagdoll(ped, false)
end

-- 荷物を持つアニメーション停止
function StopCarryingBox()
    if not carryingBox then return end
    
    carryingBox = false
    
    local ped = PlayerPedId()
    
    -- アニメーション停止
    ClearPedTasks(ped)
    StopAnimTask(ped, "anim@heists@box_carry@", "idle", 1.0)
    
    -- 荷物オブジェクト削除
    if carryBoxProp and DoesEntityExist(carryBoxProp) then
        DetachEntity(carryBoxProp, true, true)
        DeleteEntity(carryBoxProp)
        carryBoxProp = nil
    end
    
    -- 移動速度制限解除
    SetPedMoveRateOverride(ped, 1.0)
    SetPedCanRagdoll(ped, true)
end

-- 荷物回収（レベルによる速度ボーナス適用）
function PickupRecyclables(pointIndex)
    -- すでに回収済みならスキップ
    if pointIndex > #pickupPoints or pickupPoints[pointIndex].collected then
        return
    end
    
    -- すでに荷物を持っている場合はスキップ
    if carryingBox then
        lib.notify({
            title = 'リサイクル作業',
            description = 'すでに荷物を持っています。先に納品してください。',
            type = 'error'
        })
        return
    end
    
    -- レベルボーナスを適用した時間計算
    local baseDuration = 2000
    local adjustedDuration = math.floor(baseDuration * (1 - speedBonus))
    
    -- アニメーション再生と移動制限
    if lib.progressBar({
        duration = adjustedDuration,
        label = '荷物を回収中... (Lv.' .. playerLevel .. ')',
        useWhileDead = false,
        canCancel = false, -- キャンセル不可に変更
        disable = {
            car = true,
            move = true, -- 移動を無効化
            combat = true, -- 戦闘を無効化
            mouse = false
        },
        anim = {
            dict = 'mp_am_hold_up',
            clip = 'purchase_beerbox_shopkeeper'
        },
    }) then
        -- 荷物を持つアニメーション開始
        StartCarryingBox()
        
        -- 回収済みとしてマーク
        pickupPoints[pointIndex].collected = true
        table.insert(collectedPickups, pointIndex)
        
        -- ブリップ削除
        RemoveBlip(pickupBlips[pointIndex])
        pickupBlips[pointIndex] = nil
        
        -- 通知
        lib.notify({
            title = 'リサイクル作業',
            description = '荷物を回収しました。納品所に運んでください。',
            type = 'success'
        })
        
        -- 納品場所のルートを表示
        SetBlipRoute(deliveryBlip, true)
    else
        -- キャンセルされた場合(通常は発生しないが念のため)
        lib.notify({
            title = 'リサイクル作業',
            description = '荷物の回収がキャンセルされました。',
            type = 'error'
        })
    end
end

-- 荷物納品(レベルによる速度ボーナス適用)
function DeliverRecyclables()
    if not carryingBox then
        lib.notify({
            title = 'リサイクル作業',
            description = '荷物を持っていません。',
            type = 'error'
        })
        return
    end
    
    -- 納品前に重量チェック
    local weightInfo = CheckPlayerWeight()
    if weightInfo and weightInfo.percentage >= 90 then
        lib.notify({
            title = 'インベントリ警告',
            description = 'インベントリがほぼ満杯です (' .. weightInfo.percentage .. '%)\n報酬を受け取れない可能性があります',
            type = 'warning',
            duration = 5000
        })
        
        -- 確認ダイアログを表示
        local input = lib.inputDialog('重量警告', {
            {type = 'checkbox', label = 'インベントリがほぼ満杯ですが納品を続行しますか？報酬の一部または全部を受け取れない可能性があります。', required = true}
        })
        
        if not input or not input[1] then
            lib.notify({
                title = 'リサイクル作業',
                description = '納品がキャンセルされました。',
                type = 'info'
            })
            return
        end
    end
    
    -- レベルボーナスを適用した時間計算
    local baseDuration = 3000
    local adjustedDuration = math.floor(baseDuration * (1 - speedBonus))
    
    -- アニメーション再生と移動制限
    if lib.progressBar({
        duration = adjustedDuration,
        label = '荷物を納品中... (Lv.' .. playerLevel .. ')',
        useWhileDead = false,
        canCancel = false, -- キャンセル不可に変更
        disable = {
            car = true,
            move = true, -- 移動を無効化
            combat = true, -- 戦闘を無効化
            mouse = false
        },
        anim = {
            dict = 'mp_am_hold_up',
            clip = 'purchase_beerbox_shopkeeper'
        },
    }) then
        -- 荷物を持つアニメーション停止
        StopCarryingBox()
        
        -- 納品カウント
        local deliveredCount = #collectedPickups
        
        -- 全ての荷物を納品したかチェック
        local allPickupsCollected = true
        for _, pickup in pairs(pickupPoints) do
            if not pickup.collected then
                allPickupsCollected = false
                break
            end
        end
        
        -- 報酬付与
        TriggerServerEvent('ng-recycling:server:rewardDelivery', deliveredCount, allPickupsCollected)
        
        -- 全て納品したらジョブ完了
        if allPickupsCollected then
            -- ジョブ完了処理
            CancelRecyclingJob(true)
            
            -- クールダウン設定
            isOnCooldown = true
            local cooldownTime = 3 -- 3秒
            
            -- クールダウン通知
            lib.notify({
                title = 'リサイクル作業',
                description = cooldownTime .. '秒間のクールダウンが始まりました',
                type = 'info'
            })
            
            -- クールダウンタイマー
            CreateThread(function()
                local startTime = GetGameTimer()
                local endTime = startTime + (cooldownTime * 1000)
                
                while GetGameTimer() < endTime do
                    Wait(1000) -- 1秒ごとに更新
                    local timeLeft = math.ceil((endTime - GetGameTimer()) / 1000)
                    
                    if timeLeft <= 0 then
                        isOnCooldown = false
                        lib.notify({
                            title = 'リサイクル作業',
                            description = 'クールダウンが終了しました。新しい作業を開始できます',
                            type = 'success'
                        })
                        break
                    end
                end
            end)
            
            -- 通知
            lib.notify({
                title = 'リサイクル作業',
                description = 'すべての荷物の納品が完了しました。報酬を受け取りました。',
                type = 'success'
            })
        else
            -- まだ納品が残っている場合
            collectedPickups = {} -- 納品済みをリセット
            
            -- 通知
            lib.notify({
                title = 'リサイクル作業',
                description = '荷物を納品しました。残りの荷物も回収してください。',
                type = 'success'
            })
        end
    else
        -- キャンセルされた場合(通常は発生しないが念のため)
        lib.notify({
            title = 'リサイクル作業',
            description = '荷物の納品がキャンセルされました。',
            type = 'error'
        })
    end
end

-- リサイクル作業のキャンセル
function CancelRecyclingJob(completed)
    if not activeJob then return end
    
    -- ブリップ削除
    for _, blip in pairs(pickupBlips) do
        if blip then
            RemoveBlip(blip)
        end
    end
    
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
    end
    
    -- キャリー状態を解除
    if carryingBox then
        StopCarryingBox()
    end
    
    -- 変数リセット
    pickupBlips = {}
    pickupPoints = {}
    collectedPickups = {}
    deliveryBlip = nil
    activeJob = false
    
    -- 全タスク完了時のクールダウン設定
    if completed then
        isOnCooldown = true
        local cooldownTime = 3 -- 3秒
        
        -- クールダウン通知
        lib.notify({
            title = 'リサイクル作業',
            description = cooldownTime .. '秒間のクールダウンが始まりました',
            type = 'info'
        })
        
        -- クールダウンタイマー
        CreateThread(function()
            local startTime = GetGameTimer()
            local endTime = startTime + (cooldownTime * 1000)
            
            while GetGameTimer() < endTime do
                Wait(1000) -- 1秒ごとに更新
                local timeLeft = math.ceil((endTime - GetGameTimer()) / 1000)
                
                if timeLeft <= 0 then
                    isOnCooldown = false
                    lib.notify({
                        title = 'リサイクル作業',
                        description = 'クールダウンが終了しました。新しい作業を開始できます',
                        type = 'success'
                    })
                    break
                end
            end
        end)
    else
        -- 完了していない場合のみ通知
        lib.notify({
            title = 'リサイクル作業',
            description = '作業がキャンセルされました。',
            type = 'error'
        })
    end
end

-- ヘルプテキスト表示（FloatingHelpText）
function ShowHelpNotification(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

-- 緊急脱出ポータルの座標
local EmergencyExitCoords = vector3(1072.39, -3094.93, -39.0)

-- 緊急脱出処理
local function UseEmergencyExit()
    local exitLocation = Config.EntranceLocations[1]
    
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(10)
    end
    
    -- ルームから退出（内部にいた場合）
    if currentRoom then
        TriggerServerEvent('ng-recycling:server:exitRoom', currentRoom)
    end
    
    -- キャリー状態を解除
    if carryingBox then
        StopCarryingBox()
    end
    
    -- アクティブなジョブをキャンセル
    if activeJob then
        CancelRecyclingJob()
    end
    
    -- 外部へテレポート
    SetEntityCoords(PlayerPedId(), exitLocation.coords.x, exitLocation.coords.y, exitLocation.coords.z)
    SetEntityHeading(PlayerPedId(), exitLocation.heading)
    Wait(100)
    
    DoScreenFadeIn(500)
    
    isInsideRecyclingCenter = false
    currentWarehouse = nil
    currentRoom = nil
    
    lib.notify({
        title = 'リサイクルセンター',
        description = '緊急脱出ポータルを使用しました。',
        type = 'success'
    })
end

-- マーカーの確認とヘルプテキスト表示
local function HandleMarkers()
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local isInMarker = false
    local currentZoneType = nil
    local currentZoneData = nil
    
    -- 緊急脱出ポータル（常に表示）
    local emergencyDistance = #(pedCoords - EmergencyExitCoords)
    if emergencyDistance < 15.0 then
        -- マーカー描画（紫色の大きなマーカー）
        DrawMarker(1, EmergencyExitCoords.x, EmergencyExitCoords.y, EmergencyExitCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 1.5, 128, 0, 128, 150, false, true, 2, false, nil, nil, false)
        
        -- ヘルプテキスト表示
        if emergencyDistance < 2.0 then
            ShowHelpNotification('~INPUT_CONTEXT~ で緊急脱出する')
            isInMarker = true
            currentZoneType = "emergency_exit"
        end
    end
    
    -- 入口マーカー
    if not isInsideRecyclingCenter then
        for k, v in pairs(Config.EntranceLocations) do
            local distance = #(pedCoords - v.coords)
            if distance < 15.0 then
                -- マーカー描画
                DrawMarker(1, v.coords.x, v.coords.y, v.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0, 0, 120, 255, 100, false, true, 2, false, nil, nil, false)
                
                -- ヘルプテキスト表示
                if distance < 1.5 then
                    ShowHelpNotification('~INPUT_CONTEXT~ でリサイクルセンターに入る')
                    isInMarker = true
                    currentZoneType = "entrance"
                    currentZoneData = {id = k}
                end
            end
        end
    else
        -- 出口マーカー
        local exitCoords = Config.RecyclingInterior.coords
        local distance = #(pedCoords - exitCoords)
        if distance < 15.0 then
            -- マーカー描画
            DrawMarker(1, exitCoords.x, exitCoords.y, exitCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)
            
            -- ヘルプテキスト表示
            if distance < 1.5 then
                ShowHelpNotification('~INPUT_CONTEXT~ でリサイクルセンターから出る')
                isInMarker = true
                currentZoneType = "exit"
            end
        end
        
        -- ジョブ開始マーカー
        if not activeJob then
            local startCoords = Config.JobStartLocation.coords
            local distance = #(pedCoords - startCoords)
            if distance < 15.0 then
                -- マーカー描画
                DrawMarker(1, startCoords.x, startCoords.y, startCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0, 0, 255, 0, 100, false, true, 2, false, nil, nil, false)
                
                -- ヘルプテキスト表示
                if distance < 1.5 then
                    if isOnCooldown then
                        ShowHelpNotification('クールダウン中です。しばらくお待ちください')
                    else
                        ShowHelpNotification('~INPUT_CONTEXT~ で作業を開始する | ~INPUT_DETONATE~ でレベル情報表示')
                        isInMarker = true
                        currentZoneType = "job_start"
                    end
                end
            end
        end
        
        -- 納品マーカー
        if activeJob and carryingBox then
            local deliveryCoords = Config.DeliveryLocation.coords
            local distance = #(pedCoords - deliveryCoords)
            if distance < 15.0 then
                -- マーカー描画
                DrawMarker(1, deliveryCoords.x, deliveryCoords.y, deliveryCoords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0, 255, 255, 0, 100, false, true, 2, false, nil, nil, false)
                
                -- ヘルプテキスト表示
                if distance < 1.5 then
                    ShowHelpNotification('~INPUT_CONTEXT~ で荷物を納品する')
                    isInMarker = true
                    currentZoneType = "delivery"
                end
            end
        end
        
        -- 収集ポイントマーカー
        if activeJob and not carryingBox then
            for i, pickup in ipairs(pickupPoints) do
                if not pickup.collected then
                    local distance = #(pedCoords - pickup.coords)
                    if distance < 15.0 then
                        -- マーカー描画
                        DrawMarker(1, pickup.coords.x, pickup.coords.y, pickup.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0, 255, 165, 0, 100, false, true, 2, false, nil, nil, false)
                        
                        -- ヘルプテキスト表示
                        if distance < 1.5 then
                            ShowHelpNotification('~INPUT_CONTEXT~ で荷物を回収する')
                            isInMarker = true
                            currentZoneType = "pickup"
                            currentZoneData = {index = i}
                        end
                    end
                end
            end
        end
    end
    
    -- マーカー状態の更新
    if isInMarker and not inMarkerZone then
        inMarkerZone = true
        currentZone = {type = currentZoneType, data = currentZoneData}
    end
    
    if not isInMarker and inMarkerZone then
        inMarkerZone = false
        currentZone = nil
    end
end

-- キー入力の処理
local function HandleKeyInput()
    if inMarkerZone and IsControlJustReleased(0, 38) then -- Eキー
        if currentZone.type == "entrance" then
            EnterRecyclingCenter(currentZone.data.id)
        elseif currentZone.type == "exit" then
            ExitRecyclingCenter()
        elseif currentZone.type == "emergency_exit" then
            UseEmergencyExit()
        elseif currentZone.type == "job_start" then
            StartRecyclingJob()
        elseif currentZone.type == "delivery" then
            DeliverRecyclables()
        elseif currentZone.type == "pickup" then
            PickupRecyclables(currentZone.data.index)
        end
    end
    
    -- Gキーでレベル情報表示（ジョブ開始マーカー付近のみ）
    if inMarkerZone and currentZone.type == "job_start" and IsControlJustReleased(0, 47) then -- Gキー
        ShowLevelInfo()
    end
end

-- プレイヤースポーン時
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    CreateEntrancePoint()
    SetupInterior()
    LoadPlayerLevel()
end)

-- リソース開始時
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        CreateEntrancePoint()
        SetupInterior()
        
        -- プレイヤーがリサイクルセンター内にいる場合は状態を復元
        CreateThread(function()
            Wait(1000) -- サーバー接続を待つ
            
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            local interiorCoords = Config.RecyclingInterior.coords
            local distance = #(pedCoords - interiorCoords)
            
            -- 内部座標から100m以内、またはZ座標が-39.0付近（内部の高さ）にいる場合
            if distance < 100.0 or (pedCoords.z < -30.0 and pedCoords.z > -50.0) then
                -- 内部にいることを認識
                isInsideRecyclingCenter = true
                
                -- サーバーから復元情報を取得してルームに再参加
                -- 注: これはサーバー側で実装が必要
                
                lib.notify({
                    title = 'リサイクルセンター',
                    description = '出口マーカーから退出できます。',
                    type = 'info',
                    duration = 5000
                })
                
                -- レベル情報を読み込み
                LoadPlayerLevel()
            end
        end)
    end
end)

-- リソース停止時
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- キャリー状態を解除
        if carryingBox then
            StopCarryingBox()
        end
        
        -- リサイクルセンター内の場合は強制退出
        if isInsideRecyclingCenter and currentRoom then
            TriggerServerEvent('ng-recycling:server:exitRoom', currentRoom)
        end
    end
end)

-- メインループ
CreateThread(function()
    while true do
        HandleMarkers()
        HandleKeyInput()
        Wait(0)
    end
end)