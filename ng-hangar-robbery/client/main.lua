local QBCore = exports['qb-core']:GetCoreObject()

-- ローカル変数
local jobStartNpc = nil
local guards = {}
local robberyActive = false
local playerInArea = false
local hasEnteredArea = false
local robbedTrollys = {}
local trollyProps = {} -- トロリープロップ管理用
local trollyLocks = {} -- トロリーロック状態管理用（新追加）

-- デバッグ出力関数
local function DebugPrint(...)
    if Config.Debug and Config.Debug.enabled then
        print('[ng-hangar-robbery] ' .. string.format(...))
    end
end

-- NPC作成関数
local function CreateJobNPC()
    local model = Config.JobStartLocation.model
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    jobStartNpc = CreatePed(4, model, Config.JobStartLocation.coords.x, Config.JobStartLocation.coords.y, Config.JobStartLocation.coords.z - 1.0, Config.JobStartLocation.heading, false, true)
    SetEntityCanBeDamaged(jobStartNpc, false)
    SetPedCanRagdollFromPlayerImpact(jobStartNpc, false)
    SetBlockingOfNonTemporaryEvents(jobStartNpc, true)
    SetEntityInvincible(jobStartNpc, true)
    FreezeEntityPosition(jobStartNpc, true)
    
    if Config.JobStartLocation.scenario then
        TaskStartScenarioInPlace(jobStartNpc, Config.JobStartLocation.scenario, 0, true)
    end
    
    -- ox_target設定
    exports.ox_target:addLocalEntity(jobStartNpc, {
        {
            name = 'hangar_robbery_start',
            icon = 'fas fa-mask',
            label = '格納庫強盗を受注する',
            onSelect = function()
                StartJobDialog()
            end
        }
    })
end

-- 受注ダイアログ
function StartJobDialog()
    QBCore.Functions.TriggerCallback('ng-hangar-robbery:server:canStartRobbery', function(data)
        if data.canStart then
            local alert = lib.alertDialog({
                header = '格納庫強盗',
                content = '飛行場の格納庫で強盗を実行しますか？\n\n⚠️ 警告: 重武装の警備員が待機しています\n現在の警察官数: ' .. data.copCount .. '/' .. data.requiredCops,
                centered = true,
                cancel = true,
                labels = {
                    confirm = '受注する',
                    cancel = 'キャンセル'
                }
            })
            
            if alert == 'confirm' then
                TriggerServerEvent('ng-hangar-robbery:server:startJob')
            end
        else
            local reason = ''
            if data.robberyInProgress then
                reason = '現在他のプレイヤーが強盗を実行中です'
            elseif data.copCount < data.requiredCops then
                reason = '警察官が不足しています (' .. data.copCount .. '/' .. data.requiredCops .. ')'
            else
                reason = 'クールダウン中です\n残り時間: ' .. data.formattedTime
            end
            
            lib.alertDialog({
                header = '格納庫強盗',
                content = '現在受注できません\n\n' .. reason,
                centered = true
            })
        end
    end)
end

