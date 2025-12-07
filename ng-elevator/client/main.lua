local QBCore = exports['qb-core']:GetCoreObject()

-- プレイヤーデータ
local PlayerData = {}

-- プレイヤーのロード時
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

-- エレベーターメニューを表示
local function ShowElevatorMenu(buildingId)
    if not Config.Buildings[buildingId] then return end

    local building = Config.Buildings[buildingId]
    local menuOptions = {}

    -- 各階層のメニューオプションを作成
    for i, floor in ipairs(building.floors) do
        menuOptions[#menuOptions + 1] = {
            title = floor.label,
            description = string.format('%sに移動', floor.label),
            icon = 'elevator',
            onSelect = function()
                -- アニメーション再生
                if lib.progressCircle({
                    duration = 2000,
                    label = '移動中...',
                    useWhileDead = false,
                    canCancel = false,
                    disable = {
                        car = true,
                        move = true,
                        combat = true
                    },
                }) then
                    -- テレポート
                    SetEntityCoords(cache.ped, floor.coords.x, floor.coords.y, floor.coords.z, false, false, false, false)
                    SetEntityHeading(cache.ped, floor.heading)
                end
            end
        }
    end

    -- メニューを表示
    lib.registerContext({
        id = 'elevator_menu',
        title = building.label,
        options = menuOptions
    })

    lib.showContext('elevator_menu')
end

-- マーカーの描画とキー入力の検知
CreateThread(function()
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(cache.ped)
        
        for buildingId, building in pairs(Config.Buildings) do
            for _, floor in ipairs(building.floors) do
                local distance = #(playerCoords - floor.coords)
                
                if distance < 10.0 then
                    sleep = 0
                    -- マーカーの描画
                    DrawMarker(1, -- マーカータイプ (円形)
                        floor.coords.x, floor.coords.y, floor.coords.z - 1.0, -- 座標
                        0.0, 0.0, 0.0, -- 方向
                        0.0, 0.0, 0.0, -- 回転
                        1.0, 1.0, 1.0, -- サイズ
                        0, 157, 255, 155, -- 色 (RGBA)
                        false, false, 2, false, nil, nil, false -- その他のオプション
                    )
                    
                    if distance < 1.5 then
                        -- 近くにいる時は操作ガイドを表示
                        lib.showTextUI('[E] エレベーターを使用')
                        
                        -- Eキーが押されたらメニューを表示
                        if IsControlJustReleased(0, 38) then -- 38 = E
                            lib.hideTextUI()
                            ShowElevatorMenu(buildingId)
                        end
                    else
                        lib.hideTextUI()
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)