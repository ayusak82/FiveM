local QBCore = exports['qb-core']:GetCoreObject()

-- ローカル変数
local StartPeds = {}
local isActive = false
local InMilitaryPoint = false
local InBuyerPoint = false
local CurrentCops = 0
local InTeam = false
local IsTeamLeader = false
local TeamSize = 0
local TeamMembers = {}
local MissionVehiclePlate = nil
local MissionTeamMembers = {}
local VehicleBlip = nil
local HasSpawnedTruck = false
local ClientBaseReached = false

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

-- ミッションクールダウンチェック
function IsMissionInCooldown()
    local missionStatus = false
    QBCore.Functions.TriggerCallback('ng-thermite:server:CheckCooldown', function(status)
        missionStatus = status
    end)
    Wait(200)
    return missionStatus
end

-- 警察人数更新
RegisterNetEvent('police:SetCopCount')
AddEventHandler('police:SetCopCount', function(amount)
    CurrentCops = amount
end)

-- マップブリップ作成
Citizen.CreateThread(function()
    for _, info in pairs(Config.BlipLocation) do
        if Config.UseBlips then
            info.blip = AddBlipForCoord(info.x, info.y, info.z)
            SetBlipSprite(info.blip, info.id)
            SetBlipDisplay(info.blip, 4)
            SetBlipScale(info.blip, 0.6)
            SetBlipColour(info.blip, info.colour)
            SetBlipAsShortRange(info.blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(info.title)
            EndTextCommandSetBlipName(info.blip)
        end
    end
end)

-- ミッション開始NPC作成
CreateThread(function()
    for k, v in pairs(Config.StartPeds) do
        RequestModel(GetHashKey(v.Ped))
        while not HasModelLoaded(GetHashKey(v.Ped)) do
            Wait(1)
        end
        StartPed = CreatePed(0, v.Ped, v.Coords['PedCoords'].x, v.Coords['PedCoords'].y, v.Coords['PedCoords'].z, v.Coords['Heading'], false, true)
        SetEntityInvincible(StartPed, true)
        SetBlockingOfNonTemporaryEvents(StartPed, true)
        TaskStartScenarioInPlace(StartPed, v.Scenario, 0, true)
        FreezeEntityPosition(StartPed, true)

        if Config.TargetSystem == 'ox_target' then
            exports.ox_target:addEntity({
                entity = StartPed,
                options = {
                    {
                        name = "JoinTeam"..k,
                        icon = "fas fa-user-plus",
                        label = v.JoinLabel,
                        distance = v.Coords['Distance'],
                        onSelect = function()
                            JoinTeam()
                        end,
                        canInteract = function(entity)
                            if IsPedAPlayer(entity) then return false end
                            return not InTeam and not isActive
                        end
                    },
                    {
                        name = "LeaveTeam"..k,
                        icon = "fas fa-user-minus",
                        label = v.LeaveLabel,
                        distance = v.Coords['Distance'],
                        onSelect = function()
                            LeaveTeam()
                        end,
                        canInteract = function(entity)
                            if IsPedAPlayer(entity) then return false end
                            return InTeam and not isActive
                        end
                    },
                    {
                        name = "StartMission"..k,
                        icon = "fas fa-play",
                        label = v.StartLabel,
                        distance = v.Coords['Distance'],
                        onSelect = function()
                            StartMission()
                        end,
                        canInteract = function(entity)
                            if IsPedAPlayer(entity) then return false end
                            return IsTeamLeader and not isActive
                        end
                    }
                }
            })
        elseif Config.TargetSystem == 'qb-target' then
            exports['qb-target']:AddTargetEntity(StartPed, {
                options = {
                    {
                        type = "client",
                        icon = "fas fa-user-plus",
                        label = v.JoinLabel,
                        action = function()
                            JoinTeam()
                        end,
                        canInteract = function(entity)
                            if IsPedAPlayer(entity) then return false end
                            return not InTeam and not isActive
                        end,
                        distance = v.Coords['Distance'],
                    },
                    {
                        type = "client",
                        icon = "fas fa-user-minus",
                        label = v.LeaveLabel,
                        action = function()
                            LeaveTeam()
                        end,
                        canInteract = function(entity)
                            if IsPedAPlayer(entity) then return false end
                            return InTeam and not isActive
                        end,
                        distance = v.Coords['Distance'],
                    },
                    {
                        type = "client",
                        icon = "fas fa-play",
                        label = v.StartLabel,
                        action = function()
                            StartMission()
                        end,
                        canInteract = function(entity)
                            if IsPedAPlayer(entity) then return false end
                            return IsTeamLeader and not isActive
                        end,
                        distance = v.Coords['Distance'],
                    }
                }
            })
        end
    end
end)

-- チーム参加
function JoinTeam()
    TriggerServerEvent('ng-thermite:server:JoinTeam')
end

-- チーム離脱
function LeaveTeam()
    TriggerServerEvent('ng-thermite:server:LeaveTeam')
    InTeam = false
    IsTeamLeader = false
    TeamSize = 0
    TeamMembers = {}
end

-- チーム情報更新
RegisterNetEvent('ng-thermite:client:UpdateTeam', function(teamSize, teamNames)
    TeamSize = teamSize
    TeamMembers = teamNames
    
    if teamSize > 0 then
        InTeam = true
        local memberList = table.concat(teamNames, ", ")
        QBCore.Functions.Notify("チームメンバー (" .. teamSize .. "/" .. Config.MaxTeamMembers .. "): " .. memberList, "info", 5000)
        
        QBCore.Functions.TriggerCallback('ng-thermite:server:GetTeamInfo', function(info)
            IsTeamLeader = info.isLeader
        end)
    else
        InTeam = false
        IsTeamLeader = false
        TeamSize = 0
        TeamMembers = {}
    end
end)

-- ミッション開始
function StartMission()
    if not IsTeamLeader then
        QBCore.Functions.Notify("チームリーダーのみがミッションを開始できます", "error")
        return
    end
    
    if TeamSize < Config.MinTeamMembers then
        QBCore.Functions.Notify("ミッションを開始するには最低" .. Config.MinTeamMembers .. "人必要です（現在: " .. TeamSize .. "人）", "error")
        return
    end
    
    QBCore.Functions.TriggerCallback('ng-thermite:server:GetCurrentCops', function(copCount)
        CurrentCops = copCount
        
        if IsMissionInCooldown() then
            QBCore.Functions.Notify("このミッションは現在クールダウン中です！", "error")
            return
        end

        if isActive then
            QBCore.Functions.Notify("他のプレイヤーが既にミッションを実行中です！", "error")
            return
        end

        if CurrentCops >= Config.RequiredPolice then
            TriggerServerEvent("ng-thermite:server:StartMission")
        else
            QBCore.Functions.Notify("ミッションを開始するには" .. Config.RequiredPolice .. "人の警察官が必要です。現在は " .. CurrentCops .. "人しかいません。", "error")
        end
    end)
end

-- ミッション開始通知
RegisterNetEvent('ng-thermite:client:MissionStarted', function(teamMembers, vehiclePlate)
    MissionTeamMembers = teamMembers or {}
    MissionVehiclePlate = vehiclePlate
    DebugPrint('Mission started - Vehicle Plate:', vehiclePlate)
    DebugPrint('Team Members:', json.encode(teamMembers))
    QBCore.Functions.Notify("ミッション開始！", "success", 5000)
    SendEmail()
    StartVehicleCheck()
end)

-- 車両スポーン
RegisterNetEvent("ng-thermite:SpawnTruck")
AddEventHandler("ng-thermite:SpawnTruck", function()
    DebugPrint('SpawnTruck event triggered')
    local coords = vector4(-2118.253, 3284.9494, 32.432666, 150.8552)
    
    local vehicles = GetGamePool('CVehicle')
    for _, vehicle in pairs(vehicles) do
        if GetVehicleNumberPlateText(vehicle) == MissionVehiclePlate then
            DebugPrint('Vehicle already exists, giving keys')
            TriggerEvent("vehiclekeys:client:SetOwner", MissionVehiclePlate)
            return
        end
    end
    
    DebugPrint('Spawning new vehicle at coords:', coords)
    QBCore.Functions.SpawnVehicle("barracks", function(veh)
        DebugPrint('Vehicle spawned successfully')
        if MissionVehiclePlate then
            SetVehicleNumberPlateText(veh, MissionVehiclePlate)
        end
        exports['cdn-fuel']:SetFuel(veh, 100.0)
        
        local plate = QBCore.Functions.GetPlate(veh)
        DebugPrint('Vehicle plate from GetPlate:', plate)
        
        MissionVehiclePlate = plate
        
        TriggerEvent("vehiclekeys:client:SetOwner", plate)
        TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
        
        SetVehicleEngineOn(veh, true, true)
        SetVehicleDoorsLocked(veh, true)
        Citizen.Wait(5000)
        SetVehicleDoorsLocked(veh, false)
        
        TriggerServerEvent('ng-thermite:server:ShareVehicleKeys', plate)
        TriggerServerEvent('ng-thermite:server:ShareVehiclePlate', plate)
    end, coords, true)
end)

-- 車両乗車検知
function StartVehicleCheck()
    Citizen.CreateThread(function()
        Citizen.Wait(2000)
        local vehicleFound = false
        local attempts = 0
        while not vehicleFound and attempts < 20 do
            attempts = attempts + 1
            Citizen.Wait(1000)
            local vehicles = GetGamePool('CVehicle')
            for _, vehicle in pairs(vehicles) do
                local plate = QBCore.Functions.GetPlate(vehicle)
                if plate == MissionVehiclePlate then
                    vehicleFound = true
                    if not VehicleBlip then
                        local vehCoords = GetEntityCoords(vehicle)
                        VehicleBlip = AddBlipForCoord(vehCoords.x, vehCoords.y, vehCoords.z)
                        SetBlipSprite(VehicleBlip, 225)
                        SetBlipColour(VehicleBlip, 2)
                        SetBlipScale(VehicleBlip, 0.9)
                        BeginTextCommandSetBlipName("STRING")
                        AddTextComponentString("Mission Vehicle")
                        EndTextCommandSetBlipName(VehicleBlip)
                        QBCore.Functions.Notify("ミッション車両の位置がマップに表示されました", "info", 3000)
                    end
                    break
                end
            end
        end
        
        while not InBuyerPoint do
            Citizen.Wait(500)
            if IsPedInAnyVehicle(PlayerPedId(), false) then
                local currentVeh = GetVehiclePedIsIn(PlayerPedId(), false)
                local currentPlate = QBCore.Functions.GetPlate(currentVeh)
                DebugPrint('In vehicle with plate:', currentPlate, 'Mission plate:', MissionVehiclePlate)
                if currentPlate == MissionVehiclePlate then
                    if VehicleBlip then
                        RemoveBlip(VehicleBlip)
                        VehicleBlip = nil
                    end
                    QBCore.Functions.Notify("GPS にマークされた場所まで運転してください。", "success", 4000)
                    BuyerBlip()
                    break
                end
            end
        end
    end)
end

-- メール送信
function SendEmail()
    TriggerServerEvent(Config.Phone..':server:sendNewMail', {
        sender = "ペイジ",
        subject = "テルミットミッション",
        message = "GPSの場所にトラックがあるので盗み出して届けてください！",
        button = {}
    })
    MissionBlip()
end

-- サーバーからBaseReachedフラグを受信
RegisterNetEvent('ng-thermite:client:SetBaseReached', function()
    DebugPrint('Base reached flag set by server')
    ClientBaseReached = true
    HasSpawnedTruck = true
end)

-- 基地到達チェック
function CheckCoords()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(7)
            
            if ClientBaseReached or HasSpawnedTruck then
                break
            end
            
            local PlayerCoords = GetEntityCoords(PlayerPedId())
            local Distance = GetDistanceBetweenCoords(PlayerCoords, -2133.433, 3261.0524, 32.81026, true)
            if Distance < 60.0 and not HasSpawnedTruck and not ClientBaseReached then
                HasSpawnedTruck = true
                InMilitaryPoint = true
                DebugPrint('Player reached base - Triggering server event')
                TriggerServerEvent('ng-thermite:server:PlayerReachedBase')
                QBCore.Functions.Notify("警備員を殺せ！")
                break
            end
        end
    end)
