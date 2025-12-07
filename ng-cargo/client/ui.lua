local timerVisible = false
local timerData = {}

-- ============================================
-- タイマー開始
-- ============================================
function StartTimer()
    if not currentJob then return end
    
    timerVisible = true
    timerData = {
        startTime = GetGameTimer(),
        timeLimit = currentJob.timeLimit * 1000, -- ミリ秒に変換
        difficulty = currentJob.difficulty,
        destinations = #currentJob.destinations,
        currentDestination = 1
    }
    
    -- タイマー更新スレッド
    CreateThread(function()
        while isInJob and timerVisible do
            local elapsed = GetGameTimer() - timerData.startTime
            local remaining = timerData.timeLimit - elapsed
            
            if remaining <= 0 then
                -- 時間切れ
                FailJob('time_expired')
                HideTimer()
                break
            end
            
            UpdateTimerDisplay(remaining)
            Wait(Config.UI.timerUpdateInterval)
        end
    end)
end

-- ============================================
-- タイマー表示更新
-- ============================================
function UpdateTimerDisplay(remainingMs)
    local minutes = math.floor(remainingMs / 60000)
    local seconds = math.floor((remainingMs % 60000) / 1000)
    
    local timeColor = 'green'
    if remainingMs < 60000 then -- 1分未満
        timeColor = 'red'
    elseif remainingMs < 180000 then -- 3分未満
        timeColor = 'orange'
    end
    
    local progressPercent = (remainingMs / timerData.timeLimit) * 100
    
    -- SendNUIMessage を使用してカスタムUIを表示
    SendNUIMessage({
        action = 'updateTimer',
        data = {
            time = string.format('%02d:%02d', minutes, seconds),
            color = timeColor,
            progress = progressPercent,
            destination = string.format('%d/%d', currentDestinationIndex, #currentJob.destinations),
            unloads = string.format('%d/%d', unloadCount, currentJob.unloadCount),
            difficulty = currentJob.difficulty
        }
    })
end

-- ============================================
-- タイマー非表示
-- ============================================
function HideTimer()
    timerVisible = false
    timerData = {}
    
    SendNUIMessage({
        action = 'hideTimer'
    })
end

-- ============================================
-- ジョブ完了統計表示
-- ============================================
function ShowJobCompleteStats(data)
    local statsOptions = {
        {
            title = '🎉 配送完了!',
            description = 'お疲れ様でした',
            icon = 'check-circle',
            iconColor = 'green',
            disabled = true
        },
        {
            title = '━━━━━━━━━━━━━━━━━━',
            disabled = true
        },
        {
            title = '⏱️ 所要時間',
            description = FormatTime(data.completionTime),
            icon = 'clock',
            disabled = true
        },
        {
            title = '💰 獲得報酬',
            description = string.format('$%s', FormatNumber(data.totalReward)),
            icon = 'money-bill-wave',
            iconColor = 'green',
            disabled = true
        }
    }
    
    -- ボーナス表示
    if data.timeBonus and data.timeBonus > 0 then
        table.insert(statsOptions, {
            title = '⚡ 時間ボーナス',
            description = string.format('+$%s', FormatNumber(data.timeBonus)),
            icon = 'bolt',
            iconColor = 'yellow',
            disabled = true
        })
    end
    
    -- レベルボーナス
    if data.levelBonus and data.levelBonus > 1.0 then
        table.insert(statsOptions, {
            title = '📈 レベルボーナス',
            description = string.format('x%.1f (Lv.%d)', data.levelBonus, data.currentLevel or 1),
            icon = 'arrow-up',
            iconColor = 'blue',
            disabled = true
        })
    end
    
    -- ランダムイベントボーナス
    if data.eventBonus and data.eventBonus > 0 then
        table.insert(statsOptions, {
            title = '🎲 イベントボーナス',
            description = string.format('+$%s', FormatNumber(data.eventBonus)),
            icon = 'gift',
            iconColor = 'purple',
            disabled = true
        })
    end
    
    table.insert(statsOptions, {
        title = '━━━━━━━━━━━━━━━━━━',
        disabled = true
    })
    
    -- 経験値
    table.insert(statsOptions, {
        title = '✨ 獲得経験値',
        description = string.format('+%d EXP', data.experience or 0),
        icon = 'star',
        iconColor = 'gold',
        disabled = true
    })
    
    -- レベル情報
    if data.levelUp then
        table.insert(statsOptions, {
            title = '🎊 レベルアップ!',
            description = string.format('レベル %d → %d', data.oldLevel or 1, data.newLevel or 1),
            icon = 'trophy',
            iconColor = 'gold',
            disabled = true
        })
        
        if data.levelUpReward and data.levelUpReward > 0 then
            table.insert(statsOptions, {
                title = '🎁 レベルアップ報酬',
                description = string.format('+$%s', FormatNumber(data.levelUpReward)),
                icon = 'gift',
                iconColor = 'gold',
                disabled = true
            })
        end
    else
        local expProgress = data.currentExp or 0
        local expNeeded = Config.LevelSystem.experiencePerLevel
        local expPercent = math.floor((expProgress / expNeeded) * 100)
        
        table.insert(statsOptions, {
            title = '📊 次のレベルまで',
            description = string.format('%d / %d EXP (%d%%)', expProgress, expNeeded, expPercent),
            icon = 'chart-line',
            disabled = true
        })
    end
    
    table.insert(statsOptions, {
        title = '━━━━━━━━━━━━━━━━━━',
        disabled = true
    })
    
    -- 統計
    table.insert(statsOptions, {
        title = '📈 あなたの記録',
        description = string.format('総配送: %d回 | 成功率: %d%%',
            data.totalDeliveries or 0,
            data.successRate or 0
        ),
        icon = 'chart-bar',
        disabled = true
    })
    
    -- 最速記録更新
    if data.newBestTime then
        table.insert(statsOptions, {
            title = '🏆 最速記録更新!',
            description = string.format('新記録: %s', FormatTime(data.completionTime)),
            icon = 'medal',
            iconColor = 'gold',
            disabled = true
        })
    elseif data.bestTime and data.bestTime > 0 then
        table.insert(statsOptions, {
            title = '⏱️ 自己ベスト記録',
            description = FormatTime(data.bestTime),
            icon = 'stopwatch',
            disabled = true
        })
    end
    
    table.insert(statsOptions, {
        title = '━━━━━━━━━━━━━━━━━━',
        disabled = true
    })
    
    table.insert(statsOptions, {
        title = '✅ 閉じる',
        icon = 'times',
        onSelect = function()
            -- メニューを閉じる
        end
    })
    
    lib.registerContext({
        id = 'ng_cargo_complete',
        title = '配送完了',
        options = statsOptions
    })
    
    lib.showContext('ng_cargo_complete')
    
    -- サウンド再生
    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true)
