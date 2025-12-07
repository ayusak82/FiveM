local QBCore = exports['qb-core']:GetCoreObject()
local craftingMenuOpen = false
local craftableItems = {}
local playerJob = ''
local createdProps = {}

-- グローバル関数として定義
-- ターゲットゾーンを設定する関数
SetupCraftingZones = function()
    --print('ターゲットゾーンを設定中...')
    
    for k, v in pairs(Config.CraftingLocations) do
        --print('ターゲットゾーン作成: #' .. k .. ' ' .. tostring(v.coords))
        local success = pcall(function()
            exports.ox_target:addSphereZone({
                coords = v.coords,
                radius = v.radius or 1.5,
                debug = v.debug or false,
                options = {
                    {
                        name = 'crafting_zone_' .. k,
                        icon = 'fas fa-hammer',
                        label = 'クラフトする',
                        onSelect = function()
                            OpenCraftingMenu()
                        end,
                        canInteract = function()
                            -- 常にインタラクション可能
                            return true
                        end,
                    }
                }
            })
        end)
        
        if success then
            --print('クラフトポイント #' .. k .. ' のターゲットゾーン作成成功')
        else
            --print('クラフトポイント #' .. k .. ' のターゲットゾーン作成失敗')
        end
    end
end

-- 最大クラフト可能数を計算する関数
local function CalculateMaxCraftable(requiredItems)
    local maxCraftable = 0
    
    for i, item in ipairs(requiredItems) do
        -- ox_inventoryでアイテム所持数を確認
        local count = exports.ox_inventory:Search('count', item.name)
        local possibleCrafts = math.floor(count / item.amount)
        
        -- 初回の場合は現在の値を設定、それ以降は最小値を選択
        if i == 1 then
            maxCraftable = possibleCrafts
        else
            maxCraftable = math.min(maxCraftable, possibleCrafts)
        end
    end
    
    return maxCraftable
end

