local QBCore = exports['qb-core']:GetCoreObject()

-- サーバー起動時のログ表示
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    print('^2ng-seatbelt-warning^7: シートベルト警告システムが正常に起動しました')
end)