local QBCore = exports['qb-core']:GetCoreObject()
local isCrafting = false
local craftZones = {}
local policeBlips = {}

-- プレイヤーが作業可能な状態かチェック
local function canCraft()
    -- 警察ジョブのチェックを追加
    local Player = QBCore.Functions.GetPlayerData()
    if Player and Player.job and Player.job.name and Player.job.name == Config.PoliceAlert.job then
        return false, '警察官は製造できません'
    end

    if IsPedDeadOrDying(cache.ped) then 
        return false, '意識がありません'
    end
    if cache.vehicle then 
        return false, '車両に乗っている間は製造できません'
    end
    return true
end

-- 警察通報機能
local function alertPolice(coords, craftLabel)
    if not Config.PoliceAlert.enabled then return end
    
    TriggerServerEvent('ng-drugscraft:server:alertPolice', coords, craftLabel)
end

-- 爆発生成関数
local function createExplosion(coords)
    local explosion = Config.Explosion or {}
    AddExplosion(
        coords.x, 
        coords.y, 
        coords.z, 
        explosion.type or 34, 
        explosion.damage or 1.0, 
        explosion.isAudible or true, 
        explosion.isInvisible or false, 
        explosion.cameraShake or 1.0
    )
end

-- 警察ブリップの作成
RegisterNetEvent('ng-drugscraft:client:createPoliceBlip', function(coords, craftLabel)
    -- ブリップを作成
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, Config.PoliceAlert.blipSprite)
    SetBlipColour(blip, Config.PoliceAlert.blipColor)
    SetBlipScale(blip, Config.PoliceAlert.blipScale)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.PoliceAlert.notifyTitle)
    EndTextCommandSetBlipName(blip)
    
    -- 通知音を再生
    if Config.PoliceAlert.soundName and Config.PoliceAlert.soundRef then
        PlaySoundFrontend(-1, Config.PoliceAlert.soundName, Config.PoliceAlert.soundRef, false)
    end
    
    -- 通知を表示
    lib.notify({
        title = Config.PoliceAlert.notifyTitle,
        description = Config.PoliceAlert.notifyDesc .. ' (場所: ' .. craftLabel .. ')',
        type = 'inform',
        position = 'top-right',
        duration = 10000, -- 10秒間表示
        style = {
            backgroundColor = '#c0392b',
            color = '#ffffff'
        },
        icon = 'fas fa-exclamation-triangle'
    })
    
    -- ブリップを保存して一定時間後に削除
    table.insert(policeBlips, {blip = blip, time = GetGameTimer() + (Config.PoliceAlert.blipTime * 1000)})
end)

-- ブリップの管理用スレッド
CreateThread(function()
    while true do
        Wait(1000)
        local currentTime = GetGameTimer()
        local temp = {}
        
        for i, blipData in ipairs(policeBlips) do
            if currentTime < blipData.time then
                table.insert(temp, blipData)
            else
                RemoveBlip(blipData.blip)
            end
        end
        
        policeBlips = temp
    end
end)

-- クラフトポイントのゾーンを作成
CreateThread(function()
    for k, v in pairs(Config.CraftPoints) do
        -- クラフトゾーンの作成
        craftZones[k] = {
            coords = v.coords,
            label = v.label
        }
    end
end)

