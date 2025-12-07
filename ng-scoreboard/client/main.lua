local QBCore = exports['qb-core']:GetCoreObject()
local isScoreboardOpen = false

-- サーバーからデータを受け取る
RegisterNetEvent('ng-scoreboard:client:UpdateData', function(data)
    -- 自分自身のPlayerデータを取得
    local Player = QBCore.Functions.GetPlayerData()
    local myCitizenId = Player.citizenid
    
    -- 自分自身のデータにisSelf=true を追加
    for i, player in ipairs(data.playersList) do
        if player.citizenid == myCitizenId then
            data.playersList[i].isSelf = true
        else
            data.playersList[i].isSelf = false
        end
    end
    
    -- データをNUIに送信
    SendNUIMessage({
        type = 'updateData',
        totalPlayers = data.totalPlayers,
        maxPlayers = data.maxPlayers,
        restartInfo = data.restartInfo,
        jobCounts = data.jobCounts,
        playersList = data.playersList,
        robberies = Config.Robberies
    })
end)

-- スコアボードの表示/非表示を切り替える
local function ToggleScoreboard()
    isScoreboardOpen = not isScoreboardOpen
    
    if isScoreboardOpen then
        TriggerServerEvent('ng-scoreboard:server:RequestData')
    end
    
    SendNUIMessage({
        type = 'toggle',
        isOpen = isScoreboardOpen
    })
    
    SetNuiFocus(isScoreboardOpen, isScoreboardOpen)
end

-- キーマッピングの設定
RegisterCommand('toggle_scoreboard', function()
    ToggleScoreboard()
end, false)

RegisterKeyMapping('toggle_scoreboard', 'スコアボードの表示/非表示', 'keyboard', Config.OpenKey)

-- NUIからのコールバック（スコアボードを閉じる）
RegisterNUICallback('close', function(_, cb)
    isScoreboardOpen = false
    SetNuiFocus(false, false)
    cb({})
end)

-- NUIからのコールバック（現在の名前を取得）
RegisterNUICallback('getCurrentName', function(_, cb)
    QBCore.Functions.TriggerCallback('ng-scoreboard:server:GetCurrentName', function(nameData)
        cb(nameData)
    end)
end)

-- NUIからのコールバック（カスタム名を設定）
RegisterNUICallback('setCustomName', function(data, cb)
    QBCore.Functions.TriggerCallback('ng-scoreboard:server:SetCustomName', function(success, errorMsg)
        if success then
            -- 成功したら即座にスコアボードを更新
            if isScoreboardOpen then
                Wait(200) -- サーバー側の処理を待つ
                TriggerServerEvent('ng-scoreboard:server:RequestData')
            end
            cb({ success = true })
        else
            cb({ success = false, error = errorMsg })
        end
    end, {
        firstname = data.firstname,
        lastname = data.lastname
    })
end)

-- サーバーから自分自身の電話番号を取得する関数
function GetMyPhoneNumber(callback)
    QBCore.Functions.TriggerCallback('ng-scoreboard:server:GetMyPhoneNumber', function(phoneNumber)
        callback(phoneNumber)
    end)
end

-- NUIからのコールバック（電話をかける）
RegisterNUICallback('callNumber', function(data, cb)
    local number = data.number
    if number and number ~= '不明' then
        -- サーバーから自分の電話番号を取得して比較
        GetMyPhoneNumber(function(myPhoneNumber)
            -- 自分自身への電話を防止
            if myPhoneNumber and myPhoneNumber == number then
                -- 自分自身には電話できないことを通知
                QBCore.Functions.Notify('自分自身には電話できません', 'error')
                cb({})
                return
            end
            
            -- スコアボードを閉じる
            isScoreboardOpen = false
            SetNuiFocus(false, false)
            
            -- まずクライアント側の直接発信を試す
            local success = false
            
            -- クライアント側のCreateCall関数を使用
            success = pcall(function()
                exports["lb-phone"]:CreateCall({
                    number = number,
                    videoCall = false,
                    hideNumber = false
                })
            end)
            
            -- 直接発信が失敗した場合、サーバー側に発信リクエストを送信
            if not success then
                TriggerServerEvent('ng-scoreboard:server:CallNumber', number)
            end
            
            cb({})
        end)
    else
        cb({})
    end
end)

-- リソース開始時にサーバーにデータを要求
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    TriggerServerEvent('ng-scoreboard:server:RequestData')
end)

-- 定期的にデータを更新する
CreateThread(function()
    while true do
        if isScoreboardOpen then
            TriggerServerEvent('ng-scoreboard:server:RequestData')
        end
        Wait(5000) -- 5秒ごとに更新
    end
end)