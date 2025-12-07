local QBCore = exports['qb-core']:GetCoreObject()
local isDead = false
local isProcessing = false -- 処理中フラグを追加
local cooldowns = {
    F = 0,
    G = 0,
    H = 0
}

-- プレイヤーの死亡状態を監視
CreateThread(function()
   while true do
       local player = PlayerId()
       if NetworkIsPlayerActive(player) then
           local ped = PlayerPedId()
           
           -- プレイヤーデータの安全な取得
           local playerData = QBCore.Functions.GetPlayerData()
           local isDeadByMetadata = false
           local inLastStand = false
           
           -- metadataが存在することを確認してからアクセス
           if playerData and playerData.metadata then
               isDeadByMetadata = playerData.metadata["isdead"] or false
               inLastStand = playerData.metadata["inlaststand"] or false
           end
           
           -- 死亡判定
           if IsEntityDead(ped) or isDeadByMetadata or inLastStand then
               if not isDead then
                   isDead = true
                   isProcessing = false -- 死亡時にリセット
                   if Config.Debug then print("プレイヤーが死亡しました") end
               end
           else
               if isDead then
                   isDead = false
                   isProcessing = false -- 蘇生時にリセット
                   if Config.Debug then print("プレイヤーが蘇生しました") end
               end
           end
       end
       Wait(1000)
   end
end)

-- キー長押し処理用の関数
local function handleKeyPress(key, action, checkJob)
    if not isDead or isProcessing then return end
    
    -- クールタイムチェック
    local currentTime = GetGameTimer()
    if cooldowns[key] > currentTime then
        local remainingTime = math.ceil((cooldowns[key] - currentTime) / 1000)
        lib.notify({
            title = 'クールタイム',
            description = 'あと' .. remainingTime .. '秒お待ちください',
            type = 'error'
        })
        return
    end
    
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData then return end
    
    -- 職業チェック（必要な場合）
    if checkJob then
        local playerJob = PlayerData.job.name
        if not Config.TeleportJobs[playerJob] then
            lib.notify({
                title = 'エラー',
                description = 'この機能は利用できません',
                type = 'error'
            })
            return
        end
    end
    
    isProcessing = true
    
    local labels = {
        F = '医療施設への搬送中...',
        G = '医者を呼んでいます...',
        H = '個人医を呼んでいます...'
    }
    
    local success = lib.progressCircle({
        duration = Config.HoldTime,
        label = labels[key],
        position = 'bottom',
        useWhileDead = true,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    })
    
    if success then
        -- プログレスが完了した場合のみ実行
        if key == 'F' then
            local playerJob = PlayerData.job.name
            TriggerServerEvent('ng-deathnotify:server:jobTeleport', playerJob)
        elseif key == 'G' then
            TriggerServerEvent('ng-deathnotify:server:callAmbulance')
        elseif key == 'H' then
            TriggerServerEvent('ng-deathnotify:server:callDoctor')
        end
        
        -- クールタイムを設定（15秒）
        cooldowns[key] = GetGameTimer() + 60000
        
        if Config.Debug then
            print('キー処理完了:', key, 'クールタイム設定: 15秒')
        end
        
        -- 処理完了後のクールダウン
        Wait(1000)
    else
        if Config.Debug then
            print('キー処理キャンセル:', key)
        end
    end
    
    isProcessing = false
end

