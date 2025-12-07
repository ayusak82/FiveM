local QBCore = exports['qb-core']:GetCoreObject()
local PlayerJobs = {}
local IsAdmin = false

local ShowPlayerJobsList
local ShowAdminJobSelection
local ShowAdminJobMenu

-- Get job label
local function GetJobLabel(job)
    if not job or not QBCore.Shared.Jobs[job] then return job end
    return QBCore.Shared.Jobs[job].label or job
end

-- Get grade label
local function GetGradeLabel(job, grade)
    if not job or not QBCore.Shared.Jobs[job] then return 'Unknown Grade' end
    
    -- gradesの存在確認と名前の取得
    local gradeData = QBCore.Shared.Jobs[job].grades[tostring(grade)]
    if not gradeData then return 'Grade ' .. grade end
    
    return gradeData.name or ('Grade ' .. grade)
end

-- Get job salary
local function GetJobSalary(job, grade)
    -- Base validation
    if not job or not grade then 
        print('Invalid job or grade')
        return 0 
    end

    -- Get job data
    local jobData = QBCore.Shared.Jobs[job]
    if not jobData then 
        print('Job not found:', job)
        return 0 
    end

    -- Debug
    if Config.Debug then
        print('=== GetJobSalary Debug ===')
        print('Job:', job)
        print('Grade:', grade)
        print('Job Data:', json.encode(jobData))
    end

    -- Get grade data
    if not jobData.grades then return 0 end

    -- Luaのテーブルのキーは文字列または数値なので、両方試してみる
    local gradeData = jobData.grades[grade] or jobData.grades[tostring(grade)]

    if Config.Debug then
        print('Trying grade number:', grade)
        print('Trying grade string:', tostring(grade))
        print('Grade Data:', gradeData and json.encode(gradeData) or 'nil')
        print('Raw grades:', json.encode(jobData.grades))
    end

    -- 給与を返す
    if gradeData and gradeData.payment then
        if Config.Debug then
            print('Found payment:', gradeData.payment)
        end
        return gradeData.payment
    end

    return 0
end

-- Get all jobs list
local function GetAllJobs()
    local jobs = {}
    for name, job in pairs(QBCore.Shared.Jobs) do
        if name and job and job.label then
            jobs[#jobs + 1] = {
                name = name,
                label = job.label
            }
        end
    end
    table.sort(jobs, function(a, b) 
        return a.label < b.label 
    end)
    return jobs
end

-- Get all grades for a job
local function GetJobGrades(job)
    if not job or not QBCore.Shared.Jobs[job] then return {} end
    
    local grades = {}
    for grade, data in pairs(QBCore.Shared.Jobs[job].grades) do
        grades[#grades + 1] = {
            grade = tonumber(grade),
            name = data.name
        }
    end
    
    table.sort(grades, function(a, b) return a.grade < b.grade end)
    return grades
end

-- Show admin player search menu
local function ShowAdminPlayerSearch(action, selectedJob, selectedGrade)
    local players = lib.callback.await('ng-multijob:server:GetOnlinePlayers', false)
    local options = {
        {
            title = 'CitizenIDで検索',
            description = 'CitizenIDを直接入力して管理',
            icon = 'id-card',
            onSelect = function()
                local input = lib.inputDialog('CitizenID検索', {
                    {type = 'input', label = 'CitizenID', placeholder = 'CitizenIDを入力してください'},
                })
                if not input or not input[1] then return end
                
                if action == 'add' then
                    TriggerServerEvent('ng-multijob:server:AdminAddJob', input[1], selectedJob, selectedGrade)
                else
                    TriggerServerEvent('ng-multijob:server:AdminRemoveJob', input[1], selectedJob)
                end
            end
        }
    }

    -- Add online players to the list
    for _, player in pairs(players) do
        options[#options + 1] = {
            title = player.name,
            description = ('ID: %s | CID: %s'):format(player.source, player.citizenid),
            metadata = {
                {label = '現在の職業', value = GetJobLabel(player.job)},
                {label = 'グレード', value = GetGradeLabel(player.job, player.grade)}
            },
            onSelect = function()
                if action == 'add' then
                    TriggerServerEvent('ng-multijob:server:AdminAddJob', player.citizenid, selectedJob, selectedGrade)
                else
                    TriggerServerEvent('ng-multijob:server:AdminRemoveJob', player.citizenid, selectedJob)
                end
            end
        }
    end

    lib.registerContext({
        id = 'admin_player_search',
        title = action == 'add' and '職業を追加するプレイヤーを選択' or '職業を削除するプレイヤーを選択',
        menu = 'admin_job_menu',
        options = options
    })

    lib.showContext('admin_player_search')
