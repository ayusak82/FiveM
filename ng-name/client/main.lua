local QBCore = exports['qb-core']:GetCoreObject()
local nameCache = {}
local lastUpdateTime = 0
local UPDATE_INTERVAL = 10000  -- 10秒ごとに更新
local myName = nil -- 自分の名前を保存する変数
local isNameVisible = Config.DefaultVisibility -- 表示状態の変数
local isStreamerMode = false
local myNickname = nil
local useNickname = false
local myTopText = nil -- 上部テキスト用の変数を追加
local useTopText = false -- 上部テキスト表示制御用の変数を追加
local showBeginnerMark = false -- 初心者マーク表示制御用の変数を追加
local nameColor = {r = 255, g = 255, b = 255, a = 255} -- 名前の色
local topTextColor = {r = 255, g = 255, b = 255, a = 255} -- 上部テキストの色
local useCustomNameColor = false -- カスタム名前色の使用フラグ
local useCustomTopTextColor = false -- カスタム上部テキスト色の使用フラグ
local isInitialized = false -- プレイヤーの初期化処理を改善
local isPlayerReady = false -- プレイヤーの準備状態を追跡

local function InitializePlayerNames()
    if isInitialized then return end
    
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData and PlayerData.charinfo then  -- charinfoの存在チェックを追加
        local charinfo = PlayerData.charinfo
        myName = Config.NameFormat:gsub("{firstname}", charinfo.firstname):gsub("{lastname}", charinfo.lastname)
        
        -- 既存プレイヤーの情報を要求
        local players = GetActivePlayers()
        for _, playerId in ipairs(players) do
            if playerId ~= PlayerId() then
                local serverID = GetPlayerServerId(playerId)
                TriggerServerEvent('ng-name:server:getPlayerName', serverID)
            end
        end
        isInitialized = true
    end
end

-- プレイヤーの初期化チェック
local function IsPlayerFullyLoaded()
    local Player = QBCore.Functions.GetPlayerData()
    return Player and Player.charinfo ~= nil
end

-- 視認性チェック関数を追加
local function IsEntityVisible(entity1, entity2)
    return HasEntityClearLosToEntity(entity1, entity2, 17) -- 17 = すべてのオブジェクトを考慮
end

local function GetEntityHeight(entity)
    local min, max = GetModelDimensions(GetEntityModel(entity))
    return math.abs(max.z - min.z)
end

local function CalculateDisplayHeight(ped, isOtherPlayer)
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 then
        -- 車両乗車時
        local vehicleHeight = GetEntityHeight(vehicle)
        return {
            height = (vehicleHeight * 0.5) + Config.Display.height,
            spacing = isOtherPlayer and 0.15 or 0.15  -- 他プレイヤー視点なら広めに
        }
    else
        -- 徒歩時
        return {
            height = Config.Display.height,
            spacing = isOtherPlayer and 0.1 or 0.1  -- 他プレイヤー視点なら広めに
        }
    end
end

-- 名前表示の処理（初心者マーク設定チェック対応）
local function DrawText3D(x, y, z, text, isStreamer, isBeginner, showNameText, customNameColor, useCustomColor)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    
    if onScreen then
        SetTextScale(Config.Display.scale, Config.Display.scale)
        SetTextFont(Config.Display.font)
        SetTextProportional(true)
        
        -- 色の設定（カスタム色が有効で設定されている場合はそれを使用）
        if useCustomColor and customNameColor then
            SetTextColour(customNameColor.r, customNameColor.g, customNameColor.b, customNameColor.a)
        else
            SetTextColour(Config.Display.color.r, Config.Display.color.g, Config.Display.color.b, Config.Display.color.a)
        end
        
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(true)
        
        -- 表示テキストの構築
        local displayText = ""
        
        -- 名前テキストの追加（表示設定がオンの場合のみ）
        if showNameText then
            displayText = text
        end
        
        -- マークの追加（名前の表示状態に関係なく表示）
        if isStreamer then
            if displayText ~= "" then
                displayText = displayText .. ' ' .. Config.StreamerMode.icon
            else
                displayText = Config.StreamerMode.icon
            end
        end
        
        -- 初心者マークの追加（設定が有効で、表示条件を満たす場合のみ）
        if isBeginner and Config.BeginnerMark.enabled then
            if displayText ~= "" then
                displayText = displayText .. ' ' .. Config.BeginnerMark.icon
            else
                displayText = Config.BeginnerMark.icon
            end
        end
        
        -- 何か表示するものがある場合のみ描画
        if displayText ~= "" then
            AddTextComponentString(displayText)
            DrawText(_x, _y)
            return _y -- Y座標を返す
        end
    end
    return nil
