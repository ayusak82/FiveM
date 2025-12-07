-- Discord API関連の関数

-- デバッグ出力関数
local function DebugPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^3[DEBUG]^7 ' .. message)
end

local function ErrorPrint(...)
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^1[ERROR]^7 ' .. message)
end

local function SuccessPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^2[SUCCESS]^7 ' .. message)
end

-- 最小Discordリクエスト間隔（ミリ秒）: 連続リクエスト時に必ず待機を入れる
local lastDiscordRequestTime = 0
local MIN_DISCORD_REQUEST_INTERVAL = 2000 -- 2000ms = 約2秒

local function GetTimeMs()
    -- サーバー環境によっては GetGameTimer が存在する。なければ os.time() を使う
    if GetGameTimer then
        return GetGameTimer()
    end
    return math.floor(os.time() * 1000)
end

-- プレイヤーのDiscord IDを取得
function GetPlayerDiscordId(source)
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then
        ErrorPrint('Failed to get identifiers for player:', source)
        return nil
    end
    
    for _, identifier in pairs(identifiers) do
        if string.find(identifier, Config.DiscordIdentifierPrefix) then
            local discordId = string.gsub(identifier, Config.DiscordIdentifierPrefix, '')
            DebugPrint('Found Discord ID for player', source, ':', discordId)
            return discordId
        end
    end
    
    ErrorPrint('No Discord identifier found for player:', source)
    return nil
end

-- Discord APIリクエストを実行（レート制限対応）
function PerformDiscordRequest(method, endpoint, jsondata, retryCount)
    retryCount = retryCount or 0
    local url = 'https://discord.com/api/v10' .. endpoint
    local data = jsondata or {}
    
    DebugPrint('Discord API Request:', method, url)
    
    -- 最低間隔を保証: 直近のDiscordリクエストからMIN_DISCORD_REQUEST_INTERVAL未満であれば待機する
    local now = GetTimeMs()
    local elapsed = now - lastDiscordRequestTime
    if elapsed < MIN_DISCORD_REQUEST_INTERVAL then
        local waitMs = MIN_DISCORD_REQUEST_INTERVAL - elapsed
        DebugPrint('Waiting', waitMs, 'ms before Discord API request to respect rate limits')
        Citizen.Wait(waitMs)
    end
    -- 送信直前に時刻を更新して、他の並列リクエストと間隔を守る
    lastDiscordRequestTime = GetTimeMs()
    
    local headers = {
        ['Content-Type'] = 'application/json',
        ['Authorization'] = 'Bot ' .. Config.DiscordBotToken
    }
    
    local promise = promise.new()
    
    PerformHttpRequest(url, function(statusCode, responseText, responseHeaders)
        if statusCode == 200 or statusCode == 204 then
            SuccessPrint('Discord API request successful:', statusCode)
            promise:resolve({success = true, data = responseText})
        elseif statusCode == 429 then
            -- レート制限エラー
            ErrorPrint('Rate limit hit! Status:', statusCode)
            
            -- Retry-Afterヘッダーから待機時間を取得
            local retryAfter = 5000 -- デフォルト5秒
            if responseHeaders and responseHeaders['retry-after'] then
                retryAfter = tonumber(responseHeaders['retry-after']) * 1000
            elseif responseText then
                local decoded = json.decode(responseText)
                if decoded and decoded.retry_after then
                    retryAfter = decoded.retry_after * 1000
                end
            end
            
            if retryCount < 5 then
                ErrorPrint('Retrying after', retryAfter, 'ms (attempt', retryCount + 1, '/3)')
                Citizen.Wait(retryAfter)
                -- リトライ
                local retryResult = PerformDiscordRequest(method, endpoint, jsondata, retryCount + 1)
                promise:resolve(retryResult)
            else
                ErrorPrint('Max retry attempts reached for:', endpoint)
                promise:resolve({success = false, error = 'Rate limit exceeded', code = statusCode})
            end
        else
            ErrorPrint('Discord API request failed:', statusCode, responseText)
            promise:resolve({success = false, error = responseText, code = statusCode})
        end
    end, method, #data > 0 and json.encode(data) or '', headers)
    
    local result = Citizen.Await(promise)
    
    -- リクエスト間の待機時間
    if Config.RequestDelay and Config.RequestDelay > 0 then
        Citizen.Wait(Config.RequestDelay)
    end
    
    return result
end

-- Discordロールを付与
function AddDiscordRole(discordId, roleId)
    if not discordId or not roleId then
        ErrorPrint('Invalid parameters for AddDiscordRole')
        return false
    end
    
    DebugPrint('Adding role', roleId, 'to Discord user', discordId)
    
    local endpoint = string.format('/guilds/%s/members/%s/roles/%s', Config.GuildId, discordId, roleId)
    local response = PerformDiscordRequest('PUT', endpoint)
    
    if response.success then
        SuccessPrint('Successfully added role', roleId, 'to user', discordId)
        return true
    else
        ErrorPrint('Failed to add role', roleId, 'to user', discordId)
        return false
    end
end

-- Discordロールを削除
function RemoveDiscordRole(discordId, roleId)
    if not discordId or not roleId then
        ErrorPrint('Invalid parameters for RemoveDiscordRole')
        return false
    end
    
    DebugPrint('Removing role', roleId, 'from Discord user', discordId)
    
    local endpoint = string.format('/guilds/%s/members/%s/roles/%s', Config.GuildId, discordId, roleId)
    local response = PerformDiscordRequest('DELETE', endpoint)
    
    if response.success then
        SuccessPrint('Successfully removed role', roleId, 'from user', discordId)
        return true
    else
        ErrorPrint('Failed to remove role', roleId, 'from user', discordId)
        return false
    end
end

-- ユーザーの現在のロールを取得
function GetUserRoles(discordId)
    if not discordId then
        ErrorPrint('Invalid Discord ID for GetUserRoles')
        return {}
    end
    
    DebugPrint('Getting roles for Discord user', discordId)
    
    local endpoint = string.format('/guilds/%s/members/%s', Config.GuildId, discordId)
    local response = PerformDiscordRequest('GET', endpoint)
    
    if response.success and response.data then
        local data = json.decode(response.data)
        if data and data.roles then
            DebugPrint('User', discordId, 'has', #data.roles, 'roles')
            return data.roles
        end
    end
    
    ErrorPrint('Failed to get roles for user', discordId)
    return {}
end