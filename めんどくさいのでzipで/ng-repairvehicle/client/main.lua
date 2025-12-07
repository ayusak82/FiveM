local QBCore = exports['qb-core']:GetCoreObject()

-- プレート入力用のUI
local function inputPlate()
    local input = lib.inputDialog('車両返却', {
        {
            type = 'input',
            label = 'ナンバープレート',
            placeholder = 'ABC 123',
            required = true,
            maxLength = 8
        }
    })
    
    if not input then return end
    return string.upper(input[1])
end

-- Admin用のプレイヤー選択UI
local function selectPlayer()
    -- サーバーからプレイヤー一覧を取得
    local players = {}
    for _, player in ipairs(GetActivePlayers()) do
        local serverId = GetPlayerServerId(player)
        local name = GetPlayerName(player)
        if serverId and name then
            players[#players + 1] = {
                serverId = serverId,
                name = name
            }
        end
    end

    -- オプション作成
    local options = {}
    for _, player in ipairs(players) do
        options[#options + 1] = {
            title = string.format("ID: %s - %s", player.serverId, player.name),
            value = player.serverId
        }
    end

    -- プレイヤーが見つからない場合
    if #options == 0 then
        lib.notify({
            title = '車両返却',
            description = 'オンラインプレイヤーが見つかりません',
            type = 'error'
        })
        return
    end

    local input = lib.inputDialog('プレイヤー選択', {
        {
            type = 'select',
            label = '対象プレイヤー',
            options = options,
            required = true
        }
    })
    
    if not input then return end
    return input[1] -- ServerIDを返す
end

-- 指定したプレートの車両を探して情報を取得
local function getVehicleInfoByPlate(plate)
    local vehicles = GetGamePool('CVehicle')
    for _, vehicle in ipairs(vehicles) do
        if GetVehicleNumberPlateText(vehicle) == plate then
            local engineHealth = GetVehicleEngineHealth(vehicle)
            local bodyHealth = GetVehicleBodyHealth(vehicle)
            
            -- 損傷率を計算 (100%が最良の状態)
            local engineDamage = 100 - ((engineHealth / 1000.0) * 100)
            local bodyDamage = 100 - ((bodyHealth / 1000.0) * 100)
            
            return {
                plate = plate,
                vehicle = vehicle,
                engineDamage = engineDamage,
                bodyDamage = bodyDamage
            }
        end
    end
    return {
        plate = plate,
        vehicle = nil,
        engineDamage = 0,
        bodyDamage = 0
    }
end

-- 近くの車両の情報を取得
local function getClosestVehicleInfo()
    local coords = GetEntityCoords(PlayerPedId())
    local vehicle = lib.getClosestVehicle(coords, Config.SearchDistance, false)
    if not vehicle then return false end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    
    -- 損傷率を計算 (100%が最良の状態)
    local engineDamage = 100 - ((engineHealth / 1000.0) * 100)
    local bodyDamage = 100 - ((bodyHealth / 1000.0) * 100)
    
    return {
        plate = plate,
        vehicle = vehicle,
        engineDamage = engineDamage,
        bodyDamage = bodyDamage
    }
end

-- ダメージ要件のチェック
local function checkDamageRequirement(vehicleInfo)
    if not Config.DamageRequirement.enabled then return true end
    
    local totalDamage = 0
    local damageCount = 0
    
    if Config.DamageRequirement.checkEngine then
        totalDamage = totalDamage + vehicleInfo.engineDamage
        damageCount = damageCount + 1
    end
    
    if Config.DamageRequirement.checkBody then
        totalDamage = totalDamage + vehicleInfo.bodyDamage
        damageCount = damageCount + 1
    end
    
    -- 平均ダメージを計算
    local averageDamage = totalDamage / damageCount
    return averageDamage >= Config.DamageRequirement.minPercent
end

-- 料金計算
local function calculateCost(engineDamage, bodyDamage)
    local cost = Config.Costs.base
    cost = cost + (engineDamage * Config.Costs.engineDamage)
    cost = cost + (bodyDamage * Config.Costs.bodyDamage)
    return math.ceil(cost)
end

