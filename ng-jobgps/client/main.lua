-- 変数の初期化
local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local isGPSActive = true -- この変数はローカルGPSの表示制御に使用
local blips = {}

-- プレイヤーデータのロード
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    -- プレイヤーが接続したらGPS状態を確認
    CheckDutyStatus()
end)

-- プレイヤーのジョブが変更された時の処理
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    local oldJob = PlayerData.job and PlayerData.job.name or nil
    local oldDuty = PlayerData.job and PlayerData.job.onduty or false
    
    -- 新しいジョブ情報を保存する前に古い情報をサーバーに送信
    if PlayerData.job then
        TriggerServerEvent('ng-jobgps:server:jobChanged', oldJob, JobInfo.name, oldDuty, JobInfo.onduty)
    end
    
    PlayerData.job = JobInfo
    
    -- ジョブが変更されたときのGPS状態の処理
    if oldJob ~= JobInfo.name or oldDuty ~= JobInfo.onduty then
        CheckDutyStatus()
    end
end)

-- デューティ状態に基づいてGPSの表示/非表示を制御
function CheckDutyStatus()
    -- プレイヤーデータが有効か確認
    if not PlayerData.job then return end
    
    local job = PlayerData.job.name
    local onDuty = PlayerData.job.onduty
    
    -- GPSを表示すべきか判断
    if Config.Permissions[job] and onDuty then
        -- オンデューティかつGPS対応ジョブならGPSを有効化
        if not isGPSActive then
            isGPSActive = true
            lib.notify({
                title = '通知',
                description = 'ジョブGPSを有効にしました',
                type = 'success'
            })
        end
        TriggerServerEvent('ng-jobgps:server:toggleGPS', true)
    else
        -- オフデューティまたは非対応ジョブならGPSを無効化
        if isGPSActive then
            isGPSActive = false
            -- ブリップをクリア
            for playerId, blip in pairs(blips) do
                if DoesBlipExist(blip) then
                    RemoveBlip(blip)
                end
            end
            blips = {}
            lib.notify({
                title = '通知',
                description = 'ジョブGPSを無効にしました',
                type = 'inform'
            })
        end
        TriggerServerEvent('ng-jobgps:server:toggleGPS', false)
    end
end

-- サーバーからのGPSデータを受け取るイベント
RegisterNetEvent('ng-jobgps:client:updateGPS', function(playersData)
    if not isGPSActive then return end
    
    -- プレイヤーデータがまだロードされていない場合はリターン
    if not PlayerData.job then return end
    
    -- 自分のジョブが設定されているか確認
    local myJob = PlayerData.job.name
    if not Config.Permissions[myJob] then return end
    
    -- オンデューティかどうか確認
    if not PlayerData.job.onduty then return end
    
    -- 追跡中のプレイヤーIDを記録
    local existingPlayers = {}
    
    -- 許可されたジョブのブリップを作成または更新
    for _, playerInfo in pairs(playersData) do
        -- 自分自身は除外
        if playerInfo.source ~= GetPlayerServerId(PlayerId()) then
            -- このジョブのブリップを表示する権限があるか確認
            if table.includes(Config.Permissions[myJob], playerInfo.job) then
                local jobConfig = Config.Jobs[playerInfo.job]
                if jobConfig then
                    local playerId = tostring(playerInfo.source)
                    existingPlayers[playerId] = true
                    
                    -- ブリップスプライトの決定
                    local blipSprite = jobConfig.blipSprite
                    
                    -- 車両に乗っている場合、車両タイプに応じたスプライトを選択
                    if playerInfo.inVehicle then
                        if playerInfo.vehicleType == "heli" then
                            blipSprite = jobConfig.heliBlipSprite
                        elseif playerInfo.vehicleType == "plane" then
                            blipSprite = jobConfig.planeBlipSprite
                        elseif playerInfo.vehicleType == "boat" then
                            blipSprite = jobConfig.boatBlipSprite
                        else -- 通常の車両
                            blipSprite = jobConfig.vehicleBlipSprite
                        end
                    end
                    
                    -- 死亡している場合
                    if playerInfo.isDead then
                        blipSprite = jobConfig.deadBlipSprite
                    end
                    
                    -- 既存のブリップがあるか確認
                    if blips[playerId] and DoesBlipExist(blips[playerId]) then
                        -- 既存のブリップを更新
                        SetBlipCoords(blips[playerId], playerInfo.coords.x, playerInfo.coords.y, playerInfo.coords.z)
                        -- スプライトも更新（状態が変わった場合）
                        SetBlipSprite(blips[playerId], blipSprite)
                        -- 重要: 色も再設定
                        SetBlipColour(blips[playerId], jobConfig.blipColor)
                        
                        -- ブリップ名も更新
                        BeginTextCommandSetBlipName("STRING")
                        AddTextComponentString(Config.DisplayOptions.showPlayerNames and (jobConfig.blipName .. " - " .. playerInfo.name) or jobConfig.blipName)
                        EndTextCommandSetBlipName(blips[playerId])
                    else
                        -- 新しいブリップを作成
                        local blip = AddBlipForCoord(playerInfo.coords.x, playerInfo.coords.y, playerInfo.coords.z)
                        SetBlipSprite(blip, blipSprite)
                        SetBlipDisplay(blip, 4)
                        SetBlipScale(blip, jobConfig.blipScale)
                        SetBlipColour(blip, jobConfig.blipColor)
                        SetBlipAsShortRange(blip, false)
                        
                        -- ブリップ名の設定
                        BeginTextCommandSetBlipName("STRING")
                        AddTextComponentString(Config.DisplayOptions.showPlayerNames and (jobConfig.blipName .. " - " .. playerInfo.name) or jobConfig.blipName)
                        EndTextCommandSetBlipName(blip)
                        
                        blips[playerId] = blip
                    end
                end
            end
        end
    end
    
    -- 不要になったブリップを削除（切断したプレイヤーなど）
    for playerId, blip in pairs(blips) do
        if not existingPlayers[playerId] and DoesBlipExist(blip) then
            RemoveBlip(blip)
            blips[playerId] = nil
        end
    end
end)

