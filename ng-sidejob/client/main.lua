local QBCore = exports['qb-core']:GetCoreObject()
local isOnCooldown = false
local cooldownTimer = 0

-- マーカー表示スレッド
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for _, location in ipairs(Config.JobLocations) do
            local distance = #(playerCoords - location.coords)

            if distance < 20.0 then
                sleep = 0
                DrawMarker(
                    Config.Marker.type,
                    location.coords.x, location.coords.y, location.coords.z,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    Config.Marker.scale.x, Config.Marker.scale.y, Config.Marker.scale.z,
                    Config.Marker.color.r, Config.Marker.color.g, Config.Marker.color.b, Config.Marker.color.a,
                    Config.Marker.bobUpAndDown,
                    Config.Marker.faceCamera,
                    2,
                    Config.Marker.rotate,
                    nil, nil, false
                )

                if distance < Config.InteractDistance then
                    lib.showTextUI('[E] ' .. location.label, {
                        position = "left-center",
                        icon = 'briefcase'
                    })

                    if IsControlJustReleased(0, 38) then -- E キー
                        lib.hideTextUI()
                        OpenJobMenu()
                    end
                else
                    lib.hideTextUI()
                end
            end
        end

        Citizen.Wait(sleep)
    end
end)

-- 内職メニューを開く
function OpenJobMenu()
    if isOnCooldown then
        local remainingTime = math.ceil(cooldownTimer - GetGameTimer() / 1000)
        lib.notify({
            title = Config.Notifications.cooldown.title,
            description = string.format("残り時間: %d秒", remainingTime),
            type = Config.Notifications.cooldown.type
        })
        return
    end

    local options = {}

    for gameType, gameData in pairs(Config.Minigames) do
        table.insert(options, {
            title = gameData.name,
            description = gameData.description .. "\n難易度: " .. gameData.difficulty .. " | 報酬: $" .. gameData.reward.min .. " - $" .. gameData.reward.max,
            icon = gameData.icon,
            onSelect = function()
                StartMinigame(gameType)
            end
        })
    end

    lib.registerContext({
        id = 'sidejob_menu',
        title = '内職を選択',
        options = options
    })

    lib.showContext('sidejob_menu')
end

-- ミニゲーム開始
function StartMinigame(gameType)
    local gameData = Config.Minigames[gameType]

    if not gameData then
        if Config.Debug then
            print("Invalid game type: " .. tostring(gameType))
        end
        return
    end

    -- アニメーション開始
    local playerPed = PlayerPedId()
    RequestAnimDict("amb@world_human_seat_wall_tablet@female@base")
    while not HasAnimDictLoaded("amb@world_human_seat_wall_tablet@female@base") do
        Citizen.Wait(100)
    end
    TaskPlayAnim(playerPed, "amb@world_human_seat_wall_tablet@female@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)

    -- ミニゲーム開始
    exports['ng-sidejob']:StartGame(gameType, gameData)
end

-- ミニゲーム結果を受け取る
RegisterNUICallback('gameResult', function(data, cb)
    cb('ok')

    local playerPed = PlayerPedId()
    ClearPedTasks(playerPed)

    if data.success then
        -- サーバーに報酬をリクエスト
        TriggerServerEvent('ng-sidejob:server:claimReward', data.gameType, data.score)

        -- クールダウン開始
        StartCooldown()
    else
        lib.notify({
            title = Config.Notifications.failed.title,
            description = Config.Notifications.failed.description,
            type = Config.Notifications.failed.type
        })
    end
end)

-- クールダウン開始
function StartCooldown()
    isOnCooldown = true
    cooldownTimer = GetGameTimer() / 1000 + Config.Cooldown

    Citizen.CreateThread(function()
        while isOnCooldown do
            Citizen.Wait(1000)
            if GetGameTimer() / 1000 >= cooldownTimer then
                isOnCooldown = false
                lib.notify({
                    title = "クールダウン終了",
                    description = "再度内職ができます",
                    type = "success"
                })
            end
        end
    end)
end

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    lib.hideTextUI()
end)
