-- クライアントサイドのリングトーン処理
local identifier = "ng-ringtone"
local defaultRingtone = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
local savedRingtones = {}
local currentRingtone = nil
local isPlaying = false
local currentSoundId = nil
local isMuted = false
local volumeSelf = 1.0
local volumeOthers = 0.7
local isUIOpen = false -- UIが開いているかを追跡
-- 追従する着信音の管理
local followingSoundId = nil
local followingSoundInterval = nil
local intervals = {}
local intervalCount = 0

-- デバッグ出力関数
function DebugPrint(message)
    -- デバッグ出力を無効化
    -- print("^3[リングトーン]^7 " .. tostring(message))
    -- TriggerServerEvent("ng-ringtone:server:debugLog", message)
end

-- LB-Phoneが起動するまで待機
while GetResourceState("lb-phone") ~= "started" do
    Wait(500)
end

-- xSoundが利用可能か確認
if GetResourceState("xsound") ~= "started" then
    DebugPrint("エラー: xsoundが起動していません。リングトーン変更アプリには必要です。")
end

-- カスタムアプリを追加する関数
local function addApp()
    local added, errorMessage = exports["lb-phone"]:AddCustomApp({
        identifier = identifier,
        name = "リングトーン",
        description = "電話の着信音をカスタマイズ",
        developer = "NCCGr",
        defaultApp = true,  -- 自動的に追加
        size = 2048,        -- アプリサイズ（KB）
        icon = "https://cfx-nui-" .. GetCurrentResourceName() .. "/ui/dist/icon.svg",
        ui = GetCurrentResourceName() .. "/ui/dist/index.html",
        -- ui = "http://localhost:3000", -- 開発時はこちらを使用
        fixBlur = true
    })

    if not added then
        --DebugPrint("アプリを追加できませんでした: " .. tostring(errorMessage))
    else
        --DebugPrint("アプリが正常に追加されました")
    end
end

-- アプリ追加
addApp()

-- LB-Phoneが起動したときにアプリを追加
AddEventHandler("onResourceStart", function(resource)
    if resource == "lb-phone" then
        addApp()
    end
end)

