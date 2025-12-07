local debug = true

-- アイテムタイプの定義
local ItemTypes = {
    { value = 'normal', label = '通常アイテム' },
    { value = 'food', label = '食べ物' },
    { value = 'drink', label = '飲み物' },
    { value = 'stress', label = 'ストレス' }
}

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

local function getTypeSpecificFields(itemType)
    local fields = {}
    
    if itemType == 'food' then
        table.insert(fields, {
            type = 'number',
            label = '満腹度回復量',
            description = '-100から100の間で指定してください（-で減少、+で回復）',
            required = true,
            default = 20,
            min = -100,
            max = 100
        })
    elseif itemType == 'drink' then
        table.insert(fields, {
            type = 'number',
            label = '水分回復量',
            description = '-100から100の間で指定してください（-で減少、+で回復）',
            required = true,
            default = 20,
            min = -100,
            max = 100
        })
    elseif itemType == 'stress' then
        table.insert(fields, {
            type = 'number',
            label = 'ストレス減少量',
            description = '-100から100の間で指定してください（-で減少、+で回復）',
            required = true,
            default = -20,
            min = -100,
            max = 100
        })
    end
    
    return fields
end

-- アイテム詳細入力メニューを開く関数
local function openItemCreatorDetails(playerJob, selectedType)
    -- タイプ固有のフィールドを取得
    local specificFields = getTypeSpecificFields(selectedType)
    
    -- 基本フィールドの作成
    local baseFields = {
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
            type = 'number',
            label = '重量 (グラム)',
            description = 'アイテムの重量を入力してください',
            required = true,
            default = Config.DefaultSettings.weight,
            min = 1
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
        }
    }

    -- タイプ固有のフィールドを基本フィールドに追加
    for _, field in ipairs(specificFields) do
        table.insert(baseFields, field)
    end

    -- アイテム詳細の入力
    local itemTypeLabel = ''
    for _, itemType in ipairs(ItemTypes) do
        if itemType.value == selectedType then
            itemTypeLabel = itemType.label
            break
        end
    end
    
    local input = lib.inputDialog('アイテム作成 - ' .. itemTypeLabel, baseFields)

    if not input then return end

    -- クライアント側でのバリデーション
    local isValidName, nameError = validateItemName(input[1])
    if not isValidName then
        lib.notify({
            title = 'エラー',
            description = nameError,
            type = 'error'
        })
        return
    end

    local isValidUrl, urlError = validateUrl(input[6])
    if not isValidUrl then
        lib.notify({
            title = 'エラー',
            description = urlError,
            type = 'error'
        })
        return
    end

    -- アイテムデータの作成
    local itemData = {
        name = playerJob .. '_' .. input[1],
        label = input[2],
        stack = input[3],  -- チェックボックスの値
        type = selectedType,
        weight = input[4],  -- インデックスが1つずれる
        description = input[5],
        imageUrl = input[6],
        client = {
            status = {}
        }
    }

    -- タイプ固有のデータを追加
    if selectedType == 'food' then
        itemData.client.status.hunger = input[7] * 10000
    elseif selectedType == 'drink' then
        itemData.client.status.thirst = input[7] * 10000
    elseif selectedType == 'stress' then
        itemData.client.status.stress = input[7] * 10000
    end

    -- サーバーにデータを送信
    local success, message = lib.callback.await('ng-itemcreator:server:createItemWithImage', false, itemData)
    
    if success then
        lib.notify({
            title = '成功',
            description = message,
            type = 'success'
        })
    else
        lib.notify({
            title = 'エラー',
            description = message,
            type = 'error'
        })
    end
end

-- アイテム作成メニューを開く関数
local function openItemCreatorMenu()
    -- 現在のジョブを取得
    local playerJob = lib.callback.await('ng-itemcreator:server:getPlayerJob', false)
    if not playerJob then
        lib.notify({
            title = 'エラー',
            description = 'ジョブ情報の取得に失敗しました',
            type = 'error'
        })
        return
    end

    -- アイテムタイプの選択メニュー
    local options = {}
    for _, itemType in ipairs(ItemTypes) do
        table.insert(options, {
            title = itemType.label,
            description = itemType.value .. ' タイプのアイテムを作成します',
            onSelect = function()
                openItemCreatorDetails(playerJob, itemType.value)
            end
        })
    end

    lib.registerContext({
        id = 'item_type_menu',
        title = 'アイテムタイプの選択',
        options = options
    })

    lib.showContext('item_type_menu')
end

-- アイテム削除メニューを開く関数
local function openItemDeleteMenu()
    local playerJob = lib.callback.await('ng-itemcreator:server:getPlayerJob', false)
    if not playerJob then
        lib.notify({
            title = 'エラー',
            description = 'ジョブ情報の取得に失敗しました',
            type = 'error'
        })
        return
    end

    -- 既存アイテムの取得
    local items = lib.callback.await('ng-itemcreator:server:getItems', false)
    if not items then
        lib.notify({
            title = 'エラー',
            description = 'アイテム情報の取得に失敗しました',
            type = 'error'
        })
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
                            lib.notify({
                                title = '成功',
                                description = message,
                                type = 'success'
                            })
                        else
                            lib.notify({
                                title = 'エラー',
                                description = message,
                                type = 'error'
                            })
                        end
                    end
                end
            })
        end
    end

    if #options == 0 then
        lib.notify({
            title = '情報',
            description = '削除可能なアイテムが見つかりません',
            type = 'info'
        })
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
    -- 管理者権限のチェック
    local isAdmin = lib.callback.await('ng-itemcreator:server:checkAdminPermission', false)
    
    local options = {}
    
    -- 管理者の場合のみ管理者メニューを追加
    if isAdmin then
        table.insert(options, {
            title = '管理者メニュー',
            description = '管理者用の特別なメニューです',
            onSelect = function()
                lib.notify({
                    title = '情報',
                    description = '管理者メニューは現在実装中です',
                    type = 'info'
                })
            end
        })
    end
    
    -- 通常のメニューオプションを追加
    table.insert(options, {
        title = 'アイテムの追加',
        description = '新しいアイテムを作成します',
        onSelect = function()
            openItemCreatorMenu()
        end
    })
       
    table.insert(options, {
        title = 'アイテムの削除',
        description = '既存のアイテムを削除します',
        onSelect = function()
            openItemDeleteMenu()
        end
    })

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
        lib.notify({
            title = 'エラー',
            description = '権限がありません',
            type = 'error'
        })
        return
    end
    
    openMainMenu()
end, false)