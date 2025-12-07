local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()
local missionStarted = false
local hackingCompleted = false
local deliveryCompleted = false
local missionBlips = {}
local missionPeds = {}
local hackingAttempts = 0
local activeComputerLocations = {}
local deliveryLocation = nil
local missionNPCLocation = nil
local isNearComputer = false
local isNearDelivery = false
local isNearMissionNPC = false
local nearestComputerIndex = 0
local hackedComputers = {}

-- プレイヤーデータの更新
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    PlayerData = data
end)

-- ミッションの状態の設定
RegisterNetEvent('ng-dataheist:client:syncMissionState', function(started, hacked, delivered)
    missionStarted = started
    hackingCompleted = hacked
    deliveryCompleted = delivered
    
    if missionStarted then
        if not hackingCompleted then
            CreateHackableComputerBlips()
        elseif not deliveryCompleted then
            CreateDeliveryLocationBlip()
        end
    end
end)

-- ミッションの初期化
local function InitializeMission()
    CreateMissionNPC()
    TriggerServerEvent('ng-dataheist:server:getMissionState')
end

-- ミッションNPCの作成
function CreateMissionNPC()
    local model = Config.MissionNPC.model
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    
    local coords = Config.MissionNPC.coords
    local ped = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    
    if Config.MissionNPC.scenario then
        TaskStartScenarioInPlace(ped, Config.MissionNPC.scenario, 0, true)
    end
    
    table.insert(missionPeds, ped)
    
    -- ミッションNPCのBlipを作成
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, Config.MissionNPC.blip.sprite)
    SetBlipColour(blip, Config.MissionNPC.blip.color)
    SetBlipScale(blip, Config.MissionNPC.blip.scale)
    SetBlipAsShortRange(blip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.MissionNPC.blip.label)
    EndTextCommandSetBlipName(blip)
    
    table.insert(missionBlips, blip)
    
    -- NPCの位置を保存
    missionNPCLocation = coords
end

-- ハッキング可能なコンピューターのBlipを作成
function CreateHackableComputerBlips()
    activeComputerLocations = {}
    
    for i, computer in ipairs(Config.HackableComputers) do
        -- 既にハッキングしたコンピューターはスキップ
        if hackedComputers[i] then
            goto continue
        end
        
        local blip = AddBlipForCoord(computer.coords.x, computer.coords.y, computer.coords.z)
        SetBlipSprite(blip, computer.blip.sprite)
        SetBlipColour(blip, computer.blip.color)
        SetBlipScale(blip, computer.blip.scale)
        SetBlipAsShortRange(blip, true)
        
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(computer.blip.label)
        EndTextCommandSetBlipName(blip)
        
        table.insert(missionBlips, blip)
        table.insert(activeComputerLocations, {coords = computer.coords, index = i, heading = computer.heading})
        
        ::continue::
    end
end

-- 納品場所のBlipを作成
function CreateDeliveryLocationBlip()
    local delivery = Config.DeliveryLocation
    local blip = AddBlipForCoord(delivery.coords.x, delivery.coords.y, delivery.coords.z)
    SetBlipSprite(blip, delivery.blip.sprite)
    SetBlipColour(blip, delivery.blip.color)
    SetBlipScale(blip, delivery.blip.scale)
    SetBlipAsShortRange(blip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(delivery.blip.label)
    EndTextCommandSetBlipName(blip)
    
    table.insert(missionBlips, blip)
    
    -- 納品場所の位置を保存
    deliveryLocation = delivery.coords
end

-- ミッションのクリーンアップ
function CleanupMission()
    -- Blipを削除
    for i, blip in ipairs(missionBlips) do
        RemoveBlip(blip)
    end
    missionBlips = {}
    
    -- Pedを削除
    for i, ped in ipairs(missionPeds) do
        DeletePed(ped)
    end
    missionPeds = {}
    
    -- 保存した位置情報をクリア
    activeComputerLocations = {}
    deliveryLocation = nil
    missionNPCLocation = nil
    hackedComputers = {}
    
    -- ミッションの状態をリセット
    missionStarted = false
    hackingCompleted = false
    deliveryCompleted = false
    hackingAttempts = 0
    isNearComputer = false
    isNearDelivery = false
    isNearMissionNPC = false
    nearestComputerIndex = 0
end

-- ミッションの状態を確認
function CheckMissionStatus()
    local status = 'ミッション進行中: '
    
    if not hackingCompleted then
        status = status .. 'ハッキング対象のコンピューターを見つけてください。'
    elseif not deliveryCompleted then
        status = status .. 'データを納品場所に持っていってください。'
    else
        status = status .. 'ミッション完了！'
    end
    
    lib.notify({
        title = 'ミッション状況',
        description = status,
        type = 'info',
        duration = 5000
    })
end

-- ミッションの開始
function StartMission()
    if missionStarted then
        lib.notify({
            title = 'エラー',
            description = 'ミッションは既に進行中です！',
            type = 'error'
        })
        return
    end
    
    lib.progressBar({
        duration = 2000,
        label = 'ミッションの詳細を確認中...',
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'missheistdockssetup1clipboard@base',
            clip = 'base'
        }
    })
    
    lib.callback('ng-dataheist:server:startMission', false, function(success)
        if success then
            missionStarted = true
            CreateHackableComputerBlips()
            
            lib.notify({
                title = 'ミッション開始',
                description = '機密データを入手するためにコンピューターをハッキングしてください。',
                type = 'success',
                duration = 7000
            })
        else
            lib.notify({
                title = 'エラー',
                description = 'ミッションを開始できませんでした。',
                type = 'error'
            })
        end
    end)