end

-- バイヤー到達チェック
function CheckBuyerCoords()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(500)
            local PlayerCoords = GetEntityCoords(PlayerPedId())
            local Distance = #(PlayerCoords - vector3(1963.4307, 5160.2871, 47.196655))
            
            if Distance < 10.0 and IsPedInAnyVehicle(PlayerPedId(), false) then
                local car = GetVehiclePedIsIn(PlayerPedId(), false)
                local carPlate = QBCore.Functions.GetPlate(car)
                
                DebugPrint('At buyer location - Distance:', Distance, 'Plate:', carPlate, 'Mission:', MissionVehiclePlate)
                
                if carPlate == MissionVehiclePlate then
                    InBuyerPoint = true
                    DebugPrint('Mission complete - Playing cutscene')
                    PlayCutscene('mph_pac_con_ext')
                    if DoesEntityExist(car) then
                        DeleteVehicle(car)
                        DeleteEntity(car)
                    end
                    Citizen.Wait(20000)
                    TriggerServerEvent('ng-thermite:GiveReward', Config.RewardAmount)
                    TriggerEvent("ng-thermite:ResetMission")
                    break
                end
            end
        end
    end)
end

-- 車両のカギを受け取る
RegisterNetEvent('ng-thermite:client:ReceiveVehicleKeys', function(plate)
    DebugPrint('Receiving vehicle keys for plate:', plate)
    TriggerEvent("vehiclekeys:client:SetOwner", plate)
    TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
end)

