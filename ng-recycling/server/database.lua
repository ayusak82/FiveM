-- データベーステーブル作成
CreateThread(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `recycling_levels` (
            `citizenid` VARCHAR(50) NOT NULL,
            `level` INT(11) NOT NULL DEFAULT 1,
            `experience` INT(11) NOT NULL DEFAULT 0,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    print('^2[ng-recycling]^7 データベーステーブルを確認しました')
end)

-- プレイヤーのレベルデータを取得
function GetPlayerRecyclingData(citizenid)
    local result = MySQL.Sync.fetchAll('SELECT * FROM recycling_levels WHERE citizenid = ?', {citizenid})
    
    if result and result[1] then
        return result[1]
    else
        -- データがない場合は初期データを作成
        MySQL.Sync.execute('INSERT INTO recycling_levels (citizenid, level, experience) VALUES (?, ?, ?)', 
            {citizenid, 1, 0})
        return {citizenid = citizenid, level = 1, experience = 0}
    end
end

-- プレイヤーの経験値を更新
function UpdatePlayerExperience(citizenid, experience, level)
    MySQL.Sync.execute('UPDATE recycling_levels SET experience = ?, level = ? WHERE citizenid = ?', 
        {experience, level, citizenid})
end

-- レベルアップに必要な経験値を計算（レベルが上がるほど必要経験値が増える）
function GetRequiredExperience(level)
    -- レベル1: 100 XP
    -- レベル50: 5000 XP
    -- 段階的に増加
    return math.floor(100 + (level - 1) * 100)
end

-- レベルによる採取量ボーナスを計算（1.0倍 ~ 2.0倍）
function GetCollectionBonus(level)
    -- レベル1: 1.0倍
    -- レベル50: 2.0倍
    local bonus = 1.0 + (level - 1) * 0.02
    return math.min(bonus, 2.0) -- 最大2.0倍
end

-- レベルによる取得速度ボーナスを計算（時間短縮、0%～50%短縮）
function GetSpeedBonus(level)
    -- レベル1: 0%短縮
    -- レベル50: 50%短縮
    local reduction = (level - 1) * 0.01
    return math.min(reduction, 0.5) -- 最大50%短縮
end
