local QBCore = exports['qb-core']:GetCoreObject()

-- スクリーンショット撮影関数（lb-upload-standalone使用）
local function takeScreenshot(callback)
    -- プレイヤーメタデータを準備
    local playerData = QBCore.Functions.GetPlayerData()
    local metadata = {
        identifier = playerData.citizenid or 'unknown',
        name = (playerData.charinfo.firstname .. ' ' .. playerData.charinfo.lastname) or 'Unknown'
    }
    
    -- lb-upload-standaloneにアップロード
    exports['screenshot-basic']:requestScreenshotUpload(
        Config.Screenshot.uploadUrl,
        Config.Screenshot.field,
        {
            headers = Config.Screenshot.headers or {},
            encoding = 'webp'
        },
        function(data)
            local resp = json.decode(data)
            if resp and resp.success and resp.link then
                callback(resp.link)
            else
                callback(nil)
            end
        end
    )
end

-- テレポート実行関数
local function doTeleport(coords)
    local ped = PlayerPedId()
    
    -- フェードアウト効果
    DoScreenFadeOut(500)
    
    -- フェードアウト完了まで待機
    while not IsScreenFadedOut() do
        Wait(10)
    end
    
    -- テレポート実行
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
    
    -- 向きを設定
    if coords.w then
        SetEntityHeading(ped, coords.w)
    end
    
    -- 少し待機してからフェードイン
    Wait(500)
    
    -- フェードイン効果
    DoScreenFadeIn(500)
    
    -- テレポート完了の確認
    while not IsScreenFadedIn() do
        Wait(10)
    end
end

-- テレポートコマンド処理
RegisterCommand(Config.Command.name, function()
    -- 理由入力ダイアログ表示
    local input = lib.inputDialog('緊急テレポート', {
        {
            type = 'textarea',
            label = 'テレポート理由',
            description = 'テレポートする理由を入力してください',
            required = true,
            min = 10,
            max = 500
        }
    })
    
    if not input or not input[1] then
        lib.notify({
            type = 'error',
            description = Config.Notifications.reasonRequired
        })
        return
    end
    
    local reason = input[1]
    
    -- スクリーンショット撮影
    if Config.Screenshot.enabled then
        lib.notify({
            type = 'info',
            description = 'スクリーンショットを撮影中...'
        })
        
        takeScreenshot(function(screenshotUrl)
            -- サーバーにテレポート要求送信
            TriggerServerEvent('ng-tplegion:server:requestTeleport', reason, screenshotUrl)
        end)
    else
        -- スクリーンショット無効の場合は直接テレポート要求
        TriggerServerEvent('ng-tplegion:server:requestTeleport', reason, nil)
    end
end, false)

-- サーバーからのテレポート指令受信
RegisterNetEvent('ng-tplegion:client:teleport', function(coords)
    if not coords then
        lib.notify({
            type = 'error',
            description = Config.Notifications.error
        })
        return
    end
    
    -- テレポート実行
    doTeleport(coords)
end)

-- スクリプト読み込み完了通知
CreateThread(function()
    Wait(1000) -- 他のスクリプトの読み込み完了を待つ
    if Config.Logging and Config.Logging.console then
        print('^2[ng-tplegion]^7 クライアントスクリプトが正常に読み込まれました')
    end
end)