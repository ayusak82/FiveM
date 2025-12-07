local QBCore = exports['qb-core']:GetCoreObject()

-- ドア情報をフォーマットする関数
local function formatDoorInfo(doorInfo)
    if not doorInfo then return "情報なし" end
    
    local jobsString = '{ '
    for i, job in ipairs(doorInfo.authorizedJobs) do
        jobsString = jobsString .. "'" .. job .. "'" .. (i < #doorInfo.authorizedJobs and ', ' or '')
    end
    jobsString = jobsString .. ' }'
    
    local doorsString = ''
    for i, door in ipairs(doorInfo.doors) do
        doorsString = doorsString .. '\n\t\t\t{\n'
        doorsString = doorsString .. '\t\t\t\tobjName = \'' .. door.objName .. '\',\n'
        doorsString = doorsString .. '\t\t\t\tobjYaw = ' .. string.format("%.1f", door.objYaw) .. ',\n'
        doorsString = doorsString .. '\t\t\t\tobjCoords = vec3(' .. string.format("%.5f", door.objCoords.x) .. ', ' .. string.format("%.5f", door.objCoords.y) .. ', ' .. string.format("%.5f", door.objCoords.z) .. ')\n'
        doorsString = doorsString .. '\t\t\t}' .. (i < #doorInfo.doors and ',\n' or '\n')
    end
    
    local formattedInfo = '{\n'
    formattedInfo = formattedInfo .. '\t\ttextCoords = vec3(' .. string.format("%.2f", doorInfo.textCoords.x) .. ', ' .. string.format("%.2f", doorInfo.textCoords.y) .. ', ' .. string.format("%.2f", doorInfo.textCoords.z) .. '),\n'
    formattedInfo = formattedInfo .. '\t\tauthorizedJobs = ' .. jobsString .. ',\n'
    formattedInfo = formattedInfo .. '\t\tlocked = ' .. tostring(doorInfo.locked) .. ',\n'
    formattedInfo = formattedInfo .. '\t\tpickable = ' .. tostring(doorInfo.pickable) .. ',\n'
    formattedInfo = formattedInfo .. '\t\tdistance = ' .. string.format("%.1f", doorInfo.distance) .. ',\n'
    formattedInfo = formattedInfo .. '\t\tdoors = {' .. doorsString .. '\t\t}\n'
    formattedInfo = formattedInfo .. '\t},'
    
    return formattedInfo
end

-- クリップボードにコピーするイベント
RegisterNetEvent('ng-doorinfo:server:copyToClipboard', function(doorInfo)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local formattedDoorInfo = formatDoorInfo(doorInfo)
    
    -- クライアントにクリップボードコピーイベントを送信
    TriggerClientEvent('ng-doorinfo:client:copyToClipboard', src, formattedDoorInfo)
    
    -- ログ出力
    print(string.format("^2プレイヤー %s (%s) がドア情報をコピーしました^7", GetPlayerName(src), Player.PlayerData.citizenid))
end)

-- サーバー起動メッセージ
print('^2NG-DoorInfo^7: サーバーが起動しました')