-- クラフトメニューを開く関数（グローバル関数）
OpenCraftingMenu = function()
    if craftingMenuOpen then return end
    
    -- 強制的に最新データを取得
    TriggerServerEvent('ng-crafting:server:RequestCraftableItems', playerJob)
    Citizen.Wait(300) -- サーバーからの応答を少し待つ
    
    -- アイテムがなければ通知して終了
    if not craftableItems or #craftableItems == 0 then
        lib.notify({
            title = 'クラフト',
            description = 'あなたのジョブ(' .. playerJob .. ')でクラフト可能なアイテムはありません',
            type = 'error'
        })
        
        if Config.Debug then
            --print('クラフトメニュー: アイテムなし。ジョブ = ' .. playerJob)
        end
        return
    end
    
    craftingMenuOpen = true
    
    -- メニューオプションの作成
    local options = {}
    
    for _, item in pairs(craftableItems) do
        -- 無効なアイテムをスキップ
        if not item or not item.name then
            if Config.Debug then
                --print('無効なアイテムデータをスキップ: ' .. json.encode(item))
            end
            goto continue
        end
        
        -- アイテムタイプと必要素材を取得
        local itemType = item.type or 'normal'
        
        -- タイプが存在するか確認
        if not Config.ItemTypes[itemType] then
            if Config.Debug then
                --print('警告: 未定義のアイテムタイプ: ' .. itemType .. '、デフォルトを使用')
            end
            itemType = 'normal'
        end
        
        local requiredItems = Config.ItemTypes[itemType].requiredItems
        
        -- 最大クラフト可能数を計算
        local maxCraftable = CalculateMaxCraftable(requiredItems)
        
        -- クラフト可能かどうかをチェック（最大可能数が0以上）
        local canCraft = maxCraftable > 0
        
        -- **修正: 素材の有無に関係なく全てのアイテムを表示**
        local option = {
            title = item.label or item.name,
            description = canCraft 
                and '素材を使ってクラフトします (最大' .. maxCraftable .. '個作成可能)' 
                or '必要な素材が足りません',
            icon = canCraft and 'fas fa-hammer' or 'fas fa-ban',
            disabled = not canCraft, -- 素材が足りない場合は無効化
            onSelect = function()
                -- クラフト個数を選択するためのダイアログを表示
                if canCraft then
                    local input = lib.inputDialog('クラフト個数選択', {
                        {
                            type = 'number',
                            label = '作成個数',
                            description = '作成する個数を選択してください (最大' .. maxCraftable .. '個)',
                            required = true,
                            min = 1,
                            max = maxCraftable,
                            default = 1
                        }
                    })
                    
                    if input and input[1] then
                        local amount = tonumber(input[1])
                        
                        if amount and amount > 0 and amount <= maxCraftable then
                            -- 素材確認とクラフト処理
                            local animDict = Config.ItemTypes[itemType].animDict
                            local anim = Config.ItemTypes[itemType].anim
                            local flags = Config.ItemTypes[itemType].flags
                            local duration = Config.ItemTypes[itemType].progressBarDuration
                            
                            -- アニメーション読み込み
                            lib.requestAnimDict(animDict)
                            
                            -- 個数に応じてプログレスバー時間を調整
                            local scaledDuration = duration * amount
                            
                            -- プログレスバー表示
                            if lib.progressBar({
                                duration = scaledDuration,
                                label = (Config.ItemTypes[itemType].label or (item.label .. 'を作成中...')) .. ' (' .. amount .. '個)',
                                useWhileDead = false,
                                canCancel = true,
                                disable = {
                                    car = true,
                                    move = true,
                                    combat = true
                                },
                                anim = {
                                    dict = animDict,
                                    clip = anim,
                                    flags = flags
                                },
                            }) then
                                -- プログレスバー完了後、サーバーにクラフト要求
                                TriggerServerEvent('ng-crafting:server:CraftItem', item.name, itemType, amount)
                            else
                                -- キャンセルされた場合
                                lib.notify({
                                    title = 'クラフト',
                                    description = 'クラフトをキャンセルしました',
                                    type = 'error'
                                })
                            end
                        else
                            lib.notify({
                                title = 'クラフト',
                                description = '無効な個数が指定されました',
                                type = 'error'
                            })
                        end
                    end
                else
                    lib.notify({
                        title = 'クラフト',
                        description = '必要な素材が足りません',
                        type = 'error'
                    })
                end
            end,
            metadata = {
                -- メタデータには必要素材情報を表示
                {label = 'タイプ', value = itemType}
            }
        }
        
        -- 素材情報をメタデータに追加
        if Config.ItemTypes[itemType] and Config.ItemTypes[itemType].requiredItems then
            for _, reqItem in ipairs(Config.ItemTypes[itemType].requiredItems) do
                -- ox_inventoryで所持数を確認
                local ownedCount = exports.ox_inventory:Search('count', reqItem.name)
                
                -- 素材の所持数と必要数を表示（色付きで）
                local statusColor = ownedCount >= reqItem.amount and "緑" or "赤"
                local statusIcon = ownedCount >= reqItem.amount and "✓" or "✗"
                
                table.insert(option.metadata, {
                    label = '必要: ' .. reqItem.name,
                    value = ownedCount .. '/' .. reqItem.amount .. '個 ' .. statusIcon,
                    progress = math.min(100, math.floor((ownedCount / reqItem.amount) * 100))
                })
            end
        end
        
        table.insert(options, option)
        
        ::continue::
    end
    
    -- アイテムが1つも表示できない場合
    if #options == 0 then
        lib.notify({
            title = 'クラフト',
            description = 'このジョブでクラフト可能なアイテムが定義されていません。',
            type = 'error'
        })
        craftingMenuOpen = false
        return
    end
    
    -- メニュー表示
    lib.registerContext({
        id = 'crafting_menu',
        title = 'クラフトシステム - ' .. playerJob,
        options = options
    })
    
    lib.showContext('crafting_menu')
    craftingMenuOpen = false
end

