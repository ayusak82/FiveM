local QBCore = exports['qb-core']:GetCoreObject()
local hasClaimedFirstCar = false

-- UIが表示されているか
local isUIOpen = false

-- 初期化
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('ng-firstcar:server:checkClaimed')
end)

-- サーバーから受け取り済みステータスを設定
RegisterNetEvent('ng-firstcar:client:setClaimedStatus', function(claimed)
    hasClaimedFirstCar = claimed
end)

-- UIを開く
RegisterNetEvent('ng-firstcar:client:openUI', function()
    if isUIOpen then return end
    
    if hasClaimedFirstCar then
        QBCore.Functions.Notify(Config.Messages.error.already_claimed, 'error')
        return
    end
    
    isUIOpen = true
    
    -- カーソルを表示
    SetNuiFocus(true, true)
    
    -- UIにデータを送信
    SendNUIMessage({
        action = 'open',
        vehicles = Config.VehicleOptions
    })
    
    QBCore.Functions.Notify(Config.Messages.success.ui_opened, 'primary')
end)

-- NUIコールバック: UIを閉じる
RegisterNUICallback('closeUI', function(_, cb)
    isUIOpen = false
    SetNuiFocus(false, false)
    cb({ok = true})
end)

-- NUIコールバック: 車両を選択
RegisterNUICallback('selectVehicle', function(data, cb)
    isUIOpen = false
    SetNuiFocus(false, false)
    
    if not data.index then
        QBCore.Functions.Notify(Config.Messages.error.no_selection, 'error')
        cb({ok = false})
        return
    end
    
    TriggerServerEvent('ng-firstcar:server:claimVehicle', data.index)
    cb({ok = true})
end)

-- リソース停止時にNUIを閉じる
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    if isUIOpen then
        SetNuiFocus(false, false)
    end
end)