-- 車両のプレート番号を受け取り
RegisterNetEvent('ng-thermite:client:SetVehiclePlate', function(plate)
    DebugPrint('Setting mission vehicle plate:', plate)
    MissionVehiclePlate = plate
end)

-- ミッションエンティティのスポーン
RegisterNetEvent('ng-thermite:client:SpawnMissionEntities', function(isLeader)
    DebugPrint('SpawnMissionEntities called - isLeader:', isLeader)
    
    if isLeader then
        DebugPrint('Leader spawning truck and guards')
        TriggerEvent("ng-thermite:SpawnTruck")
        SpawnGuards()
    else
        DebugPrint('Member spawning guards')
        SpawnGuards()
    end
end)

-- ミッションリセット
RegisterNetEvent("ng-thermite:ResetMission")
AddEventHandler("ng-thermite:ResetMission", function()
    StartPeds = {}
    TriggerServerEvent("ng-thermite:server:SetActive", false)
    InBuyerPoint = false
    InMilitaryPoint = false
    InTeam = false
    IsTeamLeader = false
    TeamSize = 0
    TeamMembers = {}
    MissionVehiclePlate = nil
    MissionTeamMembers = {}
    HasSpawnedTruck = false
    ClientBaseReached = false
    if VehicleBlip then
        RemoveBlip(VehicleBlip)
        VehicleBlip = nil
    end
end)

