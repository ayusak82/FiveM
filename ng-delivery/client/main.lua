-- ローカル変数
local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local activeDelivery = false
local deliveryVehicle = nil
local deliveryBlip = nil
local deliveryLocation = nil
local packageObject = nil
local isHoldingPackage = false
local deliveryCount = 0
local currentDepot = nil
local currentDifficulty = nil
local deliveryStartTime = 0
local deliveryTimeLimit = 0
local deliveryTimer = nil

-- 拠点に戻るための変数
local isReturningToDepot = false
local returnDepotBlip = nil
local completedDeliveriesCount = 0

-- イベントハンドラ
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    InitDeliveryBlips()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    RemoveDeliveryBlips()
    CleanupDelivery()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

-- グローバル変数（スポーン情報記録用）
local deliveryVehicleSpawnLocation = nil

-- 関数定義
function InitDeliveryBlips()
    if not Config.UseBlips then return end
    
    for i, depot in ipairs(Config.DeliveryDepots) do
        local blip = AddBlipForCoord(depot.coords.x, depot.coords.y, depot.coords.z)
        SetBlipSprite(blip, depot.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, depot.blip.scale)
        SetBlipColour(blip, depot.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(depot.blip.label)
        EndTextCommandSetBlipName(blip)
    end
end

function RemoveDeliveryBlips()
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end
end

function CleanupDelivery()
    activeDelivery = false
    RemoveDeliveryBlips()
    
    if deliveryTimer then
        deliveryTimer = nil
    end
    
    -- 車両の処理
    if DoesEntityExist(deliveryVehicle) then
        -- 配達完了後の車両処理
        if Config.VehicleSettings.DeleteVehicle then
            -- 車両を削除（使用しないが互換性のために残す）
            DeleteVehicle(deliveryVehicle)
            deliveryVehicle = nil
            
            if Config.Debug then
                print('配達車両を削除しました')
            end
        elseif isReturningToDepot then
            -- 車両が拠点に戻された場合（正常終了）
            local ped = PlayerPedId()
            if IsPedInVehicle(ped, deliveryVehicle, false) then
                TaskLeaveVehicle(ped, deliveryVehicle, 0)
                -- プレイヤーが降りるのを少し待つ
                Wait(1500)
            end
            
            -- 車両の状態をリセット
            SetVehicleEngineOn(deliveryVehicle, false, true, false)
            SetVehicleDirtLevel(deliveryVehicle, 0.0)
            
            -- 一定時間後に車両を削除
            SetTimeout(10000, function()
                if DoesEntityExist(deliveryVehicle) then
                    DeleteVehicle(deliveryVehicle)
                end
            end)
            
            if Config.Debug then
                print('配達車両を拠点に戻しました - ミッション完了')
            end
            
            -- 通知
            lib.notify({
                title = '配達システム',
                description = '車両を拠点に戻しました - お疲れ様でした！',
                type = Config.Notifications.Success
            })
        else
            -- 配達が途中で中断または失敗した場合、車両を削除
            DeleteVehicle(deliveryVehicle)
            deliveryVehicle = nil
            
            if Config.Debug then
                print('配達が中断されたため車両を削除しました')
            end
        end
    end
    
    -- パッケージの処理
    if packageObject and DoesEntityExist(packageObject) then
        DeleteEntity(packageObject)
        packageObject = nil
    end
    
    -- その他の変数をリセット
    isHoldingPackage = false
    deliveryLocation = nil
    currentDepot = nil
    currentDifficulty = nil
    deliveryCount = 0
    deliveryVehicleSpawnLocation = nil
    isReturningToDepot = false
    
    if returnDepotBlip then
        RemoveBlip(returnDepotBlip)
        returnDepotBlip = nil
    end
end

function CreateDeliveryVehicle(model, depot, depotId)
    -- スポーン座標を取得（カスタム設定またはオフセット）
    local spawnCoords, spawnHeading
    
    -- 拠点に直接定義されたvehicleSpawnを確認
    if depot.vehicleSpawn and depot.vehicleSpawn.coords then
        spawnCoords = depot.vehicleSpawn.coords
        spawnHeading = depot.vehicleSpawn.heading or depot.heading
        
        if Config.Debug then
            print('拠点設定のスポーン位置を使用: ' .. tostring(spawnCoords) .. ', 向き: ' .. spawnHeading)
        end
    -- カスタムスポーン位置が設定されているかチェック
    elseif Config.VehicleSettings.VehicleSpawnLocations and Config.VehicleSettings.VehicleSpawnLocations[depotId] then
        local spawnLoc = Config.VehicleSettings.VehicleSpawnLocations[depotId]
        spawnCoords = spawnLoc.coords
        spawnHeading = spawnLoc.heading
        
        if Config.Debug then
            print('カスタムスポーン位置を使用: ' .. tostring(spawnCoords) .. ', 向き: ' .. spawnHeading)
        end
    else
        -- オフセットを使用したスポーン位置を計算
        spawnCoords = vector3(
            depot.coords.x + Config.VehicleSettings.SpawnOffset.x, 
            depot.coords.y + Config.VehicleSettings.SpawnOffset.y, 
            depot.coords.z + Config.VehicleSettings.SpawnOffset.z
        )
        spawnHeading = depot.heading
        
        if Config.Debug then
            print('オフセットスポーン位置を使用: ' .. tostring(spawnCoords) .. ', 向き: ' .. spawnHeading)
        end
    end
    
    -- スポーン前に地面高さを調整
    local safeZ = spawnCoords.z
    local ground, posZ = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z + 1.0, 1)
    if ground then
        safeZ = posZ + 1.0
    end
    
    -- 安全なスポーン位置を作成
    local safeCoords = vector3(spawnCoords.x, spawnCoords.y, safeZ)
    
    -- 車両の生成
    QBCore.Functions.SpawnVehicle(model, function(vehicle)
        -- 車両の位置と向きを設定
        SetEntityHeading(vehicle, spawnHeading)
        
        -- 車両のプロパティを設定（QBCoreのバージョンによって異なる場合がある）
        if Config.VehicleSettings.UseVehicleProperties then
            -- 車両のプロパティ設定を試みる
            local success = pcall(function()
                -- qb-coreのエクスポート関数を使用
                exports['qb-core']:SetVehicleProperties(vehicle, {})
            end)
            
            if not success and Config.Debug then
                print('SetVehiclePropertiesが見つかりません。代替手段を使用します。')
            end
        else
            -- 基本的な車両プロパティの設定（カスタムプロパティなし）
            if Config.Debug then
                print('UseVehiclePropertiesがオフです。基本プロパティのみ設定します。')
            end
        end
        
        -- 車両の状態を設定
        SetVehicleEngineOn(vehicle, false, false, false)
        SetVehicleFuelLevel(vehicle, Config.VehicleSettings.FuelLevel)
        SetVehicleDirtLevel(vehicle, 0.0)
        
        -- 車両の鍵を与える（QBとOldシステムに対応）
        local plate = GetVehicleNumberPlateText(vehicle)
        
        if Config.VehicleSettings.VehicleKeys == 'qb' then
            -- qb-vehiclekeysの場合
            TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
        else
            -- 古い鍵システムの場合
            TriggerEvent("vehiclekeys:client:SetOwner", plate)
        end
        
        -- プレイヤーを車両に入れる
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
        
        -- 車両をエンジンオン
        SetTimeout(1000, function()
            SetVehicleEngineOn(vehicle, true, true, false)
        end)
        
        -- 変数に保存
        deliveryVehicle = vehicle
        
        -- スポーン位置を記録（後で戻るため）
        deliveryVehicleSpawnLocation = {
            coords = safeCoords,
            heading = spawnHeading,
            depotId = depotId
        }
        
        -- デバッグ情報
        if Config.Debug then
            print('車両がスポーンしました: ' .. model .. ' (' .. plate .. ')')
        end
    end, safeCoords, true)
