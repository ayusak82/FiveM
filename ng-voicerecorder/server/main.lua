local QBCore = exports['qb-core']:GetCoreObject()

-- リソースの絶対パスを取得
local resourcePath = GetResourcePath(GetCurrentResourceName()) or ""
-- 正規化: バックスラッシュを / にし、重複する / を潰し、末尾の / を取り除く
resourcePath = string.gsub(resourcePath, "\\", "/")
resourcePath = string.gsub(resourcePath, "/+", "/")
resourcePath = string.gsub(resourcePath, "/+$", "")

local recordingsFolder = (Config and Config.RecordingsFolder) or "recordings"
local recordingsPath = resourcePath .. "/" .. recordingsFolder
recordingsPath = string.gsub(recordingsPath, "\\", "/")  -- Windowsパス用の\を/に変換
recordingsPath = string.gsub(recordingsPath, "/+", "/")
recordingsPath = string.gsub(recordingsPath, "/+$", "")

-- ========================
-- プラットフォームヘルパー
-- ========================

local function EnsureDirectory(dir)
    if not dir or dir == '' then return end
    -- 正規化（/ を使用）
    local d = string.gsub(dir, "\\", "/")
    -- Linux/Unix環境のみサポート
    os.execute('mkdir -p "' .. d .. '"')
end

local function SafeRemoveFile(path)
    if not path or path == '' then return false end
    -- URL の場合は削除しない
    if string.match(path, '^https?://') then return false end
    local ok, err = pcall(function()
        -- io.remove は環境依存だが os.remove を試す
        os.remove(path)
    end)
    return ok
end

-- ========================
-- ユーティリティ関数
-- ========================

local function DebugPrint(message, level)
    if Config.Debug and (level or 1) <= Config.DebugLevel then
        print("[ng-voicerecorder] " .. message)
    end
end

local function CreateRecordingsFolder()
    -- 録音フォルダの作成
    DebugPrint("録音フォルダを作成: " .. recordingsPath)
    
    -- ディレクトリが存在しない場合は作成
    local ok = pcall(function() EnsureDirectory(recordingsPath) end)
    if ok then
        DebugPrint("録音フォルダ作成成功: " .. recordingsPath)
    else
        DebugPrint("録音フォルダ作成失敗: " .. recordingsPath)
    end
end

local function GenerateSystemId()
    local timestamp = os.time()
    local random = math.random(10000, 99999)
    return timestamp .. "_" .. random
end

-- プレイヤーのアイテム取得（qb-core用）
function GetPlayerItems(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        return Player.PlayerData.items or {}
    end
    return {}
end

-- MIME Typeから拡張子を取得
function GetExtensionFromMimeType(mimeType)
    local extensions = {
        ["audio/webm"] = ".weba",
        ["audio/webm;codecs=opus"] = ".opus",
        ["audio/opus"] = ".opus",
        ["audio/mp4"] = ".mp4",
        ["audio/mpeg"] = ".mp3",
        ["audio/wav"] = ".wav",
        ["audio/ogg"] = ".ogg"
    }
    
    return extensions[mimeType] or ".opus"
end

local function HasItem(src, itemName)
    -- ox_inventoryの場合
    if GetResourceState('ox_inventory') == 'started' then
        -- ox_inventory のエクスポート呼び出しが失敗すると全体がクラッシュするため pcall で保護
        local ok, count = pcall(function()
            return exports.ox_inventory:GetItem(src, itemName, nil, true)
        end)
        if not ok then
            DebugPrint("ox_inventory:GetItem の呼び出しでエラー発生: " .. tostring(count))
            return false
        end
        return count and count > 0
    end
    
    -- qb-core標準の場合
    local items = GetPlayerItems(src)
    for _, item in pairs(items) do
        if item and item.name == itemName and item.amount and item.amount > 0 then
            return true, item
        end
    end
    return false
end

local function RemoveItem(src, itemName, amount)
    -- ox_inventoryの場合
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:RemoveItem(src, itemName, amount or 1)
    end
    
    -- qb-core標準の場合
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        return Player.Functions.RemoveItem(itemName, amount or 1)
    end
    return false
end

local function AddItem(src, itemName, amount, info)
    -- ox_inventoryの場合
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:AddItem(src, itemName, amount or 1, info)
    end
    
    -- qb-core標準の場合
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        return Player.Functions.AddItem(itemName, amount or 1, false, info)
    end
    return false
end

-- ========================
-- アイテム使用可能アイテム登録
-- ========================

-- qb-core用のuseableアイテム（互換性のため）
if QBCore.Functions.CreateUseableItem then
    QBCore.Functions.CreateUseableItem(Config.Items.VoiceRecorder, function(source, item)
        local src = source
        DebugPrint("ボイスレコーダー使用 (qb-core): Player " .. src)
        TriggerClientEvent('ng-voicerecorder:useVoiceRecorder', src)
    end)
    
    -- 録音済みテープのuseableアイテム登録
    QBCore.Functions.CreateUseableItem(Config.Items.RecordedTape, function(source, item)
        local src = source
        DebugPrint("録音済みテープ使用 (qb-core): Player " .. src)
        
        local tapeInfo = item.info or {}
        local systemId = tapeInfo.systemId
        local tapeName = tapeInfo.displayName or "録音テープ"
        
        if systemId then
            DebugPrint("テープ再生開始: " .. tapeName .. " (ID: " .. systemId .. ")")
            local playerCoords = GetEntityCoords(GetPlayerPed(src))
            TriggerEvent('ng-voicerecorder:playAudio', systemId, playerCoords)
        else
            DebugPrint("エラー: テープのシステムIDが見つかりません")
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'ボイスレコーダー',
                description = 'テープのデータが破損しています',
                type = 'error'
            })
        end
    end)
