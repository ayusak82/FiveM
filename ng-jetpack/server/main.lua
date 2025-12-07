local QBCore = exports['qb-core']:GetCoreObject()

-- ====================================
-- アイテム使用可能登録
-- ====================================
QBCore.Functions.CreateUseableItem(Config.ItemName, function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- クライアントにジェットパック使用イベントを送信
    TriggerClientEvent('ng-jetpack:client:useJetpack', src)
end)

-- ====================================
-- デバッグログ出力
-- ====================================
if Config.Debug then
    print("^2[NG-Jetpack]^7 デバッグモードが有効です")
    print("^2[NG-Jetpack]^7 コマンド: /" .. Config.DebugCommand)
end

-- ====================================
-- リソース起動ログ
-- ====================================
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print("^2========================================^7")
    print("^2[NG-Jetpack]^7 スクリプトが正常に起動しました")
    print("^2[NG-Jetpack]^7 バージョン: 1.0.0")
    print("^2[NG-Jetpack]^7 作成者: NCCGr")
    print("^2========================================^7")
end)

-- ====================================
-- リソース停止ログ
-- ====================================
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print("^3[NG-Jetpack]^7 スクリプトが停止しました")
end)