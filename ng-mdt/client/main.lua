local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}

-- PlayerDataの初期化
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        PlayerData = QBCore.Functions.GetPlayerData()
    end
end)

-- 警察職チェック関数
local function isPolice()
    return PlayerData.job and PlayerData.job.name == 'police'
end

-- ボスチェック関数
local function isBoss()
    return PlayerData.job and PlayerData.job.name == 'police' and PlayerData.job.isboss == true
end

-- MDTコマンド登録
RegisterCommand(Config.Command, function()
    if not isPolice() then
        lib.notify({
            title = 'MDT',
            description = Config.Locale.notify_not_police,
            type = 'error'
        })
        return
    end
    
    OpenMainMenu()
end, false)

-- メインメニュー
function OpenMainMenu()
    lib.registerContext({
        id = 'mdt_main_menu',
        title = Config.Locale.menu_title,
        options = {
            {
                title = Config.Locale.menu_create,
                description = '新しい記録を作成',
                icon = 'plus',
                onSelect = function()
                    OpenCreateMenu()
                end
            },
            {
                title = Config.Locale.menu_history,
                description = '過去の記録を確認',
                icon = 'magnifying-glass',
                onSelect = function()
                    OpenHistorySearch()
                end
            },
            {
                title = Config.Locale.menu_vehicle,
                description = '車両情報を照会',
                icon = 'car',
                onSelect = function()
                    OpenVehicleSearch()
                end
            },
            {
                title = Config.Locale.menu_profile,
                description = 'プロファイル管理',
                icon = 'address-book',
                onSelect = function()
                    OpenProfileMenu()
                end
            }
        }
    })
    
    lib.showContext('mdt_main_menu')
end

-- 罰金額表示とクリップボードコピー
function ShowFineResult(fineAmount)
    lib.registerContext({
        id = 'mdt_fine_result',
        title = '記録作成完了',
        options = {
            {
                title = '罰金額（一人あたり）',
                description = string.format('$%s', fineAmount),
                icon = 'dollar-sign',
                disabled = true
            },
            {
                title = 'クリップボードにコピー',
                description = '罰金額をクリップボードにコピーします',
                icon = 'clipboard',
                onSelect = function()
                    lib.setClipboard(tostring(fineAmount))
                    lib.notify({
                        title = 'MDT',
                        description = 'クリップボードにコピーしました: $' .. fineAmount,
                        type = 'success'
                    })
                end
            },
            {
                title = '閉じる',
                icon = 'xmark',
                onSelect = function()
                    -- メニューを閉じる
                end
            }
        }
    })
    
    lib.showContext('mdt_fine_result')
end

-- 車両照会メニュー
function OpenVehicleSearch()
    lib.registerContext({
        id = 'mdt_vehicle_search',
        title = Config.Locale.vehicle_title,
        menu = 'mdt_main_menu',
        options = {
            {
                title = Config.Locale.vehicle_plate_input,
                description = 'ナンバープレートで車両を検索',
                icon = 'keyboard',
                onSelect = function()
                    local input = lib.inputDialog(Config.Locale.vehicle_plate_input, {
                        {
                            type = 'input',
                            label = 'ナンバープレート',
                            placeholder = '例: ABC123',
                            required = true
                        }
                    })
                    
                    if input and input[1] then
                        SearchVehicleByPlate(input[1])
                    end
                end
            },
            {
                title = Config.Locale.vehicle_check_nearby,
                description = '目の前の車両を照会',
                icon = 'car-side',
                onSelect = function()
                    CheckNearbyVehicle()
                end
            }
        }
    })
    
    lib.showContext('mdt_vehicle_search')
end

-- ナンバープレートで車両検索
function SearchVehicleByPlate(plate)
    QBCore.Functions.TriggerCallback('ng-mdt:server:searchVehicle', function(vehicleData)
        if vehicleData then
            ShowVehicleInfo(vehicleData)
        else
            lib.notify({
                title = 'MDT',
                description = Config.Locale.vehicle_not_found,
                type = 'error'
            })
        end
    end, plate)
end

-- 目の前の車両をチェック
function CheckNearbyVehicle()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local vehicle = lib.getClosestVehicle(coords, Config.VehicleCheckDistance, false)
    
    if vehicle then
        local plate = GetVehicleNumberPlateText(vehicle)
        SearchVehicleByPlate(plate)
    else
        lib.notify({
            title = 'MDT',
            description = Config.Locale.vehicle_no_vehicle,
            type = 'error'
        })
    end
end

