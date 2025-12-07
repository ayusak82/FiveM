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

local function WarnPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^5[WARNING]^7 ' .. message)
end

-- グローバル変数
local isSessionActive = false
local blips = {}

-- ブリップ作成
local function CreateBlips()
    for i, range in ipairs(Config.ShootingRanges) do
        if range.blip.enabled then
            local blip = AddBlipForCoord(range.interactionPoint.x, range.interactionPoint.y, range.interactionPoint.z)
            SetBlipSprite(blip, range.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, range.blip.scale)
            SetBlipColour(blip, range.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(range.name)
            EndTextCommandSetBlipName(blip)
            
            table.insert(blips, blip)
            DebugPrint('Blip created for', range.name)
        end
    end
end

-- ブリップ削除
local function RemoveBlips()
    for _, blip in ipairs(blips) do
        RemoveBlip(blip)
    end
    blips = {}
    DebugPrint('All blips removed')
end

-- マーカー描画スレッド
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        for _, range in ipairs(Config.ShootingRanges) do
            local distance = #(playerCoords - range.interactionPoint)
            
            if distance < Config.GameSettings.markerDrawDistance then
                sleep = 0
                DrawMarker(
                    range.marker.type,
                    range.interactionPoint.x,
                    range.interactionPoint.y,
                    range.interactionPoint.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    range.marker.scale.x,
                    range.marker.scale.y,
                    range.marker.scale.z,
                    range.marker.color.r,
                    range.marker.color.g,
                    range.marker.color.b,
                    range.marker.color.a,
                    false, true, 2, false, nil, nil, false
                )
                
                if distance < Config.GameSettings.interactionDistance then
                    -- 3Dテキスト表示
                    local onScreen, _x, _y = World3dToScreen2d(
                        range.interactionPoint.x,
                        range.interactionPoint.y,
                        range.interactionPoint.z
                    )
                    
                    if onScreen then
                        SetTextScale(0.35, 0.35)
                        SetTextFont(0)
                        SetTextProportional(1)
                        SetTextColour(255, 255, 255, 215)
                        SetTextEntry("STRING")
                        SetTextCentre(true)
                        AddTextComponentString(Config.Locale['press_e'])
                        DrawText(_x, _y)
                    end
                    
                    -- Eキー入力チェック
                    if IsControlJustReleased(0, 38) and not isSessionActive then
                        StartPracticeMenu(range)
                    end
                end
            end
        end
        
        Citizen.Wait(sleep)
    end
end)

-- 練習開始メニュー
function StartPracticeMenu(range)
    if isSessionActive then
        exports['okokNotify']:Alert(
            Config.Locale['start_practice'],
            Config.Locale['session_active'],
            3000,
            'error',
            true
        )
        return
    end
    
    DebugPrint('Opening practice menu for', range.name)
    
    local input = lib.inputDialog(Config.Locale['start_practice'], {
        {
            type = 'number',
            label = Config.Locale['target_count'],
            description = Config.Locale['target_count_desc'],
            default = Config.GameSettings.defaultTargets,
            min = Config.GameSettings.minTargets,
            max = Config.GameSettings.maxTargets,
            required = true
        }
    })
    
    if not input then
        DebugPrint('Practice menu cancelled')
        return
    end
    
    local targetCount = tonumber(input[1])
    
    if not targetCount or targetCount < Config.GameSettings.minTargets or targetCount > Config.GameSettings.maxTargets then
        exports['okokNotify']:Alert(
            Config.Locale['start_practice'],
            Config.Locale['invalid_input'],
            3000,
            'error',
            true
        )
        ErrorPrint('Invalid target count:', targetCount)
        return
    end
    
    DebugPrint('Starting practice with', targetCount, 'targets')
    
    exports['okokNotify']:Alert(
        Config.Locale['start_practice'],
        Config.Locale['practice_started'],
        3000,
        'success',
        true
    )
    
    -- 射撃練習開始
    StartShootingPractice(range, targetCount)
end

-- リソース開始時
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    DebugPrint('Resource started:', resourceName)
    CreateBlips()
end)

-- リソース停止時
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    DebugPrint('Resource stopping:', resourceName)
    RemoveBlips()
    
    -- セッションがアクティブな場合は終了
    if isSessionActive then
        EndSession()
    end
end)

-- プレイヤースポーン時
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    DebugPrint('Player loaded, creating blips')
    CreateBlips()
end)

-- セッション状態の取得/設定（他のファイルから使用）
function IsSessionActive()
    return isSessionActive
end

function SetSessionActive(state)
    isSessionActive = state
    DebugPrint('Session active state changed to:', state)
end
