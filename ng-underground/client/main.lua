local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local isInBase = false
local currentStamina = Config.WorkSettings.MaxStamina
local onCooldown = false

-- プレイヤーデータ取得
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

-- 初期化
CreateThread(function()
    PlayerData = QBCore.Functions.GetPlayerData()
    
    -- 地下基地マップを有効化
    EnableUndergroundBunker()
    
    -- 地下基地入口の設定
    SetupEntrancePoint()
    
    -- スタミナ回復ループ
    CreateThread(function()
        while true do
            if currentStamina < Config.WorkSettings.MaxStamina then
                currentStamina = math.min(currentStamina + Config.WorkSettings.StaminaRegenRate, Config.WorkSettings.MaxStamina)
            end
            Wait(1000)
        end
    end)
end)

-- 入口ポイント設定
function SetupEntrancePoint()
    local entrance = Config.EntranceLocation
    
    -- マーカー描画
    CreateThread(function()
        while true do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - entrance.coords)
            
            if distance < 50.0 then
                DrawMarker(
                    entrance.marker.type,
                    entrance.coords.x, entrance.coords.y, entrance.coords.z,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    entrance.marker.size.x, entrance.marker.size.y, entrance.marker.size.z,
                    entrance.marker.color.r, entrance.marker.color.g, entrance.marker.color.b, entrance.marker.color.a,
                    entrance.marker.bobUpAndDown,
                    entrance.marker.faceCamera,
                    2,
                    entrance.marker.rotate,
                    nil, nil, false
                )
            end
            Wait(0)
        end
    end)
    
    -- ox_target設定
    exports.ox_target:addBoxZone({
        coords = entrance.coords,
        size = vec3(2, 2, 2),
        rotation = entrance.heading,
        options = {
            {
                name = 'ng_underground_enter',
                icon = 'fas fa-door-open',
                label = Config.Messages.EnterBase,
                onSelect = function()
                    EnterUndergroundBase()
                end,
                canInteract = function()
                    return not isInBase and HasAllowedJob() and not IsInTransition()
                end
            }
        }
    })
end

-- 地下基地内部の設定
function SetupUndergroundBase()
    local base = Config.UndergroundBase
    
    -- 化学物質精製ステーション
    exports.ox_target:addBoxZone({
        coords = base.ChemicalStation.coords,
        size = vec3(2, 2, 2),
        rotation = base.ChemicalStation.heading,
        options = {
            {
                name = 'ng_underground_chemical',
                icon = 'fas fa-flask',
                label = Config.Messages.StartChemical,
                onSelect = function()
                    StartChemicalWork()
                end,
                canInteract = function()
                    return isInBase and not onCooldown and currentStamina >= Config.WorkSettings.StaminaDecreasePerWork
                end
            }
        }
    })
    
    -- 機械部品組み立てステーション
    exports.ox_target:addBoxZone({
        coords = base.MechanicalStation.coords,
        size = vec3(2, 2, 2),
        rotation = base.MechanicalStation.heading,
        options = {
            {
                name = 'ng_underground_mechanical',
                icon = 'fas fa-cogs',
                label = Config.Messages.StartMechanical,
                onSelect = function()
                    StartMechanicalWork()
                end,
                canInteract = function()
                    return isInBase and not onCooldown and currentStamina >= Config.WorkSettings.StaminaDecreasePerWork
                end
            }
        }
    })
    
    -- 出口
    exports.ox_target:addBoxZone({
        coords = base.ExitLocation.coords,
        size = vec3(2, 2, 2),
        rotation = base.ExitLocation.heading,
        options = {
            {
                name = 'ng_underground_exit',
                icon = 'fas fa-door-closed',
                label = Config.Messages.ExitBase,
                onSelect = function()
                    ExitUndergroundBase()
                end,
                canInteract = function()
                    return isInBase and not IsInTransition()
                end
            }
        }
    })
end

-- 地下基地入場
function EnterUndergroundBase()
    if not HasAllowedJob() then
        lib.notify({
            title = 'アクセス拒否',
            description = Config.Messages.NoJob,
            type = 'error'
        })
        return
    end
    
    -- カメラシーケンス開始
    StartEntranceSequence()
end

-- 地下基地退場
function ExitUndergroundBase()
    StartExitSequence()
end

-- 化学物質精製作業開始
function StartChemicalWork()
    if not CanWork() then return end
    
    -- プログレスバー表示
    if lib.progressBar({
        duration = 2000,
        label = '機械を準備中...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_ped'
        }
    }) then
        -- ミニゲーム開始
        StartMinigame('chemical')
    end
end

-- 機械部品組み立て作業開始
function StartMechanicalWork()
    if not CanWork() then return end
    
    -- プログレスバー表示
    if lib.progressBar({
        duration = 2000,
        label = '作業台を準備中...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_ped'
        }
    }) then
        -- ミニゲーム開始
        StartMinigame('mechanical')
    end
