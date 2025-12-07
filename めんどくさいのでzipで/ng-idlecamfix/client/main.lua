local QBCore = exports['qb-core']:GetCoreObject()
local lastInputTime = 0
local isIdleActive = false
local disableIdleCam = Config.DisableIdleCamera

-- INPUT_LOOK_LR = 1 (カメラを左右に動かす入力)
-- INPUT_LOOK_UD = 2 (カメラを上下に動かす入力)

-- アイドルカメラを完全に無効化
if disableIdleCam then
    -- GTA自体のアイドルカメラをオフにする設定をロードした直後に適用
    CreateThread(function()
        while true do
            -- ゲーム内設定でアイドルカメラを無効化
            SetPauseMenuActive(false)
            
            if IsPedArmed(PlayerPedId(), 4) then
                SetPlayerForcedAim(PlayerId(), false)
            end
            
            -- アイドルカメラシネマティックをオフに
            if IsPlayerCamControlDisabled() then
                EnableGameplayCam(true)
            end
            
            -- シネマティックモードも無効化
            SetCinematicModeActive(false)
            
            -- アイドルカメラに関連する内部設定を直接無効化（これが核心部分）
            InvalidateIdleCam()
            InvalidateVehicleIdleCam()
            
            -- RESTタイムアウトを無効化
            SetTimecycleModifier("default")
            
            Wait(0)
        end
    end)
end

-- アイドルカメラを無効化するためのキー入力をシミュレーション
if Config.SimulateInput then
    CreateThread(function()
        local simulateInterval = Config.InputInterval
        while true do
            Wait(simulateInterval)
            
            -- 軽微なカメラコントロール入力をシミュレーション（プレイヤーが操作していることをゲームに伝える）
            local currentTime = GetGameTimer()
            if (currentTime - lastInputTime) > simulateInterval * 0.8 then
                -- 非常に小さな値でカメラ移動を模倣（ほぼ見えない）
                local verySmallValue = 0.00001
                SetGameplayCamRelativePitch(0.0, verySmallValue)
                SetGameplayCamRelativeHeading(0.0)
                
                -- アイドルタイマーをリセットするための様々な介入
                DisableAllControlActions(0)
                EnableControlAction(0, 1, true) -- カメラ左右
                EnableControlAction(0, 2, true) -- カメラ上下
                
                -- 単純なボタン入力をシミュレート
                DisableControlAction(0, 0, false) -- 一瞬だけコントロールを有効に
                DisableControlAction(0, 199, false) -- 一瞬だけコントロールを有効に
                
                -- ゲームの内部アイドルタイマーをリセット
                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    -- 車両内での入力シミュレーション
                    SetVehicleHandbrake(GetVehiclePedIsIn(PlayerPedId(), false), false)
                else
                    -- 歩行中の入力シミュレーション
                    ResetPlayerStamina(PlayerId())
                end
                
                if Config.Debug then
                    print("アイドル防止のための入力をシミュレーションしました")
                end
            end
        end
    end)
end

-- カメラの設定を監視して修正
CreateThread(function()
    while true do
        Wait(Config.IdleCheckInterval)
        
        local playerPed = PlayerPedId()
        if not DoesEntityExist(playerPed) then 
            Wait(1000)
        else
            -- 現在のカメラモードを確認
            local camMode = GetFollowPedCamViewMode()
            
            -- アイドル状態でカメラがフリーモードになった場合に修正
            if camMode == 3 or camMode == 0 or isIdleActive then
                -- カメラモードをリセット
                if Config.ResetCameraOnIdle then
                    SetFollowPedCamViewMode(Config.PreferredCamMode)
                    
                    if Config.Debug then
                        print("カメラモードをリセットしました: " .. camMode .. " -> " .. Config.PreferredCamMode)
                    end
                    
                    if Config.ShowNotifications then
                        lib.notify({
                            title = 'カメラシステム',
                            description = 'アイドルカメラを防止しました',
                            type = 'inform',
                            position = 'top',
                            duration = 3000,
                        })
                    end
                end
                
                -- 他のカメラ関連の状態をリセット
                StopGameplayCamShaking(true)
                SetGameplayCamRelativeHeading(0)
                SetGameplayCamRelativePitch(0, 1.0)
                
                -- フォーカスをプレイヤーに戻す
                SetFocusEntity(playerPed)
                
                -- アイドル状態を更新
                isIdleActive = false
            end
            
            -- プレイヤーが入力したことを検知
            if IsControlPressed(0, 1) or IsControlPressed(0, 2) or 
               IsControlPressed(0, 30) or IsControlPressed(0, 31) or
               IsControlPressed(0, 32) or IsControlPressed(0, 33) or
               IsControlPressed(0, 34) or IsControlPressed(0, 35) or
               IsControlPressed(0, 24) then
                
                lastInputTime = GetGameTimer()
                isIdleActive = false
                
                if Config.Debug then
                    print("プレイヤー入力を検知: アイドル状態をリセット")
                end
            end
        end
    end
end)

