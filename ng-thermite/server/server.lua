local QBCore = exports['qb-core']:GetCoreObject()

-- グローバル変数
local isActive = false
local LastMissionTime = 0
local BaseReached = false
local MissionTeam = {
    leader = nil,
    members = {},
    isReady = false
}

-- デバッグ関数
local function DebugPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^3[ng-thermite DEBUG]^7 ' .. message)
end

-- チーム管理関数
function ResetTeam()
    MissionTeam = {
        leader = nil,
        members = {},
        isReady = false
    }
end

function IsInTeam(src)
    if MissionTeam.leader == src then return true end
    for _, member in pairs(MissionTeam.members) do
        if member == src then return true end
    end
    return false
end

function GetTeamSize()
    return #MissionTeam.members + (MissionTeam.leader and 1 or 0)
end

function GetTeamMemberNames()
    local names = {}
    if MissionTeam.leader then
        table.insert(names, GetPlayerName(MissionTeam.leader))
    end
    for _, member in pairs(MissionTeam.members) do
        table.insert(names, GetPlayerName(member))
    end
    return names
end

-- Discord Webhook
function DiscordLog(message)
    if Config.WebHook == false then
        DebugPrint("Discord logging disabled in config")
        return
    end
    
    local logoUrl = ""
    if Config.LogsImage and Config.LogsImage ~= false then
        logoUrl = Config.LogsImage
    end
    
    local embed = {
        {
            ["color"] = 04255,
            ["title"] = "ng-thermite Mission",
            ["description"] = message,
            ["footer"] = {
                ["text"] = "By NCCGr"
            },
            ["thumbnail"] = {}
        }
    }
    
    if logoUrl ~= "" then
        embed[1]["footer"]["icon_url"] = logoUrl
        embed[1]["thumbnail"]["url"] = logoUrl
    end
    
    PerformHttpRequest(Config.WebHook, function(err, text, headers) end, 'POST',
        json.encode({
            username = 'ng-thermite',
            embeds = embed,
            avatar_url = logoUrl ~= "" and logoUrl or nil
        }),
        { ['Content-Type'] = 'application/json' }
    )
end

-- クールダウンチェック
function CheckCooldown()
    if not Config.Cooldown.Enabled then return false end
    local currentTime = os.time()
    return (currentTime - LastMissionTime) < Config.Cooldown.Time
end

function GetRemainingCooldown()
    local currentTime = os.time()
    local remaining = Config.Cooldown.Time - (currentTime - LastMissionTime)
    return remaining > 0 and remaining or 0
end

-- Discord Webhook
function DiscordLog(message)
    if Config.WebHook == false then
        DebugPrint("Discord logging disabled in config")
        return
    end
    
    local logoUrl = ""
    if Config.LogsImage and Config.LogsImage ~= false then
        logoUrl = Config.LogsImage
    end
    
    local embed = {
        {
            ["color"] = 04255,
            ["title"] = "ng-thermite Mission",
            ["description"] = message,
            ["footer"] = {
                ["text"] = "By NCCGr"
            },
            ["thumbnail"] = {}
        }
    }
    
    if logoUrl ~= "" then
        embed[1]["footer"]["icon_url"] = logoUrl
        embed[1]["thumbnail"]["url"] = logoUrl
    end
    
    PerformHttpRequest(Config.WebHook, function(err, text, headers) end, 'POST',
        json.encode({
            username = 'ng-thermite',
            embeds = embed,
            avatar_url = logoUrl ~= "" and logoUrl or nil
        }),
        { ['Content-Type'] = 'application/json' }
    )
end

-- クールダウンチェック
function CheckCooldown()
    if not Config.Cooldown.Enabled then return false end
    local currentTime = os.time()
    return (currentTime - LastMissionTime) < Config.Cooldown.Time
end

function GetRemainingCooldown()
    local currentTime = os.time()
    local remaining = Config.Cooldown.Time - (currentTime - LastMissionTime)
    return remaining > 0 and remaining or 0
end

