local QBCore = exports['qb-core']:GetCoreObject()
local isRecording = false
local isPlaying = false
local currentRecordingId = nil

-- ========================
-- ユーティリティ関数
-- ========================

local function DebugPrint(message, level)
    if Config.Debug and (level or 1) <= Config.DebugLevel then
        print("[ng-voicerecorder] " .. message)
    end
end

local function ShowNotification(message, type)
    lib.notify({
        title = 'ボイスレコーダー',
        description = message,
        type = type or 'inform',
        duration = Config.NotificationDuration
    })
end

local function HasItem(itemName)
    -- ox_inventoryの場合
    if GetResourceState('ox_inventory') == 'started' then
        -- ox_inventory のエクスポートが何らかの理由で失敗した場合に備え、pcall で保護
        local ok, count = pcall(function()
            return exports.ox_inventory:GetItemCount(itemName)
        end)
        if not ok then
            DebugPrint("ox_inventory:GetItemCount の呼び出しでエラー発生: " .. tostring(count))
            return false
        end
        return count > 0
    end
    
    -- qb-core標準の場合
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData or not PlayerData.items then return false end
    
    for _, item in pairs(PlayerData.items) do
        if item and item.name == itemName and item.amount and item.amount > 0 then
            return true, item
        end
    end
    return false
end

local function GetRecordedTapes()
    -- ox_inventoryの場合
    if GetResourceState('ox_inventory') == 'started' then
        local items = exports.ox_inventory:GetPlayerItems()
        local tapes = {}
        
        if items then
            for slot, item in pairs(items) do
                if item and item.name == Config.Items.RecordedTape and item.count and item.count > 0 then
                    table.insert(tapes, {
                        slot = slot,
                        item = item,
                        displayName = item.metadata and item.metadata.displayName or "録音テープ #" .. slot,
                        systemId = item.metadata and item.metadata.systemId or "unknown"
                    })
                end
            end
        end
        
        return tapes
    end
    
    -- qb-core標準の場合
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData or not PlayerData.items then return {} end
    
    local tapes = {}
    for slot, item in pairs(PlayerData.items) do
        if item and item.name == Config.Items.RecordedTape and item.amount and item.amount > 0 then
            table.insert(tapes, {
                slot = slot,
                item = item,
                displayName = item.info and item.info.displayName or "録音テープ #" .. slot,
                systemId = item.info and item.info.systemId or "unknown"
            })
        end
    end
    return tapes
end

-- ========================
-- NUI コールバック
-- ========================

RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('startRecording', function(data, cb)
    if isRecording then
        cb('error')
        return
    end
    
    DebugPrint("録音開始リクエスト")
    
    -- pma-voiceの録音開始
    TriggerEvent('pma-voice:startRecording')
    isRecording = true
    currentRecordingId = GetGameTimer() .. "_" .. math.random(1000, 9999)
    
    -- 録音時間後に自動停止
    SetTimeout(Config.RecordingTime * 1000, function()
        if isRecording then
            TriggerEvent('pma-voice:stopRecording')
            -- 録音はNUI側でデータを受け取りサーバへ送信するため、ここで直接送らない
            isRecording = false
            currentRecordingId = nil
        end
    end)
    
    cb('ok')
end)

RegisterNUICallback('stopRecording', function(data, cb)
    if not isRecording then
        cb('error')
        return
    end
    
    DebugPrint("録音停止リクエスト")
    
    TriggerEvent('pma-voice:stopRecording')
    -- 録音完了データはNUI側 (script.js) から送信されるので、ここでは送信しない
    isRecording = false
    currentRecordingId = nil
    
    cb('ok')
end)