-- マーカー描画用スレッド
CreateThread(function()
    -- プレイヤーデータのロードを待つ
    local attempts = 0
    local maxAttempts = 100 -- 10秒間試行
    
    while attempts < maxAttempts do
        local PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData and PlayerData.job then
            break
        end
        attempts = attempts + 1
        Wait(100)
    end
    
    while true do
        local sleep = 1000
        local playerPos = GetEntityCoords(cache.ped)
        local Player = QBCore.Functions.GetPlayerData()
        local isPolice = Player and Player.job and Player.job.name and Player.job.name == Config.PoliceAlert.job

        for k, v in pairs(Config.CraftPoints) do
            local distance = #(playerPos - v.coords)
            if distance < 10.0 then
                sleep = 0
                
                -- マーカー描画
                DrawMarker(1, v.coords.x, v.coords.y, v.coords.z - 1.0, 
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                    2.0, 2.0, 1.0, -- サイズ
                    200, 20, 20, 180, -- 色 (RGBA) - 青色
                    false, false, 2, false, nil, nil, false)
                
                -- 近くにいる場合はHelpTextを表示
                if distance < 2.0 then
                    -- BeginTextCommandDisplayHelp を使用して日本語対応テキスト表示
                    if isPolice then
                        -- 警察官の場合のメッセージ
                        AddTextEntry('CRAFT_POLICE_TEXT', '~r~警察官は製造できません')
                        BeginTextCommandDisplayHelp('CRAFT_POLICE_TEXT')
                        EndTextCommandDisplayHelp(0, false, true, -1)
                    else
                        -- 通常のプレイヤー向けメッセージ
                        AddTextEntry('CRAFT_HELP_TEXT', '~INPUT_CONTEXT~ ' .. v.label .. 'を利用する')
                        BeginTextCommandDisplayHelp('CRAFT_HELP_TEXT')
                        EndTextCommandDisplayHelp(0, false, true, -1)
                        
                        -- Eキーの監視
                        if IsControlJustReleased(0, 38) and not isCrafting then -- Eキー
                            openCraftMenu(k)
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- プレイヤーがクラフトゾーン内にいるかチェック
local function isPlayerInCraftZone()
    local can, reason = canCraft()
    if not can then return false, reason end
    
    local playerCoords = GetEntityCoords(cache.ped)
    for k, zone in pairs(craftZones) do
        local distance = #(playerCoords - zone.coords)
        if distance <= 2.0 then
            return k
        end
    end
    return false
end

-- 薬物製造のメニューを表示する関数
function openCraftMenu(craftPointKey)
    local craftPoint = Config.CraftPoints[craftPointKey]
    if not craftPoint then return end

    -- 製造可能なアイテムのみをメニューに表示
    local options = {}
    -- インベントリの取得はもう必要ない（上で修正した関数でox_inventory:Searchを直接使用）
    
    -- アイテムを集計する関数（ox_inventoryの仕様に合わせて修正）
    local function countPlayerItems(itemName)
        local count = exports.ox_inventory:GetItemCount(itemName)
        return count or 0
    end
    
    for recipeId, recipe in pairs(Config.CraftRecipes) do
        -- 材料の所持確認と表示用テキスト作成
        local ingredientsText = ""
        local canCraftMax = 999 -- 理論上の最大数
        
        for _, ingredient in ipairs(recipe.ingredients) do
            local playerAmount = countPlayerItems(ingredient.item)
            local maxCraftable = math.floor(playerAmount / ingredient.amount)
            canCraftMax = math.min(canCraftMax, maxCraftable)
            
            -- 材料の所持数の情報を追加（シンプルに）
            local statusIcon = playerAmount >= ingredient.amount and "✓" or "✗"
            ingredientsText = ingredientsText .. string.format("%s x%d (%d/%d) %s\n", 
                ingredient.item, ingredient.amount, playerAmount, ingredient.amount, statusIcon)
        end
        
        -- 製造可能な最大数
        local maxText = string.format("最大製造可能数: %d個", canCraftMax)
        
        -- メニューに追加
        table.insert(options, {
            title = recipe.label,
            description = ingredientsText .. "\n\n" .. maxText,
            disabled = canCraftMax <= 0,
            onSelect = function()
                if canCraftMax <= 0 then
                    lib.notify({
                        title = '製造不可',
                        description = '必要な材料が足りません',
                        type = 'error'
                    })
                    return
                end
                
                -- 製造数量の入力ダイアログ（改善版）
                local input = lib.inputDialog('製造数を選択', {
                    {
                        type = 'number',
                        label = '製造数',
                        description = '製造する数量を入力してください（最大 ' .. canCraftMax .. ' 個）',
                        default = 1,
                        min = 1,
                        max = canCraftMax,
                        required = true
                    }
                })
                
                if input and input[1] then
                    -- 入力を数値として処理
                    local craftAmount = tonumber(input[1])
                    -- 数値変換できて、かつ範囲内かチェック
                    if craftAmount and craftAmount > 0 and craftAmount <= canCraftMax then
                        -- 警察官の人数をサーバーに確認してから製造開始
                        TriggerServerEvent('ng-drugscraft:server:checkPoliceCount')
                        
                        -- 警察官数チェック後に製造開始
                        local result = nil
                        local hasChecked = false
                        
                        CreateThread(function()
                            local tries = 0
                            while tries < 50 and not hasChecked do -- 最大5秒待機
                                Wait(100)
                                tries = tries + 1
                            end
                        end)
                        
                        RegisterNetEvent('ng-drugscraft:client:policeCountResult', function(currentCops, requiredCops)
                            hasChecked = true
                            if currentCops >= requiredCops then
                                -- 製造開始（数値変換したものを使用）
                                local numAmount = tonumber(craftAmount)
                                print("Client sending amount:", numAmount)
                                startCrafting(recipeId, numAmount, craftPointKey)
                            else
                                lib.notify({
                                    title = '製造不可',
                                    description = string.format('警察官が%d人以上いないと製造できません（現在%d人）', requiredCops, currentCops),
                                    type = 'error'
                                })
                            end
                        end)
                    end
                end
            end
        })
    end
    
    -- メニュー表示
    lib.registerContext({
        id = 'craft_menu',
        title = craftPoint.label,
        options = options
    })
    
    lib.showContext('craft_menu')
end

-- ミニゲームを実行する関数
local function playMinigame(difficulty, minigameCount)
    minigameCount = minigameCount or 1 -- デフォルト値の設定
    
    for i = 1, minigameCount do
        -- 死亡チェック
        if IsPedDeadOrDying(cache.ped) or IsEntityDead(cache.ped) then
            return false
        end
        
        lib.notify({
            title = 'ミニゲーム',
            description = string.format('ミニゲーム %d/%d を開始します', i, minigameCount),
            type = 'inform'
        })
        
        Wait(1000) -- 少し待機
        
        -- difficultyパラメータが正しいか確認
        if type(difficulty) ~= "table" then
            difficulty = {'medium'} -- デフォルト値を設定
        end
        
        local success = lib.skillCheck(difficulty)
        if not success then
            return false
        end
        
        -- 複数回のミニゲームがある場合は少し待機
        if i < minigameCount then Wait(1000) end
    end
    
    return true
end

-- 製造処理の実行
function startCrafting(recipeId, amount, craftPointKey)
    if isCrafting then return end
    
    local can, reason = canCraft()
    if not can then
        lib.notify({
            title = '製造不可',
            description = reason,
            type = 'error'
        })
        return
    end

    local recipe = Config.CraftRecipes[recipeId]
    local craftPoint = Config.CraftPoints[craftPointKey]
    if not recipe or not craftPoint then return end

    isCrafting = true
    
-- ミニゲームの実行（失敗したら爆発＋警察通報）
    if Config.MiniGame and Config.MiniGame.enabled then
        -- 死亡チェック
        if IsPedDeadOrDying(cache.ped) or IsEntityDead(cache.ped) then
            isCrafting = false
            return
        end

        -- レシピに設定されたミニゲーム回数を取得（デフォルト1回）
        local minigameCount = recipe.minigameCount or 1
        local difficulty = Config.MiniGame.difficulty or {'medium'}
        
        -- 指定回数分ミニゲームを実行
        for i = 1, minigameCount do
            -- ミニゲーム開始の通知
            lib.notify({
                title = 'ミニゲーム',
                description = string.format('ミニゲーム %d/%d を開始します', i, minigameCount),
                type = 'inform'
            })
            
            Wait(1000) -- 少し待機
            
            -- ミニゲームの実行
            local success = lib.skillCheck(difficulty)
            if not success then
                -- ミニゲーム失敗時
                lib.notify({
                    title = '製造失敗',
                    description = '薬品が不安定になっています！',
                    type = 'error'
                })
                
                -- 一定確率で爆発（デフォルト100%）
                local explosionChance = Config.Explosion and Config.Explosion.explosionChance or 100
                if math.random(1, 100) <= explosionChance then
                    Wait(1000) -- 少し待機してから爆発
                    
                    local playerCoords = GetEntityCoords(cache.ped)
                    createExplosion(playerCoords)
                    
                    -- 警察への通報
                    alertPolice(playerCoords, craftPoint.label)
                    
                    lib.notify({
                        title = '爆発',
                        description = '化学反応が暴走して爆発しました！',
                        type = 'error'
                    })
                end
                
                isCrafting = false
                return
            end
            
            -- 次のミニゲームの前に少し待機（最後のゲーム以外）
            if i < minigameCount then
                Wait(1000)
            end
        end
            
        -- すべてのミニゲーム成功時
        lib.notify({
            title = 'ミニゲーム成功',
            description = '製造を続行します',
            type = 'success'
        })
    end

    -- 死亡チェック
    if IsPedDeadOrDying(cache.ped) or IsEntityDead(cache.ped) then
        isCrafting = false
        return
    end

    -- アニメーション再生
    lib.requestAnimDict(Config.CraftAnimation.dict)
    TaskPlayAnim(cache.ped, Config.CraftAnimation.dict, Config.CraftAnimation.anim, 8.0, -8.0, -1, 1, 0, false, false, false)

    -- プログレスバーの表示（製造数に応じて時間を調整）
    local craftTime = recipe.time * amount
    if lib.progressBar({
        duration = craftTime,
        label = recipe.label .. ' x' .. amount .. ' を製造中...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
    }) then
        -- 死亡チェック
        if IsPedDeadOrDying(cache.ped) or IsEntityDead(cache.ped) then
            ClearPedTasks(cache.ped)
            isCrafting = false
            return
        end

        -- サーバーへアイテム交換処理を依頼
        local numAmount = tonumber(amount)
        print("Sending to server, amount:", numAmount)
        TriggerServerEvent('ng-drugscraft:server:craftItem', recipeId, numAmount)
    else
        -- キャンセルされた場合
        ClearPedTasks(cache.ped)
        lib.notify({
            title = '製造中断',
            description = '製造をキャンセルしました',
            type = 'error'
        })
    end
    
    ClearPedTasks(cache.ped)
    isCrafting = false
end

-- リソース再起動時のリセット
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    Wait(1000) -- Configのロードを待つ
    isCrafting = false
end)

-- プレイヤーがスポーンした時のリセット
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    isCrafting = false
end)

-- ジョブが変更された時の処理
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    -- 警察になった場合は製造エリアから出る
    if JobInfo and JobInfo.name and JobInfo.name == Config.PoliceAlert.job then
        lib.hideTextUI()
        isCrafting = false -- 製造中であれば中断
        ClearPedTasks(cache.ped) -- アニメーションを停止
    end
end)