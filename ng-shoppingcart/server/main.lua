local QBCore = exports['qb-core']:GetCoreObject()

-- サーバー起動時のログ
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('^2[ng-shoppingcart]^7 Shopping Cart Script が正常に起動しました')
        print('^2[ng-shoppingcart]^7 作者: NCCGr')
        print('^2[ng-shoppingcart]^7 問い合わせ: Discord - ayusak')
    end
end)

-- サーバー停止時のログ
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('^3[ng-shoppingcart]^7 Shopping Cart Script が停止しました')
    end
end)
