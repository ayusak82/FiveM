local QBCore = exports['qb-core']:GetCoreObject()

-- コマンド登録
RegisterCommand(Config.Command, function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    -- 車両に乗車しているかチェック
    if vehicle == 0 then
        lib.notify({
            title = 'エラー',
            description = Config.Messages.not_in_vehicle,
            type = 'error'
        })
        return
    end
    
    -- 車両情報取得
    local vehicleData = {
        model = GetEntityModel(vehicle),
        plate = GetVehicleNumberPlateText(vehicle):gsub("^%s*(.-)%s*$", "%1"), -- 前後の空白を削除
        name = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    }
    
    -- サーバーに使用済みチェック要求
    QBCore.Functions.TriggerCallback('ng-vehicle-transfer:checkUsed', function(alreadyUsed)
        if alreadyUsed then
            lib.notify({
                title = 'エラー',
                description = Config.Messages.already_used,
                type = 'error'
            })
            return
        end
        
        -- 確認ダイアログ表示
        local alert = lib.alertDialog({
            header = Config.Messages.confirm_title,
            content = string.format(Config.Messages.confirm_description, vehicleData.name, vehicleData.plate),
            centered = true,
            cancel = true,
            labels = {
                confirm = Config.Messages.confirm_button,
                cancel = Config.Messages.cancel_button
            }
        })
        
        if alert == 'confirm' then
            -- サーバーに車両データ送信
            TriggerServerEvent('ng-vehicle-transfer:exportVehicle', vehicleData)
        end
    end)
end, false)

-- サーバーからの結果受信
RegisterNetEvent('ng-vehicle-transfer:exportResult', function(success)
    if success then
        lib.notify({
            title = '成功',
            description = Config.Messages.export_success,
            type = 'success'
        })
    else
        lib.notify({
            title = 'エラー',
            description = Config.Messages.export_failed,
            type = 'error'
        })
    end
end)