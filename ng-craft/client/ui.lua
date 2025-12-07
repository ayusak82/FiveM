local QBCore = exports['qb-core']:GetCoreObject()
local isUIOpen = false
local currentUIData = {}

-- デバッグ用関数
local function Debug(msg)
    if Config.Debug then
        print("[ng-craft UI] " .. msg)
    end
end

-- UIを開くイベント
RegisterNetEvent('ng-craft:client:OpenUI', function(data)
    if isUIOpen then 
        Debug("UI already open, ignoring new request")
        return 
    end
    
    currentUIData = data
    isUIOpen = true
    
    -- カーソルとNUIフォーカスを有効化
    SetNuiFocus(true, true)
    
    -- UIにデータを送信
    SendNUIMessage({
        action = 'openUI',
        data = data
    })
    
    Debug("UI opened with data: " .. json.encode(data))
end)

-- UIを閉じる
local function CloseUI()
    if not isUIOpen then return end
    
    isUIOpen = false
    currentUIData = {}
    
    -- カーソルとNUIフォーカスを無効化
    SetNuiFocus(false, false)
    
    -- UIを閉じる
    SendNUIMessage({
        action = 'closeUI'
    })
    
    Debug("UI closed")
end

-- NUIコールバック：UIを閉じる
RegisterNUICallback('closeUI', function(data, cb)
    CloseUI()
    cb('ok')
end)

-- NUIコールバック：クラフト開始
RegisterNUICallback('startCraft', function(data, cb)
    local recipe = data.recipe
    local quantity = data.quantity or 1
    
    Debug("Starting craft: " .. recipe.name .. " x" .. quantity)
    
    -- サーバーにクラフト開始を通知
    TriggerServerEvent('ng-craft:server:StartCraft', recipe, quantity)
    
    cb('ok')
end)

-- NUIコールバック：クラフトキャンセル
RegisterNUICallback('cancelCraft', function(data, cb)
    local craftId = data.craftId
    
    Debug("Canceling craft: " .. craftId)
    
    -- サーバーにキャンセル通知
    TriggerServerEvent('ng-craft:server:CancelCraft', craftId)
    
    cb('ok')
end)

-- NUIコールバック：レシピ詳細取得
RegisterNUICallback('getRecipeDetails', function(data, cb)
    local recipeName = data.recipeName
    
    Debug("Getting recipe details for: " .. recipeName)
    
    -- サーバーからレシピ詳細を取得
    QBCore.Functions.TriggerCallback('ng-craft:server:GetRecipeDetails', function(result)
        cb(result)
    end, recipeName)
end)

-- NUIコールバック：アクティブクラフト更新
RegisterNUICallback('updateActiveCrafts', function(data, cb)
    if not isUIOpen then 
        cb({error = 'UI not open'})
        return 
    end
    
    QBCore.Functions.TriggerCallback('ng-craft:server:GetActiveCrafts', function(activeCrafts)
        cb({activeCrafts = activeCrafts})
    end)
end)

-- NUIコールバック：プレイヤー情報更新
RegisterNUICallback('updatePlayerInfo', function(data, cb)
    if not isUIOpen then 
        cb({error = 'UI not open'})
        return 
    end
    
    QBCore.Functions.TriggerCallback('ng-craft:server:GetPlayerLevel', function(level)
        QBCore.Functions.TriggerCallback('ng-craft:server:GetPlayerXP', function(xp, totalXP, nextLevelXP)
            cb({
                level = level,
                xp = xp,
                totalXP = totalXP,
                nextLevelXP = nextLevelXP
            })
        end)
    end)
end)

-- クラフト進行状況の更新
RegisterNetEvent('ng-craft:client:UpdateCraftProgress', function(craftId, progress)
    if isUIOpen then
        SendNUIMessage({
            action = 'updateProgress',
            data = {
                craftId = craftId,
                progress = progress
            }
        })
    end
end)

-- アクティブクラフト情報の更新
RegisterNetEvent('ng-craft:client:UpdateActiveCrafts', function(activeCrafts)
    if isUIOpen then
        SendNUIMessage({
            action = 'updateActiveCrafts',
            data = {
                activeCrafts = activeCrafts
            }
        })
    end
end)

-- プレイヤー情報の更新（レベル、XP）
RegisterNetEvent('ng-craft:client:UpdatePlayerInfo', function(level, xp, totalXP, nextLevelXP)
    if isUIOpen then
        SendNUIMessage({
            action = 'updatePlayerInfo',
            data = {
                level = level,
                xp = xp,
                totalXP = totalXP,
                nextLevelXP = nextLevelXP
            }
        })
    end
end)

-- 所持アイテム情報の更新
RegisterNetEvent('ng-craft:client:UpdatePlayerItems', function(items)
    if isUIOpen then
        SendNUIMessage({
            action = 'updatePlayerItems',
            data = {
                playerItems = items
            }
        })
    end
end)

-- ESCキーでUIを閉じる
CreateThread(function()
    while true do
        Wait(0)
        if isUIOpen then
            if IsControlJustPressed(0, 322) then -- ESC key
                CloseUI()
            end
        else
            Wait(500)
        end
    end
end)

-- UI状態のゲッター
function IsUIOpen()
    return isUIOpen
end

-- 現在のUIデータのゲッター
function GetCurrentUIData()
    return currentUIData
end

-- UIデータを更新する関数
function UpdateUIData(newData)
    if isUIOpen then
        currentUIData = newData
        SendNUIMessage({
            action = 'updateData',
            data = newData
        })
    end
end

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isUIOpen then
            CloseUI()
        end
    end
end)