-- チーム参加
RegisterNetEvent('ng-thermite:server:JoinTeam', function()
    local src = source
    
    if isActive then
        TriggerClientEvent('QBCore:Notify', src, "ミッションが既に進行中です", "error")
        return
    end
    
    if IsInTeam(src) then
        TriggerClientEvent('QBCore:Notify', src, "既にチームに参加しています", "error")
        return
    end
    
    if GetTeamSize() >= Config.MaxTeamMembers then
        TriggerClientEvent('QBCore:Notify', src, "チームが満員です（最大" .. Config.MaxTeamMembers .. "人）", "error")
        return
    end
    
    if not MissionTeam.leader then
        MissionTeam.leader = src
        TriggerClientEvent('QBCore:Notify', src, "チームを作成しました（リーダー）", "success")
        DiscordLog('チーム作成: **'..GetPlayerName(src)..'** ID: **' ..src..'**')
    else
        table.insert(MissionTeam.members, src)
        TriggerClientEvent('QBCore:Notify', src, "チームに参加しました", "success")
        TriggerClientEvent('QBCore:Notify', MissionTeam.leader, GetPlayerName(src) .. "がチームに参加しました", "success")
        DiscordLog('チーム参加: **'..GetPlayerName(src)..'** ID: **' ..src..'**')
    end
    
    local teamSize = GetTeamSize()
    local teamNames = GetTeamMemberNames()
    if MissionTeam.leader then
        TriggerClientEvent('ng-thermite:client:UpdateTeam', MissionTeam.leader, teamSize, teamNames)
    end
    for _, member in pairs(MissionTeam.members) do
        TriggerClientEvent('ng-thermite:client:UpdateTeam', member, teamSize, teamNames)
    end
end)

-- チーム離脱
RegisterNetEvent('ng-thermite:server:LeaveTeam', function()
    local src = source
    
    if not IsInTeam(src) then
        TriggerClientEvent('QBCore:Notify', src, "チームに参加していません", "error")
        return
    end
    
    if MissionTeam.leader == src then
        for _, member in pairs(MissionTeam.members) do
            TriggerClientEvent('QBCore:Notify', member, "チームリーダーが離脱したためチームが解散されました", "error")
            TriggerClientEvent('ng-thermite:client:UpdateTeam', member, 0, {})
        end
        TriggerClientEvent('QBCore:Notify', src, "チームから離脱しました", "info")
        TriggerClientEvent('ng-thermite:client:UpdateTeam', src, 0, {})
        DiscordLog('チーム解散: **'..GetPlayerName(src)..'** ID: **' ..src..'**')
        ResetTeam()
    else
        for i, member in pairs(MissionTeam.members) do
            if member == src then
                table.remove(MissionTeam.members, i)
                break
            end
        end
        TriggerClientEvent('QBCore:Notify', src, "チームから離脱しました", "info")
        TriggerClientEvent('ng-thermite:client:UpdateTeam', src, 0, {})
        
        if MissionTeam.leader then
            TriggerClientEvent('QBCore:Notify', MissionTeam.leader, GetPlayerName(src) .. "がチームから離脱しました", "info")
        end
        
        local teamSize = GetTeamSize()
        local teamNames = GetTeamMemberNames()
        if MissionTeam.leader then
            TriggerClientEvent('ng-thermite:client:UpdateTeam', MissionTeam.leader, teamSize, teamNames)
        end
        for _, member in pairs(MissionTeam.members) do
            TriggerClientEvent('ng-thermite:client:UpdateTeam', member, teamSize, teamNames)
        end
    end
end)

