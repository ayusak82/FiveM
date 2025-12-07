-- ============================================
-- CLIENT CRAFTING - ng-business
-- ============================================

local craftingStations = {}
local craftingBlips = {}
local CraftingTargets = {}  -- ox_target用のターゲット管理

-- Load crafting stations from server
local function LoadCraftingStations()
    local data = lib.callback.await('ng-business:server:getBusinessData', false)
    if data and data.crafting then
        craftingStations = data.crafting
        DebugPrint('Loaded', #craftingStations, 'crafting stations')
        
        -- Create blips
        for _, station in pairs(craftingStations) do
            if station.blip and station.blip.enabled then
                local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
                SetBlipSprite(blip, station.blip.sprite)
                SetBlipColour(blip, station.blip.color)
                SetBlipScale(blip, station.blip.scale)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(station.label)
                EndTextCommandSetBlipName(blip)
                craftingBlips[station.id] = blip
            end
        end
    end
end

-- Create crafting station event
RegisterNetEvent('ng-business:client:createCrafting', function()
    local input = lib.inputDialog('クラフトステーション作成', {
        {type = 'input', label = 'クラフトID', description = '一意の識別子（例: police_armory）', required = true},
        {type = 'input', label = '表示名', description = '表示名', required = true},
        {type = 'input', label = 'ジョブ', description = 'カンマ区切り（例: police,ambulance）空欄で全員'},
        {type = 'number', label = '最低グレード', description = '最低必要グレード', default = 0, min = 0},
        {type = 'checkbox', label = 'ブリップを有効化', checked = true},
        {type = 'number', label = 'ブリップスプライト', description = 'ブリップアイコンID', default = 566},
        {type = 'number', label = 'ブリップカラー', description = 'ブリップカラーID', default = 3},
        {type = 'number', label = 'ブリップスケール', description = 'ブリップサイズ', default = 0.7, min = 0.1, max = 2.0},
    })
    
    if not input then return end
    
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    local jobs = {}
    if input[3] and input[3] ~= '' then
        for job in string.gmatch(input[3], '([^,]+)') do
            table.insert(jobs, job:match("^%s*(.-)%s*$"))
        end
    end
    
    local craftingData = {
        crafting_id = input[1],
        label = input[2],
        coords = {x = coords.x, y = coords.y, z = coords.z},
        jobs = jobs,
        min_grade = input[4],
        recipes = {},  -- Will be added later
        blip_enabled = input[5],
        blip_sprite = input[6],
        blip_color = input[7],
        blip_scale = input[8]
    }
    
    -- Ask if they want to add recipes now
    local addRecipes = lib.alertDialog({
        header = 'レシピ追加',
        content = '今すぐクラフトレシピを追加しますか？',
        centered = true,
        cancel = true
    })
    
    if addRecipes == 'confirm' then
        TriggerEvent('ng-business:client:addRecipes', craftingData)
    else
        TriggerServerEvent('ng-business:server:createCrafting', craftingData)
    end
end)

-- Add recipes to crafting station
RegisterNetEvent('ng-business:client:addRecipes', function(craftingData)
    local recipes = {}
    local addingRecipes = true
    
    while addingRecipes do
        local recipeInput = lib.inputDialog('レシピ追加', {
            {type = 'input', label = 'アイテム名', description = 'クラフトするアイテム（例: weapon_pistol）', required = true},
            {type = 'input', label = 'レシピ名', description = '表示名', required = true},
            {type = 'number', label = 'クラフト時間', description = 'ミリ秒単位', default = 5000, min = 1000},
            {type = 'number', label = '数量', description = 'クラフトされる数量', default = 1, min = 1},
        })
        
        if not recipeInput then break end
        
        -- Add ingredients
        local ingredients = {}
        local addingIngredients = true
        
        while addingIngredients do
            local ingredientInput = lib.inputDialog('材料追加', {
                {type = 'input', label = 'アイテム名', description = '必要なアイテム', required = true},
                {type = 'number', label = '数量', description = '必要な数量', default = 1, min = 1},
            })
            
            if not ingredientInput then break end
            
            table.insert(ingredients, {
                item = ingredientInput[1],
                amount = ingredientInput[2]
            })
            
            local continueAdding = lib.alertDialog({
                header = '材料追加',
                content = '別の材料を追加しますか？',
                centered = true,
                cancel = true
            })
            
            if continueAdding ~= 'confirm' then
                addingIngredients = false
            end
        end
        
        table.insert(recipes, {
            item = recipeInput[1],
            label = recipeInput[2],
            ingredients = ingredients,
            craftTime = recipeInput[3],
            amount = recipeInput[4]
        })
        
        local continueAdding = lib.alertDialog({
            header = 'レシピ追加',
            content = '別のレシピを追加しますか？',
            centered = true,
            cancel = true
        })
        
        if continueAdding ~= 'confirm' then
            addingRecipes = false
        end
    end
    
    craftingData.recipes = recipes
    TriggerServerEvent('ng-business:server:createCrafting', craftingData)
end)

-- Open crafting menu
local function OpenCraftingMenu(stationId)
    local station = craftingStations[stationId]
    if not station then return end
    
    local options = {}
    
    for _, recipe in ipairs(station.recipes) do
        local ingredientsText = ''
        for i, ingredient in ipairs(recipe.ingredients) do
            ingredientsText = ingredientsText .. ingredient.amount .. 'x ' .. ingredient.item
            if i < #recipe.ingredients then
                ingredientsText = ingredientsText .. ', '
            end
        end
        
        table.insert(options, {
            title = recipe.label,
            description = '必要: ' .. ingredientsText,
            icon = 'hammer',
            onSelect = function()
                TriggerServerEvent('ng-business:server:craftItem', stationId, recipe.item)
            end
        })
    end
    
    lib.registerContext({
        id = 'crafting_menu_' .. stationId,
        title = station.label,
        options = options
    })
    
    lib.showContext('crafting_menu_' .. stationId)
end

-- Update crafting stations when created
RegisterNetEvent('ng-business:client:updateCrafting', function(newCrafting)
    -- Remove old blips
    for _, blip in pairs(craftingBlips) do
        RemoveBlip(blip)
    end
    craftingBlips = {}
    
    -- Remove old targets (ox_target対応)
    if Config.Target == "ox_target" then
        for targetName, targetData in pairs(CraftingTargets) do
            if targetData.id then
                exports.ox_target:removeZone(targetData.id)
            end
            CraftingTargets[targetName] = nil
        end
    else
        for targetName, _ in pairs(CraftingTargets) do
            exports[Config.Target]:RemoveZone(targetName)
            CraftingTargets[targetName] = nil
        end
    end
    
    -- Update crafting stations
    craftingStations = newCrafting
    
    -- Create new blips and targets
    for _, station in pairs(craftingStations) do
        if station.blip and station.blip.enabled then
            local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
            SetBlipSprite(blip, station.blip.sprite)
            SetBlipColour(blip, station.blip.color)
            SetBlipScale(blip, station.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(station.label)
            EndTextCommandSetBlipName(blip)
            craftingBlips[station.id] = blip
        end
        
        -- Create ox_target zone if enabled and using target mode
        if Config.InteractionType == "target" and Config.Target == "ox_target" then
            local targetName = "crafting_" .. station.id
            local targetId = exports.ox_target:addSphereZone({
                coords = vector3(station.coords.x, station.coords.y, station.coords.z),
                radius = 1.5,
                debug = Config.Debug,
                options = {{
                    name = targetName,
                    type = "client",
                    event = "ng-business:client:openCraftingTarget",
                    args = {stationId = station.id},
                    icon = "fa-solid fa-hammer",
                    label = station.label,
                    canInteract = function(entity)
                        return HasRequiredJob(station.jobs, station.minGrade)
                    end,
                    distance = 2.0
                }}
            })
            CraftingTargets[targetName] = {
                id = targetId,
                stationId = station.id
            }
        end
    end
    
    SuccessPrint('Crafting stations updated')
end)

-- ox_target用のクラフトメニューオープンイベント
RegisterNetEvent('ng-business:client:openCraftingTarget', function(data)
    if data and data.stationId then
        OpenCraftingMenu(data.stationId)
    end
end)

-- Main thread for crafting interactions (marker mode only)
CreateThread(function()
    -- Wait for player to load
    while not QBCore.Functions.GetPlayerData().citizenid do
        Wait(1000)
    end
    
    -- Load crafting stations
    LoadCraftingStations()
    
    -- Main loop
    local isShowingTextUI = false
    while true do
        local sleep = 1000
        
        -- markerモードの場合のみ実行
        if Config.InteractionType == "marker" then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local nearStation = false
            
            for _, station in pairs(craftingStations) do
                local distance = #(coords - station.coords)
                
                if distance < 10.0 then
                    sleep = 0
                    DrawMarkerAtCoords(station.coords)
                    
                    if distance < Config.UI.interactionDistance then
                    nearStation = true
                    if HasRequiredJob(station.jobs, station.minGrade) then
                        if not isShowingTextUI then
                            lib.showTextUI('[E] ' .. station.label, {
                                position = "left-center",
                                icon = 'hammer',
                            })
                            isShowingTextUI = true
                        end
                        
                        if IsControlJustPressed(0, Config.InteractionKey) then
                            OpenCraftingMenu(station.id)
                        end
                    else
                        if not isShowingTextUI then
                            lib.showTextUI('[!] アクセス不可', {
                                position = "left-center",
                                icon = 'lock',
                            })
                            isShowingTextUI = true
                        end
                    end
                        break
                    end
                end
            end
            
            if not nearStation and isShowingTextUI then
                lib.hideTextUI()
                isShowingTextUI = false
            end
        else
            -- targetモードの場合はスリープを長くする
            sleep = 1000
        end
        
        Wait(sleep)
    end
end)

-- Start crafting progress
RegisterNetEvent('ng-business:client:startCrafting', function(craftTime, itemLabel)
    if lib.progressBar({
        duration = craftTime,
        label = itemLabel .. 'をクラフト中',
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_player'
        },
    }) then
        DebugPrint('Crafting completed')
    end
end)

DebugPrint('Crafting module loaded')