-- 強盗開始
RegisterNetEvent('ng-hangar-robbery:client:startRobbery', function()
    robberyActive = true
    robbedTrollys = {}
    trollyLocks = {} -- ロック状態をリセット（新追加）
    hasEnteredArea = false
    
    SetNewWaypoint(Config.RobberyLocation.center.x, Config.RobberyLocation.center.y)
    
    lib.notify({
        title = '格納庫強盗',
        description = '目的地をマップにマークしました。現場へ向かってください。',
        type = 'inform'
    })
    
    -- エリア監視開始
    CreateThread(function()
        local hasSpawned = false
        local inCombatRange = false
        local abandonWarningGiven = false
        local abandonmentTimer = nil
        
        while robberyActive do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - Config.RobberyLocation.center)
            
            if distance <= Config.RobberyLocation.spawnRadius and not hasEnteredArea then
                hasEnteredArea = true
                DebugPrint('プレイヤーが格納庫エリアに初回侵入しました')
            end
            
            -- 放棄距離チェック（200m）
            if hasEnteredArea and distance > 200.0 then
                if not abandonWarningGiven then
                    abandonWarningGiven = true
                    lib.notify({
                        title = '警告',
                        description = '現場から離れすぎています！30秒以内に戻らないと強盗は中止されます！',
                        type = 'error'
                    })
                    
                    abandonmentTimer = SetTimeout(30000, function()
                        if robberyActive then
                            local currentCoords = GetEntityCoords(PlayerPedId())
                            local currentDistance = #(currentCoords - Config.RobberyLocation.center)
                            
                            if currentDistance > 200.0 then
                                lib.notify({
                                    title = '強盗中止',
                                    description = '現場から離れすぎたため強盗が中止されました。クールダウンが開始されます。',
                                    type = 'error'
                                })
                                
                                TriggerServerEvent('ng-hangar-robbery:server:abandonRobbery')
                                CleanupAll()
                                return
                            end
                        end
                    end)
                end
            else
                if abandonWarningGiven and distance <= 200.0 then
                    abandonWarningGiven = false
                    if abandonmentTimer then
                        ClearTimeout(abandonmentTimer)
                        abandonmentTimer = nil
                    end
                    
                    lib.notify({
                        title = '警告解除',
                        description = '現場に戻りました。強盗を続行してください。',
                        type = 'success'
                    })
                end
            end
            
            -- NPCスポーン範囲チェック
            if distance <= Config.RobberyLocation.spawnRadius and not hasSpawned then
                hasSpawned = true
                playerInArea = true
                TriggerServerEvent('ng-hangar-robbery:server:robberyDetected')
                
                lib.notify({
                    title = '警告',
                    description = '警備範囲に侵入しました！警備員が配置されています！',
                    type = 'error'
                })
            end
            
            -- 戦闘範囲チェック
            if distance <= Config.RobberyLocation.combatRadius and hasSpawned and not inCombatRange then
                inCombatRange = true
                
                lib.notify({
                    title = '警告',
                    description = '警備員に発見されました！戦闘開始！',
                    type = 'error'
                })
                
                TriggerEvent('ng-hangar-robbery:client:startCombat')
            end
            
            -- エリア離脱チェック
            if distance > Config.RobberyLocation.spawnRadius and hasSpawned then
                playerInArea = false
                inCombatRange = false
            elseif distance <= Config.RobberyLocation.spawnRadius and hasSpawned then
                playerInArea = true
            end
            
            Wait(Config.Cooldown.checkInterval)
        end
    end)
end)

-- 強盗放棄処理
RegisterNetEvent('ng-hangar-robbery:client:robberyAbandoned', function()
    CleanupAll()
end)

-- 戦闘開始イベント
RegisterNetEvent('ng-hangar-robbery:client:startCombat', function()
    CreateThread(function()
        while #guards > 0 and robberyActive do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            for _, guard in ipairs(guards) do
                if DoesEntityExist(guard) and not IsPedDeadOrDying(guard, 1) then
                    local guardCoords = GetEntityCoords(guard)
                    local distance = #(playerCoords - guardCoords)
                    
                    if distance <= Config.RobberyLocation.combatRadius and playerInArea then
                        TaskCombatPed(guard, playerPed, 0, 16)
                        SetPedKeepTask(guard, true)
                    end
                end
            end
            
            Wait(2000)
        end
    end)
end)