-- プロップを生成する関数
local function CreateLocationProp(location, index)
    if not location.prop or not location.prop.model then return end
    
    -- プロップモデルをリクエスト
    local modelHash = GetHashKey(location.prop.model)
    
    --print('プロップモデルをリクエスト: ' .. location.prop.model .. ' (' .. modelHash .. ')')
    
    RequestModel(modelHash)
    local startTime = GetGameTimer()
    local timeout = false
    
    -- モデルのロードを待機（最大5秒）
    while not HasModelLoaded(modelHash) do
        Wait(10)
        if GetGameTimer() - startTime > 5000 then
            --print('モデルのロードがタイムアウトしました: ' .. location.prop.model)
            timeout = true
            break
        end
    end
    
    if timeout then
        return
    end
    
    -- プロップ位置を計算（オフセット適用）
    local propPos = vector3(
        location.coords.x + (location.prop.offset and location.prop.offset.x or 0),
        location.coords.y + (location.prop.offset and location.prop.offset.y or 0),
        location.coords.z + (location.prop.offset and location.prop.offset.z or 0)
    )
    
    --print('プロップを生成: ' .. location.prop.model .. ' 位置: ' .. tostring(propPos))
    
    -- プロップを生成
    local prop = CreateObject(
        modelHash,
        propPos.x, propPos.y, propPos.z,
        true, false, false
    )
    
    if not DoesEntityExist(prop) then
        --print('プロップの生成に失敗しました: ' .. location.prop.model)
        SetModelAsNoLongerNeeded(modelHash)
        return
    end
    
    -- 回転を設定
    if location.prop.rotation then
        SetEntityRotation(prop, 
            location.prop.rotation.x, 
            location.prop.rotation.y, 
            location.prop.rotation.z, 
            2, 
            true
        )
    end
    
    -- プロップを固定
    if location.prop.frozen == nil or location.prop.frozen then
        FreezeEntityPosition(prop, true)
    end
    
    -- コリジョンを設定（他のオブジェクトとの衝突を無効）
    SetEntityCollision(prop, false, true)
    
    -- 生成したプロップを保存
    createdProps[index] = prop
    
    --print('プロップを正常に生成しました: ' .. location.prop.model .. ' エンティティID: ' .. prop)
    
    -- モデルをメモリから解放
    SetModelAsNoLongerNeeded(modelHash)
    
    return prop
end

-- プロップを再生成するコマンド
RegisterCommand('recreate_props', function()
    --print('プロップの再生成を開始します...')
    
    -- 既存のプロップをクリア
    for _, prop in pairs(createdProps) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
    createdProps = {}
    
    -- プロップを再生成
    for k, v in pairs(Config.CraftingLocations) do
        if v.prop and v.prop.model then
            Citizen.SetTimeout(500 * k, function()
                local prop = CreateLocationProp(v, k)
                if prop and DoesEntityExist(prop) then
                    --print('プロップ再生成成功: ' .. v.prop.model)
                else
                    --print('プロップ再生成失敗: ' .. v.prop.model)
                end
            end)
        end
    end
end, false)

-- ターゲットゾーンを再設定するコマンド
RegisterCommand('reset_craft_zones', function()
    --print('クラフトゾーンをリセットします...')
    
    -- 既存のターゲットゾーンを削除（エラーハンドリング付き）
    for k, v in pairs(Config.CraftingLocations) do
        pcall(function()
            exports.ox_target:removeZone('crafting_zone_' .. k)
        end)
    end
    
    -- ターゲットゾーンを再設定
    Wait(500)
    SetupCraftingZones()
    
    lib.notify({
        title = 'クラフトシステム',
        description = 'ターゲットゾーンをリセットしました',
        type = 'success'
    })
end, false)

-- サーバーからのクラフト可能なアイテムリスト受信イベント
RegisterNetEvent('ng-crafting:client:ReceiveCraftableItems', function(items)
    if items then
        craftableItems = items
        if Config.Debug then
            --print('クラフト可能アイテムを受信: ' .. json.encode(craftableItems))
        end
    else
        craftableItems = {}
        if Config.Debug then
            --print('クラフト可能アイテムなし')
        end
    end
end)

-- クラフト処理完了イベント
RegisterNetEvent('ng-crafting:client:CraftComplete', function(success, itemName, amount)
    if success then
        lib.notify({
            title = 'クラフト成功',
            description = itemName .. ' x' .. amount .. 'を作成しました',
            type = 'success'
        })
        
        -- インベントリを更新（サーバー側での追加を反映）
        if DoesEntityExist(PlayerPedId()) then
            TriggerServerEvent('inventory:server:OpenInventory')
            Wait(500)
            
            -- 大量のアイテムを追加した場合に通知が多くなりすぎないように
            if amount <= 5 then
                for i=1, amount do
                    Wait(50) -- 少し待ってアニメーションが重ならないように
                    TriggerEvent('inventory:client:ItemBox', QBCore.Shared.Items[itemName], 'add', 1)
                end
            else
                -- 大量の場合はまとめて表示
                TriggerEvent('inventory:client:ItemBox', QBCore.Shared.Items[itemName], 'add', amount)
            end
        end
        
        -- クラフトメニューは自動的に再開しない（不要なクラフトを防止するため）
        -- メニューを再開したい場合は再度インタラクションする必要がある
    else
        lib.notify({
            title = 'クラフト失敗',
            description = '必要なアイテムが不足しています',
            type = 'error'
        })
    end
end)

