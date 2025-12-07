Config = {}

-- デバッグモード
Config.Debug = false

-- お知らせ表示時間（ミリ秒）
Config.DisplayDuration = 15000

-- お知らせコマンド
Config.Command = 'announce'

-- クールダウン時間（秒）- 同じ人が連続で投稿できないように
Config.Cooldown = 30

-- 最大文字数
Config.MaxLength = 500

-- お知らせを出せる職業リスト
-- ここに記載された職業のみがお知らせを出せる
Config.AllowedJobs = {
    'police',
    'ambulance',
    'admin',
    -- 以下に許可する職業を追加
    -- 'jobname',
}

-- 職業設定
-- color: 表示色（HEX）
-- icon: FontAwesome アイコンクラス
-- label: 表示名
Config.Jobs = {
    ['admin'] = {
        color = '#e84393',
        icon = 'fa-solid fa-user-shield',
        label = '管理者'
    },
    ['police'] = {
        color = '#3498db',
        icon = 'fa-solid fa-shield-halved',
        label = '警察'
    },
    ['ambulance'] = {
        color = '#e74c3c',
        icon = 'fa-solid fa-truck-medical',
        label = '救急'
    },
    -- 以下に職業を追加可能
    -- ['jobname'] = {
    --     color = '#HEXCOLOR',
    --     icon = 'fa-solid fa-icon-name',
    --     label = '表示名'
    -- },
}

-- デフォルト設定（職業が設定にない場合）
Config.DefaultJob = {
    color = '#95a5a6',
    icon = 'fa-solid fa-bullhorn',
    label = '一般'
}

-- qb-radialmenu用の設定
Config.RadialMenu = {
    id = 'announcement',
    title = 'お知らせ',
    icon = 'bullhorn',
    type = 'client',
    event = 'ng-announcement:client:openUI',
    shouldClose = true
}