-- 追加：saveRecordingコールバック
RegisterNUICallback('saveRecording', function(data, cb)
    DebugPrint("=== NUIコールバック: saveRecording ===")
    DebugPrint("受信データタイプ: " .. type(data))
    
    if not data then
        DebugPrint("エラー: データがnilです")
        cb({status = 'error', message = 'データが受信されませんでした'})
        return
    end
    
    -- データの検証
    local tapeName = data.tapeName
    local audioData = data.audioData  
    local mimeType = data.mimeType
    local audioSize = data.size
    
    DebugPrint("テープ名: " .. tostring(tapeName))
    DebugPrint("MIME Type: " .. tostring(mimeType))
    DebugPrint("音声サイズ: " .. tostring(audioSize) .. " bytes")
    DebugPrint("Base64データ長: " .. tostring(string.len(audioData or "")))
    
    -- アイテムチェック
    local hasVoiceRecorder = HasItem(Config.Items.VoiceRecorder)
    local hasEmptyTape = HasItem(Config.Items.EmptyTape)
    
    if not hasVoiceRecorder then
        DebugPrint("エラー: ボイスレコーダーを持っていません")
        cb({status = 'error', message = 'ボイスレコーダーを持っていません'})
        return
    end
    
    if not hasEmptyTape then
        DebugPrint("エラー: 空のテープを持っていません")
        cb({status = 'error', message = '空のテープを持っていません'})
        return
    end
    
    -- 音声データの検証
    if not audioData or audioData == "" then
        DebugPrint("エラー: 音声データが空です")
        cb({status = 'error', message = '録音データが取得できませんでした'})
        return
    end
    
    -- サーバーにデータを送信
    TriggerServerEvent('ng-voicerecorder:saveRecording', data)
    
    -- レスポンス
    cb({status = 'ok'})
    DebugPrint("NUIコールバック処理完了")
end)

-- ========================
-- メニュー機能
-- ========================

local function showTapeSelectionMenu()
    local recordedTapes = GetRecordedTapes()
    
    if #recordedTapes == 0 then
        ShowNotification(Config.Notifications.NoRecordedTape, 'error')
        return
    end
    
    local options = {}
    
    for _, tape in ipairs(recordedTapes) do
        table.insert(options, {
            title = tape.displayName,
            description = 'システムID: ' .. tape.systemId,
            icon = 'tape',
            onSelect = function()
                local coords = GetEntityCoords(PlayerPedId())
                TriggerServerEvent('ng-voicerecorder:playAudio', tape.systemId, coords)
                ShowNotification(Config.Notifications.PlayingAudio, 'success')
            end
        })
    end
    
    lib.registerContext({
        id = 'ng_voicerecorder_tapes',
        title = Config.MenuTexts.SelectTapeTitle,
        menu = 'ng_voicerecorder_main',
        options = options
    })
    
    lib.showContext('ng_voicerecorder_tapes')
end

local function ShowRecordingMenu()
    local hasVoiceRecorder = HasItem(Config.Items.VoiceRecorder)
    local hasEmptyTape = HasItem(Config.Items.EmptyTape)
    local recordedTapes = GetRecordedTapes()
    
    -- デバッグモードがOFFの場合、アイテムをしっかりチェック
    if not hasVoiceRecorder then
        ShowNotification(Config.Notifications.NoVoiceRecorder, 'error')
        return
    end
    
    local options = {}
    
    -- 録音オプション
    if hasEmptyTape then
        table.insert(options, {
            title = Config.MenuTexts.RecordOption,
            description = '空のテープに音声を録音します',
            icon = 'microphone',
            onSelect = function()
                startRecordingProcess()
            end
        })
    end
    
    -- 再生オプション
    if #recordedTapes > 0 then
        table.insert(options, {
            title = Config.MenuTexts.PlayOption,
            description = '録音済みテープを再生します',
            icon = 'play',
            onSelect = function()
                showTapeSelectionMenu()
            end
        })
    end
    
    if #options == 0 then
        if not hasEmptyTape and #recordedTapes == 0 then
            ShowNotification("空のテープまたは録音済みテープが必要です", 'error')
        elseif not hasEmptyTape then
            ShowNotification(Config.Notifications.NoEmptyTape, 'error')
        elseif #recordedTapes == 0 then
            ShowNotification(Config.Notifications.NoRecordedTape, 'error')
        end
        return
    end
    
    lib.registerContext({
        id = 'ng_voicerecorder_main',
        title = Config.MenuTexts.MainTitle,
        options = options
    })
    
    lib.showContext('ng_voicerecorder_main')
end