-- ジョブ更新イベント
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerJob = job.name
    
    if Config.Debug then
        --print('ジョブ更新: 新しいジョブ = ' .. playerJob)
    end
    
    -- ジョブが変わったらサーバーからクラフト可能なアイテムを取得
    TriggerServerEvent('ng-crafting:server:RequestCraftableItems', playerJob)
end)

-- プレイヤースポーン時の処理
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    -- プレイヤーがスポーンするまで少し待つ
    Wait(3000)
    
    -- プレイヤーデータ取得（安全にチェック）
    local player = QBCore.Functions.GetPlayerData()
    if player and player.job and player.job.name then
        playerJob = player.job.name
    else
        playerJob = 'unemployed'
        --print('プレイヤーロード: ジョブデータなし、デフォルト値使用')
    end
    
    --print('プレイヤーロード: ジョブ = ' .. playerJob)
    
    -- クラフト可能アイテムリストを要求
    TriggerServerEvent('ng-crafting:server:RequestCraftableItems', playerJob)
    
    --print('プレイヤースポーン後の初期化完了')
end)

-- 定期的に手動で更新を要求（フォールバックメカニズム）
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(30000) -- 30秒ごとに更新
        
        -- 現在のプレイヤーデータを取得
        local player = QBCore.Functions.GetPlayerData()
        if player and player.job and player.job.name then
            if playerJob ~= player.job.name then
                playerJob = player.job.name
                if Config.Debug then
                    --print('定期更新: ジョブ変更検出 = ' .. playerJob)
                end
                TriggerServerEvent('ng-crafting:server:RequestCraftableItems', playerJob)
            elseif #craftableItems == 0 then
                -- アイテムがまだロードされていない場合は再要求
                if Config.Debug then
                    --print('定期更新: アイテムなし、再要求')
                end
                TriggerServerEvent('ng-crafting:server:RequestCraftableItems', playerJob)
            end
        else
            -- プレイヤーデータがまだロードされていない場合はスキップ
            if Config.Debug then
                --print('定期更新: プレイヤーデータ未ロード、スキップ')
            end
        end
    end
end)

-- クラフトポイント作成
Citizen.CreateThread(function()
    -- 他のリソースが読み込まれるのを少し待つ
    Wait(2000)
    
    --print('クラフトポイントの初期化を開始します...')
    
    -- プレイヤーのジョブ情報を最初に取得（安全にチェック）
    local player = QBCore.Functions.GetPlayerData()
    if player and player.job and player.job.name then
        playerJob = player.job.name
        TriggerServerEvent('ng-crafting:server:RequestCraftableItems', playerJob)
    else
        -- ジョブデータがまだない場合はデフォルト値を設定
        playerJob = 'unemployed'
        --print('ジョブデータが未ロード、デフォルト値を使用: ' .. playerJob)
    end
    
    -- クラフトポイントの設定
    for k, v in pairs(Config.CraftingLocations) do
        --print('クラフトポイント #' .. k .. ' を処理中: ' .. tostring(v.coords))
        
        -- プロップの生成
        if v.prop and v.prop.model then
            --print('プロップ生成を試行: ' .. v.prop.model)
            
            -- プロップ生成は少し遅延させて確実に実行
            Citizen.SetTimeout(1000 * k, function()
                local prop = CreateLocationProp(v, k)
                if prop and DoesEntityExist(prop) then
                    --print('クラフトポイント #' .. k .. ' のプロップ生成成功')
                else
                    --print('クラフトポイント #' .. k .. ' のプロップ生成失敗')
                end
            end)
        end
        
        -- デバッグモードならスフィア表示
        if v.debug then
            Citizen.CreateThread(function()
                while true do
                    DrawMarker(28, v.coords.x, v.coords.y, v.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.radius, v.radius, v.radius, 255, 0, 0, 100, false, false, 0, false)
                    Citizen.Wait(0)
                end
            end)
        end
    end
    
    -- ターゲットゾーンを設定
    Wait(1000) -- プロップ生成を少し待つ
    SetupCraftingZones()
    
    --print('クラフトポイントの初期化が完了しました')
end)

-- リソース終了時にプロップを削除
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    --print('プロップのクリーンアップを開始します...')
    
    -- 生成したすべてのプロップを削除
    for _, prop in pairs(createdProps) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
end)

-- デバッグコマンド
if Config.Debug then
    RegisterCommand('craftdebug', function()
        --print('現在のジョブ: ' .. playerJob)
        --print('クラフト可能アイテム: ' .. json.encode(craftableItems))
    end, false)
end