end

-- 上部テキスト表示の処理を追加
local function DrawTopText3D(x, y, z, text, baseY, customTopTextColor, useCustomTopColor)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    
    if onScreen then
        -- baseYからの固定オフセットを適用
        _y = baseY - 0.025 -- スクリーン座標での固定オフセット

        SetTextScale(Config.Display.scale, Config.Display.scale)
        SetTextFont(Config.Display.font)
        SetTextProportional(true)
        
        -- 色の設定（カスタム色が有効で設定されている場合はそれを使用）
        if useCustomTopColor and customTopTextColor then
            SetTextColour(customTopTextColor.r, customTopTextColor.g, customTopTextColor.b, customTopTextColor.a)
        else
            SetTextColour(Config.TopText.color.r, Config.TopText.color.g, Config.TopText.color.b, Config.TopText.color.a)
        end
        
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- UIメニューを更新（初心者マーク設定を追加）
local function createNameplateMenu()
    local menuOptions = {
        {
            title = '表示設定',
            description = '自分の名前を他プレイヤーから見えるようにするかを設定します',
            icon = isNameVisible and 'fa-solid fa-eye' or 'fa-solid fa-eye-slash',
            iconColor = isNameVisible and '#4ade80' or '#ef4444',
            onSelect = function()
                isNameVisible = not isNameVisible
                TriggerServerEvent('ng-name:server:updateVisibility', isNameVisible)
                
                lib.notify({
                    title = 'ネームプレート',
                    description = isNameVisible and '名前を表示します' or '名前を非表示にします',
                    type = isNameVisible and 'success' or 'inform',
                    position = Config.UI.position
                })
                
                -- メニューを再表示
                createNameplateMenu()
                lib.showContext('nameplate_menu')
            end
        },
        {
            title = '配信者モード',
            description = '配信者モードをオン/オフにします',
            icon = isStreamerMode and 'fa-solid fa-broadcast-tower' or 'fa-solid fa-tower-broadcast',
            iconColor = isStreamerMode and '#3b82f6' or '#6b7280',
            onSelect = function()
                isStreamerMode = not isStreamerMode
                TriggerServerEvent('ng-name:server:updateStreamerMode', isStreamerMode)
                
                lib.notify({
                    title = 'ネームプレート',
                    description = isStreamerMode and '配信者モードをオンにしました' or '配信者モードをオフにしました',
                    type = isStreamerMode and 'success' or 'inform',
                    position = Config.UI.position
                })
                
                -- メニューを再表示
                createNameplateMenu()
                lib.showContext('nameplate_menu')
            end
        }
    }

    -- 初心者マーク設定を条件付きで追加
    if Config.BeginnerMark.enabled then
        table.insert(menuOptions, {
            title = '初心者マーク',
            description = '初心者マークの表示/非表示を切り替えます',
            icon = showBeginnerMark and 'fa-solid fa-graduation-cap' or 'fa-solid fa-user-graduate',
            iconColor = showBeginnerMark and '#f59e0b' or '#6b7280',
            onSelect = function()
                showBeginnerMark = not showBeginnerMark
                TriggerServerEvent('ng-name:server:updateBeginnerMark', showBeginnerMark)
                
                lib.notify({
                    title = 'ネームプレート',
                    description = showBeginnerMark and '初心者マークを表示します' or '初心者マークを非表示にします',
                    type = showBeginnerMark and 'success' or 'inform',
                    position = Config.UI.position
                })
                
                -- メニューを再表示
                createNameplateMenu()
                lib.showContext('nameplate_menu')
            end
        })
    end

    -- 残りのメニュー項目を追加
    local additionalOptions = {
        {
            title = 'ニックネーム表示切替',
            description = 'ニックネームと本名の表示を切り替えます',
            icon = useNickname and 'fa-solid fa-id-badge' or 'fa-solid fa-id-card',
            iconColor = useNickname and '#10b981' or '#6b7280',
            onSelect = function()
                useNickname = not useNickname
                TriggerServerEvent('ng-name:server:toggleNickname', useNickname)
                
                lib.notify({
                    title = 'ネームプレート',
                    description = useNickname and 'ニックネームを表示します' or '本名を表示します',
                    type = 'success',
                    position = Config.UI.position
                })
                
                -- メニューを再表示
                createNameplateMenu()
                lib.showContext('nameplate_menu')
            end
        },
        {
            title = 'ニックネーム設定',
            description = 'ニックネームを設定します',
            icon = 'fa-solid fa-pen-to-square',
            iconColor = '#8b5cf6',
            onSelect = function()
                local input = lib.inputDialog('ニックネーム設定', {
                    {
                        type = 'input',
                        label = 'ニックネーム',
                        default = myNickname or '', -- 現在の値を表示
                        description = string.format('0-%d文字で入力してください', Config.Nickname.maxLength)
                    }
                })

                if input and input[1] then
                    TriggerServerEvent('ng-name:server:updateNickname', input[1])
                    -- 即座にローカル変数を更新（サーバーからの応答を待たずに）
                    myNickname = input[1]
                    
                    -- メニューを再表示
                    createNameplateMenu()
                    lib.showContext('nameplate_menu')
                else
                    -- キャンセルされた場合もメニューを再表示
                    lib.showContext('nameplate_menu')
                end
            end
        },
        {
            title = '上部テキスト表示切替',
            description = '上部テキストの表示/非表示を切り替えます',
            icon = useTopText and 'fa-solid fa-toggle-on' or 'fa-solid fa-toggle-off',
            iconColor = useTopText and '#06b6d4' or '#6b7280',
            onSelect = function()
                useTopText = not useTopText
                TriggerServerEvent('ng-name:server:toggleTopText', useTopText)
                
                lib.notify({
                    title = 'ネームプレート',
                    description = useTopText and '上部テキストを表示します' or '上部テキストを非表示にします',
                    type = 'success',
                    position = Config.UI.position
                })
                
                -- メニューを再表示
                createNameplateMenu()
                lib.showContext('nameplate_menu')
            end
        },
        {
            title = '上部テキスト設定',
            description = '名前の上に表示するテキストを設定します',
            icon = 'fa-solid fa-text-height',
            iconColor = '#ec4899',
            onSelect = function()
                local input = lib.inputDialog('上部テキスト設定', {
                    {
                        type = 'input',
                        label = '上部テキスト',
                        default = myTopText or '',
                        description = string.format('0-%d文字で入力してください', Config.TopText.maxLength)
                    }
                })

                if input then
                    TriggerServerEvent('ng-name:server:updateTopText', input[1])
                    
                    -- メニューを再表示
                    createNameplateMenu()
                    lib.showContext('nameplate_menu')
                else
                    -- キャンセルされた場合もメニューを再表示
                    lib.showContext('nameplate_menu')
                end
            end
        },
        {
            title = '名前の色設定',
            description = '名前の文字色をカスタマイズします',
            icon = 'fa-solid fa-palette',
            iconColor = '#f59e0b',
            onSelect = function()
                local input = lib.inputDialog('名前の色設定', {
                    {
                        type = 'color',
                        label = '名前の色',
                        default = string.format("#%02x%02x%02x", nameColor.r, nameColor.g, nameColor.b),
                        format = 'hex'
                    }
                })

                if input and input[1] then
                    -- HEX値をRGBに変換
                    local hex = input[1]:gsub("#", "")
                    local r = tonumber(hex:sub(1,2), 16) or 255
                    local g = tonumber(hex:sub(3,4), 16) or 255
                    local b = tonumber(hex:sub(5,6), 16) or 255
                    
                    nameColor = {r = r, g = g, b = b, a = 255}
                    useCustomNameColor = true
                    
                    TriggerServerEvent('ng-name:server:updateNameColor', nameColor, useCustomNameColor)
                    
                    lib.notify({
                        title = 'ネームプレート',
                        description = '名前の色を変更しました',
                        type = 'success',
                        position = Config.UI.position
                    })
                    
                    -- メニューを再表示
                    createNameplateMenu()
                    lib.showContext('nameplate_menu')
                else
                    -- キャンセルされた場合もメニューを再表示
                    lib.showContext('nameplate_menu')
                end
            end
        },
        {
            title = '上部テキストの色設定',
            description = '上部テキストの文字色をカスタマイズします',
            icon = 'fa-solid fa-palette',
            iconColor = '#ec4899',
            onSelect = function()
                local input = lib.inputDialog('上部テキストの色設定', {
                    {
                        type = 'color',
                        label = '上部テキストの色',
                        default = string.format("#%02x%02x%02x", topTextColor.r, topTextColor.g, topTextColor.b),
                        format = 'hex'
                    }
                })

                if input and input[1] then
                    -- HEX値をRGBに変換
                    local hex = input[1]:gsub("#", "")
                    local r = tonumber(hex:sub(1,2), 16) or 255
                    local g = tonumber(hex:sub(3,4), 16) or 255
                    local b = tonumber(hex:sub(5,6), 16) or 255
                    
                    topTextColor = {r = r, g = g, b = b, a = 255}
                    useCustomTopTextColor = true
                    
                    TriggerServerEvent('ng-name:server:updateTopTextColor', topTextColor, useCustomTopTextColor)
                    
                    lib.notify({
                        title = 'ネームプレート',
                        description = '上部テキストの色を変更しました',
                        type = 'success',
                        position = Config.UI.position
                    })
                    
                    -- メニューを再表示
                    createNameplateMenu()
                    lib.showContext('nameplate_menu')
                else
                    -- キャンセルされた場合もメニューを再表示
                    lib.showContext('nameplate_menu')
                end
            end
        },
        {
            title = '名前色リセット',
            description = '名前の色をデフォルトに戻します',
            icon = 'fa-solid fa-undo',
            iconColor = '#6b7280',
            onSelect = function()
                nameColor = {r = Config.Display.color.r, g = Config.Display.color.g, b = Config.Display.color.b, a = Config.Display.color.a}
                useCustomNameColor = false
                
                TriggerServerEvent('ng-name:server:updateNameColor', nameColor, useCustomNameColor)
                
                lib.notify({
                    title = 'ネームプレート',
                    description = '名前の色をリセットしました',
                    type = 'success',
                    position = Config.UI.position
                })
                
                -- メニューを再表示
                createNameplateMenu()
                lib.showContext('nameplate_menu')
            end
        },
        {
            title = '上部テキスト色リセット',
            description = '上部テキストの色をデフォルトに戻します',
            icon = 'fa-solid fa-undo',
            iconColor = '#6b7280',
            onSelect = function()
                topTextColor = {r = Config.TopText.color.r, g = Config.TopText.color.g, b = Config.TopText.color.b, a = Config.TopText.color.a}
                useCustomTopTextColor = false
                
                TriggerServerEvent('ng-name:server:updateTopTextColor', topTextColor, useCustomTopTextColor)
                
                lib.notify({
                    title = 'ネームプレート',
                    description = '上部テキストの色をリセットしました',
                    type = 'success',
                    position = Config.UI.position
                })
                
                -- メニューを再表示
                createNameplateMenu()
                lib.showContext('nameplate_menu')
            end
        }
    }

    -- 追加オプションを基本メニューに結合
    for _, option in ipairs(additionalOptions) do
        table.insert(menuOptions, option)
    end

    lib.registerContext({
        id = 'nameplate_menu',
        title = 'ネームプレート設定',
        options = menuOptions
    })