-- ミッション状態更新
RegisterNetEvent('ng-thermite:client:SetActive', function(status)
    isActive = status
end)

-- ミッションブリップ
function MissionBlip()
    local Mblip = AddBlipForCoord(-2133.433, 3261.0524, 32.81026)
    SetBlipSprite(Mblip, 307)
    SetBlipColour(Mblip, 0)
    SetBlipScale(Mblip, 0.8)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Military Base")
    EndTextCommandSetBlipName(Mblip)
    CheckCoords()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(7)
            if InMilitaryPoint == true then
                RemoveBlip(Mblip)
                exports['ps-dispatch']:ThermiteRobbery()
                break
            end
        end
    end)
end

-- バイヤーブリップ
function BuyerBlip()
    local Bblip = AddBlipForCoord(1963.4307, 5160.2871, 47.196655)
    SetBlipSprite(Bblip, 586)
    SetBlipColour(Bblip, 4)
    SetBlipScale(Bblip, 0.8)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Buyer")
    EndTextCommandSetBlipName(Bblip)
    CheckBuyerCoords()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(7)
            if InBuyerPoint == true then
                RemoveBlip(Bblip)
                break
            end
        end
    end)
end

-- 警備員スポーン
function SpawnGuards()
    DebugPrint('SpawnGuards function called')
    local ped = PlayerPedId()
    SetPedRelationshipGroupHash(ped, GetHashKey('PLAYER'))
    AddRelationshipGroup('GuardPeds')

    local guardCount = 0
    for k, v in pairs(Config.Guards) do
        RequestModel(GetHashKey(v.Ped))
        while not HasModelLoaded(GetHashKey(v.Ped)) do
            Wait(1)
        end
        Guards = CreatePed(0, GetHashKey(v.Ped), v.Coords, true, true)
        guardCount = guardCount + 1
        NetworkRegisterEntityAsNetworked(Guards)
        networkID = NetworkGetNetworkIdFromEntity(Guards)
        SetNetworkIdCanMigrate(networkID, true)
        GiveWeaponToPed(Guards, GetHashKey(v.Weapon), 255, false, false)
        SetNetworkIdExistsOnAllMachines(networkID, true)
        SetEntityAsMissionEntity(Guards)
        SetPedDropsWeaponsWhenDead(Guards, false)
        SetPedRelationshipGroupHash(Guards, GetHashKey("GuardPeds"))
        SetEntityVisible(Guards, true)
        SetPedRandomComponentVariation(Guards, 0)
        SetPedRandomProps(Guards)
        SetPedCombatMovement(Guards, v.Aggresiveness)
        SetPedAlertness(Guards, v.Alertness)
        SetPedAccuracy(Guards, v.Accuracy)
        SetPedMaxHealth(Guards, v.Health)
    end

    SetRelationshipBetweenGroups(0, GetHashKey("GuardPeds"), GetHashKey("GuardPeds"))
    SetRelationshipBetweenGroups(5, GetHashKey("GuardPeds"), GetHashKey("PLAYER"))
    SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), GetHashKey("GuardPeds"))
    
    DebugPrint('Spawned', guardCount, 'guards successfully')
