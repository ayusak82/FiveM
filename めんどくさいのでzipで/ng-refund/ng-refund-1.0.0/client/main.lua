local QBCore = exports['qb-core']:GetCoreObject()

-- 事前宣言
local OpenItemRefundMenu, OpenVehicleRefundMenu, OpenHistoryMenu, OpenPlayerSearchMenu, OpenItemSearchMenu, OpenVehicleSearchMenu

-- 管理者権限チェック関数
local function isAdmin()
    return lib.callback.await('ng-refund:server:isAdmin', false)
end

-- 日時フォーマット関数
local function formatTimestamp(timestamp)
    if not timestamp then return 'N/A' end

    local function addZero(n)
        return n < 10 and '0' .. n or n
    end

    -- 日本時間の補正（+9時間）
    timestamp = timestamp + (9 * 3600)

    -- 2025年1月1日からの経過時間を計算
    local baseTime = 1735689600  -- 2025/1/1 00:00:00 のUNIXタイムスタンプ
    local diff = timestamp - baseTime

    -- 日時の計算
    local days = math.floor(diff / 86400)
    local hours = math.floor((diff % 86400) / 3600)
    local minutes = math.floor((diff % 3600) / 60)

    -- 年月日の計算
    local year = 2025
    local month = 1
    local day = 1

    -- 日数から年月日を計算
    while days > 0 do
        local daysInMonth = 31
        if month == 4 or month == 6 or month == 9 or month == 11 then
            daysInMonth = 30
        elseif month == 2 then
            if year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0) then
                daysInMonth = 29
            else
                daysInMonth = 28
            end
        end

        if days >= daysInMonth then
            days = days - daysInMonth
            month = month + 1
            if month > 12 then
                month = 1
                year = year + 1
            end
        else
            day = day + days
            days = 0
        end
    end

    return string.format('%d-%s-%s %s:%s', 
        year,
        addZero(month),
        addZero(day),
        addZero(hours),
        addZero(minutes)
    )
end

-- プレイヤー検索メニューを開く
OpenPlayerSearchMenu = function(callback)
    local input = lib.inputDialog('プレイヤー検索', {
        {
            type = 'input',
            label = '検索キーワード',
            description = 'CitizenIDまたは名前で検索',
            required = true,
            placeholder = 'ABC123 または 田中 太郎'
        }
    })

    if not input then return end
    
    local searchTerm = input[1]
    if not searchTerm or searchTerm == '' then return end

    -- サーバーに検索リクエストを送信
    local players = lib.callback.await('ng-refund:server:SearchPlayers', false, searchTerm)
    
    if not players or #players == 0 then
        lib.notify({
            title = '検索結果なし',
            description = '指定された条件に一致するプレイヤーが見つかりませんでした',
            type = 'error'
        })
        return
    end

    -- 検索結果をメニューとして表示
    local options = {}
    for _, player in ipairs(players) do
        table.insert(options, {
            title = player.name,
            description = string.format('CitizenID: %s%s', 
                player.citizenid,
                player.online and ' (オンライン)' or ' (オフライン)'
            ),
            icon = player.online and 'user-check' or 'user',
            onSelect = function()
                if callback then
                    callback(player.citizenid, player.name)
                end
            end
        })
    end

    lib.registerContext({
        id = 'player_search_results',
        title = string.format('検索結果: "%s"', searchTerm),
        menu = 'admin_refund_menu',
        options = options
    })

    lib.showContext('player_search_results')
end

