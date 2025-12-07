Config = {}
Config.TargetSystem = 'qb-target' -- Options: 'ox_target', 'qb-target'

-- スタッシュを作成できるジョブの設定
Config.AllowedJobs = {
    ['police'] = {
        minGrade = 2,        -- 必要な最小グレード
        maxStashes = 3,      -- 作成可能な最大スタッシュ数
        label = '警察保管庫'  -- メニューに表示される名前
    },
    ['ambulance'] = {
        minGrade = 2,
        maxStashes = 2,
        label = '医療保管庫'
    },
    ['mechanic'] = {
        minGrade = 1,
        maxStashes = 2,
        label = '整備士保管庫'
    }
}

-- スタッシュのタイプ設定
Config.StashTypes = {
    ['small'] = {
        label = '小型保管庫',
        slots = 15,      -- インベントリのスロット数
        weight = 50000   -- 重量制限 (グラム)
    },
    ['medium'] = {
        label = '中型保管庫',
        slots = 30,
        weight = 100000
    },
    ['large'] = {
        label = '大型保管庫',
        slots = 50,
        weight = 200000
    }
}

-- ox_libメニューの設定
Config.MenuPosition = 'bottom-right' -- メニューの表示位置