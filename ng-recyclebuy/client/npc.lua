local QBCore = exports['qb-core']:GetCoreObject()
local spawnedPeds = {}

-- デバッグ出力関数
local function DebugPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^3[DEBUG]^7 ' .. message)
end

-- NPCをスポーンする関数
local function SpawnRecyclePed(location)
    local pedModel = location.ped.model
    
    -- モデルをリクエスト
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(10)
    end
    
    -- NPCを作成
    local ped = CreatePed(4, pedModel, location.coords.x, location.coords.y, location.coords.z - 1.0, location.coords.w, false, true)
    
    -- NPCの設定
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    
    -- シナリオを設定
    if location.ped.scenario then
        TaskStartScenarioInPlace(ped, location.ped.scenario, 0, true)
    end
    
    DebugPrint('Spawned recycle ped at', location.coords)
    
    return ped
end

-- ブリップを作成する関数
local function CreateRecycleBlip(location)
    if not location.blip.enabled then return end
    
    local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
    SetBlipSprite(blip, location.blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, location.blip.scale)
    SetBlipColour(blip, location.blip.color)
    SetBlipAsShortRange(blip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(location.blip.label)
    EndTextCommandSetBlipName(blip)
    
    DebugPrint('Created recycle blip at', location.coords)
    
    return blip
end

-- NPCとブリップを初期化
CreateThread(function()
    for i, location in ipairs(Config.RecycleLocations) do
        -- ブリップを作成
        local blip = CreateRecycleBlip(location)
        
        -- NPCをスポーン
        local ped = SpawnRecyclePed(location)
        
        -- スポーンしたPedを保存
        table.insert(spawnedPeds, {
            ped = ped,
            blip = blip,
            coords = location.coords
        })
    end
    
    DebugPrint('All recycle NPCs and blips created')
end)

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for _, data in ipairs(spawnedPeds) do
        if DoesEntityExist(data.ped) then
            DeleteEntity(data.ped)
        end
        if DoesBlipExist(data.blip) then
            RemoveBlip(data.blip)
        end
    end
    
    DebugPrint('Cleaned up all recycle NPCs and blips')
end)

-- スポーンしたPedのデータを取得する関数(エクスポート)
function GetSpawnedPeds()
    return spawnedPeds
end

-- エクスポートとして公開
exports('GetSpawnedPeds', GetSpawnedPeds)
