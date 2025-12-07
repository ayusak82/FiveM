local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local isLoggedIn = false
local currentStation = nil
local craftingZones = {}
local nearbyStation = nil

-- プレイヤー情報の初期化
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    isLoggedIn = true
    Debug("Player logged in via OnPlayerLoaded event")
    CreateCraftingZones()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
    PlayerData = {}
    RemoveCraftingZones()
    Debug("Player logged out")
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
    if not isLoggedIn and PlayerData.citizenid then
        isLoggedIn = true
        Debug("Player logged in via SetPlayerData event")
        CreateCraftingZones()
    end
end)

-- デバッグ用関数
local function Debug(msg)
    if Config.Debug then
        print("[ng-craft] " .. msg)
    end
end

-- プレイヤーのログイン状態を強制チェック
local function ForceCheckPlayerLogin()
    if QBCore and QBCore.Functions then
        local playerData = QBCore.Functions.GetPlayerData()
        if playerData and playerData.citizenid then
            PlayerData = playerData
            if not isLoggedIn then
                isLoggedIn = true
                Debug("Player login detected via force check - CitizenID: " .. playerData.citizenid)
                CreateCraftingZones()
            end
            return true
        end
    end
    return false
end

-- 3Dマーカーの描画
local function DrawMarker3D(coords, size, color)
    DrawMarker(
        1, -- マーカータイプ (円柱)
        coords.x, coords.y, coords.z - 1.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        size, size, 1.0,
        color.r, color.g, color.b, color.a,
        false, true, 2,
        false, nil, nil, false
    )
    
    -- 上部の光る円
    DrawMarker(
        25, -- 光るリング
        coords.x, coords.y, coords.z + 0.5,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        size * 0.8, size * 0.8, size * 0.8,
        color.r, color.g, color.b, 150,
        false, true, 2,
        false, nil, nil, false
    )
end

-- 3Dテキストの描画
local function DrawText3D(coords, text, scale)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z + 1.0)
    local pX, pY, pZ = table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(pX, pY, pZ, coords.x, coords.y, coords.z, 1)
    
    if onScreen and dist < 15.0 then
        local scale = (1 / dist) * 2
        local fov = (1 / GetGameplayCamFov()) * 100
        local scaleMultiplier = scale * fov * (scale or 0.35)
        
        SetTextScale(0.0, scaleMultiplier)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        
        -- 背景
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 150)
    end
end

-- クラフト台のゾーン作成
function CreateCraftingZones()
    for i, station in ipairs(Config.CraftingStations) do
        Debug("Creating crafting zone: " .. station.name .. " at " .. tostring(station.coords))
    end
    Debug("All crafting zones created successfully")
end

-- クラフト台のゾーン削除
function RemoveCraftingZones()
    craftingZones = {}
end

-- メインループ（マーカー表示とインタラクション）
CreateThread(function()
    while true do
        local sleep = 1000
        
        if isLoggedIn then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            nearbyStation = nil
            
            for _, station in ipairs(Config.CraftingStations) do
                local distance = #(playerCoords - station.coords)
                
                if distance < 15.0 then
                    sleep = 0
                    
                    -- マーカーを描画
                    DrawMarker3D(station.coords, 2.0, {r = 79, g = 195, b = 247, a = 200})
                    
                    if distance < 3.0 then
                        nearbyStation = station
                        
                        -- 3Dテキストを表示
                        DrawText3D(station.coords, "[E] " .. station.label, 0.35)
                        
                        -- Eキーでメニューを開く
                        if IsControlJustPressed(0, 38) then -- E key
                            OpenCraftingMenu(station)
                        end
                    end
                end
            end
        else
            -- ログインしていない場合は強制チェック
            if ForceCheckPlayerLogin() then
                CreateCraftingZones()
            end
            sleep = 2000
        end
        
        Wait(sleep)
    end
end)

-- 初期化確認用（複数の方法でログインを検知）
CreateThread(function()
    Wait(1000)
    
    -- 最初にQBCoreの存在を確認
    if not QBCore then
        Debug("ERROR: QBCore not found!")
        return
    end
    
    Debug("QBCore found, checking player login status...")
    
    -- 一回だけログイン状態をチェック
    local attempts = 0
    while not isLoggedIn and attempts < 10 do
        attempts = attempts + 1
        
        if ForceCheckPlayerLogin() then
            break
        end
        
        Debug("Login check attempt " .. attempts .. "/10")
        Wait(2000)
    end
    
    if not isLoggedIn then
        Debug("WARNING: Could not detect player login after 10 attempts")
    end
end)