-- 車両返却の主要機能
local function ReturnVehicle(manual_plate, targetCitizenId, isAdminAction)
    local isAdmin = isAdminAction and lib.callback.await('ng-repairvehicle:server:isAdmin', false)
    
    if manual_plate then
        -- プレート指定での返却処理
        if lib.callback.await('ng-repairvehicle:server:checkOwner', false, manual_plate, targetCitizenId) then
            -- 車両の情報を取得
            local vehicleInfo = getVehicleInfoByPlate(manual_plate)

            -- ダメージ要件チェック（Admin以外）
            if not isAdmin and not checkDamageRequirement(vehicleInfo) then
                lib.notify({
                    title = '車両返却',
                    description = string.format(Config.Messages.notEnoughDamage, Config.DamageRequirement.minPercent),
                    type = 'error'
                })
                return false
            end

            local cost = isAdmin and 0 or calculateCost(vehicleInfo.engineDamage, vehicleInfo.bodyDamage)
            
            local alert = lib.alertDialog({
                header = '車両返却',
                content = isAdmin and '車両を返却しますか？' or string.format(Config.Messages.costMessage, cost),
                centered = true,
                cancel = true
            })
            
            if alert == 'confirm' then
                if lib.callback.await('ng-repairvehicle:server:returnVehicle', false, manual_plate, cost, vehicleInfo, targetCitizenId, isAdminAction) then
                    -- 同じプレートの車両を探して削除
                    if vehicleInfo.vehicle then
                        DeleteVehicle(vehicleInfo.vehicle)
                    end
                    
                    lib.notify({
                        title = '車両返却',
                        description = targetCitizenId and string.format(Config.Messages.adminReturnSuccess, manual_plate) or Config.Messages.returnSuccess,
                        type = 'success'
                    })
                    return true
                else
                    lib.notify({
                        title = '車両返却',
                        description = Config.Messages.notEnoughMoney,
                        type = 'error'
                    })
                end
            end
        else
            lib.notify({
                title = '車両返却',
                description = Config.Messages.notYourVehicle,
                type = 'error'
            })
            return false
        end
    else
        -- 目の前の車両での返却処理
        local vehicleInfo = getClosestVehicleInfo()
        if not vehicleInfo then
            lib.notify({
                title = '車両返却',
                description = Config.Messages.noVehicleNearby,
                type = 'error'
            })
            return false
        end

        -- ダメージ要件チェック（Admin以外）
        if not isAdmin and not checkDamageRequirement(vehicleInfo) then
            lib.notify({
                title = '車両返却',
                description = string.format(Config.Messages.notEnoughDamage, Config.DamageRequirement.minPercent),
                type = 'error'
            })
            return false
        end

        if lib.callback.await('ng-repairvehicle:server:checkOwner', false, vehicleInfo.plate, targetCitizenId) then
            local cost = isAdmin and 0 or calculateCost(vehicleInfo.engineDamage, vehicleInfo.bodyDamage)
            
            local alert = lib.alertDialog({
                header = '車両返却',
                content = isAdmin and '車両を返却しますか？' or string.format(Config.Messages.costMessage, cost),
                centered = true,
                cancel = true
            })
            
            if alert == 'confirm' then
                if lib.callback.await('ng-repairvehicle:server:returnVehicle', false, vehicleInfo.plate, cost, {
                    engineDamage = vehicleInfo.engineDamage,
                    bodyDamage = vehicleInfo.bodyDamage
                }, targetCitizenId, isAdminAction) then
                    if vehicleInfo.vehicle then DeleteVehicle(vehicleInfo.vehicle) end
                    lib.notify({
                        title = '車両返却',
                        description = targetCitizenId and string.format(Config.Messages.adminReturnSuccess, vehicleInfo.plate) or Config.Messages.returnSuccess,
                        type = 'success'
                    })
                    return true
                else
                    lib.notify({
                        title = '車両返却',
                        description = Config.Messages.notEnoughMoney,
                        type = 'error'
                    })
                end
            end
        else
            lib.notify({
                title = '車両返却',
                description = Config.Messages.notYourVehicle,
                type = 'error'
            })
            return false
        end
    end
end

-- 通常コマンド登録
RegisterCommand(Config.Command, function()
    local alert = lib.alertDialog({
        header = '車両返却',
        content = '方法を選択してください',
        centered = true,
        cancel = true,
        labels = {
            confirm = '目の前の車両',
            cancel = 'プレート指定'
        }
    })

    if alert == 'confirm' then
        ReturnVehicle()
    else
        local plate = inputPlate()
        if plate then
            ReturnVehicle(plate)
        end
    end
end)

-- Admin用コマンド登録
RegisterCommand(Config.AdminCommand, function()
    local isAdmin = lib.callback.await('ng-repairvehicle:server:isAdmin', false)
    if not isAdmin then 
        lib.notify({
            title = '車両返却',
            description = '権限がありません',
            type = 'error'
        })
        return 
    end

    local targetServerId = selectPlayer()
    if not targetServerId then return end
    
    -- ServerIDからCitizenIDを取得
    local targetCitizenId = lib.callback.await('ng-repairvehicle:server:getPlayerCitizenId', false, targetServerId)
    if not targetCitizenId then
        lib.notify({
            title = '車両返却',
            description = 'プレイヤーが見つかりません',
            type = 'error'
        })
        return
    end
    
    local alert = lib.alertDialog({
        header = '車両返却（Admin）',
        content = '方法を選択してください',
        centered = true,
        cancel = true,
        labels = {
            confirm = '目の前の車両',
            cancel = 'プレート指定'
        }
    })

    if alert == 'confirm' then
        ReturnVehicle(nil, targetCitizenId, true)
    else
        local plate = inputPlate()
        if plate then
            ReturnVehicle(plate, targetCitizenId, true)
        end
    end
end)

-- Export登録
exports('ReturnVehicle', ReturnVehicle)