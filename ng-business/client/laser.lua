-- ============================================
-- CLIENT LASER - ng-business
-- ============================================

local isLaserActive = false
local currentCoords = nil
local laserThread = nil
local keybindId = nil
local laserCallback = nil

-- 回転からディレクションへの変換
local function RotationToDirection(rotation)
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

-- レーザーの描画とレイキャスト
local function drawLaser()
    local playerPed = PlayerPedId()
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

-- レーザーの開始
function StartLaser(callback)
    if not Config.Laser.enabled then
        lib.notify({
            title = 'エラー',
            description = 'レーザーシステムが無効化されています',
            type = 'error',
            duration = Config.UI.notificationDuration
        })
        return
    end
    
    if isLaserActive then
        lib.notify({
            title = 'エラー',
            description = 'レーザーは既に起動しています',
            type = 'error',
            duration = Config.UI.notificationDuration
        })
        return
    end
    
    isLaserActive = true
    laserCallback = callback
    
    lib.notify({
        title = 'レーザー起動',
        description = 'Eキーで座標を設定、ESCでキャンセル',
        type = 'success',
        duration = Config.UI.notificationDuration
    })
    
    -- レーザー描画スレッド開始
    laserThread = CreateThread(function()
        while isLaserActive do
            drawLaser()
            
            -- ESCキーでキャンセル
            if IsControlJustPressed(0, 322) then -- ESC
                StopLaser(true)
                break
            end
            
            -- Eキーで座標設定
            if IsControlJustPressed(0, 38) then -- E
                if currentCoords then
                    StopLaser(false)
                    if laserCallback then
                        laserCallback(currentCoords)
                    end
                    break
                end
            end
            
            Wait(Config.Laser.updateInterval)
        end
    end)
end

-- レーザーの停止
function StopLaser(cancelled)
    isLaserActive = false
    laserCallback = nil
    currentCoords = nil
    
    if laserThread then
        laserThread = nil
    end
    
    if cancelled then
        lib.notify({
            title = 'キャンセル',
            description = 'レーザーがキャンセルされました',
            type = 'inform',
            duration = Config.UI.notificationDuration
        })
    end
end

-- レーザーの切り替えコマンド（デバッグ用）
RegisterCommand(Config.Laser.toggleCommand, function()
    if not isAdmin() then
        lib.notify({
            title = 'アクセス拒否',
            description = '管理者権限が必要です',
            type = 'error',
            duration = Config.UI.notificationDuration
        })
        return
    end
    
    if isLaserActive then
        StopLaser(true)
    else
        StartLaser(function(coords)
            local coordsText = string.format(
                "vector3(%.2f, %.2f, %.2f)",
                coords.x, coords.y, coords.z
            )
            lib.setClipboard(coordsText)
            lib.notify({
                title = '座標コピー',
                description = '座標がクリップボードにコピーされました',
                type = 'success',
                duration = Config.UI.notificationDuration
            })
            DebugPrint('Copied coordinates:', coordsText)
        end)
    end
end, false)

-- チャットサジェスト
TriggerEvent('chat:addSuggestion', '/' .. Config.Laser.toggleCommand, 'レーザー座標取得システムの切り替え（管理者のみ）')

-- スクリプト終了時の処理
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isLaserActive then
            StopLaser(true)
        end
    end
end)

DebugPrint('Laser module loaded')
