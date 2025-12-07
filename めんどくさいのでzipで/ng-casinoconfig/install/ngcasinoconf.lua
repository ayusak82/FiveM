-- rcore_casinoのserver側のファイル（例えばserver/main.lua）に追加するコード

-- configとconstを更新するexport関数
exports('UpdateConfig', function(configContent, constContent)
    local success = true
    
    -- バックアップディレクトリの確認と作成
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    local backupDir = resourcePath .. '/backups'
    
    -- バックアップディレクトリが存在しない場合は作成
    if not os.rename(backupDir, backupDir) then
        os.execute('mkdir "' .. backupDir .. '"')
    end
    
    -- タイムスタンプ
    local timestamp = os.date("%Y%m%d_%H%M%S")
    
    -- configの内容を更新
    if configContent then
        -- 既存ファイルのバックアップ
        local configPath = resourcePath .. '/config.lua'
        local backupPath = backupDir .. '/config_' .. timestamp .. '.bak'
        
        -- バックアップのためにファイルをコピー
        local origFile = io.open(configPath, 'r')
        if origFile then
            local content = origFile:read("*all")
            origFile:close()
            
            local backupFile = io.open(backupPath, 'w')
            if backupFile then
                backupFile:write(content)
                backupFile:close()
            end
        end
        
        -- 古いファイルを削除
        os.remove(configPath)
        
        -- 新しいファイルを作成
        local newFile = io.open(configPath, 'w')
        if newFile then
            newFile:write(configContent)
            newFile:close()
        else
            success = false
            print("Failed to create new config file")
        end
    end
    
    -- constの内容を更新（もし提供されている場合）
    if constContent and success then
        -- 既存ファイルのバックアップ
        local constPath = resourcePath .. '/const.lua'
        local backupPath = backupDir .. '/const_' .. timestamp .. '.bak'
        
        -- バックアップのためにファイルをコピー
        local origFile = io.open(constPath, 'r')
        if origFile then
            local content = origFile:read("*all")
            origFile:close()
            
            local backupFile = io.open(backupPath, 'w')
            if backupFile then
                backupFile:write(content)
                backupFile:close()
            end
        end
        
        -- 古いファイルを削除
        os.remove(constPath)
        
        -- 新しいファイルを作成
        local newFile = io.open(constPath, 'w')
        if newFile then
            newFile:write(constContent)
            newFile:close()
        else
            success = false
            print("Failed to create new const file")
        end
    end
    
    -- カジノ設定を再読み込み
    if success and Config and type(Config.ReloadSettings) == 'function' then
        Config.ReloadSettings()
    end
    
    return success
end)