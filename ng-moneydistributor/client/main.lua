local QBCore = exports['qb-core']:GetCoreObject()
local nearbyPlayers = {} -- グローバル変数に変更

-- CitizenIDを受け取るイベント
RegisterNetEvent('ng-moneydistributor:client:receiveCitizenID')
AddEventHandler('ng-moneydistributor:client:receiveCitizenID', function(playerId, citizenId)
    for i, player in ipairs(nearbyPlayers) do
        if player.id == playerId then
            player.citizenid = citizenId
            break
        end
    end
end)

-- 近くのプレイヤーを取得する関数
local function GetNearbyPlayers()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local players = QBCore.Functions.GetPlayers()
    
    -- グローバル変数のリセット
    nearbyPlayers = {}
    
    for _, player in ipairs(players) do
        local targetPed = GetPlayerPed(player)
        if targetPed ~= playerPed then
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)
            
            if distance <= Config.MaxDistance then
                local targetPlayer = GetPlayerServerId(player)
                local targetName = GetPlayerName(player)
                
                -- サーバー側でCitizenIDを取得するためのイベントを発火
                TriggerServerEvent('ng-moneydistributor:server:getPlayerCitizenID', targetPlayer)
                
                table.insert(nearbyPlayers, {
                    id = targetPlayer,
                    name = targetName,
                    citizenid = "取得中...", -- 初期値
                    distance = math.floor(distance)
                })
            end
        end
    end
    
    -- メニューが表示されるまで少し待ち、CitizenIDの取得を待つ
    Wait(200)
    
    return nearbyPlayers
end

-- お金分配メニューを開く関数
local function OpenMoneyDistributorMenu()
    local players = GetNearbyPlayers()
    
    if #players == 0 then
        lib.notify({
            title = Config.UITitle,
            description = '近くにプレイヤーがいません',
            type = 'error'
        })
        return
    end

    -- プレイヤー選択用のチェックボックスを作成
    local playerOptions = {}
    for i, player in ipairs(players) do
        table.insert(playerOptions, {
            label = ('%s [ID:%s] [CitizenID:%s] (%sm)'):format(player.name, player.id, player.citizenid, player.distance),
            value = player.id
        })
    end

    -- UIの作成
    local input = lib.inputDialog(Config.UITitle, {
        {
            type = 'number',
            label = '金額',
            description = '分配する金額を入力してください',
            icon = 'money-bill',
            required = true,
            min = 1,
            default = Config.DefaultAmount
        },
        {
            type = 'select',
            label = '支払方法',
            description = '支払方法を選択してください',
            icon = 'wallet',
            options = {
                { label = '現金', value = 'cash' },
                { label = '銀行', value = 'bank' }
            },
            default = 'cash',
            required = true
        },
        {
            type = 'multi-select',
            label = 'プレイヤー選択',
            description = '分配するプレイヤーを選択してください（複数選択可）',
            icon = 'users',
            options = playerOptions,
            required = true
        }
    })

    if not input then return end

    local amount = input[1]
    local paymentType = input[2]
    local selectedPlayers = input[3]
    
    if not selectedPlayers or #selectedPlayers == 0 then
        lib.notify({
            title = Config.UITitle,
            description = 'プレイヤーを選択してください',
            type = 'error'
        })
        return
    end

    -- サーバーにイベントを送信
    TriggerServerEvent('ng-moneydistributor:server:distributeMoney', amount, paymentType, selectedPlayers)
end

-- 初期化通知
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        lib.notify({
            title = Config.UITitle,
            description = 'スクリプトが正常に読み込まれました',
            type = 'success'
        })
    end
end)

-- Export関数を定義
exports('OpenMenu', function()
    OpenMoneyDistributorMenu()
end)

-- イベントリスナーを追加
RegisterNetEvent('ng-moneydistributor:OpenMenu')
AddEventHandler('ng-moneydistributor:OpenMenu', function()
    OpenMoneyDistributorMenu()
end)