end

-- コマンドの登録
RegisterCommand(Config.Command, function()
    lib.showContext('nameplate_menu')
end)

-- プレイヤーの初期設定
CreateThread(function()
    while not QBCore.Functions.GetPlayerData() do
        Wait(1000)
    end
    
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData and PlayerData.charinfo then  -- charinfoの存在チェックを追加
        local charinfo = PlayerData.charinfo
        myName = Config.NameFormat:gsub("{firstname}", charinfo.firstname):gsub("{lastname}", charinfo.lastname)
        
        createNameplateMenu()
        TriggerEvent('chat:addSuggestion', '/' .. Config.Command, 'ネームプレートの設定を開きます')

        local src = GetPlayerServerId(PlayerId())
        TriggerServerEvent('ng-name:server:getPlayerName', src)
    end
end)

-- メインループ部分のみを表示
CreateThread(function()
    while true do
        if not isPlayerReady then
            local PlayerData = QBCore.Functions.GetPlayerData()
            if PlayerData and PlayerData.charinfo then  -- charinfoの存在チェックを追加
                isPlayerReady = true
                local charinfo = PlayerData.charinfo
                myName = Config.NameFormat:gsub("{firstname}", charinfo.firstname):gsub("{lastname}", charinfo.lastname)
                
                createNameplateMenu()
                TriggerEvent('chat:addSuggestion', '/' .. Config.Command, 'ネームプレートの設定を開きます')
                
                local src = GetPlayerServerId(PlayerId())
                TriggerServerEvent('ng-name:server:getPlayerName', src)
            end
            Wait(1000)
            goto continue
        end

        local sleep = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local currentTime = GetGameTimer()
        
        -- 自分の名前と上部テキストの表示
        -- マーク類は名前の表示状態に関係なく表示
        if myName and (isNameVisible or isStreamerMode or (showBeginnerMark and Config.BeginnerMark.enabled)) then
            local displayHeight = CalculateDisplayHeight(playerPed)
            local displayName = useNickname and myNickname or myName
            
            local nameCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 0.0, displayHeight.height)
            local baseY = DrawText3D(nameCoords.x, nameCoords.y, nameCoords.z, displayName, isStreamerMode, showBeginnerMark, isNameVisible, nameColor, useCustomNameColor)
            
            if baseY and useTopText and myTopText and isNameVisible then
                local topCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 0.0, displayHeight.height)
                DrawTopText3D(topCoords.x, topCoords.y, topCoords.z, myTopText, baseY, topTextColor, useCustomTopTextColor)
            end
            
            sleep = 0
        end

        -- 他プレイヤーの名前表示（パフォーマンス最適化）
        local players = GetActivePlayers()
        if #players > 0 then
            for _, playerId in ipairs(players) do
                if playerId ~= PlayerId() then
                    local targetPed = GetPlayerPed(playerId)
                    if DoesEntityExist(targetPed) then
                        local targetCoords = GetEntityCoords(targetPed)
                        local distance = #(playerCoords - targetCoords)

                        if distance <= Config.Display.distance then
                            local playerServerId = GetPlayerServerId(playerId)
                            if nameCache[playerServerId] and (nameCache[playerServerId].visible or nameCache[playerServerId].streamer or (nameCache[playerServerId].beginnerMark and Config.BeginnerMark.enabled)) then
                                -- 視認性チェックは近い距離でのみ行う
                                if distance > 5.0 or IsEntityVisible(playerPed, targetPed) then
                                    local displayHeight = CalculateDisplayHeight(targetPed)
                                    
                                    local nameCoords = GetOffsetFromEntityInWorldCoords(targetPed, 0.0, 0.0, displayHeight.height)
                                    local displayName = nameCache[playerServerId].useNickname and nameCache[playerServerId].nickname or nameCache[playerServerId].name
                                    local baseY = DrawText3D(nameCoords.x, nameCoords.y, nameCoords.z, displayName, nameCache[playerServerId].streamer, nameCache[playerServerId].beginnerMark, nameCache[playerServerId].visible, nameCache[playerServerId].nameColor, nameCache[playerServerId].useCustomNameColor)
                                    
                                    if baseY and nameCache[playerServerId].useTopText and nameCache[playerServerId].topText and nameCache[playerServerId].visible then
                                        local topCoords = GetOffsetFromEntityInWorldCoords(targetPed, 0.0, 0.0, displayHeight.height)
                                        DrawTopText3D(topCoords.x, topCoords.y, topCoords.z, nameCache[playerServerId].topText, baseY, nameCache[playerServerId].topTextColor, nameCache[playerServerId].useCustomTopTextColor)
                                    end

                                    sleep = 0
                                end
                            end
                        end
                    end
                end
            end
        end

        Wait(sleep)
        ::continue::
    end
