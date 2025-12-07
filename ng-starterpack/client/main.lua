local QBCore = exports['qb-core']:GetCoreObject()
local hasUsedStarterPack = false

-- イベント登録
RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('ng-starterpack:server:checkUsedStatus')
end)

RegisterNetEvent('ng-starterpack:client:setUsedStatus')
AddEventHandler('ng-starterpack:client:setUsedStatus', function(usedStatus)
    hasUsedStarterPack = usedStatus
end)

-- スターターパックアイテムの使用
RegisterNetEvent('ng-starterpack:client:useStarterPack')
AddEventHandler('ng-starterpack:client:useStarterPack', function()
    if hasUsedStarterPack then
        lib.notify({
            title = 'エラー',
            description = Config.AlreadyUsed,
            type = 'error'
        })
        return
    end
    
    ToggleUI(true)
end)

-- UI表示切り替え
function ToggleUI(show)
    SetNuiFocus(show, show)
    SendNUIMessage({
        action = "toggle",
        show = show,
        title = Config.UITitle,
        citizenPackName = Config.CitizenPackName,
        criminalPackName = Config.CriminalPackName,
        citizenDesc = Config.CitizenPackDescription,
        criminalDesc = Config.CriminalPackDescription,
        citizenItems = Config.CitizenPack,
        criminalItems = Config.CriminalPack
    })
end

-- NUI コールバック
RegisterNUICallback('close', function(data, cb)
    ToggleUI(false)
    cb('ok')
end)

RegisterNUICallback('selectPack', function(data, cb)
    ToggleUI(false)
    
    if data.packType == 'citizen' or data.packType == 'criminal' then
        TriggerServerEvent('ng-starterpack:server:givePack', data.packType)
    end
    
    cb('ok')
end)