-- ミッション開始
RegisterNetEvent('ng-thermite:server:StartMission', function()
    local src = source
    
    if MissionTeam.leader ~= src then
        TriggerClientEvent('QBCore:Notify', src, "チームリーダーのみがミッションを開始できます", "error")
        return
    end
    
    local teamSize = GetTeamSize()
    if teamSize < Config.MinTeamMembers then
        TriggerClientEvent('QBCore:Notify', src, "ミッションを開始するには最低" .. Config.MinTeamMembers .. "人必要です（現在: " .. teamSize .. "人）", "error")
        return
    end
    
    if isActive then
        TriggerClientEvent('QBCore:Notify', src, "他のプレイヤーが既にミッションを実行中です", "error")
        return
    end

    if CheckCooldown() then
        local remaining = GetRemainingCooldown()
        local minutes = math.floor(remaining / 60)
        local seconds = remaining % 60
        
        if Config.Cooldown.ShowRemaining then
            TriggerClientEvent('QBCore:Notify', src, string.format("ミッションはクールダウン中です（残り%d分%d秒）", minutes, seconds), "error")
        else
            TriggerClientEvent('QBCore:Notify', src, "ミッションは現在クールダウン中です", "error")
        end
        return
    end

    isActive = true
    LastMissionTime = os.time()
    MissionTeam.isReady = true
    
    local teamMembers = {}
    if MissionTeam.leader then
        table.insert(teamMembers, MissionTeam.leader)
    end
    for _, member in pairs(MissionTeam.members) do
        table.insert(teamMembers, member)
    end
    
    local vehiclePlate = "HEIST"..tostring(math.random(1000, 9999))
    
    for _, memberId in pairs(teamMembers) do
        TriggerClientEvent('ng-thermite:client:MissionStarted', memberId, teamMembers, vehiclePlate)
    end
    
    TriggerClientEvent('ng-thermite:client:SetActive', -1, true)
    
    local teamNamesStr = table.concat(GetTeamMemberNames(), ", ")
    DiscordLog('ミッション開始: チーム[' .. teamSize .. '人] - **' .. teamNamesStr .. '**')
end)

-- ミッション状態の管理
RegisterNetEvent('ng-thermite:server:SetActive', function(status)
    if not status then
        isActive = false
        BaseReached = false
        ResetTeam()
        TriggerClientEvent('ng-thermite:client:SetActive', -1, false)
    end
end)

-- クールダウン状態チェック
QBCore.Functions.CreateCallback('ng-thermite:server:CheckCooldown', function(source, cb)
    local currentTime = os.time()
    local inCooldown = (currentTime - LastMissionTime) < Config.NextRob
    cb(inCooldown)
end)

-- 現在の警察の人数を取得
QBCore.Functions.CreateCallback('ng-thermite:server:GetCurrentCops', function(source, cb)
    local cops = 0
    local players = QBCore.Functions.GetQBPlayers()
    
    for _, v in pairs(players) do
        if v.PlayerData.job.name == Config.PoliceJob and v.PlayerData.job.onduty then
            cops = cops + 1
        end
    end
    
    cb(cops)
end)

-- チーム情報取得
QBCore.Functions.CreateCallback('ng-thermite:server:GetTeamInfo', function(source, cb)
    local src = source
    local inTeam = IsInTeam(src)
    local isLeader = (MissionTeam.leader == src)
    local teamSize = GetTeamSize()
    local teamNames = GetTeamMemberNames()
    
    cb({
        inTeam = inTeam,
        isLeader = isLeader,
        teamSize = teamSize,
        teamNames = teamNames
    })
end)

-- プレイヤーが基地に到達
RegisterNetEvent('ng-thermite:server:PlayerReachedBase', function()
    local src = source
    
    if not IsInTeam(src) then
        return
    end
    
    if BaseReached then
        DebugPrint('Base already reached, ignoring duplicate request')
        return
    end
    
    BaseReached = true
    
    DebugPrint('Base reached - Spawning entities')
    
    if MissionTeam.leader then
        TriggerClientEvent('ng-thermite:client:SetBaseReached', MissionTeam.leader)
    end
    for _, member in pairs(MissionTeam.members) do
        TriggerClientEvent('ng-thermite:client:SetBaseReached', member)
    end
    
    if MissionTeam.leader then
        DebugPrint('Sending spawn event to leader:', MissionTeam.leader)
        TriggerClientEvent('ng-thermite:client:SpawnMissionEntities', MissionTeam.leader, true)
    end
    
    for _, member in pairs(MissionTeam.members) do
        DebugPrint('Sending spawn event to member (with guards):', member)
        TriggerClientEvent('ng-thermite:client:SpawnMissionEntities', member, false)
    end
end)

