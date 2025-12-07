-- ============================================
-- CLIENT ADMIN - ng-business
-- ============================================

-- Admin check
local function IsAdmin()
    return lib.callback.await('ng-business:server:isAdmin', false)
end

-- Open admin menu
local function OpenAdminMenu()
    if not IsAdmin() then
        ShowNotification('You do not have permission to access this menu', 'error')
        return
    end
    
    lib.registerContext({
        id = 'business_admin_menu',
        title = 'ビジネス管理',
        options = {
            {
                title = 'ジョブ作成',
                description = '新しいビジネスジョブを作成',
                icon = 'briefcase',
                onSelect = function()
                    TriggerEvent('ng-business:client:createJob')
                end
            },
            {
                title = 'スタッシュ作成',
                description = '新しい保管庫を作成',
                icon = 'box',
                onSelect = function()
                    TriggerEvent('ng-business:client:createStash')
                end
            },
            {
                title = 'トレイ作成',
                description = '新しいカウンタートレイを作成',
                icon = 'table',
                onSelect = function()
                    TriggerEvent('ng-business:client:createTray')
                end
            },
            {
                title = 'クラフトステーション作成',
                description = '新しいクラフトステーションを作成',
                icon = 'hammer',
                onSelect = function()
                    TriggerEvent('ng-business:client:createCrafting')
                end
            },
            {
                title = 'ロッカー作成',
                description = '新しい個人ロッカーを作成',
                icon = 'lock',
                onSelect = function()
                    TriggerEvent('ng-business:client:createLocker')
                end
            },
            {
                title = 'ブリップ作成',
                description = '新しいマップアイコンを作成',
                icon = 'map-marker',
                onSelect = function()
                    TriggerEvent('ng-business:client:createBlip')
                end
            },
            {
                title = '既存アイテム管理',
                description = '既存のアイテムを編集・削除',
                icon = 'edit',
                onSelect = function()
                    TriggerEvent('ng-business:client:manageMenu')
                end
            },
            {
                title = '設定',
                description = 'インタラクションタイプなどの設定',
                icon = 'cog',
                onSelect = function()
                    TriggerEvent('ng-business:client:settingsMenu')
                end
            }
        }
    })
    
    lib.showContext('business_admin_menu')
end

-- Register admin command
RegisterCommand('businessadmin', function()
    OpenAdminMenu()
end, false)

-- Register keybind (optional)
RegisterKeyMapping('businessadmin', 'Open Business Admin Menu', 'keyboard', '')

-- Manage existing items menu
RegisterNetEvent('ng-business:client:manageMenu', function()
    lib.registerContext({
        id = 'business_manage_menu',
        title = '既存アイテム管理',
        menu = 'business_admin_menu',
        options = {
            {
                title = 'スタッシュ管理',
                description = 'スタッシュを編集・削除',
                icon = 'box',
                onSelect = function()
                    TriggerEvent('ng-business:client:manageStashes')
                end
            },
            {
                title = 'トレイ管理',
                description = 'トレイを編集・削除',
                icon = 'table',
                onSelect = function()
                    TriggerEvent('ng-business:client:manageTrays')
                end
            },
            {
                title = 'クラフトステーション管理',
                description = 'クラフトステーションを編集・削除',
                icon = 'hammer',
                onSelect = function()
                    TriggerEvent('ng-business:client:manageCrafting')
                end
            },
            {
                title = 'ロッカー管理',
                description = 'ロッカーを編集・削除',
                icon = 'lock',
                onSelect = function()
                    TriggerEvent('ng-business:client:manageLockers')
                end
            },
            {
                title = 'ブリップ管理',
                description = 'ブリップを編集・削除',
                icon = 'map-marker',
                onSelect = function()
                    TriggerEvent('ng-business:client:manageBlips')
                end
            }
        }
    })
    
    lib.showContext('business_manage_menu')
end)