-- 車両情報表示
function ShowVehicleInfo(vehicleData)
    -- 色のフォーマット
    local colorStr = 'Unknown'
    if type(vehicleData.color) == 'table' then
        if vehicleData.color.r and vehicleData.color.g and vehicleData.color.b then
            colorStr = string.format('RGB(%d, %d, %d)', vehicleData.color.r, vehicleData.color.g, vehicleData.color.b)
        elseif vehicleData.color[1] and vehicleData.color[2] and vehicleData.color[3] then
            colorStr = string.format('RGB(%d, %d, %d)', vehicleData.color[1], vehicleData.color[2], vehicleData.color[3])
        end
    elseif type(vehicleData.color) == 'number' then
        colorStr = 'Color ID: ' .. vehicleData.color
    elseif type(vehicleData.color) == 'string' then
        colorStr = vehicleData.color
    end
    
    lib.registerContext({
        id = 'mdt_vehicle_info',
        title = Config.Locale.vehicle_info_title,
        menu = 'mdt_vehicle_search',
        options = {
            {
                title = Config.Locale.vehicle_model,
                description = vehicleData.model,
                icon = 'car',
                disabled = true
            },
            {
                title = Config.Locale.vehicle_plate,
                description = vehicleData.plate,
                icon = 'rectangle-list',
                onSelect = function()
                    lib.setClipboard(vehicleData.plate)
                    lib.notify({
                        title = 'MDT',
                        description = 'ナンバープレートをコピーしました: ' .. vehicleData.plate,
                        type = 'success'
                    })
                end
            },
            {
                title = Config.Locale.vehicle_owner,
                description = vehicleData.owner,
                icon = 'user',
                disabled = true
            },
            {
                title = Config.Locale.vehicle_citizenid,
                description = vehicleData.citizenid,
                icon = 'id-card',
                onSelect = function()
                    lib.setClipboard(vehicleData.citizenid)
                    lib.notify({
                        title = 'MDT',
                        description = 'CitizenIDをコピーしました: ' .. vehicleData.citizenid,
                        type = 'success'
                    })
                end
            },
            {
                title = Config.Locale.vehicle_color,
                description = colorStr,
                icon = 'palette',
                disabled = true
            },
            {
                title = Config.Locale.btn_close,
                icon = 'xmark',
                onSelect = function()
                    OpenVehicleSearch()
                end
            }
        }
    })
    
    lib.showContext('mdt_vehicle_info')
end

-- ============================================
-- プロファイル管理
-- ============================================

-- プロファイルメニュー
function OpenProfileMenu()
    lib.registerContext({
        id = 'mdt_profile_menu',
        title = Config.Locale.profile_title,
        menu = 'mdt_main_menu',
        options = {
            {
                title = Config.Locale.profile_create,
                description = '新しいプロファイルを作成',
                icon = 'user-plus',
                onSelect = function()
                    OpenProfileCreate()
                end
            },
            {
                title = Config.Locale.profile_search,
                description = 'プロファイルを検索',
                icon = 'magnifying-glass',
                onSelect = function()
                    OpenProfileSearch()
                end
            },
            {
                title = Config.Locale.profile_wanted_list,
                description = '警戒リストの人物を表示',
                icon = 'triangle-exclamation',
                onSelect = function()
                    SearchWantedProfiles()
                end
            }
        }
    })
    
    lib.showContext('mdt_profile_menu')
end

-- プロファイル作成
function OpenProfileCreate()
    -- 危険度レベルの選択肢作成
    local dangerOptions = {}
    for _, level in ipairs(Config.DangerLevels) do
        table.insert(dangerOptions, {
            value = level.value,
            label = level.label
        })
    end
    
    local input = lib.inputDialog(Config.Locale.profile_create, {
        {
            type = 'input',
            label = Config.Locale.profile_citizenid,
            placeholder = '例: ABC12345',
            required = true
        },
        {
            type = 'input',
            label = Config.Locale.profile_fingerprint,
            placeholder = '指紋を入力',
            required = true
        },
        {
            type = 'input',
            label = Config.Locale.profile_alias,
            placeholder = '別名または通称'
        },
        {
            type = 'input',
            label = Config.Locale.profile_dob,
            placeholder = '例: 1990/01/01'
        },
        {
            type = 'input',
            label = Config.Locale.profile_gender,
            placeholder = '例: 男性/女性'
        },
        {
            type = 'input',
            label = Config.Locale.profile_nationality,
            placeholder = '例: 日本'
        },
        {
            type = 'select',
            label = Config.Locale.profile_danger_level,
            options = dangerOptions
        },
        {
            type = 'input',
            label = Config.Locale.profile_organization,
            placeholder = '例: ギャング名'
        },
        {
            type = 'textarea',
            label = Config.Locale.profile_locations,
            placeholder = '頻繁に出没する場所を入力'
        },
        {
            type = 'input',
            label = Config.Locale.profile_photo,
            placeholder = '画像URLを入力'
        },
        {
            type = 'checkbox',
            label = Config.Locale.profile_wanted,
        },
        {
            type = 'textarea',
            label = Config.Locale.profile_notes,
            placeholder = '備考やメモを入力'
        }
    })
    
    if not input then return end
    
    -- 必須項目チェック
    if not input[1] or input[1] == '' or not input[2] or input[2] == '' then
        lib.notify({
            title = 'MDT',
            description = Config.Locale.notify_required_fields,
            type = 'error'
        })
        return
    end
    
    local data = {
        citizenid = input[1],
        fingerprint = input[2],
        alias = input[3],
        dob = input[4],
        gender = input[5],
        nationality = input[6],
        danger_level = input[7],
        organization = input[8],
        known_locations = input[9],
        photo_url = input[10],
        wanted = input[11],
        notes = input[12]
    }
    
    QBCore.Functions.TriggerCallback('ng-mdt:server:createProfile', function(success, message)
        if success then
            lib.notify({
                title = 'MDT',
                description = Config.Locale.notify_profile_created,
                type = 'success'
            })
            OpenProfileMenu()
        else
            if message == 'exists' then
                lib.notify({
                    title = 'MDT',
                    description = Config.Locale.notify_profile_exists,
                    type = 'error'
                })
            else
                lib.notify({
                    title = 'MDT',
                    description = Config.Locale.notify_error,
                    type = 'error'
                })
            end
        end
    end, data)