end

-- ox_inventory用のアイテム使用イベント
RegisterNetEvent('ng-voicerecorder:useItem', function(item, slot)
    local src = source
    DebugPrint("アイテム使用 (ox_inventory): Player " .. src .. ", Item: " .. tostring(item))
    
    if item == Config.Items.VoiceRecorder then
        TriggerClientEvent('ng-voicerecorder:useVoiceRecorder', src)
    elseif item == Config.Items.RecordedTape then
        -- ox_inventoryから詳細なアイテム情報を取得
        local itemData = exports.ox_inventory:GetSlot(src, slot)
        if itemData and itemData.metadata then
            local tapeInfo = itemData.metadata
            local systemId = tapeInfo.systemId
            local tapeName = tapeInfo.displayName or "録音テープ"
            
            if systemId then
                DebugPrint("テープ再生開始: " .. tapeName .. " (ID: " .. systemId .. ")")
                local playerCoords = GetEntityCoords(GetPlayerPed(src))
                TriggerEvent('ng-voicerecorder:playAudio', systemId, playerCoords)
            else
                DebugPrint("エラー: テープのシステムIDが見つかりません")
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'ボイスレコーダー',
                    description = 'テープのデータが破損しています',
                    type = 'error'
                })
            end
        else
            DebugPrint("エラー: テープのメタデータが見つかりません")
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'ボイスレコーダー',
                description = 'テープのデータが破損しています',
                type = 'error'
            })
        end
    end
end)

-- ========================
-- 録音関連イベント
-- ========================

-- 全てのイベントをキャッチするデバッグ用
AddEventHandler('ng-voicerecorder:saveRecording', function(data)
    local src = source
    DebugPrint("!!! イベントハンドラー呼び出し確認 !!!")
    DebugPrint("Source: " .. tostring(src))
    DebugPrint("Data type: " .. type(data))
end)