end

-- Add this function after ShowAdminPlayerSearch function
local function ShowPlayerJobsList(identifier)
    local playerData = lib.callback.await('ng-multijob:server:GetPlayerJobs', false, identifier)
    
    if not playerData then
        lib.notify({
            title = '失敗',
            description = Config.Notifications.error.player_not_found,
            type = 'error'
        })
        return
    end
    
    local options = {
        {
            title = '戻る',
            description = '前のメニューに戻る',
            icon = 'arrow-left',
            menu = 'admin_job_menu'
        },
        {
            title = '新しい職業を追加',
            description = 'このプレイヤーに新しい職業を追加',
            icon = 'plus',
            onSelect = function()
                ShowAdminJobSelection(playerData.citizenid)
            end
        }
    }
    
    -- Add job entries
    for _, jobData in ipairs(playerData.jobs) do
        if jobData and jobData.job then
            local isCurrentJob = playerData.currentJob and playerData.currentJob.name == jobData.job
            
            options[#options + 1] = {
                title = GetJobLabel(jobData.job),
                description = ('グレード: %s'):format(GetGradeLabel(jobData.job, jobData.grade)),
                icon = isCurrentJob and 'check' or 
                       Config.WhitelistJobs[jobData.job] and 'shield' or 
                       'briefcase',
                metadata = {
                    {label = 'ステータス', value = isCurrentJob and '現職' or '待機中'},
                    {label = 'タイプ', value = Config.WhitelistJobs[jobData.job] and '特殊職業' or '一般職業'}
                },
                onSelect = function()
                    local jobOptions = {
                        {
                            title = '職業に就かせる',
                            description = 'この職業に切り替えさせます',
                            icon = 'right-to-bracket',
                            onSelect = function()
                                TriggerServerEvent('ng-multijob:server:AdminSwitchJob', playerData.citizenid, jobData.job)
                                Wait(100)
                                ShowPlayerJobsList(identifier)
                            end
                        }
                    }

                    -- デフォルト職業以外の場合のみ削除オプションを追加
                    if jobData.job ~= Config.DefaultJob then
                        jobOptions[#jobOptions + 1] = {
                            title = '職業を削除',
                            description = 'この職業を完全に削除します',
                            icon = 'trash',
                            onSelect = function()
                                local confirm = lib.alertDialog({
                                    header = '職業削除の確認',
                                    content = GetJobLabel(jobData.job) .. 'を削除してもよろしいですか？',
                                    cancel = true,
                                    labels = {
                                        confirm = '削除する',
                                        cancel = 'キャンセル'
                                    }
                                })
                                
                                if confirm == 'confirm' then
                                    TriggerServerEvent('ng-multijob:server:AdminRemoveJob', playerData.citizenid, jobData.job)
                                    Wait(100)
                                    ShowPlayerJobsList(identifier)
                                end
                            end
                        }
                    end

                    lib.registerContext({
                        id = 'player_job_actions',
                        title = GetJobLabel(jobData.job) .. 'の管理',
                        menu = 'player_jobs_list',
                        options = jobOptions
                    })

                    lib.showContext('player_job_actions')
                end
            }
        end
    end

    lib.registerContext({
        id = 'player_jobs_list',
        title = playerData.name .. 'の職業一覧',
        menu = 'admin_job_menu',
        options = options
    })

    lib.showContext('player_jobs_list')
