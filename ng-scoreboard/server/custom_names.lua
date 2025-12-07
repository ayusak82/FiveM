local QBCore = exports['qb-core']:GetCoreObject()

-- プレイヤーの名前を取得する関数（playersテーブルのfirstname, lastnameから取得）
local function GetPlayerCustomName(citizenid)
    if not citizenid then return nil end
    
    local result = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ?', {citizenid})
    if result and #result > 0 then
        local charinfo = json.decode(result[1].charinfo)
        if charinfo and charinfo.firstname and charinfo.lastname then
            return charinfo.firstname .. " " .. charinfo.lastname
        end
    end
    
    return nil
end

-- プレイヤーの名前を設定する関数（playersテーブルのcharinfoを更新）
local function SetPlayerCustomName(citizenid, firstname, lastname)
    if not citizenid or not firstname or not lastname then 
        print('[ng-scoreboard] エラー: 必須パラメータが不足しています')
        return false, "必須パラメータが不足しています"
    end
    
    -- 姓の長さチェック
    if #lastname < 1 or #lastname > 25 then
        return false, "姓は1文字以上25文字以下にしてください"
    end
    
    -- 名の長さチェック
    if #firstname < 1 or #firstname > 25 then
        return false, "名は1文字以上25文字以下にしてください"
    end
    
    -- 不適切な文字のチェック
    if string.match(firstname, "[<>%$;]") or string.match(lastname, "[<>%$;]") then
        return false, "不適切な文字が含まれています"
    end
    
    -- 現在のcharinfoを取得
    local result = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ?', {citizenid})
    if not result or #result == 0 then
        print('[ng-scoreboard] エラー: プレイヤーデータが見つかりません - CitizenID: ' .. tostring(citizenid))
        return false, "プレイヤーデータが見つかりません"
    end
    
    -- charinfoをデコードして更新
    local charinfo = json.decode(result[1].charinfo)
    local oldFirstname = charinfo.firstname
    local oldLastname = charinfo.lastname
    
    charinfo.firstname = firstname
    charinfo.lastname = lastname
    
    -- データベースに保存
    local updateResult = MySQL.query.await('UPDATE players SET charinfo = ? WHERE citizenid = ?', {json.encode(charinfo), citizenid})
    
    if updateResult then
        print(string.format('[ng-scoreboard] 名前変更成功: %s %s -> %s %s (CitizenID: %s)', 
            oldLastname, oldFirstname, lastname, firstname, citizenid))
        return true, nil
    else
        print('[ng-scoreboard] エラー: データベース更新に失敗しました')
        return false, "データベース更新に失敗しました"
    end
end

-- クライアントから現在の名前を取得するコールバック
QBCore.Functions.CreateCallback('ng-scoreboard:server:GetCurrentName', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(nil)
        return
    end
    
    cb({
        firstname = Player.PlayerData.charinfo.firstname,
        lastname = Player.PlayerData.charinfo.lastname
    })
end)

-- クライアントからのカスタム名設定リクエストを処理
QBCore.Functions.CreateCallback('ng-scoreboard:server:SetCustomName', function(source, cb, data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(false, "プレイヤーデータが見つかりません")
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    local success, errorMsg = SetPlayerCustomName(citizenid, data.firstname, data.lastname)
    
    if success then
        -- QBCoreのメモリ内のプレイヤーデータを即座に更新
        Player.PlayerData.charinfo.firstname = data.firstname
        Player.PlayerData.charinfo.lastname = data.lastname
        
        -- プレイヤーデータを同期
        TriggerClientEvent('QBCore:Player:SetPlayerData', src, Player.PlayerData)
        
        -- 全プレイヤーにスコアボードの更新を通知
        TriggerClientEvent('QBCore:Notify', src, "名前を変更しました", "success")
        
        -- 少し遅延させてから全プレイヤーに更新を通知
        SetTimeout(100, function()
            TriggerEvent('ng-scoreboard:server:UpdateAllPlayers')
        end)
    else
        TriggerClientEvent('QBCore:Notify', src, errorMsg or "名前の変更に失敗しました", "error")
    end
    
    cb(success, errorMsg)
end)

-- 全プレイヤーにスコアボードデータを更新する
RegisterNetEvent('ng-scoreboard:server:UpdateAllPlayers', function()
    local Players = QBCore.Functions.GetPlayers()
    for _, v in pairs(Players) do
        TriggerEvent('ng-scoreboard:server:SendDataToPlayer', v)
    end
end)

-- 指定したプレイヤーにスコアボードデータを送信する
RegisterNetEvent('ng-scoreboard:server:SendDataToPlayer', function(targetId)
    TriggerClientEvent('ng-scoreboard:client:RequestData', targetId)
end)

-- GetPlayerCustomName関数をエクスポート
exports('GetPlayerCustomName', GetPlayerCustomName)