-- クラフトメニューを開く
function OpenCraftingMenu(station)
    if not isLoggedIn then return end
    
    -- プレイヤーレベルチェック
    QBCore.Functions.TriggerCallback('ng-craft:server:GetPlayerLevel', function(level)
        if level < station.requiredLevel then
            lib.notify({
                title = 'アクセス拒否',
                description = string.format('このクラフト台を使用するにはレベル %d が必要です', station.requiredLevel),
                type = 'error'
            })
            return
        end
        
        -- レシピデータを取得
        local availableRecipes = {}
        for _, category in ipairs(station.categories) do
            if Config.Recipes[category] then
                for _, recipe in ipairs(Config.Recipes[category]) do
                    if level >= recipe.requiredLevel then
                        table.insert(availableRecipes, recipe)
                    end
                end
            end
        end
        
        -- UIデータを準備
        local uiData = {
            station = station,
            recipes = availableRecipes,
            playerLevel = level
        }
        
        -- プレイヤーの所持アイテム情報を取得
        QBCore.Functions.TriggerCallback('ng-craft:server:GetPlayerItems', function(items)
            uiData.playerItems = items
            
            -- 現在のクラフト状況を取得
            QBCore.Functions.TriggerCallback('ng-craft:server:GetActiveCrafts', function(activeCrafts)
                uiData.activeCrafts = activeCrafts
                
                -- UIを開く
                TriggerEvent('ng-craft:client:OpenUI', uiData)
            end)
        end)
    end)
end