end

-- Add this new function for showing job selection for target player
ShowAdminJobSelection = function(targetCitizenId)
    local allJobs = GetAllJobs()
    local options = {
        {
            title = '戻る',
            description = '前のメニューに戻る',
            icon = 'arrow-left',
            onSelect = function()
                ShowPlayerJobsList(targetCitizenId)  -- 直接呼び出し
            end
        }
    }

    for _, jobData in ipairs(allJobs) do
        if jobData.name and jobData.label then
            options[#options + 1] = {
                title = jobData.label,
                description = ('職業ID: %s'):format(jobData.name),
                icon = Config.WhitelistJobs[jobData.name] and 'shield' or 'briefcase',
                arrow = true,
                onSelect = function()
                    local grades = GetJobGrades(jobData.name)
                    local gradeOptions = {
                        {
                            title = '戻る',
                            description = '前のメニューに戻る',
                            icon = 'arrow-left',
                            menu = 'admin_job_selection'
                        }
                    }

                    for _, grade in ipairs(grades) do
                        if grade and grade.grade and grade.name then
                            gradeOptions[#gradeOptions + 1] = {
                                title = grade.name,
                                description = ('グレード %s でこの職業を追加'):format(grade.grade),
                                icon = 'plus',
                                onSelect = function()
                                    TriggerServerEvent('ng-multijob:server:AdminAddJob', targetCitizenId, jobData.name, grade.grade)
                                    Wait(100)
                                    ShowPlayerJobsList(targetCitizenId)
                                end
                            }
                        end
                    end

                    lib.registerContext({
                        id = 'admin_grade_selection',
                        title = jobData.label,
                        menu = 'admin_job_selection',
                        options = gradeOptions
                    })

                    lib.showContext('admin_grade_selection')
                end
            }
        end
    end

    lib.registerContext({
        id = 'admin_job_selection',
        title = '職業の追加',
        options = options
    })

    lib.showContext('admin_job_selection')
end

-- Show admin job selection menu
local function ShowAdminJobMenu()
    local allJobs = GetAllJobs()
    local options = {
        {
            title = 'プレイヤー検索',
            description = 'プレイヤーの職業一覧を表示',
            icon = 'magnifying-glass',
            onSelect = function()
                local input = lib.inputDialog('プレイヤー検索', {
                    {type = 'input', label = 'ID / CitizenID', placeholder = 'サーバーIDまたはCitizenIDを入力'},
                })
                if not input or not input[1] then return end
                
                ShowPlayerJobsList(input[1])
            end
        }
    }

    for _, jobData in ipairs(allJobs) do
        if jobData.name and jobData.label then
            options[#options + 1] = {
                title = jobData.label or jobData.name,
                description = ('職業ID: %s'):format(jobData.name),
                icon = Config.WhitelistJobs[jobData.name] and 'shield' or 'briefcase',
                arrow = true,
                onSelect = function()
                    local grades = GetJobGrades(jobData.name)
                    local gradeOptions = {
                        {
                            title = '職業を削除',
                            description = 'プレイヤーからこの職業を削除します',
                            icon = 'trash',
                            onSelect = function()
                                ShowAdminPlayerSearch('remove', jobData.name)
                            end
                        }
                    }

                    for _, grade in ipairs(grades) do
                        if grade and grade.grade and grade.name then
                            gradeOptions[#gradeOptions + 1] = {
                                title = grade.name,
                                description = ('グレード %s でこの職業を追加'):format(grade.grade),
                                icon = 'plus',
                                onSelect = function()
                                    ShowAdminPlayerSearch('add', jobData.name, grade.grade)
                                end
                            }
                        end
                    end

                    lib.registerContext({
                        id = 'admin_grade_menu',
                        title = jobData.label or jobData.name,
                        menu = 'admin_job_menu',
                        options = gradeOptions
                    })

                    lib.showContext('admin_grade_menu')
                end
            }
        end
    end

    lib.registerContext({
        id = 'admin_job_menu',
        title = '職業管理 (Admin)',
        menu = 'job_menu',
        options = options
    })

    lib.showContext('admin_job_menu')