end

-- プロファイル検索
function OpenProfileSearch()
    local dangerOptions = {{ value = '', label = 'すべて' }}
    for _, level in ipairs(Config.DangerLevels) do
        table.insert(dangerOptions, {
            value = level.value,
            label = level.label
        })
    end
    
    local input = lib.inputDialog(Config.Locale.profile_search, {
        {
            type = 'input',
            label = Config.Locale.profile_citizenid,
            placeholder = 'CitizenIDで検索'
        },
        {
            type = 'input',
            label = Config.Locale.profile_name,
            placeholder = '名前で検索'
        },
        {
            type = 'select',
            label = Config.Locale.profile_danger_level,
            options = dangerOptions
        },
        {
            type = 'input',
            label = Config.Locale.profile_organization,
            placeholder = '所属組織で検索'
        }
    })
    
    if not input then return end
    
    local searchData = {
        citizenid = input[1],
        name = input[2],
        danger_level = input[3],
        organization = input[4],
        wanted_only = false
    }
    
    QBCore.Functions.TriggerCallback('ng-mdt:server:searchProfiles', function(profiles)
        if not profiles or #profiles == 0 then
            lib.notify({
                title = 'MDT',
                description = Config.Locale.profile_not_found,
                type = 'info'
            })
            return
        end
        
        ShowProfileResults(profiles)
    end, searchData)
end

-- 警戒リスト検索
function SearchWantedProfiles()
    local searchData = {
        wanted_only = true
    }
    
    QBCore.Functions.TriggerCallback('ng-mdt:server:searchProfiles', function(profiles)
        if not profiles or #profiles == 0 then
            lib.notify({
                title = 'MDT',
                description = Config.Locale.profile_not_found,
                type = 'info'
            })
            return
        end
        
        ShowProfileResults(profiles)
    end, searchData)
end

-- プロファイル検索結果表示
function ShowProfileResults(profiles)
    local options = {}
    
    for _, profile in ipairs(profiles) do
        local dangerLabel = ''
        for _, level in ipairs(Config.DangerLevels) do
            if level.value == profile.danger_level then
                dangerLabel = level.label
                break
            end
        end
        
        local wantedIcon = profile.wanted == 1 and '⚠️ ' or ''
        
        table.insert(options, {
            title = wantedIcon .. profile.name,
            description = string.format('CitizenID: %s | 危険度: %s', profile.citizenid, dangerLabel),
            icon = 'user',
            onSelect = function()
                ViewProfile(profile.citizenid)
            end
        })
    end
    
    lib.registerContext({
        id = 'mdt_profile_results',
        title = Config.Locale.profile_search,
        menu = 'mdt_profile_menu',
        options = options
    })
    
    lib.showContext('mdt_profile_results')
end