end)

-- イベントハンドラーを修正（初心者マーク対応）
RegisterNetEvent('ng-name:client:displayName', function(targetId, firstname, lastname, nickname, useNick, streamerMode, topText, useTop, beginnerMark, nameColorData, topTextColorData)
    local displayName = Config.NameFormat:gsub("{firstname}", firstname):gsub("{lastname}", lastname)
    
    nameCache[targetId] = nameCache[targetId] or {}
    nameCache[targetId] = {
        name = displayName,
        nickname = nickname,
        useNickname = useNick,
        streamer = streamerMode,
        topText = topText,
        useTopText = useTop,
        beginnerMark = beginnerMark, -- 初心者マーク情報を追加
        nameColor = nameColorData and nameColorData.color or {r = 255, g = 255, b = 255, a = 255},
        useCustomNameColor = nameColorData and nameColorData.enabled or false,
        topTextColor = topTextColorData and topTextColorData.color or {r = 255, g = 255, b = 255, a = 255},
        useCustomTopTextColor = topTextColorData and topTextColorData.enabled or false,
        visible = true
    }
end)

RegisterNetEvent('ng-name:client:loadSettings', function(visibility, streamerMode, nickname, useNick, topText, useTop, beginnerMark, nameColorData, topTextColorData)
    isNameVisible = visibility
    isStreamerMode = streamerMode
    myNickname = nickname
    useNickname = useNick
    myTopText = topText
    useTopText = useTop
    showBeginnerMark = beginnerMark -- 初心者マーク設定を追加
    
    -- 色設定の読み込み
    if nameColorData then
        nameColor = nameColorData.color or {r = 255, g = 255, b = 255, a = 255}
        useCustomNameColor = nameColorData.enabled or false
    end
    
    if topTextColorData then
        topTextColor = topTextColorData.color or {r = 255, g = 255, b = 255, a = 255}
        useCustomTopTextColor = topTextColorData.enabled or false
    end
    
    local myServerId = GetPlayerServerId(PlayerId())
    if nameCache[myServerId] then
        nameCache[myServerId].streamer = streamerMode
        nameCache[myServerId].nickname = nickname
        nameCache[myServerId].useNickname = useNick
        nameCache[myServerId].topText = topText
        nameCache[myServerId].useTopText = useTop
        nameCache[myServerId].beginnerMark = beginnerMark
        nameCache[myServerId].nameColor = nameColor
        nameCache[myServerId].useCustomNameColor = useCustomNameColor
        nameCache[myServerId].topTextColor = topTextColor
        nameCache[myServerId].useCustomTopTextColor = useCustomTopTextColor
        nameCache[myServerId].visible = visibility
    end
    
    createNameplateMenu()
end)