-- NUIからのsaveRecordingリクエストを処理
RegisterNetEvent('ng-voicerecorder:saveRecording', function(data)
    local src = source
    DebugPrint("=== 録音保存イベント受信 ===")
    DebugPrint("Player: " .. src)
    DebugPrint("受信データタイプ: " .. type(data))
    
    if not data then
        DebugPrint("エラー: データがnilです")
        TriggerClientEvent('ng-voicerecorder:recordingComplete', src, false, "データが受信されませんでした")
        return
    end
    
    if type(data) == "table" then
        DebugPrint("データ構造: テーブル")
        for k, v in pairs(data) do
            if k == "audioData" then
                DebugPrint("- " .. k .. ": " .. type(v) .. " (長さ: " .. tostring(string.len(v or "")) .. ")")
            else
                DebugPrint("- " .. k .. ": " .. tostring(v))
            end
        end
    else
        DebugPrint("データ構造: " .. type(data))
        DebugPrint("データ内容: " .. tostring(data))
        TriggerClientEvent('ng-voicerecorder:recordingComplete', src, false, "データ形式が不正です")
        return
    end
    
    -- データの取得
    local tapeName = data.tapeName
    local audioData = data.audioData  
    local mimeType = data.mimeType
    local audioSize = data.size
    
    DebugPrint("=== 抽出されたデータ ===")
    DebugPrint("テープ名: " .. tostring(tapeName))
    DebugPrint("MIME Type: " .. tostring(mimeType))
    DebugPrint("音声サイズ: " .. tostring(audioSize) .. " bytes")
    DebugPrint("Base64データ長: " .. tostring(string.len(audioData or "")))
    
    -- アイテムチェック
    DebugPrint("=== アイテムチェック開始 ===")
    local hasVoiceRecorder = HasItem(src, Config.Items.VoiceRecorder)
    local hasEmptyTape = HasItem(src, Config.Items.EmptyTape)
    
    DebugPrint("ボイスレコーダー所持: " .. tostring(hasVoiceRecorder))
    DebugPrint("空のテープ所持: " .. tostring(hasEmptyTape))
    
    if not hasVoiceRecorder then
        DebugPrint("エラー: ボイスレコーダーを持っていません")
        TriggerClientEvent('ng-voicerecorder:recordingComplete', src, false, "ボイスレコーダーを持っていません")
        return
    end
    
    if not hasEmptyTape then
        DebugPrint("エラー: 空のテープを持っていません")
        TriggerClientEvent('ng-voicerecorder:recordingComplete', src, false, "空のテープを持っていません")
        return
    end
    
    -- 音声データの検証
    if not audioData or audioData == "" then
        DebugPrint("エラー: 音声データが空です")
        TriggerClientEvent('ng-voicerecorder:recordingComplete', src, false, "録音データが取得できませんでした")
        return
    end
    
    DebugPrint("=== ファイル保存準備 ===")
    -- システムID生成
    local systemId = GenerateSystemId()
    local fileExtension = GetExtensionFromMimeType(mimeType or "audio/opus")
    local fileName = systemId .. fileExtension
    
    -- より確実なパス生成
    local filePath = recordingsPath .. "/" .. fileName
    -- Windows環境対応のため、バックスラッシュもチェック
    filePath = string.gsub(filePath, "\\", "/")
    -- 重複するスラッシュや末尾スラッシュを潰す
    filePath = string.gsub(filePath, "/+", "/")
    filePath = string.gsub(filePath, "/+$", "")
    
    DebugPrint("システムID: " .. systemId)
    DebugPrint("ファイル名: " .. fileName)
    DebugPrint("recordingsPath: " .. recordingsPath)
    DebugPrint("ファイルパス: " .. filePath)
    
    -- メタデータ作成
    local metadata = {
        systemId = systemId,
        displayName = tapeName or "録音テープ",
        recordedAt = os.date("%Y-%m-%d %H:%M:%S"),
        filePath = filePath,
        duration = Config.RecordingTime,
        recordedBy = src,
        mimeType = mimeType or "audio/opus",
        size = audioSize or 0,
        -- アイテム説明用の情報
        description = "録音内容: " .. (tapeName or "無題"),
        info = {
            displayName = tapeName or "録音テープ",
            recordedDate = os.date("%Y/%m/%d %H:%M"),
            duration = Config.RecordingTime .. "秒"
        }
    }
    
    DebugPrint("=== ファイル保存実行 ===")
    -- 録音ファイル保存処理 (SaveRecordingFile が (success, storedPath) を返す)
    local saveSuccess, storedPath = SaveRecordingFile(audioData, filePath, mimeType, src)
    DebugPrint("ファイル保存結果: " .. tostring(saveSuccess))
    
    if saveSuccess then
        -- 保存先パス/URL をメタデータに反映
        if storedPath and storedPath ~= "" then
            metadata.filePath = storedPath
        else
            metadata.filePath = filePath
        end
        DebugPrint("=== アイテム処理開始 ===")
        
        -- 空のテープを削除
        local removeSuccess = RemoveItem(src, Config.Items.EmptyTape, 1)
        DebugPrint("空のテープ削除結果: " .. tostring(removeSuccess))
        
        -- 録音済みテープを追加
        local addSuccess = AddItem(src, Config.Items.RecordedTape, 1, metadata)
        DebugPrint("録音済みテープ追加結果: " .. tostring(addSuccess))
        
        if removeSuccess and addSuccess then
            DebugPrint("=== データベース保存開始 ===")
            -- データベースに保存
            MySQL.insert('INSERT INTO ng_voicerecorder_recordings (system_id, player_id, display_name, file_path, recorded_at, duration, mime_type, file_size) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
                systemId,
                src,
                metadata.displayName,
                metadata.filePath,
                metadata.recordedAt,
                metadata.duration,
                metadata.mimeType,
                metadata.size
            }, function(insertId)
                if insertId then
                    DebugPrint("データベース保存成功: INSERT ID " .. insertId)
                    TriggerClientEvent('ng-voicerecorder:recordingComplete', src, true, "録音が完了しました")
                else
                    DebugPrint("データベース保存失敗")
                    TriggerClientEvent('ng-voicerecorder:recordingComplete', src, false, "データベース保存に失敗しました")
                end
            end)
            
            DebugPrint("=== 録音処理完了 ===")
        else
            DebugPrint("アイテム操作失敗")
            TriggerClientEvent('ng-voicerecorder:recordingComplete', src, false, "アイテム処理に失敗しました")
        end
    else
        DebugPrint("録音保存失敗")
        TriggerClientEvent('ng-voicerecorder:recordingComplete', src, false, "録音の保存に失敗しました")
    end
