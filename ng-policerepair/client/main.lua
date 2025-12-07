local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local inRepairZone = false
local currentPoint = nil
local repairPoints = {}

-- デバッグログ関数
local function DebugLog(message)
    if Config.Debug then
        print('^3[ng-policerepair DEBUG] ^7' .. message)
    end
end

-- プレイヤーデータの初期化
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

-- プレイヤーが修理を使用できるかチェック
function IsPlayerAllowed()
    if not PlayerData.job then return false end
    
    for _, allowedJob in ipairs(Config.AllowedJobs) do
        if PlayerData.job.name == allowedJob then
            return true
        end
    end
    return false
end

-- 車両修理処理
function RepairVehicle()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    -- 車両に乗っているかチェック
    if vehicle == 0 then
        -- 近くの車両を検索
        local playerCoords = GetEntityCoords(playerPed)
        vehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 5.0, 0, 71)
        
        if vehicle == 0 then
            lib.notify({
                title = '修理エラー',
                description = Config.Notifications.noVehicle,
                type = 'error'
            })
            return
        end
    end

    -- 確認ダイアログを表示
    local alert = lib.alertDialog({
        header = '車両修理確認',
        content = string.format('この車両を修理しますか？\n費用: $%s', Config.RepairCost),
        centered = true,
        cancel = true
    })

    if alert == 'confirm' then
        -- 修理アニメーションを開始
        lib.requestAnimDict('mini@repair')
        TaskPlayAnim(playerPed, 'mini@repair', 'fixing_a_ped', 1.0, 1.0, -1, 1, 0, false, false, false)
        
        -- プログレスバーを表示
        if lib.progressBar({
            duration = 5000, -- 5秒
            label = '車両を修理中...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true
            }
        }) then
            -- 修理完了
            ClearPedTasks(playerPed)
            
            -- サーバーに修理要求を送信
            TriggerServerEvent('ng-policerepair:server:repairVehicle', VehToNet(vehicle))
        else
            -- キャンセルされた場合
            ClearPedTasks(playerPed)
            lib.notify({
                title = '修理キャンセル',
                description = '車両の修理がキャンセルされました',
                type = 'inform'
            })
        end
    end
end

-- 修理完了時の処理
RegisterNetEvent('ng-policerepair:client:repairComplete', function(success, message)
    if success then
        lib.notify({
            title = '修理完了',
            description = message,
            type = 'success'
        })
    else
        lib.notify({
            title = '修理失敗',
            description = message,
            type = 'error'
        })
    end
end)

-- 車両修理実行
RegisterNetEvent('ng-policerepair:client:executeRepair', function(netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(vehicle) then
        SetVehicleUndriveable(vehicle, false)
        WashDecalsFromVehicle(vehicle, 1.0)
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehiclePetrolTankHealth(vehicle, 1000.0)
        SetVehicleDirtLevel(vehicle, 0.0)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleFixed(vehicle)
        SetVehicleEngineOn(vehicle, true, true, false)


        pcall(function()
            for i = 0, 5 do
                pcall(SetVehicleTyreFixed, vehicle, i)
            end
            for i = 0, 7 do
                pcall(FixVehicleWindow, vehicle, i)
            end

            -- ドアを閉じる
            for i = 0, 5 do
                pcall(SetVehicleDoorShut, vehicle, i, false)
            end
        end)

        -- 外部燃料リソースを優先して満タン化（cdn-fuel / ox_fuel）
        if GetResourceState and GetResourceState('cdn-fuel') == 'started' then
            DebugLog('cdn-fuel detected, setting fuel to 100%')
            pcall(function()
                exports['cdn-fuel']:SetFuel(vehicle, 100.0)
            end)
        elseif GetResourceState and GetResourceState('ox_fuel') == 'started' then
            DebugLog('ox_fuel detected, setting fuel to 100%')
            pcall(function()
                exports.ox_fuel:SetFuel(vehicle, 100.0)
            end)
        end

        -- 追加: jim-mechanic 等で管理されている可能性のある詳細パラメータ（ドライブシャフト、スパークプラグ、オイル、バッテリー、燃料タンク等）を復旧する試行
        pcall(function()
            if GetResourceState and GetResourceState('jim-mechanic') == 'started' then
                DebugLog('jim-mechanic detected, attempting to repair additional vehicle components...')
                local DamageComponents = { "oil", "axle", "battery", "fuel", "spark" }
                for _, component in ipairs(DamageComponents) do
                    DebugLog('Repairing component: ' .. component)
                    pcall(function()
                        exports['jim-mechanic']:SetVehicleStatus(vehicle, component, 100)
                    end)
                end
            end
        end)

    end
end)

-- 修理ポイントの作成
local function CreateRepairPoints()
    for i, point in ipairs(Config.RepairPoints) do
        local repairPoint = lib.points.new({
            coords = point.coords,
            distance = 5.0,
        })

        function repairPoint:onEnter()
            inRepairZone = true
            currentPoint = point
            
            if IsPlayerAllowed() then
                lib.showTextUI('[E] ' .. point.label, {
                    position = "top-center",
                    icon = 'wrench'
                })
            else
                lib.showTextUI('[!] ポリス職員のみ使用可能', {
                    position = "top-center",
                    icon = 'times'
                })
            end
        end

        function repairPoint:onExit()
            inRepairZone = false
            currentPoint = nil
            lib.hideTextUI()
        end

        function repairPoint:nearby()
            -- サークルマーカーを描画
            DrawMarker(
                1, -- タイプ（円柱）
                point.coords.x, point.coords.y, point.coords.z - 1.0,
                0.0, 0.0, 0.0, -- 回転
                0.0, 0.0, 0.0, -- 方向
                point.radius * 2, point.radius * 2, 1.0, -- スケール
                0, 100, 255, 100, -- 色（青、半透明）
                false, true, 2, false, nil, nil, false
            )

            -- 境界線を描画
            DrawMarker(
                25, -- タイプ（円のアウトライン）
                point.coords.x, point.coords.y, point.coords.z,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                point.radius * 2, point.radius * 2, 1.0,
                0, 150, 255, 200, -- 色（青、より濃い）
                false, true, 2, false, nil, nil, false
            )
        end

        repairPoints[i] = repairPoint
    end
end

-- Eキーの入力処理
CreateThread(function()
    while true do
        if inRepairZone and currentPoint then
            if IsControlJustReleased(0, 38) then -- Eキー
                if IsPlayerAllowed() then
                    RepairVehicle()
                else
                    lib.notify({
                        title = 'アクセス拒否',
                        description = Config.Notifications.noJob,
                        type = 'error'
                    })
                end
            end
        end
        Wait(0)
    end
end)

-- 初期化
CreateThread(function()
    -- Wait until player data is loaded
    while not PlayerData.job do
        PlayerData = QBCore.Functions.GetPlayerData()
        Wait(1000)
    end
    
    -- Create repair points
    CreateRepairPoints()
    print('^2[ng-policerepair] ^7Client initialized successfully')
end)