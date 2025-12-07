local QBCore = exports['qb-core']:GetCoreObject()

-- 管理者権限チェック関数
local function isAdmin(source)
    if not source then return false end
    return IsPlayerAceAllowed(source, 'command.admin')
end

-- 管理者権限チェックのコールバック登録
lib.callback.register('ng-speedlimiter:server:isAdmin', function(source)
    return isAdmin(source)
end)

-- スクリプト起動時のログ
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print('^2[ng-speedlimiter]^7 Speed Limiter has been started!')
    print('^2[ng-speedlimiter]^7 Normal vehicles: ' .. Config.SpeedLimit.Normal .. ' km/h')
    print('^2[ng-speedlimiter]^7 Emergency vehicles: ' .. Config.SpeedLimit.Emergency .. ' km/h')
end)