-- サーバーからリングトーン一覧を受け取る
RegisterNetEvent('ng-ringtone:client:receiveRingtones')
AddEventHandler('ng-ringtone:client:receiveRingtones', function(ringtones)
    local count = ringtones and #ringtones or 0
    ----DebugPrint("サーバーからリングトーン一覧を受信: " .. count .. "件")
    
    -- 詳細をログに出力
    if count > 0 then
        for i, ringtone in ipairs(ringtones) do
            ----DebugPrint(string.format("受信リングトーン #%d: ID=%d, 名前=%s", i, ringtone.id, ringtone.name))
        end
    end
    
    savedRingtones = ringtones or {}
    
    -- デフォルトリングトーンを設定
    local found = false
    for _, ringtone in ipairs(savedRingtones) do
        if ringtone.is_default == 1 then
            currentRingtone = ringtone
            isMuted = ringtone.is_muted == 1
            volumeSelf = ringtone.volume_self
            volumeOthers = ringtone.volume_others
            found = true
            break
        end
    end
    
    -- デフォルトが見つからない場合はシステムデフォルトを使用
    if not found then
        currentRingtone = {
            name = "システムデフォルト",
            url = defaultRingtone,
            is_default = 1,
            is_muted = 0,
            volume_self = 1.0,
            volume_others = 0.7
        }
    end
    
    ----DebugPrint("リングトーン一覧を取得しました。合計: " .. #savedRingtones)
    
    -- UIが開いている場合は、リストを更新
    if isUIOpen then
        ----DebugPrint("UI開いているため、リストを更新")
        SendNUIMessage({
            action = "updateRingtoneList",
            ringtones = savedRingtones
        })
    else
        ----DebugPrint("UIが閉じているため、更新をスキップ")
    end
end)

-- 音量設定を受け取るイベント
RegisterNetEvent('ng-ringtone:client:receiveVolumeSettings')
AddEventHandler('ng-ringtone:client:receiveVolumeSettings', function(data)
    if data.volumeSelf then volumeSelf = data.volumeSelf end
    if data.volumeOthers then volumeOthers = data.volumeOthers end
    if data.isMuted ~= nil then isMuted = data.isMuted end
    print("^2[リングトーン] サーバーから設定を受信: 自分=" .. volumeSelf .. ", 周囲=" .. volumeOthers .. ", ミュート=" .. tostring(isMuted) .. "^7")
end)

-- アプリ起動時にリングトーン一覧を取得
AddEventHandler("onClientResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        -- まず音量設定を要求してから、リングトーン一覧を取得する順序が重要
        Citizen.CreateThread(function()
            -- 設定情報を明示的に要求
            TriggerServerEvent("ng-ringtone:server:requestVolumeSettings")
            
            -- 音量設定の読み込みを待機
            Citizen.Wait(1000)
            
            -- 設定が適用された後でリングトーン一覧を要求
            TriggerServerEvent("ng-ringtone:server:getRingtones")
            
            -- デバッグ出力（必要に応じてコメントアウト）
            ----DebugPrint("初期化完了: 音量設定=" .. tostring(volumeSelf) .. ", 周囲音量=" .. tostring(volumeOthers) .. ", ミュート=" .. tostring(isMuted))
        end)
    end
end)

-- 着信音停止関数を改善
function StopRingtone()
    ----DebugPrint("StopRingtone 関数が呼び出されました")
    
    -- 再生中でなくても強制的に停止を試みる
    local playerId = GetPlayerServerId(PlayerId())
    
    -- 現在のサウンドIDを停止
    if currentSoundId then
        ----DebugPrint("サウンド停止: " .. currentSoundId)
        pcall(function() exports["xsound"]:Destroy(currentSoundId) end)
        currentSoundId = nil
    else
        -- IDが不明な場合でも複数の可能性を試す
        local possibleIds = {
            "ringtone_" .. playerId,
            "call_" .. playerId,
            "incoming_" .. playerId
        }
        
        for _, id in ipairs(possibleIds) do
            ----DebugPrint("追加の停止試行: " .. id)
            pcall(function() exports["xsound"]:Destroy(id) end)
        end
    end
    
    -- 周囲のプレイヤーにも停止を通知
    TriggerServerEvent("ng-ringtone:server:stopAllNearbyRingtones", playerId)
    
    isPlaying = false
    ----DebugPrint("着信音停止処理完了")
end

-- 安全に音を停止する関数
function SafelyDestroySound(soundId)
    if not soundId then return false end
    
    ----DebugPrint("サウンド停止試行: " .. soundId)
    
    local success = pcall(function() 
        -- 複数の方法で停止を試みる
        pcall(function() exports["xsound"]:Destroy(soundId) end)
        pcall(function() exports["xsound"]:Stop(soundId) end)
        pcall(function() exports["xsound"]:stopSound(soundId) end)
    end)
    
    return success
end

-- 着信音を完全に停止する関数
function StopAllRingtoneSounds()
    ----DebugPrint("すべての着信音を強制停止")
    
    -- 現在のサウンドIDを停止
    if currentSoundId then
        SafelyDestroySound(currentSoundId)
        currentSoundId = nil
    end
    
    -- 追従音を停止
    if followingSoundId then
        SafelyDestroySound(followingSoundId)
        followingSoundId = nil
    end
    
    -- インターバルをクリア
    if followingSoundInterval then
        clearInterval(followingSoundInterval)
        followingSoundInterval = nil
    end
    
    -- プレイヤーIDに基づく可能性のあるすべてのサウンドIDを試す
    local playerId = GetPlayerServerId(PlayerId())
    local possibleIds = {
        "ringtone_" .. playerId,
        "following_ringtone",
        "call_" .. playerId,
        "incoming_" .. playerId,
        "ringtone_preview"
    }
    
    for _, id in ipairs(possibleIds) do
        SafelyDestroySound(id)
    end
    
    -- 周囲のプレイヤーにも停止を通知
    TriggerServerEvent("ng-ringtone:server:stopAllNearbyRingtones", playerId)
    
    isPlaying = false
    ----DebugPrint("着信音停止処理完了")
    
    -- 成功レスポンスを返す
    return true
end

-- PlayCustomRingtone関数を追従型に変更
function PlayCustomRingtone(callerName)
    print("^3[リングトーン] PlayCustomRingtone呼び出し: 発信者=" .. tostring(callerName) .. ", ミュート状態=" .. tostring(isMuted) .. "^7")
    
    -- ミュートモードならサイレントで処理
    if isMuted then
        print("^1[リングトーン] ミュートモードのため、着信音を再生しません^7")
        isPlaying = true
        return true
    end
    
    -- 着信中フラグを設定
    isPlaying = true
    
    local ringtoneUrl = currentRingtone and currentRingtone.url or defaultRingtone
    -- 全体設定の音量を使用
    local currentVolume = volumeSelf
    
    ----DebugPrint("リングトーンURL: " .. ringtoneUrl .. ", ボリューム: " .. currentVolume)
    
    -- 以前の着信音を停止
    StopRingtone()
    
    -- 追従型着信音を再生
    local success = PlayFollowingRingtone(ringtoneUrl, currentVolume)
    
    if not success then
        ----DebugPrint("再生エラー")
        return false
    end
    
    -- プレイヤーの位置を取得して周囲のプレイヤーに通知
    local playerCoords = GetEntityCoords(PlayerPedId())
    -- 周囲のプレイヤーに着信音のURLと位置を通知（各プレイヤーが自分の音量設定を使用）
    TriggerServerEvent("ng-ringtone:server:notifyNearbyPlayers", playerCoords, ringtoneUrl)
    
    return true
end

function setInterval(callback, msec)
    intervalCount = intervalCount + 1
    local id = intervalCount
    
    intervals[id] = true
    
    Citizen.CreateThread(function()
        while intervals[id] do
            callback()
            Citizen.Wait(msec)
        end
    end)
    
    return id
end

function clearInterval(id)
    if intervals[id] then
        intervals[id] = nil
    end
end

-- 追従型着信音停止関数
function StopFollowingRingtone()
    if followingSoundId then
        ----DebugPrint("追従型着信音を停止: " .. followingSoundId)
        pcall(function() exports["xsound"]:Destroy(followingSoundId) end)
        followingSoundId = nil
    end
    
    if followingSoundInterval then
        clearInterval(followingSoundInterval)
        followingSoundInterval = nil
    end
end

-- StopRingtone関数を拡張
local originalStopRingtone = StopRingtone
function StopRingtone()
    originalStopRingtone()
    StopFollowingRingtone()
end

-- プレイヤーに追従する着信音を再生
function PlayFollowingRingtone(url, volume)
    ----DebugPrint("追従型着信音を再生: " .. url)
    
    local soundId = "following_ringtone"
    followingSoundId = soundId
    
    -- 最初の再生
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    pcall(function()
        exports["xsound"]:PlayUrlPos(
            soundId,
            url,
            volume,
            playerCoords,
            true, -- ループする
            {
                soundId = soundId,
                range = 20.0,
                volume = volume
            }
        )
    end)
    
    -- 追従インターバルをセットアップ
    if followingSoundInterval then
        clearInterval(followingSoundInterval)
    end
    
    -- 100ms間隔で位置を更新
    followingSoundInterval = setInterval(function()
        if followingSoundId then
            local newCoords = GetEntityCoords(PlayerPedId())
            pcall(function()
                exports["xsound"]:Position(followingSoundId, newCoords)
            end)
        else
            -- 音が停止していたらインターバルも停止
            clearInterval(followingSoundInterval)
            followingSoundInterval = nil
        end
    end, 100)
    
    return true
end

-- リングトーン再生イベント
RegisterNetEvent("ng-ringtone:client:playRingtone")
AddEventHandler("ng-ringtone:client:playRingtone", function(data)
    ----DebugPrint("リングトーン再生イベント受信: " .. json.encode(data))
    
    local caller = data.caller or "不明な発信者"
    local ringtone = data.ringtone
    
    if ringtone then
        ----DebugPrint("サーバーから受信したリングトーン設定を使用")
        -- サーバーから受信したリングトーン設定を一時的に適用
        local tempRingtone = currentRingtone
        currentRingtone = ringtone
        
        -- リングトーンを再生
        local success = PlayCustomRingtone(caller)
        ----DebugPrint("リングトーン再生結果: " .. tostring(success))
        
        -- 元の設定に戻す
        if not success then
            currentRingtone = tempRingtone
        end
    else
        ----DebugPrint("リングトーン設定なし - デフォルトを使用")
        PlayCustomRingtone(caller)
    end
end)

-- 着信検知イベントをデバッグ
RegisterNetEvent("lb-phone:newCall")
AddEventHandler("lb-phone:newCall", function(call)
    ----DebugPrint("着信検知: " .. json.encode(call))
    
    -- 着信時のみ音を鳴らす（発信時は鳴らさない）
    local receiverId = call.receiver or (call.callee and call.callee.source)
    local playerId = GetPlayerServerId(PlayerId())
    
    ----DebugPrint("着信先ID: " .. tostring(receiverId) .. ", 自分のID: " .. tostring(playerId))
    
    if receiverId == playerId then
        ----DebugPrint("自分宛ての着信です。カスタムリングトーンを再生します。")
        local callerName = call.caller_name or (call.caller and call.caller.number) or "不明な発信者"
        local success = PlayCustomRingtone(callerName)
        ----DebugPrint("リングトーン再生結果: " .. tostring(success))
    else
        ----DebugPrint("自分宛ての着信ではありません")
    end
end)

-- LB-Phoneのデフォルト着信音を無効化するためのイベント
RegisterNetEvent("lb-phone:client:IncomingCallSound")
AddEventHandler("lb-phone:client:IncomingCallSound", function(callerName, cb)
    ----DebugPrint("着信音イベント検知: " .. tostring(callerName))
    
    -- すでに再生中なら停止しない
    if not isPlaying then
        -- 自分のカスタム着信音を再生
        PlayCustomRingtone(callerName)
    else
        ----DebugPrint("すでに着信音が再生中です")
    end
    
    -- trueを返すことでデフォルトの着信音が鳴らないようにします
    if cb then
        ----DebugPrint("デフォルト着信音を無効化")
        cb(true)
    end
end)

-- 通話応答時の停止処理を強化
RegisterNetEvent("lb-phone:callAnswered")
AddEventHandler("lb-phone:callAnswered", function(call)
    ----DebugPrint("通話応答: " .. json.encode(call))
    StopAllRingtoneSounds()
end)

-- 通話終了時の停止処理を強化
RegisterNetEvent("lb-phone:callEnded")
AddEventHandler("lb-phone:callEnded", function(call)
    ----DebugPrint("通話終了: " .. json.encode(call))
    StopAllRingtoneSounds()
end)

-- 古いイベントの対応も維持
RegisterNetEvent("lb-phone:client:StopRingingSound")
AddEventHandler("lb-phone:client:StopRingingSound", function()
    ----DebugPrint("着信音停止イベント(旧): lb-phone:client:StopRingingSound")
    StopAllRingtoneSounds()
end)

-- 着信音停止イベントを追加
RegisterNetEvent("ng-ringtone:client:stopRingtone")
AddEventHandler("ng-ringtone:client:stopRingtone", function()
    ----DebugPrint("着信音停止イベント: ng-ringtone:client:stopRingtone")
    StopAllRingtoneSounds()
end)

-- 周囲のプレイヤーに着信音を再生（修正版）
RegisterNetEvent("ng-ringtone:client:playNearbyRingtone")
AddEventHandler("ng-ringtone:client:playNearbyRingtone", function(playerSrc, coords, ringtoneUrl)
    -- 自分自身の着信は無視（すでに再生しているため）
    if playerSrc == GetPlayerServerId(PlayerId()) then
        return
    end
    
    -- ミュートモードの場合は周りの着信音も再生しない
    if isMuted then
        print("^1[リングトーン] ミュートモードのため、周囲の着信音を再生しません^7")
        return
    end
    
    local myCoords = GetEntityCoords(PlayerPedId())
    local distance = #(myCoords - vector3(coords.x, coords.y, coords.z))
    
    -- 近くにいる場合のみ再生
    if distance <= 20.0 then
        --DebugPrint("近くのプレイヤー " .. playerSrc .. " の着信音を再生します。距離: " .. distance)
        
        -- 自分の「周りの音量」設定を使用（他人の着信音が自分に聞こえる音量）
        local othersVolumeSetting = volumeOthers
        
        -- 音量が0の場合は再生しない
        if othersVolumeSetting <= 0.0 then
            --DebugPrint("周囲音量が0のため、再生をスキップします")
            return
        end
        
        -- 音量を距離と自分の音量設定に応じて調整
        -- 距離による減衰を適用
        local distanceFactor = 1.0 - (distance / 20.0)
        local volume = othersVolumeSetting * distanceFactor
        
        -- デバッグ情報
        --DebugPrint(string.format("周囲音量設定: %.2f, 距離: %.2f, 最終音量: %.2f", 
        --                         othersVolumeSetting, distance, volume))
        
        local nearbyId = "nearby_" .. playerSrc
        
        -- 既存の音を停止
        pcall(function() exports["xsound"]:Destroy(nearbyId) end)
        
        -- 新しい音を再生
        pcall(function()
            exports["xsound"]:PlayUrlPos(
                nearbyId,
                ringtoneUrl,
                volume,
                coords,
                true, -- ループ
                {
                    soundId = nearbyId,
                    range = 20.0,
                    volume = volume
                }
            )
        end)
    end
end)
-- 通話が終了した際に周囲のプレイヤーの音も停止
RegisterNetEvent("ng-ringtone:client:stopNearbyRingtone")
AddEventHandler("ng-ringtone:client:stopNearbyRingtone", function(sourcePlayer)
    ----DebugPrint("プレイヤー " .. sourcePlayer .. " の着信音を停止します")
    
    -- 複数の方法で停止を試みる
    local soundFormats = {
        "nearby_ringtone_" .. sourcePlayer,
        "nearby_" .. sourcePlayer,
        "ringtone_" .. sourcePlayer
    }
    
    for _, soundId in ipairs(soundFormats) do
        pcall(function() exports["xsound"]:Destroy(soundId) end)
        pcall(function() exports["xsound"]:Stop(soundId) end)
        pcall(function() exports["xsound"]:stopSound(soundId) end)
        ----DebugPrint("サウンドID停止試行: " .. soundId)
    end
    
    -- ng-soundの場合も停止を試みる
    if IsEventExist and IsEventExist("ng-sound:client:stopSound") then
        TriggerEvent("ng-sound:client:stopSound", "nearby_" .. sourcePlayer)
    end
end)

-- UI連携のための新しいコールバック

-- UIが開かれた時に呼ばれるコールバック
RegisterNUICallback("appOpened", function(data, cb)
    ----DebugPrint("UIが開かれました - リングトーン一覧を要求します")
    isUIOpen = true
    
    -- 最新データを明示的に要求
    TriggerServerEvent("ng-ringtone:server:getRingtones")
    
    cb({ success = true })
end)

-- UIが閉じられた時に呼ばれるコールバック
RegisterNUICallback("appClosed", function(data, cb)
    ----DebugPrint("UIが閉じられました")
    isUIOpen = false
    cb({ success = true })
end)

-- リングトーン一覧取得
RegisterNUICallback("getRingtones", function(data, cb)
    ----DebugPrint("UIからリングトーン一覧のリクエスト - 直接データを返します")
    
    -- 現在のデータを直接返す
    cb({ success = true, ringtones = savedRingtones })
    
    -- 念のため、サーバーからも最新データを要求
    TriggerServerEvent("ng-ringtone:server:getRingtones")
end)

-- リングトーン一覧を更新（明示的に更新ボタンが押された場合）
RegisterNUICallback("refreshRingtones", function(data, cb)
    ----DebugPrint("UIからリングトーン一覧の更新リクエスト")
    
    -- データを要求
    TriggerServerEvent("ng-ringtone:server:getRingtones")
    
    -- クライアント側で即座に通知を送信
    SendNUIMessage({
        action = "notification",
        message = "リストを更新中...",
        type = "info"
    })
    
    -- 成功を返す
    cb({ success = true })
end)

-- 現在のリングトーン取得
RegisterNUICallback("getCurrentRingtone", function(data, cb)
    --DebugPrint("UIから現在のリングトーン情報のリクエスト")
    cb(currentRingtone)
end)

-- リングトーンを保存
RegisterNUICallback("saveRingtone", function(data, cb)
    if data.url and data.name then
        --DebugPrint("新しいリングトーンを保存: " .. data.name .. " - " .. data.url)
        TriggerServerEvent("ng-ringtone:server:saveRingtone", data)
        cb({ success = true, message = "リングトーンを保存しています..." })
    else
        --DebugPrint("無効なデータでの保存リクエスト")
        cb({ success = false, message = "無効な情報です" })
    end
end)

-- リングトーン保存成功イベント
RegisterNetEvent('ng-ringtone:client:saveSuccess')
AddEventHandler('ng-ringtone:client:saveSuccess', function(success)
    if success then
        SendNUIMessage({
            action = "notification",
            message = "着信音が正常に追加されました",
            type = "success"
        })
        -- 自動的にリストを更新
        TriggerServerEvent("ng-ringtone:server:getRingtones")
    else
        SendNUIMessage({
            action = "notification",
            message = "着信音の追加に失敗しました",
            type = "error"
        })
    end
end)

-- リングトーンを更新
RegisterNUICallback("updateRingtone", function(data, cb)
    if data.id and data.url and data.name then
        --DebugPrint("リングトーンを更新: " .. data.name .. " - " .. data.url)
        TriggerServerEvent("ng-ringtone:server:updateRingtone", data)
        cb({ success = true, message = "リングトーンを更新しています..." })
    else
        --DebugPrint("無効なデータでの更新リクエスト")
        cb({ success = false, message = "無効な情報です" })
    end
end)

-- リングトーン更新成功イベント
RegisterNetEvent('ng-ringtone:client:updateSuccess')
AddEventHandler('ng-ringtone:client:updateSuccess', function(success)
    if success then
        SendNUIMessage({
            action = "notification",
            message = "着信音が正常に更新されました",
            type = "success"
        })
        -- 自動的にリストを更新
        TriggerServerEvent("ng-ringtone:server:getRingtones")
    else
        SendNUIMessage({
            action = "notification",
            message = "着信音の更新に失敗しました",
            type = "error"
        })
    end
end)

-- リングトーンを削除
RegisterNUICallback("deleteRingtone", function(id, cb)
    --DebugPrint("リングトーンを削除: ID " .. tostring(id))
    
    -- IDを確認して数値に変換
    local idNum = tonumber(id)
    if not idNum then
        --DebugPrint("無効なIDフォーマット: " .. tostring(id))
        cb({ success = false, message = "無効なID形式です" })
        return
    end
    
    -- サーバーに削除リクエストを送信
    TriggerServerEvent("ng-ringtone:server:deleteRingtone", idNum)
    
    -- 直ちに成功を返す（実際の削除結果はイベントで通知される）
    cb({ success = true, message = "削除リクエストを送信しました" })
end)

-- リングトーン削除成功イベント
RegisterNetEvent('ng-ringtone:client:deleteSuccess')
AddEventHandler('ng-ringtone:client:deleteSuccess', function(success)
    if success then
        --DebugPrint("リングトーン削除成功")
        SendNUIMessage({
            action = "notification",
            message = "着信音が正常に削除されました",
            type = "success"
        })
        
        -- 自動的にリストを更新するリクエストを送信
        TriggerServerEvent("ng-ringtone:server:getRingtones")
    else
        --DebugPrint("リングトーン削除失敗")
        SendNUIMessage({
            action = "notification",
            message = "着信音の削除に失敗しました",
            type = "error"
        })
    end
end)

-- ミュート設定を切り替え - 修正済み（新しいグローバル設定システムに対応）
RegisterNUICallback("toggleMute", function(data, cb)
    -- 全体のミュート設定を切り替え
    isMuted = not isMuted
    print("^2[リングトーン] ミュート設定を変更: " .. tostring(isMuted) .. "^7")
    
    -- 新しいミュート設定をサーバーに送信
    TriggerServerEvent("ng-ringtone:server:toggleMute", isMuted)
    
    cb({ success = true, message = "ミュート設定を変更しました", isMuted = isMuted })
end)

-- NUIコールバックの追加（updateGlobalVolume用）
RegisterNUICallback("updateGlobalVolume", function(data, cb)
    if data.volumeSelf ~= nil then 
        volumeSelf = data.volumeSelf 
        --DebugPrint("自分の音量を設定: " .. volumeSelf)
    end
    if data.volumeOthers ~= nil then 
        volumeOthers = data.volumeOthers 
        --DebugPrint("周囲から聞こえる音量を設定: " .. volumeOthers)
    end
    
    -- サーバーに音量設定を保存
    TriggerServerEvent("ng-ringtone:server:saveGlobalVolume", {
        volumeSelf = volumeSelf,
        volumeOthers = volumeOthers
    })
    
    cb({ success = true, message = "音量設定を更新しました" })
end)

-- リングトーンプレビュー
RegisterNUICallback("previewRingtone", function(data, cb)
    local url = data.url or currentRingtone.url
    --DebugPrint("リングトーンプレビュー: " .. url)
    
    -- 再生中のプレビューを停止
    if isPlaying then
        --DebugPrint("既存のプレビューを停止")
        exports["xsound"]:Destroy("ringtone_preview")
        isPlaying = false
    end
    
    -- 新しいプレビューを再生
    --DebugPrint("プレビュー再生開始")
    local success, error = pcall(function()
        exports["xsound"]:PlayUrl("ringtone_preview", url, 0.5, false)
    end)
    
    if not success then
        --DebugPrint("プレビュー再生エラー: " .. tostring(error))
        cb({ success = false, error = tostring(error) })
        return
    end
    
    isPlaying = true
    cb({ success = true })
end)

-- プレビューを停止
RegisterNUICallback("stopPreview", function(data, cb)
    --DebugPrint("プレビュー停止リクエスト")
    pcall(function() exports["xsound"]:Destroy("ringtone_preview") end)
    isPlaying = false
    cb({ success = true })
end)

-- デフォルトリングトーンにリセット
RegisterNUICallback("resetToDefault", function(data, cb)
    --DebugPrint("デフォルトリングトーンにリセット")
    currentRingtone = {
        name = "システムデフォルト",
        url = defaultRingtone,
        is_default = 1,
        is_muted = 0,
        volume_self = 1.0,
        volume_others = 0.7
    }
    cb({ success = true, message = "デフォルトリングトーンにリセットしました" })
end)

-- 設定をデータベースから再読み込み
RegisterNUICallback("refreshSettings", function(data, cb)
    print("^2[リングトーン] 設定を再読み込み中...^7")
    
    -- サーバーに設定を要求
    TriggerServerEvent("ng-ringtone:server:requestVolumeSettings")
    
    -- 少し待ってから現在の設定を返す
    Citizen.Wait(500)
    
    cb({ 
        success = true, 
        volumeSelf = volumeSelf,
        volumeOthers = volumeOthers,
        isMuted = isMuted
    })
end)