local QBCore = exports['qb-core']:GetCoreObject()

-- クライアントからの電話番号取得コールバック
QBCore.Functions.CreateCallback('ng-scoreboard:server:GetMyPhoneNumber', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(nil)
        return
    end
    
    -- プレイヤー自身の電話番号をデータベースから取得
    local citizenid = Player.PlayerData.citizenid
    local phoneNumber = nil
    
    -- データベースから電話番号を取得
    local result = MySQL.query.await('SELECT phone_number FROM phone_phones WHERE owner_id = ?', {citizenid})
    if result and #result > 0 then
        phoneNumber = result[1].phone_number
    else
        -- データベースから取得できない場合はQBCoreのデータを使用
        phoneNumber = Player.PlayerData.charinfo.phone
    end
    
    cb(phoneNumber)
end)

-- クライアントから電話をかけるリクエストを受け取るイベント
RegisterNetEvent('ng-scoreboard:server:CallNumber', function(phoneNumber)
    local src = source
    
    -- プレイヤーのデータを取得
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- プレイヤー自身の電話番号をデータベースから取得
    local citizenid = Player.PlayerData.citizenid
    local myPhoneNumber = nil
    
    -- データベースから電話番号を取得
    local result = MySQL.query.await('SELECT phone_number FROM phone_phones WHERE owner_id = ?', {citizenid})
    if result and #result > 0 then
        myPhoneNumber = result[1].phone_number
    end
    
    -- 自分自身への電話を防止
    if myPhoneNumber == phoneNumber then
        -- 自分自身には電話できないことを通知
        TriggerClientEvent('QBCore:Notify', src, '自分自身には電話できません', 'error')
        return
    end
    
    -- プレイヤーデータを設定
    local playerData = {
        source = src,
        phoneNumber = myPhoneNumber -- プレイヤーの電話番号
    }
    
    -- lb-phoneのCreateCall関数を使用して電話をかける
    exports["lb-phone"]:CreateCall(playerData, phoneNumber, {
        requirePhone = false, -- 電話アイテムが必要かどうか
        hideNumber = false,   -- 発信者番号を隠すかどうか
        company = nil         -- 会社からの発信の場合は会社名を指定
    })
end)