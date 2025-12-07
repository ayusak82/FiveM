local QBCore = exports['qb-core']:GetCoreObject()

-- キューシステムの状態管理
local Queue = {}
local ConnectedPlayers = {}
local PlayerPriority = {}

-- デバッグ用ログ関数
local function DebugLog(message)
    if Config.Debug then
        print("[ng-priorityqueue] " .. message)
    end
end

-- プレイヤーのDiscord IDを取得
local function GetPlayerDiscordId(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    for _, identifier in pairs(identifiers) do
        if string.find(identifier, "discord:") then
            return string.gsub(identifier, "discord:", "")
        end
    end
    return nil
end

-- Discord APIからユーザー情報を取得
local function GetDiscordRoles(discordId, callback)
    if not discordId or discordId == "" then
        callback(nil)
        return
    end
    
    local url = string.format("https://discord.com/api/v10/guilds/%s/members/%s", Config.DiscordBot.GuildId, discordId)
    local headers = {
        ["Authorization"] = "Bot " .. Config.DiscordBot.Token,
        ["Content-Type"] = "application/json"
    }
    
    PerformHttpRequest(url, function(statusCode, response, headers)
        if statusCode == 200 then
            local data = json.decode(response)
            if data and data.roles then
                callback(data.roles)
            else
                callback(nil)
            end
        else
            DebugLog("Discord API エラー: " .. statusCode .. " (Player: " .. discordId .. ")")
            callback(nil)
        end
    end, "GET", "", headers)
end

-- プレイヤーの優先度を計算
local function CalculatePlayerPriority(discordRoles)
    if not discordRoles then
        return Config.Priority[4].priority, Config.Priority[4].name -- デフォルト優先度
    end
    
    local highestPriority = 0
    local priorityName = "一般プレイヤー"
    
    for _, priorityLevel in pairs(Config.Priority) do
        for _, roleId in pairs(priorityLevel.roles) do
            for _, userRole in pairs(discordRoles) do
                if userRole == roleId and priorityLevel.priority > highestPriority then
                    highestPriority = priorityLevel.priority
                    priorityName = priorityLevel.name
                end
            end
        end
    end
    
    if highestPriority == 0 then
        return Config.Priority[4].priority, Config.Priority[4].name
    end
    
    return highestPriority, priorityName
end

-- キューをソート（優先度順）
local function SortQueue()
    table.sort(Queue, function(a, b)
        if a.priority == b.priority then
            return a.joinTime < b.joinTime -- 同じ優先度なら先着順
        end
        return a.priority > b.priority -- 優先度が高い順
    end)
end

-- 現在の接続数を取得
local function GetConnectedCount()
    local count = 0
    for _ in pairs(ConnectedPlayers) do
        count = count + 1
    end
    return count
end

-- キューから削除
local function RemoveFromQueue(playerId)
    for i, queuedPlayer in ipairs(Queue) do
        if queuedPlayer.playerId == playerId then
            table.remove(Queue, i)
            DebugLog(string.format("プレイヤー %s がキューから削除されました", playerId))
            return true
        end
    end
    return false
end

-- キューステータス処理
local function ProcessQueueStatus(playerId, deferrals)
    local position = 0
    local priorityName = "不明"
    
    -- プレイヤーの位置を検索
    for i, queuedPlayer in ipairs(Queue) do
        if queuedPlayer.playerId == playerId then
            position = i
            priorityName = queuedPlayer.priorityName
            break
        end
    end
    
    if position == 0 then
        deferrals.done("❌ キューでエラーが発生しました。再接続してください。")
        return
    end
    
    local connectedCount = GetConnectedCount()
    
    -- 接続可能かチェック
    if connectedCount < Config.MaxPlayers and position == 1 then
        -- 接続許可
        ConnectedPlayers[playerId] = {
            playerName = GetPlayerName(playerId) or "Unknown",
            joinTime = os.time(),
            priority = 1
        }
        
        -- キューから削除
        RemoveFromQueue(playerId)
        
        DebugLog(string.format("プレイヤー %s の接続を承認しました (接続数: %d/%d)", 
                 playerId, GetConnectedCount(), Config.MaxPlayers))
        
        -- 接続承認メッセージ（3秒間）
        for i = 3, 1, -1 do
            local approvalMessage = string.format(
                "✅ 接続承認されました！\n\n" ..
                "━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" ..
                "🎉 おめでとうございます！\n" ..
                "👤 プレイヤー名: %s\n" ..
                "⭐ 優先度: %s\n" ..
                "🎮 サーバー名: %s\n" ..
                "━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" ..
                "🚀 サーバーに接続中... %d秒",
                GetPlayerName(playerId) or "Unknown",
                priorityName,
                GetConvar("sv_hostname", "FiveM Server"),
                i
            )
            
            deferrals.update(approvalMessage)
            Wait(1000)
        end
        
        deferrals.done()
        return
    end
    
    -- 待機中のメッセージ
    local estimatedTime = math.ceil(position * 0.5)
    local statusMessage = string.format(
        "⏳ 優先キューシステム - 待機中\n\n" ..
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" ..
        "👤 プレイヤー名: %s\n" ..
        "📍 現在の順番: %d位\n" ..
        "⭐ 優先度: %s\n" ..
        "⏰ 推定待機時間: 約%d分\n" ..
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" ..
        "📊 サーバー状況:\n" ..
        "   👥 キュー内人数: %d人\n" ..
        "   🌐 接続中: %d/%d人\n" ..
        "   💾 空きスロット: %d人\n" ..
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" ..
        "💡 順番が来るまでお待ちください...\n" ..
        "🔄 この画面は自動で更新されます",
        GetPlayerName(playerId) or "Unknown",
        position, 
        priorityName, 
        estimatedTime, 
        #Queue, 
        connectedCount, 
        Config.MaxPlayers,
        Config.MaxPlayers - connectedCount
    )
    
    deferrals.update(statusMessage)
    
    -- 5秒後に再チェック
    SetTimeout(5000, function()
        ProcessQueueStatus(playerId, deferrals)
    end)
end

-- 自動キュー参加処理
local function HandleQueueJoinAuto(playerId, playerName, discordId, deferrals)
    -- 既にキューにいるかチェック
    for i, queuedPlayer in ipairs(Queue) do
        if queuedPlayer.playerId == playerId then
            ProcessQueueStatus(playerId, deferrals)
            return
        end
    end
    
    -- Discord情報を取得してキューに追加
    deferrals.update("Discord認証中...")
    
    GetDiscordRoles(discordId, function(roles)
        local priority, priorityName = CalculatePlayerPriority(roles)
        
        local queueEntry = {
            playerId = playerId,
            playerName = playerName,
            discordId = discordId,
            priority = priority,
            priorityName = priorityName,
            joinTime = os.time(),
            deferrals = deferrals
        }
        
        table.insert(Queue, queueEntry)
        SortQueue()
        
        DebugLog(string.format("プレイヤー %s がキューに追加 - 優先度: %s (%d)", 
                              playerName, priorityName, priority))
        
        -- キューステータス処理を開始
        ProcessQueueStatus(playerId, deferrals)
    end)
end

-- プレイヤー情報表示（10秒間）
local function ShowPlayerWelcome(playerId, playerName, discordId, deferrals)
    deferrals.update("🔍 プレイヤー情報を取得中...")
    Wait(1000)
    
    -- Discord情報を取得
    GetDiscordRoles(discordId, function(roles)
        local priority, priorityName = CalculatePlayerPriority(roles)
        
        -- 現在のサーバー状況を取得
        local connectedCount = GetConnectedCount()
        
        -- 10秒間のウェルカム表示
        for i = 10, 1, -1 do
            local welcomeMessage = string.format(
                "🎮 %s へようこそ！\n\n" ..
                "━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" ..
                "👤 プレイヤー名: %s\n" ..
                "🔗 Discord ID: %s\n" ..
                "⭐ 優先度ロール: %s\n" ..
                "🎯 優先度レベル: %d\n" ..
                "📅 接続日時: %s\n" ..
                "━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" ..
                "🌐 現在の接続状況:\n" ..
                "   📊 接続中: %d/%d人\n" ..
                "   ⏳ キュー待機: %d人\n" ..
                "━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" ..
                "⏰ キューシステムに移行まで: %d秒",
                GetConvar("sv_hostname", "FiveM Server"),
                playerName,
                discordId,
                priorityName,
                priority,
                os.date("%Y/%m/%d %H:%M:%S"),
                connectedCount,
                Config.MaxPlayers,
                #Queue,
                i
            )
            
            deferrals.update(welcomeMessage)
            Wait(1000)
        end
        
        -- 10秒後にキューシステムに移行
        deferrals.update("🚦 キューシステムに移行中...")
        Wait(500)
        
        -- キューに追加
        HandleQueueJoinAuto(playerId, playerName, discordId, deferrals)
    end)
end

-- 全キューの処理
local function ProcessAllQueues()
    local connectedCount = GetConnectedCount()
    
    -- 接続可能な場合は次のプレイヤーを処理
    if connectedCount < Config.MaxPlayers and #Queue > 0 then
        local nextPlayer = Queue[1]
        if nextPlayer and nextPlayer.deferrals then
            -- 次のプレイヤーのキュー処理を実行
            ProcessQueueStatus(nextPlayer.playerId, nextPlayer.deferrals)
        else
            -- deferralsがない場合はキューから削除
            table.remove(Queue, 1)
            DebugLog("無効なキューエントリを削除しました")
        end
    end
    
    -- デバッグ情報
    if Config.Debug then
        DebugLog(string.format("キュー処理完了 - 接続中: %d/%d, キュー待機: %d人", 
                 connectedCount, Config.MaxPlayers, #Queue))
    end
end

-- プレイヤー接続開始時の処理
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local playerId = source
    local discordId = GetPlayerDiscordId(playerId)
    
    deferrals.defer()
    Wait(500)
    
    DebugLog(string.format("プレイヤー %s (%s) が接続を試行 - Discord: %s", playerName, playerId, discordId or "なし"))
    
    -- Discord認証チェック
    if not discordId then
        deferrals.done("❌ Discordアカウントでサーバーに接続してください。\n\n💡 Discordを起動してからFiveMを再起動してください。")
        return
    end
    
    -- 初期情報表示（10秒間）
    ShowPlayerWelcome(playerId, playerName, discordId, deferrals)
end)

-- プレイヤー切断時の処理
AddEventHandler('playerDropped', function(reason)
    local playerId = source
    local playerName = GetPlayerName(playerId) or "Unknown"
    
    DebugLog(string.format("プレイヤー %s (%s) が切断 - 理由: %s", playerName, playerId, reason))
    
    -- 接続プレイヤーリストから削除
    local wasConnected = ConnectedPlayers[playerId] ~= nil
    if wasConnected then
        ConnectedPlayers[playerId] = nil
        DebugLog(string.format("プレイヤー %s を接続リストから削除 (新しい接続数: %d/%d)", 
                 playerId, GetConnectedCount(), Config.MaxPlayers))
    end
    
    -- キューからも削除
    local removedFromQueue = RemoveFromQueue(playerId)
    if removedFromQueue then
        DebugLog(string.format("プレイヤー %s をキューから削除", playerId))
    end
    
    -- 優先度情報をクリア
    PlayerPriority[playerId] = nil
    
    -- 切断処理が完了したら2秒後にキューを処理
    if wasConnected then
        SetTimeout(2000, function()
            DebugLog("切断後のキュー処理を開始")
            ProcessAllQueues()
        end)
    end
end)

-- プレイヤーがリソース開始時に既に接続している場合
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- 既存の接続プレイヤーを登録
        local players = GetPlayers()
        for _, playerId in ipairs(players) do
            local numericPlayerId = tonumber(playerId)
            if numericPlayerId then
                ConnectedPlayers[numericPlayerId] = {
                    playerName = GetPlayerName(playerId) or "Unknown",
                    joinTime = os.time(),
                    priority = 1
                }
            end
        end
        
        DebugLog(string.format("リソース開始 - 既存プレイヤー: %d人を登録", #players))
    end
end)

-- 定期的なキュー処理
CreateThread(function()
    while true do
        ProcessAllQueues()
        Wait(Config.ConnectionInterval)
    end
end)

-- 定期的な接続状況の整合性チェック
CreateThread(function()
    while true do
        Wait(30000) -- 30秒ごと
        
        -- 実際の接続プレイヤー数を取得
        local actualPlayers = GetPlayers()
        local actualCount = #actualPlayers
        local trackedCount = GetConnectedCount()
        
        if Config.Debug then
            DebugLog(string.format("整合性チェック - 実際: %d人, 追跡: %d人, キュー: %d人", 
                     actualCount, trackedCount, #Queue))
        end
        
        -- 不整合がある場合は修正
        if actualCount ~= trackedCount then
            DebugLog("接続数に不整合があります。修正を実行します...")
            
            -- ConnectedPlayersを実際の接続状況に合わせて修正
            local newConnectedPlayers = {}
            
            for _, actualPlayerId in ipairs(actualPlayers) do
                local numericPlayerId = tonumber(actualPlayerId)
                if numericPlayerId then
                    -- 既存の情報があれば保持、なければ新規作成
                    newConnectedPlayers[numericPlayerId] = ConnectedPlayers[numericPlayerId] or {
                        playerName = GetPlayerName(actualPlayerId) or "Unknown",
                        joinTime = os.time(),
                        priority = 1
                    }
                end
            end
            
            ConnectedPlayers = newConnectedPlayers
            
            DebugLog(string.format("接続リストを修正しました - 新しい接続数: %d人", GetConnectedCount()))
        end
    end
end)

-- サーバー起動時の初期化
CreateThread(function()
    Wait(2000)
    DebugLog("ng-priorityqueue サーバーが開始されました")
    DebugLog("最大接続数: " .. Config.MaxPlayers)
    DebugLog("Discord Bot Token: " .. (Config.DiscordBot.Token ~= "YOUR_BOT_TOKEN_HERE" and "設定済み" or "未設定"))
    DebugLog("Discord Guild ID: " .. Config.DiscordBot.GuildId)
    
    -- 初期状態をログ出力
    local initialCount = GetConnectedCount()
    DebugLog(string.format("初期接続数: %d/%d人", initialCount, Config.MaxPlayers))
end)