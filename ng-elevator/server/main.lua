local QBCore = exports['qb-core']:GetCoreObject()

-- サーバー起動時のデバッグ情報
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    print('^2NG-Elevator started successfully^7')
end)

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    print('^1NG-Elevator stopped^7')
end)