end

-- Show boss hire menu
local function ShowBossHireMenu(job)
    local options = {
        {
            type = 'input',
            label = 'プレイヤー指定',
            description = 'サーバーIDまたはCitizenIDを入力',
            required = true,
            placeholder = 'ID or CitizenID'
        },
        {
            type = 'number',
            label = 'グレード',
            description = '付与する職業グレード',
            required = true,
            min = 0,
            max = 10,
            default = 0
        }
    }

    local input = lib.inputDialog('従業員を雇用', options)
    if not input or not input[1] or not input[2] then return end

    TriggerServerEvent('ng-multijob:server:BossAddJob', input[1], input[2])
end

local function ShowBossFireMenu(job)
    local players = lib.callback.await('ng-multijob:server:GetOnlinePlayers', false)
    local options = {
        {
            title = 'CitizenIDで検索',
            description = 'CitizenIDを直接入力して解雇',
            icon = 'id-card',
            onSelect = function()
                local input = lib.inputDialog('従業員を解雇', {
                    {type = 'input', label = 'CitizenID', placeholder = 'CitizenIDを入力してください'},
                })
                if not input or not input[1] then return end
                
                TriggerServerEvent('ng-multijob:server:BossFireEmployee', input[1], job)
            end
        }
    }

    -- オンラインプレイヤーのリストを追加
    for _, player in pairs(players) do
        -- 同じ職業を持っているプレイヤーのみ表示
        if player.job == job then
            options[#options + 1] = {
                title = player.name,
                description = ('ID: %s | CID: %s'):format(player.source, player.citizenid),
                metadata = {
                    {label = 'グレード', value = GetGradeLabel(player.job, player.grade)}
                },
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = '従業員解雇の確認',
                        content = player.name .. 'を解雇してもよろしいですか？',
                        cancel = true,
                        labels = {
                            confirm = '解雇する',
                            cancel = 'キャンセル'
                        }
                    })
                    
                    if confirm == 'confirm' then
                        TriggerServerEvent('ng-multijob:server:BossFireEmployee', player.citizenid, job)
                    end
                end
            }
        end
    end

    lib.registerContext({
        id = 'boss_fire_menu',
        title = '従業員を解雇',
        menu = 'job_action_menu',
        options = options
    })

    lib.showContext('boss_fire_menu')
end

-- Show job action menu
local function ShowJobActionMenu(job, grade, is_duty)
    if not job then return end

    local currentJob = QBCore.Functions.GetPlayerData().job
    local isCurrentJob = currentJob.name == job

    -- オプションを動的に構築
    local options = {}

    -- 現在の職業かつボス権限がある場合のみ雇用と解雇オプションを追加
    if currentJob.name == job and currentJob.isboss then
        table.insert(options, {
            title = '従業員を雇用',
            description = '新しい従業員を雇用します',
            icon = 'user-plus',
            onSelect = function()
                ShowBossHireMenu(job)
            end
        })

        table.insert(options, {
            title = '従業員を解雇',
            description = '従業員を解雇します',
            icon = 'user-minus',
            onSelect = function()
                ShowBossFireMenu(job)
            end
        })
    end

    -- 職業切り替えオプション
    table.insert(options, {
        title = isCurrentJob and '現在の職業' or '職業に就く',
        description = isCurrentJob and '現在この職業に就いています' or 'この職業に切り替えます',
        icon = isCurrentJob and 'check' or 'right-to-bracket',
        disabled = isCurrentJob,
        onSelect = function()
            if not isCurrentJob then
                TriggerServerEvent('ng-multijob:server:SwitchJob', job)
            end
        end
    })

    -- 職業を辞めるオプション
    if job ~= Config.DefaultJob then
        table.insert(options, {
            title = '職業を辞める',
            description = '現在の職業を削除します',
            icon = 'trash',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = '職業削除の確認',
                    content = GetJobLabel(job) .. 'を辞めてもよろしいですか？',
                    cancel = true,
                    labels = {
                        confirm = '辞める',
                        cancel = 'キャンセル'
                    }
                })
                
                if confirm == 'confirm' then
                    TriggerServerEvent('ng-multijob:server:RemoveJob', job)
                end
            end
        })
    end

    lib.registerContext({
        id = 'job_action_menu',
        title = GetJobLabel(job),
        menu = 'job_menu',
        options = options
    })

    lib.showContext('job_action_menu')