-- Manage stashes
RegisterNetEvent('ng-business:client:manageStashes', function()
    local data = lib.callback.await('ng-business:server:getBusinessData', false)
    if not data or not data.stashes then return end
    
    local options = {}
    for _, stash in pairs(data.stashes) do
        table.insert(options, {
            title = stash.label,
            description = 'ID: ' .. stash.id,
            icon = 'box',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = stash.label,
                    content = 'どうしますか？',
                    centered = true,
                    cancel = true,
                    labels = {
                        cancel = '戻る',
                        confirm = '削除'
                    }
                })
                
                if alert == 'confirm' then
                    TriggerServerEvent('ng-business:server:deleteStash', stash.id)
                end
            end
        })
    end
    
    lib.registerContext({
        id = 'manage_stashes',
        title = 'スタッシュ管理',
        menu = 'business_manage_menu',
        options = options
    })
    
    lib.showContext('manage_stashes')
end)

-- Manage trays
RegisterNetEvent('ng-business:client:manageTrays', function()
    local data = lib.callback.await('ng-business:server:getBusinessData', false)
    if not data or not data.trays then return end
    
    local options = {}
    for _, tray in pairs(data.trays) do
        table.insert(options, {
            title = tray.label,
            description = 'ID: ' .. tray.id,
            icon = 'table',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = tray.label,
                    content = 'どうしますか？',
                    centered = true,
                    cancel = true,
                    labels = {
                        cancel = '戻る',
                        confirm = '削除'
                    }
                })
                
                if alert == 'confirm' then
                    TriggerServerEvent('ng-business:server:deleteTray', tray.id)
                end
            end
        })
    end
    
    lib.registerContext({
        id = 'manage_trays',
        title = 'トレイ管理',
        menu = 'business_manage_menu',
        options = options
    })
    
    lib.showContext('manage_trays')
end)

-- Manage crafting stations
RegisterNetEvent('ng-business:client:manageCrafting', function()
    local data = lib.callback.await('ng-business:server:getBusinessData', false)
    if not data or not data.crafting then return end
    
    local options = {}
    for _, station in pairs(data.crafting) do
        table.insert(options, {
            title = station.label,
            description = 'ID: ' .. station.id,
            icon = 'hammer',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = station.label,
                    content = 'どうしますか？',
                    centered = true,
                    cancel = true,
                    labels = {
                        cancel = '戻る',
                        confirm = '削除'
                    }
                })
                
                if alert == 'confirm' then
                    TriggerServerEvent('ng-business:server:deleteCrafting', station.id)
                end
            end
        })
    end
    
    lib.registerContext({
        id = 'manage_crafting',
        title = 'クラフトステーション管理',
        menu = 'business_manage_menu',
        options = options
    })
    
    lib.showContext('manage_crafting')
end)

-- Manage lockers
RegisterNetEvent('ng-business:client:manageLockers', function()
    local data = lib.callback.await('ng-business:server:getBusinessData', false)
    if not data or not data.lockers then return end
    
    local options = {}
    for _, locker in pairs(data.lockers) do
        table.insert(options, {
            title = locker.label,
            description = 'ID: ' .. locker.id,
            icon = 'lock',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = locker.label,
                    content = 'どうしますか？',
                    centered = true,
                    cancel = true,
                    labels = {
                        cancel = '戻る',
                        confirm = '削除'
                    }
                })
                
                if alert == 'confirm' then
                    TriggerServerEvent('ng-business:server:deleteLocker', locker.id)
                end
            end
        })
    end
    
    lib.registerContext({
        id = 'manage_lockers',
        title = 'ロッカー管理',
        menu = 'business_manage_menu',
        options = options
    })
    
    lib.showContext('manage_lockers')
end)

