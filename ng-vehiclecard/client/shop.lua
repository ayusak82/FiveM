local QBCore = exports['qb-core']:GetCoreObject()

-- ============================================
-- グローバル変数
-- ============================================

local inShopZone = false
local currentShop = nil

-- ============================================
-- ショップメニュー
-- ============================================

local function openShopMenu(shop)
    local options = {}
    
    for _, category in ipairs(Config.ShopVehicles) do
        local categoryOptions = {}
        
        for _, vehicle in ipairs(category.vehicles) do
            table.insert(categoryOptions, {
                title = vehicle.label,
                description = string.format('%s | %s | 使用回数: %d回', 
                    Locale.shop_price:format(vehicle.price),
                    vehicle.model,
                    vehicle.uses
                ),
                icon = 'car',
                onSelect = function()
                    -- 購入確認ダイアログ
                    local alert = lib.alertDialog({
                        header = vehicle.label .. ' を購入しますか？',
                        content = string.format('価格: $%s\n使用回数: %d回\n\nこの車両カードを購入しますか？', 
                            vehicle.price, vehicle.uses),
                        centered = true,
                        cancel = true,
                        labels = {
                            confirm = '購入',
                            cancel = 'キャンセル'
                        }
                    })
                    
                    if alert == 'confirm' then
                        -- サーバー側で購入処理
                        local success, message = lib.callback.await('ng-vehiclecard:server:buyVehicleCard', false, vehicle)
                        
                        if success then
                            lib.notify({
                                title = '購入完了',
                                description = Locale[message] or Locale.shop_success,
                                type = 'success'
                            })
                        else
                            lib.notify({
                                title = 'エラー',
                                description = Locale[message] or Locale.error_general,
                                type = 'error'
                            })
                        end
                    end
                end
            })
        end
        
        table.insert(options, {
            title = category.category,
            icon = 'list',
            iconColor = '#3b82f6',
            menu = 'vehicle_category_' .. category.category,
        })
        
        -- カテゴリーごとのサブメニューを登録
        lib.registerContext({
            id = 'vehicle_category_' .. category.category,
            title = category.category,
            menu = 'vehicle_shop_main',
            options = categoryOptions
        })
    end
    
    -- メインメニューを登録
    lib.registerContext({
        id = 'vehicle_shop_main',
        title = Locale.shop_title,
        options = options
    })
    
    -- メニューを表示
    lib.showContext('vehicle_shop_main')
end

-- ============================================
-- ショップゾーン管理
-- ============================================

CreateThread(function()
    -- ブリップを作成
    for i, shop in ipairs(Config.Shops) do
        if shop.blip.enabled then
            local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
            SetBlipSprite(blip, shop.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, shop.blip.scale)
            SetBlipColour(blip, shop.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(shop.blip.name)
            EndTextCommandSetBlipName(blip)
        end
    end
    
    -- ショップゾーンのチェック
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        for i, shop in ipairs(Config.Shops) do
            local distance = #(playerCoords - shop.coords)
            
            -- マーカー表示範囲内
            if distance < shop.marker.distance then
                sleep = 0
                
                -- マーカーを描画
                DrawMarker(
                    shop.marker.type,
                    shop.coords.x, shop.coords.y, shop.coords.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    shop.marker.size.x, shop.marker.size.y, shop.marker.size.z,
                    shop.marker.color.r, shop.marker.color.g, shop.marker.color.b, shop.marker.color.a,
                    false, true, 2, false, nil, nil, false
                )
                
                -- インタラクション範囲内
                if distance < shop.interactDistance then
                    if not inShopZone then
                        inShopZone = true
                        currentShop = shop
                        
                        -- DrawText表示
                        lib.showTextUI(Locale.shop_marker, {
                            position = "left-center",
                            icon = 'car',
                            style = {
                                borderRadius = 5,
                                backgroundColor = '#1e293b',
                                color = 'white'
                            }
                        })
                    end
                    
                    -- Eキーでメニューを開く
                    if IsControlJustReleased(0, 38) then -- E key
                        openShopMenu(shop)
                    end
                else
                    if inShopZone and currentShop == shop then
                        inShopZone = false
                        currentShop = nil
                        lib.hideTextUI()
                    end
                end
            else
                if inShopZone and currentShop == shop then
                    inShopZone = false
                    currentShop = nil
                    lib.hideTextUI()
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- ============================================
-- リソース停止時のクリーンアップ
-- ============================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if inShopZone then
        lib.hideTextUI()
    end
end)

print('^2[ng-vehiclecard]^7 Shop script loaded successfully')
