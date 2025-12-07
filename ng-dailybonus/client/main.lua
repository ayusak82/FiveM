local QBCore = exports['qb-core']:GetCoreObject()

-- 利用可能なボーナス情報を保存
local availableBonuses = {}

-- 初期化
CreateThread(function()
    Wait(1000)
    if Config.Debug then
        print('[ng-dailybonus] クライアント初期化完了')
    end
end)

-- デイリーボーナスメニューを開く
local function OpenDailyBonusMenu()
    if Config.Debug then
        print('[ng-dailybonus] メニューを開いています...')
    end
    
    -- サーバーから利用可能なボーナス情報を取得
    TriggerServerEvent('ng-dailybonus:server:getAvailableBonuses')
end

-- メニューを表示する
local function ShowBonusMenu(bonuses)
    if not bonuses or #bonuses == 0 then
        lib.notify({
            title = Config.Notifications.error.title,
            description = '利用可能なボーナスがありません',
            type = Config.Notifications.error.type,
            duration = Config.Notifications.error.duration
        })
        return
    end
    
    local menuOptions = {}
    
    for _, bonus in pairs(bonuses) do
        local description = bonus.description
        local metadata = {}
        
        if not bonus.canClaim then
            table.insert(metadata, {
                label = '状態',
                value = '⏰ ' .. bonus.remainingTime
            })
        else
            table.insert(metadata, {
                label = '状態',
                value = '✅ 受け取り可能'
            })
            
            -- 報酬リストを追加
            for _, reward in pairs(bonus.rewards) do
                table.insert(metadata, {
                    label = reward.label,
                    value = 'x' .. reward.amount
                })
            end
        end
        
        table.insert(menuOptions, {
            title = bonus.name,
            description = description,
            metadata = metadata,
            disabled = not bonus.canClaim,
            onSelect = function()
                if bonus.canClaim then
                    -- 確認ダイアログを表示
                    local input = lib.alertDialog({
                        header = 'ボーナス受け取り確認',
                        content = '「' .. bonus.name .. '」を受け取りますか？',
                        centered = true,
                        cancel = true
                    })
                    
                    if input == 'confirm' then
                        TriggerServerEvent('ng-dailybonus:server:claimBonus', bonus.id)
                        lib.hideContext()
                        
                        -- 少し待ってからメニューを再度開く
                        CreateThread(function()
                            Wait(1500)
                            OpenDailyBonusMenu()
                        end)
                    end
                end
            end
        })
    end
    
    -- 更新オプションを追加
    table.insert(menuOptions, {
        title = '更新',
        description = 'ボーナス状況を更新します',
        icon = 'refresh',
        onSelect = function()
            lib.hideContext()
            OpenDailyBonusMenu()
        end
    })
    
    lib.registerContext({
        id = 'ng_dailybonus_menu',
        title = Config.UI.title,
        options = menuOptions
    })
    
    lib.showContext('ng_dailybonus_menu')
end

-- サーバーからボーナス情報を受信
RegisterNetEvent('ng-dailybonus:client:receiveAvailableBonuses', function(bonuses)
    availableBonuses = bonuses
    ShowBonusMenu(bonuses)
    
    if Config.Debug then
        print('[ng-dailybonus] ' .. #bonuses .. '個のボーナスを受信しました')
    end
end)

-- コマンド登録
RegisterCommand(Config.Command, function()
    OpenDailyBonusMenu()
end, false)

-- チャットでコマンドの説明を表示
TriggerEvent('chat:addSuggestion', '/' .. Config.Command, 'デイリーボーナスメニューを開く')

-- キーマッピング（オプション）
-- RegisterKeyMapping(Config.Command, 'デイリーボーナスメニューを開く', 'keyboard', '')

-- プレイヤーがスポーンした時の処理
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    if Config.Debug then
        print('[ng-dailybonus] プレイヤーがロードされました')
    end
    
    -- 初回ログイン時に通知を表示（オプション）
    lib.notify({
        title = 'デイリーボーナス',
        description = '/' .. Config.Command .. ' でデイリーボーナスを受け取れます！',
        type = 'inform',
        duration = 5000
    })
end)

-- 定期的な更新（オプション）
-- 5分ごとにボーナス状況をチェック
CreateThread(function()
    while true do
        Wait(300000) -- 5分 = 300秒
        
        -- メニューが開いている場合のみ更新
        if lib.getOpenContextMenu() == 'ng_dailybonus_menu' then
            if Config.Debug then
                print('[ng-dailybonus] 定期更新を実行中...')
            end
            TriggerServerEvent('ng-dailybonus:server:getAvailableBonuses')
        end
    end
end)

-- デバッグ用関数
if Config.Debug then
    RegisterCommand('debugdailybonus', function()
        print('=== ng-dailybonus デバッグ情報 ===')
        print('コマンド: /' .. Config.Command)
        print('利用可能ボーナス数: ' .. #availableBonuses)
        print('Discord連携: ' .. tostring(Config.Discord.enabled))
        print('基本ボーナス: ' .. tostring(Config.BasicBonus.enabled))
        print('ロールボーナス数: ' .. #Config.RoleBonuses)
        print('==============================')
    end, false)
end

-- エクスポート関数（他のスクリプトから使用可能）
exports('OpenDailyBonusMenu', OpenDailyBonusMenu)
exports('GetAvailableBonuses', function()
    return availableBonuses
end)
exports('IsMenuOpen', function()
    return lib.getOpenContextMenu() == 'ng_dailybonus_menu'
end)

-- ===== EVENTS =====

-- 外部スクリプトからメニューを開くイベント
RegisterNetEvent('ng-dailybonus:client:openMenu', function()
    OpenDailyBonusMenu()
end)

-- 外部スクリプトから特定のボーナス情報を受信するイベント
RegisterNetEvent('ng-dailybonus:client:receiveBonusInfo', function(bonusInfo)
    if Config.Debug then
        print('[ng-dailybonus] ボーナス情報受信: ' .. json.encode(bonusInfo))
    end
    -- 必要に応じて他のスクリプトにトリガー
    TriggerEvent('ng-dailybonus:bonusInfoReceived', bonusInfo)
end)

-- 外部スクリプトから通知を表示するイベント
RegisterNetEvent('ng-dailybonus:client:notify', function(title, description, type, duration)
    lib.notify({
        title = title or 'デイリーボーナス',
        description = description or '',
        type = type or 'inform',
        duration = duration or 3000
    })
end)