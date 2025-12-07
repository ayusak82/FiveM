local POOL_SIZE = 100

local function tableConcat(t1, t2)
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

local function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

local function generateLootPoolFromCase(case)
    Bridge.Debug("Generating loot pool for case")

    if not case then
        Bridge.Error("Invalid case provided")
        return nil
    end

    local pool = {}
    local desiredCounts = {
        common = 80,
        uncommon = 16,
        rare = 3,
        epic = 0,
        legendary = 0,
    }

    local rnJesus = math.random(100)
    print("^3[DEBUG] RNG roll:", rnJesus)

    if rnJesus > 74 then
        desiredCounts.legendary = desiredCounts.legendary + 1
        print("^3[DEBUG] Legendary roll!")
    elseif rnJesus > 10 then
        desiredCounts.epic = desiredCounts.epic + 1
        print("^3[DEBUG] Epic roll!")
    else
        desiredCounts.rare = desiredCounts.rare + 1
    end

    for i = 1, POOL_SIZE do
        local rarity = next(desiredCounts)
        if not rarity then break end

        if not case[rarity] or #case[rarity] == 0 then
            print("^1[ERROR] No items found for rarity:", rarity)
            return nil
        end

        local selectedItem = case[rarity][math.random(#case[rarity])]
        if not selectedItem then
            print("^1[ERROR] Failed to select item for rarity:", rarity)
            return nil
        end

        pool[i] = table.clone(selectedItem)
        pool[i].rarity = rarity

        desiredCounts[rarity] = desiredCounts[rarity] - 1
        if desiredCounts[rarity] <= 0 then
            desiredCounts[rarity] = nil
        end
    end

    shuffle(pool)
    pool = tableConcat(pool, pool)
    
    print("^3[DEBUG] Generated pool size:", #pool)
    return pool
end

local playerLootQueue = {}

function GetCaseData(source, caseIndex)
    print("^3[DEBUG] Getting case data for", caseIndex)
    
    local case = CASES[caseIndex]
    if not case then 
        print("^1[ERROR] Case not found:", caseIndex)
        return nil, nil 
    end

    local lootPool = generateLootPoolFromCase(case)
    if not lootPool then
        print("^1[ERROR] Failed to generate loot pool")
        return nil, nil
    end

    local winner = (math.random(#lootPool - POOL_SIZE) + POOL_SIZE)
    playerLootQueue[source] = lootPool[winner]

    print("^3[DEBUG] Winner item:", playerLootQueue[source].name)
    return lootPool, winner - 1
end

RegisterNetEvent('ng-lootbox:useGacha', function(itemName)
    local src = source
    if CASES[itemName] then
        if exports.ox_inventory:RemoveItem(src, itemName, 1) then
            local lootPool, winner = GetCaseData(src, itemName)
            if lootPool and winner then
                TriggerClientEvent('ng-lootbox:RollCase', src, lootPool, winner)
            end
        end
    end
end)

RegisterNetEvent('ng-lootbox:getQueuedItem', function()
    local src = source
    local loot = playerLootQueue[src]

    print("^3[DEBUG] Getting queued item for source:", src)

    if not loot then
        print("^1[WARNING] No queued item found for source:", src)
        return
    end

    if not exports.ox_inventory:CanCarryItem(src, loot.name, loot.amount) then
        print("^1[ERROR] Player cannot carry item:", loot.name)
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'インベントリがいっぱいです'
        })
        return
    end

    if loot.additionalItems then
        for _, item in ipairs(loot.additionalItems) do
            Bridge.giveItem(src, item.name, item.amount)
        end
    end

    Bridge.giveItem(src, loot.name, loot.amount)
    playerLootQueue[src] = nil
end)

-- server/main.lua に追加
RegisterNetEvent('ng-lootbox:checkItem', function(itemName)
    local src = source
    local isValidCase = CASES[itemName] ~= nil
    
    print("^3[DEBUG] Checking item:", itemName, "Valid:", isValidCase)
    TriggerClientEvent('ng-lootbox:itemCheckResult', src, itemName, isValidCase)
end)

-- テストコマンド登録
RegisterCommand('addtestcase', function(source)
    if source > 0 then
        exports.ox_inventory:AddItem(source, 'gun_case', 1)
        print("^3[DEBUG] Added test case to player:", source)
    end
end, false)