local QBCore = exports['qb-core']:GetCoreObject()
local currentSubscription = nil

-- メニュー関連の関数宣言
local OpenPlayerMenu, OpenVehicleCategoryMenu, OpenVehicleSelectionMenu, OpenAdminMenu

-- サブスクリプション情報を見やすく整形する関数
local function FormatSubscriptionInfo(subscription, playerName)
    if not subscription then
        return '現在のプラン: なし'
    end

    local plan = Config.Plans[subscription.plan_name]
    if not plan then return '無効なプラン' end

    -- 報酬アイテムのリスト作成
    local itemsList = {}
    for itemName, amount in pairs(plan.rewards.items) do
        local item = QBCore.Shared.Items[itemName]
        if item then
            table.insert(itemsList, item.label .. ' x' .. amount)
        end
    end

    -- 有効期限の整形
    local expiresText = '無期限'
    if subscription.expires_at then
        local timestamp = subscription.expires_at
        if type(timestamp) == 'string' then
            -- MySQL timestamp文字列からUnixタイムスタンプに変換
            local year, month, day, hour, min, sec = string.match(timestamp, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
            if year then
                local timeObj = {
                    year = tonumber(year),
                    month = tonumber(month),
                    day = tonumber(day),
                    hour = tonumber(hour),
                    min = tonumber(min),
                    sec = tonumber(sec)
                }
                expiresText = string.format('%d年%d月%d日 %d:%02d', 
                    timeObj.year, timeObj.month, timeObj.day, timeObj.hour, timeObj.min)
            end
        end
    end

    -- 情報を整形
    local info = string.format([[
プレイヤー名: %s
プラン: %s
有効期限: %s
報酬受取状況: %s
車両受取状況: %s

報酬内容:
- 現金: $%s
- アイテム:
  %s

利用可能な車両カテゴリー:
%s]], 
        playerName,
        plan.label,
        expiresText,
        subscription.rewards_claimed and '受取済み' or '未受取',
        subscription.vehicle_claimed and '受取済み' or '未受取',
        plan.rewards.cash,
        table.concat(itemsList, '\n  '),
        table.concat(plan.rewards.vehicle_categories, '\n')
    )

    return info
end

-- サブスクリプション情報の取得
local function GetCurrentSubscription()
    return lib.callback.await('ng-subscribe:server:getSubscription', false)
end

-- サブスクリプション情報の更新
local function UpdateCurrentSubscription()
    local success = true
    local errorMessage = nil
    
    currentSubscription = GetCurrentSubscription()
    
    if not currentSubscription then
        success = false
        errorMessage = Config.Messages.error.no_subscription
    end
    
    return success, errorMessage
end

-- サブスクリプション失効処理
local function RevokeSubscription(citizenId)
    local success = lib.callback.await('ng-subscribe:server:revokeSubscription', false, citizenId)
    if success then
        lib.notify({
            title = '成功',
            description = 'サブスクリプションを失効させました',
            type = 'success'
        })
    else
        lib.notify({
            title = 'エラー',
            description = '失効処理に失敗しました',
            type = 'error'
        })
    end
    Wait(500)
    ExecuteCommand('subsadmin')
end

-- 車両選択メニュー
OpenVehicleSelectionMenu = function(category)
    local vehicles = QBCore.Shared.Vehicles
    local menuOptions = {}

    -- カテゴリーごとの車両をソート
    local sortedVehicles = {}
    for model, data in pairs(vehicles) do
        if data.category == category then
            table.insert(sortedVehicles, {model = model, data = data})
        end
    end
    table.sort(sortedVehicles, function(a, b) 
        return (a.data.name or a.model) < (b.data.name or b.model)
    end)

    -- メニューオプションの作成
    for _, vehicle in ipairs(sortedVehicles) do
        table.insert(menuOptions, {
            title = vehicle.data.name or vehicle.model,
            description = ('モデル: %s\n製造: %s'):format(
                vehicle.model,
                vehicle.data.brand or '不明'
            ),
            onSelect = function()
                local success = lib.callback.await('ng-subscribe:server:claimVehicle', false, vehicle.model, category)
                if success then
                    lib.notify({
                        title = '成功',
                        description = Config.Messages.success.vehicle_claimed,
                        type = 'success'
                    })
                    OpenPlayerMenu()
                else
                    lib.notify({
                        title = 'エラー',
                        description = Config.Messages.error.vehicle_blacklisted,
                        type = 'error'
                    })
                end
            end
        })
    end

    lib.registerContext({
        id = 'vehicle_selection_menu',
        title = ('車両選択 - %s'):format(category:upper()),
        menu = 'vehicle_category_menu',
        options = menuOptions
    })

    lib.showContext('vehicle_selection_menu')
end

-- カテゴリー選択メニュー
OpenVehicleCategoryMenu = function()
    if not UpdateCurrentSubscription() then return end
    
    local plan = Config.Plans[currentSubscription.plan_name]
    if not plan then return end

    local menuOptions = {}
    
    for _, category in ipairs(plan.rewards.vehicle_categories) do
        table.insert(menuOptions, {
            title = category:upper(),
            description = 'このカテゴリーから車両を選択',
            onSelect = function()
                OpenVehicleSelectionMenu(category)
            end
        })
    end

    lib.registerContext({
        id = 'vehicle_category_menu',
        title = '車両カテゴリー選択',
        menu = 'player_subscription_menu',
        options = menuOptions
    })

    lib.showContext('vehicle_category_menu')
end

-- プレイヤーメインメニュー
OpenPlayerMenu = function()
    if not UpdateCurrentSubscription() then
        lib.notify({
            title = 'エラー',
            description = Config.Messages.error.no_subscription,
            type = 'error'
        })
        return
    end

    local plan = Config.Plans[currentSubscription.plan_name]
    if not plan then return end

    local menuOptions = {
        {
            title = ('現在のプラン: %s'):format(plan.label),
            description = '特典内容を確認し、受け取ることができます',
            disabled = true
        },
        -- 更新ボタンを追加
        {
            title = '🔄 サブスクリプション情報を更新',
            description = 'Discord連携情報を最新の状態に更新します',
            onSelect = function()
                ExecuteCommand('updatesubs')
                Wait(1000) -- 少し待機
                OpenPlayerMenu() -- メニューを再表示
            end
        }
    }

    if not currentSubscription.rewards_claimed then
        local itemsList = {}
        for itemName, amount in pairs(plan.rewards.items) do
            local item = QBCore.Shared.Items[itemName]
            if item then
                table.insert(itemsList, item.label .. ' x' .. amount)
            end
        end

        table.insert(menuOptions, {
            title = '特典を受け取る',
            description = ('現金: $%s\nアイテム:\n%s'):format(
                plan.rewards.cash,
                table.concat(itemsList, '\n')
            ),
            onSelect = function()
                local success = lib.callback.await('ng-subscribe:server:claimRewards', false)
                if success then
                    lib.notify({
                        title = '成功',
                        description = Config.Messages.success.rewards_claimed,
                        type = 'success'
                    })
                    OpenPlayerMenu()
                else
                    lib.notify({
                        title = 'エラー',
                        description = Config.Messages.error.already_claimed,
                        type = 'error'
                    })
                end
            end
        })
    end

    if not currentSubscription.vehicle_claimed then
        table.insert(menuOptions, {
            title = '車両を選択',
            description = '利用可能な車両カテゴリーから選択できます',
            onSelect = function()
                OpenVehicleCategoryMenu()
            end
        })
    end

    lib.registerContext({
        id = 'player_subscription_menu',
        title = 'サブスクリプション特典',
        options = menuOptions
    })

    lib.showContext('player_subscription_menu')
end

-- 管理者メニュー
RegisterCommand('subsadmin', function()
    local isAdmin = lib.callback.await('ng-subscribe:server:isAdmin', false)
    if not isAdmin then
        lib.notify({
            title = 'エラー',
            description = '管理者権限がありません',
            type = 'error'
        })
        return
    end

    lib.registerContext({
        id = 'subscription_admin_menu',
        title = 'サブスクリプション管理',
        options = {
            {
                title = '🔍 プレイヤー情報確認',
                description = 'CitizenIDを入力してプレイヤーのサブスクリプション情報を確認',
                onSelect = function()
                    local input = lib.inputDialog('プレイヤー情報確認', {
                        {
                            type = 'input',
                            label = 'CitizenID',
                            description = 'プレイヤーのCitizenIDを入力してください',
                            required = true
                        }
                    })
                    
                    if input then
                        local citizenId = input[1]
                        local playerInfo = lib.callback.await('ng-subscribe:server:searchPlayer', false, citizenId)
                        
                        if playerInfo then
                            lib.registerContext({
                                id = 'player_subscription_info',
                                title = 'サブスクリプション情報',
                                menu = 'subscription_admin_menu',
                                options = {
                                    {
                                        title = '📋 詳細情報',
                                        description = FormatSubscriptionInfo(playerInfo.subscription, playerInfo.name),
                                        disabled = true
                                    },
                                    {
                                        title = '🔄 強制更新',
                                        description = 'このプレイヤーのサブスクリプションを強制的に更新します',
                                        onSelect = function()
                                            ExecuteCommand('forceplayersubs ' .. citizenId)
                                            Wait(500)
                                            ExecuteCommand('subsadmin')
                                        end
                                    },
                                    {
                                        title = '✨ プラン変更',
                                        description = '新しいプランを選択してください',
                                        onSelect = function()
                                            local options = {}
                                            for planName, planData in pairs(Config.Plans) do
                                                table.insert(options, {
                                                    value = planName,
                                                    label = planData.label
                                                })
                                            end
                                            
                                            local planInput = lib.inputDialog('プラン変更', {
                                                {
                                                    type = 'select',
                                                    label = '新しいプラン',
                                                    description = '適用するプランを選択してください',
                                                    required = true,
                                                    options = options
                                                }
                                            })
                                            
                                            if planInput and planInput[1] then
                                                -- デバッグ出力を追加
                                                --print('プラン変更: CitizenID=' .. citizenId .. ', 新プラン=' .. planInput[1])
                                                
                                                -- イベント発火
                                                TriggerServerEvent('ng-subscribe:server:changePlan', citizenId, planInput[1])
                                                
                                                -- 少し待機してからメニューを再表示
                                                Wait(1000)
                                                ExecuteCommand('subsadmin')
                                            else
                                                lib.notify({
                                                    title = 'エラー',
                                                    description = 'プランが選択されていません',
                                                    type = 'error'
                                                })
                                            end
                                        end
                                    },
                                    {
                                        title = '❌ サブスクリプション失効',
                                        description = 'このプレイヤーのサブスクリプションを失効させます',
                                        onSelect = function()
                                            local confirmed = lib.alertDialog({
                                                header = '失効確認',
                                                content = 'このプレイヤーのサブスクリプションを失効させますか？\nこの操作は取り消せません。',
                                                cancel = true,
                                                labels = {
                                                    confirm = '失効させる',
                                                    cancel = 'キャンセル'
                                                }
                                            })
                                            if confirmed then
                                                RevokeSubscription(citizenId)
                                            end
                                        end
                                    }
                                }
                            })
                            lib.showContext('player_subscription_info')
                        else
                            lib.notify({
                                title = 'エラー',
                                description = 'プレイヤーが見つかりません',
                                type = 'error'
                            })
                        end
                    end
                end
            },
            {
                title = '🔄 全体強制更新',
                description = '全プレイヤーのサブスクリプションを強制的に更新します',
                onSelect = function()
                    ExecuteCommand('forcesubs')
                end
            }
        }
    })

    lib.showContext('subscription_admin_menu')
end)

-- プレイヤーコマンド
RegisterCommand(Config.UI.PlayerCommand, function()
    OpenPlayerMenu()
end)