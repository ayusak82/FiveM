local QBCore = exports['qb-core']:GetCoreObject()
local spawnedCarts = {} -- プレイヤーがスポーンしたカート
local cartCount = 0 -- 現在のカート数
local isRiding = false -- カートに乗っているか
local currentCart = nil -- 現在乗っているカート

-- カートモデルをロード
local function LoadModel(model)
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    if not HasModelLoaded(modelHash) then
        print("^1[ERROR] Failed to load model: " .. model .. "^7")
        return nil
    end
    
    return modelHash
end

-- アニメーションをロード
local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    if not HasAnimDictLoaded(dict) then
        print("^1[ERROR] Failed to load animation: " .. dict .. "^7")
        return false
    end
    
    return true
end

-- 3Dテキスト描画
local function DrawText3D(x, y, z, text)
    SetTextScale(Config.TextScale, Config.TextScale)
    SetTextFont(Config.TextFont)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- カートをスポーン
local function SpawnCart()
    local playerPed = PlayerPedId()
    
    -- 車両に乗っているかチェック
    if IsPedInAnyVehicle(playerPed, false) then
        lib.notify({
            title = 'ショッピングカート',
            description = Config.Notifications.inVehicle,
            type = 'error'
        })
        return
    end
    
    -- カート数制限チェック
    if cartCount >= Config.MaxCartsPerPlayer then
        lib.notify({
            title = 'ショッピングカート',
            description = Config.Notifications.limit,
            type = 'error'
        })
        return
    end
    
    -- プレイヤーの座標と向きを取得
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)
    local playerForward = GetEntityForwardVector(playerPed)
    
    -- スポーン位置を計算
    local spawnCoords = vector3(
        playerCoords.x + playerForward.x * Config.SpawnDistance,
        playerCoords.y + playerForward.y * Config.SpawnDistance,
        playerCoords.z
    )
    
    -- モデルをロード
    local modelHash = LoadModel(Config.CartModel)
    
    if not modelHash then
        lib.notify({
            title = 'ショッピングカート',
            description = 'カートモデルの読み込みに失敗しました',
            type = 'error'
        })
        return
    end
    
    -- プログレスバー表示
    if lib.progressBar({
        duration = 2000,
        label = 'カートを設置中...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'amb@prop_human_bum_bin@base',
            clip = 'base'
        }
    }) then
        -- カートをスポーン (プロップとして)
        local cart = CreateObject(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, true, true, false)
        
        -- カートの設定
        PlaceObjectOnGroundProperly(cart)
        SetEntityHeading(cart, playerHeading)
        FreezeEntityPosition(cart, false)
        SetEntityAsMissionEntity(cart, true, true)
        
        -- カートをテーブルに追加
        table.insert(spawnedCarts, {
            object = cart,
            coords = GetEntityCoords(cart),
            heading = GetEntityHeading(cart)
        })
        cartCount = cartCount + 1
        
        lib.notify({
            title = 'ショッピングカート',
            description = Config.Notifications.spawned,
            type = 'success'
        })
        
        SetModelAsNoLongerNeeded(modelHash)
    else
        SetModelAsNoLongerNeeded(modelHash)
    end
end

