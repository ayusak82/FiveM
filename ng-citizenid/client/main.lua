local QBCore = exports['qb-core']:GetCoreObject()

-- コマンドの登録
RegisterCommand(Config.Command.name, function()
    -- プレイヤーデータの取得
    local Player = QBCore.Functions.GetPlayerData()
    if not Player then return end

    -- CitizenIDをクリップボードにコピー
    lib.setClipboard(Player.citizenid)

    -- 通知の表示
    lib.notify({
        title = Config.Notification.title,
        description = Config.Notification.description,
        type = Config.Notification.type,
        position = Config.Notification.position,
        duration = Config.Notification.duration
    })
end)