local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local isLoggedIn = false
local globalHeistActive = false -- グローバル強盗状態
local insideHeist = false
local alarmPlaying = false
local dataCollected = 0
local npcsSpawned = {}
local blips = {}
local syncedDataPoints = {} -- 同期されたデータポイント状態

-- フレームワーク初期化
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    isLoggedIn = true
    
    -- 少し遅延してから初期化
    Wait(2000)
    InitializeHeist()
    
    if Config.Debug then
        print('[ng-iaaheist] Player loaded and heist initialized')
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
    PlayerData = {}
    CleanupHeist()
    
    if Config.Debug then
        print('[ng-iaaheist] Player unloaded and heist cleaned up')
    end
end)

-- リソース開始時の初期化も追加
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- プレイヤーが既にログインしている場合
        if LocalPlayer.state.isLoggedIn then
            PlayerData = QBCore.Functions.GetPlayerData()
            isLoggedIn = true
            Wait(2000)
            InitializeHeist()
            
            -- 強盗状態をチェック
            QBCore.Functions.TriggerCallback('ng-iaaheist:server:GetHeistStatus', function(status)
                if status.active then
                    globalHeistActive = true
                    syncedDataPoints = status.hackedDataPoints or {}
                    CreateHeistBlip()
                end
            end)
        end
        
        if Config.Debug then
            print('[ng-iaaheist] Resource started and initialized')
        end
    end
end)

-- 初期化
function InitializeHeist()
    -- NUIを初期化
    SendNUIMessage({
        action = 'initialize'
    })
    
    CreateHeistStartPed()
    CreateBlips()
    CreateZones()
    
    if Config.Debug then
        print('[ng-iaaheist] Heist system initialized')
    end
end

