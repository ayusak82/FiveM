local currentItemName = nil
local currentConfig = nil
local items = {}

-- アイテムリストの取得
local function GetItems()
    local success, result = lib.callback.await('ng-itemeditor:getItemList')
    if success then
        items = result
        return true
    end
    return false
end

-- アイテム設定の取得
local function GetItemConfig(itemName)
    local success, result = lib.callback.await('ng-itemeditor:getItemConfig', itemName)
    if success then
        currentConfig = result
        return true
    end
    return false
end

-- アイテム設定の保存
local function SaveItemConfig(itemName, config)
    local success, error = lib.callback.await('ng-itemeditor:saveItemConfig', itemName, config)
    if not success then
        lib.notify({
            title = 'エラー',
            description = error,
            type = 'error'
        })
        return false
    end
    return true
end

-- アイテム設定の削除
local function DeleteItemConfig(itemName)
    local success, error = lib.callback.await('ng-itemeditor:deleteItemConfig', itemName)
    if not success then
        lib.notify({
            title = 'エラー',
            description = error,
            type = 'error'
        })
        return false
    end
    return true
end

-- サウンド設定コンテキストメニュー
local function ShowSoundContext()
    if not currentConfig.sound then currentConfig.sound = {} end
    local sound = currentConfig.sound
    
    lib.showContext('ng_itemeditor_sound')
end

-- アニメーション設定コンテキストメニュー
local function ShowAnimationContext()
    if not currentConfig.animation then currentConfig.animation = {} end
    local animation = currentConfig.animation
    
    lib.showContext('ng_itemeditor_animation')
end

-- エフェクト設定コンテキストメニュー
local function ShowEffectContext()
    if not currentConfig.effect then currentConfig.effect = {} end
    local effect = currentConfig.effect
    
    lib.showContext('ng_itemeditor_effect')
end

-- 回復設定コンテキストメニュー
local function ShowRecoveryContext()
    if not currentConfig.recovery then currentConfig.recovery = {} end
    local recovery = currentConfig.recovery
    
    lib.showContext('ng_itemeditor_recovery')
end

-- アイテムリストをソート
local function SortItems(itemsList)
    table.sort(itemsList, function(a, b)
        return a.label:lower() < b.label:lower()
    end)
    return itemsList
end

-- アイテムをフィルタリング
local function FilterItems(itemsList, searchText)
    if not searchText or searchText == '' then return itemsList end
    
    local filtered = {}
    searchText = searchText:lower()
    
    for _, item in ipairs(itemsList) do
        if item.label:lower():find(searchText) or item.name:lower():find(searchText) then
            table.insert(filtered, item)
        end
    end
    
    return filtered
end

-- メインコンテキストメニューを表示
local function ShowMainContext(searchText)
    if not GetItems() then return end
    
    -- アイテムをソートしてフィルタリング
    local sortedItems = SortItems(items)
    local filteredItems = FilterItems(sortedItems, searchText)
    
    local options = {
        {
            title = '🔍 検索',
            description = '検索するアイテム名を入力',
            onSelect = function()
                local input = lib.inputDialog('アイテム検索', {
                    { type = 'input', label = '検索キーワード', default = searchText or '' }
                })
                if input then
                    ShowMainContext(input[1])
                end
            end
        }
    }

    -- 検索中の場合、検索解除オプションを追加
    if searchText and searchText ~= '' then
        table.insert(options, {
            title = '❌ 検索解除',
            description = '検索をクリア',
            onSelect = function()
                ShowMainContext()
            end
        })
    end
    
    -- フィルタリングされたアイテムリストを追加
    for _, item in ipairs(filteredItems) do
        table.insert(options, {
            title = item.label,
            description = item.name .. (item.hasConfig and ' (設定済み)' or ''),
            onSelect = function()
                currentItemName = item.name
                if GetItemConfig(item.name) then
                    ShowItemContext()
                end
            end
        })
    end

    lib.registerContext({
        id = 'ng_itemeditor_main',
        title = 'アイテムエディタ',
        options = options
    })
    
    lib.showContext('ng_itemeditor_main')
end

