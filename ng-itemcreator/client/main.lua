local debug = true
local QBCore = exports['qb-core']:GetCoreObject()



-- アイテム名の形式チェック
local function validateItemName(name)
    if not name then 
        return false, "アイテム名が入力されていません" 
    end
    
    -- 英数字のみを許可
    if string.match(name, "[^%w]") then
        return false, "アイテム名には英数字のみ使用できます"
    end
    
    return true, "有効なアイテム名です"
end

-- URLの形式チェック
local function validateUrl(url)
    if not url then
        return false, "URLが入力されていません"
    end

    -- gazou1.dlup.byドメインのみを許可
    if not string.match(url, "^https://gazou1.dlup.by/") then
        return false, "許可されていないドメインです"
    end

    return true, "有効なURLです"
end



-- アニメーション選択用のオプションを作成
local function getAnimationOptions()
    local options = {}
    for key, anim in pairs(Config.Animations) do
        table.insert(options, {
            value = key,
            label = anim.label
        })
    end
    return options
end

-- プロップ選択用のオプションを作成
local function getPropOptions()
    local options = {}
    for key, prop in pairs(Config.Props) do
        table.insert(options, {
            value = key,
            label = prop.label
        })
    end
    return options
end

-- アイテム詳細入力メニューを開く関数
local function openItemCreatorDetails(playerJob)
    
    -- すべてのフィールドを作成
    local fields = {
        {
            type = 'input',
            label = 'アイテム名',
            description = string.format('"%s_" が自動的に追加されます', playerJob),
            required = true,
            placeholder = 'evidence'
        },
        {
            type = 'input',
            label = '表示名',
            description = 'インベントリに表示される名前',
            required = true,
            placeholder = '証拠品'
        },
        {
            type = 'checkbox',
            label = 'スタック可能',
            description = 'アイテムをスタックできるようにするか',
            checked = true
        },
        {
            type = 'slider',
            label = '重量 (グラム)',
            description = 'スライダーでアイテムの重量を設定してください',
            required = true,
            default = Config.Limits.weight.default,
            min = Config.Limits.weight.min,
            max = Config.Limits.weight.max,
            step = Config.Limits.weight.step
        },
        {
            type = 'input',
            label = '説明文',
            description = 'アイテムの説明文を入力してください',
            required = true,
            default = Config.DefaultSettings.description
        },
        {
            type = 'input',
            label = '画像URL',
            description = 'アイテムの画像URLを入力してください',
            required = true,
            placeholder = 'https://gazou1.dlup.by/example.png'
        },
        {
            type = 'slider',
            label = '満腹度回復量',
            description = '0の場合は効果なし',
            required = false,
            default = Config.Limits.hunger.default,
            min = Config.Limits.hunger.min,
            max = Config.Limits.hunger.max,
            step = Config.Limits.hunger.step
        },
        {
            type = 'slider',
            label = '水分回復量',
            description = '0の場合は効果なし',
            required = false,
            default = Config.Limits.thirst.default,
            min = Config.Limits.thirst.min,
            max = Config.Limits.thirst.max,
            step = Config.Limits.thirst.step
        },
        {
            type = 'slider',
            label = 'ストレス減少量',
            description = '0の場合は効果なし',
            required = false,
            default = Config.Limits.stress.default,
            min = Config.Limits.stress.min,
            max = Config.Limits.stress.max,
            step = Config.Limits.stress.step
        },
        {
            type = 'select',
            label = 'アニメーション',
            description = 'アイテム使用時のアニメーションを選択',
            required = false,
            default = 'なし',
            options = getAnimationOptions()
        },
        {
            type = 'select',
            label = 'プロップ',
            description = 'アイテム使用時に表示するプロップを選択',
            required = false,
            default = 'なし',
            options = getPropOptions()
        },
        {
            type = 'number',
            label = '使用時間（秒）',
            description = 'アイテム使用にかかる時間（0の場合はデフォルト）',
            required = false,
            default = Config.Limits.usetime.default,
            min = Config.Limits.usetime.min,
            max = Config.Limits.usetime.max
        }
    }
    
    local input = lib.inputDialog('アイテム作成', fields)

    if not input then return end

    -- クライアント側でのバリデーション
    local isValidName, nameError = validateItemName(input[1])
    if not isValidName then
        QBCore.Functions.Notify(nameError, 'error')
        return
    end

    local isValidUrl, urlError = validateUrl(input[6])
    if not isValidUrl then
        QBCore.Functions.Notify(urlError, 'error')
        return
    end

    -- 効果の値を取得
    local hungerValue = input[7] or 0
    local thirstValue = input[8] or 0
    local stressValue = input[9] or 0
    local selectedAnimation = input[10] or 'なし'
    local selectedProp = input[11] or 'なし'
    local useTime = (input[12] or 0) * 1000  -- 秒をミリ秒に変換

    -- アイテムタイプを自動判定
    local itemType = 'normal'
    if hungerValue ~= 0 or thirstValue ~= 0 or stressValue ~= 0 then
        -- 何らかの効果がある場合は消費アイテムとする
        if hungerValue ~= 0 then
            itemType = 'food'
        elseif thirstValue ~= 0 then
            itemType = 'drink'
        elseif stressValue ~= 0 then
            itemType = 'stress'
        end
    end

    -- アイテムデータの作成
    local itemData = {
        name = playerJob .. '_' .. input[1],
        label = input[2],
        stack = input[3] and true or false,
        type = itemType,
        weight = input[4],
        description = input[5],
        imageUrl = input[6],
        animation = selectedAnimation,
        prop = selectedProp,
        useTime = useTime,
        client = {
            status = {
                hunger = hungerValue ~= 0 and (hungerValue * 10000) or nil,
                thirst = thirstValue ~= 0 and (thirstValue * 10000) or nil,
                stress = stressValue ~= 0 and (stressValue * 10000) or nil
            }
        }
    }

    -- サーバーにデータを送信
    local success, message = lib.callback.await('ng-itemcreator:server:createItemWithImage', false, itemData)
    
    if success then
        QBCore.Functions.Notify(message, 'success')
    else
        QBCore.Functions.Notify(message, 'error')
    end
