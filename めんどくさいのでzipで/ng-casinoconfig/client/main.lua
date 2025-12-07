local QBCore = exports['qb-core']:GetCoreObject()

-- プレイヤーデータの取得
local function GetPlayerData()
    return QBCore.Functions.GetPlayerData()
end

-- 権限チェック
local function HasPermission()
    local PlayerData = GetPlayerData()
    if not PlayerData.job then return false end
    
    local jobName = PlayerData.job.name
    local jobGrade = PlayerData.job.grade.level
    
    if Config.AuthorizedJobs[jobName] ~= nil and jobGrade >= Config.AuthorizedJobs[jobName] then
        return true
    end
    
    return false
end

-- 設定ファイルの読み込み
local function LoadPresetFiles(preset)
    local resourceName = GetCurrentResourceName()
    local configPath = ('configs/%s.lua'):format(preset)
    local constPath = ('consts/%s.lua'):format(preset)
    
    -- 設定ファイルを読み込む
    local configContent = LoadResourceFile(resourceName, configPath)
    if not configContent then
        lib.notify(Config.Notify.Error)
        return nil, nil
    end
    
    -- 定数ファイルを読み込む
    local constContent = LoadResourceFile(resourceName, constPath)
    
    return configContent, constContent
end

-- 設定変更メニュー
local function OpenConfigMenu()
    if not HasPermission() then
        lib.notify(Config.Notify.NoPermission)
        return
    end
    
    local options = {}
    
    for preset, label in pairs(Config.Presets) do
        table.insert(options, {
            title = label,
            description = preset .. '設定に変更します',
            icon = 'fas fa-cog',
            onSelect = function()
                local configContent, constContent = LoadPresetFiles(preset)
                if configContent then
                    TriggerServerEvent('ng-casinoconfig:server:updateConfig', configContent, constContent, preset)
                end
            end
        })
    end
    
    lib.registerContext({
        id = Config.MenuSettings.id,
        title = Config.MenuSettings.title,
        options = options,
        position = Config.MenuSettings.position,
        icon = Config.MenuSettings.icon
    })
    
    lib.showContext(Config.MenuSettings.id)
end

-- コマンド登録
RegisterCommand('casinoconfig', function()
    OpenConfigMenu()
end, false)

-- チャットのサジェスチョン登録
TriggerEvent('chat:addSuggestion', '/casinoconfig', 'カジノの設定を変更します')