-- アイテム検索メニューを開く
local function OpenItemSearchMenu(callback)
    local input = lib.inputDialog('アイテム検索', {
        {
            type = 'input',
            label = '検索キーワード',
            description = 'アイテム名またはラベルで検索',
            required = true,
            placeholder = 'phone または 電話'
        }
    })

    if not input then return end
    
    local searchTerm = input[1]
    if not searchTerm or searchTerm == '' then return end

    -- サーバーにアイテム検索リクエストを送信
    local items = lib.callback.await('ng-refund:server:SearchItems', false, searchTerm)
    
    if not items or #items == 0 then
        lib.notify({
            title = '検索結果なし',
            description = '指定された条件に一致するアイテムが見つかりませんでした',
            type = 'error'
        })
        return
    end

    -- 検索結果をメニューとして表示
    local options = {}
    for _, item in ipairs(items) do
        table.insert(options, {
            title = item.label,
            description = string.format('アイテム名: %s\n種類: %s%s', 
                item.name,
                item.type or 'item',
                item.weight and string.format('\n重量: %sg', item.weight) or ''
            ),
            icon = 'box-open',
            onSelect = function()
                if callback then
                    callback(item.name, item.label)
                end
            end
        })
    end

    lib.registerContext({
        id = 'item_search_results',
        title = string.format('アイテム検索結果: "%s"', searchTerm),
        menu = 'admin_refund_menu',
        options = options
    })

    lib.showContext('item_search_results')
end

-- アイテム補填メニューを開く
OpenItemRefundMenu = function()
    -- プレイヤー検索を開く
    OpenPlayerSearchMenu(function(citizenId, playerName)
        -- プレイヤーが選択されたらアイテム検索へ
        OpenItemSearchMenu(function(itemName, itemLabel)
            -- アイテムが選択されたら個数入力へ
            local input = lib.inputDialog('アイテム補填', {
                {
                    type = 'number',
                    label = '個数',
                    description = string.format('%s の補填個数を入力してください', itemLabel),
                    required = true,
                    min = 1,
                    max = 2000000000,
                    default = 1
                }
            })

            if not input then return end
            
            local amount = input[1]
            
            -- 確認ダイアログを表示
            local confirm = lib.alertDialog({
                header = '補填確認',
                content = string.format('以下の内容で補填を実行しますか？\n\nプレイヤー: %s\nCitizenID: %s\nアイテム: %s (%s)\n個数: %d', 
                    playerName, citizenId, itemLabel, itemName, amount),
                centered = true,
                cancel = true
            })

            if confirm == 'confirm' then
                TriggerServerEvent('ng-refund:server:GiveItem', citizenId, itemName, amount)
            end
        end)
    end)
end

-- 車両検索メニューを開く
local function OpenVehicleSearchMenu(callback)
    local input = lib.inputDialog('車両検索', {
        {
            type = 'input',
            label = '検索キーワード',
            description = '車両名またはブランドで検索（空欄で全車両表示）',
            required = false,
            placeholder = 'adder または Bugatti'
        }
    })

    if input == nil then return end -- キャンセルされた場合
    
    local searchTerm = input[1] or '' -- 空欄の場合は全車両表示

    -- サーバーに車両検索リクエストを送信
    local vehicles = lib.callback.await('ng-refund:server:SearchVehicles', false, searchTerm)
    
    if not vehicles or #vehicles == 0 then
        lib.notify({
            title = '検索結果なし',
            description = searchTerm == '' and '車両データが見つかりませんでした' or '指定された条件に一致する車両が見つかりませんでした',
            type = 'error'
        })
        return
    end

    -- 検索結果をメニューとして表示
    local options = {}
    for _, vehicle in ipairs(vehicles) do
        table.insert(options, {
            title = vehicle.name,
            description = string.format('車両名: %s\nブランド: %s\nクラス: %s', 
                vehicle.model,
                vehicle.brand or 'Unknown',
                vehicle.category or 'Unknown'
            ),
            icon = 'car',
            onSelect = function()
                if callback then
                    callback(vehicle.model, vehicle.name)
                end
            end
        })
    end

    lib.registerContext({
        id = 'vehicle_search_results',
        title = searchTerm == '' and '車両一覧' or string.format('車両検索結果: "%s"', searchTerm),
        menu = 'admin_refund_menu',
        options = options
    })

    lib.showContext('vehicle_search_results')
end