end

-- アイテム作成メニューを開く関数
local function openItemCreatorMenu()
    -- 現在のジョブを取得
    local playerJob = lib.callback.await('ng-itemcreator:server:getPlayerJob', false)
    if not playerJob then
        QBCore.Functions.Notify('ジョブ情報の取得に失敗しました', 'error')
        return
    end

    -- 直接アイテム作成画面を開く
    openItemCreatorDetails(playerJob)
end

-- アイテム削除メニューを開く関数
local function openItemDeleteMenu()
    local playerJob = lib.callback.await('ng-itemcreator:server:getPlayerJob', false)
    if not playerJob then
        QBCore.Functions.Notify('ジョブ情報の取得に失敗しました', 'error')
        return
    end

    -- 既存アイテムの取得
    local items = lib.callback.await('ng-itemcreator:server:getItems', false)
    if not items then
        QBCore.Functions.Notify('アイテム情報の取得に失敗しました', 'error')
        return
    end

    -- 削除可能なアイテムのオプションを作成（自分のジョブのアイテムのみ）
    local options = {}
    for name, data in pairs(items) do
        -- ジョブプレフィックスのチェック
        if string.match(name, "^" .. playerJob .. "_") then
            table.insert(options, {
                title = data.label,
                description = '削除: ' .. name,
                onSelect = function()
                    local confirmed = lib.alertDialog({
                        header = 'アイテム削除の確認',
                        content = string.format('本当に「%s」を削除しますか？\nこの操作は取り消せません。', data.label),
                        cancel = true,
                        labels = {
                            confirm = '削除する',
                            cancel = 'キャンセル'
                        }
                    })
                    
                    if confirmed == 'confirm' then
                        local success, message = lib.callback.await('ng-itemcreator:server:deleteItem', false, name)
                        if success then
                            QBCore.Functions.Notify(message, 'success')
                        else
                            QBCore.Functions.Notify(message, 'error')
                        end
                    end
                end
            })
        end
    end

    if #options == 0 then
        QBCore.Functions.Notify('削除可能なアイテムが見つかりません', 'inform')
        return
    end

    lib.registerContext({
        id = 'item_delete_menu',
        title = 'アイテム削除',
        options = options
    })

    lib.showContext('item_delete_menu')
end

-- メインメニューを開く関数
local function openMainMenu()
    local options = {
        {
            title = 'アイテムの追加',
            description = '新しいアイテムを作成します',
            onSelect = function()
                openItemCreatorMenu()
            end
        },
        {
            title = 'アイテムの削除',
            description = '既存のアイテムを削除します',
            onSelect = function()
                openItemDeleteMenu()
            end
        }
    }

    lib.registerContext({
        id = 'item_creator_menu',
        title = 'アイテム管理メニュー',
        options = options
    })

    lib.showContext('item_creator_menu')
end

-- コマンド登録
RegisterCommand('createitem', function()
    local hasPermission = lib.callback.await('ng-itemcreator:server:checkPermission', false)
    if not hasPermission then
        QBCore.Functions.Notify('権限がありません', 'error')
        return
    end
    
    openMainMenu()
end, false)

-- イベントとして登録
RegisterNetEvent('ng-itemcreator:client:openMenu')
AddEventHandler('ng-itemcreator:client:openMenu', function()
    local hasPermission = lib.callback.await('ng-itemcreator:server:checkPermission', false)
    if not hasPermission then
        QBCore.Functions.Notify('権限がありません', 'error')
        return
    end
    
    openMainMenu()
end)