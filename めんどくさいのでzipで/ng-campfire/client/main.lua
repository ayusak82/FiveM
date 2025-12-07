local QBCore = exports['qb-core']:GetCoreObject()
local activeCampfires = {}
local playerInHealingZone = false
local ownCampfire = nil

-- 焚火オブジェクトを設置する関数
local function PlaceCampfire()
    -- 車両に乗っているかチェック
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        lib.notify({
            title = '焚火',
            description = '車両から降りて使用してください',
            type = 'error'
        })
        return
    end
    
    if ownCampfire then
        lib.notify({
            title = '焚火',
            description = Config.Notifications.alreadyHave,
            type = 'error'
        })
        return
    end

    if Config.RequireItem then
        local hasItem = QBCore.Functions.HasItem(Config.RequiredItem)
        if not hasItem then
            lib.notify({
                title = '焚火',
                description = Config.RequiredItem .. 'が必要です',
                type = 'error'
            })
            return
        end
    end

    -- アニメーションの実行
    local playerPed = PlayerPedId()
    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_GARDENER_PLANT", 0, true)
    
    -- プログレスバーの表示
    if lib.progressBar({
        duration = 5000,
        label = '焚火を設置中...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'amb@world_human_tourist_map@male@base',
            clip = 'base'
        },
    }) then
        -- プログレスバー完了後の処理
        ClearPedTasks(playerPed)
        
        -- プレイヤーの前方の座標を取得
        local playerCoords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        local forward = GetEntityForwardVector(playerPed)
        local x = playerCoords.x + forward.x * 1.5
        local y = playerCoords.y + forward.y * 1.5
        local z = playerCoords.z - 1.0
        
        -- サーバーに焚火設置を要求
        TriggerServerEvent('ng-campfire:server:placeCampfire', vector3(x, y, z), heading)
    else
        -- キャンセルされた場合
        ClearPedTasks(playerPed)
    end
end

-- 焚火を設置するイベントハンドラ（サーバーからの応答）
RegisterNetEvent('ng-campfire:client:placeCampfire')
AddEventHandler('ng-campfire:client:placeCampfire', function(campfireId, coords, heading)
    -- 焚火プロップの生成
    local hash = GetHashKey(Config.CampfireProp)
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(0)
    end
    
    local campfireObj = CreateObject(hash, coords.x, coords.y, coords.z, true, false, false)
    SetEntityHeading(campfireObj, heading)
    PlaceObjectOnGroundProperly(campfireObj)
    FreezeEntityPosition(campfireObj, true)
    
    -- 焚火情報を保存
    activeCampfires[campfireId] = {
        object = campfireObj,
        coords = GetEntityCoords(campfireObj),
        blip = nil
    }
    
    -- 自分が設置した焚火かどうかを確認
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    if #(playerCoords - coords) < 10.0 then
        ownCampfire = campfireId
        
        -- 焚火の消滅タイマーを設定
        Citizen.CreateThread(function()
            Citizen.Wait(Config.DurationMinutes * 60 * 1000)
            if activeCampfires[campfireId] then
                TriggerServerEvent('ng-campfire:server:removeCampfire', campfireId)
                lib.notify({
                    title = '焚火',
                    description = Config.Notifications.expired,
                    type = 'inform'
                })
            end
        end)
    end
    
    -- ミニマップにブリップを追加
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 648) -- 焚火アイコン
    SetBlipColour(blip, 1) -- 赤色
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("焚火")
    EndTextCommandSetBlipName(blip)
    
    activeCampfires[campfireId].blip = blip
    
    -- 通知
    lib.notify({
        title = '焚火',
        description = Config.Notifications.placed,
        type = 'success'
    })
end)

-- 焚火を削除するイベントハンドラ
RegisterNetEvent('ng-campfire:client:removeCampfire')
AddEventHandler('ng-campfire:client:removeCampfire', function(campfireId)
    if activeCampfires[campfireId] then
        -- 焚火オブジェクトの削除
        if DoesEntityExist(activeCampfires[campfireId].object) then
            DeleteObject(activeCampfires[campfireId].object)
        end
        
        -- ブリップの削除
        if activeCampfires[campfireId].blip then
            RemoveBlip(activeCampfires[campfireId].blip)
        end
        
        -- 自分の焚火だった場合はリセット
        if ownCampfire == campfireId then
            ownCampfire = nil
        end
        
        -- 焚火情報を削除
        activeCampfires[campfireId] = nil
    end
end)

