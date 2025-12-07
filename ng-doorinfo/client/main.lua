local QBCore = exports['qb-core']:GetCoreObject()

-- ドア情報を保存する変数
local DoorInfo = {}

-- モデル名をハッシュから取得する関数
local function getModelName(hash)
    -- 既知のドアモデルリスト (実際のモデル名は必要に応じて追加してください)
    local knownModels = {
        [-1156992775] = 'p_jewel_door_l',
        [73386408] = 'p_jewel_door_r1',
        -- 他のドアモデルを必要に応じて追加
    }
    
    -- 既知のモデルリストにあればそれを返す
    if knownModels[hash] then
        return knownModels[hash]
    end
    
    -- モデル名が特定できない場合はハッシュ値を文字列として返す
    return tostring(hash)
end

-- ドア情報をリセット
local function resetDoorInfo()
    DoorInfo = {
        textCoords = nil,
        authorizedJobs = Config.DefaultDoorSettings.authorizedJobs,
        locked = Config.DefaultDoorSettings.locked,
        pickable = Config.DefaultDoorSettings.pickable,
        distance = Config.DefaultDoorSettings.distance,
        doors = {}
    }
end

-- 初期化
local function Initialize()
    resetDoorInfo()
end

-- レイキャスト関数（修正版）
local function raycastWeapon()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local offset = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 20.0, 0.0)
    
    local rayHandle = StartShapeTestRay(coords.x, coords.y, coords.z, offset.x, offset.y, offset.z, 16, playerPed, 0)
    local _, hit, hitCoords, _, entityHit = GetShapeTestResult(rayHandle)
    
    return hit, entityHit, hitCoords
end

-- オブジェクト情報の表示
local function displayObjectInfo(entity)
    if entity == 0 or not DoesEntityExist(entity) then return end
    
    local coords = GetEntityCoords(entity)
    local model = GetEntityModel(entity)
    local heading = GetEntityHeading(entity)
    
    local screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    
    if screenX and screenY then
        SetTextFont(4)
        SetTextScale(0.4, 0.4)
        SetTextColour(255, 255, 255, 255)
        SetTextOutline()
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString("モデル: " .. model .. "\nHeading: " .. string.format("%.2f", heading))
        DrawText(screenX, screenY)
    end
end

-- 単一ドア情報の取得
local function getSingleDoorInfo()
    lib.notify({
        title = 'ドア情報取得',
        description = 'ドアを照準して選択してください [左クリックで選択、右クリックでキャンセル]',
        type = 'info',
        position = Config.UI.position,
        duration = 5000
    })
    
    local entity = 0
    local canSelect = true
    
    CreateThread(function()
        while canSelect do
            Wait(0)
            DisableControlAction(0, 25, true) -- 右クリック無効化（照準のみに使用）
            
            -- 右クリックでキャンセル
            if IsControlJustPressed(0, 177) then -- バックスペース/ESC
                lib.notify({
                    title = 'キャンセル',
                    description = '操作がキャンセルされました',
                    type = 'error',
                    position = Config.UI.position
                })
                canSelect = false
                if entity ~= 0 then
                    SetEntityDrawOutline(entity, false)
                end
                return
            end
            
            -- エンティティの情報表示
            if entity ~= 0 then
                displayObjectInfo(entity)
            end
            
            -- 照準中のエンティティを検出
            local hit, entityHit, hitCoords = raycastWeapon()
            
            if hit == 1 and entityHit ~= 0 and entityHit ~= entity then
                -- 以前のエンティティのアウトラインを消す
                if entity ~= 0 then
                    SetEntityDrawOutline(entity, false)
                end
                
                -- 新しいエンティティをハイライト
                entity = entityHit
                SetEntityDrawOutline(entity, true)
                SetEntityDrawOutlineColor(255, 255, 0, 255)
                SetEntityDrawOutlineShader(1)
            end
            
            -- 左クリックで選択
            if entity ~= 0 and IsControlJustPressed(0, 24) then
                local coords = GetEntityCoords(entity)
                local model = GetEntityModel(entity)
                local heading = GetEntityHeading(entity)
                
                -- モデル名を文字列として設定
                local modelName = getModelName(model)
                
                -- ドア情報を設定
                DoorInfo.textCoords = vec3(coords.x, coords.y, coords.z)
                DoorInfo.doors = {
                    {
                        objName = modelName,
                        objYaw = heading,
                        objCoords = vec3(coords.x, coords.y, coords.z)
                    }
                }
                
                SetEntityDrawOutline(entity, false)
                
                -- 直接サーバーイベントを呼び出してクリップボードにコピー
                TriggerServerEvent('ng-doorinfo:server:copyToClipboard', DoorInfo)
                
                lib.notify({
                    title = '成功',
                    description = 'ドア情報を取得しました',
                    type = 'success',
                    position = Config.UI.position
                })
                
                canSelect = false
                break
            end
        end
    end)
end