-- アイテム設定コンテキストメニューを表示
local function ShowItemContext()
    if not currentItemName or not currentConfig then return end
    
    lib.registerContext({
        id = 'ng_itemeditor_item',
        title = currentItemName .. ' の設定',
        menu = 'ng_itemeditor_main',
        options = {
            {
                title = 'サウンド設定',
                description = '音声の設定を行う',
                onSelect = function()
                    ShowSoundContext()
                end
            },
            {
                title = 'アニメーション設定',
                description = 'アニメーションの設定を行う',
                onSelect = function()
                    ShowAnimationContext()
                end
            },
            {
                title = 'エフェクト設定',
                description = 'エフェクトの設定を行う',
                onSelect = function()
                    ShowEffectContext()
                end
            },
            {
                title = '回復設定',
                description = '回復効果の設定を行う',
                onSelect = function()
                    ShowRecoveryContext()
                end
            },
            {
                title = '使用後に削除',
                description = '使用後にアイテムを削除するかどうか',
                onSelect = function()
                    currentConfig.removeAfterUse = not currentConfig.removeAfterUse
                    ShowItemContext()
                end,
                metadata = {
                    '現在: ' .. (currentConfig.removeAfterUse and '有効' or '無効')
                }
            },
            {
                title = '設定を保存',
                description = '現在の設定を保存する',
                onSelect = function()
                    if SaveItemConfig(currentItemName, currentConfig) then
                        lib.notify({
                            title = '成功',
                            description = '設定を保存しました',
                            type = 'success'
                        })
                        ShowMainContext()
                    end
                end
            },
            {
                title = '設定を削除',
                description = 'このアイテムの設定を削除する',
                onSelect = function()
                    if DeleteItemConfig(currentItemName) then
                        lib.notify({
                            title = '成功',
                            description = '設定を削除しました',
                            type = 'success'
                        })
                        ShowMainContext()
                    end
                end
            },
            {
                title = 'テスト実行',
                description = 'このアイテムの効果をテストする',
                onSelect = function()
                    TriggerServerEvent('ng-itemeditor:server:useItem', currentItemName)
                end
            }
        }
    })
    
    lib.showContext('ng_itemeditor_item')
end

-- エディタを開く
RegisterNetEvent('ng-itemeditor:client:openEditor', function()
    ShowMainContext()
end)

-- サウンド設定コンテキストメニューの登録
lib.registerContext({
    id = 'ng_itemeditor_sound',
    title = 'サウンド設定',
    menu = 'ng_itemeditor_item',
    options = {
        {
            title = 'サウンドURL',
            description = 'サウンドファイルのURL',
            onSelect = function()
                local input = lib.inputDialog('サウンドURL', {
                    { type = 'input', label = 'URL', default = currentConfig.sound.url or '' }
                })
                if input then
                    currentConfig.sound.url = input[1]
                    ShowSoundContext()
                end
            end
        },
        {
            title = '音量',
            description = '0.0 ～ 1.0',
            onSelect = function()
                local input = lib.inputDialog('音量', {
                    { type = 'number', label = '音量', default = currentConfig.sound.volume or 0.3, min = 0.0, max = 1.0, step = 0.1 }
                })
                if input then
                    currentConfig.sound.volume = input[1]
                    ShowSoundContext()
                end
            end
        },
        {
            title = '最大距離',
            description = '音が聞こえる最大距離',
            onSelect = function()
                local input = lib.inputDialog('最大距離', {
                    { type = 'number', label = '距離', default = currentConfig.sound.maxDistance or 10.0, min = 0.0 }
                })
                if input then
                    currentConfig.sound.maxDistance = input[1]
                    ShowSoundContext()
                end
            end
        },
        {
            title = '遅延時間',
            description = '音声再生までの遅延時間（ミリ秒）',
            onSelect = function()
                local input = lib.inputDialog('遅延時間', {
                    { type = 'number', label = '時間', default = currentConfig.sound.soundDelay or 0, min = 0 }
                })
                if input then
                    currentConfig.sound.soundDelay = input[1]
                    ShowSoundContext()
                end
            end
        },
        {
            title = 'ループ再生',
            description = 'サウンドをループ再生するかどうか',
            onSelect = function()
                currentConfig.sound.loop = not currentConfig.sound.loop
                ShowSoundContext()
            end,
            metadata = {
                '現在: ' .. (currentConfig.sound.loop and '有効' or '無効')
            }
        }
    }
})

-- アニメーション設定コンテキストメニューの登録
lib.registerContext({
    id = 'ng_itemeditor_animation',
    title = 'アニメーション設定',
    menu = 'ng_itemeditor_item',
    options = {
        {
            title = 'アニメーション辞書',
            description = 'アニメーションの種類',
            onSelect = function()
                local options = {}
                for _, dict in ipairs(Config.AnimationDicts) do
                    table.insert(options, dict)
                end
                local input = lib.inputDialog('アニメーション辞書', {
                    { type = 'select', label = '辞書', options = options, default = currentConfig.animation.dict }
                })
                if input then
                    currentConfig.animation.dict = input[1]
                    ShowAnimationContext()
                end
            end
        },
        {
            title = 'アニメーション名',
            description = '例: pill, burger, coffee',
            onSelect = function()
                local input = lib.inputDialog('アニメーション名', {
                    { type = 'input', label = '名前', default = currentConfig.animation.anim or '' }
                })
                if input then
                    currentConfig.animation.anim = input[1]
                    ShowAnimationContext()
                end
            end
        },
        {
            title = 'フラグ',
            description = 'アニメーションフラグ',
            onSelect = function()
                local input = lib.inputDialog('フラグ', {
                    { type = 'number', label = 'フラグ', default = currentConfig.animation.flag or 49 }
                })
                if input then
                    currentConfig.animation.flag = input[1]
                    ShowAnimationContext()
                end
            end
        },
        {
            title = '時間',
            description = 'アニメーション時間（ミリ秒）',
            onSelect = function()
                local input = lib.inputDialog('時間', {
                    { type = 'number', label = '時間', default = currentConfig.animation.duration or 2800, min = 0 }
                })
                if input then
                    currentConfig.animation.duration = input[1]
                    ShowAnimationContext()
                end
            end
        }
    }
})