-- 焚火の回復効果を処理するスレッド
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local inHealingZone = false
        
        -- 全ての焚火との距離をチェック
        for campfireId, campfire in pairs(activeCampfires) do
            local dist = #(playerCoords - campfire.coords)
            if dist <= Config.HealingRadius then
                inHealingZone = true
                break
            end
        end
        
        -- ゾーンの出入りを処理
        if inHealingZone and not playerInHealingZone then
            playerInHealingZone = true
            -- 回復効果開始
            lib.notify({
                title = '焚火',
                description = Config.Notifications.entering,
                type = 'inform'
            })
            StartHealingEffect()
        elseif not inHealingZone and playerInHealingZone then
            playerInHealingZone = false
            -- 回復効果終了
            lib.notify({
                title = '焚火',
                description = Config.Notifications.leaving,
                type = 'inform'
            })
        end
    end
end)

-- 回復効果を処理する関数
function StartHealingEffect()
    Citizen.CreateThread(function()
        while playerInHealingZone do
            Citizen.Wait(Config.HealInterval)
            
            local playerPed = PlayerPedId()
            
            -- 体力回復
            local currentHealth = GetEntityHealth(playerPed)
            local maxHealth = GetEntityMaxHealth(playerPed)
            
            if currentHealth < maxHealth then
                SetEntityHealth(playerPed, math.min(currentHealth + Config.HealthRegenAmount, maxHealth))
            end
            
            -- ストレス軽減（qb-stressが有効な場合）
            TriggerServerEvent('ng-campfire:server:reduceStress')
        end
    end)
end

-- コマンド登録
RegisterCommand(Config.Command, function()
    PlaceCampfire()
end, false)

-- キーマッピング登録
RegisterKeyMapping(Config.Command, '焚火を設置する', 'keyboard', '')

-- アイテムから焚火を設置するイベント（ox_inventoryから使用）
RegisterNetEvent('ng-campfire:client:placeFromItem')
AddEventHandler('ng-campfire:client:placeFromItem', function(data, slot)
    -- ox_inventoryからはdata, slotパラメータが渡されることがあります
    -- この場合は単にPlaceCampfireを呼び出します
    PlaceCampfire()
end)

-- 焚火を削除するコマンド
RegisterCommand('removecampfire', function()
    if ownCampfire then
        TriggerServerEvent('ng-campfire:server:removeCampfire', ownCampfire)
        lib.notify({
            title = '焚火',
            description = Config.Notifications.removed,
            type = 'success'
        })
    else
        lib.notify({
            title = '焚火',
            description = '自分の焚火がありません',
            type = 'error'
        })
    end
end, false)

-- ox_targetの統合（オプション）
if GetResourceState('ox_target') ~= 'missing' then
    exports.ox_target:addGlobalObject({
        name = Config.CampfireProp,
        label = '焚火を使用',
        icon = 'fas fa-fire',
        distance = 2.5,
        onSelect = function(data)
            lib.showContext('campfire_menu')
        end
    })
    
    -- 焚火のコンテキストメニュー
    lib.registerContext({
        id = 'campfire_menu',
        title = '焚火',
        options = {
            {
                title = '体を温める',
                description = '焚火に当たって体を温めます',
                icon = 'temperature-high',
                onSelect = function()
                    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_STAND_FIRE", 0, true)
                    Citizen.Wait(5000)
                    ClearPedTasks(PlayerPedId())
                end
            },
            {
                title = '焚火を片付ける',
                description = '自分の焚火を片付けます',
                icon = 'trash',
                onSelect = function()
                    if ownCampfire then
                        TriggerServerEvent('ng-campfire:server:removeCampfire', ownCampfire)
                        lib.notify({
                            title = '焚火',
                            description = Config.Notifications.removed,
                            type = 'success'
                        })
                    else
                        lib.notify({
                            title = '焚火',
                            description = '自分の焚火ではありません',
                            type = 'error'
                        })
                    end
                end
            }
        }
    })
end