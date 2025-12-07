local QBCore = exports['qb-core']:GetCoreObject()

-- 管理者権限チェック関数
local function isAdmin(source)
    if not source then return false end
    return IsPlayerAceAllowed(source, 'command.admin')
end

-- 管理者権限チェックのコールバック登録
lib.callback.register('ng-heavyarmor:server:isAdmin', function(source)
    return isAdmin(source)
end)

-- デバッグログ
local function debugPrint(message)
    if Config.Debug then
        print('[ng-heavyarmor] ' .. message)
    end
end

-- リソース起動時
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        debugPrint('Server script loaded')
        print('^2[ng-heavyarmor]^7 Heavy Armor System started successfully!')
    end
end)
