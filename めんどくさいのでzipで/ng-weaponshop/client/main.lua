local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local shopOpen = false
local shopNPCs = {}

-- プレイヤーデータのロード
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    -- プレイヤーデータがロードされた時点でショップを初期化
    Wait(1000) -- 少し待機してから実行
    InitializeShops()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

-- NPCの生成
local function CreateShopPed(data)
    local pedModel = data.pedModel
    local coords = data.coords
    local peds = GetGamePool('CPed')
    
    -- 近くに既存のNPCがいるかチェック
    for _, ped in ipairs(peds) do
        local pedCoords = GetEntityCoords(ped)
        local distance = #(vector3(coords.x, coords.y, coords.z) - pedCoords)
        
        if distance < 3.0 then
            DeleteEntity(ped)
        end
    end
    
    -- NPCモデルのロード
    lib.requestModel(pedModel, 500)
    
    -- NPCの生成
    local ped = CreatePed(4, pedModel, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    
    -- NPCの設定
    SetEntityCanBeDamaged(ped, false)
    SetPedCanBeTargetted(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetPedResetFlag(ped, 249, true)
    SetPedConfigFlag(ped, 185, true)
    SetPedConfigFlag(ped, 108, true)
    SetPedConfigFlag(ped, 208, true)
    FreezeEntityPosition(ped, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    
    -- NPCのアニメーションを設定
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", 0, true)
    
    table.insert(shopNPCs, ped)
    return ped
end

-- ブリップの生成
local function CreateShopBlip(data)
    if not data.blip or not data.blip.enable then return end
    
    local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipSprite(blip, data.blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, data.blip.scale)
    SetBlipColour(blip, data.blip.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(data.blip.label)
    EndTextCommandSetBlipName(blip)
end

-- ショップUIを開く
local function OpenWeaponShop()
    if shopOpen then return end
    shopOpen = true
    
    -- NUIを表示
    SendNUIMessage({
        action = 'open',
        items = Config.Items,
        config = Config.UI,
        paymentMethods = Config.PaymentMethods
    })
    
    -- マウスカーソルを表示
    SetNuiFocus(true, true)
end

-- NUIからのコールバック
RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    shopOpen = false
    cb('ok')
end)

RegisterNUICallback('buyItem', function(data, cb)
    if not data.item or not data.paymentMethod then
        cb({status = 'error', message = '必要なデータが不足しています'})
        return
    end
    
    -- サーバーサイドで購入処理
    QBCore.Functions.TriggerCallback('ng-weaponshop:server:buyItem', function(success, message)
        cb({status = success and 'success' or 'error', message = message})
    end, data.item, data.paymentMethod)
end)

-- カート内のアイテムを購入するコールバック
RegisterNUICallback('buyItems', function(data, cb)
    if not data.items or #data.items == 0 or not data.paymentMethod then
        cb({status = 'error', message = '必要なデータが不足しています'})
        return
    end
    
    -- サーバーサイドで購入処理
    QBCore.Functions.TriggerCallback('ng-weaponshop:server:buyItems', function(success, message)
        cb({status = success and 'success' or 'error', message = message})
    end, data.items, data.paymentMethod)
end)

-- ショップを初期化する関数
local function InitializeShops()
    -- 既存のNPCを削除
    for _, ped in ipairs(shopNPCs) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    shopNPCs = {}
    
    -- 新しいNPCを生成
    for _, location in pairs(Config.Locations) do
        -- NPCを生成
        local ped = CreateShopPed(location)
        
        -- ブリップを生成
        CreateShopBlip(location)
        
        -- ターゲットオプションを追加
        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'weaponshop_open',
                icon = 'fas fa-gun',
                label = '武器ショップを開く',
                distance = 2.0,
                onSelect = function()
                    OpenWeaponShop()
                end
            }
        })
    end
end

-- 初期起動時にショップを初期化
CreateThread(function()
    -- サーバーが完全に起動するのを待つ
    Wait(3000)
    InitializeShops()
end)

-- プレイヤーがスポーンしたときのショップ初期化はすでに上部で行っています

-- リソース起動時にショップを初期化
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    -- 少し待機してから実行（リソースが完全にロードされるのを待つ）
    Wait(2000)
    InitializeShops()
end)

-- リソース終了時にNPCを削除
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    for _, ped in ipairs(shopNPCs) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
end)

-- キーを押して閉じる
CreateThread(function()
    while true do
        Wait(0)
        if shopOpen and IsControlJustReleased(0, 177) then -- ESCキー
            SetNuiFocus(false, false)
            SendNUIMessage({action = 'close'})
            shopOpen = false
        end
    end
end)