-- キー案内表示
CreateThread(function()
    while true do
        Wait(0)
        if isDead and not isProcessing then
            local PlayerData = QBCore.Functions.GetPlayerData()
            local playerJob = PlayerData and PlayerData.job and PlayerData.job.name or nil
            local currentTime = GetGameTimer()
            
            local yPosition = 0.65 -- 秒数の上に表示（位置を上げる）
            local keyInfos = {}
            
            -- 表示するキー情報を設定
            if playerJob and Config.TeleportJobs[playerJob] then
                keyInfos = {
                    {key = "~r~[F]~w~", text = "医療施設へ搬送", cooldownKey = "F"},
                    {key = "~b~[G]~w~", text = "医者を呼ぶ", cooldownKey = "G"},
                    {key = "~g~[H]~w~", text = "個人医を呼ぶ", cooldownKey = "H"}
                }
            else
                keyInfos = {
                    {key = "~b~[G]~w~", text = "医者を呼ぶ", cooldownKey = "G"},
                    {key = "~g~[H]~w~", text = "個人医を呼ぶ", cooldownKey = "H"}
                }
            end
            
            -- 各キー案内を縦に表示
            for i, info in ipairs(keyInfos) do
                SetTextFont(0)
                SetTextProportional(1)
                SetTextScale(0.50, 0.50)
                SetTextColour(255, 255, 255, 215)
                SetTextOutline()
                SetTextCentre(true)
                SetTextEntry("STRING")
                
                -- クールタイムの確認と表示
                local displayText = info.key .. " " .. info.text
                if cooldowns[info.cooldownKey] > currentTime then
                    local remainingTime = math.ceil((cooldowns[info.cooldownKey] - currentTime) / 1000)
                    displayText = displayText .. " ~r~(" .. remainingTime .. "秒待機)~w~"
                end
                
                AddTextComponentString(displayText)
                DrawText(0.5, yPosition + (i - 1) * 0.04)
            end
        else
            Wait(500)
        end
    end
end)

-- キー入力監視（シンプル化）
CreateThread(function()
    while true do
        Wait(0)
        if isDead and not isProcessing then
            -- 死亡時の入力を強制的に有効化
            EnableControlAction(0, 23, true)  -- F
            EnableControlAction(0, 47, true)  -- G
            EnableControlAction(0, 74, true)  -- H
            EnableControlAction(0, 249, true) -- N (プッシュトゥトーク用)
            
            -- キーが押された瞬間を検知
            if IsControlJustPressed(0, 23) then -- F key
                handleKeyPress('F', 'teleport', true)
            elseif IsControlJustPressed(0, 47) then -- G key
                handleKeyPress('G', 'ambulance', false)
            elseif IsControlJustPressed(0, 74) then -- H key
                handleKeyPress('H', 'doctor', false)
            end
        else
            Wait(500)
        end
    end
end)

-- サーバーからのテレポート実行
RegisterNetEvent('ng-deathnotify:client:doTeleport', function(coords, sendNotification)
    local ped = PlayerPedId()
    DoScreenFadeOut(1000)
    Wait(1000)
    
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
    SetEntityHeading(ped, coords.w)
    
    Wait(1000)
    DoScreenFadeIn(1000)
    
    lib.notify({
        title = '医療施設',
        description = '医療施設に搬送されました',
        type = 'success'
    })
    
    -- テレポート完了後に通知を送信
    if sendNotification then
        Wait(500) -- 少し待機してから通知
        TriggerServerEvent('ng-deathnotify:server:sendTeleportNotification')
    end
end)

-- 通知確認
RegisterNetEvent('ng-deathnotify:client:notifySent', function(type)
    local messages = {
        ambulance = '医者に通知を送信しました',
        doctor = '個人医に通知を送信しました',
        teleport = '医療施設への搬送と通知が完了しました'
    }
    
    lib.notify({
        title = '通知送信',
        description = messages[type] or '通知を送信しました',
        type = 'success'
    })
end)

