local QBCore = exports['qb-core']:GetCoreObject()
local isLaserActive = false
local currentCoords = nil
local laserThread = nil
local keybindId = nil

-- レーザーの権限チェック
local function hasPermission()
    if Config.Permission.adminOnly then
        return QBCore.Functions.HasPermission('admin')
    end
    
    if #Config.Permission.allowedJobs > 0 then
        local PlayerData = QBCore.Functions.GetPlayerData()
        local playerJob = PlayerData.job.name
        local playerGrade = PlayerData.job.grade.level
        
        for _, job in ipairs(Config.Permission.allowedJobs) do
            if playerJob == job and playerGrade >= Config.Permission.minGrade then
                return true
            end
        end
        return false
    end
    
    return true
end

-- レーザーの描画とレイキャスト
local function drawLaser()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local _, camRot = GetGameplayCamCoord()
    local camCoords = GetGameplayCamCoord()
    
    -- カメラの方向を計算
    local direction = RotationToDirection(GetGameplayCamRot(2))
    local destination = {
        x = camCoords.x + direction.x * Config.Laser.maxDistance,
        y = camCoords.y + direction.y * Config.Laser.maxDistance,
        z = camCoords.z + direction.z * Config.Laser.maxDistance
    }
    
    -- レイキャスト実行
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(
        camCoords.x, camCoords.y, camCoords.z,
        destination.x, destination.y, destination.z,
        -1, playerPed, 0
    )
    
    local _, hit, endCoords, _, _ = GetShapeTestResult(rayHandle)
    
    -- 当たった場合は当たった座標、当たらなかった場合は最大距離の座標
    local targetCoords = hit and endCoords or destination
    currentCoords = vector3(targetCoords.x, targetCoords.y, targetCoords.z)
    
    -- レーザーを描画
    DrawLine(
        camCoords.x, camCoords.y, camCoords.z,
        targetCoords.x, targetCoords.y, targetCoords.z,
        Config.Laser.color[1], Config.Laser.color[2], Config.Laser.color[3], Config.Laser.color[4]
    )
    
    -- 当たった場所にマーカーを表示
    if hit then
        DrawMarker(
            28, -- マーカータイプ
            targetCoords.x, targetCoords.y, targetCoords.z,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            0.1, 0.1, 0.1,
            Config.Laser.color[1], Config.Laser.color[2], Config.Laser.color[3], 200,
            false, true, 2, false, false, false, false
        )
    end
end

-- 回転からディレクションへの変換
function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

-- レーザーの切り替え
local function toggleLaser()
    if not hasPermission() then
        lib.notify({
            title = 'アクセス拒否',
            description = 'レーザーを使用する権限がありません',
            type = 'error',
            duration = Config.UI.notificationDuration
        })
        return
    end
    
    isLaserActive = not isLaserActive
    
    if isLaserActive then
        lib.notify({
            title = 'レーザー起動',
            description = 'レーザーが起動されました。Eキーで座標をコピーできます',
            type = 'success',
            duration = Config.UI.notificationDuration
        })
        
        -- レーザー描画スレッド開始
        laserThread = CreateThread(function()
            while isLaserActive do
                drawLaser()
                Wait(Config.Laser.updateInterval)
            end
        end)
        
        -- 座標コピー用キーバインド
        keybindId = lib.addKeybind({
            name = 'laser_copy',
            description = '座標をコピー',
            defaultKey = Config.Laser.copyKey,
            onPressed = function()
                if isLaserActive and currentCoords then
                    local formatString = string.format("%%.%df, %%.%df, %%.%df", 
                        Config.UI.coordinateDecimals,
                        Config.UI.coordinateDecimals,
                        Config.UI.coordinateDecimals
                    )
                    local coordsText = string.format(
                        "vector3(" .. formatString .. ")",
                        currentCoords.x,
                        currentCoords.y,
                        currentCoords.z
                    )
                    
                    lib.setClipboard(coordsText)
                    lib.notify({
                        title = '座標コピー完了',
                        description = '座標がクリップボードにコピーされました',
                        type = 'success',
                        duration = Config.UI.notificationDuration
                    })
                    
                    if Config.Debug then
                        print('[ng-laser] コピーされた座標: ' .. coordsText)
                    end
                end
            end
        })
        
    else
        lib.notify({
            title = 'レーザー停止',
            description = 'レーザーが停止されました',
            type = 'inform',
            duration = Config.UI.notificationDuration
        })
        
        -- キーバインドを無効化（削除は不要）
        keybindId = nil
    end
end

-- コマンド登録
RegisterCommand(Config.Laser.toggleCommand, function()
    toggleLaser()
end, false)

-- チャットサジェスト
TriggerEvent('chat:addSuggestion', '/' .. Config.Laser.toggleCommand, 'レーザー座標取得システムの切り替え')

-- スクリプト終了時の処理
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        isLaserActive = false
        if laserThread then
            laserThread = nil
        end
        keybindId = nil
    end
end)