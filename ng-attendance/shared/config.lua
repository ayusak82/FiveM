Config = {}

-- 基本設定
Config.Debug = false -- デバッグモード
Config.UpdateInterval = 10000 -- 勤務状況更新間隔（ミリ秒）
Config.SaveInterval = 60000 -- データベース保存間隔（ミリ秒）

-- UI設定
Config.UIKey = 'F5' -- UI表示キー

-- ジョブ設定
Config.Jobs = {
    ['admin'] = {
        label = '運営',
        minGrade = 0
    },
    ['police'] = {
        label = '警察',
        minGrade = 0 -- 最低必要グレード
    },
    ['ambulance'] = {
        label = '救急',
        minGrade = 0
    },
    ['mechanic'] = {
        label = 'メカニック',
        minGrade = 0
    },
    ['taxi'] = {
        label = 'タクシー',
        minGrade = 0
    },
    ['realestate'] = {
        label = '不動産',
        minGrade = 0
    },
    ['cardealer'] = {
        label = '車両販売',
        minGrade = 0
    },
    -- 必要に応じて追加してください
}

-- 勤務計測設定
Config.WorkTracking = {
    enableAutoTracking = true, -- 自動勤務追跡
    requireOnDuty = true, -- 勤務中のみ追跡
    trackOfflineTime = false, -- オフライン時間も追跡するか
    minSessionTime = 60, -- 最小セッション時間（秒）
    maxDailyHours = 24 -- 1日の最大勤務時間
}

-- データベース設定
Config.Database = {
    attendanceTable = 'ng_attendance_records',
    sessionsTable = 'ng_attendance_sessions'
}

-- 通知設定
Config.Notifications = {
    workStart = true, -- 勤務開始通知
    workEnd = true, -- 勤務終了通知
    autoSave = false -- 自動保存通知
}

-- 言語設定
Config.Locale = 'ja'

Config.Text = {
    ['ja'] = {
        ['ui_title'] = '出退勤管理システム',
        ['work_status'] = '勤務状況',
        ['management'] = '管理画面',
        ['work_start'] = '勤務を開始しました',
        ['work_end'] = '勤務を終了しました',
        ['no_permission'] = '権限がありません',
        ['not_on_duty'] = '勤務中ではありません',
        ['already_working'] = 'すでに勤務中です',
        ['data_saved'] = 'データが保存されました',
        ['error_occurred'] = 'エラーが発生しました',
        ['employee_not_found'] = '従業員が見つかりません',
        ['invalid_date'] = '無効な日付です'
    }
}

Config.MonthsToShow = 3 -- 過去3ヶ月分を表示

-- ヘルパー関数（サーバーサイドやクライアントサイドの関数は削除）
function Config.GetText(key)
    local locale = Config.Locale or 'ja'
    if Config.Text[locale] and Config.Text[locale][key] then
        return Config.Text[locale][key]
    end
    return key
end

function Config.IsJobEnabled(jobName)
    return Config.Jobs[jobName] ~= nil
end

function Config.GetJobLabel(jobName)
    if Config.Jobs[jobName] then
        return Config.Jobs[jobName].label
    end
    return jobName
end