end)

-- ========================
-- 再生関連イベント
-- ========================

RegisterNetEvent('ng-voicerecorder:playAudio', function(systemId, sourceCoords)
    local src = source
    DebugPrint("音声再生リクエスト: " .. systemId .. " by Player " .. src)
    
    -- デバッグモード用の処理
    if systemId == "debug_tape" and Config.EnableDebugCommands then
        DebugPrint("デバッグモード: 音声再生シミュレーション")
        
        -- 範囲内の全プレイヤーに再生イベント送信
        local players = QBCore.Functions.GetPlayers()
        for _, playerId in pairs(players) do
            local targetCoords = GetEntityCoords(GetPlayerPed(playerId))
            local distance = #(vector3(sourceCoords.x, sourceCoords.y, sourceCoords.z) - targetCoords)
            
            if distance <= Config.PlaybackRange then
                TriggerClientEvent('ng-voicerecorder:playAudioClient', playerId, "debug_audio_data", sourceCoords, Config.PlaybackRange)
            end
        end
        return
    end
    
    -- データベースから録音データを取得
    MySQL.query('SELECT * FROM ng_voicerecorder_recordings WHERE system_id = ?', {systemId}, function(result)
        if result and result[1] then
            local recording = result[1]
            
            -- ファイル存在チェック / URLかローカルかを判定
            local audioData = nil
            if type(recording.file_path) == 'string' and string.match(recording.file_path, '^https?://') then
                -- 外部URLとしてそのままクライアントに渡す
                audioData = recording.file_path
                DebugPrint("音声ファイルはURL: " .. recording.file_path)
            else
                audioData = LoadRecordingFile(recording.file_path)
                if audioData then
                    DebugPrint("音声ファイル読み込み成功: " .. recording.file_path)
                end
            end
            if audioData then
                
                -- 範囲内の全プレイヤーに再生イベント送信
                local players = QBCore.Functions.GetPlayers()
                for _, playerId in pairs(players) do
                    local targetCoords = GetEntityCoords(GetPlayerPed(playerId))
                    local distance = #(vector3(sourceCoords.x, sourceCoords.y, sourceCoords.z) - targetCoords)
                    
                    if distance <= Config.PlaybackRange then
                        TriggerClientEvent('ng-voicerecorder:playAudioClient', playerId, audioData, sourceCoords, Config.PlaybackRange)
                        DebugPrint("音声送信: Player " .. playerId .. " (距離: " .. distance .. "m)")
                    end
                end
            else
                DebugPrint("音声ファイル読み込み失敗: " .. recording.file_path)
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'ボイスレコーダー',
                    description = '音声ファイルが見つかりません',
                    type = 'error'
                })
            end
        else
            DebugPrint("録音データが見つかりません: " .. systemId)
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'ボイスレコーダー',
                description = '録音データが見つかりません',
                type = 'error'
            })
        end
    end)