function startRecordingProcess()
    local input = lib.inputDialog(Config.MenuTexts.NameTapeTitle, {
        {
            type = 'input',
            label = 'テープ名',
            placeholder = Config.MenuTexts.NameTapePlaceholder,
            required = true,
            min = 1,
            max = 50
        }
    })
    
    if not input or not input[1] or input[1]:len() == 0 then
        ShowNotification(Config.Notifications.InvalidTapeName, 'error')
        return
    end
    
    local tapeName = input[1]
    
    -- NUIを開いて録音開始
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showRecording',
        tapeName = tapeName,
        recordingTime = Config.RecordingTime
    })
    
    ShowNotification(Config.Notifications.RecordingStarted, 'success')
    DebugPrint("録音プロセス開始: " .. tapeName)
end

-- ========================
-- アイテム使用イベント
-- ========================

RegisterNetEvent('ng-voicerecorder:useVoiceRecorder', function()
    DebugPrint("ボイスレコーダー使用")
    ShowRecordingMenu()
end)

-- ox_inventory用のアイテム使用フック（重複防止）
local lastUsedTime = 0
if GetResourceState('ox_inventory') == 'started' then
    RegisterNetEvent('ox_inventory:usedItem', function(item, slot)
        if item == Config.Items.VoiceRecorder then
            local currentTime = GetGameTimer()
            if currentTime - lastUsedTime > 1000 then -- 1秒間のクールダウン
                lastUsedTime = currentTime
                TriggerServerEvent('ng-voicerecorder:useItem', item, slot)
            end
        end
    end)
end

-- ========================
-- サーバーイベント
-- ========================

RegisterNetEvent('ng-voicerecorder:recordingComplete', function(success, message)
    DebugPrint("録音完了通知受信: " .. tostring(success))
    
    -- NUIに録音完了を通知
    SendNUIMessage({
        action = 'recordingComplete',
        success = success,
        message = message
    })
    
    if success then
        ShowNotification(Config.Notifications.RecordingCompleted, 'success')
        DebugPrint("録音保存成功")
    else
        ShowNotification(message or Config.Notifications.RecordingFailed, 'error')
        DebugPrint("録音保存失敗: " .. tostring(message))
    end
end)

RegisterNetEvent('ng-voicerecorder:playAudioClient', function(audioData, sourceCoords, range)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(playerCoords - sourceCoords)
    
    if distance <= range then
        DebugPrint("音声再生: 距離 " .. distance .. "m")
        
        -- 距離による音量調整
        local volume = math.max(0.1, 1.0 - (distance / range))
        
        -- NUIで音声再生
        SendNUIMessage({
            action = 'playAudio',
            audioData = audioData,
            volume = volume
        })
    end
end)

-- ========================
-- デバッグコマンド
-- ========================

if Config.EnableDebugCommands then
    RegisterCommand(Config.DebugCommands.TestRecorder, function()
        DebugPrint("デバッグ: ボイスレコーダーテスト実行")
        ShowRecordingMenu()
    end, false)
    
    RegisterCommand(Config.DebugCommands.GiveItems, function()
        DebugPrint("デバッグ: アイテム付与")
        TriggerServerEvent('ng-voicerecorder:giveDebugItems')
    end, false)
    
    RegisterCommand(Config.DebugCommands.ClearRecordings, function()
        DebugPrint("デバッグ: 録音ファイルクリア")
        TriggerServerEvent('ng-voicerecorder:clearRecordings')
    end, false)
    
    -- ヘルプコマンド
    RegisterCommand('voicehelp', function()
        print("=== ng-voicerecorder デバッグコマンド ===")
        print("/" .. Config.DebugCommands.TestRecorder .. " - ボイスレコーダーテスト")
        print("/" .. Config.DebugCommands.GiveItems .. " - アイテム付与")  
        print("/" .. Config.DebugCommands.ClearRecordings .. " - 録音ファイルクリア")
        print("/voicehelp - このヘルプを表示")
    end, false)
end

-- ========================
-- 初期化
-- ========================

CreateThread(function()
    DebugPrint("ng-voicerecorder クライアント初期化完了")
    
    if Config.EnableDebugCommands then
        DebugPrint("デバッグコマンドが有効です。/voicehelp でコマンド一覧を確認できます。")
    end
end)