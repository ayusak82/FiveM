local QBCore = exports['qb-core']:GetCoreObject()

-- 管理者権限チェック関数
local function isAdmin(source)
    if not source then return false end
    return IsPlayerAceAllowed(source, 'command.admin')
end

-- 管理者権限チェックのコールバック登録
lib.callback.register('ng-magic:server:isAdmin', function(source)
    return isAdmin(source)
end)

-- リソース開始時のメッセージ
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print('^2[ng-magic]^7 魔法システムが起動しました')
    print('^2[ng-magic]^7 コマンド: /' .. Config.Command)
    print('^2[ng-magic]^7 作成者: NCCGr')
end)

-- リソース停止時のメッセージ
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print('^1[ng-magic]^7 魔法システムが停止しました')
end)
