-- ============================================
-- CLIENT MAIN - ng-business
-- ============================================

QBCore = exports['qb-core']:GetCoreObject()

-- Debug print function (Global for all client modules)
function DebugPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^3[DEBUG]^7 ' .. message)
end

-- Error print function (Global for all client modules)
function ErrorPrint(...)
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^1[ERROR]^7 ' .. message)
end

-- Success print function (Global for all client modules)
function SuccessPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^2[SUCCESS]^7 ' .. message)
end

-- Check if player has required job and grade
function HasRequiredJob(jobs, minGrade)
    if not jobs or #jobs == 0 then
        return true  -- No job requirement
    end
    
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData.job then
        DebugPrint('Player has no job data')
        return false
    end
    
    for _, jobName in ipairs(jobs) do
        if PlayerData.job.name == jobName then
            if PlayerData.job.grade.level >= minGrade then
                DebugPrint('Player has required job:', jobName, 'grade:', PlayerData.job.grade.level)
                return true
            else
                DebugPrint('Player job grade too low:', PlayerData.job.grade.level, 'required:', minGrade)
                return false
            end
        end
    end
    
    DebugPrint('Player does not have required job')
    return false
end

-- Draw marker function
function DrawMarkerAtCoords(coords)
    DrawMarker(
        Config.UI.marker.type,
        coords.x, coords.y, coords.z - 1.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        Config.UI.marker.size.x, Config.UI.marker.size.y, Config.UI.marker.size.z,
        Config.UI.marker.color.r, Config.UI.marker.color.g, Config.UI.marker.color.b, Config.UI.marker.color.a,
        Config.UI.marker.bobUpAndDown,
        Config.UI.marker.faceCamera,
        2,
        Config.UI.marker.rotate,
        nil,
        nil,
        Config.UI.marker.drawOnEnts
    )
end

-- Show notification
function ShowNotification(message, type)
    exports['okokNotify']:Alert('ビジネスシステム', message, Config.UI.notificationDuration, type or 'info', false)
end

-- Resource started
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    DebugPrint('ng-business client started')
    SuccessPrint('All client modules loaded successfully')
end)

-- Player loaded
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    DebugPrint('Player loaded, initializing business system')
end)

-- Job update
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    DebugPrint('Job updated:', JobInfo.name, 'grade:', JobInfo.grade.level)
end)
