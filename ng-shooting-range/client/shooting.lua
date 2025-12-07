-- デバッグ関数
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

-- グローバル変数
local currentNpc = nil
local npcSpawnTime = 0
local npcEntity = nil

-- vector2エリア内のランダム位置を取得
local function GetRandomSpawnPosition(spawnArea)
    -- X座標の範囲を計算
    local minX = math.min(
        spawnArea.point1.x,
        spawnArea.point2.x,
        spawnArea.point3.x,
        spawnArea.point4.x
    )
    local maxX = math.max(
        spawnArea.point1.x,
        spawnArea.point2.x,
        spawnArea.point3.x,
        spawnArea.point4.x
    )
    
    -- Y座標の範囲を計算
    local minY = math.min(
        spawnArea.point1.y,
        spawnArea.point2.y,
        spawnArea.point3.y,
        spawnArea.point4.y
    )
    local maxY = math.max(
        spawnArea.point1.y,
        spawnArea.point2.y,
        spawnArea.point3.y,
        spawnArea.point4.y
    )
    
    -- ランダム位置生成
    local x = minX + math.random() * (maxX - minX)
    local y = minY + math.random() * (maxY - minY)
    
    -- 地面の高さを取得
    local z = spawnArea.minZ
    local found, groundZ = GetGroundZFor_3dCoord(x, y, spawnArea.maxZ, false)
    
    if found and groundZ >= spawnArea.minZ and groundZ <= spawnArea.maxZ then
        z = groundZ
    else
        -- 地面が見つからない場合は範囲内のランダムなZ座標を使用
        z = spawnArea.minZ + math.random() * (spawnArea.maxZ - spawnArea.minZ)
    end
    
    DebugPrint('Spawn position calculated:', x, y, z)
    return vector3(x, y, z)
end

-- NPCをスポーン
local function SpawnTarget(spawnArea, heading)
    local spawnPos = GetRandomSpawnPosition(spawnArea)
    
    -- モデルをロード
    local modelHash = GetHashKey(Config.GameSettings.npcModel)
    RequestModel(modelHash)
    
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Citizen.Wait(10)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(modelHash) then
        ErrorPrint('Failed to load NPC model:', Config.GameSettings.npcModel)
        return nil
    end
    
    -- NPCを作成
    local npc = CreatePed(4, modelHash, spawnPos.x, spawnPos.y, spawnPos.z, heading, false, true)
    
    if not DoesEntityExist(npc) then
        ErrorPrint('Failed to create NPC entity')
        SetModelAsNoLongerNeeded(modelHash)
        return nil
    end
    
    -- NPC設定
    SetEntityHealth(npc, Config.GameSettings.npcHealth)
    SetPedArmour(npc, Config.GameSettings.npcArmor)
    SetEntityInvincible(npc, Config.GameSettings.npcInvincible)
    FreezeEntityPosition(npc, Config.GameSettings.npcFrozen)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetPedFleeAttributes(npc, 0, false)
    SetPedCombatAttributes(npc, 17, true)
    
    SetModelAsNoLongerNeeded(modelHash)
    
    DebugPrint('NPC spawned at:', spawnPos)
    SuccessPrint('Target spawned successfully')
    
    return npc
end

-- NPCをデスポーン
local function DespawnTarget(npc)
    if DoesEntityExist(npc) then
        DeleteEntity(npc)
        DebugPrint('NPC despawned')
    end
end

-- 命中部位を判定
local function GetHitBodyPart(npc, coords)
    local headBone = GetPedBoneIndex(npc, 31086) -- SKEL_HEAD
    local headCoords = GetWorldPositionOfEntityBone(npc, headBone)
    local headDistance = #(coords - headCoords)
    
    if headDistance < 0.3 then
        return 'head'
    end
    
    local torsoBone = GetPedBoneIndex(npc, 24818) -- SKEL_Spine3
    local torsoCoords = GetWorldPositionOfEntityBone(npc, torsoBone)
    local torsoDistance = #(coords - torsoCoords)
    
    if torsoDistance < 0.5 then
        return 'torso'
    end
    
    return 'other'
end

-- タイムボーナスを計算
local function GetTimeBonus(reactionTime)
    for _, bonus in ipairs(Config.Scoring.timeBonus) do
        if reactionTime <= bonus.time then
            return bonus.bonus
        end
    end
    return 0
end

-- スコアを計算
local function CalculateScore(bodyPart, reactionTime)
    local baseScore = Config.Scoring.bodyParts[bodyPart] or 0
    local timeBonus = GetTimeBonus(reactionTime)
    local totalScore = baseScore + timeBonus
    
    DebugPrint('Score calculation - Body part:', bodyPart, 'Base:', baseScore, 'Time bonus:', timeBonus, 'Total:', totalScore)
    
    return totalScore
end

-- NPC監視スレッド
local function MonitorTarget(npc, spawnTime, maxLifetime)
    local startTime = GetGameTimer()
    local hit = false
    local hitScore = 0
    local reactionTime = 0.0
    
    while GetGameTimer() - startTime < maxLifetime do
        Citizen.Wait(0)
        
        if not DoesEntityExist(npc) then
            DebugPrint('NPC entity no longer exists')
            break
        end
        
        if IsEntityDead(npc) then
            local currentTime = GetGameTimer()
            reactionTime = (currentTime - spawnTime) / 1000.0
            
            -- 最後のダメージ座標を取得
            local damageCoords = GetPedLastDamageBone(npc)
            local bodyPart = GetHitBodyPart(npc, GetEntityCoords(npc))
            
            hitScore = CalculateScore(bodyPart, reactionTime)
            hit = true
            
            DebugPrint('Target hit! Body part:', bodyPart, 'Time:', reactionTime, 'Score:', hitScore)
            SuccessPrint('Target eliminated in', reactionTime, 'seconds')
            
            break
        end
    end
    
    return hit, hitScore, reactionTime
end

-- 射撃練習開始
function StartShootingPractice(range, targetCount)
    SetSessionActive(true)
    ResetScore()
    ShowScoreHud(targetCount)
    
    DebugPrint('Starting shooting practice with', targetCount, 'targets')
    
    Citizen.CreateThread(function()
        for i = 1, targetCount do
            DebugPrint('Spawning target', i, '/', targetCount)
            
            -- NPCをスポーン
            local npc = SpawnTarget(range.spawnArea, range.heading)
            
            if not npc then
                ErrorPrint('Failed to spawn target', i)
                Citizen.Wait(1000)
                goto continue
            end
            
            npcEntity = npc
            npcSpawnTime = GetGameTimer()
            
            -- NPCを監視（撃たれるか、時間切れまで）
            local hit, score, time = MonitorTarget(npc, npcSpawnTime, Config.GameSettings.npcLifetime)
            
            -- スコアを更新
            UpdateScore(score, time, hit)
            
            -- NPCをデスポーン
            DespawnTarget(npc)
            npcEntity = nil
            
            -- 次のターゲットまで少し待機
            if i < targetCount then
                Citizen.Wait(500)
            end
            
            ::continue::
        end
        
        -- セッション終了
        DebugPrint('Practice session completed')
        EndSession()
    end)
end

-- セッション終了
function EndSession()
    HideScoreHud()
    
    -- 結果表示
    ShowResults()
    
    -- 残っているNPCを削除
    if npcEntity and DoesEntityExist(npcEntity) then
        DespawnTarget(npcEntity)
        npcEntity = nil
    end
    
    SetSessionActive(false)
    DebugPrint('Session ended')
end