end

-- Show main job menu
local function ShowJobMenu()
    if not PlayerJobs or #PlayerJobs == 0 then 
        lib.notify({
            title = '通知',
            description = '職業情報が見つかりません',
            type = 'error'
        })
        return 
    end

    local options = {}
    local currentJob = QBCore.Functions.GetPlayerData().job

    -- Add Admin Menu if player is admin
    if IsAdmin then
        options[#options + 1] = {
            title = '職業管理 (Admin)',
            description = 'プレイヤーの職業を管理します',
            icon = 'shield',
            onSelect = function()
                ShowAdminJobMenu()
            end
        }
    end

    -- Add player jobs
    for _, jobData in ipairs(PlayerJobs) do
        if jobData and jobData.job then
            -- Debug print
            if Config.Debug then
                print('=== Job Menu Debug ===')
                print('Job Data:', json.encode(jobData))
                print('Job Name:', jobData.job)
                print('Job Grade:', jobData.grade)
                print('QB Job Data:', json.encode(QBCore.Shared.Jobs[jobData.job]))
                print('Grade Data:', json.encode(QBCore.Shared.Jobs[jobData.job].grades[tostring(jobData.grade)]))
                print('Calculated Salary:', GetJobSalary(jobData.job, jobData.grade))
            end

            options[#options + 1] = {
                title = GetJobLabel(jobData.job),
                description = ('グレード: %s | 給与: $%s'):format(
                    GetGradeLabel(jobData.job, jobData.grade),
                    GetJobSalary(jobData.job, jobData.grade)
                ),
                icon = currentJob.name == jobData.job and 'check' or 
                       Config.WhitelistJobs[jobData.job] and 'shield' or 
                       'briefcase',
                arrow = true,  -- 矢印を表示して、サブメニューがあることを示す
                onSelect = function()
                    ShowJobActionMenu(jobData.job, jobData.grade, jobData.is_duty)
                end,
                metadata = {
                    {label = 'ステータス', value = currentJob.name == jobData.job and '現職' or '待機中'},
                    {label = 'タイプ', value = Config.WhitelistJobs[jobData.job] and '特殊職業' or '一般職業'}
                }
            }
        end
    end

    lib.registerContext({
        id = 'job_menu',
        title = '職業管理',
        options = options
    })

    lib.showContext('job_menu')
end

-- Events
RegisterNetEvent('ng-multijob:client:UpdateJobs', function(jobs)
    PlayerJobs = jobs or {}
end)

RegisterNetEvent('ng-multijob:client:SetAdmin', function(isAdmin)
    IsAdmin = isAdmin
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('ng-multijob:server:GetJobs')
    TriggerServerEvent('ng-multijob:server:CheckAdmin')
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    TriggerServerEvent('ng-multijob:server:GetJobs')
end)

-- Resource start handling
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    while not QBCore.Functions.GetPlayerData() do Wait(100) end
    TriggerServerEvent('ng-multijob:server:GetJobs')
    TriggerServerEvent('ng-multijob:server:CheckAdmin')
end)

-- Command registration
RegisterCommand(Config.UI.commandName, function()
    ShowJobMenu()
end)

-- Keybind registration
lib.addKeybind({
    name = 'show_jobs_menu',
    description = '職業メニューを開く',
    defaultKey = Config.UI.keyBind,
    onPressed = function()
        ShowJobMenu()
    end
})