-- プロファイル詳細表示
function ViewProfile(citizenid)
    QBCore.Functions.TriggerCallback('ng-mdt:server:getProfile', function(profile)
        if not profile then
            lib.notify({
                title = 'MDT',
                description = Config.Locale.profile_not_found,
                type = 'error'
            })
            return
        end
        
        local dangerLabel = ''
        for _, level in ipairs(Config.DangerLevels) do
            if level.value == profile.danger_level then
                dangerLabel = level.label
                break
            end
        end
        
        local vehiclesStr = ''
        if profile.vehicles and #profile.vehicles > 0 then
            local vList = {}
            for _, v in ipairs(profile.vehicles) do
                table.insert(vList, string.format('%s (%s)', v.model, v.plate))
            end
            vehiclesStr = table.concat(vList, '\n')
        else
            vehiclesStr = Config.Locale.profile_no_vehicles
        end
        
        local options = {
            {
                title = Config.Locale.profile_citizenid,
                description = profile.citizenid,
                icon = 'id-card',
                onSelect = function()
                    lib.setClipboard(profile.citizenid)
                    lib.notify({
                        title = 'MDT',
                        description = 'CitizenIDをコピーしました',
                        type = 'success'
                    })
                end
            },
            {
                title = Config.Locale.profile_name,
                description = profile.name,
                icon = 'user',
                disabled = true
            },
            {
                title = Config.Locale.profile_fingerprint,
                description = profile.fingerprint,
                icon = 'fingerprint',
                disabled = true
            }
        }
        
        if profile.alias and profile.alias ~= '' then
            table.insert(options, {
                title = Config.Locale.profile_alias,
                description = profile.alias,
                icon = 'mask',
                disabled = true
            })
        end
        
        if profile.dob and profile.dob ~= '' then
            table.insert(options, {
                title = Config.Locale.profile_dob,
                description = profile.dob,
                icon = 'cake-candles',
                disabled = true
            })
        end
        
        if profile.gender and profile.gender ~= '' then
            table.insert(options, {
                title = Config.Locale.profile_gender,
                description = profile.gender,
                icon = 'person',
                disabled = true
            })
        end
        
        if profile.nationality and profile.nationality ~= '' then
            table.insert(options, {
                title = Config.Locale.profile_nationality,
                description = profile.nationality,
                icon = 'flag',
                disabled = true
            })
        end
        
        if dangerLabel ~= '' then
            table.insert(options, {
                title = Config.Locale.profile_danger_level,
                description = dangerLabel,
                icon = 'skull-crossbones',
                disabled = true
            })
        end
        
        if profile.organization and profile.organization ~= '' then
            table.insert(options, {
                title = Config.Locale.profile_organization,
                description = profile.organization,
                icon = 'users',
                disabled = true
            })
        end
        
        if profile.known_locations and profile.known_locations ~= '' then
            table.insert(options, {
                title = Config.Locale.profile_locations,
                description = profile.known_locations,
                icon = 'location-dot',
                disabled = true
            })
        end
        
        table.insert(options, {
            title = Config.Locale.profile_vehicles,
            description = vehiclesStr,
            icon = 'car',
            disabled = true
        })
        
        if profile.photo_url and profile.photo_url ~= '' then
            table.insert(options, {
                title = Config.Locale.profile_photo,
                description = '画像を表示',
                icon = 'image',
                onSelect = function()
                    lib.notify({
                        title = 'MDT',
                        description = '画像URL: ' .. profile.photo_url,
                        type = 'info',
                        duration = 10000
                    })
                end
            })
        end
        
        if profile.notes and profile.notes ~= '' then
            table.insert(options, {
                title = Config.Locale.profile_notes,
                description = profile.notes,
                icon = 'note-sticky',
                disabled = true
            })
        end
        
        table.insert(options, {
            title = Config.Locale.profile_wanted,
            description = profile.wanted and '警戒リスト登録済' or '未登録',
            icon = profile.wanted and 'triangle-exclamation' or 'circle-check',
            disabled = true
        })
        
        table.insert(options, {
            title = Config.Locale.btn_edit,
            icon = 'pen-to-square',
            onSelect = function()
                EditProfile(profile)
            end
        })
        
        if isBoss() then
            table.insert(options, {
                title = Config.Locale.btn_delete,
                icon = 'trash',
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = '削除確認',
                        content = 'このプロファイルを削除してもよろしいですか?',
                        centered = true,
                        cancel = true
                    })
                    
                    if confirm == 'confirm' then
                        QBCore.Functions.TriggerCallback('ng-mdt:server:deleteProfile', function(success)
                            if success then
                                lib.notify({
                                    title = 'MDT',
                                    description = Config.Locale.notify_profile_deleted,
                                    type = 'success'
                                })
                                OpenProfileMenu()
                            else
                                lib.notify({
                                    title = 'MDT',
                                    description = Config.Locale.notify_error,
                                    type = 'error'
                                })
                            end
                        end, citizenid)
                    end
                end
            })
        end
        
        lib.registerContext({
            id = 'mdt_profile_detail',
            title = Config.Locale.profile_info_title,
            menu = 'mdt_profile_results',
            options = options
        })
        
        lib.showContext('mdt_profile_detail')
    end, citizenid)
end

