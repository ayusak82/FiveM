local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local placedItems = {}
local previewObject = nil
local isPlacing = false
local currentSeat = nil

-- プレイヤーデータ取得
CreateThread(function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

-- アイテム設置開始
RegisterNetEvent('ng-camping:client:startPlacement', function(itemType)
    if isPlacing then
        lib.notify({
            title = Config.Notifications.error.title,
            description = '既に設置中です',
            type = Config.Notifications.error.type,
            duration = Config.Notifications.error.duration
        })
        return
    end

    local itemConfig = Config.CampingItems[itemType]
    if not itemConfig then return end

    -- アイテム所持チェック（臨時で無効化）
    --[[
    local hasItem = exports.ox_inventory:Search('count', itemConfig.item)
    if hasItem < 1 then
        lib.notify({
            title = Config.Notifications.error.title,
            description = itemConfig.label .. 'を持っていません',
            type = Config.Notifications.error.type,
            duration = Config.Notifications.error.duration
        })
        return
    end
    --]]

    startPlacementMode(itemType, itemConfig)
end)

-- 設置モード開始
function startPlacementMode(itemType, itemConfig)
    isPlacing = true
    
    -- プレビューオブジェクト作成
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    lib.requestModel(itemConfig.model)
    previewObject = CreateObject(GetHashKey(itemConfig.model), coords.x, coords.y, coords.z, false, false, false)
    SetEntityAlpha(previewObject, 150, false)
    SetEntityCollision(previewObject, false, false)
    
    lib.notify({
        title = Config.Notifications.info.title,
        description = '[E] 設置 | [X] キャンセル',
        type = Config.Notifications.info.type,
        duration = 5000
    })
    
    -- 設置ループ
    CreateThread(function()
        while isPlacing do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local forward = GetEntityForwardVector(ped)
            local placement = coords + forward * 3.0
            
            -- 地面の高さ取得
            local _, groundZ = GetGroundZFor_3dCoord(placement.x, placement.y, placement.z + 10.0, false)
            placement = vector3(placement.x, placement.y, groundZ)
            
            -- プレビュー更新
            SetEntityCoords(previewObject, placement.x, placement.y, placement.z, false, false, false, false)
            
            -- 設置可能チェック
            local canPlace = canPlaceItem(placement, itemType)
            if canPlace then
                SetEntityAlpha(previewObject, 200, false)
            else
                SetEntityAlpha(previewObject, 100, false)
            end
            
            -- 入力チェック
            if IsControlJustPressed(0, 38) then -- E
                if canPlace then
                    placeItem(itemType, itemConfig, placement)
                else
                    lib.notify({
                        title = Config.Notifications.error.title,
                        description = 'ここには設置できません',
                        type = Config.Notifications.error.type,
                        duration = Config.Notifications.error.duration
                    })
                end
            elseif IsControlJustPressed(0, 73) then -- X
                cancelPlacement()
            end
            
            Wait(0)
        end
    end)
end

-- 設置可能チェック
function canPlaceItem(coords, itemType)
    -- 他のアイテムとの距離チェック
    for _, item in pairs(placedItems) do
        if #(coords - GetEntityCoords(item.object)) < 2.0 then
            return false
        end
    end
    
    -- プレイヤーとの距離チェック
    local players = GetActivePlayers()
    for _, playerId in pairs(players) do
        local playerPed = GetPlayerPed(playerId)
        if playerPed ~= PlayerPedId() then
            local playerCoords = GetEntityCoords(playerPed)
            if #(coords - playerCoords) < Config.PlacementLimits.minPlayerDistance then
                return false
            end
        end
    end
    
    -- 禁止エリアチェック
    for _, blockedZone in pairs(Config.PlacementLimits.blockedZones) do
        if #(coords - blockedZone) < 50.0 then
            return false
        end
    end
    
    return true
end

-- アイテム設置
function placeItem(itemType, itemConfig, coords)
    -- アニメーション再生
    local ped = PlayerPedId()
    lib.requestAnimDict(Config.Animations.place.dict)
    TaskPlayAnim(ped, Config.Animations.place.dict, Config.Animations.place.anim, 8.0, -8.0, Config.Animations.place.duration, 1, 0, false, false, false)
    
    -- プログレスバー
    if lib.progressBar({
        duration = Config.Animations.place.duration,
        label = itemConfig.label .. 'を設置中...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    }) then
        -- サーバーに設置要求
        TriggerServerEvent('ng-camping:server:placeItem', itemType, coords, GetEntityHeading(ped))
        cancelPlacement()
    else
        ClearPedTasks(ped)
        cancelPlacement()
    end
end

-- 設置キャンセル
function cancelPlacement()
    isPlacing = false
    if previewObject then
        DeleteObject(previewObject)
        previewObject = nil
    end
end

-- アイテム設置成功
RegisterNetEvent('ng-camping:client:itemPlaced', function(itemData)
    local itemConfig = Config.CampingItems[itemData.type]
    
    -- オブジェクト作成
    lib.requestModel(itemConfig.model)
    local object = CreateObject(GetHashKey(itemConfig.model), itemData.coords.x, itemData.coords.y, itemData.coords.z, true, false, false)
    SetEntityHeading(object, itemData.heading)
    
    -- ローカルデータに追加
    placedItems[itemData.id] = {
        id = itemData.id,
        type = itemData.type,
        object = object,
        coords = itemData.coords,
        owner = itemData.owner
    }
    
    -- ox_target追加
    exports.ox_target:addLocalEntity(object, Config.TargetOptions[itemData.type])
    
    lib.notify({
        title = Config.Notifications.success.title,
        description = itemConfig.label .. 'を設置しました',
        type = Config.Notifications.success.type,
        duration = Config.Notifications.success.duration
    })
end)

-- アイテム撤去
RegisterNetEvent('ng-camping:client:removeItem', function(entity, itemType)
    local itemId = nil
    
    -- アイテムID検索
    for id, item in pairs(placedItems) do
        if item.object == entity then
            itemId = id
            break
        end
    end
    
    if not itemId then return end
    
    -- 権限チェック
    local item = placedItems[itemId]
    if item.owner ~= PlayerData.citizenid then
        lib.notify({
            title = Config.Notifications.error.title,
            description = '他の人のアイテムは撤去できません',
            type = Config.Notifications.error.type,
            duration = Config.Notifications.error.duration
        })
        return
    end
    
    -- アニメーション再生
    local ped = PlayerPedId()
    lib.requestAnimDict(Config.Animations.remove.dict)
    TaskPlayAnim(ped, Config.Animations.remove.dict, Config.Animations.remove.anim, 8.0, -8.0, Config.Animations.remove.duration, 1, 0, false, false, false)
    
    -- プログレスバー
    if lib.progressBar({
        duration = Config.Animations.remove.duration,
        label = Config.CampingItems[itemType].label .. 'を撤去中...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    }) then
        -- サーバーに撤去要求
        TriggerServerEvent('ng-camping:server:removeItem', itemId)
    else
        ClearPedTasks(ped)
    end
end)

-- アイテム撤去成功
RegisterNetEvent('ng-camping:client:itemRemoved', function(itemId, itemType)
    if placedItems[itemId] then
        -- ox_target削除
        exports.ox_target:removeLocalEntity(placedItems[itemId].object, Config.TargetOptions[itemType])
        
        -- オブジェクト削除
        DeleteObject(placedItems[itemId].object)
        placedItems[itemId] = nil
        
        lib.notify({
            title = Config.Notifications.success.title,
            description = Config.CampingItems[itemType].label .. 'を撤去しました',
            type = Config.Notifications.success.type,
            duration = Config.Notifications.success.duration
        })
    end
end)

-- 椅子に座る
RegisterNetEvent('ng-camping:client:sitOnChair', function(entity)
    if currentSeat then
        -- 既に座っている場合は立ち上がる
        local ped = PlayerPedId()
        ClearPedTasks(ped)
        currentSeat = nil
    else
        -- 椅子に座る
        local ped = PlayerPedId()
        local coords = GetEntityCoords(entity)
        local heading = GetEntityHeading(entity)
        
        SetEntityCoords(ped, coords.x, coords.y, coords.z + 0.5, false, false, false, false)
        SetEntityHeading(ped, heading + 180.0)
        
        lib.requestAnimDict(Config.Animations.sit.dict)
        TaskPlayAnim(ped, Config.Animations.sit.dict, Config.Animations.sit.anim, 8.0, -8.0, -1, Config.Animations.sit.flag, 0, false, false, false)
        
        currentSeat = entity
        
        lib.notify({
            title = Config.Notifications.info.title,
            description = '[E] で立ち上がります',
            type = Config.Notifications.info.type,
            duration = 3000
        })
    end
end)

-- テントに入る
RegisterNetEvent('ng-camping:client:enterTent', function(entity)
    lib.notify({
        title = Config.Notifications.info.title,
        description = 'テント機能は開発中です',
        type = Config.Notifications.info.type,
        duration = Config.Notifications.info.duration
    })
end)

-- 料理する
RegisterNetEvent('ng-camping:client:cookFood', function(entity)
    lib.notify({
        title = Config.Notifications.info.title,
        description = '料理機能は開発中です',
        type = Config.Notifications.info.type,
        duration = Config.Notifications.info.duration
    })
end)

-- サーバーから設置済みアイテム受信
RegisterNetEvent('ng-camping:client:loadItems', function(items)
    for _, itemData in pairs(items) do
        local itemConfig = Config.CampingItems[itemData.type]
        
        -- オブジェクト作成
        lib.requestModel(itemConfig.model)
        local object = CreateObject(GetHashKey(itemConfig.model), itemData.coords.x, itemData.coords.y, itemData.coords.z, true, false, false)
        SetEntityHeading(object, itemData.heading)
        
        -- ローカルデータに追加
        placedItems[itemData.id] = {
            id = itemData.id,
            type = itemData.type,
            object = object,
            coords = itemData.coords,
            owner = itemData.owner
        }
        
        -- ox_target追加
        exports.ox_target:addLocalEntity(object, Config.TargetOptions[itemData.type])
    end
end)

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    -- 全オブジェクト削除
    for _, item in pairs(placedItems) do
        if DoesEntityExist(item.object) then
            DeleteObject(item.object)
        end
    end
    
    -- プレビューオブジェクト削除
    if previewObject then
        DeleteObject(previewObject)
    end
    
    -- 座り状態解除
    if currentSeat then
        local ped = PlayerPedId()
        ClearPedTasks(ped)
    end
end)

-- テスト用コマンド追加
RegisterCommand('tent', function()
    TriggerEvent('ng-camping:client:startPlacement', 'tent')
end, false)

RegisterCommand('chair', function()
    TriggerEvent('ng-camping:client:startPlacement', 'chair')
end, false)

RegisterCommand('campfire', function()
    TriggerEvent('ng-camping:client:startPlacement', 'campfire')
end, false)