-- エフェクト設定コンテキストメニューの登録
lib.registerContext({
    id = 'ng_itemeditor_effect',
    title = 'エフェクト設定',
    menu = 'ng_itemeditor_item',
    options = {
        {
            title = 'エフェクトタイプ',
            description = 'エフェクトの種類',
            onSelect = function()
                local options = {}
                for _, effect in ipairs(Config.EffectTypes) do
                    table.insert(options, { label = effect.label, value = effect.value })
                end
                local input = lib.inputDialog('エフェクトタイプ', {
                    { type = 'select', label = 'タイプ', options = options, default = currentConfig.effect.type }
                })
                if input then
                    currentConfig.effect.type = input[1]
                    ShowEffectContext()
                end
            end
        },
        {
            title = '遅延時間',
            description = 'エフェクト発動までの遅延時間（ミリ秒）',
            onSelect = function()
                local input = lib.inputDialog('遅延時間', {
                    { type = 'number', label = '時間', default = currentConfig.effect.delay or 0, min = 0 }
                })
                if input then
                    currentConfig.effect.delay = input[1]
                    ShowEffectContext()
                end
            end
        },
        {
            title = '継続時間',
            description = 'エフェクトの継続時間（ミリ秒）',
            onSelect = function()
                local input = lib.inputDialog('継続時間', {
                    { type = 'number', label = '時間', default = currentConfig.effect.duration or 0, min = 0 }
                })
                if input then
                    currentConfig.effect.duration = input[1]
                    ShowEffectContext()
                end
            end
        }
    }
})

-- 回復設定コンテキストメニューの登録
lib.registerContext({
    id = 'ng_itemeditor_recovery',
    title = '回復設定',
    menu = 'ng_itemeditor_item',
    options = {
        {
            title = 'HP',
            description = '回復するHP量（マイナス可）',
            onSelect = function()
                local input = lib.inputDialog('HP', {
                    { type = 'number', label = 'HP', default = currentConfig.recovery.health or 0 }
                })
                if input then
                    currentConfig.recovery.health = input[1]
                    ShowRecoveryContext()
                end
            end
        },
        {
            title = 'アーマー',
            description = '回復するアーマー量（マイナス可）',
            onSelect = function()
                local input = lib.inputDialog('アーマー', {
                    { type = 'number', label = 'アーマー', default = currentConfig.recovery.armour or 0 }
                })
                if input then
                    currentConfig.recovery.armour = input[1]
                    ShowRecoveryContext()
                end
            end
        },
        {
            title = '食料',
            description = '回復する食料量（マイナス可）',
            onSelect = function()
                local input = lib.inputDialog('食料', {
                    { type = 'number', label = '食料', default = currentConfig.recovery.food or 0 }
                })
                if input then
                    currentConfig.recovery.food = input[1]
                    ShowRecoveryContext()
                end
            end
        },
        {
            title = '水分',
            description = '回復する水分量（マイナス可）',
            onSelect = function()
                local input = lib.inputDialog('水分', {
                    { type = 'number', label = '水分', default = currentConfig.recovery.water or 0 }
                })
                if input then
                    currentConfig.recovery.water = input[1]
                    ShowRecoveryContext()
                end
            end
        },
        {
            title = '時間',
            description = '回復までの時間（ミリ秒）',
            onSelect = function()
                local input = lib.inputDialog('時間', {
                    { type = 'number', label = '時間', default = currentConfig.recovery.time or 0, min = 0 }
                })
                if input then
                    currentConfig.recovery.time = input[1]
                    ShowRecoveryContext()
                end
            end
        },
        {
            title = '即時回復',
            description = 'ONなら即時回復、OFFなら徐々に回復',
            onSelect = function()
                currentConfig.recovery.isInstant = not currentConfig.recovery.isInstant
                ShowRecoveryContext()
            end,
            metadata = {
                '現在: ' .. (currentConfig.recovery.isInstant and '即時回復' or '徐々に回復')
            }
        },
        {
            title = '回復間隔',
            description = '徐々に回復する場合の間隔（ミリ秒）',
            onSelect = function()
                local input = lib.inputDialog('回復間隔', {
                    { type = 'number', label = '間隔', default = currentConfig.recovery.gradualTick or 500, min = 100 }
                })
                if input then
                    currentConfig.recovery.gradualTick = input[1]
                    ShowRecoveryContext()
                end
            end
        }
    }
})