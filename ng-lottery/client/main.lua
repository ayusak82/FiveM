local QBCore = exports['qb-core']:GetCoreObject()
local isUIOpen = false

-- NUI Callbacks
RegisterNUICallback('startLottery', function(data, cb)
    if isUIOpen then
        -- アニメーション開始
        PlayLotteryAnimation()
        
        -- サーバーに宝くじ結果をリクエスト
        QBCore.Functions.TriggerCallback('ng-lottery:server:playLottery', function(result)
            if result.success then
                -- 結果をUIに送信
                SendNUIMessage({
                    action = 'showResult',
                    amount = result.amount,
                    hasMoreTickets = result.hasMoreTickets,
                    ticketCount = result.ticketCount
                })
                
                if Config.Debug then
                    print(string.format('^2[ng-lottery] Won: $%d (Tickets remaining: %d)^0', result.amount, result.ticketCount))
                end
            else
                -- エラー通知
                lib.notify({
                    title = '宝くじ',
                    description = result.message or 'エラーが発生しました',
                    type = 'error'
                })
                CloseUI()
            end
        end)
    end
    cb('ok')
end)

RegisterNUICallback('continueDrawing', function(data, cb)
    -- 続けて引く処理
    if isUIOpen then
        -- UIをリセット
        SendNUIMessage({
            action = 'resetForContinue'
        })
        
        if Config.Debug then
            print('^3[ng-lottery] Continue drawing^0')
        end
    end
    cb('ok')
end)

RegisterNUICallback('closeUI', function(data, cb)
    CloseUI()
    cb('ok')
end)

-- アニメーション再生
function PlayLotteryAnimation()
    local playerPed = PlayerPedId()
    
    lib.requestAnimDict(Config.Animation.dict)
    
    TaskPlayAnim(playerPed, Config.Animation.dict, Config.Animation.anim, 8.0, -8.0, Config.Animation.duration, 0, 0, false, false, false)
    
    if Config.Debug then
        print('^3[ng-lottery] Playing animation^0')
    end
end

-- UI表示
function OpenUI()
    if not isUIOpen then
        isUIOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'open'
        })
        
        if Config.Debug then
            print('^2[ng-lottery] UI Opened^0')
        end
    end
end

-- UI非表示
function CloseUI()
    if isUIOpen then
        isUIOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({
            action = 'close'
        })
        
        if Config.Debug then
            print('^1[ng-lottery] UI Closed^0')
        end
    end
end

-- アイテム使用イベント
RegisterNetEvent('ng-lottery:client:useLotteryItem', function()
    OpenUI()
end)

-- リソース停止時の処理
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CloseUI()
    end
end)