end

-- ============================================
-- ランキング表示
-- ============================================
RegisterNetEvent('ng-cargo:client:showRanking', function(rankings)
    local rankingOptions = {
        {
            title = '🏆 貨物輸送ランキング',
            description = 'トップ配送者',
            icon = 'trophy',
            iconColor = 'gold',
            disabled = true
        },
        {
            title = '━━━━━━━━━━━━━━━━━━',
            disabled = true
        }
    }
    
    for category, data in pairs(rankings) do
        local categoryInfo = nil
        for _, cat in ipairs(Config.Ranking.categories) do
            if cat.id == category then
                categoryInfo = cat
                break
            end
        end
        
        if categoryInfo then
            table.insert(rankingOptions, {
                title = '📊 ' .. categoryInfo.label,
                icon = 'list-ol',
                iconColor = 'blue',
                disabled = true
            })
            
            for i, player in ipairs(data) do
                local medal = i == 1 and '🥇' or (i == 2 and '🥈' or (i == 3 and '🥉' or string.format('%d位', i)))
                local value = player.value
                
                -- フォーマット
                if category == 'earnings' then
                    value = '$' .. FormatNumber(value)
                elseif category == 'time' and value > 0 then
                    value = FormatTime(value)
                end
                
                table.insert(rankingOptions, {
                    title = string.format('%s %s', medal, player.name),
                    description = string.format('%s: %s', categoryInfo.label, value),
                    icon = 'user',
                    disabled = true
                })
            end
            
            table.insert(rankingOptions, {
                title = '━━━━━━━━━━━━━━━━━━',
                disabled = true
            })
        end
    end
    
    table.insert(rankingOptions, {
        title = '✅ 閉じる',
        icon = 'times',
        onSelect = function()
            -- メニューを閉じる
        end
    })
    
    lib.registerContext({
        id = 'ng_cargo_ranking',
        title = 'ランキング',
        options = rankingOptions
    })
    
    lib.showContext('ng_cargo_ranking')
end)

-- ============================================
-- ヘルパー関数: 時間フォーマット
-- ============================================
function FormatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format('%d分%d秒', minutes, secs)
end

-- ============================================
-- ヘルパー関数: 数値フォーマット (カンマ区切り)
-- ============================================
function FormatNumber(num)
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- ============================================
-- 進行状況表示 (オプション)
-- ============================================
function ShowProgressHUD()
    if not isInJob or not currentJob then return end
    
    CreateThread(function()
        while isInJob do
            Wait(0)
            
            -- 画面右上に情報表示
            SetTextFont(4)
            SetTextProportional(1)
            SetTextScale(0.35, 0.35)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            
            local infoText = string.format(
                "配送進行状況\n目的地: %d/%d\n荷下ろし: %d/%d",
                currentDestinationIndex,
                #currentJob.destinations,
                unloadCount,
                currentJob.unloadCount
            )
            
            AddTextComponentString(infoText)
            DrawText(0.92, 0.02)
        end
    end)