end

function StartDelivery(depotId, difficulty)
    if activeDelivery then
        lib.notify({
            title = '配達システム',
            description = '既に配達が進行中です',
            type = Config.Notifications.Error
        })
        return
    end
    
    -- ジョブチェック
    if Config.RequireJob and PlayerData.job.name ~= Config.JobName then
        lib.notify({
            title = '配達システム',
            description = 'このジョブを行うには' .. Config.JobName .. 'の職業が必要です',
            type = Config.Notifications.Error
        })
        return
    end
    
    -- 難易度と時間制限の設定
    currentDifficulty = difficulty
    deliveryTimeLimit = Config.Difficulty[difficulty].TimeLimit
    
    -- 配達拠点の設定
    currentDepot = Config.DeliveryDepots[depotId]
    
    -- 配達車両のスポーン
    if Config.VehicleSettings.SpawnVehicle then
        CreateDeliveryVehicle(
            Config.VehicleSettings.VehicleModel,
            currentDepot,
            depotId
        )
    end
    
    -- 配達先の選択（ランダム）
    local randomLocation = Config.DeliveryLocations[math.random(#Config.DeliveryLocations)]
    deliveryLocation = randomLocation
    
    -- 配達先のブリップ作成
    if Config.UseBlips then
        deliveryBlip = AddBlipForCoord(deliveryLocation.coords.x, deliveryLocation.coords.y, deliveryLocation.coords.z)
        SetBlipSprite(deliveryBlip, 501)
        SetBlipDisplay(deliveryBlip, 4)
        SetBlipScale(deliveryBlip, 0.8)
        SetBlipColour(deliveryBlip, 2)
        SetBlipRoute(deliveryBlip, true)
        SetBlipRouteColour(deliveryBlip, 2)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("配達先")
        EndTextCommandSetBlipName(deliveryBlip)
    end
    
    -- 配達の開始
    activeDelivery = true
    deliveryStartTime = GetGameTimer()
    
    -- タイマーの開始
    StartDeliveryTimer()
    
    -- 通知
    lib.notify({
        title = '配達システム',
        description = '配達を開始しました。パッケージを運んでください',
        type = Config.Notifications.Success
    })
    
    -- パッケージの取得オプションを表示
    TriggerEvent('ng-delivery:client:ShowGetPackageOption')
end

function StartDeliveryTimer()
    if deliveryTimer then return end
    
    deliveryTimer = true
    
    CreateThread(function()
        while deliveryTimer do
            if not activeDelivery then
                deliveryTimer = nil
                return
            end
            
            local timeLeft = deliveryTimeLimit - math.floor((GetGameTimer() - deliveryStartTime) / 1000)
            
            if timeLeft <= 0 then
                -- 時間切れ
                lib.notify({
                    title = '配達システム',
                    description = '時間切れ！配達に失敗しました',
                    type = Config.Notifications.Error
                })
                
                CleanupDelivery()
                TriggerServerEvent('ng-delivery:server:FailDelivery')
                break
            end
            
            -- 残り時間が少ない場合の警告
            if timeLeft <= 60 and timeLeft % 10 == 0 then
                lib.notify({
                    title = '配達システム',
                    description = '残り' .. timeLeft .. '秒！急いでください',
                    type = Config.Notifications.Info
                })
            end
            
            Wait(1000)
        end
    end)
end

function GetPackageType(difficulty)
    if difficulty == 'Easy' then
        return 'small'
    elseif difficulty == 'Medium' then
        return 'medium'
    else
        return 'large'
    end
end

function PickupPackage()
    if not activeDelivery or isHoldingPackage then return end
    
    local packageType = GetPackageType(currentDifficulty)
    local packageConfig = Config.PackageTypes[packageType]
    
    -- プレイヤーアニメーション
    lib.requestAnimDict(packageConfig.animation.dict)
    
    -- パッケージオブジェクトの作成
    lib.requestModel(packageConfig.model)
    
    -- アニメーション開始
    TaskPlayAnim(
        PlayerPedId(),
        packageConfig.animation.dict,
        packageConfig.animation.anim,
        8.0, -8.0, -1, 49, 0, false, false, false
    )
    
    -- パッケージ作成
    packageObject = CreateObject(
        GetHashKey(packageConfig.model),
        0, 0, 0,
        true, true, true
    )
    
    AttachEntityToEntity(
        packageObject,
        PlayerPedId(),
        GetPedBoneIndex(PlayerPedId(), 60309),
        0.125, 0.0, 0.0,
        0.0, 0.0, 0.0,
        true, true, false, true, 0, true
    )
    
    isHoldingPackage = true
    
    -- 通知
    lib.notify({
        title = '配達システム',
        description = 'パッケージを持ち上げました。配達先に届けてください',
        type = Config.Notifications.Info
    })
end

function DeliverPackage()
    if not activeDelivery or not isHoldingPackage then return end
    
    -- パッケージとアニメーションの解除
    if DoesEntityExist(packageObject) then
        DeleteEntity(packageObject)
    end
    
    ClearPedTasks(PlayerPedId())
    isHoldingPackage = false
    
    -- 配達完了処理
    deliveryCount = deliveryCount + 1
    RemoveDeliveryBlips()
    
    -- 配達報酬の計算
    local timeSpent = math.floor((GetGameTimer() - deliveryStartTime) / 1000)
    local timeBonus = math.max(0, (deliveryTimeLimit - timeSpent) / deliveryTimeLimit)
    
    -- サーバーサイドに報告
    TriggerServerEvent('ng-delivery:server:CompleteDelivery', currentDifficulty, timeBonus)
    
    -- 続けるかどうかの確認ダイアログ
    lib.showContext('delivery_continue_menu')
end

-- Target 統合
if Config.UseTarget then
    -- 配達拠点でのターゲットオプション
    for i, depot in ipairs(Config.DeliveryDepots) do
        if Config.TargetResource == 'ox_target' then
            -- ox_target の場合
            exports.ox_target:addBoxZone({
                coords = vec3(depot.coords.x, depot.coords.y, depot.coords.z),
                size = vec3(2.0, 2.0, 3.0),
                rotation = depot.heading,
                debug = Config.Debug,
                options = {
                    {
                        name = 'depot_' .. i,
                        label = '配達の仕事を開始',
                        icon = 'fas fa-box',
                        onSelect = function()
                            lib.showContext('delivery_start_menu')
                        end
                    }
                }
            })
        elseif Config.TargetResource == 'qb-target' then
            -- qb-target の場合
            exports['qb-target']:AddBoxZone(
                'depot_' .. i,
                vector3(depot.coords.x, depot.coords.y, depot.coords.z),
                2.0, 2.0, {
                    name = 'depot_' .. i,
                    heading = depot.heading,
                    debugPoly = Config.Debug,
                    minZ = depot.coords.z - 1.0,
                    maxZ = depot.coords.z + 2.0,
                }, {
                    options = {
                        {
                            type = 'client',
                            icon = 'fas fa-box',
                            label = '配達の仕事を開始',
                            action = function()
                                lib.showContext('delivery_start_menu')
                            end
                        }
                    },
                    distance = 2.5
                }
            )
        end
    end
end

-- ox_lib コンテキストメニュー
lib.registerContext({
    id = 'delivery_start_menu',
    title = '配達システム',
    options = {
        {
            title = '簡単な配達',
            description = '時間: ' .. math.floor(Config.Difficulty.Easy.TimeLimit / 60) .. '分, 報酬: 低',
            icon = 'fas fa-box',
            onSelect = function()
                local closestDepot = 1 -- 最も近い拠点を取得する処理を簡略化
                StartDelivery(closestDepot, 'Easy')
            end
        },
        {
            title = '通常の配達',
            description = '時間: ' .. math.floor(Config.Difficulty.Medium.TimeLimit / 60) .. '分, 報酬: 中',
            icon = 'fas fa-truck',
            onSelect = function()
                local closestDepot = 1
                StartDelivery(closestDepot, 'Medium')
            end
        },
        {
            title = '難しい配達',
            description = '時間: ' .. math.floor(Config.Difficulty.Hard.TimeLimit / 60) .. '分, 報酬: 高',
            icon = 'fas fa-truck-loading',
            onSelect = function()
                local closestDepot = 1
                StartDelivery(closestDepot, 'Hard')
            end
        }
    }
})

-- 拠点までのルートを作成する関数
function CreateReturnRoute()
    -- 既存のブリップをクリア
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end
    
    if returnDepotBlip then
        RemoveBlip(returnDepotBlip)
        returnDepotBlip = nil
    end
    
    -- 拠点への戻るモードに移行
    isReturningToDepot = true
    
    -- 拠点の座標を取得（スポーン位置を優先的に使用）
    local depotCoords
    local returnHeading
    
    if deliveryVehicleSpawnLocation and deliveryVehicleSpawnLocation.coords then
        depotCoords = deliveryVehicleSpawnLocation.coords
        returnHeading = deliveryVehicleSpawnLocation.heading
    elseif currentDepot and currentDepot.coords then
        depotCoords = currentDepot.coords
        returnHeading = currentDepot.heading
    else
        -- フォールバック：もし両方が使用できない場合は現在のプレイヤー位置を使用
        depotCoords = GetEntityCoords(PlayerPedId())
        returnHeading = 0.0
        
        -- デバッグ情報
        if Config.Debug then
            print('警告: 拠点座標が見つからないため、プレイヤー位置を使用します')
        end
    end
    
    -- 拠点へのブリップを作成
    if Config.UseBlips then
        returnDepotBlip = AddBlipForCoord(depotCoords.x, depotCoords.y, depotCoords.z)
        SetBlipSprite(returnDepotBlip, 38) -- 別のアイコンを使用
        SetBlipDisplay(returnDepotBlip, 4)
        SetBlipScale(returnDepotBlip, 1.0)
        SetBlipColour(returnDepotBlip, 3) -- 緑色
        SetBlipRoute(returnDepotBlip, true)
        SetBlipRouteColour(returnDepotBlip, 3)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("配達拠点 (報酬受取)")
        EndTextCommandSetBlipName(returnDepotBlip)
    end
    
    -- 通知
    lib.notify({
        title = '配達システム',
        description = '配達を終了します。車両で拠点に戻って報酬を受け取ってください',
        type = Config.Notifications.Info
    })
    
    -- 拠点への到着をチェックするスレッドを開始
    CreateThread(function()
        local checkInterval = 500 -- チェックの間隔（ミリ秒）
        local warningInterval = 30000 -- 警告メッセージの間隔（ミリ秒）
        local lastWarningTime = 0
        
        while isReturningToDepot do
            Wait(checkInterval)
            
            -- 車両が存在しなくなった場合（削除されたか破壊された）
            if not DoesEntityExist(deliveryVehicle) then
                lib.notify({
                    title = '配達システム',
                    description = '配達車両が見つかりません。ミッションに失敗しました',
                    type = Config.Notifications.Error
                })
                
                TriggerServerEvent('ng-delivery:server:FailDelivery')
                CleanupDelivery()
                return
            end
            
            -- プレイヤーが車両に乗っているかチェック
            local playerPed = PlayerPedId()
            local inVehicle = IsPedInVehicle(playerPed, deliveryVehicle, false)
            local currentTime = GetGameTimer()
            
            -- 車両から離れすぎた場合の警告
            if not inVehicle then
                local playerPos = GetEntityCoords(playerPed)
                local vehiclePos = GetEntityCoords(deliveryVehicle)
                local distanceToVehicle = #(playerPos - vehiclePos)
                
                -- 一定間隔で車両に戻るように警告
                if currentTime - lastWarningTime > warningInterval and distanceToVehicle > 50.0 then
                    lib.notify({
                        title = '配達システム',
                        description = '車両から離れすぎています。車両に戻って拠点に向かってください',
                        type = Config.Notifications.Error
                    })
                    lastWarningTime = currentTime
                end
            else
                -- 車両に乗っている場合、拠点への距離をチェック
                local playerPos = GetEntityCoords(playerPed)
                local distance = #(playerPos - depotCoords)
                
                -- 拠点に到着したかチェック
                if distance < Config.VehicleSettings.ReturnRadius then
                    -- 拠点に到着したので、報酬を受け取る
                    isReturningToDepot = false
                    
                    -- 車両を停める
                    SetVehicleHandbrake(deliveryVehicle, true)
                    SetVehicleEngineOn(deliveryVehicle, false, true, false)
                    
                    -- 通知
                    lib.notify({
                        title = '配達システム',
                        description = '拠点に到着しました！報酬を受け取ります',
                        type = Config.Notifications.Success
                    })
                    
                    -- ブリップを削除
                    if returnDepotBlip then
                        RemoveBlip(returnDepotBlip)
                        returnDepotBlip = nil
                    end
                    
                    -- 報酬を受け取る
                    TriggerServerEvent('ng-delivery:server:FinishDeliveryJob', completedDeliveriesCount)
                    
                    -- 配達をクリーンアップ
                    CleanupDelivery()
                    return
                end
            end
        end
    end)
end

lib.registerContext({
    id = 'delivery_continue_menu',
    title = '配達完了',
    options = {
        {
            title = '別の配達を続ける',
            description = '新しい配達先に向かう',
            icon = 'fas fa-redo',
            onSelect = function()
                -- 新しい配達先を選択
                local randomLocation = Config.DeliveryLocations[math.random(#Config.DeliveryLocations)]
                while randomLocation.coords == deliveryLocation.coords do
                    randomLocation = Config.DeliveryLocations[math.random(#Config.DeliveryLocations)]
                end
                
                deliveryLocation = randomLocation
                
                -- 配達先のブリップ作成
                if Config.UseBlips then
                    deliveryBlip = AddBlipForCoord(deliveryLocation.coords.x, deliveryLocation.coords.y, deliveryLocation.coords.z)
                    SetBlipSprite(deliveryBlip, 501)
                    SetBlipDisplay(deliveryBlip, 4)
                    SetBlipScale(deliveryBlip, 0.8)
                    SetBlipColour(deliveryBlip, 2)
                    SetBlipRoute(deliveryBlip, true)
                    SetBlipRouteColour(deliveryBlip, 2)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString("配達先")
                    EndTextCommandSetBlipName(deliveryBlip)
                end
                
                -- タイマーをリセット
                deliveryStartTime = GetGameTimer()
                
                -- 通知
                lib.notify({
                    title = '配達システム',
                    description = '新しい配達先が設定されました。続けてください',
                    type = Config.Notifications.Success
                })
                
                -- パッケージの取得オプションを表示
                TriggerEvent('ng-delivery:client:ShowGetPackageOption')
            end
        },
        {
            title = '配達を終了する',
            description = '報酬を受け取るために拠点に戻る',
            icon = 'fas fa-check',
            onSelect = function()
                -- 完了した配達数を保存
                completedDeliveriesCount = deliveryCount
                
                -- 常に拠点に戻るように要求する (新仕様)
                CreateReturnRoute()
                
                -- 通知を表示
                lib.notify({
                    title = '配達システム',
                    description = '配達を終了します。拠点に戻って報酬を受け取ってください',
                    type = Config.Notifications.Info
                })
            end
        }
    }
})

-- カスタムイベント
RegisterNetEvent('ng-delivery:client:ShowGetPackageOption', function()
    -- 配達車両の近くでパッケージを取得するオプション
    if Config.UseTarget and deliveryVehicle and DoesEntityExist(deliveryVehicle) then
        if Config.TargetResource == 'ox_target' then
            -- ox_target の場合
            exports.ox_target:addTargetEntity(deliveryVehicle, {
                {
                    name = 'get_package',
                    label = 'パッケージを取得',
                    icon = 'fas fa-box-open',
                    canInteract = function()
                        return activeDelivery and not isHoldingPackage
                    end,
                    onSelect = function()
                        PickupPackage()
                    end
                }
            })
        elseif Config.TargetResource == 'qb-target' then
            -- qb-target の場合
            exports['qb-target']:AddTargetEntity(deliveryVehicle, {
                options = {
                    {
                        type = 'client',
                        icon = 'fas fa-box-open',
                        label = 'パッケージを取得',
                        action = function()
                            PickupPackage()
                        end,
                        canInteract = function()
                            return activeDelivery and not isHoldingPackage
                        end
                    }
                },
                distance = 2.5
            })
        end
    end
end)

-- 配達先でのパッケージ配達オプション
CreateThread(function()
    while true do
        Wait(0)
        
        if activeDelivery and isHoldingPackage and deliveryLocation then
            local playerPos = GetEntityCoords(PlayerPedId())
            local dist = #(playerPos - deliveryLocation.coords)
            
            if dist < 3.0 then
                if Config.ShowMarkers then
                    DrawMarker(
                        2, 
                        deliveryLocation.coords.x, 
                        deliveryLocation.coords.y, 
                        deliveryLocation.coords.z, 
                        0.0, 0.0, 0.0, 
                        0.0, 0.0, 0.0, 
                        0.5, 0.5, 0.5, 
                        0, 255, 0, 155, 
                        false, true, 2, nil, nil, false
                    )
                end
                
                if dist < 1.5 then
                    lib.showTextUI('[E] パッケージを配達する')
                    
                    if IsControlJustReleased(0, 38) then -- E キー
                        lib.hideTextUI()
                        DeliverPackage()
                    end
                else
                    lib.hideTextUI()
                end
            end
        end
    end
end)

-- コマンド登録
RegisterCommand('delivery', function()
    -- 最も近い配達拠点を検索
    local playerPos = GetEntityCoords(PlayerPedId())
    local closestDepot = nil
    local closestDistance = 1000.0
    
    for i, depot in ipairs(Config.DeliveryDepots) do
        local dist = #(playerPos - depot.coords)
        if dist < closestDistance then
            closestDistance = dist
            closestDepot = i
        end
    end
    
    if closestDistance <= 10.0 then
        lib.showContext('delivery_start_menu')
    else
        lib.notify({
            title = '配達システム',
            description = '配達拠点に近づいて試してください',
            type = Config.Notifications.Error
        })
    end
end, false)

-- 初期化
CreateThread(function()
    PlayerData = QBCore.Functions.GetPlayerData()
    InitDeliveryBlips()
end)