-- 強盗開始NPC作成
function CreateHeistStartPed()
    CreateThread(function()
        local model = Config.HeistStart.ped
        local modelHash = GetHashKey(model)
        
        if Config.Debug then
            print('[ng-iaaheist] Creating heist start ped with model: ' .. model)
        end
        
        -- モデルをリクエスト
        if not HasModelLoaded(modelHash) then
            RequestModel(modelHash)
            local timeout = 0
            while not HasModelLoaded(modelHash) and timeout < 10000 do
                Wait(100)
                timeout = timeout + 100
            end
            
            if not HasModelLoaded(modelHash) then
                print('[ng-iaaheist] Failed to load heist start ped model: ' .. model)
                return
            end
        end
        
        -- NPCを作成
        local ped = CreatePed(4, modelHash, Config.HeistStart.coords.x, Config.HeistStart.coords.y, Config.HeistStart.coords.z, Config.HeistStart.heading, false, true)
        
        -- NPCが作成されるまで待機
        local pedTimeout = 0
        while not DoesEntityExist(ped) and pedTimeout < 5000 do
            Wait(100)
            pedTimeout = pedTimeout + 100
        end
        
        if not DoesEntityExist(ped) then
            print('[ng-iaaheist] Failed to create heist start ped')
            return
        end
        
        -- NPCの設定
        SetEntityAsMissionEntity(ped, true, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedCanBeTargetted(ped, false)
        SetPedCanBeDraggedOut(ped, false)
        
        if Config.Debug then
            print('[ng-iaaheist] Heist start ped created successfully at: ' .. Config.HeistStart.coords.x .. ', ' .. Config.HeistStart.coords.y .. ', ' .. Config.HeistStart.coords.z)
        end
        
        -- モデルをアンロード
        SetModelAsNoLongerNeeded(modelHash)
    end)
end

-- ブリップ作成
function CreateBlips()
    -- 強盗開始地点
    local startBlip = AddBlipForCoord(Config.HeistStart.coords.x, Config.HeistStart.coords.y, Config.HeistStart.coords.z)
    SetBlipSprite(startBlip, 434)
    SetBlipDisplay(startBlip, 4)
    SetBlipScale(startBlip, 0.8)
    SetBlipColour(startBlip, 1)
    SetBlipAsShortRange(startBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('IAA強盗受注')
    EndTextCommandSetBlipName(startBlip)
    table.insert(blips, startBlip)
end

-- ゾーン作成
function CreateZones()
    -- 強盗開始ターゲット
    exports.ox_target:addSphereZone({
        coords = Config.HeistStart.coords,
        radius = 3.0,
        debug = Config.Debug,
        options = {
            {
                name = 'start_heist',
                icon = 'fa-solid fa-user-secret',
                label = Config.HeistStart.label,
                canInteract = function()
                    return not globalHeistActive
                end,
                onSelect = function()
                    if Config.Debug then
                        print('[ng-iaaheist] Target interaction for heist start')
                    end
                    StartHeistDialog()
                end,
            }
        }
    })
end

-- 強盗開始ダイアログ
function StartHeistDialog()
    local alert = lib.alertDialog({
        header = 'IAA強盗',
        content = 'IAA基地から機密データを盗み出しますか？\n\n危険度：高\n報酬：ハードディスク（データ）\n\n※開始すると全プレイヤーが参加可能になります',
        centered = true,
        cancel = true,
        labels = {
            confirm = '受注する',
            cancel = 'キャンセル'
        }
    })
    
    if alert == 'confirm' then
        TriggerServerEvent('ng-iaaheist:server:StartHeist')
    end
end

-- グローバル強盗開始
RegisterNetEvent('ng-iaaheist:client:GlobalHeistStarted', function()
    globalHeistActive = true
    syncedDataPoints = {} -- データポイント状態をリセット
    CreateHeistBlip()
    
    lib.notify({
        title = 'IAA強盗開始',
        description = 'IAA強盗が開始されました！基地に向かってください',
        type = 'inform',
        duration = 7000
    })
end)

-- データポイント同期
RegisterNetEvent('ng-iaaheist:client:SyncDataPoint', function(pointId, hacked)
    syncedDataPoints[pointId] = hacked
    if Config.Debug then
        print('[ng-iaaheist] Data point ' .. pointId .. ' synced: ' .. tostring(hacked))
    end
end)

-- NPC同期
RegisterNetEvent('ng-iaaheist:client:SyncNPCs', function(npcData)
    for index, npcInfo in pairs(npcData) do
        if npcInfo.killed then
            -- 既に削除されたNPCは削除
            if npcsSpawned[index] and DoesEntityExist(npcsSpawned[index]) then
                DeleteEntity(npcsSpawned[index])
                npcsSpawned[index] = nil
            end
        end
    end
end)

-- NPC削除同期
RegisterNetEvent('ng-iaaheist:client:RemoveNPC', function(npcIndex)
    if npcsSpawned[npcIndex] and DoesEntityExist(npcsSpawned[npcIndex]) then
        DeleteEntity(npcsSpawned[npcIndex])
        npcsSpawned[npcIndex] = nil
        
        if Config.Debug then
            print('[ng-iaaheist] NPC ' .. npcIndex .. ' removed via sync')
        end
    end
end)

-- 全NPCクリーンアップ
RegisterNetEvent('ng-iaaheist:client:CleanupAllNPCs', function()
    CleanupNPCs()
end)

-- 強制NPCクリーンアップ（リソース再起動時）
RegisterNetEvent('ng-iaaheist:client:ForceCleanupNPCs', function()
    -- より強力なNPCクリーンアップ
    ForceCleanupAllNPCs()
end)

-- グローバル強盗終了
RegisterNetEvent('ng-iaaheist:client:GlobalHeistEnded', function()
    globalHeistActive = false
    insideHeist = false
    dataCollected = 0
    syncedDataPoints = {}
    
    -- 警報停止
    StopAlarm()
    
    -- NPCクリーンアップ
    CleanupNPCs()
    
    -- ブリップクリーンアップ
    for _, blip in pairs(blips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    blips = {}
    
    -- 初期化
    CreateBlips()
    
    lib.notify({
        title = 'IAA強盗終了',
        description = '強盗が終了しました',
        type = 'inform',
        duration = 5000
    })
end)

-- 強盗ブリップ作成
function CreateHeistBlip()
    local heistBlip = AddBlipForCoord(Config.IAA_Entrance.coords.x, Config.IAA_Entrance.coords.y, Config.IAA_Entrance.coords.z)
    SetBlipSprite(heistBlip, 161)
    SetBlipDisplay(heistBlip, 4)
    SetBlipScale(heistBlip, 1.0)
    SetBlipColour(heistBlip, 1)
    SetBlipAsShortRange(heistBlip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('IAA基地入口')
    EndTextCommandSetBlipName(heistBlip)
    table.insert(blips, heistBlip)
    
    -- 入口ターゲット作成
    exports.ox_target:addSphereZone({
        coords = Config.IAA_Entrance.coords,
        radius = 5.0,
        debug = Config.Debug,
        options = {
            {
                name = 'enter_heist',
                icon = 'fa-solid fa-door-open',
                label = Config.IAA_Entrance.label,
                canInteract = function()
                    return globalHeistActive and not insideHeist
                end,
                onSelect = function()
                    if Config.Debug then
                        print('[ng-iaaheist] Target interaction for heist entrance')
                    end
                    EnterHeist()
                end,
            }
        }
    })
end

-- 基地侵入
function EnterHeist()
    insideHeist = true
    
    -- 強盗参加をサーバーに通知
    TriggerServerEvent('ng-iaaheist:server:JoinHeist')
    
    -- テレポート
    DoScreenFadeOut(1000)
    Wait(1000)
    SetEntityCoords(PlayerPedId(), Config.IAA_Interior.coords.x, Config.IAA_Interior.coords.y, Config.IAA_Interior.coords.z)
    SetEntityHeading(PlayerPedId(), Config.IAA_Interior.heading)
    Wait(1000)
    DoScreenFadeIn(1000)
    
    -- フェードイン完了を待つ
    Wait(1500)
    
    -- NUIを初期化（テレポート後）
    SendNUIMessage({
        action = 'initialize'
    })
    
    -- 少し待ってから警報開始
    Wait(500)
    StartAlarm()
    
    -- NPCスポーン（警報開始後）
    Wait(1000)
    SpawnNPCs()
    
    -- NPC同期を要求
    TriggerServerEvent('ng-iaaheist:server:RequestNPCSync')
    
    -- データポイント作成
    CreateDataPoints()
    
    -- 脱出ポイント作成
    CreateExitPoint()
    
    lib.notify({
        title = 'IAA強盗',
        description = '基地に侵入しました！データを回収してください',
        type = 'warning',
        duration = 5000
    })
    
    if Config.Debug then
        print('[ng-iaaheist] Player entered heist area')
    end
end

-- 警報開始
function StartAlarm()
    if not alarmPlaying then
        alarmPlaying = true
        
        if Config.Debug then
            print('[ng-iaaheist] Starting alarm sound')
        end
        
        -- 複数回試行して確実に音声を再生
        CreateThread(function()
            for i = 1, 3 do
                -- NUIに警報開始メッセージを送信
                SendNUIMessage({
                    action = 'playAlarm',
                    sound = Config.Alarm.soundFile,
                    volume = Config.Alarm.volume
                })
                
                if Config.Debug then
                    print('[ng-iaaheist] Alarm message sent, attempt: ' .. i)
                end
                
                Wait(500) -- 500ms待機してから次の試行
            end
        end)
        
        -- フォールバック：警報音が再生されない場合の代替手段
        CreateThread(function()
            Wait(2000) -- 2秒後にチェック
            if alarmPlaying then
                -- 代替警報音（ゲーム内サウンド）
                PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", true)
                
                if Config.Debug then
                    print('[ng-iaaheist] Fallback alarm sound played')
                end
            end
        end)
    end
end

-- 警報停止
function StopAlarm()
    if alarmPlaying then
        alarmPlaying = false
        
        if Config.Debug then
            print('[ng-iaaheist] Stopping alarm sound')
        end
        
        SendNUIMessage({
            action = 'stopAlarm'
        })
        
        -- フォールバック音も停止
        StopSound(-1)
    end
end

-- NPC敵スポーン
function SpawnNPCs()
    if Config.Debug then
        print('[ng-iaaheist] Starting NPC spawn process...')
    end
    
    for k, npc in pairs(Config.NPCs) do
        CreateThread(function()
            -- モデルをリクエスト
            local modelHash = GetHashKey(npc.model)
            if not HasModelLoaded(modelHash) then
                RequestModel(modelHash)
                local timeout = 0
                while not HasModelLoaded(modelHash) and timeout < 10000 do
                    Wait(100)
                    timeout = timeout + 100
                end
                
                if not HasModelLoaded(modelHash) then
                    print('[ng-iaaheist] Failed to load model: ' .. npc.model)
                    return
                end
            end
            
            -- NPCを作成
            local ped = CreatePed(4, modelHash, npc.coords.x, npc.coords.y, npc.coords.z, npc.heading, true, true)
            
            -- NPCが作成されるまで待機
            local pedTimeout = 0
            while not DoesEntityExist(ped) and pedTimeout < 5000 do
                Wait(100)
                pedTimeout = pedTimeout + 100
            end
            
            if not DoesEntityExist(ped) then
                print('[ng-iaaheist] Failed to create NPC at index: ' .. k)
                return
            end
            
            -- NPCの設定
            SetEntityAsMissionEntity(ped, true, true)
            SetEntityMaxHealth(ped, npc.health)
            SetEntityHealth(ped, npc.health)
            SetPedArmour(ped, npc.armor)
            
            -- 武器を付与
            local weaponHash = GetHashKey(npc.weapon)
            GiveWeaponToPed(ped, weaponHash, 250, false, true)
            SetPedInfiniteAmmo(ped, true, weaponHash)
            
            -- 戦闘設定
            SetPedCombatAttributes(ped, 46, true)
            SetPedCombatAttributes(ped, 0, false)
            SetPedCombatAttributes(ped, 5, true)
            SetPedCombatAbility(ped, 100)
            SetPedCombatMovement(ped, 2)
            SetPedCombatRange(ped, 2)
            SetPedAlertness(ped, 3)
            SetPedAccuracy(ped, 75)
            
            -- プレイヤーとの関係設定
            SetPedRelationshipGroupHash(ped, GetHashKey('HATES_PLAYER'))
            SetRelationshipBetweenGroups(5, GetHashKey('HATES_PLAYER'), GetHashKey('PLAYER'))
            SetRelationshipBetweenGroups(5, GetHashKey('PLAYER'), GetHashKey('HATES_PLAYER'))
            
            -- 戦闘開始
            SetPedCanSwitchWeapon(ped, true)
            TaskCombatPed(ped, PlayerPedId(), 0, 16)
            
            -- 配列に保存
            npcsSpawned[k] = ped
            
            -- NPC死亡監視
            CreateThread(function()
                while DoesEntityExist(ped) and not IsEntityDead(ped) do
                    Wait(1000)
                end
                
                if DoesEntityExist(ped) and IsEntityDead(ped) then
                    -- サーバーにNPC死亡を通知
                    TriggerServerEvent('ng-iaaheist:server:NPCKilled', k)
                    
                    -- 少し待ってから削除
                    Wait(5000)
                    if DoesEntityExist(ped) then
                        DeleteEntity(ped)
                    end
                    npcsSpawned[k] = nil
                end
            end)
            
            if Config.Debug then
                print('[ng-iaaheist] NPC spawned successfully at index: ' .. k .. ' | Entity ID: ' .. ped)
            end
            
            -- モデルをアンロード
            SetModelAsNoLongerNeeded(modelHash)
        end)
    end
    
    if Config.Debug then
        print('[ng-iaaheist] NPC spawn process completed. Total NPCs: ' .. #Config.NPCs)
    end
end

-- データポイント作成
function CreateDataPoints()
    for k, point in pairs(Config.DataPoints) do
        -- データ回収ターゲット
        exports.ox_target:addSphereZone({
            coords = point.coords,
            radius = 2.5,
            debug = Config.Debug,
            options = {
                {
                    name = 'hack_data_' .. k,
                    icon = 'fa-solid fa-download',
                    label = point.label,
                    canInteract = function()
                        return not syncedDataPoints[k] and globalHeistActive
                    end,
                    onSelect = function()
                        if Config.Debug then
                            print('[ng-iaaheist] Target interaction for data point: ' .. k)
                        end
                        HackData(k)
                    end,
                }
            }
        })
    end
end

-- データハッキング
function HackData(pointId)
    -- 既にハッキング済みかチェック
    if syncedDataPoints[pointId] then
        lib.notify({
            title = 'エラー',
            description = 'このデータポイントは既にハッキング済みです',
            type = 'error'
        })
        return
    end
    
    -- 必要アイテムチェック
    QBCore.Functions.TriggerCallback('ng-iaaheist:server:HasItem', function(hasItem)
        if not hasItem then
            lib.notify({
                title = 'エラー',
                description = 'ハッキング用のラップトップが必要です',
                type = 'error'
            })
            return
        end
        
        -- ハッキングミニゲーム
        local success = lib.skillCheck({'easy', 'easy', {areaSize = 60, speedMultiplier = 2}, 'medium'}, {'w', 'a', 's', 'd'})
        
        if success then
            -- サーバーにハッキング成功を通知
            TriggerServerEvent('ng-iaaheist:server:HackDataPoint', pointId)
            
            -- ローカル状態を更新
            syncedDataPoints[pointId] = true
            dataCollected = dataCollected + 1
            
            lib.notify({
                title = 'データ回収',
                description = 'データを取得しました (' .. dataCollected .. '/' .. #Config.DataPoints .. ')',
                type = 'success'
            })
            
            -- データアイテム取得
            TriggerServerEvent('ng-iaaheist:server:GiveData')
            
            if dataCollected >= Config.Items.minData then
                lib.notify({
                    title = 'IAA強盗',
                    description = '十分なデータを収集しました。脱出してください！',
                    type = 'inform',
                    duration = 7000
                })
            end
        else
            lib.notify({
                title = 'ハッキング失敗',
                description = 'ハッキングに失敗しました',
                type = 'error'
            })
        end
    end, Config.Items.requiredItem)
end

-- 脱出ポイント作成
function CreateExitPoint()
    exports.ox_target:addSphereZone({
        coords = Config.ExitPoint.coords,
        radius = 4.0,
        debug = Config.Debug,
        options = {
            {
                name = 'exit_heist',
                icon = 'fa-solid fa-door-open',
                label = Config.ExitPoint.label,
                canInteract = function()
                    return globalHeistActive
                end,
                onSelect = function()
                    if Config.Debug then
                        print('[ng-iaaheist] Target interaction for heist exit')
                    end
                    ExitHeist()
                end,
            }
        }
    })
end

-- 基地脱出（ミッション完了）
function ExitHeist()
    insideHeist = false
    
    -- 警報停止
    StopAlarm()
    
    -- NPCクリーンアップ
    CleanupNPCs()
    
    -- テレポート
    DoScreenFadeOut(1000)
    Wait(1000)
    SetEntityCoords(PlayerPedId(), Config.IAA_Entrance.coords.x, Config.IAA_Entrance.coords.y, Config.IAA_Entrance.coords.z)
    SetEntityHeading(PlayerPedId(), Config.IAA_Entrance.heading)
    Wait(1000)
    DoScreenFadeIn(1000)
    
    -- サーバーにミッション完了を通知
    TriggerServerEvent('ng-iaaheist:server:CompleteHeist')
    
    lib.notify({
        title = 'IAA強盗',
        description = '基地から脱出しました。ミッション完了処理中...',
        type = 'success',
        duration = 5000
    })
end

-- ミッション完了
RegisterNetEvent('ng-iaaheist:client:HeistCompleted', function(dataCount)
    if dataCount > 0 then
        lib.notify({
            title = 'ミッション完了！',
            description = '回収データ：' .. dataCount .. '個\nお疲れ様でした！',
            type = 'success',
            duration = 7000
        })
    else
        lib.notify({
            title = 'ミッション失敗',
            description = 'データを回収せずに脱出しました',
            type = 'error',
            duration = 5000
        })
    end
end)

-- NPCクリーンアップ関数
function CleanupNPCs()
    for k, ped in pairs(npcsSpawned) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    npcsSpawned = {}
    
    if Config.Debug then
        print('[ng-iaaheist] NPCs cleaned up')
    end
end

-- 強制NPCクリーンアップ関数（リソース再起動時など）
function ForceCleanupAllNPCs()
    -- 既存のNPCリストをクリア
    CleanupNPCs()
    
    -- さらに強力なクリーンアップ（範囲内の全ての敵NPCを削除）
    local playerCoords = GetEntityCoords(PlayerPedId())
    local handle, ped = FindFirstPed()
    local success
    
    repeat
        if DoesEntityExist(ped) then
            local pedModel = GetEntityModel(ped)
            local modelName = GetHashKey('s_m_m_fibsec_01')
            
            -- IAA強盗用のNPCモデルかチェック
            if pedModel == modelName then
                local pedCoords = GetEntityCoords(ped)
                local distance = #(playerCoords - pedCoords)
                
                -- 1000m以内のNPCを削除（十分な範囲）
                if distance < 1000.0 then
                    if Config.Debug then
                        print('[ng-iaaheist] Force cleaning NPC at distance: ' .. distance)
                    end
                    DeleteEntity(ped)
                end
            end
        end
        success, ped = FindNextPed(handle)
    until not success
    
    EndFindPed(handle)
    
    if Config.Debug then
        print('[ng-iaaheist] Force cleanup completed')
    end
end

-- クリーンアップ
function CleanupHeist()
    StopAlarm()
    CleanupNPCs()
    
    for _, blip in pairs(blips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    blips = {}
    
    syncedDataPoints = {}
end

-- リソース停止時
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        CleanupHeist()
    end
end)