-- 車両補填メニューを開く
OpenVehicleRefundMenu = function()
    -- プレイヤー検索を開く
    OpenPlayerSearchMenu(function(citizenId, playerName)
        -- プレイヤーが選択されたら車両検索へ
        OpenVehicleSearchMenu(function(vehicleModel, vehicleName)
            -- 車両が選択されたらナンバープレート入力へ
            local input = lib.inputDialog('車両補填', {
                {
                    type = 'input',
                    label = 'ナンバープレート',
                    description = '空欄の場合は自動生成されます（最大8文字、英数字のみ）',
                    required = false,
                    placeholder = 'ABC123'
                }
            })
            
            if input == nil then return end -- キャンセルされた場合
            
            local customPlate = input[1]
            
            -- 確認ダイアログを表示
            local plateText = customPlate and customPlate ~= '' and customPlate or '自動生成'
            local confirm = lib.alertDialog({
                header = '補填確認',
                content = string.format('以下の内容で補填を実行しますか？\n\nプレイヤー: %s\nCitizenID: %s\n車両: %s (%s)\nナンバープレート: %s', 
                    playerName, citizenId, vehicleName, vehicleModel, plateText),
                centered = true,
                cancel = true
            })

            if confirm == 'confirm' then
                TriggerServerEvent('ng-refund:server:GiveVehicle', citizenId, vehicleModel, customPlate)
            end
        end)
    end)
end

-- 補填履歴メニューを開く
OpenHistoryMenu = function()
    local history = lib.callback.await('ng-refund:server:GetRefundHistory', false)
    
    if not history or #history == 0 then
        lib.notify({
            title = '履歴なし',
            description = '補填履歴が存在しません',
            type = 'info'
        })
        return
    end

    local options = {}
    for _, record in ipairs(history) do
        local itemInfo = ''
        if record.type == 'item' then
            local itemLabel = QBCore.Shared.Items[record.item_name] and QBCore.Shared.Items[record.item_name].label or record.item_name
            itemInfo = string.format('%s x%d', itemLabel, record.amount)
        else
            local vehicleName = QBCore.Shared.Vehicles[record.vehicle_model] and QBCore.Shared.Vehicles[record.vehicle_model].name or record.vehicle_model
            itemInfo = string.format('%s (%s) %s', 
                vehicleName,
                record.vehicle_model,
                record.plate ~= '' and ('- ナンバー: ' .. record.plate) or ''
            )
        end

        table.insert(options, {
            title = string.format('%s - %s', 
                record.type == 'item' and 'アイテム補填' or '車両補填',
                formatTimestamp(record.created_at)
            ),
            description = string.format('対象: %s\n補填: %s\n状態: %s',
                record.target_name,
                itemInfo,
                record.claimed == true or record.claimed == 1 and '受取済み' or '未受取'
            ),
            icon = record.type == 'item' and 'box' or 'car',
            metadata = {
                {label = '管理者', value = record.admin_name},
                {label = 'CitizenID', value = record.target_identifier}
            }
        })
    end

    lib.registerContext({
        id = 'refund_history_menu',
        title = '補填履歴',
        menu = 'admin_refund_menu',
        options = options
    })

    lib.showContext('refund_history_menu')
end

-- メインメニューを開く
local function OpenMainMenu()
    if not isAdmin() then
        lib.notify(Config.Notifications.noPermission)
        return
    end

    lib.registerContext({
        id = 'admin_refund_menu',
        title = Config.UI.header.title,
        options = {
            {
                title = 'アイテム補填',
                description = '指定したプレイヤーにアイテムを補填します',
                icon = 'box',
                onSelect = function()
                    OpenItemRefundMenu()
                end
            },
            {
                title = '車両補填',
                description = '指定したプレイヤーに車両を補填します',
                icon = 'car',
                onSelect = function()
                    OpenVehicleRefundMenu()
                end
            },
            {
                title = '補填履歴確認',
                description = '補填履歴を確認・管理します',
                icon = 'history',
                onSelect = function()
                    OpenHistoryMenu()
                end
            }
        }
    })
    
    lib.showContext('admin_refund_menu')
end

-- コマンド登録
RegisterCommand('refund', function()
    OpenMainMenu()
end, false)