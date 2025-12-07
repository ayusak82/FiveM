local QBCore = exports['qb-core']:GetCoreObject()
local isProcessing = false

-- デバッグ出力関数
local function DebugPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^3[DEBUG]^7 ' .. message)
end

-- 3Dテキスト描画関数
local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = #(vector3(px, py, pz) - vector3(x, y, z))
    
    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov
    
    if onScreen then
        SetTextScale(0.0 * scale, 0.55 * scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- プレイヤーが持っているリサイクル可能なアイテムを取得
local function GetRecyclableItems()
    local items = {}
    
    -- ox_inventoryからアイテムを取得
    for itemName, price in pairs(Config.RecycleItems) do
        local itemCount = exports.ox_inventory:GetItemCount(itemName)
        
        if itemCount and itemCount > 0 then
            -- アイテムデータを取得
            local itemData = exports.ox_inventory:Items(itemName)
            local itemLabel = itemData and itemData.label or itemName
            
            table.insert(items, {
                name = itemName,
                label = itemLabel,
                count = itemCount,
                price = price
            })
            DebugPrint('Found recyclable item:', itemName, 'x', itemCount)
        end
    end
    
    return items
end

-- リサイクルメニューを開く
local function OpenRecycleMenu()
    if isProcessing then return end
    
    local recyclableItems = GetRecyclableItems()
    
    if #recyclableItems == 0 then
        exports['okokNotify']:Alert('リサイクルセンター', Config.Messages.noItems, 5000, 'warning', false)
        return
    end
    
    local options = {}
    
    for _, item in ipairs(recyclableItems) do
        local totalPrice = item.price * item.count
        table.insert(options, {
            title = item.label,
            description = string.format('所持数: %d | 単価: $%d | 合計: $%d', item.count, item.price, totalPrice),
            icon = 'recycle',
            onSelect = function()
                OpenSellMenu(item)
            end
        })
    end
    
    lib.registerContext({
        id = 'recycle_main_menu',
        title = 'リサイクルセンター',
        options = options
    })
    
    lib.showContext('recycle_main_menu')
    DebugPrint('Opened recycle menu with', #recyclableItems, 'items')
end

-- 売却数量選択メニュー
function OpenSellMenu(item)
    local input = lib.inputDialog('売却数量', {
        {
            type = 'number',
            label = '数量',
            description = string.format('最大: %d | 単価: $%d', item.count, item.price),
            required = true,
            min = 1,
            max = item.count
        }
    })
    
    if not input then
        DebugPrint('Sell cancelled by player')
        return
    end
    
    local amount = tonumber(input[1])
    
    if not amount or amount < 1 or amount > item.count then
        exports['okokNotify']:Alert('エラー', '無効な数量です', 5000, 'error', false)
        return
    end
    
    -- 売却処理
    SellItem(item.name, amount, item.price)
end

-- アイテムを売却
function SellItem(itemName, amount, price)
    if isProcessing then return end
    isProcessing = true
    
    DebugPrint('Selling item:', itemName, 'amount:', amount, 'price:', price)
    
    -- アニメーション再生
    local playerPed = PlayerPedId()
    RequestAnimDict(Config.Animation.dict)
    while not HasAnimDictLoaded(Config.Animation.dict) do
        Wait(10)
    end
    
    TaskPlayAnim(playerPed, Config.Animation.dict, Config.Animation.anim, 8.0, -8.0, Config.Animation.duration, 0, 0, false, false, false)
    
    -- 処理中通知
    exports['okokNotify']:Alert('リサイクルセンター', Config.Messages.processing, Config.Animation.duration, 'info', false)
    
    Wait(Config.Animation.duration)
    
    -- サーバーに売却リクエスト
    QBCore.Functions.TriggerCallback('ng-recyclebuy:server:sellItem', function(success, message)
        isProcessing = false
        
        if success then
            local totalPrice = price * amount
            exports['okokNotify']:Alert('成功', string.format('%s x%d を $%d で売却しました', message, amount, totalPrice), 5000, 'success', true)
            DebugPrint('Sell successful:', itemName, 'x', amount)
        else
            exports['okokNotify']:Alert('エラー', message or '売却に失敗しました', 5000, 'error', true)
            DebugPrint('Sell failed:', message)
        end
    end, itemName, amount, price)
end

-- NPCとのインタラクション（ox_targetを使用しない場合）
CreateThread(function()
    -- ox_targetが有効な場合は3秒待ってから判定
    if Config.Interaction.useTarget then
        Wait(3000)
    end
    
    -- useTargetがfalseの場合、またはox_targetの初期化に失敗した場合に実行
    if not Config.Interaction.useTarget then
        DebugPrint('Using key-based interaction (ox_target disabled or unavailable)')
        
        while true do
            local sleep = 1000
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            for _, location in ipairs(Config.RecycleLocations) do
                local distance = #(playerCoords - vector3(location.coords.x, location.coords.y, location.coords.z))
                
                if distance < Config.Interaction.distance then
                    sleep = 0
                    
                    -- Draw text on screen instead of constant notifications
                    DrawText3D(location.coords.x, location.coords.y, location.coords.z + 1.0, Config.Messages.interact)
                    
                    -- Eキーが押されたらメニューを開く
                    if IsControlJustPressed(0, Config.Interaction.key) then
                        OpenRecycleMenu()
                    end
                end
            end
            
            Wait(sleep)
        end
    end
end)

-- ox_targetを使用する場合
if Config.Interaction.useTarget then
    CreateThread(function()
        -- ox_targetの存在確認
        local oxTargetExists = GetResourceState('ox_target') == 'started'
        
        if not oxTargetExists then
            print('^1[ng-recyclebuy ERROR]^7 ox_target is not running! Falling back to key interaction.')
            print('^3[ng-recyclebuy WARN]^7 Please install ox_target or set Config.Interaction.useTarget to false')
            Config.Interaction.useTarget = false
            return
        end
        
        -- NPCのスポーンを待機（最大10秒）
        local maxAttempts = 20
        local attempts = 0
        local spawnedPeds = nil
        
        while attempts < maxAttempts do
            Wait(500)
            spawnedPeds = exports['ng-recyclebuy']:GetSpawnedPeds()
            
            if spawnedPeds and #spawnedPeds > 0 then
                DebugPrint('Found', #spawnedPeds, 'spawned peds after', attempts * 500, 'ms')
                break
            end
            
            attempts = attempts + 1
            DebugPrint('Waiting for NPCs to spawn... attempt', attempts)
        end
        
        if not spawnedPeds or #spawnedPeds == 0 then
            print('^1[ng-recyclebuy ERROR]^7 Failed to find spawned NPCs after 10 seconds')
            return
        end
        
        -- ox_targetをPedに追加
        local successCount = 0
        for _, data in ipairs(spawnedPeds) do
            if DoesEntityExist(data.ped) then
                local success, errorMsg = pcall(function()
                    exports.ox_target:addLocalEntity(data.ped, {
                        {
                            name = 'recycle_npc',
                            icon = 'fas fa-recycle',
                            label = 'リサイクルセンター',
                            onSelect = function()
                                OpenRecycleMenu()
                            end
                        }
                    })
                end)
                
                if success then
                    successCount = successCount + 1
                    DebugPrint('Added ox_target to ped:', data.ped)
                else
                    print('^1[ng-recyclebuy ERROR]^7 Failed to add ox_target:', errorMsg)
                end
            else
                print('^3[ng-recyclebuy WARN]^7 Ped does not exist:', data.ped)
            end
        end
        
        if successCount > 0 then
            print('^2[ng-recyclebuy]^7 Successfully added ox_target to', successCount, 'NPCs')
        else
            print('^1[ng-recyclebuy ERROR]^7 Failed to add ox_target to any NPCs')
        end
    end)
end