end

-- ミニゲーム開始
function StartMinigame(gameType)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'startGame',
        gameType = gameType,
        config = Config.Minigames[gameType == 'chemical' and 'Chemical' or 'Mechanical']
    })
end

-- NUIコールバック
RegisterNUICallback('gameResult', function(data, cb)
    SetNuiFocus(false, false)
    
    local success = data.success
    local gameType = data.gameType
    
    if success then
        -- 作業成功
        currentStamina = currentStamina - Config.WorkSettings.StaminaDecreasePerWork
        SetCooldown()
        
        -- サーバーに結果送信
        TriggerServerEvent('ng-underground:workComplete', gameType, success)
        
        lib.notify({
            title = '作業完了',
            description = Config.Messages.Success,
            type = 'success'
        })
    else
        -- 作業失敗
        currentStamina = currentStamina - (Config.WorkSettings.StaminaDecreasePerWork / 2)
        SetCooldown()
        
        lib.notify({
            title = '作業失敗',
            description = Config.Messages.Failed,
            type = 'error'
        })
    end
    
    cb('ok')
end)

RegisterNUICallback('closeGame', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- 作業可能チェック
function CanWork()
    if currentStamina < Config.WorkSettings.StaminaDecreasePerWork then
        lib.notify({
            title = 'スタミナ不足',
            description = Config.Messages.NotEnoughStamina,
            type = 'error'
        })
        return false
    end
    
    if onCooldown then
        lib.notify({
            title = 'クールダウン中',
            description = Config.Messages.OnCooldown,
            type = 'error'
        })
        return false
    end
    
    return true
end

-- クールダウン設定
function SetCooldown()
    onCooldown = true
    SetTimeout(Config.WorkSettings.WorkCooldown, function()
        onCooldown = false
    end)
end

-- 許可されたjobチェック
function HasAllowedJob()
    if not PlayerData.job then return false end
    
    for _, job in pairs(Config.AllowedJobs) do
        if PlayerData.job.name == job then
            return true
        end
    end
    return false
end

-- 基地内状態設定
function SetInBaseState(state)
    isInBase = state
    if state then
        SetupUndergroundBase()
    end
end

-- 地下基地マップ有効化
function EnableUndergroundBunker()
    -- 地下基地のIPL（Interior Proxy List）を有効化
    local bunkerIpls = {
        'gr_case0_bunkerclosed',
        'gr_case1_bunkerclosed', 
        'gr_case2_bunkerclosed',
        'gr_case3_bunkerclosed',
        'gr_case4_bunkerclosed',
        'gr_case5_bunkerclosed',
        'gr_case6_bunkerclosed',
        'gr_case7_bunkerclosed',
        'gr_case9_bunkerclosed',
        'gr_case10_bunkerclosed',
        'gr_case11_bunkerclosed',
        
        -- 地下基地内部
        'gr_grdlc_interior_v1_bunkerclosed',
        'gr_grdlc_interior_v2_bunkerclosed',
        'gr_grdlc_interior_v3_bunkerclosed',
        
        -- バンカー内部（推奨）
        'xm_bunkerentrance_door',
        'xm_hatch_closed',
        'xm_hatch_open',
        'xm_hatch_01',
        'xm_hatch_02',
        'xm_hatch_03',
        'xm_hatch_04',
        'xm_hatch_06',
        'xm_hatch_07',
        'xm_hatch_08',
        'xm_hatch_09',
        'xm_hatch_10',
        
        -- プレイヤー用地下基地
        'gr_grdlc_interior_placement',
        'gr_grdlc_interior_placement_interior_0_grdlc_int_01_milo_',
        'gr_grdlc_interior_placement_interior_1_grdlc_int_02_milo_'
    }
    
    -- すべてのIPLを有効化
    for _, ipl in pairs(bunkerIpls) do
        RequestIpl(ipl)
    end
    
    if Config.Debug then
        print('[ng-underground] Underground bunker IPLs loaded')
    end
end

-- デバッグコマンド
if Config.Debug then
    RegisterCommand('ng_debug_stamina', function()
        print('Current Stamina: ' .. currentStamina)
        print('On Cooldown: ' .. tostring(onCooldown))
        print('In Base: ' .. tostring(isInBase))
    end)
    
    RegisterCommand('ng_debug_teleport', function()
        SetEntityCoords(PlayerPedId(), Config.UndergroundBase.coords.x, Config.UndergroundBase.coords.y, Config.UndergroundBase.coords.z)
        SetEntityHeading(PlayerPedId(), Config.UndergroundBase.heading)
        SetInBaseState(true)
    end)
    
    RegisterCommand('ng_reload_ipl', function()
        EnableUndergroundBunker()
        print('[ng-underground] IPLs reloaded')
    end)
end