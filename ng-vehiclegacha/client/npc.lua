local QBCore = exports['qb-core']:GetCoreObject()
local spawnedNPCs = {}
local spawnedBlips = {}

-- ============================================
-- NPC生成
-- ============================================
local function spawnNPC(npcData, index)
    local model = GetHashKey(npcData.model)
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end
    
    local npc = CreatePed(4, model, npcData.coords.x, npcData.coords.y, npcData.coords.z - 1.0, npcData.coords.w, false, false)
    
    SetEntityAsMissionEntity(npc, true, true)
    SetPedFleeAttributes(npc, 0, false)
    SetPedCombatAttributes(npc, 17, true)
    SetPedCanRagdoll(npc, false)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetEntityInvincible(npc, true)
    FreezeEntityPosition(npc, true)
    
    -- シナリオ設定
    if npcData.scenario then
        TaskStartScenarioInPlace(npc, npcData.scenario, 0, true)
    end
    
    -- NPCを配列に保存
    spawnedNPCs[index] = npc
    
    -- Blip作成
    if npcData.blipSettings and npcData.blipSettings.enabled then
        local blip = AddBlipForCoord(npcData.coords.x, npcData.coords.y, npcData.coords.z)
        SetBlipSprite(blip, npcData.blipSettings.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, npcData.blipSettings.scale)
        SetBlipColour(blip, npcData.blipSettings.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(npcData.blipSettings.label)
        EndTextCommandSetBlipName(blip)
        
        spawnedBlips[index] = blip
    end
    
    -- ox_targetインタラクション設定
    exports.ox_target:addLocalEntity(npc, {
        {
            name = 'vehiclegacha_npc_' .. index,
            icon = Config.Interaction.icon,
            label = Config.Interaction.label,
            distance = Config.Interaction.distance,
            onSelect = function()
                TriggerEvent('ng-vehiclegacha:client:openMenu')
            end
        }
    })
    
    if Config.Debug then
        print('^2[ng-vehiclegacha]^7 NPC #' .. index .. ' を生成しました: ' .. npcData.coords)
    end
end

-- ============================================
-- 全NPC生成
-- ============================================
CreateThread(function()
    Wait(1000) -- リソース完全ロード待機
    
    for index, npcData in ipairs(Config.NPCs) do
        spawnNPC(npcData, index)
    end
    
    if Config.Debug then
        print('^2[ng-vehiclegacha]^7 全NPCの生成が完了しました')
    end
end)

-- ============================================
-- リソース停止時のクリーンアップ
-- ============================================
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- NPCを削除
    for _, npc in pairs(spawnedNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
    
    -- Blipを削除
    for _, blip in pairs(spawnedBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    
    if Config.Debug then
        print('^2[ng-vehiclegacha]^7 全NPCとBlipをクリーンアップしました')
    end
end)

-- ============================================
-- DrawText形式のインタラクション(ox_targetが使えない場合)
-- ============================================
if not GetResourceState('ox_target'):find('start') then
    CreateThread(function()
        while true do
            local sleep = 1000
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            for index, npcData in ipairs(Config.NPCs) do
                local npcCoords = vector3(npcData.coords.x, npcData.coords.y, npcData.coords.z)
                local distance = #(playerCoords - npcCoords)
                
                if distance < Config.Interaction.distance then
                    sleep = 0
                    
                    -- DrawText表示
                    lib.showTextUI(Config.Interaction.label, {
                        position = 'left-center',
                        icon = Config.Interaction.icon,
                    })
                    
                    -- キー入力チェック
                    if IsControlJustPressed(0, 38) then -- E key
                        lib.hideTextUI()
                        TriggerEvent('ng-vehiclegacha:client:openMenu')
                    end
                else
                    lib.hideTextUI()
                end
            end
            
            Wait(sleep)
        end
    end)
    
    if Config.Debug then
        print('^3[ng-vehiclegacha]^7 ox_targetが見つからないため、DrawText方式を使用します')
    end
end
