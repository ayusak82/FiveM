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

-- 状態管理
local currentVehicle = nil
local originalEngineSound = nil
local isEngineModified = false
local availableSounds = {}

-- エンジン音を適用する関数
local function ApplyEngineSound(soundName)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        lib.notify({
            title = 'エンジン音',
            description = '車両に乗車してください',
            type = 'error'
        })
        ErrorPrint('Player is not in a vehicle')
        return false
    end

    if isEngineModified then
        lib.notify({
            title = 'エンジン音',
            description = '既にエンジン音が適用されています。/stop で元に戻してください',
            type = 'error'
        })
        return false
    end

    currentVehicle = vehicle
    
    DebugPrint('Applying engine sound:', soundName)
    
    -- エンジン音を設定
    ForceVehicleEngineAudio(vehicle, soundName)
    isEngineModified = true
    
    lib.notify({
        title = 'エンジン音適用',
        description = 'エンジン音: ' .. soundName .. '\n/stop で元に戻せます',
        type = 'success'
    })
    
    SuccessPrint('Engine sound applied:', soundName)
    return true
end

-- エンジン音を元に戻す関数
local function RestoreEngineSound()
    if not isEngineModified then
        lib.notify({
            title = 'エンジン音',
            description = 'エンジン音は変更されていません',
            type = 'error'
        })
        return
    end

    if DoesEntityExist(currentVehicle) then
        ForceVehicleEngineAudio(currentVehicle, "")
        DebugPrint('Engine sound restored')
    end

    isEngineModified = false
    currentVehicle = nil
    originalEngineSound = nil

    lib.notify({
        title = 'エンジン音復元',
        description = '元のエンジン音に戻しました',
        type = 'success'
    })
    
    SuccessPrint('Engine sound restored')
end

-- 利用可能なエンジン音をスキャンする関数
local function ScanAvailableSounds()
    DebugPrint('Scanning for available engine sounds...')
    availableSounds = {}
    
    -- Config.CommonEngineSoundsから利用可能な音をチェック
    for _, soundName in ipairs(Config.CommonEngineSounds) do
        table.insert(availableSounds, soundName)
    end
    
    SuccessPrint('Found', #availableSounds, 'engine sounds')
    return availableSounds
end

-- メニューを開く関数
local function OpenEngineMenu()
    if #availableSounds == 0 then
        ScanAvailableSounds()
    end

    local options = {}
    
    -- 情報表示
    table.insert(options, {
        title = '利用可能なエンジン音: ' .. #availableSounds .. '個',
        description = '下から選択してエンジン音を適用',
        icon = 'info-circle',
        disabled = true
    })

    -- 区切り線
    table.insert(options, {
        title = '─────────────────',
        disabled = true
    })

    -- エンジン音リスト
    for _, soundName in ipairs(availableSounds) do
        table.insert(options, {
            title = soundName,
            description = 'このエンジン音を適用',
            icon = 'volume-high',
            onSelect = function()
                ApplyEngineSound(soundName)
            end
        })
    end

    -- 区切り線
    table.insert(options, {
        title = '─────────────────',
        disabled = true
    })

    -- カスタム入力
    table.insert(options, {
        title = 'カスタムエンジン音',
        description = 'エンジン音名を手動入力',
        icon = 'keyboard',
        onSelect = function()
            local input = lib.inputDialog('エンジン音適用', {
                {
                    type = 'input',
                    label = 'エンジン音名',
                    description = '適用するエンジン音の名前を入力',
                    required = true,
                    min = 1,
                    max = 50
                }
            })

            if input and input[1] then
                ApplyEngineSound(input[1])
            end
        end
    })

    -- エンジン音を戻す
    if isEngineModified then
        table.insert(options, {
            title = 'エンジン音を元に戻す',
            description = '元のエンジン音に戻す',
            icon = 'rotate-left',
            iconColor = 'orange',
            onSelect = function()
                RestoreEngineSound()
            end
        })
    end

    lib.registerContext({
        id = 'engine_sound_menu',
        title = 'エンジン音チェンジャー',
        options = options
    })

    lib.showContext('engine_sound_menu')
end

-- コマンド登録（メニュー表示）
RegisterCommand('engine', function()
    DebugPrint('Command executed: engine')
    OpenEngineMenu()
end, false)

-- コマンド登録（直接適用）
RegisterCommand('engine', function(source, args)
    if #args < 1 then
        DebugPrint('Opening engine menu')
        OpenEngineMenu()
        return
    end

    local soundName = args[1]
    DebugPrint('Command executed: engine', soundName)
    ApplyEngineSound(soundName)
end, false)

-- コマンド登録（元に戻す）
RegisterCommand('stop', function()
    DebugPrint('Command executed: stop')
    RestoreEngineSound()
end, false)

-- 車両から降りた時の処理
CreateThread(function()
    while true do
        Wait(1000)
        
        if isEngineModified then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            -- 車両から降りた、または車両が変わった場合
            if vehicle == 0 or vehicle ~= currentVehicle then
                DebugPrint('Player left vehicle, restoring engine sound')
                isEngineModified = false
                currentVehicle = nil
                originalEngineSound = nil
            end
        end
    end
end)

-- スクリプト起動時
CreateThread(function()
    -- エンジン音リストをスキャン
    ScanAvailableSounds()
    
    SuccessPrint('Engine Sound Tester loaded successfully')
    print('^2[ng-enginesound-tester]^7 Script loaded')
    print('^3Commands:^7')
    print('  /engine - Open engine sound menu')
    print('  /engine [sound_name] - Apply specific engine sound')
    print('  /stop - Restore original engine sound')
    print('^3Available sounds:^7 ' .. #availableSounds)
end)