-- 車両のカギをチーム全員に配布
RegisterNetEvent('ng-thermite:server:ShareVehicleKeys', function(plate)
    local src = source
    
    if not IsInTeam(src) then
        return
    end
    
    if MissionTeam.leader then
        TriggerClientEvent('ng-thermite:client:ReceiveVehicleKeys', MissionTeam.leader, plate)
    end
    for _, member in pairs(MissionTeam.members) do
        TriggerClientEvent('ng-thermite:client:ReceiveVehicleKeys', member, plate)
    end
end)

-- 車両のプレート番号をチーム全員に配布
RegisterNetEvent('ng-thermite:server:ShareVehiclePlate', function(plate)
    local src = source
    
    if not IsInTeam(src) then
        return
    end
    
    DebugPrint('Sharing vehicle plate to all team members:', plate)
    
    if MissionTeam.leader then
        TriggerClientEvent('ng-thermite:client:SetVehiclePlate', MissionTeam.leader, plate)
    end
    for _, member in pairs(MissionTeam.members) do
        TriggerClientEvent('ng-thermite:client:SetVehiclePlate', member, plate)
    end
end)

-- 報酬付与
RegisterNetEvent('ng-thermite:GiveReward', function(amount)
    local src = source
    
    if not IsInTeam(src) then
        TriggerClientEvent('QBCore:Notify', src, "チームメンバーではありません", "error")
        return
    end
    
    local teamSize = GetTeamSize()
    local rewardPerPerson = math.floor(amount / teamSize)
    
    if MissionTeam.leader then
        local Player = QBCore.Functions.GetPlayer(MissionTeam.leader)
        if Player then
            Player.Functions.AddItem(Config.RewardItem, rewardPerPerson, false)
            TriggerClientEvent('QBCore:Notify', MissionTeam.leader, "報酬として" .. Config.RewardItem .. " x" .. rewardPerPerson .. "を受け取りました！", "success")
        end
    end
    
    for _, member in pairs(MissionTeam.members) do
        local Player = QBCore.Functions.GetPlayer(member)
        if Player then
            Player.Functions.AddItem(Config.RewardItem, rewardPerPerson, false)
            TriggerClientEvent('QBCore:Notify', member, "報酬として" .. Config.RewardItem .. " x" .. rewardPerPerson .. "を受け取りました！", "success")
        end
    end
    
    local teamNamesStr = table.concat(GetTeamMemberNames(), ", ")
    DiscordLog('ミッション完了: チーム[' .. teamSize .. '人] - **' .. teamNamesStr .. '** 各報酬: $**'..rewardPerPerson..'**')
end)

-- プレイヤー切断時の処理
AddEventHandler('playerDropped', function(reason)
    local src = source
    
    if IsInTeam(src) then
        if MissionTeam.leader == src then
            for _, member in pairs(MissionTeam.members) do
                TriggerClientEvent('QBCore:Notify', member, "チームリーダーが切断したためチームが解散されました", "error")
                TriggerClientEvent('ng-thermite:client:UpdateTeam', member, 0, {})
            end
            DiscordLog('チーム解散（切断）: **'..GetPlayerName(src)..'** 理由: '..reason)
            
            if isActive then
                isActive = false
                TriggerClientEvent('ng-thermite:client:SetActive', -1, false)
            end
            ResetTeam()
        else
            for i, member in pairs(MissionTeam.members) do
                if member == src then
                    table.remove(MissionTeam.members, i)
                    break
                end
            end
            
            if MissionTeam.leader then
                TriggerClientEvent('QBCore:Notify', MissionTeam.leader, GetPlayerName(src) .. "が切断しました", "info")
                
                local teamSize = GetTeamSize()
                local teamNames = GetTeamMemberNames()
                TriggerClientEvent('ng-thermite:client:UpdateTeam', MissionTeam.leader, teamSize, teamNames)
                for _, member in pairs(MissionTeam.members) do
                    TriggerClientEvent('ng-thermite:client:UpdateTeam', member, teamSize, teamNames)
                end
            end
        end
    end
end)
