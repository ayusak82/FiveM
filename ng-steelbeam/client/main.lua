local QBCore = exports['qb-core']:GetCoreObject()
local spawnedBeams = {}
local isBeamsSpawned = false

-- デバッグ用のプリント関数
local function DebugPrint(message)
    if Config.Debug then
        print('^3[ng-steelbeam]^7 ' .. message)
    end
end

-- 2点間の距離を計算
local function GetDistance3D(point1, point2)
    local dx = point2.x - point1.x
    local dy = point2.y - point1.y
    local dz = point2.z - point1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- 2点間の角度を計算（Z軸回転）
local function GetHeadingBetweenPoints(point1, point2)
    local dx = point2.x - point1.x
    local dy = point2.y - point1.y
    local heading = math.deg(math.atan2(dy, dx))
    return heading
end

-- 鉄骨をスポーンさせる関数
local function SpawnSteelBeams()
    if isBeamsSpawned then
        DebugPrint('鉄骨は既にスポーンされています')
        return
    end

    local startPoint = Config.SteelBeam.StartPoint
    local endPoint = Config.SteelBeam.EndPoint
    local spacing = Config.SteelBeam.BeamSpacing
    local model = Config.SteelBeam.Model
    local heightAdjust = Config.SteelBeam.HeightAdjust

    -- モデルをロード
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end

    DebugPrint('鉄骨モデルをロード完了: ' .. model)

    -- 総距離を計算
    local totalDistance = GetDistance3D(startPoint, endPoint)
    local beamCount = math.floor(totalDistance / spacing)

    DebugPrint('総距離: ' .. string.format("%.2f", totalDistance) .. 'm')
    DebugPrint('配置する鉄骨の数: ' .. beamCount)

    -- 各鉄骨をスポーン
    for i = 0, beamCount do
        local progress = i / beamCount
        
        -- 線形補間で座標を計算
        local x = startPoint.x + (endPoint.x - startPoint.x) * progress
        local y = startPoint.y + (endPoint.y - startPoint.y) * progress
        local z = startPoint.z + (endPoint.z - startPoint.z) * progress + heightAdjust
        
        local beamCoords = vector3(x, y, z)
        
        -- 回転角度を計算
        local heading = 0.0
        if Config.SteelBeam.AutoRotation then
            heading = GetHeadingBetweenPoints(startPoint, endPoint)
        end
        
        -- 鉄骨をスポーン
        local beam = CreateObject(model, beamCoords.x, beamCoords.y, beamCoords.z, false, false, false)
        
        -- オブジェクトの設定
        SetEntityHeading(beam, heading)
        FreezeEntityPosition(beam, true)
        SetEntityAsMissionEntity(beam, true, true)
        
        -- スポーンした鉄骨を記録
        table.insert(spawnedBeams, beam)
        
        DebugPrint('鉄骨 #' .. i .. ' をスポーン: ' .. string.format("%.2f, %.2f, %.2f", x, y, z))
        
        Wait(50) -- スポーン時の負荷軽減
    end

    isBeamsSpawned = true
    DebugPrint('全ての鉄骨のスポーンが完了しました (合計: ' .. #spawnedBeams .. '個)')
    
    lib.notify({
        title = '鉄骨チャレンジ',
        description = '鉄骨が設置されました',
        type = 'success',
        duration = 5000
    })
end

-- 鉄骨を削除する関数
local function RemoveSteelBeams()
    if not isBeamsSpawned then
        DebugPrint('削除する鉄骨がありません')
        return
    end

    for i, beam in ipairs(spawnedBeams) do
        if DoesEntityExist(beam) then
            DeleteEntity(beam)
        end
    end

    spawnedBeams = {}
    isBeamsSpawned = false
    
    DebugPrint('全ての鉄骨を削除しました')
    
    lib.notify({
        title = '鉄骨チャレンジ',
        description = '鉄骨を削除しました',
        type = 'info',
        duration = 5000
    })
end

-- リソース開始時の処理
CreateThread(function()
    DebugPrint('ng-steelbeam クライアントスクリプトを起動しました')
    
    if Config.AutoSpawnOnStart then
        Wait(1000) -- プレイヤーのスポーン待機
        SpawnSteelBeams()
    end
end)

-- リソース停止時の処理
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    RemoveSteelBeams()
end)

-- コマンド: 鉄骨をスポーン
RegisterCommand('spawnbeams', function()
    SpawnSteelBeams()
end, false)

-- コマンド: 鉄骨を削除
RegisterCommand('removebeams', function()
    RemoveSteelBeams()
end, false)

-- デバッグ用: 自分の座標を表示
if Config.Debug then
    RegisterCommand('mypos', function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        print('^2現在の座標:^7 vector3(' .. string.format("%.2f, %.2f, %.2f", coords.x, coords.y, coords.z) .. ')')
        lib.notify({
            title = 'デバッグ',
            description = string.format("X: %.2f, Y: %.2f, Z: %.2f", coords.x, coords.y, coords.z),
            type = 'info',
            duration = 10000
        })
    end, false)
end