end

-- ハッキングの開始
function StartHacking(computerIndex)
    if not missionStarted or hackingCompleted then return end
    
    -- 既にハッキングしたコンピューターはスキップ
    if hackedComputers[computerIndex] then
        lib.notify({
            title = 'エラー',
            description = 'このコンピューターは既にハッキングされています。',
            type = 'error'
        })
        return
    end
    
    local computer = Config.HackableComputers[computerIndex]
    if not computer then return end
    
    -- プレイヤーをコンピューターの位置に向ける
    local playerPed = PlayerPedId()
    TaskGoStraightToCoord(playerPed, computer.coords.x, computer.coords.y, computer.coords.z, 1.0, -1, computer.heading, 0.1)
    
    Wait(1000)
    
    -- ハッキングアニメーション
    lib.progressBar({
        duration = 3000,
        label = 'コンピューターに接続中...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'anim@heists@prison_heiststation@cop_reactions',
            clip = 'cop_b_idle'
        }
    })
    
    -- タイピングゲームを開始
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openHacking',
        difficulty = DetermineHackingDifficulty()
    })
    
    -- 現在アクセス中のコンピューターインデックスを保存
    nearestComputerIndex = computerIndex
end

-- ハッキングの難易度を決定
function DetermineHackingDifficulty()
    local difficulty = 'easy'
    
    if hackingAttempts >= 1 then
        difficulty = 'medium'
    end
    
    if hackingAttempts >= 2 then
        difficulty = 'hard'
    end
    
    return Config.Mission.difficulty[difficulty]
end

-- NUIからのコールバック
RegisterNUICallback('hackingResult', function(data, cb)
    SetNuiFocus(false, false)
    
    hackingAttempts = hackingAttempts + 1
    
    if data.success then
        -- ハッキング成功
        HackingSuccess()
    else
        -- ハッキング失敗
        HackingFailed()
    end
    
    cb('ok')
end)

-- ハッキング成功
function HackingSuccess()
    lib.progressBar({
        duration = 5000,
        label = 'データをダウンロード中...',
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'anim@heists@prison_heiststation@cop_reactions',
            clip = 'cop_b_idle'
        }
    })
    
    lib.callback('ng-dataheist:server:completeHacking', false, function(success)
        if success then
            hackingCompleted = true
            
            -- ハッキングしたコンピューターを記録
            hackedComputers[nearestComputerIndex] = true
            
            -- Blipをクリア
            for i, blip in ipairs(missionBlips) do
                if i > 1 then -- ミッションNPCのBlipは保持
                    RemoveBlip(blip)
                    missionBlips[i] = nil
                end
            end
            
            -- 新しいBlipのテーブルを作成
            local newBlips = {}
            for i, blip in ipairs(missionBlips) do
                if blip then
                    table.insert(newBlips, blip)
                end
            end
            missionBlips = newBlips
            activeComputerLocations = {}
            
            -- 納品場所のBlipを作成
            CreateDeliveryLocationBlip()
            
            lib.notify({
                title = 'ハッキング成功',
                description = 'データを入手しました。指定の場所に納品してください。',
                type = 'success',
                duration = 7000
            })
        else
            lib.notify({
                title = 'エラー',
                description = 'データの取得に失敗しました。',
                type = 'error'
            })
        end
    end)
end

-- ハッキング失敗
function HackingFailed()
    lib.notify({
        title = 'ハッキング失敗',
        description = 'ハッキングに失敗しました。もう一度試してください。',
        type = 'error',
        duration = 5000
    })
    
    -- 最大試行回数に達した場合
    if hackingAttempts >= Config.Mission.hackingAttempts then
        lib.notify({
            title = '警告',
            description = 'セキュリティシステムが作動しました！別のコンピューターを試してください。',
            type = 'warning',
            duration = 7000
        })
        
        -- 現在のコンピューターを使用不可に
        hackedComputers[nearestComputerIndex] = true
        
        -- すべてのコンピュータが使用不可能になったかチェック
        local allHacked = true
        for i = 1, #Config.HackableComputers do
            if not hackedComputers[i] then
                allHacked = false
                break
            end
        end
        
        -- すべてのコンピュータが使用不可能であればBlipsを再生成
        if allHacked then
            -- すべてのコンピュータをリセット
            hackedComputers = {}
        end
        
        -- Blipsを再生成
        for i, blip in ipairs(missionBlips) do
            if i > 1 then -- ミッションNPCのBlipは保持
                RemoveBlip(blip)
                missionBlips[i] = nil
            end
        end
        
        -- 新しいBlipのテーブルを作成
        local newBlips = {}
        for i, blip in ipairs(missionBlips) do
            if blip then
                table.insert(newBlips, blip)
            end
        end
        missionBlips = newBlips
        
        -- コンピューターのBlipを再作成
        CreateHackableComputerBlips()
        
        hackingAttempts = 0
    end
