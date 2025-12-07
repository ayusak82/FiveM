local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local blips = {}

-- フレームワーク初期化
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    TriggerServerEvent('ng-blip-creator:server:loadBlips')
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

-- ブリップを作成する関数
local function CreateBlip(blipData)
    local blip = AddBlipForCoord(blipData.x, blipData.y, blipData.z)
    SetBlipSprite(blip, blipData.sprite)
    SetBlipScale(blip, blipData.scale)
    SetBlipColour(blip, blipData.color)
    SetBlipAsShortRange(blip, true)
    SetBlipDisplay(blip, 4)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipData.name)
    EndTextCommandSetBlipName(blip)
    
    blips[blipData.id] = blip
    return blip
end

-- ブリップを削除する関数
local function RemoveBlip(blipId)
    if blips[blipId] then
        RemoveBlip(blips[blipId])
        blips[blipId] = nil
    end
end

-- すべてのブリップをクリアする関数
local function ClearAllBlips()
    for id, blip in pairs(blips) do
        RemoveBlip(blip)
    end
    blips = {}
end

-- ブリップリストを更新する関数
RegisterNetEvent('ng-blip-creator:client:updateBlips', function(blipList)
    ClearAllBlips()
    for _, blipData in pairs(blipList) do
        CreateBlip(blipData)
    end
end)

-- 新しいブリップを追加
RegisterNetEvent('ng-blip-creator:client:addBlip', function(blipData)
    CreateBlip(blipData)
end)

-- ブリップを削除
RegisterNetEvent('ng-blip-creator:client:removeBlip', function(blipId)
    RemoveBlip(blipId)
end)

-- ブリップメニューを開く関数
local function OpenBlipMenu()
    -- サーバーサイドで権限チェックを行うため、クライアントサイドでは軽いチェックのみ
    TriggerServerEvent('ng-blip-creator:server:getBlips')
end

-- ブリップ作成メニューを開く
local function OpenCreateBlipMenu()
    local input = lib.inputDialog(Config.UI.menuTitle, {
        {
            type = 'input',
            label = 'ブリップ名',
            description = '表示されるブリップの名前を入力してください',
            placeholder = 'ブリップ名...',
            required = true,
            min = 1,
            max = 50
        },
        {
            type = 'select',
            label = 'ブリップスプライト',
            description = 'ブリップのアイコンを選択してください',
            options = Config.BlipSprites,
            default = Config.Blips.defaultSprite,
            required = true
        },
        {
            type = 'select',
            label = 'ブリップ色',
            description = 'ブリップの色を選択してください',
            options = Config.BlipColors,
            default = Config.Blips.defaultColor,
            required = true
        },
        {
            type = 'select',
            label = 'ブリップサイズ',
            description = 'ブリップのサイズを選択してください',
            options = Config.BlipScales,
            default = Config.Blips.defaultScale,
            required = true
        },
        {
            type = 'checkbox',
            label = '現在位置に設置',
            description = '現在立っている場所にブリップを設置します'
        }
    })

    if not input then return end

    local coords = GetEntityCoords(PlayerPedId())
    local blipData = {
        name = input[1],
        sprite = input[2],
        color = input[3],
        scale = input[4],
        x = coords.x,
        y = coords.y,
        z = coords.z,
        useCurrentPos = input[5]
    }

    if not input[5] then
        -- 座標入力メニュー
        local coordInput = lib.inputDialog('座標設定', {
            {
                type = 'number',
                label = 'X座標',
                description = 'X座標を入力してください',
                default = math.floor(coords.x),
                required = true
            },
            {
                type = 'number',
                label = 'Y座標',
                description = 'Y座標を入力してください',
                default = math.floor(coords.y),
                required = true
            },
            {
                type = 'number',
                label = 'Z座標',
                description = 'Z座標を入力してください',
                default = math.floor(coords.z),
                required = true
            }
        })

        if not coordInput then return end
        
        blipData.x = coordInput[1]
        blipData.y = coordInput[2]
        blipData.z = coordInput[3]
    end

    TriggerServerEvent('ng-blip-creator:server:createBlip', blipData)
end

