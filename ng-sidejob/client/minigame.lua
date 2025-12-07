-- NUI通信管理

-- ミニゲーム開始関数をエクスポート
exports('StartGame', function(gameType, gameData)
    if not gameType or not gameData then
        if Config.Debug then
            print("StartGame: Invalid parameters")
        end
        return
    end

    -- NUIを表示してゲーム開始
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'startGame',
        gameType = gameType,
        gameData = gameData
    })

    if Config.Debug then
        print("Starting game: " .. gameType)
    end
end)

-- NUIを閉じる
RegisterNUICallback('closeUI', function(data, cb)
    cb('ok')
    SetNuiFocus(false, false)
end)

-- デバッグ用：ESCキーでNUIを強制終了
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, 322) then -- ESC キー
            SendNUIMessage({
                action = 'forceClose'
            })
            SetNuiFocus(false, false)
        end
    end
end)