end

-- データの納品
function DeliverData()
    if not missionStarted or not hackingCompleted or deliveryCompleted then return end
    
    -- 納品アニメーション
    lib.progressBar({
        duration = 5000,
        label = 'データを転送中...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'mp_common',
            clip = 'givetake1_a'
        }
    })
    
    -- カットシーン（簡易版）
    DoScreenFadeOut(1000)
    Wait(1000)
    
    lib.callback('ng-dataheist:server:completeDelivery', false, function(success, reward)
        Wait(1000)
        DoScreenFadeIn(1000)
        
        if success then
            deliveryCompleted = true
            
            -- Blipをクリア
            for i, blip in ipairs(missionBlips) do
                RemoveBlip(blip)
            end
            missionBlips = {}
            
            lib.notify({
                title = 'ミッション完了',
                description = '報酬として$' .. reward .. 'を受け取りました！',
                type = 'success',
                duration = 7000
            })
            
            -- ミッションをリセット
            Wait(5000)
            TriggerServerEvent('ng-dataheist:server:resetMission')
            CleanupMission()
        else
            lib.notify({
                title = 'エラー',
                description = '納品に失敗しました。',
                type = 'error'
            })
        end
    end)
end

-- 近くにあるインタラクションポイントをチェックするスレッド
CreateThread(function()
    while true do
        Wait(500)
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- 1. ミッションNPCの近くかどうかチェック
        isNearMissionNPC = false
        if missionNPCLocation ~= nil then
            local distance = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(missionNPCLocation.x, missionNPCLocation.y, missionNPCLocation.z))
            if distance < 2.0 then
                isNearMissionNPC = true
            end
        end
        
        -- 2. コンピューターの近くかどうかチェック
        isNearComputer = false
        nearestComputerIndex = 0
        for i, computerInfo in ipairs(activeComputerLocations) do
            local distance = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(computerInfo.coords.x, computerInfo.coords.y, computerInfo.coords.z))
            if distance < 2.0 and not hackedComputers[computerInfo.index] then
                isNearComputer = true
                nearestComputerIndex = computerInfo.index
                break
            end
        end
        
        -- 3. 納品場所の近くかどうかチェック
        isNearDelivery = false
        if deliveryLocation ~= nil then
            local distance = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(deliveryLocation.x, deliveryLocation.y, deliveryLocation.z))
            if distance < 2.0 then
                isNearDelivery = true
            end
        end
    end
end)

-- ヘルプテキスト表示スレッド
CreateThread(function()
    while true do
        Wait(0)
        
        -- ミッションNPCの近くにいる場合
        if isNearMissionNPC then
            if not missionStarted then
                -- 指示テキスト表示
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('~y~E~w~を押してミッションを開始')
                EndTextCommandDisplayHelp(0, false, true, -1)
                
                -- Eキーを押したらミッション開始
                if IsControlJustPressed(0, 38) then
                    StartMission()
                end
            else
                -- ミッション状況確認
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('~y~E~w~を押してミッション状況を確認')
                EndTextCommandDisplayHelp(0, false, true, -1)
                
                -- Eキーを押したらミッション状況確認
                if IsControlJustPressed(0, 38) then
                    CheckMissionStatus()
                end
            end
        end
        
        -- コンピュータの近くにいる場合（ハッキング前）
        if isNearComputer and missionStarted and not hackingCompleted then
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName('~y~E~w~を押してハッキングを開始')
            EndTextCommandDisplayHelp(0, false, true, -1)
            
            -- Eキーを押したらハッキング開始
            if IsControlJustPressed(0, 38) then
                StartHacking(nearestComputerIndex)
            end
        end
        
        -- 納品場所の近くにいる場合
        if isNearDelivery and missionStarted and hackingCompleted and not deliveryCompleted then
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName('~y~E~w~を押してデータを納品')
            EndTextCommandDisplayHelp(0, false, true, -1)
            
            -- Eキーを押したら納品
            if IsControlJustPressed(0, 38) then
                DeliverData()
            end
        end
    end
end)

-- リソース開始時の処理
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(1000)
    InitializeMission()
end)

-- リソース停止時の処理
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    CleanupMission()
end)

-- プレイヤーが接続した時の初期化（リソース開始後にプレイヤーが接続した場合）
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    TriggerServerEvent('ng-dataheist:server:getMissionState')
end)

-- 管理者コマンドによるミッションリセット処理
RegisterNetEvent('ng-dataheist:client:missionReset', function()
    -- 通知
    lib.notify({
        title = 'システム',
        description = 'データ強盗ミッションがリセットされました。',
        type = 'info',
        duration = 5000
    })
    
    -- ミッションの状態をクリーンアップ
    CleanupMission()
    
    -- 再度ミッションNPCを初期化
    InitializeMission()
end)