-- ガード生成
RegisterNetEvent('ng-hangar-robbery:client:spawnGuards', function(shouldSpawn)
    CleanupGuards()
    
    if shouldSpawn then
        CreateThread(function()
            Wait(2000)
            
            for i, guardData in ipairs(Config.Guards) do
                local model = Config.GuardSettings.model
                
                RequestModel(model)
                local timeout = 0
                while not HasModelLoaded(model) and timeout < 10000 do
                    Wait(100)
                    timeout = timeout + 100
                end
                
                if HasModelLoaded(model) then
                    local guard = CreatePed(4, model, guardData.coords.x, guardData.coords.y, guardData.coords.z, guardData.heading, true, true)
                    
                    if DoesEntityExist(guard) then
                        SetPedMaxHealth(guard, Config.GuardSettings.health)
                        SetEntityHealth(guard, Config.GuardSettings.health)
                        SetPedArmour(guard, Config.GuardSettings.armor)
                        SetPedAccuracy(guard, Config.GuardSettings.accuracy)
                        SetPedFleeAttributes(guard, 0, 0)
                        SetPedCombatAttributes(guard, 46, 1)
                        SetPedCombatMovement(guard, 2)
                        SetPedCombatRange(guard, 2)
                        SetPedAlertness(guard, 3)
                        SetEntityCanBeDamaged(guard, true)
                        SetPedCanBeTargetted(guard, true)
                        
                        SetPedRelationshipGroupHash(guard, GetHashKey('HATES_PLAYER'))
                        SetRelationshipBetweenGroups(Config.GuardSettings.relationship, GetHashKey('HATES_PLAYER'), GetHashKey('PLAYER'))
                        
                        local weaponHash = GetHashKey(guardData.weapon)
                        GiveWeaponToPed(guard, weaponHash, 999, false, true)
                        SetPedInfiniteAmmo(guard, true, weaponHash)
                        SetCurrentPedWeapon(guard, weaponHash, true)
                        
                        SetPedCombatAbility(guard, 2)
                        SetPedSeeingRange(guard, Config.RobberyLocation.combatRadius)
                        SetPedHearingRange(guard, Config.RobberyLocation.combatRadius)
                        SetPedCombatRange(guard, 2)
                        
                        TaskGuardCurrentPosition(guard, 10.0)
                        
                        guards[#guards + 1] = guard
                        
                        DebugPrint('ガード生成完了: %d/%d', i, #Config.Guards)
                    else
                        DebugPrint('ガード生成失敗: %d', i)
                    end
                    
                    SetModelAsNoLongerNeeded(model)
                else
                    DebugPrint('モデル読み込み失敗: %s', model)
                end
                
                Wait(300)
            end
            
            DebugPrint('全ガード生成完了: %d体', #guards)
        end)
    end
    
    -- トロリー設定
    SetupTrollys()
end)

-- トロリー設定（修正版）
function SetupTrollys()
    CreateThread(function()
        for i, trollyData in ipairs(Config.Trollys) do
            -- modelが存在する場合のみプロップを作成（overheatタイプは除く）
            if trollyData.model then
                local model = trollyData.model
                RequestModel(model)
                
                local timeout = 0
                while not HasModelLoaded(model) and timeout < 10000 do
                    Wait(100)
                    timeout = timeout + 100
                end
                
                if HasModelLoaded(model) then
                    local prop = CreateObject(model, trollyData.coords.x, trollyData.coords.y, trollyData.coords.z, false, false, false)
                    
                    if DoesEntityExist(prop) then
                        SetEntityHeading(prop, trollyData.coords.w)
                        SetEntityCanBeDamaged(prop, false)
                        FreezeEntityPosition(prop, true)
                        SetEntityInvincible(prop, true)
                        
                        trollyProps[i] = prop
                        DebugPrint('トロリープロップ生成完了: %s', trollyData.label or "不明")
                    else
                        DebugPrint('トロリープロップ生成失敗: %d', i)
                    end
                    
                    SetModelAsNoLongerNeeded(model)
                else
                    DebugPrint('トロリーモデル読み込み失敗: %s', model)
                end
            end
            
            -- ox_target設定（全タイプ共通）
            local targetEntity = trollyData.model and trollyProps[i] or nil
            local targetCoords = trollyData.coords
            
            if targetEntity then
                -- プロップが存在する場合
                exports.ox_target:addLocalEntity(targetEntity, {
                    {
                        name = 'robbery_trolly_' .. i,
                        icon = trollyData.typ == 'cash_crate' and 'fas fa-money-bill-wave' or 'fas fa-tools',
                        label = trollyData.label or "アイテムを回収",
                        canInteract = function()
                            local hasItem = exports.ox_inventory:Search('count', trollyData.requiredItem) > 0
                            local isLocked = trollyLocks[i] -- ロック状態チェック（新追加）
                            return not robbedTrollys[i] and hasItem and not isLocked
                        end,
                        onSelect = function()
                            RobTrolly(i, trollyData)
                        end
                    }
                })
            else
                -- プロップが存在しない場合（overheatタイプ）はボックスゾーンを作成
                exports.ox_target:addBoxZone({
                    coords = vector3(targetCoords.x, targetCoords.y, targetCoords.z),
                    size = vector3(2.0, 2.0, 2.0),
                    rotation = targetCoords.w,
                    options = {
                        {
                            name = 'robbery_trolly_' .. i,
                            icon = 'fas fa-tools',
                            label = trollyData.label or "電子セーフをハッキング",
                            canInteract = function()
                                local hasItem = exports.ox_inventory:Search('count', trollyData.requiredItem) > 0
                                local isLocked = trollyLocks[i] -- ロック状態チェック（新追加）
                                return not robbedTrollys[i] and hasItem and not isLocked
                            end,
                            onSelect = function()
                                RobTrolly(i, trollyData)
                            end
                        }
                    }
                })
            end
            
            Wait(200)
        end
    end)
end

-- トロリーから回収（修正版）
function RobTrolly(index, trollyData)
    if robbedTrollys[index] or trollyLocks[index] then 
        if trollyLocks[index] then
            lib.notify({
                title = '回収不可',
                description = '誰かが既に回収中です。しばらく待ってください。',
                type = 'error'
            })
        end
        return 
    end
    
    -- ロック状態をサーバーに確認して設定（新追加）
    QBCore.Functions.TriggerCallback('ng-hangar-robbery:server:tryLockTrolly', function(success, lockedBy)
        if not success then
            if lockedBy then
                lib.notify({
                    title = '回収不可',
                    description = '他のプレイヤーが回収中です: ' .. lockedBy,
                    type = 'error'
                })
            else
                lib.notify({
                    title = '回収不可',
                    description = '既に回収済みです。',
                    type = 'error'
                })
            end
            return
        end
        
        -- ローカルでもロック状態を設定
        trollyLocks[index] = true
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- プレイヤーを適切な位置に向ける
        local trollyCoords = vector3(trollyData.coords.x, trollyData.coords.y, trollyData.coords.z)
        local heading = GetHeadingFromVector_2d(trollyCoords.x - playerCoords.x, trollyCoords.y - playerCoords.y)
        SetEntityHeading(playerPed, heading)
        
        -- アニメーション設定を取得
        local animConfig
        if trollyData.typ == 'cash_crate' then
            animConfig = Config.CashCrateAnimation
        elseif trollyData.typ == 'overheat' then
            animConfig = Config.OverheatAnimation
        else
            animConfig = Config.CashCrateAnimation -- デフォルト
        end
        
        -- アニメーション辞書をロード
        RequestAnimDict(animConfig.dict)
        
        local timeout = 0
        while not HasAnimDictLoaded(animConfig.dict) and timeout < 10000 do
            Wait(100)
            timeout = timeout + 100
        end
        
        if HasAnimDictLoaded(animConfig.dict) then
            -- アニメーション再生
            TaskPlayAnim(playerPed, animConfig.dict, animConfig.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
            
            local success = lib.progressBar({
                duration = animConfig.duration,
                label = animConfig.text,
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                    move = true,
                    combat = true
                }
            })
            
            -- アニメーション停止
            StopAnimTask(playerPed, animConfig.dict, animConfig.anim, 1.0)
            RemoveAnimDict(animConfig.dict)
            
            if success then
                robbedTrollys[index] = true
                
                -- プロップを削除（存在する場合）
                if trollyProps[index] and DoesEntityExist(trollyProps[index]) then
                    exports.ox_target:removeLocalEntity(trollyProps[index])
                    DeleteObject(trollyProps[index])
                    trollyProps[index] = nil
                end
                
                -- サーバーに通知
                TriggerServerEvent('ng-hangar-robbery:server:trollyRobbed', index)
                TriggerServerEvent('ng-hangar-robbery:server:giveTrollyItems', trollyData)
                
                -- 全トロリー回収チェック
                local allRobbed = true
                for i = 1, #Config.Trollys do
                    if not robbedTrollys[i] then
                        allRobbed = false
                        break
                    end
                end
                
                if allRobbed then
                    lib.notify({
                        title = '強盗完了',
                        description = '全てのアイテムを回収しました！安全な場所へ逃げてください！',
                        type = 'success'
                    })
                    
                    TriggerServerEvent('ng-hangar-robbery:server:robberyComplete')
                end
            else
                -- キャンセルされた場合はロックを解除（新追加）
                TriggerServerEvent('ng-hangar-robbery:server:unlockTrolly', index)
                trollyLocks[index] = false
            end
        else
            -- アニメーション読み込み失敗時もロックを解除（新追加）
            TriggerServerEvent('ng-hangar-robbery:server:unlockTrolly', index)
            trollyLocks[index] = false
            lib.notify({
                title = 'エラー',
                description = 'アニメーションの読み込みに失敗しました',
                type = 'error'
            })
        end
    end, index)
end

-- トロリーロック状態同期（新追加）
RegisterNetEvent('ng-hangar-robbery:client:syncTrollyLock', function(index, isLocked, playerName)
    trollyLocks[index] = isLocked
    
    if isLocked and playerName then
        DebugPrint('トロリー%d がロックされました - プレイヤー: %s', index, playerName)
    else
        DebugPrint('トロリー%d のロックが解除されました', index)
    end
end)

-- プロップクリーンアップ
function CleanupTrollyProps()
    for i, prop in pairs(trollyProps) do
        if DoesEntityExist(prop) then
            exports.ox_target:removeLocalEntity(prop)
            DeleteObject(prop)
        end
    end
    trollyProps = {}
end

-- ガードクリーンアップ
function CleanupGuards()
    for _, guard in ipairs(guards) do
        if DoesEntityExist(guard) then
            DeleteEntity(guard)
        end
    end
    guards = {}
end

-- 全体クリーンアップ
function CleanupAll()
    CleanupGuards()
    CleanupTrollyProps()
    robberyActive = false
    playerInArea = false
    hasEnteredArea = false
    robbedTrollys = {}
    trollyLocks = {} -- ロック状態もクリア（新追加）
end

-- 警察通報イベント
RegisterNetEvent('ng-hangar-robbery:client:callPolice', function()
    if GetResourceState('ps-dispatch') == 'started' then
        exports['ps-dispatch']:HangerRobbery(nil)
    end
end)

-- トロリー回収状態同期
RegisterNetEvent('ng-hangar-robbery:client:syncTrollyRobbed', function(index)
    robbedTrollys[index] = true
    trollyLocks[index] = false -- 回収完了時はロックも解除（新追加）
    
    if trollyProps[index] and DoesEntityExist(trollyProps[index]) then
        exports.ox_target:removeLocalEntity(trollyProps[index])
        DeleteObject(trollyProps[index])
        trollyProps[index] = nil
    end
end)

-- 強盗状態同期
RegisterNetEvent('ng-hangar-robbery:client:syncRobberyState', function(state)
    robbedTrollys = state.robbedTrollys or {}
    trollyLocks = state.trollyLocks or {} -- ロック状態も同期（新追加）
    
    for i, robbed in pairs(robbedTrollys) do
        if robbed and trollyProps[i] and DoesEntityExist(trollyProps[i]) then
            exports.ox_target:removeLocalEntity(trollyProps[i])
            DeleteObject(trollyProps[i])
            trollyProps[i] = nil
        end
    end
end)

-- ガードクリーンアップイベント
RegisterNetEvent('ng-hangar-robbery:client:cleanupGuards', function()
    CleanupAll()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        CreateJobNPC()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if DoesEntityExist(jobStartNpc) then
            DeleteEntity(jobStartNpc)
        end
        CleanupAll()
    end
end)

-- プレイヤーログイン時
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    CreateJobNPC()
    
    QBCore.Functions.TriggerCallback('ng-hangar-robbery:server:getRobberyState', function(data)
        if data.robberyInProgress and data.robberyStarted then
            robbedTrollys = data.robbedTrollys or {}
            trollyLocks = data.trollyLocks or {} -- ロック状態も取得（新追加）
            SetupTrollys()
            
            lib.notify({
                title = '格納庫強盗',
                description = '格納庫強盗が進行中です。現場に参加できます。',
                type = 'inform'
            })
            
            StartAreaMonitoring()
        end
    end)
end)

-- エリア監視開始
function StartAreaMonitoring()
    CreateThread(function()
        while true do
            QBCore.Functions.TriggerCallback('ng-hangar-robbery:server:getRobberyState', function(data)
                if not data.robberyInProgress or not data.robberyStarted then
                    return
                end
                
                local playerCoords = GetEntityCoords(PlayerPedId())
                local distance = #(playerCoords - Config.RobberyLocation.center)
                
                if distance <= Config.RobberyLocation.spawnRadius then
                    local hasProps = false
                    for _, prop in pairs(trollyProps) do
                        if DoesEntityExist(prop) then
                            hasProps = true
                            break
                        end
                    end
                    
                    if not hasProps then
                        robbedTrollys = data.robbedTrollys or {}
                        trollyLocks = data.trollyLocks or {} -- ロック状態も更新（新追加）
                        SetupTrollys()
                    end
                end
            end)
            
            Wait(5000)
        end
    end)
end

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    CleanupAll()
end)

-- 警察専用リセットコマンド
RegisterCommand('pdhanger', function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    
    if PlayerData.job.type == 'leo' and PlayerData.job.onduty then
        local alert = lib.alertDialog({
            header = '格納庫強盗リセット',
            content = '格納庫強盗の状態をリセットしますか？\n\n• 進行中の強盗を強制終了\n• NPCを全て削除\n• クールダウンをリセット\n• トロリープロップをリセット',
            centered = true,
            cancel = true,
            labels = {
                confirm = 'リセット実行',
                cancel = 'キャンセル'
            }
        })
        
        if alert == 'confirm' then
            TriggerServerEvent('ng-hangar-robbery:server:policeReset')
            CleanupAll()
        end
    else
        lib.notify({
            title = '権限エラー',
            description = '警察官のみが実行できるコマンドです',
            type = 'error'
        })
    end
end, false)

TriggerEvent('chat:addSuggestion', '/pdhanger', '格納庫強盗の状態をリセット（警察専用）')