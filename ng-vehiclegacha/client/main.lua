local QBCore = exports['qb-core']:GetCoreObject()
local isGachaActive = false

local function isAdmin()
    return lib.callback.await('ng-vehiclegacha:server:isAdmin', false)
end

local function formatNumber(num)
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- ============================================
-- プレイヤー移動制限
-- ============================================
local function disableControls()
    CreateThread(function()
        while isGachaActive do
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true) -- マウス操作(カメラ)
            EnableControlAction(0, 2, true) -- マウス操作(カメラ)
            EnableControlAction(0, 249, true) -- チャット
            Wait(0)
        end
    end)
end

RegisterNetEvent('ng-vehiclegacha:client:openMenu', function()
    local gachaTypes = lib.callback.await('ng-vehiclegacha:server:getGachaTypes', false)
    
    if not gachaTypes or #gachaTypes == 0 then
        lib.notify({
            type = 'error',
            description = '利用可能なガチャがありません',
            position = Config.Notify.position,
            duration = Config.Notify.duration
        })
        return
    end
    
    local tickets = lib.callback.await('ng-vehiclegacha:server:getPlayerTickets', false)
    local options = {}
    
    for _, gacha in ipairs(gachaTypes) do
        table.insert(options, {
            title = gacha.label,
            description = string.format('💰 $%s | 🎫 %s枚', formatNumber(gacha.price_money), gacha.price_ticket),
            icon = gacha.icon,
            iconColor = gacha.enabled == 1 and '#4CAF50' or '#F44336',
            onSelect = function()
                openGachaCountMenu(gacha)
            end,
            disabled = gacha.enabled == 0
        })
    end
    
    table.insert(options, {
        title = '📜 ガチャ履歴',
        description = '過去のガチャ結果を確認',
        icon = 'fa-solid fa-history',
        onSelect = function()
            openHistoryMenu()
        end
    })
    
    lib.registerContext({
        id = 'vehiclegacha_main',
        title = '🎰 車両ガチャ',
        menu = 'vehiclegacha_main',
        options = options
    })
    
    lib.showContext('vehiclegacha_main')
end)

function openGachaCountMenu(gacha)
    local multiCount = Config.MultiGacha.count
    local discount = Config.MultiGacha.discount
    local multiPriceMoney = math.floor(gacha.price_money * multiCount * (1 - discount))
    local multiPriceTicket = math.floor(gacha.price_ticket * multiCount * (1 - discount))
    
    local options = {
        {
            title = '🎯 単発ガチャ',
            description = string.format('💰 $%s | 🎫 %s枚', formatNumber(gacha.price_money), gacha.price_ticket),
            icon = 'fa-solid fa-dice-one',
            iconColor = '#4CAF50',
            onSelect = function()
                openPaymentMenu(gacha, 'single')
            end
        }
    }
    
    if Config.MultiGacha.enabled then
        table.insert(options, {
            title = string.format('🎊 10連ガチャ (%d%%割引)', discount * 100),
            description = string.format('💰 $%s | 🎫 %s枚', formatNumber(multiPriceMoney), multiPriceTicket),
            icon = 'fa-solid fa-dice',
            iconColor = '#FF9800',
            onSelect = function()
                openPaymentMenu(gacha, 'multi')
            end
        })
    end
    
    lib.registerContext({
        id = 'vehiclegacha_count',
        title = gacha.label .. ' - 回数選択',
        menu = 'vehiclegacha_main',
        options = options
    })
    
    lib.showContext('vehiclegacha_count')
end

function openPaymentMenu(gacha, gachaCount)
    local tickets = lib.callback.await('ng-vehiclegacha:server:getPlayerTickets', false)
    
    local priceMoney = gacha.price_money
    local priceTicket = gacha.price_ticket
    
    if gachaCount == 'multi' then
        local multiCount = Config.MultiGacha.count
        local discount = Config.MultiGacha.discount
        priceMoney = math.floor(gacha.price_money * multiCount * (1 - discount))
        priceTicket = math.floor(gacha.price_ticket * multiCount * (1 - discount))
    end
    
    local options = {
        {
            title = '💵 お金で支払う',
            description = string.format('必要金額: $%s', formatNumber(priceMoney)),
            icon = 'fa-solid fa-money-bill-wave',
            iconColor = '#4CAF50',
            onSelect = function()
                confirmGacha(gacha, 'money', gachaCount, priceMoney, priceTicket)
            end
        },
        {
            title = '🎫 チケットで支払う',
            description = string.format('必要枚数: %s枚 (所持: %s枚)', priceTicket, tickets),
            icon = 'fa-solid fa-ticket',
            iconColor = '#FF9800',
            onSelect = function()
                confirmGacha(gacha, 'ticket', gachaCount, priceMoney, priceTicket)
            end,
            disabled = tickets < priceTicket
        }
    }
    
    lib.registerContext({
        id = 'vehiclegacha_payment',
        title = gacha.label .. ' - 支払い方法',
        menu = 'vehiclegacha_count',
        options = options
    })
    
    lib.showContext('vehiclegacha_payment')
end