end

-- ============================================
-- マップマーカー更新
-- ============================================
function UpdateDestinationMarker()
    if not isInJob or not currentJob then return end
    
    CreateThread(function()
        while isInJob and currentDestinationIndex <= #currentJob.destinations do
            Wait(0)
            
            local destination = currentJob.destinations[currentDestinationIndex]
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - destination.coords)
            
            -- 近くにいる場合、3Dマーカーを表示
            if dist < 100.0 then
                DrawMarker(
                    1, -- マーカータイプ
                    destination.coords.x,
                    destination.coords.y,
                    destination.coords.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    5.0, 5.0, 2.0,
                    255, 255, 0, 150,
                    false, true, 2, false, nil, nil, false
                )
                
                -- テキスト表示
                if dist < 50.0 then
                    local onScreen, _x, _y = World3dToScreen2d(
                        destination.coords.x,
                        destination.coords.y,
                        destination.coords.z + 2.0
                    )
                    
                    if onScreen then
                        SetTextScale(0.4, 0.4)
                        SetTextFont(4)
                        SetTextProportional(1)
                        SetTextColour(255, 255, 255, 255)
                        SetTextDropshadow(0, 0, 0, 0, 255)
                        SetTextEdge(1, 0, 0, 0, 255)
                        SetTextDropShadow()
                        SetTextOutline()
                        SetTextCentre(true)
                        SetTextEntry("STRING")
                        AddTextComponentString(string.format('~y~%s~w~\n%.1fm', destination.name, dist))
                        DrawText(_x, _y)
                    end
                end
            end
        end
    end)
end

-- ============================================
-- ミニマップ通知
-- ============================================
function ShowMinimapNotification(title, subtitle, icon)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(subtitle)
    EndTextCommandThefeedPostMessagetext(icon or "CHAR_CARSITE", icon or "CHAR_CARSITE", false, 1, title, "")
    EndTextCommandThefeedPostTicker(false, false)
end

-- ============================================
-- 警告通知 (時間切れ警告など)
-- ============================================
function ShowWarningNotification(message)
    lib.notify({
        title = '⚠️ 警告',
        description = message,
        type = 'warning',
        duration = 5000,
        position = 'top'
    })
    
    -- 警告音
    PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", true)
end

-- ============================================
-- カスタム通知: 経験値獲得
-- ============================================
function ShowExpGainNotification(amount)
    lib.notify({
        title = '✨ 経験値獲得',
        description = string.format('+%d EXP', amount),
        type = 'success',
        duration = 3000,
        icon = 'star',
        iconColor = 'gold'
    })
end

-- ============================================
-- カスタム通知: レベルアップ
-- ============================================
function ShowLevelUpNotification(newLevel)
    lib.notify({
        title = '🎊 レベルアップ!',
        description = string.format('レベル %d に到達しました', newLevel),
        type = 'success',
        duration = 7000,
        icon = 'trophy',
        iconColor = 'gold',
        position = 'top'
    })
    
    -- レベルアップ音
    PlaySoundFrontend(-1, "RANK_UP", "HUD_AWARDS", true)
end

-- ============================================
-- 時間警告 (残り時間が少ない時)
-- ============================================
CreateThread(function()
    local warningShown = {
        ['5min'] = false,
        ['3min'] = false,
        ['1min'] = false,
        ['30sec'] = false
    }
    
    while true do
        Wait(5000) -- 5秒ごとにチェック
        
        if isInJob and timerVisible and timerData.timeLimit then
            local elapsed = GetGameTimer() - timerData.startTime
            local remaining = timerData.timeLimit - elapsed
            local remainingSec = math.floor(remaining / 1000)
            
            if remainingSec <= 300 and not warningShown['5min'] then
                ShowWarningNotification('残り時間: 5分')
                warningShown['5min'] = true
            elseif remainingSec <= 180 and not warningShown['3min'] then
                ShowWarningNotification('残り時間: 3分')
                warningShown['3min'] = true
            elseif remainingSec <= 60 and not warningShown['1min'] then
                ShowWarningNotification('残り時間: 1分!')
                warningShown['1min'] = true
            elseif remainingSec <= 30 and not warningShown['30sec'] then
                ShowWarningNotification('残り時間: 30秒!')
                warningShown['30sec'] = true
            end
        else
            -- リセット
            for k in pairs(warningShown) do
                warningShown[k] = false
            end
        end
    end
end)

-- ============================================
-- NUI コールバック (必要に応じて)
-- ============================================
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)