-- 色設定同期イベントを追加
RegisterNetEvent('ng-name:client:syncNameColor', function(playerId, colorData)
    if nameCache[playerId] then
        nameCache[playerId].nameColor = colorData.color
        nameCache[playerId].useCustomNameColor = colorData.enabled
    end
    
    -- 自分の場合はローカル変数も更新
    if playerId == GetPlayerServerId(PlayerId()) then
        nameColor = colorData.color
        useCustomNameColor = colorData.enabled
    end
end)

RegisterNetEvent('ng-name:client:syncTopTextColor', function(playerId, colorData)
    if nameCache[playerId] then
        nameCache[playerId].topTextColor = colorData.color
        nameCache[playerId].useCustomTopTextColor = colorData.enabled
    end
    
    -- 自分の場合はローカル変数も更新
    if playerId == GetPlayerServerId(PlayerId()) then
        topTextColor = colorData.color
        useCustomTopTextColor = colorData.enabled
    end
end)
RegisterNetEvent('ng-name:client:syncBeginnerMark', function(playerId, enabled)
    if nameCache[playerId] then
        nameCache[playerId].beginnerMark = enabled
    end
    
    -- 自分の場合はローカル変数も更新
    if playerId == GetPlayerServerId(PlayerId()) then
        showBeginnerMark = enabled
    end
end)

