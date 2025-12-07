local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local inDuel = false
local currentDuel = nil
local isDead = false
local isSpectating = false

-- ===================================
-- 初期化
-- ===================================
CreateThread(function()
    PlayerData = QBCore.Functions.GetPlayerData()
    
    -- Blip作成
    if Config.Debug then print('[ng-duelsystem] クライアント初期化') end
    CreateArenaBlips()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

-- ===================================
-- Blip作成
-- ===================================
function CreateArenaBlips()
    for i, arena in ipairs(Config.Arenas) do
        if arena.enabled and arena.blip and arena.blip.enabled then
            local blip = AddBlipForCoord(arena.location.x, arena.location.y, arena.location.z)
            SetBlipSprite(blip, arena.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, arena.blip.scale)
            SetBlipColour(blip, arena.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(arena.blip.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end

-- ===================================
-- アリーナ近接検知
-- ===================================
CreateThread(function()
    local points = {}
    
    for i, arena in ipairs(Config.Arenas) do
        if arena.enabled then
            local point = lib.points.new({
                coords = arena.location,
                distance = 2.5,
                arena = arena,
                arenaIndex = i,
                onEnter = function(self)
                    if not inDuel and not isSpectating then
                        lib.showTextUI(Config.Text.press_to_open, {
                            position = "left-center",
                            icon = 'hand-fist',
                            style = {
                                borderRadius = 5,
                                backgroundColor = '#48BB78',
                                color = 'white'
                            }
                        })
                    end
                end,
                onExit = function(self)
                    lib.hideTextUI()
                end,
                nearby = function(self)
                    if not inDuel and not isSpectating then
                        if IsControlJustReleased(0, 38) then -- E key
                            OpenDuelMenu(self.arenaIndex)
                        end
                    end
                end
            })
            
            points[i] = point
        end
    end
end)

-- ===================================
-- デュエルメニュー
-- ===================================
function OpenDuelMenu(arenaIndex)
    local menuOptions = {
        {
            title = Config.Text.menu_start_duel,
            description = '近くのプレイヤーとデュエルを開始',
            icon = 'gun',
            onSelect = function()
                StartDuelRequest(arenaIndex)
            end
        },
        {
            title = Config.Text.menu_view_stats,
            description = 'あなたの統計を表示',
            icon = 'chart-bar',
            onSelect = function()
                ViewStats()
            end
        },
    }
    
    if Config.Statistics.showRanking then
        table.insert(menuOptions, {
            title = Config.Text.menu_view_ranking,
            description = 'トッププレイヤーを表示',
            icon = 'trophy',
            onSelect = function()
                ViewRanking()
            end
        })
    end
    
    if Config.DuelSettings.AllowSpectators then
        table.insert(menuOptions, {
            title = Config.Text.menu_spectate,
            description = '進行中のデュエルを観戦',
            icon = 'eye',
            onSelect = function()
                SpectateMenu(arenaIndex)
            end
        })
    end
    
    lib.registerContext({
        id = 'ng_duel_main_menu',
        title = Config.Text.menu_title,
        options = menuOptions
    })
    
    lib.showContext('ng_duel_main_menu')
end

-- ===================================
-- デュエルリクエスト開始
-- ===================================
function StartDuelRequest(arenaIndex)
    -- 近くのプレイヤーを取得
    TriggerServerEvent('ng-duelsystem:server:getNearbyPlayers', arenaIndex)
end

RegisterNetEvent('ng-duelsystem:client:showPlayerSelection', function(players, arenaIndex)
    if #players == 0 then
        lib.notify({
            title = 'デュエルシステム',
            description = Config.Text.no_players_nearby,
            type = 'error',
            position = Config.UI.notificationPosition
        })
        return
    end
    
    local playerOptions = {}
    for _, player in ipairs(players) do
        table.insert(playerOptions, {
            title = player.name,
            description = 'サーバーID: ' .. player.id,
            icon = 'user',
            onSelect = function()
                SelectRounds(player.id, arenaIndex)
            end
        })
    end
    
    lib.registerContext({
        id = 'ng_duel_player_select',
        title = Config.Text.select_player,
        menu = 'ng_duel_main_menu',
        options = playerOptions
    })
    
    lib.showContext('ng_duel_player_select')
end)

-- ===================================
-- ラウンド数選択
-- ===================================
function SelectRounds(targetId, arenaIndex)
    local roundOptions = {}
    
    for i = 1, Config.DuelSettings.MaxRounds do
        table.insert(roundOptions, {
            title = i .. ' ラウンド',
            description = '先に' .. math.ceil(i/2) .. '勝したプレイヤーの勝利',
            icon = 'circle',
            onSelect = function()
                SelectWeaponCategory(targetId, arenaIndex, i)
            end
        })
    end
    
    lib.registerContext({
        id = 'ng_duel_round_select',
        title = Config.Text.select_rounds,
        menu = 'ng_duel_player_select',
        options = roundOptions
    })
    
    lib.showContext('ng_duel_round_select')
end

-- ===================================
-- 武器カテゴリー選択
-- ===================================
function SelectWeaponCategory(targetId, arenaIndex, rounds)
    local weaponOptions = {}
    
    for _, category in ipairs(Config.Weapons) do
        table.insert(weaponOptions, {
            title = category.label,
            description = #category.weapons .. '種類の武器',
            icon = 'gun',
            onSelect = function()
                SelectSpecificWeapon(targetId, arenaIndex, rounds, category)
            end
        })
    end
    
    lib.registerContext({
        id = 'ng_duel_weapon_category',
        title = Config.Text.select_weapon,
        menu = 'ng_duel_round_select',
        options = weaponOptions
    })
    
    lib.showContext('ng_duel_weapon_category')
end

-- ===================================
-- 具体的な武器選択
-- ===================================
function SelectSpecificWeapon(targetId, arenaIndex, rounds, category)
    local specificWeapons = {}
    
    for _, weapon in ipairs(category.weapons) do
        table.insert(specificWeapons, {
            title = weapon.label,
            description = '弾薬: ' .. weapon.ammo,
            icon = 'gun',
            onSelect = function()
                -- デュエルリクエスト送信
                TriggerServerEvent('ng-duelsystem:server:sendDuelRequest', {
                    targetId = targetId,
                    arenaIndex = arenaIndex,
                    rounds = rounds,
                    weapon = weapon
                })
                
                lib.notify({
                    title = 'デュエルシステム',
                    description = Config.Text.duel_request_sent,
                    type = 'success',
                    position = Config.UI.notificationPosition
                })
            end
        })
    end
    
    lib.registerContext({
        id = 'ng_duel_specific_weapon',
        title = category.label,
        menu = 'ng_duel_weapon_category',
        options = specificWeapons
    })
    
    lib.showContext('ng_duel_specific_weapon')
end

-- ===================================
-- デュエルリクエスト受信
-- ===================================
RegisterNetEvent('ng-duelsystem:client:receiveDuelRequest', function(data)
    local alert = lib.alertDialog({
        header = 'デュエルリクエスト',
        content = string.format(Config.Text.duel_request_received, data.senderName) .. '\n\n' ..
                  'アリーナ: ' .. data.arenaName .. '\n' ..
                  'ラウンド: ' .. data.rounds .. '\n' ..
                  '武器: ' .. data.weaponLabel,
        centered = true,
        cancel = true,
        labels = {
            confirm = '承認',
            cancel = '拒否'
        }
    })
    
    if alert == 'confirm' then
        TriggerServerEvent('ng-duelsystem:server:acceptDuel', data.duelId)
    else
        TriggerServerEvent('ng-duelsystem:server:declineDuel', data.duelId)
    end
end)

-- ===================================
-- デュエル開始
-- ===================================
RegisterNetEvent('ng-duelsystem:client:startDuel', function(duelData)
    inDuel = true
    currentDuel = duelData
    isDead = false
    
    lib.notify({
        title = 'デュエルシステム',
        description = Config.Text.duel_started,
        type = 'success',
        position = Config.UI.notificationPosition,
        duration = 3000
    })
    
    -- プレイヤーをスポーン地点にテレポート
    local ped = PlayerPedId()
    local arena = Config.Arenas[duelData.arenaIndex]
    local spawnPoint
    
    if GetPlayerServerId(PlayerId()) == duelData.player1 then
        spawnPoint = arena.spawn1
    else
        spawnPoint = arena.spawn2
    end
    
    DoScreenFadeOut(500)
    Wait(500)
    
    SetEntityCoords(ped, spawnPoint.x, spawnPoint.y, spawnPoint.z, false, false, false, false)
    SetEntityHeading(ped, spawnPoint.w)
    
    Wait(500)
    DoScreenFadeIn(500)
    
    -- 準備フェーズ
    StartPrepPhase()
end)

-- ===================================
-- 準備フェーズ
-- ===================================
function StartPrepPhase()
    local prepTime = Config.DuelSettings.PrepTime
    
    CreateThread(function()
        while prepTime > 0 and inDuel do
            Wait(1000)
            prepTime = prepTime - 1
            
            lib.notify({
                title = 'デュエルシステム',
                description = string.format(Config.Text.prep_time, prepTime),
                type = 'info',
                position = Config.UI.notificationPosition,
                duration = 1000
            })
        end
        
        if inDuel then
            StartRound()
        end
    end)
end

-- ===================================
-- ラウンド開始
-- ===================================
function StartRound()
    local ped = PlayerPedId()
    
    -- 武器を付与
    RemoveAllPedWeapons(ped, true)
    GiveWeaponToPed(ped, GetHashKey(currentDuel.weapon.name), currentDuel.weapon.ammo, false, true)
    SetPedAmmo(ped, GetHashKey(currentDuel.weapon.name), currentDuel.weapon.ammo)
    
    lib.notify({
        title = 'デュエルシステム',
        description = string.format(Config.Text.round_start, currentDuel.currentRound),
        type = 'success',
        position = Config.UI.notificationPosition,
        duration = 2000
    })
    
    -- 体力監視
    MonitorHealth()
end

-- ===================================
-- 体力監視
-- ===================================
function MonitorHealth()
    CreateThread(function()
        while inDuel and not isDead do
            Wait(100)
            local ped = PlayerPedId()
            
            if IsEntityDead(ped) then
                isDead = true
                TriggerServerEvent('ng-duelsystem:server:playerDied', currentDuel.duelId)
                break
            end
        end
    end)
end

-- ===================================
-- 死亡処理
-- ===================================
RegisterNetEvent('ng-duelsystem:client:handleDeath', function(isWinner)
    Wait(Config.DuelSettings.RespawnTime * 1000)
    
    local ped = PlayerPedId()
    
    -- リスポーン
    DoScreenFadeOut(500)
    Wait(500)
    
    local arena = Config.Arenas[currentDuel.arenaIndex]
    local spawnPoint
    
    if GetPlayerServerId(PlayerId()) == currentDuel.player1 then
        spawnPoint = arena.spawn1
    else
        spawnPoint = arena.spawn2
    end
    
    -- 蘇生
    local coords = vector3(spawnPoint.x, spawnPoint.y, spawnPoint.z)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, spawnPoint.w, true, false)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, spawnPoint.w)
    SetEntityHealth(ped, 200)
    ClearPedBloodDamage(ped)
    
    DoScreenFadeIn(500)
    
    isDead = false
    
    -- 次のラウンドまたは終了待機
end)

-- ===================================
-- ラウンド終了
-- ===================================
RegisterNetEvent('ng-duelsystem:client:roundEnd', function(roundWinner, scores)
    lib.notify({
        title = 'デュエルシステム',
        description = string.format(Config.Text.round_end, currentDuel.currentRound) .. '\n' ..
                      'スコア: ' .. scores.player1 .. ' - ' .. scores.player2,
        type = 'info',
        position = Config.UI.notificationPosition,
        duration = 3000
    })
    
    Wait(2000)
    
    -- 武器を削除
    local ped = PlayerPedId()
    RemoveAllPedWeapons(ped, true)
end)

-- ===================================
-- デュエル終了
-- ===================================
RegisterNetEvent('ng-duelsystem:client:endDuel', function(winner, finalScores, reward)
    inDuel = false
    local ped = PlayerPedId()
    
    -- 結果表示
    local isWinner = (GetPlayerServerId(PlayerId()) == winner)
    local resultText = isWinner and Config.Text.you_won or Config.Text.you_lost
    
    lib.notify({
        title = 'デュエルシステム',
        description = resultText .. '\n' ..
                      '最終スコア: ' .. finalScores.player1 .. ' - ' .. finalScores.player2 .. '\n' ..
                      (reward > 0 and string.format(Config.Text.reward_received, reward) or ''),
        type = isWinner and 'success' or 'error',
        position = Config.UI.notificationPosition,
        duration = 5000
    })
    
    -- 元の場所に戻す
    Wait(3000)
    DoScreenFadeOut(500)
    Wait(500)
    
    RemoveAllPedWeapons(ped, true)
    TriggerServerEvent('ng-duelsystem:server:returnToSpawn')
end)

-- ===================================
-- 元の場所に戻す
-- ===================================
RegisterNetEvent('ng-duelsystem:client:returnToSpawn', function(coords)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    
    Wait(500)
    DoScreenFadeIn(500)
    
    currentDuel = nil
end)

-- ===================================
-- 統計表示
-- ===================================
function ViewStats()
    TriggerServerEvent('ng-duelsystem:server:getStats')
end

RegisterNetEvent('ng-duelsystem:client:showStats', function(stats)
    local alert = lib.alertDialog({
        header = 'あなたの統計',
        content = 'デュエル数: ' .. stats.total_duels .. '\n' ..
                  '勝利: ' .. stats.wins .. '\n' ..
                  '敗北: ' .. stats.losses .. '\n' ..
                  '勝率: ' .. string.format("%.1f", stats.win_rate) .. '%\n' ..
                  'キル数: ' .. stats.kills .. '\n' ..
                  'デス数: ' .. stats.deaths .. '\n' ..
                  'K/D比: ' .. string.format("%.2f", stats.kd_ratio),
        centered = true,
        labels = {
            confirm = '閉じる'
        }
    })
end)

-- ===================================
-- ランキング表示
-- ===================================
function ViewRanking()
    TriggerServerEvent('ng-duelsystem:server:getRanking')
end

RegisterNetEvent('ng-duelsystem:client:showRanking', function(rankings)
    local rankingOptions = {}
    
    for i, player in ipairs(rankings) do
        table.insert(rankingOptions, {
            title = i .. '. ' .. player.name,
            description = '勝利: ' .. player.wins .. ' | 勝率: ' .. string.format("%.1f", player.win_rate) .. '%',
            icon = i <= 3 and 'trophy' or 'user',
            iconColor = i == 1 and '#FFD700' or (i == 2 and '#C0C0C0' or (i == 3 and '#CD7F32' or nil))
        })
    end
    
    lib.registerContext({
        id = 'ng_duel_ranking',
        title = Config.Text.menu_view_ranking,
        menu = 'ng_duel_main_menu',
        options = rankingOptions
    })
    
    lib.showContext('ng_duel_ranking')
end)

-- ===================================
-- 観戦モード
-- ===================================
function SpectateMenu(arenaIndex)
    TriggerServerEvent('ng-duelsystem:server:getActiveDuels', arenaIndex)
end

RegisterNetEvent('ng-duelsystem:client:showActiveDuels', function(duels)
    if #duels == 0 then
        lib.notify({
            title = 'デュエルシステム',
            description = '現在進行中のデュエルはありません',
            type = 'info',
            position = Config.UI.notificationPosition
        })
        return
    end
    
    local duelOptions = {}
    for _, duel in ipairs(duels) do
        table.insert(duelOptions, {
            title = duel.player1Name .. ' vs ' .. duel.player2Name,
            description = 'スコア: ' .. duel.scores.player1 .. ' - ' .. duel.scores.player2,
            icon = 'eye',
            onSelect = function()
                TriggerServerEvent('ng-duelsystem:server:startSpectating', duel.duelId)
            end
        })
    end
    
    lib.registerContext({
        id = 'ng_duel_spectate_list',
        title = Config.Text.menu_spectate,
        menu = 'ng_duel_main_menu',
        options = duelOptions
    })
    
    lib.showContext('ng_duel_spectate_list')
end)

-- ===================================
-- 観戦開始
-- ===================================
RegisterNetEvent('ng-duelsystem:client:startSpectate', function(duelData)
    isSpectating = true
    local ped = PlayerPedId()
    local arena = Config.Arenas[duelData.arenaIndex]
    
    DoScreenFadeOut(500)
    Wait(500)
    
    SetEntityCoords(ped, arena.spectatorSpawn.x, arena.spectatorSpawn.y, arena.spectatorSpawn.z, false, false, false, false)
    SetEntityHeading(ped, arena.spectatorSpawn.w)
    
    DoScreenFadeIn(500)
    
    lib.notify({
        title = '観戦モード',
        description = Config.Text.spectator_mode .. '\n[X] で観戦を終了',
        type = 'info',
        position = Config.UI.notificationPosition,
        duration = 5000
    })
    
    -- 観戦終了キー監視
    CreateThread(function()
        while isSpectating do
            Wait(0)
            if IsControlJustReleased(0, 73) then -- X key
                TriggerServerEvent('ng-duelsystem:server:stopSpectating')
                isSpectating = false
            end
        end
    end)
end)

-- ===================================
-- デバッグ関数
-- ===================================
if Config.Debug then
    RegisterCommand('dueltest', function()
        print('[ng-duelsystem] デバッグモード')
        print('inDuel:', inDuel)
        print('currentDuel:', json.encode(currentDuel))
    end, false)
end