-- GTA内部のスクリプトによるカメラ操作を監視して制御する（より強力な対策）
CreateThread(function()
    while true do
        local sleep = 500
        
        -- 優先度の高いカメラ操作の検出
        if IsCinematicCamRendering() or IsCinematicIdleCamRendering() or 
           IsCinematicCamShaking() or IsGameplayCamShaking() then
            
            -- シネマティックモードを無効化
            SetCinematicModeActive(false)
            StopCinematicCamShaking(true)
            StopGameplayCamShaking(true)
            
            -- カメラをリセット
            SetGameplayCamRelativeHeading(0)
            SetGameplayCamRelativePitch(0, 1.0)
            
            if Config.Debug then
                print("シネマティックカメラやシェイクを無効化しました")
            end
            
            -- アイドル状態を設定
            isIdleActive = true
            sleep = 0  -- 処理を急ぐ
        end
        
        Wait(sleep)
    end
end)

-- いくつかの追加の強制メカニズム（最後の手段）
CreateThread(function()
    while true do
        Wait(1000)
        
        -- アイドルカメラ無効化のためのさらなる対策
        if disableIdleCam then
            -- ゲーム内のアイドルタイマーを無効にするためのハック
            SetPlayerLockon(PlayerId(), true)
            SetPlayerCanUseCover(PlayerId(), true)
            
            -- スクリプトによって作成されたカメラなどを完全に無効化
            -- 注意: これは緊急措置であり、一部のゲームプレイ要素に影響する可能性あり
            if isIdleActive then
                SetGameplayCamRelativeHeading(0.0)
                ClearFocus()
                ClearTimecycleModifier()
                
                -- 特定のシーンで使われるカメラも強制的に無効化
                RenderScriptCams(false, false, 0, true, true)
                
                if Config.Debug then
                    print("追加の強制カメラリセットが適用されました")
                end
            end
        end
    end
end)

-- カメラを手動でリセットするコマンドを追加
RegisterCommand('fixcam', function()
    -- カメラを設定値にリセット
    SetFollowPedCamViewMode(Config.PreferredCamMode)
    StopGameplayCamShaking(true)
    SetGameplayCamRelativeHeading(0)
    SetGameplayCamRelativePitch(0, 1.0)
    
    lib.notify({
        title = 'カメラシステム',
        description = 'カメラをリセットしました',
        type = 'success',
        position = 'top',
        duration = 3000,
    })
    
    if Config.Debug then
        print("コマンドによるカメラリセット実行")
    end
end, false)

-- リソース開始時に実行
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    
    if Config.Debug then
        print('[ng-idlecamfix] リソースが開始されました')
    end
    
    -- カメラ設定を初期化
    SetFollowPedCamViewMode(Config.PreferredCamMode)
    StopGameplayCamShaking(true)
    lastInputTime = GetGameTimer()
end)

-- プレイヤーがロードされたとき
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    if Config.Debug then
        print('[ng-idlecamfix] プレイヤーがロードされました - カメラをリセットします')
    end
    
    -- 遅延を入れてプレイヤーが完全にロードされてから実行
    Wait(1000)
    SetFollowPedCamViewMode(Config.PreferredCamMode)
    lastInputTime = GetGameTimer()
end)