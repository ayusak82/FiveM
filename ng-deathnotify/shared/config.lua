Config = {}

-- 特定jobのテレポート設定
Config.TeleportJobs = {
    ['police'] = {
        coords = vector4(321.1, -584.17, 43.28, 79.25), -- Mission Row病院
        label = '病院'
    },
}

-- キー長押し時間（ミリ秒）
Config.HoldTime = 3000 -- 3秒

-- 通知設定
Config.Notifications = {
    -- 一般プレイヤーがGキーを押した時の通知
    ambulanceCall = {
        title = '医療要請',
        message = '市民が医療支援を要請しています',
        code = '10-69',
        icon = 'fas fa-face-dizzy'
    },
    -- 一般プレイヤーがHキーを押した時の通知
    doctorCall = {
        title = '個人医要請',
        message = '市民が個人医の支援を要請しています',
        code = '10-69',
        icon = 'fas fa-user-md'
    },
    -- 特定jobがFキーを押した時の通知
    jobTeleport = {
        title = '緊急医療搬送',
        message = '公務員が医療施設に搬送されました',
        code = '10-99',
        icon = 'fas fa-skull'
    }
}

-- ps-dispatch設定
Config.DispatchCodes = {
    --ambulanceCall = 'civdown',
    --doctorCall = 'docrequest',
    jobTeleport = 'officerdown'
}

-- 通知を受け取るjob（参考用）
Config.MedicalJobs = {
    'ambulance',
    -- 'doctor',  -- コメントアウト
    'ems'  -- ps-dispatchでよく使われるjob名
}

-- デバッグモード
Config.Debug = false