-- プロファイル編集
function EditProfile(profile)
    local dangerOptions = {}
    local defaultDanger = 1
    for i, level in ipairs(Config.DangerLevels) do
        table.insert(dangerOptions, {
            value = level.value,
            label = level.label
        })
        if level.value == profile.danger_level then
            defaultDanger = i
        end
    end
    
    local input = lib.inputDialog('プロファイル編集', {
        {
            type = 'input',
            label = Config.Locale.profile_fingerprint,
            default = profile.fingerprint,
            required = true
        },
        {
            type = 'input',
            label = Config.Locale.profile_alias,
            default = profile.alias
        },
        {
            type = 'input',
            label = Config.Locale.profile_dob,
            default = profile.dob
        },
        {
            type = 'input',
            label = Config.Locale.profile_gender,
            default = profile.gender
        },
        {
            type = 'input',
            label = Config.Locale.profile_nationality,
            default = profile.nationality
        },
        {
            type = 'select',
            label = Config.Locale.profile_danger_level,
            options = dangerOptions,
            default = defaultDanger
        },
        {
            type = 'input',
            label = Config.Locale.profile_organization,
            default = profile.organization
        },
        {
            type = 'textarea',
            label = Config.Locale.profile_locations,
            default = profile.known_locations
        },
        {
            type = 'input',
            label = Config.Locale.profile_photo,
            default = profile.photo_url
        },
        {
            type = 'checkbox',
            label = Config.Locale.profile_wanted,
            checked = profile.wanted
        },
        {
            type = 'textarea',
            label = Config.Locale.profile_notes,
            default = profile.notes
        }
    })
    
    if not input then return end
    
    if not input[1] or input[1] == '' then
        lib.notify({
            title = 'MDT',
            description = Config.Locale.notify_required_fields,
            type = 'error'
        })
        return
    end
    
    local data = {
        citizenid = profile.citizenid,
        fingerprint = input[1],
        alias = input[2],
        dob = input[3],
        gender = input[4],
        nationality = input[5],
        danger_level = input[6],
        organization = input[7],
        known_locations = input[8],
        photo_url = input[9],
        wanted = input[10],
        notes = input[11]
    }
    
    QBCore.Functions.TriggerCallback('ng-mdt:server:updateProfile', function(success)
        if success then
            lib.notify({
                title = 'MDT',
                description = Config.Locale.notify_profile_updated,
                type = 'success'
            })
            ViewProfile(profile.citizenid)
        else
            lib.notify({
                title = 'MDT',
                description = Config.Locale.notify_error,
                type = 'error'
            })
        end
    end, data)
end