-- 上部テキスト関連のイベントを追加
RegisterNetEvent('ng-name:client:syncTopText', function(playerId, text)
    if nameCache[playerId] then
        nameCache[playerId].topText = text
    end
    
    -- 自分の場合はローカル変数も更新
    if playerId == GetPlayerServerId(PlayerId()) then
        myTopText = text
    end
end)

RegisterNetEvent('ng-name:client:syncTopTextToggle', function(playerId, useTop)
    if nameCache[playerId] then
        nameCache[playerId].useTopText = useTop
    end
    
    -- 自分の場合はローカル変数も更新
    if playerId == GetPlayerServerId(PlayerId()) then
        useTopText = useTop
    end
end)

-- 既存のイベントはそのまま維持
RegisterNetEvent('ng-name:client:syncVisibility', function(playerId, visibility)
    if playerId == GetPlayerServerId(PlayerId()) then
        isNameVisible = visibility
    end
    
    -- 名前の可視性が変更されても、キャッシュ自体は維持
    if nameCache[playerId] then
        nameCache[playerId].visible = visibility
    else
        -- キャッシュが存在しない場合は、プレイヤー情報を要求
        TriggerServerEvent('ng-name:server:getPlayerName', playerId)
    end
end)

RegisterNetEvent('ng-name:client:syncStreamerMode', function(playerId, enabled)
    if nameCache[playerId] then
        nameCache[playerId].streamer = enabled
    end
end)