-- 両開きドア情報の取得
local function getDoubleDoorInfo()
    lib.notify({
        title = 'ドア情報取得',
        description = '1つ目のドアを照準して選択してください [左クリックで選択、右クリックでキャンセル]',
        type = 'info',
        position = Config.UI.position,
        duration = 5000
    })
    
    local entities = {0, 0}
    local coords = {0, 0}
    local headings = {0, 0}
    local models = {0, 0}
    local doorIndex = 1
    local canSelect = true
    local entity = 0
    
    CreateThread(function()
        while canSelect do
            Wait(0)
            DisableControlAction(0, 25, true) -- 右クリック無効化（照準のみに使用）
            
            -- 右クリックでキャンセル
            if IsControlJustPressed(0, 177) then -- バックスペース/ESC
                lib.notify({
                    title = 'キャンセル',
                    description = '操作がキャンセルされました',
                    type = 'error',
                    position = Config.UI.position
                })
                canSelect = false
                if entity ~= 0 then
                    SetEntityDrawOutline(entity, false)
                end
                return
            end
            
            -- エンティティの情報表示
            if entity ~= 0 then
                displayObjectInfo(entity)
            end
            
            if doorIndex > 2 then
                -- 中央点を計算（textCoords用）
                local centerX = (coords[1].x + coords[2].x) / 2
                local centerY = (coords[1].y + coords[2].y) / 2
                local centerZ = (coords[1].z + coords[2].z) / 2
                
                -- モデル名を文字列として設定
                local modelName1 = getModelName(models[1])
                local modelName2 = getModelName(models[2])
                
                -- ドア情報を設定
                DoorInfo.textCoords = vec3(centerX, centerY, centerZ)
                DoorInfo.doors = {
                    {
                        objName = modelName1,
                        objYaw = headings[1],
                        objCoords = vec3(coords[1].x, coords[1].y, coords[1].z)
                    },
                    {
                        objName = modelName2,
                        objYaw = headings[2],
                        objCoords = vec3(coords[2].x, coords[2].y, coords[2].z)
                    }
                }
                
                -- 直接サーバーイベントを呼び出してクリップボードにコピー
                TriggerServerEvent('ng-doorinfo:server:copyToClipboard', DoorInfo)
                
                lib.notify({
                    title = '成功',
                    description = 'ドア情報を取得しました',
                    type = 'success',
                    position = Config.UI.position
                })
                
                canSelect = false
                break
            end
            
            -- 照準中のエンティティを検出
            local hit, entityHit, hitCoords = raycastWeapon()
            
            if hit == 1 and entityHit ~= 0 and entityHit ~= entity then
                -- 以前のエンティティのアウトラインを消す
                if entity ~= 0 then
                    SetEntityDrawOutline(entity, false)
                end
                
                -- 新しいエンティティをハイライト
                entity = entityHit
                SetEntityDrawOutline(entity, true)
                SetEntityDrawOutlineColor(255, 255, 0, 255)
                SetEntityDrawOutlineShader(1)
            end
            
            -- 左クリックで選択
            if entity ~= 0 and IsControlJustPressed(0, 24) then
                entities[doorIndex] = entity
                coords[doorIndex] = GetEntityCoords(entity)
                models[doorIndex] = GetEntityModel(entity)
                headings[doorIndex] = GetEntityHeading(entity)
                
                lib.notify({
                    title = '選択完了',
                    description = doorIndex .. '目のドアを選択しました',
                    type = 'success',
                    position = Config.UI.position,
                    duration = 2000
                })
                
                SetEntityDrawOutline(entity, false)
                entity = 0
                doorIndex = doorIndex + 1
                
                Wait(500)  -- 連続選択を防止
                
                if doorIndex <= 2 then
                    lib.notify({
                        title = 'ドア情報取得',
                        description = doorIndex .. '目のドアを照準して選択してください [左クリックで選択、右クリックでキャンセル]',
                        type = 'info',
                        position = Config.UI.position,
                        duration = 5000
                    })
                end
            end
        end
    end)
end

-- ドア情報取得コマンド
RegisterCommand(Config.Command, function(source, args)
    if args[1] == 'single' then
        resetDoorInfo()
        getSingleDoorInfo()
    elseif args[1] == 'double' then
        resetDoorInfo()
        getDoubleDoorInfo()
    else
        -- メニューではなく直接選択肢を表示
        lib.notify({
            title = 'ドアタイプを選択',
            description = 'コマンドに single または double を付けて実行してください',
            type = 'info',
            position = Config.UI.position
        })
    end
end, false)

-- コマンドサジェスト
TriggerEvent('chat:addSuggestion', '/' .. Config.Command, 'ドア情報を取得', {
    { name = 'type', help = 'ドアタイプ (single/double)' }
})

-- クリップボードにコピーするイベント
RegisterNetEvent('ng-doorinfo:client:copyToClipboard', function(text)
    lib.setClipboard(text)
    lib.notify({
        title = '成功',
        description = 'ドア情報がクリップボードにコピーされました',
        type = 'success',
        position = Config.UI.position
    })
end)

-- 初期化
Initialize()