-- カートに乗る
local function RideCart(cartData)
    if isRiding then return end
    
    local playerPed = PlayerPedId()
    
    -- アニメーションをロード
    if not LoadAnimDict(Config.SitAnimation.dict) then
        lib.notify({
            title = 'ショッピングカート',
            description = 'アニメーションの読み込みに失敗しました',
            type = 'error'
        })
        return
    end
    
    isRiding = true
    currentCart = cartData
    
    -- プレイヤーをカートの位置に移動
    local cartCoords = GetEntityCoords(cartData.object)
    local cartHeading = GetEntityHeading(cartData.object)
    
    -- カートのオフセット位置を計算
    local sitCoords = GetOffsetFromEntityInWorldCoords(
        cartData.object,
        Config.SitOffset.x,
        Config.SitOffset.y,
        Config.SitOffset.z
    )
    
    -- プレイヤーをカートにアタッチ（向きを180度回転）
    SetEntityCoords(playerPed, sitCoords.x, sitCoords.y, sitCoords.z, false, false, false, true)
    SetEntityHeading(playerPed, cartHeading + Config.SitOffset.heading)
    
    -- 座るアニメーション再生
    TaskPlayAnim(playerPed, Config.SitAnimation.dict, Config.SitAnimation.anim, 8.0, 8.0, -1, Config.SitAnimation.flag, 0, false, false, false)
    
    -- プレイヤーをカートにアタッチ（向きを180度回転）
    AttachEntityToEntity(
        playerPed,
        cartData.object,
        0,
        Config.SitOffset.x,
        Config.SitOffset.y,
        Config.SitOffset.z,
        0.0, 0.0, Config.SitOffset.heading,
        false, false, false, false, 2, true
    )
    
    lib.notify({
        title = 'ショッピングカート',
        description = Config.Notifications.riding,
        type = 'info'
    })
end

-- カートから降りる
local function GetOffCart()
    if not isRiding or not currentCart then return end
    
    local playerPed = PlayerPedId()
    
    -- プレイヤーをデタッチ
    DetachEntity(playerPed, true, false)
    
    -- アニメーション停止
    ClearPedTasks(playerPed)
    
    -- プレイヤーをカートの横に移動
    local cartCoords = GetEntityCoords(currentCart.object)
    local cartHeading = GetEntityHeading(currentCart.object)
    local offset = GetOffsetFromEntityInWorldCoords(currentCart.object, 1.5, 0.0, 0.0)
    
    SetEntityCoords(playerPed, offset.x, offset.y, offset.z, false, false, false, true)
    
    isRiding = false
    currentCart = nil
    
    lib.notify({
        title = 'ショッピングカート',
        description = Config.Notifications.gotOff,
        type = 'info'
    })
end

-- カートを回収
local function CollectCart()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestCart = nil
    local closestDistance = Config.InteractDistance
    local closestIndex = nil
    
    -- 最も近いカートを検索
    for i, cartData in ipairs(spawnedCarts) do
        if DoesEntityExist(cartData.object) then
            local cartCoords = GetEntityCoords(cartData.object)
            local distance = #(playerCoords - cartCoords)
            
            if distance < closestDistance then
                closestDistance = distance
                closestCart = cartData
                closestIndex = i
            end
        end
    end
    
    -- カートが見つかった場合
    if closestCart and closestIndex then
        -- プログレスバー表示
        if lib.progressBar({
            duration = 2000,
            label = 'カートを回収中...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true
            },
            anim = {
                dict = 'amb@prop_human_bum_bin@base',
                clip = 'base'
            }
        }) then
            -- カートを削除
            DeleteEntity(closestCart.object)
            table.remove(spawnedCarts, closestIndex)
            cartCount = cartCount - 1
            
            lib.notify({
                title = 'ショッピングカート',
                description = Config.Notifications.collected,
                type = 'success'
            })
        end
    else
        lib.notify({
            title = 'ショッピングカート',
            description = Config.Notifications.noCart,
            type = 'error'
        })
    end
end