RegisterNetEvent('ng-name:client:syncNickname', function(playerId, nickname)
    if nameCache[playerId] then
        nameCache[playerId].nickname = nickname
    end
    
    -- 自分の場合はローカル変数も更新
    if playerId == GetPlayerServerId(PlayerId()) then
        myNickname = nickname
    end
end)

RegisterNetEvent('ng-name:client:syncNicknameToggle', function(playerId, useNick)
    if nameCache[playerId] then
        nameCache[playerId].useNickname = useNick
    end
    
    -- 自分の場合はローカル変数も更新
    if playerId == GetPlayerServerId(PlayerId()) then
        useNickname = useNick
    end
end)

-- プレイヤーロード時の処理を修正
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData and PlayerData.charinfo then  -- charinfoの存在チェックを追加
        local charinfo = PlayerData.charinfo
        myName = Config.NameFormat:gsub("{firstname}", charinfo.firstname):gsub("{lastname}", charinfo.lastname)
        
        local src = GetPlayerServerId(PlayerId())
        TriggerServerEvent('ng-name:server:getPlayerName', src)
        
        InitializePlayerNames()
        createNameplateMenu()
    end
end)

-- プレイヤーがスポーンした時の処理を追加
AddEventHandler('playerSpawned', function()
    Wait(1000)
    InitializePlayerNames()
end)

-- リソース開始時の処理を追加
AddEventHandler('onClientResourceStart', function(resourceName)
    if(GetCurrentResourceName() ~= resourceName) then
        return
    end
    Wait(1000)
    InitializePlayerNames()
end)

-- 新しいプレイヤーが参加した時の処理を追加
RegisterNetEvent('QBCore:Client:OnPlayerJoined', function()
    Wait(1000)
    InitializePlayerNames()
end)

-- 定期的な更新処理を追加
CreateThread(function()
    while true do
        Wait(10000) -- 10秒ごとに更新
        
        -- オンラインプレイヤーの情報を更新
        local players = GetActivePlayers()
        for _, playerId in ipairs(players) do
            if playerId ~= PlayerId() then
                local serverID = GetPlayerServerId(playerId)
                if not nameCache[serverID] then
                    TriggerServerEvent('ng-name:server:getPlayerName', serverID)
                end
            end
        end
    end
end)

-- キャラクター選択解除時のクリーンアップ
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    isPlayerReady = false
    isInitialized = false
    myName = nil
    nameCache = {}
end)

-- 他のスクリプトからメニューを開くためのイベント
RegisterNetEvent('ng-name:client:openMenu', function()
    lib.showContext('nameplate_menu')
end)