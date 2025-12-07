local QBCore = exports['qb-core']:GetCoreObject()

-- デバッグ用の関数
local function Debug(msg)
    if Config.Debug then
        print('[ng-npcs] ' .. msg)
    end
end

-- 管理者権限をチェックする関数
local function IsAdmin(source)
    return IsPlayerAceAllowed(source, 'command.admin')
end

-- リソース開始時のイベント
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    Debug('サーバーサイドリソース起動')
    
    -- 将来的にデータベースからNPC設定を読み込む場合はここに実装
    -- 現在はConfig.luaの静的設定を使用
end)

-- NPCの設定をサーバーから取得するコマンド
RegisterNetEvent('ng-npcs:server:requestNPCRefresh', function()
    local src = source
    
    -- 管理者権限をチェック
    if IsAdmin(src) then
        Debug('管理者によるNPCリフレッシュリクエスト')
        
        -- すべてのクライアントにNPCを再生成するよう通知
        TriggerClientEvent('ng-npcs:client:refreshNPCs', -1, Config.NPCs)
        
        -- 管理者に通知
        TriggerClientEvent('QBCore:Notify', src, 'NPCを再読み込みしました', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'この操作を行う権限がありません', 'error')
    end
end)

-- NPCの設定を追加するコマンド
QBCore.Commands.Add('addnpc', '新しいNPCを追加する（管理者専用）', {}, false, function(source, args)
    local src = source
    
    -- 管理者権限をチェック
    if IsAdmin(src) then
        -- プレイヤーの現在位置を取得
        local ped = GetPlayerPed(src)
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        
        -- 位置情報をフォーマット
        local positionStr = string.format('vector4(%0.2f, %0.2f, %0.2f, %0.2f)', coords.x, coords.y, coords.z, heading)
        
        -- 管理者に位置情報を通知
        TriggerClientEvent('QBCore:Notify', src, '位置: ' .. positionStr, 'success')
        Debug('新しいNPC位置: ' .. positionStr)
        
        -- 将来的にはここでデータベースにNPC情報を保存し、クライアントに反映
    else
        TriggerClientEvent('QBCore:Notify', src, 'この操作を行う権限がありません', 'error')
    end
end, 'admin')

-- プレイヤーベースのNPCを作成するコマンド
QBCore.Commands.Add('createplayernpc', 'プレイヤーの見た目でNPCを作成する（管理者専用）', {{name='citizenid', help='プレイヤーのCitizenID'}, {name='name', help='NPCの名前'}}, true, function(source, args)
    local src = source
    
    -- 管理者権限をチェック
    if IsAdmin(src) then
        local citizenid = args[1]
        local npcName = args[2] or "プレイヤーNPC"
        
        -- プレイヤーの現在位置を取得
        local ped = GetPlayerPed(src)
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        
        -- NPC基本データを作成
        local npcData = {
            id = 'player_npc_' .. citizenid,
            name = npcName,
            coords = vector4(coords.x, coords.y, coords.z, heading),
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
            blip = {
                enabled = false
            },
            dialogues = {
                greeting = 'こんにちは、何かお手伝いできることはありますか？',
                options = {
                    {
                        label = '調子はどう？',
                        response = '元気にしてるよ、ありがとう！'
                    }
                },
                farewell = 'またね！'
            }
        }
        
        -- プレイヤーデータを取得してNPCを作成
        TriggerEvent('ng-npcs:server:createPlayerNPC', citizenid, npcData)
    else
        TriggerClientEvent('QBCore:Notify', src, 'この操作を行う権限がありません', 'error')
    end
end, 'admin')

-- プレイヤーのCitizenIDからNPCを作成するイベント
RegisterNetEvent('ng-npcs:server:createPlayerNPC', function(citizenid, npcData)
    local src = source
    
    -- 管理者権限をチェック
    if IsAdmin(src) then
        Debug('管理者によるプレイヤーNPC作成リクエスト')
        
        -- プレイヤーの外見データを取得
        local playerData = GetPlayerAppearance(citizenid)
        
        if playerData then
            -- プレイヤーが見つかった場合
            local newNPC = npcData
            newNPC.playerSkin = playerData.skin
            newNPC.characterInfo = playerData.charinfo
            
            -- NPCのモデルをPlayerPedに設定
            newNPC.model = 'mp_m_freemode_01' -- デフォルトは男性モデル
            if playerData.skin.sex == 1 then
                newNPC.model = 'mp_f_freemode_01' -- 女性プレイヤーの場合
            end
            
            -- NPCデータをクライアントに送信
            TriggerClientEvent('ng-npcs:client:createPlayerBasedNPC', src, newNPC)
            
            TriggerClientEvent('QBCore:Notify', src, citizenid .. 'のプレイヤーデータを使用したNPCを作成しました', 'success')
        else
            -- プレイヤーが見つからない場合
            TriggerClientEvent('QBCore:Notify', src, '指定されたCitizenIDのプレイヤーが見つかりません', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'この操作を行う権限がありません', 'error')
    end
end)

-- プレイヤーの外見データを取得する関数
local function GetPlayerAppearance(citizenid)
    Debug('プレイヤーの外見データを取得: ' .. citizenid)
    
    local result = nil
    local promise = promise.new()
    
    MySQL.Async.fetchAll('SELECT charinfo, skin FROM players WHERE citizenid = @citizenid', {
        ['@citizenid'] = citizenid
    }, function(results)
        if results and #results > 0 then
            local data = results[1]
            local charinfo = json.decode(data.charinfo)
            local skin = json.decode(data.skin)
            
            result = {
                charinfo = charinfo,
                skin = skin
            }
            
            promise:resolve(result)
        else
            Debug('プレイヤーが見つかりません: ' .. citizenid)
            promise:resolve(nil)
        end
    end)
    
    return Citizen.Await(promise)
end