-- テーブルに値が含まれているかチェックするヘルパー関数
function table.includes(tbl, val)
    for _, v in pairs(tbl) do
        if v == val then return true end
    end
    return false
end

-- GPSのトグルメニュー
RegisterCommand(Config.UIMenu.toggleCommand, function()
    -- プレイヤーデータが有効か確認
    if not PlayerData.job then return end
    
    -- 該当するジョブかどうか確認
    local jobName = PlayerData.job.name
    if not Config.Permissions[jobName] then
        lib.notify({
            title = '通知',
            description = 'このコマンドはあなたのジョブでは使用できません',
            type = 'error'
        })
        return
    end
    
    -- オンデューティかどうか確認
    if not PlayerData.job.onduty then
        lib.notify({
            title = '通知',
            description = 'オフデューティ状態ではGPSを使用できません',
            type = 'error'
        })
        return
    end
    
    -- メニューオプションの作成
    local options = {
        {
            title = 'GPS表示設定',
            description = 'ジョブGPSの表示設定を変更します',
            icon = 'fa-solid fa-location-dot',
            onSelect = function()
                local menuOptions = {
                    {
                        title = isGPSActive and 'GPSを無効にする' or 'GPSを有効にする',
                        description = 'ジョブGPSの表示を切り替えます',
                        icon = isGPSActive and 'fa-solid fa-toggle-on' or 'fa-solid fa-toggle-off',
                        onSelect = function()
                            isGPSActive = not isGPSActive
                            -- サーバーにGPS状態を送信
                            TriggerServerEvent('ng-jobgps:server:toggleGPS', isGPSActive)
                            
                            if not isGPSActive then
                                -- GPSを無効にした場合、ブリップを削除
                                for playerId, blip in pairs(blips) do
                                    if DoesBlipExist(blip) then
                                        RemoveBlip(blip)
                                    end
                                end
                                blips = {}
                                lib.notify({
                                    title = '通知',
                                    description = 'ジョブGPSを無効にしました',
                                    type = 'inform'
                                })
                            else
                                lib.notify({
                                    title = '通知',
                                    description = 'ジョブGPSを有効にしました',
                                    type = 'success'
                                })
                                -- サーバーに最新データを要求
                                TriggerServerEvent('ng-jobgps:server:requestUpdate')
                            end
                        end
                    }
                }
                lib.registerContext({
                    id = 'gps_submenu',
                    title = 'GPS設定',
                    options = menuOptions
                })
                lib.showContext('gps_submenu')
            end
        }
    }
    
    lib.registerContext({
        id = 'job_gps_menu',
        title = Config.UIMenu.title,
        options = options
    })
    lib.showContext('job_gps_menu')
end)

-- 定期的にサーバーにプレイヤーの位置を送信
CreateThread(function()
    while true do
        if PlayerData.job and Config.Permissions[PlayerData.job.name] and PlayerData.job.onduty then
            local coords = GetEntityCoords(PlayerPedId())
            local ped = PlayerPedId()
            
            -- 車両情報の初期化
            local inVehicle = false
            local vehicleType = nil
            
            -- 車両に乗っているかチェック
            if IsPedInAnyVehicle(ped, false) then
                inVehicle = true
                local vehicle = GetVehiclePedIsIn(ped, false)
                
                -- 車両のタイプを判定
                if IsThisModelAHeli(GetEntityModel(vehicle)) then
                    vehicleType = "heli"
                elseif IsThisModelAPlane(GetEntityModel(vehicle)) then
                    vehicleType = "plane"
                elseif IsThisModelABoat(GetEntityModel(vehicle)) then
                    vehicleType = "boat"
                else
                    vehicleType = "car"
                end
            end
            
            -- 死亡しているかチェック
            local isDead = IsPlayerDead(PlayerId()) or IsPedDeadOrDying(ped, true)
            
            TriggerServerEvent('ng-jobgps:server:updatePosition', {
                x = coords.x,
                y = coords.y,
                z = coords.z
            }, inVehicle, isDead, vehicleType)
        end
        Wait(Config.DisplayOptions.refreshRate)
    end
end)

-- リソース起動時の初期化
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    PlayerData = QBCore.Functions.GetPlayerData()
    -- リソース起動時にデューティ状態を確認
    CheckDutyStatus()
end)