-- デバッグ関数
local function DebugPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^3[DEBUG]^7 ' .. message)
end

-- UI表示用変数
local currentScore = 0
local currentTarget = 0
local totalTargets = 0
local totalTime = 0.0
local hitCount = 0

-- スコアHUD表示
local isHudVisible = false

-- スコアをリセット
function ResetScore()
    currentScore = 0
    currentTarget = 0
    totalTargets = 0
    totalTime = 0.0
    hitCount = 0
    DebugPrint('Score reset')
end

-- スコアを更新
function UpdateScore(score, time, hit)
    currentScore = currentScore + score
    currentTarget = currentTarget + 1
    
    if hit then
        totalTime = totalTime + time
        hitCount = hitCount + 1
    end
    
    DebugPrint('Score updated - Total:', currentScore, 'Target:', currentTarget, '/', totalTargets, 'Hit:', hit)
end

-- HUD表示を開始
function ShowScoreHud(targets)
    totalTargets = targets
    isHudVisible = true
    DebugPrint('Score HUD shown')
end

-- HUD表示を終了
function HideScoreHud()
    isHudVisible = false
    DebugPrint('Score HUD hidden')
end

-- スコアHUD描画スレッド
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if isHudVisible then
            -- 平均時間計算
            local avgTime = 0.0
            if hitCount > 0 then
                avgTime = totalTime / hitCount
            end
            
            -- スコア表示
            SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(0.0, 0.5)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString(string.format(
                "%s: %d\n%s: %d/%d\n%s: %.2fs",
                Config.Locale['current_score'],
                currentScore,
                Config.Locale['targets_hit'],
                currentTarget,
                totalTargets,
                Config.Locale['avg_time'],
                avgTime
            ))
            DrawText(0.5, 0.02)
        else
            Citizen.Wait(500)
        end
    end
end)

-- 結果表示
function ShowResults()
    local hitRate = 0
    if totalTargets > 0 then
        hitRate = math.floor((hitCount / totalTargets) * 100)
    end
    
    local avgTime = 0.0
    if hitCount > 0 then
        avgTime = totalTime / hitCount
    end
    
    -- 最高スコアを計算（ヘッドショット + 最速ボーナス）
    local bestPossibleScore = Config.Scoring.bodyParts.head + Config.Scoring.timeBonus[1].bonus
    
    DebugPrint('Showing results - Score:', currentScore, 'Hit Rate:', hitRate, 'Avg Time:', avgTime)
    
    lib.alertDialog({
        header = Config.Locale['results'],
        content = string.format(
            '%s: %d\n%s: %d%%\n%s: %.2f秒\n%s: %d',
            Config.Locale['total_score'],
            currentScore,
            Config.Locale['hit_rate'],
            hitRate,
            Config.Locale['avg_time'],
            avgTime,
            Config.Locale['best_score'],
            bestPossibleScore
        ),
        centered = true,
        cancel = false
    })
    
    exports['okokNotify']:Alert(
        Config.Locale['results'],
        Config.Locale['practice_finished'],
        5000,
        'success',
        true
    )
end

-- 現在のスコアを取得
function GetCurrentScore()
    return {
        score = currentScore,
        targets = currentTarget,
        total = totalTargets,
        hits = hitCount,
        avgTime = hitCount > 0 and (totalTime / hitCount) or 0.0
    }
end
