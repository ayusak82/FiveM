-- SQL保存のための初期化部分を追加
local QBCore = exports['qb-core']:GetCoreObject() -- QBCoreを使用する場合

-- サーバーサイドのリングトーン処理
local activeRingtones = {}

-- テーブル作成（サーバー起動時に実行）
CreateThread(function()
    -- リングトーン用テーブル
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `ng_ringtone` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(50) NOT NULL,
            `name` varchar(50) NOT NULL,
            `url` varchar(255) NOT NULL,
            `is_default` tinyint(1) NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`)
        )
    ]])
    
    -- 設定用テーブル
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `ng_ringtone_settings` (
            `identifier` varchar(50) NOT NULL,
            `is_muted` tinyint(1) NOT NULL DEFAULT 0,
            `volume_self` float NOT NULL DEFAULT 1.0,
            `volume_others` float NOT NULL DEFAULT 0.7,
            PRIMARY KEY (`identifier`)
        )
    ]])
end)

-- プレイヤーの設定を取得または作成する関数
local function GetOrCreateSettings(identifier, callback)
    -- identifierがnilまたは空の場合は処理を中止
    if not identifier or identifier == "" then
        print("ERROR: GetOrCreateSettings - 無効な識別子:", identifier)
        callback({
            identifier = "unknown",
            is_muted = 0,
            volume_self = 1.0,
            volume_others = 0.7
        })
        return
    end
    
    exports.oxmysql:execute('SELECT * FROM ng_ringtone_settings WHERE identifier = ?', {
        identifier
    }, function(result)
        if result and #result > 0 then
            -- 既存の設定を返す
            callback(result[1])
        else
            -- 設定が存在しない場合はデフォルト値で作成
            exports.oxmysql:insert('INSERT INTO ng_ringtone_settings (identifier, is_muted, volume_self, volume_others) VALUES (?, 0, 1.0, 0.7)', {
                identifier
            }, function()
                -- 作成後に再取得
                exports.oxmysql:execute('SELECT * FROM ng_ringtone_settings WHERE identifier = ?', {
                    identifier
                }, function(newResult)
                    if newResult and #newResult > 0 then
                        callback(newResult[1])
                    else
                        -- 何らかの理由で失敗した場合はデフォルト値を返す
                        callback({
                            identifier = identifier,
                            is_muted = 0,
                            volume_self = 1.0,
                            volume_others = 0.7
                        })
                    end
                end)
            end)
        end
    end)
end

-- リングトーン取得用関数を修正
RegisterNetEvent('ng-ringtone:server:getRingtones')
AddEventHandler('ng-ringtone:server:getRingtones', function()
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    
    -- identifierが取得できない場合はエラーを出して処理中止
    if not identifier or identifier == "" then
        print("ERROR: getRingtones - 無効な識別子:", identifier)
        -- 空のリストを返す
        TriggerClientEvent('ng-ringtone:client:receiveRingtones', src, {})
        return
    end
    
    ----print("プレイヤー " .. src .. " のリングトーン一覧を取得中...")
    
    -- まず設定を取得
    GetOrCreateSettings(identifier, function(settings)
        -- 次にリングトーンリストを取得
        exports.oxmysql:execute('SELECT id, identifier, name, url, CAST(is_default AS SIGNED) as is_default FROM ng_ringtone WHERE identifier = ?', {
            identifier
        }, function(result)
            local count = result and #result or 0
            ----print("プレイヤー " .. src .. " のリングトーン取得結果: " .. count .. "件")
            
            -- 設定情報をリングトーンに追加
            for i, item in ipairs(result) do
                -- 設定情報を各リングトーンに追加
                item.is_muted = settings.is_muted
                item.volume_self = settings.volume_self
                item.volume_others = settings.volume_others
                
                ----print("リングトーン #" .. i .. ": ID=" .. item.id .. ", 名前=" .. item.name .. 
                --      ", URL=" .. item.url .. ", デフォルト=" .. item.is_default)
            end
            
            TriggerClientEvent('ng-ringtone:client:receiveRingtones', src, result)
        end)
    end)
end)

-- 既存のデフォルトリングトーンをリセットする関数
local function resetDefaultRingtones(identifier, excludeId, callback)
    ----print("プレイヤー識別子 " .. identifier .. " のデフォルトリングトーンをリセット中（ID " .. tostring(excludeId) .. " を除く）")
    
    -- excludeId が nil の場合は 0 にして常にマッチしないようにする
    excludeId = excludeId or 0
    
    -- SQL文を改善：特定のIDを除外したデフォルト設定を解除
    local sql = 'UPDATE ng_ringtone SET is_default = 0 WHERE identifier = ? AND id != ?'
    
    exports.oxmysql:execute(sql, {
        identifier,
        excludeId
    }, function(result)
        --print("デフォルトリセット結果: " .. tostring(result and result.affectedRows or 0) .. "行を更新")
        if callback then callback() end
    end)
end

-- リングトーン保存用関数
RegisterNetEvent('ng-ringtone:server:saveRingtone')
AddEventHandler('ng-ringtone:server:saveRingtone', function(data)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    
    -- identifierが取得できない場合はエラーを出して処理中止
    if not identifier or identifier == "" then
        print("ERROR: saveRingtone - 無効な識別子:", identifier)
        TriggerClientEvent('ng-ringtone:client:saveSuccess', src, false)
        return
    end
    
    --print("着信音保存リクエスト: プレイヤー " .. src .. ", 名前=" .. data.name)
    
    -- NULL値を防ぐためにデフォルト値を設定
    local is_default = 0
    if data.is_default == 1 or data.is_default == true then
        is_default = 1
    end
    
    -- デフォルト設定の場合は、まず他のすべてをリセット
    if is_default == 1 then
        -- 新規作成時にはIDが不明なのでIDを0として処理
        resetDefaultRingtones(identifier, 0, function()
            -- リセット完了後に保存処理
            exports.oxmysql:insert('INSERT INTO ng_ringtone (identifier, name, url, is_default) VALUES (?, ?, ?, ?)', {
                identifier,
                data.name or "Unnamed Ringtone",
                data.url,
                is_default
            }, function(id)
                --print("着信音保存結果: ID=" .. tostring(id))
                
                if id > 0 then
                    -- 成功を通知
                    TriggerClientEvent('ng-ringtone:client:saveSuccess', src, true)
                    
                    -- 保存後に最新リストを取得して送信
                    TriggerEvent('ng-ringtone:server:getRingtones', src)
                else
                    TriggerClientEvent('ng-ringtone:client:saveSuccess', src, false)
                end
            end)
        end)
    else
        -- デフォルト設定でない場合は直接保存
        exports.oxmysql:insert('INSERT INTO ng_ringtone (identifier, name, url, is_default) VALUES (?, ?, ?, ?)', {
                identifier,
                data.name or "Unnamed Ringtone",
                data.url,
                is_default
            }, function(id)
                --print("着信音保存結果: ID=" .. tostring(id))
                
                if id > 0 then
                    -- 成功を通知
                    TriggerClientEvent('ng-ringtone:client:saveSuccess', src, true)
                    
                    -- 保存後に最新リストを取得して送信
                    TriggerEvent('ng-ringtone:server:getRingtones', src)
                else
                    TriggerClientEvent('ng-ringtone:client:saveSuccess', src, false)
                end
            end)
    end
end)

-- 更新関数内で適切に使用
RegisterNetEvent('ng-ringtone:server:updateRingtone')
AddEventHandler('ng-ringtone:server:updateRingtone', function(data)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    
    -- identifierが取得できない場合はエラーを出して処理中止
    if not identifier or identifier == "" then
        print("ERROR: updateRingtone - 無効な識別子:", identifier)
        TriggerClientEvent('ng-ringtone:client:updateSuccess', src, false)
        return
    end
    
    -- データをデバッグ出力
    if type(data) == "table" then
        --print("更新データ: " .. json.encode(data))
    else
        --print("更新データ: " .. tostring(data))
    end
    
    -- NULL値を防ぐためにデフォルト値を設定
    local is_default = 0
    if data.is_default == 1 or data.is_default == true then
        is_default = 1
    end
    
    local id = tonumber(data.id)
    
    if not id then
        --print("無効なID: " .. tostring(data.id))
        return
    end
    
    -- デバッグ出力
    --print(string.format("リングトーン更新実行: ID=%d, 名前=%s, デフォルト=%d", 
    --    id, data.name or "不明", is_default))
    
    -- デフォルト設定の場合は、まず他のすべてをリセット
    if is_default == 1 then
        resetDefaultRingtones(identifier, id, function()
            -- リセット完了後に更新処理
            exports.oxmysql:execute('UPDATE ng_ringtone SET name = ?, url = ?, is_default = ? WHERE id = ? AND identifier = ?', {
                data.name or "Unnamed Ringtone",
                data.url,
                is_default,
                id,
                identifier
            }, function(result)
                --print("更新結果: " .. json.encode(result))
                
                -- 成功を通知
                TriggerClientEvent('ng-ringtone:client:updateSuccess', src, true)
                
                -- 更新後に最新リストを送信
                TriggerEvent('ng-ringtone:server:getRingtones', src)
            end)
        end)
    else
        -- デフォルト設定でない場合は直接更新
        exports.oxmysql:execute('UPDATE ng_ringtone SET name = ?, url = ?, is_default = ? WHERE id = ? AND identifier = ?', {
                data.name or "Unnamed Ringtone",
                data.url,
                is_default,
                id,
                identifier
            }, function(result)
                --print("更新結果: " .. json.encode(result))
                
                -- 成功を通知
                TriggerClientEvent('ng-ringtone:client:updateSuccess', src, true)
                
                -- 更新後に最新リストを送信
                TriggerEvent('ng-ringtone:server:getRingtones', src)
            end)
    end
end)

-- リングトーン削除用関数
RegisterNetEvent('ng-ringtone:server:deleteRingtone')
AddEventHandler('ng-ringtone:server:deleteRingtone', function(id)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    
    -- identifierが取得できない場合はエラーを出して処理中止
    if not identifier or identifier == "" then
        print("ERROR: deleteRingtone - 無効な識別子:", identifier)
        TriggerClientEvent('ng-ringtone:client:deleteSuccess', src, false)
        return
    end
    
    --print("プレイヤー " .. src .. " がリングトーンID " .. id .. " を削除しようとしています")
    
    -- IDが数値であることを確認
    local idNum = tonumber(id)
    if not idNum then
        --print("無効なID: " .. tostring(id))
        TriggerClientEvent('ng-ringtone:client:deleteSuccess', src, false)
        return
    end
    
    -- 削除する前に、このリングトーンがデフォルトかどうかを確認
    exports.oxmysql:execute('SELECT is_default FROM ng_ringtone WHERE id = ? AND identifier = ?', {
        idNum,
        identifier
    }, function(result)
        local isDefault = result and result[1] and result[1].is_default == 1
        
        -- 削除を実行
        exports.oxmysql:execute('DELETE FROM ng_ringtone WHERE id = ? AND identifier = ?', {
            idNum,
            identifier
        }, function(result)
            local affectedRows = 0
            if type(result) == "table" and result.affectedRows then
                affectedRows = result.affectedRows
            end
            
            --print("削除結果: " .. affectedRows .. "行が影響を受けました")
            
            if affectedRows > 0 then
                TriggerClientEvent('ng-ringtone:client:deleteSuccess', src, true)
                
                -- 削除後に最新リストを取得して送信
                exports.oxmysql:execute('SELECT * FROM ng_ringtone WHERE identifier = ?', {
                    identifier
                }, function(updatedResult)
                    --print("更新されたリスト: " .. #updatedResult .. "件")
                    
                    -- デフォルトリングトーンが削除された場合、新しいデフォルトを設定
                    if isDefault and #updatedResult > 0 then
                        --print("デフォルトリングトーンが削除されました。新しいデフォルトを設定します。")
                        
                        -- 最初のリングトーンをデフォルトに設定
                        exports.oxmysql:execute('UPDATE ng_ringtone SET is_default = 1 WHERE id = ? AND identifier = ?', {
                            updatedResult[1].id,
                            identifier
                        }, function()
                            -- 更新後の最新リストを再取得
                            TriggerEvent('ng-ringtone:server:getRingtones', src)
                        end)
                    else
                        -- デフォルトが削除されていない場合は、そのままリストを送信
                        TriggerEvent('ng-ringtone:server:getRingtones', src)
                    end
                end)
            else
                TriggerClientEvent('ng-ringtone:client:deleteSuccess', src, false)
            end
        end)
    end)
end)

-- 既存の着信イベントハンドラを修正
AddEventHandler("lb-phone:newCall", function(call)
    --print("着信検知:", json.encode(call))
    
    -- 受信者のソースIDを取得
    local calleeSource = call.callee and call.callee.source or call.receiver
    
    if not calleeSource then
        --print("受信者のソースIDが見つかりません")
        return
    end
    
    --print("受信者のソースID:", calleeSource)
    
    -- ユーザーのリングトーン設定を取得してから再生するように変更
    local identifier = GetPlayerIdentifier(calleeSource, 0)
    --print("識別子:", identifier)
    
    -- identifierが取得できない場合は標準音を再生
    if not identifier or identifier == "" then
        print("ERROR: newCall - 無効な識別子:", identifier)
        -- デフォルトのリングトーンの再生をクライアントに指示
        TriggerClientEvent("ng-ringtone:client:playRingtone", calleeSource, {
            caller = call.caller_name or "不明な発信者",
            callId = call.callId or math.random(1000000, 9999999),
            ringtone = nil -- デフォルト（システム）音を使用
        })
        
        -- アクティブなリングトーンを記録
        activeRingtones[calleeSource] = true
        return
    end
    
    -- 設定とリングトーンを取得してから再生
    GetOrCreateSettings(identifier, function(settings)
        -- デフォルトリングトーンを取得
        exports.oxmysql:execute('SELECT id, name, url, is_default FROM ng_ringtone WHERE identifier = ? AND is_default = 1', {
            identifier
        }, function(results)
            -- リングトーンデータを構築
            local ringtoneData = nil
            if results and #results > 0 then
                ringtoneData = results[1]
                -- 設定情報を追加
                ringtoneData.is_muted = settings.is_muted
                ringtoneData.volume_self = settings.volume_self
                ringtoneData.volume_others = settings.volume_others
                
                --print("デフォルトリングトーン検出:", ringtoneData.name, ringtoneData.url)
            end
            
            -- リングトーンの再生をクライアントに指示（設定データも送信）
            TriggerClientEvent("ng-ringtone:client:playRingtone", calleeSource, {
                caller = call.caller_name or "不明な発信者",
                callId = call.callId or math.random(1000000, 9999999),
                ringtone = ringtoneData
            })
            
            -- アクティブなリングトーンを記録
            activeRingtones[calleeSource] = true
        end)
    end)
end)

-- サーバーサイドの通知改善に関する部分を修正
RegisterServerEvent("ng-ringtone:server:notifyNearbyPlayers")
AddEventHandler("ng-ringtone:server:notifyNearbyPlayers", function(coords, ringtoneUrl)
    local src = source
    --print("プレイヤー " .. src .. " の着信音を周囲に通知します")
    
    -- 全プレイヤーに音声再生を要求（各プレイヤーが自分の音量設定を使用）
    TriggerClientEvent("ng-ringtone:client:playNearbyRingtone", -1, src, coords, ringtoneUrl)
end)

-- デバッグログイベントを無効化
--[[
RegisterServerEvent("ng-ringtone:server:debugLog")
AddEventHandler("ng-ringtone:server:debugLog", function(message)
    local playerId = source
    local playerName = GetPlayerName(playerId)
    --print("^2[リングトーン変更 | " .. playerName .. " (" .. playerId .. ")] ^7" .. tostring(message))
end)
]]--

-- 周囲のプレイヤーの着信音を全て停止
RegisterServerEvent("ng-ringtone:server:stopAllNearbyRingtones")
AddEventHandler("ng-ringtone:server:stopAllNearbyRingtones", function(playerId)
    --print("プレイヤー " .. playerId .. " の着信音を全プレイヤーで停止します")
    -- 全プレイヤーに停止を通知
    TriggerClientEvent("ng-ringtone:client:stopNearbyRingtone", -1, playerId)
end)

-- 通話応答/終了イベント
AddEventHandler("lb-phone:callAnswered", function(call)
    --print("通話応答:", json.encode(call))
    
    -- 受信者を特定
    local calleeSource = call.callee and call.callee.source or call.receiver
    local callerSource = call.caller and call.caller.source
    
    -- 受信者側の着信音を停止
    if calleeSource and activeRingtones[calleeSource] then
        --print("受信者の着信音を停止:", calleeSource)
        TriggerClientEvent("ng-ringtone:client:stopRingtone", calleeSource)
        activeRingtones[calleeSource] = nil
    end
    
    -- 発信者側も念のため停止
    if callerSource then
        --print("発信者の着信音も停止:", callerSource)
        TriggerClientEvent("ng-ringtone:client:stopRingtone", callerSource)
        activeRingtones[callerSource] = nil
    end
    
    -- 全プレイヤーに停止を通知
    if calleeSource then
        TriggerClientEvent("ng-ringtone:client:stopNearbyRingtone", -1, calleeSource)
    end
    if callerSource then
        TriggerClientEvent("ng-ringtone:client:stopNearbyRingtone", -1, callerSource)
    end
end)

-- 通話終了イベント
AddEventHandler("lb-phone:callEnded", function(call)
    --print("通話終了:", json.encode(call))
    
    -- 受信者を特定
    local calleeSource = call.callee and call.callee.source or call.receiver
    local callerSource = call.caller and call.caller.source
    
    -- すべての関連プレイヤーの着信音を停止
    local playersToStop = {}
    if calleeSource then table.insert(playersToStop, calleeSource) end
    if callerSource then table.insert(playersToStop, callerSource) end
    
    for _, playerSource in ipairs(playersToStop) do
        if activeRingtones[playerSource] then
            --print("プレイヤーの着信音を停止:", playerSource)
            TriggerClientEvent("ng-ringtone:client:stopRingtone", playerSource)
            activeRingtones[playerSource] = nil
        end
        
        -- 周囲のプレイヤーにも停止を通知
        TriggerClientEvent("ng-ringtone:client:stopNearbyRingtone", -1, playerSource)
    end
end)

-- グローバル音量設定の保存
RegisterServerEvent("ng-ringtone:server:saveGlobalVolume")
AddEventHandler("ng-ringtone:server:saveGlobalVolume", function(data)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    
    -- identifierが取得できない場合はエラーを出して処理中止
    if not identifier or identifier == "" then
        print("ERROR: saveGlobalVolume - 無効な識別子:", identifier)
        return
    end
    
    if not data.volumeSelf or not data.volumeOthers then
        --print("無効な音量データ: " .. json.encode(data))
        return
    end
    
    --print("グローバル音量設定を保存: 自分=" .. data.volumeSelf .. ", 周囲=" .. data.volumeOthers)
    
    -- 設定テーブルに既存のレコードがあるか確認
    exports.oxmysql:execute('SELECT * FROM ng_ringtone_settings WHERE identifier = ?', {
        identifier
    }, function(result)
        if result and #result > 0 then
            -- 既存の設定を更新
            exports.oxmysql:execute('UPDATE ng_ringtone_settings SET volume_self = ?, volume_others = ? WHERE identifier = ?', {
                data.volumeSelf,
                data.volumeOthers,
                identifier
            }, function()
                --print("プレイヤー " .. src .. " の音量設定を更新しました")
                
                -- 設定が更新されたことをクライアントに通知
                TriggerClientEvent('ng-ringtone:client:receiveVolumeSettings', src, {
                    volumeSelf = data.volumeSelf,
                    volumeOthers = data.volumeOthers,
                    isMuted = result[1].is_muted == 1
                })
            end)
        else
            -- 設定が存在しない場合は新規作成
            exports.oxmysql:execute('INSERT INTO ng_ringtone_settings (identifier, volume_self, volume_others, is_muted) VALUES (?, ?, ?, 0)', {
                identifier,
                data.volumeSelf,
                data.volumeOthers
            }, function()
                --print("プレイヤー " .. src .. " の音量設定を新規作成しました")
                
                -- 設定が作成されたことをクライアントに通知
                TriggerClientEvent('ng-ringtone:client:receiveVolumeSettings', src, {
                    volumeSelf = data.volumeSelf,
                    volumeOthers = data.volumeOthers,
                    isMuted = false
                })
            end)
        end
    end)
end)

-- ミュート設定の更新
RegisterServerEvent("ng-ringtone:server:toggleMute")
AddEventHandler("ng-ringtone:server:toggleMute", function(isMuted)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    
    -- identifierが取得できない場合はエラーを出して処理中止
    if not identifier or identifier == "" then
        print("ERROR: toggleMute - 無効な識別子:", identifier)
        return
    end
    
    -- ミュート状態を数値に変換
    local mutedValue = isMuted and 1 or 0
    
    print("^2[リングトーン] プレイヤー " .. src .. " のミュート設定を保存: " .. mutedValue .. "^7")
    
    -- 設定を更新または作成
    exports.oxmysql:execute('INSERT INTO ng_ringtone_settings (identifier, is_muted) VALUES (?, ?) ON DUPLICATE KEY UPDATE is_muted = VALUES(is_muted)', {
        identifier,
        mutedValue
    }, function()
        print("^2[リングトーン] プレイヤー " .. src .. " のミュート設定を更新完了: " .. mutedValue .. "^7")
    end)
end)

-- 起動時にクライアントへ音量設定を送信するイベント
RegisterNetEvent('ng-ringtone:server:requestVolumeSettings')
AddEventHandler('ng-ringtone:server:requestVolumeSettings', function()
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    
    -- identifierが取得できない場合はエラーを出して処理中止
    if not identifier or identifier == "" then
        print("ERROR: requestVolumeSettings - 無効な識別子:", identifier)
        -- デフォルト設定をクライアントに送信
        TriggerClientEvent('ng-ringtone:client:receiveVolumeSettings', src, {
            volumeSelf = 1.0,
            volumeOthers = 0.7,
            isMuted = false
        })
        return
    end
    
    -- 設定を取得または作成
    GetOrCreateSettings(identifier, function(settings)
        -- 設定をクライアントに送信
        TriggerClientEvent('ng-ringtone:client:receiveVolumeSettings', src, {
            volumeSelf = settings.volume_self,
            volumeOthers = settings.volume_others,
            isMuted = settings.is_muted == 1
        })
    end)
end)

-- 強制停止用の新しいイベント
RegisterServerEvent("ng-ringtone:server:forceStopAllRingtones")
AddEventHandler("ng-ringtone:server:forceStopAllRingtones", function(playerId)
    local src = source
    --print("強制停止リクエスト from", src, "for", playerId or "all")
    
    if playerId then
        -- 特定プレイヤーの着信音を停止
        TriggerClientEvent("ng-ringtone:client:stopRingtone", playerId)
        activeRingtones[playerId] = nil
        TriggerClientEvent("ng-ringtone:client:stopNearbyRingtone", -1, playerId)
    else
        -- 自分自身の着信音を停止
        TriggerClientEvent("ng-ringtone:client:stopRingtone", src)
        activeRingtones[src] = nil
        TriggerClientEvent("ng-ringtone:client:stopNearbyRingtone", -1, src)
    end
end)