-- 作成メニュー
function OpenCreateMenu()
    -- オンライン警察官取得
    QBCore.Functions.TriggerCallback('ng-mdt:server:getOnlineOfficers', function(officers)
        -- オンライン全プレイヤー取得
        QBCore.Functions.TriggerCallback('ng-mdt:server:getOnlinePlayers', function(players)
            
            -- 警察官選択肢作成
            local officerOptions = {}
            for _, officer in ipairs(officers) do
                table.insert(officerOptions, {
                    value = officer.citizenid,
                    label = string.format('|%s|%s|%s|', officer.source, officer.name, officer.citizenid)
                })
            end
            
            -- 犯人選択肢作成
            local criminalOptions = {}
            for _, player in ipairs(players) do
                table.insert(criminalOptions, {
                    value = player.citizenid,
                    label = string.format('|%s|%s|%s|', player.source, player.name, player.citizenid)
                })
            end
            
            -- 罪状選択肢作成
            local crimeOptions = {}
            for i, crime in ipairs(Config.Crimes) do
                table.insert(crimeOptions, {
                    value = i,
                    label = string.format('%s ($%s)', crime.label, crime.fine)
                })
            end
            
            local input = lib.inputDialog(Config.Locale.create_title, {
                {
                    type = 'multi-select',
                    label = Config.Locale.create_officers,
                    description = Config.Locale.create_officers_desc,
                    options = officerOptions,
                    required = true
                },
                {
                    type = 'input',
                    label = Config.Locale.create_manual_input .. ' (警察官)',
                    description = 'CitizenIDをカンマ区切りで入力 (例: ABC123,DEF456)',
                    placeholder = 'ABC123,DEF456'
                },
                {
                    type = 'multi-select',
                    label = Config.Locale.create_crimes,
                    description = Config.Locale.create_crimes_desc,
                    options = crimeOptions,
                    required = true
                },
                {
                    type = 'multi-select',
                    label = Config.Locale.create_criminals,
                    description = Config.Locale.create_criminals_desc,
                    options = criminalOptions,
                    required = true
                },
                {
                    type = 'input',
                    label = Config.Locale.create_manual_input .. ' (犯人)',
                    description = 'CitizenIDをカンマ区切りで入力 (例: ABC123,DEF456)',
                    placeholder = 'ABC123,DEF456'
                },
                {
                    type = 'textarea',
                    label = Config.Locale.create_notes,
                    description = Config.Locale.create_notes_desc,
                    placeholder = '備考を入力...'
                }
            })
            
            if not input then return end
            
            -- バリデーション
            if not input[1] or #input[1] == 0 then
                if not input[2] or input[2] == '' then
                    lib.notify({
                        title = 'MDT',
                        description = Config.Locale.notify_select_officer,
                        type = 'error'
                    })
                    return
                end
            end
            
            if not input[3] or #input[3] == 0 then
                lib.notify({
                    title = 'MDT',
                    description = Config.Locale.notify_select_crime,
                    type = 'error'
                })
                return
            end
            
            if not input[4] or #input[4] == 0 then
                if not input[5] or input[5] == '' then
                    lib.notify({
                        title = 'MDT',
                        description = Config.Locale.notify_select_criminal,
                        type = 'error'
                    })
                    return
                end
            end
            
            -- 手動入力のCitizenIDを統合
            local selectedOfficers = input[1] or {}
            if input[2] and input[2] ~= '' then
                for citizenid in string.gmatch(input[2], '([^,]+)') do
                    citizenid = citizenid:gsub('^%s*(.-)%s*$', '%1') -- トリム
                    if citizenid ~= '' then
                        table.insert(selectedOfficers, citizenid)
                    end
                end
            end
            
            local selectedCriminals = input[4] or {}
            if input[5] and input[5] ~= '' then
                for citizenid in string.gmatch(input[5], '([^,]+)') do
                    citizenid = citizenid:gsub('^%s*(.-)%s*$', '%1') -- トリム
                    if citizenid ~= '' then
                        table.insert(selectedCriminals, citizenid)
                    end
                end
            end
            
            -- 罰金額計算
            local totalFine = 0
            local selectedCrimes = {}
            for _, crimeIndex in ipairs(input[3]) do
                local crime = Config.Crimes[crimeIndex]
                totalFine = totalFine + crime.fine
                table.insert(selectedCrimes, crime.label)
            end
            
            -- データ送信
            local data = {
                officers = selectedOfficers,
                crimes = selectedCrimes,
                fine_amount = totalFine,
                criminals = selectedCriminals,
                notes = input[6] or ''
            }
            
            QBCore.Functions.TriggerCallback('ng-mdt:server:createRecord', function(success)
                if success then
                    lib.notify({
                        title = 'MDT',
                        description = Config.Locale.notify_created,
                        type = 'success'
                    })
                    
                    -- 罰金額表示とクリップボードコピー
                    ShowFineResult(totalFine)
                else
                    lib.notify({
                        title = 'MDT',
                        description = Config.Locale.notify_error,
                        type = 'error'
                    })
                end
            end, data)
            
        end)
    end)
end

-- 履歴検索
function OpenHistorySearch()
    local input = lib.inputDialog(Config.Locale.history_title, {
        {
            type = 'input',
            label = '警察官 CitizenID',
            placeholder = 'CitizenIDで検索'
        },
        {
            type = 'input',
            label = '犯人 CitizenID',
            placeholder = 'CitizenIDで検索'
        },
        {
            type = 'input',
            label = '罪状',
            placeholder = '罪状名で検索'
        },
        {
            type = 'date',
            label = '開始日',
            icon = 'calendar'
        },
        {
            type = 'date',
            label = '終了日',
            icon = 'calendar'
        },
        {
            type = 'input',
            label = '備考',
            placeholder = '備考で検索'
        }
    })
    
    if not input then return end
    
    local searchData = {
        officer = input[1],
        criminal = input[2],
        crime = input[3],
        date_start = input[4],
        date_end = input[5],
        notes = input[6]
    }
    
    QBCore.Functions.TriggerCallback('ng-mdt:server:searchRecords', function(records)
        if not records or #records == 0 then
            lib.notify({
                title = 'MDT',
                description = Config.Locale.history_no_results,
                type = 'info'
            })
            return
        end
        
        ShowSearchResults(records)
    end, searchData)
end