-- カートの移動処理
CreateThread(function()
    while true do
        local sleep = 100
        
        if isRiding and currentCart and DoesEntityExist(currentCart.object) then
            sleep = 0
            
            local cart = currentCart.object
            local cartCoords = GetEntityCoords(cart)
            local cartHeading = GetEntityHeading(cart)
            local cartForward = GetEntityForwardVector(cart)
            
            local newCoords = cartCoords
            local newHeading = cartHeading
            
            -- 前進 (Wキー) - 逆向きなのでマイナス方向に移動
            if IsControlPressed(0, Config.MoveForwardKey) then
                newCoords = vector3(
                    cartCoords.x - cartForward.x * Config.CartMoveSpeed * GetFrameTime(),
                    cartCoords.y - cartForward.y * Config.CartMoveSpeed * GetFrameTime(),
                    cartCoords.z
                )
            end
            
            -- 後退 (Sキー) - 逆向きなのでプラス方向に移動
            if IsControlPressed(0, Config.MoveBackwardKey) then
                newCoords = vector3(
                    cartCoords.x + cartForward.x * Config.CartMoveSpeed * GetFrameTime(),
                    cartCoords.y + cartForward.y * Config.CartMoveSpeed * GetFrameTime(),
                    cartCoords.z
                )
            end
            
            -- 左折
            if IsControlPressed(0, Config.TurnLeftKey) then
                newHeading = cartHeading + (Config.CartTurnSpeed * GetFrameTime() * 50)
            end
            
            -- 右折
            if IsControlPressed(0, Config.TurnRightKey) then
                newHeading = cartHeading - (Config.CartTurnSpeed * GetFrameTime() * 50)
            end
            
            -- カートの位置と向きを更新
            SetEntityCoords(cart, newCoords.x, newCoords.y, newCoords.z, false, false, false, true)
            SetEntityHeading(cart, newHeading)
            PlaceObjectOnGroundProperly(cart)
        end
        
        Wait(sleep)
    end
end)

-- 3Dテキスト表示スレッド
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        if not isRiding then
            for _, cartData in ipairs(spawnedCarts) do
                if DoesEntityExist(cartData.object) then
                    local cartCoords = GetEntityCoords(cartData.object)
                    local distance = #(playerCoords - cartCoords)
                    
                    if distance < Config.DrawDistance then
                        sleep = 0
                        
                        if distance < Config.InteractDistance and not IsPedInAnyVehicle(playerPed, false) then
                            DrawText3D(cartCoords.x, cartCoords.y, cartCoords.z + 1.0, '[E] 乗る | [G] 回収')
                        end
                    end
                end
            end
        else
            -- 乗っている時の表示
            sleep = 0
            if currentCart and DoesEntityExist(currentCart.object) then
                local cartCoords = GetEntityCoords(currentCart.object)
                DrawText3D(cartCoords.x, cartCoords.y, cartCoords.z + 1.5, '[E] 降りる | [W/A/S/D] 移動')
            end
        end
        
        Wait(sleep)
    end
end)

-- キー入力監視
CreateThread(function()
    while true do
        Wait(0)
        
        -- Eキー (乗る/降りる)
        if IsControlJustReleased(0, Config.RideKey) then
            local playerPed = PlayerPedId()
            
            if isRiding then
                -- 乗っている場合は降りる
                GetOffCart()
            elseif not IsPedInAnyVehicle(playerPed, false) then
                -- 乗っていない場合は最寄りのカートに乗る
                local playerCoords = GetEntityCoords(playerPed)
                
                for _, cartData in ipairs(spawnedCarts) do
                    if DoesEntityExist(cartData.object) then
                        local cartCoords = GetEntityCoords(cartData.object)
                        local distance = #(playerCoords - cartCoords)
                        
                        if distance < Config.InteractDistance then
                            RideCart(cartData)
                            break
                        end
                    end
                end
            end
        end
        
        -- Gキー (回収) - 乗っていない時のみ
        if not isRiding and IsControlJustReleased(0, Config.CollectKey) then
            local playerPed = PlayerPedId()
            
            if not IsPedInAnyVehicle(playerPed, false) then
                CollectCart()
            end
        end
    end
end)

-- コマンド登録
RegisterCommand(Config.Command, function()
    SpawnCart()
end, false)

-- リソース停止時の処理
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- カートに乗っている場合は降りる
        if isRiding then
            GetOffCart()
        end
        
        -- すべてのカートを削除
        for _, cartData in ipairs(spawnedCarts) do
            if DoesEntityExist(cartData.object) then
                DeleteEntity(cartData.object)
            end
        end
    end
end)
