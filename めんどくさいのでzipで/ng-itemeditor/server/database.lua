Database = {}

-- テーブル作成用のSQL
local createTableSQL = [[
CREATE TABLE IF NOT EXISTS `]]..Config.DatabaseTable..[[` (
    `item_name` varchar(100) NOT NULL,
    `config` longtext NOT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`item_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
]]

-- 初期化関数
Database.Init = function()
    return MySQL.query(createTableSQL)
end

-- アイテム設定の取得
Database.GetItemConfig = function(itemName)
    local result = MySQL.single.await('SELECT config FROM ?? WHERE item_name = ?', {
        Config.DatabaseTable,
        itemName
    })
    
    if result then
        local success, config = pcall(json.decode, result.config)
        if success then
            return config
        end
    end
    
    return nil
end

-- 全アイテム設定の取得
Database.GetAllConfigs = function()
    local results = MySQL.query.await('SELECT item_name, config FROM ??', {
        Config.DatabaseTable
    })
    
    local configs = {}
    for _, row in ipairs(results) do
        local success, config = pcall(json.decode, row.config)
        if success then
            configs[row.item_name] = config
        end
    end
    
    return configs
end

-- アイテム設定の保存
Database.SaveItemConfig = function(itemName, config)
    -- 設定の検証
    local isValid, error = Utils.ValidateConfig(config)
    if not isValid then
        return false, error
    end
    
    -- デフォルト値の削除
    local cleanConfig = Utils.RemoveDefaults(config)
    
    -- JSON文字列に変換
    local configJson = json.encode(cleanConfig)
    
    -- データベースに保存
    local success = MySQL.update.await('INSERT INTO ?? (item_name, config) VALUES (?, ?) ON DUPLICATE KEY UPDATE config = ?', {
        Config.DatabaseTable,
        itemName,
        configJson,
        configJson
    })
    
    return success ~= 0, success == 0 and 'Failed to save config' or nil
end

-- アイテム設定の削除
Database.DeleteItemConfig = function(itemName)
    local success = MySQL.update.await('DELETE FROM ?? WHERE item_name = ?', {
        Config.DatabaseTable,
        itemName
    })
    
    return success ~= 0, success == 0 and 'Failed to delete config' or nil
end

-- リソース起動時にテーブルを作成
CreateThread(function()
    Database.Init()
end)