end)

-- ========================
-- デバッグコマンドイベント
-- ========================

RegisterNetEvent('ng-voicerecorder:giveDebugItems', function()
    if not Config.EnableDebugCommands then return end
    
    local src = source
    DebugPrint("デバッグ: アイテム付与 Player " .. src)
    
    local voiceRecorderAdded = AddItem(src, Config.Items.VoiceRecorder, 1)
    local emptyTapeAdded = AddItem(src, Config.Items.EmptyTape, 5)
    
    DebugPrint("ボイスレコーダー追加: " .. tostring(voiceRecorderAdded))
    DebugPrint("空のテープ追加: " .. tostring(emptyTapeAdded))
    
    if voiceRecorderAdded and emptyTapeAdded then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'デバッグ',
            description = 'ボイスレコーダーアイテムを付与しました',
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'デバッグ',
            description = 'アイテム付与に失敗しました',
            type = 'error'
        })
    end
end)

RegisterNetEvent('ng-voicerecorder:clearRecordings', function()
    if not Config.EnableDebugCommands then return end
    
    local src = source
    DebugPrint("デバッグ: 録音ファイルクリア by Player " .. src)
    
    -- データベースから削除
    MySQL.execute('DELETE FROM ng_voicerecorder_recordings')
    
    -- ファイルシステムからの削除をシミュレート
    ClearRecordingFiles()
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'デバッグ',
        description = '全ての録音ファイルをクリアしました',
        type = 'success'
    })
end)

-- ========================
-- ファイル操作関数
-- ========================

