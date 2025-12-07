local function isAllowed(job)
    if not job or not job.name or not job.grade or not job.grade.level then
        return false
    end
    
    if not Config.AllowedJobs[job.name] then
        return false
    end
    
    return job.grade.level >= Config.AllowedJobs[job.name].minGrade
end

local function isAdmin()
    return lib.callback.await('ng-stash:server:isAdmin', false)
end

-- 管理者用の全スタッシュ管理メニュー
local function manageAllStashMenu()
    if not isAdmin() then return end

    lib.callback('ng-stash:server:getAllStashes', false, function(stashes)
        if not stashes or #stashes == 0 then
            lib.notify({
                title = '全保管庫管理',
                description = '保管庫が存在しません',
                type = 'inform'
            })
            return
        end

        -- ジョブごとにスタッシュを分類
        local jobStashes = {}
        for _, stash in ipairs(stashes) do
            if not jobStashes[stash.job] then
                jobStashes[stash.job] = {}
            end
            table.insert(jobStashes[stash.job], stash)
        end

        -- メニューオプションの作成
        local options = {}
        for job, jobStashList in pairs(jobStashes) do
            local jobOption = {
                title = string.format('%s の保管庫一覧', Config.AllowedJobs[job] and Config.AllowedJobs[job].label or job),
                description = string.format('保管庫数: %d', #jobStashList),
                metadata = {
                    {label = 'ジョブ', value = job},
                    {label = '総数', value = #jobStashList}
                },
                onSelect = function()
                    local subOptions = {}
                    for _, stash in ipairs(jobStashList) do
                        table.insert(subOptions, {
                            title = stash.label,
                            description = string.format('タイプ: %s', Config.StashTypes[stash.type].label),
                            metadata = {
                                {label = '作成者', value = stash.job},
                                {label = '座標', value = string.format('X: %.2f, Y: %.2f, Z: %.2f', stash.coords.x, stash.coords.y, stash.coords.z)}
                            },
                            onSelect = function()
                                lib.registerContext({
                                    id = 'admin_stash_actions',
                                    title = stash.label,
                                    menu = 'admin_job_stashes',
                                    options = {
                                        {
                                            title = '保管庫を開く',
                                            description = '保管庫の中身を確認します',
                                            icon = 'box-open',
                                            onSelect = function()
                                                exports.ox_inventory:openInventory('stash', stash.id)
                                            end
                                        },
                                        {
                                            title = 'テレポート',
                                            description = '保管庫の位置へ移動します',
                                            icon = 'location-arrow',
                                            onSelect = function()
                                                SetEntityCoords(cache.ped, stash.coords.x, stash.coords.y, stash.coords.z)
                                            end
                                        },
                                        {
                                            title = '削除',
                                            description = '保管庫を削除します',
                                            icon = 'trash',
                                            onSelect = function()
                                                local alert = lib.alertDialog({
                                                    header = '保管庫の削除',
                                                    content = '本当にこの保管庫を削除しますか？\n※この操作は取り消せません',
                                                    centered = true,
                                                    cancel = true
                                                })
                                                
                                                if alert == 'confirm' then
                                                    lib.callback('ng-stash:server:deleteStash', false, function(success)
                                                        if success then
                                                            removeStashPoint(stash.id)
                                                            lib.notify({
                                                                title = '保管庫削除',
                                                                description = '保管庫を削除しました',
                                                                type = 'success'
                                                            })
                                                            manageAllStashMenu()
                                                        end
                                                    end, stash.id)
                                                end
                                            end
                                        }
                                    }
                                })
                                lib.showContext('admin_stash_actions')
                            end
                        })
                    end

                    lib.registerContext({
                        id = 'admin_job_stashes',
                        title = string.format('%s の保管庫一覧', Config.AllowedJobs[job] and Config.AllowedJobs[job].label or job),
                        menu = 'admin_all_stashes',
                        options = subOptions
                    })
                    lib.showContext('admin_job_stashes')
                end
            }
            table.insert(options, jobOption)
        end

        lib.registerContext({
            id = 'admin_all_stashes',
            title = '全保管庫管理 [Admin]',
            menu = 'stash_main_menu',
            options = options
        })
        lib.showContext('admin_all_stashes')
    end)
end

-- スタッシュの同期イベントを処理
RegisterNetEvent('ng-stash:client:syncStash', function(type, data)
    if not data then return end

    local job = lib.callback.await('ng-stash:server:getJob', false)
    if not job then return end

    if type == 'create' then
        -- 非同期処理を保護
        Citizen.CreateThread(function()
            if data.job == job.name or isAdmin() then
                createStashPoint(data)
            end
        end)
    elseif type == 'delete' then
        removeStashPoint(data.id)
    end
end)

-- スタッシュポイントの作成
local stashPoints = {} -- スタッシュポイントを追跡

function createStashPoint(stash)
    if not stash or not stash.id or not stash.coords then
        print('[Stash] Invalid stash data:', json.encode(stash or {}))
        return false
    end

    -- 既存のポイントがあれば削除
    if stashPoints[stash.id] then
        removeStashPoint(stash.id)
    end
    
    -- 座標を確実に取得
    local coords = type(stash.coords) == 'vector3' and stash.coords or vector3(stash.coords.x, stash.coords.y, stash.coords.z)
    
    -- ターゲットの位置を調整
    local adjustedCoords = vector3(coords.x, coords.y, coords.z + 0.5)
    
    -- エラーハンドリング付きでゾーン作成
    local success, result = pcall(function()
        if Config.TargetSystem == 'ox_target' then
            return exports.ox_target:addSphereZone({
                coords = adjustedCoords,
                radius = 3.0,
                debug = false,
                drawSprite = true,
                options = {
                    {
                        name = 'stash_' .. stash.id,
                        icon = 'fas fa-box',
                        label = stash.label or 'Stash',
                        distance = 3.5,
                        onSelect = function()
                            exports.ox_inventory:openInventory('stash', stash.id)
                        end,
                        canInteract = function()
                            local job = lib.callback.await('ng-stash:server:getJob', false)
                            return job and job.name == stash.job
                        end
                    }
                }
            })
        elseif Config.TargetSystem == 'qb-target' then
            -- For qb-target, create a box zone instead
            exports['qb-target']:AddBoxZone(
                'stash_' .. stash.id, 
                adjustedCoords, 
                2.0, 2.0, {
                    name = 'stash_' .. stash.id,
                    heading = 0.0,
                    debugPoly = false,
                    minZ = coords.z - 1.0,
                    maxZ = coords.z + 2.0,
                }, {
                    options = {
                        {
                            icon = 'fas fa-box',
                            label = stash.label or 'Stash',
                            job = stash.job,
                            action = function()
                                exports.ox_inventory:openInventory('stash', stash.id)
                            end,
                        },
                    },
                    distance = 3.5
                }
            )
            
            -- qb-target doesn't return an ID, so we'll create one
            return 'stash_' .. stash.id
        else
            error('[Stash] Invalid target system specified in config: ' .. (Config.TargetSystem or 'nil'))
        end
    end)

    if success and result then
        stashPoints[stash.id] = result
        return true
    else
        print('[Stash] Failed to create zone:', result)
        return false
    end
end

-- We also need to modify the removeStashPoint function to handle both systems
function removeStashPoint(stashId)
    if not stashPoints[stashId] then return end
    
    local success, error = pcall(function()
        if Config.TargetSystem == 'ox_target' then
            exports.ox_target:removeZone(stashPoints[stashId])
        elseif Config.TargetSystem == 'qb-target' then
            exports['qb-target']:RemoveZone('stash_' .. stashId)
        end
    end)
    
    if not success then
        print('[Stash] Error removing stash point:', error)
    end
    
    stashPoints[stashId] = nil
end

-- 既存のスタッシュポイントの読み込み
CreateThread(function()
    Wait(2000) -- サーバーからのデータ受信を待機（時間を増やす）
    
    local job = lib.callback.await('ng-stash:server:getJob', false)
    if not job then return end
    
    local stashes = lib.callback.await('ng-stash:server:getStashes', false, job.name, false)
    if stashes then
        for _, stash in ipairs(stashes) do
            -- 各スタッシュの作成を個別のスレッドで処理
            Citizen.CreateThread(function()
                if stash.job == job.name then
                    Wait(100) -- スタッシュごとに少し待機
                    createStashPoint(stash)
                end
            end)
        end
    end
end)

-- スタッシュ作成時の追加チェック
local function validateStashCreation(job, coords)
    -- 近くの既存スタッシュをチェック
    local stashes = lib.callback.await('ng-stash:server:getStashes', false, job.name, false)
    if stashes then
        for _, stash in ipairs(stashes) do
            local distance = #(vector3(stash.coords.x, stash.coords.y, stash.coords.z) - coords)
            if distance < 2.0 then
                return false, '既に近くに保管庫が存在します'
            end
        end
    end
    return true
end

-- スタッシュ作成メニュー
local function createStashMenu(job)
    local currentCount = lib.callback.await('ng-stash:server:getStashCount', false, job.name)
    local maxStashes = Config.AllowedJobs[job.name].maxStashes

    local options = {}
    for type, data in pairs(Config.StashTypes) do
        options[#options + 1] = {
            title = data.label,
            description = string.format('スロット数: %d, 重量制限: %dkg', data.slots, data.weight/1000),
            metadata = {
                {label = '作成済み', value = string.format('%d / %d', currentCount, maxStashes)}
            },
            disabled = currentCount >= maxStashes,
            onSelect = function()
                if currentCount >= maxStashes then
                    lib.notify({
                        title = '保管庫作成エラー',
                        description = string.format('作成可能な保管庫の上限（%d個）に達しています', maxStashes),
                        type = 'error'
                    })
                    return
                end

                local input = lib.inputDialog('保管庫の作成', {
                    {type = 'input', label = '保管庫の名前', required = true, min = 3, max = 20},
                })
                if not input then return end
                
                local coords = GetEntityCoords(cache.ped)
                local name = input[1]
                
                lib.callback('ng-stash:server:createStash', false, function(success, message, stashData)
                    if success and stashData then
                        local created = createStashPoint(stashData)
                        if created then
                            lib.notify({
                                title = '保管庫作成',
                                description = message,
                                type = 'success'
                            })
                        else
                            lib.notify({
                                title = '保管庫作成エラー',
                                description = 'スタッシュポイントの作成に失敗しました',
                                type = 'error'
                            })
                        end
                    else
                        lib.notify({
                            title = '保管庫作成エラー',
                            description = message,
                            type = 'error'
                        })
                    end
                end, job.name, type, name, coords)
            end
        }
    end

    lib.registerContext({
        id = 'stash_create_menu',
        title = string.format('%s - 保管庫作成 (%d/%d)', 
            Config.AllowedJobs[job.name].label,
            currentCount,
            maxStashes
        ),
        options = options,
        menu = 'stash_main_menu'
    })

    lib.showContext('stash_create_menu')
end

-- スタッシュ管理メニュー
local function manageStashMenu(job)
    lib.callback('ng-stash:server:getStashes', false, function(stashes)
        if not stashes then return end

        local options = {}
        for _, stash in ipairs(stashes) do
            if stash.job == job.name then
                options[#options + 1] = {
                    title = stash.label,
                    description = string.format('タイプ: %s', Config.StashTypes[stash.type].label),
                    metadata = {
                        {label = '作成者', value = stash.job},
                        {label = '座標', value = string.format('X: %.2f, Y: %.2f, Z: %.2f', stash.coords.x, stash.coords.y, stash.coords.z)}
                    },
                    onSelect = function()
                        lib.registerContext({
                            id = 'stash_actions',
                            title = stash.label,
                            menu = 'stash_manage_menu',
                            options = {
                                {
                                    title = '削除',
                                    description = '保管庫を削除します',
                                    icon = 'trash',
                                    onSelect = function()
                                        local alert = lib.alertDialog({
                                            header = '保管庫の削除',
                                            content = '本当にこの保管庫を削除しますか？\n※この操作は取り消せません',
                                            centered = true,
                                            cancel = true
                                        })
                                        
                                        if alert == 'confirm' then
                                            lib.callback('ng-stash:server:deleteStash', false, function(success)
                                                if success then
                                                    removeStashPoint(stash.id)
                                                    lib.notify({
                                                        title = '保管庫削除',
                                                        description = '保管庫を削除しました',
                                                        type = 'success'
                                                    })
                                                    manageStashMenu(job)
                                                end
                                            end, stash.id)
                                        end
                                    end
                                }
                            }
                        })
                        lib.showContext('stash_actions')
                    end
                }
            end
        end

        if #options == 0 then
            lib.notify({
                title = '保管庫管理',
                description = '利用可能な保管庫がありません',
                type = 'inform'
            })
            return
        end

        lib.registerContext({
            id = 'stash_manage_menu',
            title = '保管庫管理',
            menu = 'stash_main_menu',
            options = options
        })

        lib.showContext('stash_manage_menu')
    end, job.name, false)
end

-- 初期化状態の追跡
local isInitialized = false

-- スタッシュの初期化処理（改善版）
local function initializeStashes()
    if isInitialized then return end
    
    print('[Stash] Initializing stashes...')
    
    -- 既存のポイントをクリーンアップ
    for stashId, _ in pairs(stashPoints) do
        removeStashPoint(stashId)
    end
    stashPoints = {}

    local job = lib.callback.await('ng-stash:server:getJob', false)
    if not job then 
        print('[Stash] Failed to get job data')
        return 
    end

    local stashes = lib.callback.await('ng-stash:server:getStashes', false, job.name, isAdmin())
    if not stashes then 
        print('[Stash] No stashes found')
        return 
    end

    print('[Stash] Found ' .. #stashes .. ' stashes to initialize')
    for _, stash in ipairs(stashes) do
        if (stash.job == job.name or isAdmin()) then
            local success = createStashPoint(stash)
            if success then
                print('[Stash] Successfully created stash point: ' .. stash.id)
            else
                print('[Stash] Failed to create stash point: ' .. stash.id)
            end
        end
    end
    
    isInitialized = true
end

-- メインメニューの登録
local function openMainMenu()
    local isAdminUser = isAdmin()
    local job = lib.callback.await('ng-stash:server:getJob', false)
    
    if not job or not job.name then
        lib.notify({
            title = '保管庫管理',
            description = 'ジョブ情報の取得に失敗しました',
            type = 'error'
        })
        return
    end

    -- メニューオプションの作成
    local options = {}

    -- 保管庫作成オプション
    if isAllowed(job) then
        table.insert(options, {
            title = '保管庫を作成',
            description = '新しい保管庫を作成します',
            icon = 'plus',
            onSelect = function()
                createStashMenu(job)
            end
        })

        table.insert(options, {
            title = '保管庫を管理',
            description = '既存の保管庫を管理します',
            icon = 'gear',
            onSelect = function()
                manageStashMenu(job)
            end
        })
    end

    -- 管理者メニュー
    if isAdminUser then
        table.insert(options, {
            title = '📋 全保管庫の管理 [Admin]',
            description = '全ての保管庫を管理します',
            icon = 'shield',
            onSelect = function()
                manageAllStashMenu()
            end
        })
    end

    -- メニューのオプションが空の場合
    if #options == 0 then
        lib.notify({
            title = '保管庫管理',
            description = '保管庫管理メニューを使用する権限がありません',
            type = 'error'
        })
        return
    end

    lib.registerContext({
        id = 'stash_main_menu',
        title = '保管庫管理',
        options = options
    })

    lib.showContext('stash_main_menu')
end

-- コマンド登録
RegisterCommand('stash', function()
    local job = lib.callback.await('ng-stash:server:getJob', false)
    
    if not job or not job.name then
        lib.notify({
            title = '保管庫管理',
            description = 'ジョブ情報の取得に失敗しました',
            type = 'error'
        })
        return
    end

    -- ジョブが許可リストにない場合
    if not Config.AllowedJobs[job.name] then
        lib.notify({
            title = '保管庫管理',
            description = 'このジョブでは保管庫を使用できません',
            type = 'error'
        })
        return
    end
    
    -- 管理者または必要なグレード以上の場合のみアクセス可能
    if not isAllowed(job) and not isAdmin() then
        lib.notify({
            title = '保管庫管理',
            description = string.format('このコマンドには%d以上の階級が必要です', Config.AllowedJobs[job.name].minGrade),
            type = 'error'
        })
        return
    end

    openMainMenu()
end)

-- リソースが開始されたときの処理
RegisterNetEvent('ng-stash:client:resourceStarted', function()
    Wait(3000) -- サーバーのデータ読み込みを待機
    initializeStashes()
end)

-- プレイヤーがロードされたときの処理
RegisterNetEvent('ng-stash:client:initializeStashes', function()
    initializeStashes()
end)

-- QBCoreのプレイヤーロードイベント
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000) -- プレイヤーデータの読み込みを待機
    initializeStashes()
end)

-- ジョブが変更されたときの処理
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    Wait(1000)
    initializeStashes()
end)

-- リソース停止時のクリーンアップ
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for stashId, _ in pairs(stashPoints) do
            removeStashPoint(stashId)
        end
    end
end)