-- 検索結果表示
function ShowSearchResults(records, page)
    page = page or 1
    local startIndex = (page - 1) * Config.ResultsPerPage + 1
    local endIndex = math.min(startIndex + Config.ResultsPerPage - 1, #records)
    local totalPages = math.ceil(#records / Config.ResultsPerPage)
    
    local options = {}
    
    for i = startIndex, endIndex do
        local record = records[i]
        local officersStr = table.concat(record.officers, ', ')
        local crimesStr = table.concat(record.crimes, ', ')
        local criminalsStr = table.concat(record.criminals, ', ')
        
        table.insert(options, {
            title = string.format('記録 #%s', record.id),
            description = string.format('日時: %s\n罪状: %s', record.created_at, crimesStr),
            icon = 'file-lines',
            onSelect = function()
                ShowRecordDetail(record, records, page)
            end
        })
    end
    
    -- ページネーション
    if page > 1 then
        table.insert(options, 1, {
            title = '← 前のページ',
            icon = 'arrow-left',
            onSelect = function()
                ShowSearchResults(records, page - 1)
            end
        })
    end
    
    if page < totalPages then
        table.insert(options, {
            title = '次のページ →',
            icon = 'arrow-right',
            onSelect = function()
                ShowSearchResults(records, page + 1)
            end
        })
    end
    
    lib.registerContext({
        id = 'mdt_search_results',
        title = string.format('%s (ページ %d/%d)', Config.Locale.history_results, page, totalPages),
        menu = 'mdt_main_menu',
        options = options
    })
    
    lib.showContext('mdt_search_results')
end

-- 記録詳細表示
function ShowRecordDetail(record, allRecords, currentPage)
    local officersStr = table.concat(record.officers, '\n')
    local crimesStr = table.concat(record.crimes, '\n')
    local criminalsStr = table.concat(record.criminals, '\n')
    
    local options = {
        {
            title = '対応警察官',
            description = officersStr,
            icon = 'user-shield',
            disabled = true
        },
        {
            title = '罪状',
            description = crimesStr,
            icon = 'scale-balanced',
            disabled = true
        },
        {
            title = '罰金額',
            description = string.format('$%s (一人あたり)', record.fine_amount),
            icon = 'dollar-sign',
            disabled = true
        },
        {
            title = '犯人',
            description = criminalsStr,
            icon = 'user',
            disabled = true
        },
        {
            title = '備考',
            description = record.notes ~= '' and record.notes or 'なし',
            icon = 'note-sticky',
            disabled = true
        },
        {
            title = '作成日時',
            description = record.created_at,
            icon = 'clock',
            disabled = true
        }
    }
    
    -- 編集ボタン
    table.insert(options, {
        title = Config.Locale.btn_edit,
        icon = 'pen-to-square',
        onSelect = function()
            OpenEditMenu(record, allRecords, currentPage)
        end
    })
    
    -- 削除ボタン(ボスのみ)
    if isBoss() then
        table.insert(options, {
            title = Config.Locale.btn_delete,
            icon = 'trash',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = '削除確認',
                    content = 'この記録を削除してもよろしいですか?',
                    centered = true,
                    cancel = true
                })
                
                if confirm == 'confirm' then
                    QBCore.Functions.TriggerCallback('ng-mdt:server:deleteRecord', function(success)
                        if success then
                            lib.notify({
                                title = 'MDT',
                                description = Config.Locale.notify_deleted,
                                type = 'success'
                            })
                            -- 検索結果リストから削除して再表示
                            for i, r in ipairs(allRecords) do
                                if r.id == record.id then
                                    table.remove(allRecords, i)
                                    break
                                end
                            end
                            if #allRecords > 0 then
                                ShowSearchResults(allRecords, currentPage)
                            else
                                OpenMainMenu()
                            end
                        else
                            lib.notify({
                                title = 'MDT',
                                description = Config.Locale.notify_error,
                                type = 'error'
                            })
                        end
                    end, record.id)
                end
            end
        })
    end
    
    lib.registerContext({
        id = 'mdt_record_detail',
        title = string.format('記録 #%s', record.id),
        menu = 'mdt_search_results',
        options = options
    })
    
    lib.showContext('mdt_record_detail')
end