end

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        ClearArea(-2140.512, 3244.9045, 32.81031, 80.0)
        ClearAreaOfEverything(-2140.512, 3244.9045, 32.81031, 80.0, true, true, true, true)
    end
end)

-- リソース開始時のクリーンアップ
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        ClearArea(-2140.512, 3244.9045, 32.81031, 80.0)
        ClearAreaOfEverything(-2140.512, 3244.9045, 32.81031, 80.0, true, true, true, true)
    end
end)

-- カットシーン再生
function PlayCutscene(cut)
    while not HasThisCutsceneLoaded(cut) do
        RequestCutscene(cut, 8)
        Wait(0)
    end
    CreateCutscene()
    RemoveCutscene()
    DoScreenFadeIn(500)
end

-- カットシーン作成
function CreateCutscene()
    local ped = PlayerPedId()
    local clone = ClonePedEx(ped, 0.0, false, true, 1)
    local clone2 = ClonePedEx(ped, 0.0, false, true, 1)
    local clone3 = ClonePedEx(ped, 0.0, false, true, 1)
    local clone4 = ClonePedEx(ped, 0.0, false, true, 1)
    local clone5 = ClonePedEx(ped, 0.0, false, true, 1)
    SetBlockingOfNonTemporaryEvents(clone, true)
    SetEntityVisible(clone, false, false)
    SetEntityInvincible(clone, true)
    SetEntityCollision(clone, false, false)
    FreezeEntityPosition(clone, true)
    SetPedHelmet(clone, false)
    RemovePedHelmet(clone, true)
    SetCutsceneEntityStreamingFlags('MP_1', 0, 1)
    RegisterEntityForCutscene(ped, 'MP_1', 0, GetEntityModel(ped), 64)
    SetCutsceneEntityStreamingFlags('MP_2', 0, 1)
    RegisterEntityForCutscene(clone2, 'MP_2', 0, GetEntityModel(clone2), 64)
    SetCutsceneEntityStreamingFlags('MP_3', 0, 1)
    RegisterEntityForCutscene(clone3, 'MP_3', 0, GetEntityModel(clone3), 64)
    SetCutsceneEntityStreamingFlags('MP_4', 0, 1)
    RegisterEntityForCutscene(clone4, 'MP_4', 0, GetEntityModel(clone4), 64)
    SetCutsceneEntityStreamingFlags('MP_5', 0, 1)
    RegisterEntityForCutscene(clone5, 'MP_5', 0, GetEntityModel(clone5), 64)
    Wait(10)
    StartCutscene(0)
    Wait(10)
    ClonePedToTarget(clone, ped)
    Wait(10)
    DeleteEntity(clone)
    DeleteEntity(clone2)
    DeleteEntity(clone3)
    DeleteEntity(clone4)
    DeleteEntity(clone5)
    Wait(50)
    DoScreenFadeIn(250)
end
