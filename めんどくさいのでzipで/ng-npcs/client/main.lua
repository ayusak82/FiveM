local QBCore = exports['qb-core']:GetCoreObject()
local createdNPCs = {}
local createdBlips = {}
local showingNameLabels = true

-- デバッグ用の関数
local function Debug(msg)
    if Config.Debug then
        print('[ng-npcs] ' .. msg)
    end
end

-- NPCの頭上に名前を表示する関数（改良版）
local function DrawText3D(x, y, z, text)
    -- テキストのサイズを設定
    SetTextScale(Config.UI.nameLabel.scale, Config.UI.nameLabel.scale)
    -- フォント設定
    SetTextFont(Config.UI.nameLabel.font)
    -- プロポーショナルテキスト設定
    SetTextProportional(1)
    -- テキストの色設定
    SetTextColour(
        Config.UI.nameLabel.color[1], 
        Config.UI.nameLabel.color[2], 
        Config.UI.nameLabel.color[3], 
        Config.UI.nameLabel.color[4]
    )
    -- 縁取りを設定
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    -- テキストをセンター寄せ
    SetTextCentre(1)
    -- テキストを設定する
    SetTextEntry("STRING")
    AddTextComponentString(text)
    -- ワールド座標に3Dテキストを描画
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- NPCを生成する関数
local function CreateNPC(npcData)
    -- モデルのロード
    local model = GetHashKey(npcData.model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    
    Debug('NPCを生成中: ' .. npcData.name)
    
    -- NPCの生成
    local npcPed = CreatePed(4, model, npcData.coords.x, npcData.coords.y, npcData.coords.z - 1.0, npcData.coords.w, false, true)
    FreezeEntityPosition(npcPed, true)
    SetEntityInvincible(npcPed, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    
    -- シナリオの設定（存在する場合）
    if npcData.scenario then
        TaskStartScenarioInPlace(npcPed, npcData.scenario, 0, true)
    end
    
    -- ox_targetのオプション設定
    exports.ox_target:addLocalEntity(npcPed, {
        {
            name = 'ng_npcs:talk_' .. npcData.id,
            icon = 'fas fa-comments',
            label = npcData.name .. 'と会話する',
            distance = Config.UI.interactionDistance,
            onSelect = function()
                TalkToNPC(npcData)
            end
        }
    })
    
    -- NPCを記録
    createdNPCs[npcData.id] = {
        ped = npcPed,
        name = npcData.name,
        coords = vector3(npcData.coords.x, npcData.coords.y, npcData.coords.z)
    }
    
    -- ブリップの作成（有効な場合）
    if npcData.blip and npcData.blip.enabled then
        local blip = AddBlipForCoord(npcData.coords.x, npcData.coords.y, npcData.coords.z)
        SetBlipSprite(blip, npcData.blip.sprite)
        SetBlipColour(blip, npcData.blip.color)
        SetBlipScale(blip, npcData.blip.scale)
        SetBlipAsShortRange(blip, true)
        
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(npcData.blip.label)
        EndTextCommandSetBlipName(blip)
        
        createdBlips[npcData.id] = blip
    end
    
    Debug('NPC生成完了: ' .. npcData.name)
end

-- プレイヤーの見た目を持つNPCを生成する関数
local function CreatePlayerBasedNPC(npcData)
    -- モデルのロード
    local model = GetHashKey(npcData.model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    
    Debug('プレイヤーNPCを生成中: ' .. npcData.name)
    
    -- NPCの生成
    local npcPed = CreatePed(4, model, npcData.coords.x, npcData.coords.y, npcData.coords.z - 1.0, npcData.coords.w, false, true)
    FreezeEntityPosition(npcPed, true)
    SetEntityInvincible(npcPed, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    
    -- プレイヤーの外見を適用
    local skin = npcData.playerSkin
    
    -- 基本的な外見の適用
    -- 性別に応じたモデルロード済み
    
    -- 顔の特徴
    SetPedHeadBlendData(npcPed, 
        skin.mom or 0, 
        skin.dad or 0, 
        0, 
        skin.mom or 0, 
        skin.dad or 0, 
        0, 
        skin.shapeMix or 0.5, 
        skin.skinMix or 0.5, 
        0.0, 
        false
    )
    
    -- 髪型、髪の色
    SetPedComponentVariation(npcPed, 2, skin.hair or 0, 0, 0)
    SetPedHairColor(npcPed, skin.hair_color or 0, skin.hair_color_2 or 0)
    
    -- 眉毛
    SetPedHeadOverlay(npcPed, 2, skin.eyebrows or 0, 1.0)
    SetPedHeadOverlayColor(npcPed, 2, 1, skin.eyebrows_color or 0, skin.eyebrows_color_2 or 0)
    
    -- 肌
    SetPedHeadOverlay(npcPed, 0, skin.blemishes or 0, 1.0)
    
    -- 髭
    SetPedHeadOverlay(npcPed, 1, skin.beard or 0, 1.0)
    SetPedHeadOverlayColor(npcPed, 1, 1, skin.beard_color or 0, skin.beard_color_2 or 0)
    
    -- 目の色
    SetPedEyeColor(npcPed, skin.eye_color or 0)
    
    -- 服装適用（QB-Coreの標準的なスキン構造に基づく）
    -- トルソ
    SetPedComponentVariation(npcPed, 3, skin.arms or 0, 0, 0)
    -- 脚
    SetPedComponentVariation(npcPed, 4, skin.pants or 0, skin.pants_texture or 0, 0)
    -- バッグ
    SetPedComponentVariation(npcPed, 5, skin.bag or 0, 0, 0)
    -- 靴
    SetPedComponentVariation(npcPed, 6, skin.shoes or 0, skin.shoes_texture or 0, 0)
    -- アンダーシャツ
    SetPedComponentVariation(npcPed, 8, skin.t_shirt or 0, skin.t_shirt_texture or 0, 0)
    -- 防弾チョッキなど
    SetPedComponentVariation(npcPed, 9, skin.bproof or 0, 0, 0)
    -- デカール
    SetPedComponentVariation(npcPed, 10, skin.decals or 0, 0, 0)
    -- トップス
    SetPedComponentVariation(npcPed, 11, skin.torso2 or 0, skin.torso2_texture or 0, 0)

    -- アクセサリー
    -- 帽子
    if skin.hat and skin.hat ~= -1 then
        SetPedPropIndex(npcPed, 0, skin.hat, skin.hat_texture or 0, true)
    end
    
    -- メガネ
    if skin.glasses and skin.glasses ~= -1 then
        SetPedPropIndex(npcPed, 1, skin.glasses, skin.glasses_texture or 0, true)
    end
    
    -- 耳アクセサリー
    if skin.ear and skin.ear ~= -1 then
        SetPedPropIndex(npcPed, 2, skin.ear, skin.ear_texture or 0, true)
    end
    
    -- 時計
    if skin.watch and skin.watch ~= -1 then
        SetPedPropIndex(npcPed, 6, skin.watch, skin.watch_texture or 0, true)
    end
    
    -- シナリオの設定（存在する場合）
    if npcData.scenario then
        TaskStartScenarioInPlace(npcPed, npcData.scenario, 0, true)
    end
    
    -- ox_targetのオプション設定
    exports.ox_target:addLocalEntity(npcPed, {
        {
            name = 'ng_npcs:talk_' .. npcData.id,
            icon = 'fas fa-comments',
            label = npcData.name .. 'と会話する',
            distance = Config.UI.interactionDistance,
            onSelect = function()
                TalkToNPC(npcData)
            end
        }
    })
    
    -- NPCを記録
    createdNPCs[npcData.id] = {
        ped = npcPed,
        name = npcData.name,
        coords = vector3(npcData.coords.x, npcData.coords.y, npcData.coords.z)
    }
    
    -- ブリップの作成（有効な場合）
    if npcData.blip and npcData.blip.enabled then
        local blip = AddBlipForCoord(npcData.coords.x, npcData.coords.y, npcData.coords.z)
        SetBlipSprite(blip, npcData.blip.sprite)
        SetBlipColour(blip, npcData.blip.color)
        SetBlipScale(blip, npcData.blip.scale)
        SetBlipAsShortRange(blip, true)
        
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(npcData.blip.label or npcData.name)
        EndTextCommandSetBlipName(blip)
        
        createdBlips[npcData.id] = blip
    end
    
    -- 会話メニューを登録
    RegisterDialogueMenu(npcData)
    
    Debug('プレイヤーNPC生成完了: ' .. npcData.name)
    
    return npcPed
end

-- NPCと会話する関数
function TalkToNPC(npcData)
    -- 会話初期化
    lib.showContext('ng_npcs_dialogue_' .. npcData.id)
end

-- 会話メニューを登録する関数
local function RegisterDialogueMenu(npcData)
    local options = {}
    
    -- 会話オプションを生成
    for i, option in ipairs(npcData.dialogues.options) do
        table.insert(options, {
            title = option.label,
            description = '',
            icon = 'comments',
            onSelect = function()
                -- 応答メッセージを表示
                lib.notify({
                    title = npcData.name,
                    description = option.response,
                    type = 'info',
                    position = 'top',
                    duration = Config.UI.dialogTimeout
                })
                
                -- 少し待ってから別れの挨拶を表示
                Wait(Config.UI.dialogTimeout)
                lib.notify({
                    title = npcData.name,
                    description = npcData.dialogues.farewell,
                    type = 'info',
                    position = 'top',
                    duration = Config.UI.dialogTimeout
                })
            end
        })
    end
    
    -- 会話メニューを登録
    lib.registerContext({
        id = 'ng_npcs_dialogue_' .. npcData.id,
        title = npcData.name,
        options = options,
        onExit = function()
            lib.notify({
                title = npcData.name,
                description = npcData.dialogues.farewell,
                type = 'info',
                position = 'top',
                duration = Config.UI.dialogTimeout
            })
        end,
        onOpen = function()
            -- 挨拶メッセージを表示
            lib.notify({
                title = npcData.name,
                description = npcData.dialogues.greeting,
                type = 'info',
                position = 'top',
                duration = Config.UI.dialogTimeout
            })
        end
    })
end

-- NPC名前表示用のループ
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if showingNameLabels then
            local playerCoords = GetEntityCoords(PlayerPedId())
            for id, npcData in pairs(createdNPCs) do
                -- 新しい形式（テーブル）のNPCデータのみ処理
                if type(npcData) == "table" and npcData.ped ~= nil then
                    if DoesEntityExist(npcData.ped) then
                        local dist = #(playerCoords - npcData.coords)
                        if dist < Config.UI.nameLabel.showDistance then
                            local npcCoords = GetEntityCoords(npcData.ped)
                            -- 頭上の位置にテキストを表示
                            DrawText3D(npcCoords.x, npcCoords.y, npcCoords.z + 1.0, npcData.name)
                        end
                    end
                end
            end
        else
            Citizen.Wait(1000) -- 名前表示無効時は負荷軽減のため待機時間を延ばす
        end
    end
end)

-- リソース起動時にNPCを生成
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    Debug('リソース起動: NPCの生成を開始')
    
    -- 各NPCを生成
    for _, npcData in ipairs(Config.NPCs) do
        CreateNPC(npcData)
        RegisterDialogueMenu(npcData)
    end
    
    Debug('すべてのNPCを生成完了')
end)

-- プレイヤー接続時にNPCを生成
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Debug('プレイヤーロード: NPCの生成を開始')
    
    -- 各NPCを生成
    for _, npcData in ipairs(Config.NPCs) do
        CreateNPC(npcData)
        RegisterDialogueMenu(npcData)
    end
    
    Debug('すべてのNPCを生成完了')
end)

-- リソース停止時にNPCとブリップを削除
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    Debug('リソース停止: NPCとブリップの削除を開始')
    
    -- 生成したNPCを削除
    for id, npcData in pairs(createdNPCs) do
        -- NPCデータが新しい形式かどうかチェック
        if type(npcData) == "table" and npcData.ped ~= nil then
            if DoesEntityExist(npcData.ped) then
                exports.ox_target:removeEntity(npcData.ped)
                DeleteEntity(npcData.ped)
            end
        -- 古い形式（直接エンティティID）の場合
        elseif type(npcData) == "number" then
            if DoesEntityExist(npcData) then
                exports.ox_target:removeEntity(npcData)
                DeleteEntity(npcData)
            end
        end
    end
    
    -- 生成したブリップを削除
    for _, blip in pairs(createdBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    
    Debug('すべてのNPCとブリップの削除完了')
end)

-- プレイヤーがサーバーを離れた時にNPCとブリップを削除
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    Debug('プレイヤーアンロード: NPCとブリップの削除を開始')
    
    -- 生成したNPCを削除
    for id, npcData in pairs(createdNPCs) do
        -- NPCデータが新しい形式かどうかチェック
        if type(npcData) == "table" and npcData.ped ~= nil then
            if DoesEntityExist(npcData.ped) then
                exports.ox_target:removeEntity(npcData.ped)
                DeleteEntity(npcData.ped)
            end
        -- 古い形式（直接エンティティID）の場合
        elseif type(npcData) == "number" then
            if DoesEntityExist(npcData) then
                exports.ox_target:removeEntity(npcData)
                DeleteEntity(npcData)
            end
        end
    end
    
    -- 生成したブリップを削除
    for _, blip in pairs(createdBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    
    createdNPCs = {}
    createdBlips = {}
    
    Debug('すべてのNPCとブリップの削除完了')
end)

-- NPCの設定をサーバーから取得するコマンド（デバッグ/管理者用）
RegisterNetEvent('ng-npcs:client:refreshNPCs', function(npcsData)
    -- 既存のNPCとブリップを削除
    for id, npcData in pairs(createdNPCs) do
        -- NPCデータが新しい形式かどうかチェック
        if type(npcData) == "table" and npcData.ped ~= nil then
            if DoesEntityExist(npcData.ped) then
                exports.ox_target:removeEntity(npcData.ped)
                DeleteEntity(npcData.ped)
            end
        -- 古い形式（直接エンティティID）の場合
        elseif type(npcData) == "number" then
            if DoesEntityExist(npcData) then
                exports.ox_target:removeEntity(npcData)
                DeleteEntity(npcData)
            end
        end
    end
    
    for _, blip in pairs(createdBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    
    createdNPCs = {}
    createdBlips = {}
    
    -- 新しいNPCデータを使用してNPCを再生成
    for _, npcData in ipairs(npcsData) do
        CreateNPC(npcData)
        RegisterDialogueMenu(npcData)
    end
    
    lib.notify({
        title = 'NPCシステム',
        description = 'NPCを再読み込みしました',
        type = 'success'
    })
end)

-- 管理者権限をチェックする関数
local function IsAdmin(callback)
    lib.callback('ng-npcs:server:isAdmin', false, function(isAdmin)
        callback(isAdmin)
    end)
end

-- 管理者用コマンド: NPCを再読み込み
RegisterCommand('reloadnpcs', function()
    IsAdmin(function(isAdmin)
        if isAdmin then
            TriggerServerEvent('ng-npcs:server:requestNPCRefresh')
        else
            lib.notify({
                title = 'NPCシステム',
                description = 'この操作を行う権限がありません',
                type = 'error'
            })
        end
    end)
end, false)

-- NPCの名前表示切り替えコマンド
RegisterCommand('togglenpcnames', function()
    showingNameLabels = not showingNameLabels
    lib.notify({
        title = 'NPCシステム',
        description = showingNameLabels and 'NPC名表示: オン' or 'NPC名表示: オフ',
        type = 'info'
    })
end, false)

-- プレイヤーベースのNPCを作成するイベント
RegisterNetEvent('ng-npcs:client:createPlayerBasedNPC', function(npcData)
    CreatePlayerBasedNPC(npcData)
    
    lib.notify({
        title = 'NPCシステム',
        description = 'プレイヤーの見た目を持つNPCを作成しました',
        type = 'success'
    })
end)