-- 編集メニュー
function OpenEditMenu(record, allRecords, currentPage)
    QBCore.Functions.TriggerCallback('ng-mdt:server:getOnlineOfficers', function(officers)
        QBCore.Functions.TriggerCallback('ng-mdt:server:getOnlinePlayers', function(players)
            
            local officerOptions = {}
            for _, officer in ipairs(officers) do
                table.insert(officerOptions, {
                    value = officer.citizenid,
                    label = string.format('|%s|%s|%s|', officer.source, officer.name, officer.citizenid)
                })
            end
            
            local criminalOptions = {}
            for _, player in ipairs(players) do
                table.insert(criminalOptions, {
                    value = player.citizenid,
                    label = string.format('|%s|%s|%s|', player.source, player.name, player.citizenid)
                })
            end
            
            local crimeOptions = {}
            local defaultCrimes = {}
            for i, crime in ipairs(Config.Crimes) do
                table.insert(crimeOptions, {
                    value = i,
                    label = string.format('%s ($%s)', crime.label, crime.fine)
                })
                -- デフォルト選択を設定
                for _, recordCrime in ipairs(record.crimes) do
                    if crime.label == recordCrime then
                        table.insert(defaultCrimes, i)
                    end
                end
            end
            
            local input = lib.inputDialog('記録編集 #' .. record.id, {
                {
                    type = 'multi-select',
                    label = Config.Locale.create_officers,
                    options = officerOptions,
                    default = record.officers
                },
                {
                    type = 'input',
                    label = Config.Locale.create_manual_input .. ' (警察官)',
                    description = 'CitizenIDをカンマ区切りで入力',
                    placeholder = 'ABC123,DEF456'
                },
                {
                    type = 'multi-select',
                    label = Config.Locale.create_crimes,
                    options = crimeOptions,
                    default = defaultCrimes,
                    required = true
                },
                {
                    type = 'multi-select',
                    label = Config.Locale.create_criminals,
                    options = criminalOptions,
                    default = record.criminals
                },
                {
                    type = 'input',
                    label = Config.Locale.create_manual_input .. ' (犯人)',
                    description = 'CitizenIDをカンマ区切りで入力',
                    placeholder = 'ABC123,DEF456'
                },
                {
                    type = 'textarea',
                    label = Config.Locale.create_notes,
                    default = record.notes,
                    placeholder = '備考を入力...'
                }
            })
            
            if not input then return end
            
            -- バリデーション
            if not input[1] or #input[1] == 0 then
                if not input[2] or input[2] == '' then
                    lib.notify({
                        title = 'MDT',
                        description = Config.Locale.notify_select_officer,
                        type = 'error'
                    })
                    return
                end
            end
            
            if not input[3] or #input[3] == 0 then
                lib.notify({
                    title = 'MDT',
                    description = Config.Locale.notify_select_crime,
                    type = 'error'
                })
                return
            end
            
            if not input[4] or #input[4] == 0 then
                if not input[5] or input[5] == '' then
                    lib.notify({
                        title = 'MDT',
                        description = Config.Locale.notify_select_criminal,
                        type = 'error'
                    })
                    return
                end
            end
            
            local selectedOfficers = input[1] or {}
            if input[2] and input[2] ~= '' then
                for citizenid in string.gmatch(input[2], '([^,]+)') do
                    citizenid = citizenid:gsub('^%s*(.-)%s*$', '%1')
                    if citizenid ~= '' then
                        table.insert(selectedOfficers, citizenid)
                    end
                end
            end
            
            local selectedCriminals = input[4] or {}
            if input[5] and input[5] ~= '' then
                for citizenid in string.gmatch(input[5], '([^,]+)') do
                    citizenid = citizenid:gsub('^%s*(.-)%s*$', '%1')
                    if citizenid ~= '' then
                        table.insert(selectedCriminals, citizenid)
                    end
                end
            end
            
            local totalFine = 0
            local selectedCrimes = {}
            for _, crimeIndex in ipairs(input[3]) do
                local crime = Config.Crimes[crimeIndex]
                totalFine = totalFine + crime.fine
                table.insert(selectedCrimes, crime.label)
            end
            
            local data = {
                id = record.id,
                officers = selectedOfficers,
                crimes = selectedCrimes,
                fine_amount = totalFine,
                criminals = selectedCriminals,
                notes = input[6] or ''
            }
            
            QBCore.Functions.TriggerCallback('ng-mdt:server:updateRecord', function(success)
                if success then
                    lib.notify({
                        title = 'MDT',
                        description = Config.Locale.notify_updated,
                        type = 'success'
                    })
                    -- レコードを更新
                    for i, r in ipairs(allRecords) do
                        if r.id == record.id then
                            allRecords[i] = data
                            allRecords[i].id = record.id
                            allRecords[i].created_at = record.created_at
                            break
                        end
                    end
                    ShowSearchResults(allRecords, currentPage)
                else
                    lib.notify({
                        title = 'MDT',
                        description = Config.Locale.notify_error,
                        type = 'error'
                    })
                end
            end, data)
            
        end)
    end)
end

-- ========================================
-- EXPORTS
-- ========================================

-- Export: MDTメニューを開く
exports('OpenMDT', function()
    if not isPolice() then
        lib.notify({
            title = 'MDT',
            description = Config.Locale.notify_not_police,
            type = 'error'
        })
        return
    end
    
    OpenMainMenu()
end)

-- Event: MDTメニューを開く (Radial Menu用)
RegisterNetEvent('ng-mdt:client:openMDT', function()
    if not isPolice() then
        lib.notify({
            title = 'MDT',
            description = Config.Locale.notify_not_police,
            type = 'error'
        })
        return
    end
    
    OpenMainMenu()
end)