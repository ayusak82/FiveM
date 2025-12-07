local QBCore = exports['qb-core']:GetCoreObject()

-- スクリプト開始時のログ
CreateThread(function()
    Wait(1000)
    if Config.Debug then
        print('[ng-laser] サーバーサイドが正常に開始されました')
        print('[ng-laser] バージョン: 1.0.0')
        print('[ng-laser] 作成者: NCCGr')
    end
end)

-- プレイヤーの権限チェック（サーバーサイド）
QBCore.Functions.CreateCallback('ng-laser:checkPermission', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false)
        return
    end
    
    -- 管理者のみの場合
    if Config.Permission.adminOnly then
        cb(QBCore.Functions.HasPermission(source, 'admin'))
        return
    end
    
    -- ジョブ制限がある場合
    if #Config.Permission.allowedJobs > 0 then
        local playerJob = Player.PlayerData.job.name
        local playerGrade = Player.PlayerData.job.grade.level
        
        for _, job in ipairs(Config.Permission.allowedJobs) do
            if playerJob == job and playerGrade >= Config.Permission.minGrade then
                cb(true)
                return
            end
        end
        cb(false)
        return
    end
    
    -- 制限がない場合
    cb(true)
end)

-- 座標ログ記録（オプション）
RegisterNetEvent('ng-laser:logCoordinates', function(coords)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    if Config.Debug then
        print(string.format('[ng-laser] プレイヤー %s (%s) が座標をコピー: %s', 
            Player.PlayerData.name, 
            Player.PlayerData.citizenid, 
            coords
        ))
    end
end)

-- スクリプト停止時の処理
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if Config.Debug then
            print('[ng-laser] サーバーサイドが正常に停止されました')
        end
    end
end)