function confirmGacha(gacha, paymentType, gachaCount, priceMoney, priceTicket)
    local paymentText = paymentType == 'money' 
        and string.format('$%s', formatNumber(priceMoney))
        or string.format('%s枚のチケット', priceTicket)
    
    local countText = gachaCount == 'multi' and '10連' or '単発'
    
    local alert = lib.alertDialog({
        header = 'ガチャ確認',
        content = string.format('%sを使用して「%s」%sガチャを回しますか?', paymentText, gacha.label, countText),
        centered = true,
        cancel = true,
        labels = {
            confirm = 'ガチャを回す',
            cancel = 'キャンセル'
        }
    })
    
    if alert == 'confirm' then
        if gachaCount == 'multi' then
            executeMultiGacha(gacha, paymentType)
        else
            executeGacha(gacha, paymentType)
        end
    end
end

-- ============================================
-- 単発ガチャ実行(移動制限付き)
-- ============================================
function executeGacha(gacha, paymentType)
    isGachaActive = true
    disableControls()
    
    SendNUIMessage({
        type = 'showGachaAnimation'
    })
    
    Wait(Config.GachaUI.animationDuration)
    
    local result = lib.callback.await('ng-vehiclegacha:server:executeGacha', false, gacha.gacha_type, paymentType)
    
    SendNUIMessage({
        type = 'hideGachaAnimation'
    })
    
    Wait(300)
    
    if result.success then
        showGachaResult(result.vehicle)
    else
        isGachaActive = false
        lib.notify({
            type = 'error',
            description = result.message,
            position = Config.Notify.position,
            duration = Config.Notify.duration
        })
    end
end

-- ============================================
-- 10連ガチャ実行(移動制限付き)
-- ============================================
function executeMultiGacha(gacha, paymentType)
    isGachaActive = true
    disableControls()
    
    SendNUIMessage({
        type = 'showGachaAnimation'
    })
    
    Wait(Config.GachaUI.animationDuration)
    
    local result = lib.callback.await('ng-vehiclegacha:server:executeMultiGacha', false, gacha.gacha_type, paymentType)
    
    SendNUIMessage({
        type = 'hideGachaAnimation'
    })
    
    Wait(300)
    
    if result.success then
        showMultiGachaResult(result.vehicles)
    else
        isGachaActive = false
        lib.notify({
            type = 'error',
            description = result.message,
            position = Config.Notify.position,
            duration = Config.Notify.duration
        })
    end
end

-- ============================================
-- 単発ガチャ結果表示
-- ============================================
function showGachaResult(vehicle)
    PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    
    SendNUIMessage({
        type = 'showGachaResult',
        vehicle = vehicle
    })
    
    SetTimeout(5000, function()
        SendNUIMessage({
            type = 'hideGachaResult'
        })
        isGachaActive = false
    end)
    
    lib.notify({
        type = 'success',
        description = string.format(Config.Locale.vehicle_won, vehicle.label),
        position = Config.Notify.position,
        duration = Config.Notify.duration
    })
end

-- ============================================
-- 10連ガチャ結果表示
-- ============================================
function showMultiGachaResult(vehicles)
    PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    
    SendNUIMessage({
        type = 'showMultiGachaResult',
        vehicles = vehicles
    })
    
    SetTimeout(8000, function()
        SendNUIMessage({
            type = 'hideMultiGachaResult'
        })
        isGachaActive = false
    end)
    
    lib.notify({
        type = 'success',
        description = Config.Locale.multi_gacha_success,
        position = Config.Notify.position,
        duration = Config.Notify.duration
    })
end

RegisterNUICallback('closeUI', function(data, cb)
    SendNUIMessage({
        type = 'hideGachaResult'
    })
    SendNUIMessage({
        type = 'hideMultiGachaResult'
    })
    isGachaActive = false
    cb('ok')
end)

function openHistoryMenu()
    local history = lib.callback.await('ng-vehiclegacha:server:getPlayerHistory', false, 20)
    
    if not history or #history == 0 then
        lib.notify({
            type = 'info',
            description = 'ガチャ履歴がありません',
            position = Config.Notify.position,
            duration = Config.Notify.duration
        })
        return
    end
    
    local options = {}
    
    for _, record in ipairs(history) do
        local rarityInfo = nil
        for _, r in ipairs(Config.Rarities) do
            if r.name == record.rarity then
                rarityInfo = r
                break
            end
        end
        
        local rarityLabel = rarityInfo and rarityInfo.label or record.rarity
        local rarityColor = rarityInfo and rarityInfo.color or '#FFFFFF'
        local dateTime = record.created_at or 'N/A'
        
        table.insert(options, {
            title = record.vehicle_label,
            description = string.format('%s | %s', rarityLabel, dateTime),
            icon = 'fa-solid fa-car',
            iconColor = rarityColor,
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'vehiclegacha_history',
        title = '📜 ガチャ履歴',
        menu = 'vehiclegacha_main',
        options = options
    })
    
    lib.showContext('vehiclegacha_history')
end

RegisterNetEvent('ng-vehiclegacha:client:openAdminMenu', function()
    if not isAdmin() then
        lib.notify({
            type = 'error',
            description = Config.Locale.no_permission,
            position = Config.Notify.position,
            duration = Config.Notify.duration
        })
        return
    end
    
    lib.notify({
        type = 'info',
        description = '管理メニューは /vgacha_ticket と /vgacha_toggle コマンドを使用してください',
        position = Config.Notify.position,
        duration = 5000
    })
end)

if Config.Debug then
    print('^2[ng-vehiclegacha]^7 クライアントメイン処理がロードされました')
end