-- ブリップ編集メニューを開く
local function OpenEditBlipMenu(blipData)
    local input = lib.inputDialog('ブリップ編集', {
        {
            type = 'input',
            label = 'ブリップ名',
            description = '表示されるブリップの名前を入力してください',
            placeholder = 'ブリップ名...',
            default = blipData.name,
            required = true,
            min = 1,
            max = 50
        },
        {
            type = 'select',
            label = 'ブリップスプライト',
            description = 'ブリップのアイコンを選択してください',
            options = Config.BlipSprites,
            default = blipData.sprite,
            required = true
        },
        {
            type = 'select',
            label = 'ブリップ色',
            description = 'ブリップの色を選択してください',
            options = Config.BlipColors,
            default = blipData.color,
            required = true
        },
        {
            type = 'select',
            label = 'ブリップサイズ',
            description = 'ブリップのサイズを選択してください',
            options = Config.BlipScales,
            default = blipData.scale,
            required = true
        },
        {
            type = 'number',
            label = 'X座標',
            description = 'X座標を入力してください',
            default = blipData.x,
            required = true
        },
        {
            type = 'number',
            label = 'Y座標',
            description = 'Y座標を入力してください',
            default = blipData.y,
            required = true
        },
        {
            type = 'number',
            label = 'Z座標',
            description = 'Z座標を入力してください',
            default = blipData.z,
            required = true
        }
    })

    if not input then return end

    local updatedBlipData = {
        id = blipData.id,
        name = input[1],
        sprite = input[2],
        color = input[3],
        scale = input[4],
        x = input[5],
        y = input[6],
        z = input[7]
    }

    TriggerServerEvent('ng-blip-creator:server:updateBlip', updatedBlipData)
end

-- ブリップリストメニューを開く
RegisterNetEvent('ng-blip-creator:client:openBlipList', function(blipList)
    local menuOptions = {}
    
    -- ブリップ作成ボタン
    table.insert(menuOptions, {
        title = '新しいブリップを作成',
        description = '新しいブリップを作成します',
        icon = 'plus',
        onSelect = function()
            OpenCreateBlipMenu()
        end
    })

    -- セパレーター
    if #blipList > 0 then
        table.insert(menuOptions, {
            title = '─────────────────',
            disabled = true
        })
    end

    -- 既存のブリップリスト
    for _, blip in pairs(blipList) do
        table.insert(menuOptions, {
            title = blip.name,
            description = string.format('座標: %.1f, %.1f, %.1f | 色: %d | スプライト: %d', 
                blip.x, blip.y, blip.z, blip.color, blip.sprite),
            icon = 'map-pin',
            metadata = {
                {label = 'ID', value = blip.id},
                {label = 'スプライト', value = blip.sprite},
                {label = '色', value = blip.color},
                {label = 'サイズ', value = blip.scale}
            },
            onSelect = function()
                local blipOptions = {
                    {
                        title = '編集',
                        description = 'このブリップを編集します',
                        icon = 'edit',
                        onSelect = function()
                            OpenEditBlipMenu(blip)
                        end
                    },
                    {
                        title = 'テレポート',
                        description = 'このブリップの位置にテレポートします',
                        icon = 'location-arrow',
                        onSelect = function()
                            SetEntityCoords(PlayerPedId(), blip.x, blip.y, blip.z, false, false, false, false)
                            lib.notify({
                                title = 'NG Blip Creator',
                                description = string.format('%s にテレポートしました', blip.name),
                                type = 'success',
                                position = 'top'
                            })
                        end
                    },
                    {
                        title = '削除',
                        description = 'このブリップを削除します（取り消しできません）',
                        icon = 'trash',
                        iconColor = 'red',
                        onSelect = function()
                            local confirm = lib.alertDialog({
                                header = 'ブリップ削除確認',
                                content = string.format('本当に "%s" を削除しますか？\nこの操作は取り消しできません。', blip.name),
                                centered = true,
                                cancel = true,
                                labels = {
                                    confirm = '削除',
                                    cancel = 'キャンセル'
                                }
                            })
                            
                            if confirm == 'confirm' then
                                TriggerServerEvent('ng-blip-creator:server:deleteBlip', blip.id)
                            end
                        end
                    }
                }
                
                lib.registerContext({
                    id = 'blip_actions',
                    title = blip.name,
                    options = blipOptions
                })
                
                lib.showContext('blip_actions')
            end
        })
    end

    if #menuOptions == 1 then
        table.insert(menuOptions, {
            title = 'ブリップが見つかりません',
            description = '作成されたブリップがありません',
            disabled = true,
            icon = 'info-circle'
        })
    end

    lib.registerContext({
        id = 'blip_menu',
        title = Config.UI.menuTitle,
        options = menuOptions
    })

    lib.showContext('blip_menu')
end)

-- コマンド登録
RegisterCommand(Config.Commands.blipMenu, function()
    if Config.Commands.adminOnly then
        OpenBlipMenu()
    else
        OpenBlipMenu()
    end
end, false)

-- キーボードマッピング
RegisterKeyMapping(Config.Commands.blipMenu, 'NG Blip Creator メニューを開く', 'keyboard', '')

-- 通知イベント
RegisterNetEvent('ng-blip-creator:client:notify', function(message, type)
    lib.notify({
        title = 'NG Blip Creator',
        description = message,
        type = type or 'info',
        position = 'top'
    })
end)

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        ClearAllBlips()
    end
end)