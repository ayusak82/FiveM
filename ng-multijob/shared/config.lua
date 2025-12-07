Config = {}

-- Jobs Settings
Config.MaxJobs = 3

-- Whitelist Jobs Settings (特殊職業)
Config.WhitelistJobs = {
    ['police'] = true,
    ['police_staff'] = true,
    ['ambulance'] = true,
    ['sample_mechanic_1'] = true,
    ['sample_mechanic_2'] = true,
    ['sample_mechanic_3'] = true,
    ['sample_mechanic_4'] = true,
    ['sample_mechanic_5'] = true,
    ['sample_mechanic_6'] = true,
    ['sample_mechanic_7'] = true,
    ['sample_mechanic_8'] = true,
    ['sample_mechanic_9'] = true,
    ['sample_mechanic_10'] = true,
    ['sample_mechanic_11'] = true,
    ['sample_mechanic_12'] = true,
    ['sample_mechanic_13'] = true,
    ['sample_mechanic_14'] = true,
    ['sample_mechanic_15'] = true,
    ['sample_mechanic_16'] = true,
}

-- Default Job Settings (民間人)
Config.DefaultJob = 'unemployed'
Config.DefaultGrade = 0

-- UI Settings
Config.UI = {
    position = 'middle',
    icon = 'briefcase',
    commandName = 'jobs',
    keyBind = 'J'
}

-- Debug Settings
Config.Debug = false

-- Debug Print Function
function Config.Debug_Print(message, ...)
    if Config.Debug then
        local prefix = '[ng-multijob:DEBUG] '
        if ... then
            print(prefix .. string.format(message, ...))
        else
            print(prefix .. message)
        end
    end
end

-- Notifications
Config.Notifications = {
    ['error'] = {
        already_has_job = 'すでにこの職業を持っています',
        already_has_whitelist_job = 'すでに特殊職業を持っています',
        max_jobs_reached = '職業の上限に達しています',
        cannot_remove_default_job = 'デフォルトの職業は削除できません',
        cannot_remove_current_job = '現在就いている職業は削除できません',
        failed_to_load = 'ジョブ情報の読み込みに失敗しました',
        invalid_job = '無効な職業です',
        no_permission = '権限がありません',
        player_not_found = 'プレイヤーが見つかりません',
        not_boss = 'あなたはこの職業のオーナーではありません',
        invalid_input = '入力が無効です',
        not_boss = 'あなたはこの職業のオーナーではありません',
    },
    ['success'] = {
        job_added = '職業が追加されました',
        job_removed = '職業が削除されました',
        job_switched = '職業を切り替えました',
        job_added_other = '%sに職業を追加しました',
        job_removed_other = '%sの職業を削除しました',
        job_added_by_boss = '%sを雇用しました',
        employee_fired = '%sを解雇しました',
        fired_from_job = '%sから解雇されました'
    }
}

return Config