-- コマンド登録（デバッグ用）
RegisterCommand('craftdebug', function()
    Debug("=== NG-CRAFT DEBUG INFO ===")
    Debug("QBCore exists: " .. tostring(QBCore ~= nil))
    Debug("Player logged in: " .. tostring(isLoggedIn))
    Debug("PlayerData exists: " .. tostring(PlayerData ~= nil))
    if PlayerData and PlayerData.citizenid then
        Debug("CitizenID: " .. PlayerData.citizenid)
    end
    Debug("Nearby station: " .. tostring(nearbyStation and nearbyStation.name or "none"))
    Debug("Total stations configured: " .. #Config.CraftingStations)
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    Debug("Player coords: " .. tostring(playerCoords))
    
    for i, station in ipairs(Config.CraftingStations) do
        local distance = #(playerCoords - station.coords)
        Debug("Station " .. station.name .. " distance: " .. string.format("%.2f", distance))
    end
end)

RegisterCommand('craftlogin', function()
    Debug("Force attempting login check...")
    if ForceCheckPlayerLogin() then
        CreateCraftingZones()
        Debug("Login successful!")
    else
        Debug("Login failed!")
    end
end)

if Config.Debug then
    RegisterCommand('craft', function()
        if nearbyStation then
            OpenCraftingMenu(nearbyStation)
        else
            lib.notify({
                title = 'エラー',
                description = 'クラフト台の近くにいる必要があります',
                type = 'error'
            })
        end
    end)
end

-- サーバーからの通知イベント
RegisterNetEvent('ng-craft:client:Notify', function(data)
    lib.notify({
        title = data.title or 'クラフト',
        description = data.message,
        type = data.type or 'inform'
    })
end)

-- レベルアップ通知
RegisterNetEvent('ng-craft:client:LevelUp', function(newLevel)
    lib.notify({
        title = 'レベルアップ！',
        description = string.format('現在のレベル: %d', newLevel),
        type = 'success',
        duration = 5000
    })
    
    -- エフェクト表示（オプション）
    if lib.requestAnimDict then
        lib.requestAnimDict('anim@mp_player_intcelebrationfemale@thumbs_up')
        TaskPlayAnim(PlayerPedId(), 'anim@mp_player_intcelebrationfemale@thumbs_up', 'thumbs_up', 8.0, 8.0, 2000, 0, 0, false, false, false)
    end
end)

-- 経験値獲得通知
RegisterNetEvent('ng-craft:client:XPGained', function(xp, totalXP, level)
    lib.notify({
        title = 'XP獲得',
        description = string.format('+%d XP (合計: %d / レベル: %d)', xp, totalXP, level),
        type = 'success',
        duration = 3000
    })
end)

-- クラフト完了通知
RegisterNetEvent('ng-craft:client:CraftCompleted', function(recipe, success)
    if success then
        lib.notify({
            title = 'クラフト完了',
            description = recipe.label .. ' を作成しました！',
            type = 'success'
        })
        
        -- 成功音（オプション）
        PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    else
        lib.notify({
            title = 'クラフト失敗',
            description = recipe.label .. ' の作成に失敗しました',
            type = 'error'
        })
        
        -- 失敗音（オプション）
        PlaySoundFrontend(-1, "CANCEL", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
end)

-- クラフト開始
RegisterNetEvent('ng-craft:client:StartCraft', function(recipe, quantity)
    -- サーバーにクラフト開始を送信
    TriggerServerEvent('ng-craft:server:StartCraft', recipe, quantity)
end)

-- クラフトキャンセル
RegisterNetEvent('ng-craft:client:CancelCraft', function(craftId)
    -- サーバーにキャンセル通知
    TriggerServerEvent('ng-craft:server:CancelCraft', craftId)
end)

-- 初期化（リソース開始時）
CreateThread(function()
    if isLoggedIn then
        CreateCraftingZones()
    end
end)

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        RemoveCraftingZones()
    end
end)

-- クラフトメニューを開く
function OpenCraftingMenu(station)
    if not isLoggedIn then return end
    
    -- プレイヤーレベルチェック
    QBCore.Functions.TriggerCallback('ng-craft:server:GetPlayerLevel', function(level)
        if level < station.requiredLevel then
            lib.notify({
                title = 'アクセス拒否',
                description = string.format('このクラフト台を使用するにはレベル %d が必要です', station.requiredLevel),
                type = 'error'
            })
            return
        end
        
        -- レシピデータを取得
        local availableRecipes = {}
        for _, category in ipairs(station.categories) do
            if Config.Recipes[category] then
                for _, recipe in ipairs(Config.Recipes[category]) do
                    if level >= recipe.requiredLevel then
                        table.insert(availableRecipes, recipe)
                    end
                end
            end
        end
        
        -- UIデータを準備
        local uiData = {
            station = station,
            recipes = availableRecipes,
            playerLevel = level
        }
        
        -- プレイヤーの所持アイテム情報を取得
        QBCore.Functions.TriggerCallback('ng-craft:server:GetPlayerItems', function(items)
            uiData.playerItems = items
            
            -- 現在のクラフト状況を取得
            QBCore.Functions.TriggerCallback('ng-craft:server:GetActiveCrafts', function(activeCrafts)
                uiData.activeCrafts = activeCrafts
                
                -- UIを開く
                TriggerEvent('ng-craft:client:OpenUI', uiData)
            end)
        end)
    end)
end

-- コマンド登録（デバッグ用）
if Config.Debug then
    RegisterCommand('craft', function()
        if currentStation then
            OpenCraftingMenu(currentStation)
        else
            lib.notify({
                title = 'エラー',
                description = 'クラフト台の近くにいる必要があります',
                type = 'error'
            })
        end
    end)
end

-- サーバーからの通知イベント
RegisterNetEvent('ng-craft:client:Notify', function(data)
    lib.notify({
        title = data.title or 'クラフト',
        description = data.message,
        type = data.type or 'inform'
    })
end)

-- レベルアップ通知
RegisterNetEvent('ng-craft:client:LevelUp', function(newLevel)
    lib.notify({
        title = 'レベルアップ！',
        description = string.format('現在のレベル: %d', newLevel),
        type = 'success',
        duration = 5000
    })
    
    -- エフェクト表示（オプション）
    if lib.requestAnimDict then
        lib.requestAnimDict('anim@mp_player_intcelebrationfemale@thumbs_up')
        TaskPlayAnim(PlayerPedId(), 'anim@mp_player_intcelebrationfemale@thumbs_up', 'thumbs_up', 8.0, 8.0, 2000, 0, 0, false, false, false)
    end
end)

-- 経験値獲得通知
RegisterNetEvent('ng-craft:client:XPGained', function(xp, totalXP, level)
    lib.notify({
        title = 'XP獲得',
        description = string.format('+%d XP (合計: %d / レベル: %d)', xp, totalXP, level),
        type = 'success',
        duration = 3000
    })
end)

-- クラフト完了通知
RegisterNetEvent('ng-craft:client:CraftCompleted', function(recipe, success)
    if success then
        lib.notify({
            title = 'クラフト完了',
            description = recipe.label .. ' を作成しました！',
            type = 'success'
        })
        
        -- 成功音（オプション）
        PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    else
        lib.notify({
            title = 'クラフト失敗',
            description = recipe.label .. ' の作成に失敗しました',
            type = 'error'
        })
        
        -- 失敗音（オプション）
        PlaySoundFrontend(-1, "CANCEL", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
end)

-- クラフト開始
RegisterNetEvent('ng-craft:client:StartCraft', function(recipe, quantity)
    -- サーバーにクラフト開始を送信
    TriggerServerEvent('ng-craft:server:StartCraft', recipe, quantity)
end)

-- クラフトキャンセル
RegisterNetEvent('ng-craft:client:CancelCraft', function(craftId)
    -- サーバーにキャンセル通知
    TriggerServerEvent('ng-craft:server:CancelCraft', craftId)
end)

-- 初期化（リソース開始時）
CreateThread(function()
    if isLoggedIn then
        CreateCraftingZones()
    end
end)

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        RemoveCraftingZones()
        lib.hideTextUI()
    end
end)