local QBCore = exports['qb-core']:GetCoreObject()

-- 座標を指定された小数点以下の桁数に丸める関数
local function roundCoords(coord)
    local multiplier = 10 ^ Config.Format.decimal_places
    return math.floor(coord * multiplier + 0.5) / multiplier
end

-- vector3を取得してクリップボードにコピーする
local function copyVector3()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- 座標を丸める
    local x = roundCoords(coords.x)
    local y = roundCoords(coords.y)
    local z = roundCoords(coords.z)
    
    -- フォーマットに従って文字列を作成
    local coordString = string.format(Config.Format.vector3, x, y, z)
    
    -- クリップボードにコピー
    lib.setClipboard(coordString)
    
    -- 通知を表示
    lib.notify({
        title = '座標をコピーしました',
        description = coordString,
        type = 'success',
        position = 'top'
    })
end

-- vector4を取得してクリップボードにコピーする
local function copyVector4()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = roundCoords(GetEntityHeading(ped))
    
    -- 座標を丸める
    local x = roundCoords(coords.x)
    local y = roundCoords(coords.y)
    local z = roundCoords(coords.z)
    
    -- フォーマットに従って文字列を作成
    local coordString = string.format(Config.Format.vector4, x, y, z, heading)
    
    -- クリップボードにコピー
    lib.setClipboard(coordString)
    
    -- 通知を表示
    lib.notify({
        title = '座標をコピーしました',
        description = coordString,
        type = 'success',
        position = 'top'
    })
end

-- コマンドの登録
RegisterCommand(Config.Commands.vector3, function()
    copyVector3()
end, false)

RegisterCommand(Config.Commands.vector4, function()
    copyVector4()
end, false)

-- チャットの提案を登録
TriggerEvent('chat:addSuggestion', '/'..Config.Commands.vector3, 'vector3の座標をクリップボードにコピー')
TriggerEvent('chat:addSuggestion', '/'..Config.Commands.vector4, 'vector4の座標（heading含む）をクリップボードにコピー')