-- Base64デコード関数
function base64Decode(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='','0123456789ABCDEF'
        for i=1,6 do
            local c=b:find(x)-1
            r=r..(c%2^1 and '1' or '0')
            c=math.floor(c/2)
        end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

function SaveRecordingFile(base64Data, filePath, mimeType, src)
    -- 新実装: 外部アップロードを使用する場合は HTTP multipart でアップロード
    DebugPrint("録音ファイル保存: " .. tostring(filePath))
    DebugPrint("MIME Type: " .. tostring(mimeType))
    DebugPrint("Base64データ長: " .. tostring(string.len(base64Data or "")))

    if not base64Data or base64Data == "" then
        DebugPrint("エラー: Base64データが空です")
        return false
    end

    -- data:...;base64, のような prefix が付いている場合は取り除く
    local cleanBase64 = base64Data
    if string.find(base64Data, "data:") then
        cleanBase64 = string.match(base64Data, "data:[^;]*;base64,(.+)") or base64Data
    end

    local binaryData = base64Decode(cleanBase64)
    if not binaryData or #binaryData == 0 then
        DebugPrint("エラー: Base64 デコードに失敗しました")
        return false
    end

    -- ディレクトリ作成
    local dir = string.match(filePath, "(.+)/[^/]*$") or recordingsPath
    DebugPrint("ローカル保存ディレクトリ確認/作成: " .. tostring(dir))
    pcall(function() EnsureDirectory(dir) end)

    local ok, err = pcall(function()
        local f = io.open(filePath, "wb")
        if not f then error("ファイルオープン失敗: " .. tostring(filePath)) end
        f:write(binaryData)
        f:close()
    end)

    if ok then
        DebugPrint("ローカル保存成功: " .. filePath)
        return true, filePath
    else
        DebugPrint("ローカル保存失敗: " .. tostring(err))
        return false
    end
end

-- Base64エンコード関数
function base64Encode(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

function LoadRecordingFile(filePath)
    -- 実際の実装では、指定されたパスからWebMファイルを読み込む
    DebugPrint("録音ファイル読み込み: " .. tostring(filePath))
    
    local success, result = pcall(function()
        -- バイナリで読み込む
        local file = io.open(filePath, "rb")
        if not file then
            error("ファイルが見つかりません: " .. filePath)
        end
        
        local content = file:read("*all")
        file:close()
        
        if not content or #content == 0 then
            error("ファイルが空です")
        end
        
        -- Base64形式で保存されている場合は、そのまま返す
        DebugPrint("ファイル読み込み成功: " .. filePath .. " (Base64サイズ: " .. #content .. " chars)")
        return content
    end)
    
    if success then
        return result
    else
        DebugPrint("録音ファイル読み込み失敗: " .. tostring(result))
        return nil
    end
end

function ClearRecordingFiles()
    -- 録音フォルダ内のファイルを削除
    DebugPrint("録音ファイル全削除")
    -- データベースの登録ファイルを取得して個別に削除する（URLはスキップ）
    MySQL.query('SELECT file_path FROM ng_voicerecorder_recordings', {}, function(results)
        if results and #results > 0 then
            for _, row in ipairs(results) do
                local fp = row.file_path
                if fp and not string.match(fp, '^https?://') then
                    local ok = SafeRemoveFile(fp)
                    DebugPrint("ファイル削除: " .. tostring(fp) .. " -> " .. tostring(ok))
                end
            end
        else
            DebugPrint("削除対象ファイルなし（DBに登録なし）")
        end
    end)
end

-- ========================
-- データベーステーブル作成（安全なカラム追加）
-- ========================

CreateThread(function()
    -- メインテーブル作成
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS ng_voicerecorder_recordings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            system_id VARCHAR(50) UNIQUE NOT NULL,
            player_id INT NOT NULL,
            display_name VARCHAR(100) NOT NULL,
            file_path VARCHAR(255) NOT NULL,
            recorded_at DATETIME NOT NULL,
            duration INT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
    -- カラム存在チェック後に追加
    MySQL.query("SHOW COLUMNS FROM ng_voicerecorder_recordings LIKE 'mime_type'", {}, function(result)
        if not result or #result == 0 then
            MySQL.query("ALTER TABLE ng_voicerecorder_recordings ADD COLUMN mime_type VARCHAR(50) DEFAULT 'audio/webm'", {}, function(success)
                if success then
                    DebugPrint("mime_typeカラム追加完了")
                end
            end)
        else
            DebugPrint("mime_typeカラムは既に存在します")
        end
    end)
    
    MySQL.query("SHOW COLUMNS FROM ng_voicerecorder_recordings LIKE 'file_size'", {}, function(result)
        if not result or #result == 0 then
            MySQL.query("ALTER TABLE ng_voicerecorder_recordings ADD COLUMN file_size INT DEFAULT 0", {}, function(success)
                if success then
                    DebugPrint("file_sizeカラム追加完了")
                end
            end)
        else
            DebugPrint("file_sizeカラムは既に存在します")
        end
    end)
    
    DebugPrint("データベーステーブル初期化完了")
end)

-- ========================
-- ファイル自動削除
-- ========================

CreateThread(function()
    while true do
        Wait(Config.CleanupInterval * 60 * 60 * 1000) -- 時間をミリ秒に変換
        
        local cutoffDate = os.date("%Y-%m-%d %H:%M:%S", os.time() - (Config.FileRetentionDays * 24 * 60 * 60))
        
        MySQL.query('SELECT * FROM ng_voicerecorder_recordings WHERE recorded_at < ?', {cutoffDate}, function(result)
            if result and #result > 0 then
                for _, recording in pairs(result) do
                    -- ファイル削除
                    DeleteRecordingFile(recording.file_path)
                end
                
                -- データベースから削除
                MySQL.execute('DELETE FROM ng_voicerecorder_recordings WHERE recorded_at < ?', {cutoffDate})
                
                DebugPrint("古い録音ファイル削除: " .. #result .. "件")
            end
        end)
    end
end)

function DeleteRecordingFile(filePath)
    -- 指定されたファイルを削除
    DebugPrint("録音ファイル削除: " .. filePath)
    local ok = SafeRemoveFile(filePath)
    if ok then
        DebugPrint("録音ファイル削除成功: " .. filePath)
    else
        DebugPrint("録音ファイル削除失敗: " .. filePath)
    end
end

-- ========================
-- 初期化
-- ========================

CreateThread(function()
    CreateRecordingsFolder()
    DebugPrint("ng-voicerecorder サーバー初期化完了")
    
    if Config.EnableDebugCommands then
        DebugPrint("デバッグモードが有効です")
    end
end)