-- ps-dispatch送信（クライアント側）
RegisterNetEvent('ng-deathnotify:client:sendDispatch', function(dispatchType, notifConfig, jobs)
    -- 特定のタイプに応じて適切なexportを使用
    if dispatchType == 'ambulanceCall' then
        -- 一般市民のambulance要請
        if exports['ps-dispatch'] and exports['ps-dispatch']['InjuriedPerson'] then
            exports['ps-dispatch']:InjuriedPerson()
        else
            -- フォールバック
            local coords = GetEntityCoords(PlayerPedId())
            local currentStreetName, intersectStreetName = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
            local currentStreetName = GetStreetNameFromHashKey(currentStreetName)
            local intersectStreetName = GetStreetNameFromHashKey(intersectStreetName)
            local street = currentStreetName
            if intersectStreetName and intersectStreetName ~= "" then
                street = currentStreetName .. " | " .. intersectStreetName
            end
            
            local gender = IsPedMale(PlayerPedId()) and "Male" or "Female"
            
            local dispatchData = {
                message = notifConfig.title,
                codeName = 'civdown',
                code = notifConfig.code,
                icon = notifConfig.icon,
                priority = 2,
                coords = coords,
                gender = gender,
                street = street,
                alertTime = 10,
                jobs = { 'ambulance', 'ems' }  -- doctorは含まれていない
            }
            TriggerServerEvent('ps-dispatch:server:notify', dispatchData)
        end
    elseif dispatchType == 'doctorCall' then
        -- 個人医要請
        if exports['ps-dispatch'] and exports['ps-dispatch']['DoctorRequest'] then
            exports['ps-dispatch']:DoctorRequest()
        else
            -- フォールバック
            local coords = GetEntityCoords(PlayerPedId())
            local currentStreetName, intersectStreetName = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
            local currentStreetName = GetStreetNameFromHashKey(currentStreetName)
            local intersectStreetName = GetStreetNameFromHashKey(intersectStreetName)
            local street = currentStreetName
            if intersectStreetName and intersectStreetName ~= "" then
                street = currentStreetName .. " | " .. intersectStreetName
            end
            
            local gender = IsPedMale(PlayerPedId()) and "Male" or "Female"
            
            local dispatchData = {
                message = notifConfig.title,
                codeName = 'doctorrequest',
                code = notifConfig.code,
                icon = notifConfig.icon,
                priority = 2,
                coords = coords,
                gender = gender,
                street = street,
                alertTime = 10,
                jobs = { 'doctor' }  -- doctorのみ
            }
            TriggerServerEvent('ps-dispatch:server:notify', dispatchData)
        end
    elseif dispatchType == 'jobTeleport' then
        -- 公務員の緊急搬送（ambulanceのみに通知、doctorには通知しない）
        if exports['ps-dispatch'] and exports['ps-dispatch']['OfficerDown'] then
            -- OfficerDownを使用（通常はambulanceのみに通知される）
            exports['ps-dispatch']:OfficerDown()
        else
            -- フォールバック - ambulanceのみに通知
            local coords = GetEntityCoords(PlayerPedId())
            local currentStreetName, intersectStreetName = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
            local currentStreetName = GetStreetNameFromHashKey(currentStreetName)
            local intersectStreetName = GetStreetNameFromHashKey(intersectStreetName)
            local street = currentStreetName
            if intersectStreetName and intersectStreetName ~= "" then
                street = currentStreetName .. " | " .. intersectStreetName
            end
            
            local gender = IsPedMale(PlayerPedId()) and "Male" or "Female"
            local Player = QBCore.Functions.GetPlayerData()
            
            local dispatchData = {
                message = notifConfig.title,
                codeName = 'officerdown',
                code = notifConfig.code,
                icon = notifConfig.icon,
                priority = 1,
                coords = coords,
                gender = gender,
                street = street,
                name = Player.charinfo.firstname .. " " .. Player.charinfo.lastname,
                callsign = Player.metadata["callsign"] or "N/A",
                alertTime = 10,
                jobs = { 'ambulance' }  -- ambulanceのみ、doctorは除外
            }
            TriggerServerEvent('ps-dispatch:server:notify', dispatchData)
        end
    end
    
    if Config.Debug then
        print('Dispatch送信完了:', dispatchType, 'Jobs:', json.encode(jobs or {}))
    end
end)