-- Manage blips
RegisterNetEvent('ng-business:client:manageBlips', function()
    local data = lib.callback.await('ng-business:server:getBusinessData', false)
    if not data or not data.blips then return end
    
    local options = {}
    for _, blip in pairs(data.blips) do
        table.insert(options, {
            title = blip.label,
            description = 'ID: ' .. blip.id,
            icon = 'map-marker',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = blip.label,
                    content = 'どうしますか？',
                    centered = true,
                    cancel = true,
                    labels = {
                        cancel = '戻る',
                        confirm = '削除'
                    }
                })
                
                if alert == 'confirm' then
                    TriggerServerEvent('ng-business:server:deleteBlip', blip.id)
                end
            end
        })
    end
    
    lib.registerContext({
        id = 'manage_blips',
        title = 'ブリップ管理',
        menu = 'business_manage_menu',
        options = options
    })
    
    lib.showContext('manage_blips')
end)

DebugPrint('Admin module loaded')


-- Settings menu
RegisterNetEvent('ng-business:client:settingsMenu', function()
    local currentInteractionType = Config.InteractionType
    
    lib.registerContext({
        id = 'business_settings_menu',
        title = '設定',
        menu = 'business_admin_menu',
        options = {
            {
                title = 'インタラクションタイプ',
                description = '現在: ' .. (currentInteractionType == 'target' and 'ターゲット' or 'マーカー'),
                icon = currentInteractionType == 'target' and 'crosshairs' or 'map-marker',
                onSelect = function()
                    local alert = lib.alertDialog({
                        header = 'インタラクションタイプ変更',
                        content = 'どちらを使用しますか？',
                        centered = true,
                        cancel = true,
                        labels = {
                            cancel = 'キャンセル',
                            confirm = currentInteractionType == 'target' and 'マーカーに変更' or 'ターゲットに変更'
                        }
                    })
                    
                    if alert == 'confirm' then
                        local newType = currentInteractionType == 'target' and 'marker' or 'target'
                        Config.InteractionType = newType
                        
                        lib.notify({
                            title = '設定変更',
                            description = 'インタラクションタイプを' .. (newType == 'target' and 'ターゲット' or 'マーカー') .. 'に変更しました',
                            type = 'success',
                            duration = Config.UI.notificationDuration
                        })
                        
                        -- リロードして反映
                        TriggerEvent('ng-business:client:reloadInteractions')
                    end
                end
            },
            {
                title = 'レーザーシステム',
                description = 'レーザーで座標を設定: ' .. (Config.Laser.enabled and '有効' or '無効'),
                icon = 'laser-pointer',
                onSelect = function()
                    Config.Laser.enabled = not Config.Laser.enabled
                    lib.notify({
                        title = '設定変更',
                        description = 'レーザーシステムを' .. (Config.Laser.enabled and '有効' or '無効') .. 'にしました',
                        type = 'success',
                        duration = Config.UI.notificationDuration
                    })
                end
            },
            {
                title = 'レーザーテスト',
                description = 'レーザーシステムをテスト',
                icon = 'vial',
                onSelect = function()
                    if not Config.Laser.enabled then
                        lib.notify({
                            title = 'エラー',
                            description = 'レーザーシステムが無効化されています',
                            type = 'error',
                            duration = Config.UI.notificationDuration
                        })
                        return
                    end
                    
                    StartLaser(function(coords)
                        local coordsText = string.format(
                            "vector3(%.2f, %.2f, %.2f)",
                            coords.x, coords.y, coords.z
                        )
                        lib.setClipboard(coordsText)
                        lib.notify({
                            title = '座標取得',
                            description = '座標: ' .. coordsText,
                            type = 'success',
                            duration = Config.UI.notificationDuration
                        })
                    end)
                end
            }
        }
    })
    
    lib.showContext('business_settings_menu')
end)

-- Reload interactions
RegisterNetEvent('ng-business:client:reloadInteractions', function()
    -- スタッシュをリロード
    local data = lib.callback.await('ng-business:server:getBusinessData', false)
    if data then
        if data.stashes then
            TriggerEvent('ng-business:client:updateStashes', data.stashes)
        end
        if data.trays then
            TriggerEvent('ng-business:client:updateTrays', data.trays)
        end
        if data.crafting then
            TriggerEvent('ng-business:client:updateCrafting', data.crafting)
        end
        if data.lockers then
            TriggerEvent('ng-business:client:updateLockers', data.lockers)
        end
    end
end)
