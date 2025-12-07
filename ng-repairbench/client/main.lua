local QBCore = exports['qb-core']:GetCoreObject()

-- ローカル変数
local repairBenches = {}
local isRepairing = false

-- リソース開始時の初期化
CreateThread(function()
    -- 修理ベンチの設置とターゲット登録
    for i, bench in pairs(Config.RepairBenches) do
        -- ベンチオブジェクトの作成
        local benchObject = CreateObject(GetHashKey('prop_toolchest_05'), bench.coords.x, bench.coords.y, bench.coords.z, false, true, false)
        SetEntityHeading(benchObject, bench.heading)
        FreezeEntityPosition(benchObject, true)
        
        -- ベンチ情報を保存
        repairBenches[i] = {
            object = benchObject,
            coords = bench.coords
        }
        
        -- ox_targetでインタラクション設定
        exports.ox_target:addLocalEntity(benchObject, {
            {
                name = 'ng_repairbench_' .. i,
                label = Config.Texts.targetLabel,
                icon = 'fas fa-wrench',
                distance = Config.Settings.playerMaxDistance,
                onSelect = function()
                    OpenRepairMenu(bench.coords)
                end
            }
        })
        
        -- ブリップの作成
        if bench.blip.enabled then
            local blip = AddBlipForCoord(bench.coords.x, bench.coords.y, bench.coords.z)
            SetBlipSprite(blip, bench.blip.sprite)
            SetBlipColour(blip, bench.blip.color)
            SetBlipScale(blip, bench.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(bench.blip.name)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- 修理メニューを開く
function OpenRepairMenu(benchCoords)
    if isRepairing then return end
    
    -- 近くの車両を検索
    local vehicle = GetNearestVehicle(benchCoords)
    if not vehicle then
        lib.notify({
            title = 'エラー',
            description = Config.Texts.noVehicle,
            type = 'error'
        })
        return
    end
    
    -- プレイヤーが車両に乗っているかチェック
    local ped = PlayerPedId()
    if IsPedInVehicle(ped, vehicle, false) then
        lib.notify({
            title = 'エラー',
            description = Config.Texts.notInVehicle,
            type = 'error'
        })
        return
    end
    
    -- 車両の状態を取得
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    local fuelLevel = GetVehicleFuelLevel(vehicle)
    
    -- 修理が必要かチェック
    local needsEngineRepair = engineHealth < 1000.0
    local needsBodyRepair = bodyHealth < 1000.0
    local needsFuel = fuelLevel < 95.0
    
    -- 燃料補給の料金計算
    local fuelNeeded = math.ceil(100 - fuelLevel)
    local fuelCost = fuelNeeded * Config.RepairPrices.petrol
    
    -- メニューオプションを作成
    local options = {}
    
    -- エンジン修理
    if needsEngineRepair then
        table.insert(options, {
            title = Config.Texts.engineRepair,
            description = string.format(Config.Texts.engineRepairDesc, Config.RepairPrices.engine),
            icon = 'engine',
            onSelect = function()
                StartRepair(vehicle, 'engine', Config.RepairPrices.engine, Config.RepairTimes.engine)
            end
        })
    end
    
    -- ボディ修理
    if needsBodyRepair then
        table.insert(options, {
            title = Config.Texts.bodyRepair,
            description = string.format(Config.Texts.bodyRepairDesc, Config.RepairPrices.body),
            icon = 'hammer',
            onSelect = function()
                StartRepair(vehicle, 'body', Config.RepairPrices.body, Config.RepairTimes.body)
            end
        })
    end
    
    -- 完全修理
    if needsEngineRepair or needsBodyRepair then
        table.insert(options, {
            title = Config.Texts.fullRepair,
            description = string.format(Config.Texts.fullRepairDesc, Config.RepairPrices.full),
            icon = 'screwdriver-wrench',
            onSelect = function()
                StartRepair(vehicle, 'full', Config.RepairPrices.full, Config.RepairTimes.full)
            end
        })
    end
    
    -- 燃料補給
    if needsFuel then
        table.insert(options, {
            title = Config.Texts.refuel,
            description = string.format(Config.Texts.refuelDesc, fuelCost),
            icon = 'gas-pump',
            onSelect = function()
                StartRepair(vehicle, 'petrol', fuelCost, Config.RepairTimes.petrol, fuelNeeded)
            end
        })
    end
    
    -- メニューに表示するオプションがない場合
    if #options == 0 then
        lib.notify({
            title = '修理不要',
            description = '車両は修理の必要がありません',
            type = 'success'
        })
        return
    end
    
    -- メニューを表示
    lib.registerContext({
        id = 'ng_repairbench_menu',
        title = Config.Texts.menuTitle,
        options = options
    })
    
    lib.showContext('ng_repairbench_menu')
end

-- 修理処理を開始
function StartRepair(vehicle, repairType, cost, duration, fuelAmount)
    if isRepairing then return end
    
    -- エンジンがかかっているかチェック
    if Config.Settings.checkVehicleEngine and GetIsVehicleEngineRunning(vehicle) then
        lib.notify({
            title = 'エラー',
            description = 'エンジンを停止してください',
            type = 'error'
        })
        return
    end
    
    -- サーバーに支払い確認を送信
    QBCore.Functions.TriggerCallback('ng-repairbench:server:checkPayment', function(canAfford)
        if not canAfford then
            lib.notify({
                title = 'エラー',
                description = Config.Texts.notEnoughMoney,
                type = 'error'
            })
            return
        end
        
        -- 修理アニメーション開始
        if Config.Settings.playAnimation then
            StartRepairAnimation()
        end
        
        isRepairing = true
        
        -- プログレスバーを表示
        if Config.Settings.showProgressBar then
            if lib.progressBar({
                duration = duration * 1000,
                label = Config.Texts.repairInProgress,
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                    move = true,
                    combat = true
                }
            }) then
                -- 修理完了
                TriggerServerEvent('ng-repairbench:server:processPayment', cost, repairType)
                ApplyRepair(vehicle, repairType, fuelAmount)
                
                local successMessage = repairType == 'petrol' and Config.Texts.refuelSuccess or Config.Texts.repairSuccess
                lib.notify({
                    title = '完了',
                    description = successMessage,
                    type = 'success'
                })
            else
                -- キャンセル
                lib.notify({
                    title = 'キャンセル',
                    description = Config.Texts.cancelled,
                    type = 'error'
                })
            end
        else
            -- プログレスバーなしの場合
            Wait(duration * 1000)
            TriggerServerEvent('ng-repairbench:server:processPayment', cost, repairType)
            ApplyRepair(vehicle, repairType, fuelAmount)
            
            local successMessage = repairType == 'petrol' and Config.Texts.refuelSuccess or Config.Texts.repairSuccess
            lib.notify({
                title = '完了',
                description = successMessage,
                type = 'success'
            })
        end
        
        -- アニメーション終了
        if Config.Settings.playAnimation then
            StopRepairAnimation()
        end
        
        isRepairing = false
        
    end, cost)
end

-- 修理を適用
function ApplyRepair(vehicle, repairType, fuelAmount)
    if repairType == 'engine' then
        SetVehicleEngineHealth(vehicle, 1000.0)
    elseif repairType == 'body' then
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehicleDeformationFixed(vehicle)
    elseif repairType == 'full' then
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleFixed(vehicle)
    elseif repairType == 'petrol' then
        SetVehicleFuelLevel(vehicle, 100.0)
    end
end

-- 近くの車両を取得
function GetNearestVehicle(coords)
    local vehicles = GetGamePool('CVehicle')
    local closestVehicle = nil
    local closestDistance = Config.Settings.maxDistance
    
    for _, vehicle in pairs(vehicles) do
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(coords - vehicleCoords)
        
        if distance < closestDistance then
            closestVehicle = vehicle
            closestDistance = distance
        end
    end
    
    return closestVehicle
end

-- 修理アニメーション開始
function StartRepairAnimation()
    local ped = PlayerPedId()
    RequestAnimDict(Config.Settings.animation.dict)
    
    while not HasAnimDictLoaded(Config.Settings.animation.dict) do
        Wait(10)
    end
    
    TaskPlayAnim(ped, Config.Settings.animation.dict, Config.Settings.animation.anim, 8.0, -8.0, -1, Config.Settings.animation.flag, 0, false, false, false)
end

-- 修理アニメーション終了
function StopRepairAnimation()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
end

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        -- 作成したオブジェクトを削除
        for _, bench in pairs(repairBenches) do
            if DoesEntityExist(bench.object) then
                DeleteEntity(bench.object)
            end
        end
    end
end)