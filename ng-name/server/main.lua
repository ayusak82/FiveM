local QBCore = exports['qb-core']:GetCoreObject()
local playerVisibility = {}

-- データベーステーブル作成（初心者マーク対応）
MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `nameplate_settings` (
            `citizenid` varchar(50) NOT NULL,
            `visibility` boolean DEFAULT true,
            `streamer_mode` boolean DEFAULT false,
            `nickname` varchar(100) DEFAULT NULL,
            `use_nickname` boolean DEFAULT false,
            `top_text` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
            `use_top_text` boolean DEFAULT false,
            `show_beginner_mark` boolean DEFAULT false,
            `name_color_r` int DEFAULT 255,
            `name_color_g` int DEFAULT 255,
            `name_color_b` int DEFAULT 255,
            `name_color_a` int DEFAULT 255,
            `use_custom_name_color` boolean DEFAULT false,
            `top_text_color_r` int DEFAULT 255,
            `top_text_color_g` int DEFAULT 255,
            `top_text_color_b` int DEFAULT 255,
            `top_text_color_a` int DEFAULT 255,
            `use_custom_top_text_color` boolean DEFAULT false,
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`)
        )
    ]])
end)

-- プレイヤー設定を取得する関数
local function GetPlayerSettings(citizenid)
    local result = MySQL.query.await('SELECT * FROM nameplate_settings WHERE citizenid = ?', {
        citizenid
    })
    
    if not result or not result[1] then
        return false
    end
    return result[1]
end

-- プレイヤー設定を更新する関数
local function UpdatePlayerSettings(citizenid, settings)
    -- boolean値を明示的に設定
    local params = {
        citizenid,                              -- 1
        settings.visibility == true,            -- 2
        settings.streamerMode == true,          -- 3
        settings.nickname,                      -- 4
        settings.useNickname == true,           -- 5
        settings.topText,                       -- 6
        settings.useTopText == true,            -- 7
        settings.showBeginnerMark == true,      -- 8
        settings.nameColor and settings.nameColor.r or 255,   -- 9
        settings.nameColor and settings.nameColor.g or 255,   -- 10
        settings.nameColor and settings.nameColor.b or 255,   -- 11
        settings.nameColor and settings.nameColor.a or 255,   -- 12
        settings.useCustomNameColor == true,    -- 13
        settings.topTextColor and settings.topTextColor.r or 255, -- 14
        settings.topTextColor and settings.topTextColor.g or 255, -- 15
        settings.topTextColor and settings.topTextColor.b or 255, -- 16
        settings.topTextColor and settings.topTextColor.a or 255, -- 17
        settings.useCustomTopTextColor == true  -- 18
    }

    local success = MySQL.query.await([[
        INSERT INTO nameplate_settings 
        (citizenid, visibility, streamer_mode, nickname, use_nickname, top_text, use_top_text, show_beginner_mark,
         name_color_r, name_color_g, name_color_b, name_color_a, use_custom_name_color,
         top_text_color_r, top_text_color_g, top_text_color_b, top_text_color_a, use_custom_top_text_color) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) 
        ON DUPLICATE KEY UPDATE 
        visibility = ?,
        streamer_mode = ?,
        nickname = ?,
        use_nickname = ?,
        top_text = ?,
        use_top_text = ?,
        show_beginner_mark = ?,
        name_color_r = ?,
        name_color_g = ?,
        name_color_b = ?,
        name_color_a = ?,
        use_custom_name_color = ?,
        top_text_color_r = ?,
        top_text_color_g = ?,
        top_text_color_b = ?,
        top_text_color_a = ?,
        use_custom_top_text_color = ?
    ]], {
        -- 追加用パラメータ
        params[1], params[2], params[3], params[4], params[5], params[6], params[7], params[8],
        params[9], params[10], params[11], params[12], params[13], params[14], params[15], params[16], params[17], params[18],
        -- 更新用パラメータ
        params[2], params[3], params[4], params[5], params[6], params[7], params[8],
        params[9], params[10], params[11], params[12], params[13], params[14], params[15], params[16], params[17], params[18]
    })
    
    return success
end

-- 初心者かどうかをチェックする関数
local function IsPlayerBeginner(Player)
    if not Config.BeginnerMark.enabled then
        return false
    end
    
    -- プレイタイムをチェック（分単位）
    local playtime = Player.PlayerData.metadata.playtime or 0
    return playtime < Config.BeginnerMark.maxPlayTime
end

-- 名前の色設定更新イベント
RegisterNetEvent('ng-name:server:updateNameColor', function(color, enabled)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local currentSettings = GetPlayerSettings(Player.PlayerData.citizenid) or {}
        
        local settings = {
            visibility = currentSettings.visibility,
            streamerMode = currentSettings.streamer_mode,
            nickname = currentSettings.nickname,
            useNickname = currentSettings.use_nickname,
            topText = currentSettings.top_text,
            useTopText = currentSettings.use_top_text,
            showBeginnerMark = currentSettings.show_beginner_mark,
            nameColor = color,
            useCustomNameColor = enabled,
            topTextColor = {
                r = currentSettings.top_text_color_r or 255,
                g = currentSettings.top_text_color_g or 255,
                b = currentSettings.top_text_color_b or 255,
                a = currentSettings.top_text_color_a or 255
            },
            useCustomTopTextColor = currentSettings.use_custom_top_text_color
        }
        
        UpdatePlayerSettings(Player.PlayerData.citizenid, settings)
        TriggerClientEvent('ng-name:client:syncNameColor', -1, src, {color = color, enabled = enabled})
    end
end)

-- 上部テキストの色設定更新イベント
RegisterNetEvent('ng-name:server:updateTopTextColor', function(color, enabled)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local currentSettings = GetPlayerSettings(Player.PlayerData.citizenid) or {}
        
        local settings = {
            visibility = currentSettings.visibility,
            streamerMode = currentSettings.streamer_mode,
            nickname = currentSettings.nickname,
            useNickname = currentSettings.use_nickname,
            topText = currentSettings.top_text,
            useTopText = currentSettings.use_top_text,
            showBeginnerMark = currentSettings.show_beginner_mark,
            nameColor = {
                r = currentSettings.name_color_r or 255,
                g = currentSettings.name_color_g or 255,
                b = currentSettings.name_color_b or 255,
                a = currentSettings.name_color_a or 255
            },
            useCustomNameColor = currentSettings.use_custom_name_color,
            topTextColor = color,
            useCustomTopTextColor = enabled
        }
        
        UpdatePlayerSettings(Player.PlayerData.citizenid, settings)
        TriggerClientEvent('ng-name:client:syncTopTextColor', -1, src, {color = color, enabled = enabled})
    end
end)

-- 初心者マーク設定更新イベント（設定が無効な場合の処理を追加）
RegisterNetEvent('ng-name:server:updateBeginnerMark', function(showMark)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        -- 初心者マーク機能が無効な場合は処理しない
        if not Config.BeginnerMark.enabled then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'エラー',
                description = '初心者マーク機能は無効になっています',
                type = 'error'
            })
            return
        end

        local currentSettings = GetPlayerSettings(Player.PlayerData.citizenid) or {}
        
        -- 現在の設定を全て維持しながら、showBeginnerMarkのみを更新
        local settings = {
            visibility = currentSettings.visibility,
            streamerMode = currentSettings.streamer_mode,
            nickname = currentSettings.nickname,
            useNickname = currentSettings.use_nickname,
            topText = currentSettings.top_text,
            useTopText = currentSettings.use_top_text,
            showBeginnerMark = showMark,
            nameColor = {
                r = currentSettings.name_color_r or 255,
                g = currentSettings.name_color_g or 255,
                b = currentSettings.name_color_b or 255,
                a = currentSettings.name_color_a or 255
            },
            useCustomNameColor = currentSettings.use_custom_name_color,
            topTextColor = {
                r = currentSettings.top_text_color_r or 255,
                g = currentSettings.top_text_color_g or 255,
                b = currentSettings.top_text_color_b or 255,
                a = currentSettings.top_text_color_a or 255
            },
            useCustomTopTextColor = currentSettings.use_custom_top_text_color
        }
        
        UpdatePlayerSettings(Player.PlayerData.citizenid, settings)
        TriggerClientEvent('ng-name:client:syncBeginnerMark', -1, src, showMark)
    end
end)

-- ニックネーム更新イベント
RegisterNetEvent('ng-name:server:updateNickname', function(nickname)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        if #nickname < Config.Nickname.minLength or #nickname > Config.Nickname.maxLength then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'エラー',
                description = string.format('ニックネームは%d-%d文字で設定してください', Config.Nickname.minLength, Config.Nickname.maxLength),
                type = 'error'
            })
            return
        end

        -- 現在の設定を取得
        local currentSettings = GetPlayerSettings(Player.PlayerData.citizenid) or {}
        
        -- 現在の設定を全て維持しながら、nicknameのみを更新
        local settings = {
            visibility = currentSettings.visibility,
            streamerMode = currentSettings.streamer_mode,
            nickname = nickname,
            useNickname = currentSettings.use_nickname,
            topText = currentSettings.top_text,
            useTopText = currentSettings.use_top_text,
            showBeginnerMark = currentSettings.show_beginner_mark,
            nameColor = {
                r = currentSettings.name_color_r or 255,
                g = currentSettings.name_color_g or 255,
                b = currentSettings.name_color_b or 255,
                a = currentSettings.name_color_a or 255
            },
            useCustomNameColor = currentSettings.use_custom_name_color,
            topTextColor = {
                r = currentSettings.top_text_color_r or 255,
                g = currentSettings.top_text_color_g or 255,
                b = currentSettings.top_text_color_b or 255,
                a = currentSettings.top_text_color_a or 255
            },
            useCustomTopTextColor = currentSettings.use_custom_top_text_color
        }
        
        UpdatePlayerSettings(Player.PlayerData.citizenid, settings)
        TriggerClientEvent('ng-name:client:syncNickname', -1, src, nickname)
    end
end)

RegisterNetEvent('ng-name:server:toggleNickname', function(useNickname)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        -- 現在の設定を取得
        local currentSettings = GetPlayerSettings(Player.PlayerData.citizenid) or {}
        
        -- 現在の設定を全て維持しながら、useNicknameのみを更新
        local settings = {
            visibility = currentSettings.visibility,
            streamerMode = currentSettings.streamer_mode,
            nickname = currentSettings.nickname,
            useNickname = useNickname,
            topText = currentSettings.top_text,
            useTopText = currentSettings.use_top_text,
            showBeginnerMark = currentSettings.show_beginner_mark,
            nameColor = {
                r = currentSettings.name_color_r or 255,
                g = currentSettings.name_color_g or 255,
                b = currentSettings.name_color_b or 255,
                a = currentSettings.name_color_a or 255
            },
            useCustomNameColor = currentSettings.use_custom_name_color,
            topTextColor = {
                r = currentSettings.top_text_color_r or 255,
                g = currentSettings.top_text_color_g or 255,
                b = currentSettings.top_text_color_b or 255,
                a = currentSettings.top_text_color_a or 255
            },
            useCustomTopTextColor = currentSettings.use_custom_top_text_color
        }
        
        UpdatePlayerSettings(Player.PlayerData.citizenid, settings)
        TriggerClientEvent('ng-name:client:syncNicknameToggle', -1, src, useNickname)
    end
end)

-- 上部テキスト更新イベント（色情報も保持するように修正）
RegisterNetEvent('ng-name:server:updateTopText', function(text)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        if #text < Config.TopText.minLength or #text > Config.TopText.maxLength then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'エラー',
                description = string.format('上部テキストは%d-%d文字で設定してください', Config.TopText.minLength, Config.TopText.maxLength),
                type = 'error'
            })
            return
        end

        local currentSettings = GetPlayerSettings(Player.PlayerData.citizenid) or {}
        
        local settings = {
            visibility = currentSettings.visibility,
            streamerMode = currentSettings.streamer_mode,
            nickname = currentSettings.nickname,
            useNickname = currentSettings.use_nickname,
            topText = text,
            useTopText = currentSettings.use_top_text,
            showBeginnerMark = currentSettings.show_beginner_mark,
            nameColor = {
                r = currentSettings.name_color_r or 255,
                g = currentSettings.name_color_g or 255,
                b = currentSettings.name_color_b or 255,
                a = currentSettings.name_color_a or 255
            },
            useCustomNameColor = currentSettings.use_custom_name_color,
            topTextColor = {
                r = currentSettings.top_text_color_r or 255,
                g = currentSettings.top_text_color_g or 255,
                b = currentSettings.top_text_color_b or 255,
                a = currentSettings.top_text_color_a or 255
            },
            useCustomTopTextColor = currentSettings.use_custom_top_text_color
        }
        
        UpdatePlayerSettings(Player.PlayerData.citizenid, settings)
        TriggerClientEvent('ng-name:client:syncTopText', -1, src, text)
    end
end)

-- 上部テキスト表示切替イベント（色情報も保持するように修正）
RegisterNetEvent('ng-name:server:toggleTopText', function(useTopText)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local currentSettings = GetPlayerSettings(Player.PlayerData.citizenid) or {}
        
        local settings = {
            visibility = currentSettings.visibility,
            streamerMode = currentSettings.streamer_mode,
            nickname = currentSettings.nickname,
            useNickname = currentSettings.use_nickname,
            topText = currentSettings.top_text,
            useTopText = useTopText,
            showBeginnerMark = currentSettings.show_beginner_mark,
            nameColor = {
                r = currentSettings.name_color_r or 255,
                g = currentSettings.name_color_g or 255,
                b = currentSettings.name_color_b or 255,
                a = currentSettings.name_color_a or 255
            },
            useCustomNameColor = currentSettings.use_custom_name_color,
            topTextColor = {
                r = currentSettings.top_text_color_r or 255,
                g = currentSettings.top_text_color_g or 255,
                b = currentSettings.top_text_color_b or 255,
                a = currentSettings.top_text_color_a or 255
            },
            useCustomTopTextColor = currentSettings.use_custom_top_text_color
        }
        
        UpdatePlayerSettings(Player.PlayerData.citizenid, settings)
        TriggerClientEvent('ng-name:client:syncTopTextToggle', -1, src, useTopText)
    end
end)

-- QBCore:Server:PlayerLoaded イベントを修正（色情報の送信を追加）
RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        -- 既存の処理（現在の設定の読み込み）は維持
        local settings = GetPlayerSettings(Player.PlayerData.citizenid)
        if settings then
            playerVisibility[src] = settings.visibility
            
            -- 色情報を含む設定データを準備
            local nameColorData = {
                color = {
                    r = settings.name_color_r or 255,
                    g = settings.name_color_g or 255,
                    b = settings.name_color_b or 255,
                    a = settings.name_color_a or 255
                },
                enabled = settings.use_custom_name_color or false
            }
            
            local topTextColorData = {
                color = {
                    r = settings.top_text_color_r or 255,
                    g = settings.top_text_color_g or 255,
                    b = settings.top_text_color_b or 255,
                    a = settings.top_text_color_a or 255
                },
                enabled = settings.use_custom_top_text_color or false
            }
            
            TriggerClientEvent('ng-name:client:loadSettings', src, 
                settings.visibility, 
                settings.streamer_mode, 
                settings.nickname, 
                settings.use_nickname,
                settings.top_text,
                settings.use_top_text,
                settings.show_beginner_mark,
                nameColorData,
                topTextColorData
            )
        else
            -- 新規プレイヤーのデフォルト設定
            UpdatePlayerSettings(Player.PlayerData.citizenid, {
                visibility = true,
                streamerMode = false,
                nickname = nil,
                useNickname = false,
                topText = nil,
                useTopText = false,
                showBeginnerMark = false,
                nameColor = {r = 255, g = 255, b = 255, a = 255},
                useCustomNameColor = false,
                topTextColor = {r = 255, g = 255, b = 255, a = 255},
                useCustomTopTextColor = false
            })
            playerVisibility[src] = true
            
            local defaultNameColorData = {
                color = {r = 255, g = 255, b = 255, a = 255},
                enabled = false
            }
            
            local defaultTopTextColorData = {
                color = {r = 255, g = 255, b = 255, a = 255},
                enabled = false
            }
            
            TriggerClientEvent('ng-name:client:loadSettings', src, 
                true, false, nil, false, nil, false, false,
                defaultNameColorData, defaultTopTextColorData
            )
        end

        -- 既存プレイヤーの情報を新規プレイヤーに送信（색정보 포함）
        local Players = QBCore.Functions.GetQBPlayers()
        for _, xPlayer in pairs(Players) do
            if xPlayer.PlayerData.source ~= src then
                local xSettings = GetPlayerSettings(xPlayer.PlayerData.citizenid) or {}
                if xSettings.visibility or xSettings.streamer_mode or (IsPlayerBeginner(xPlayer) and xSettings.show_beginner_mark) then
                    local charInfo = xPlayer.PlayerData.charinfo
                    local isBeginner = IsPlayerBeginner(xPlayer) and (xSettings.show_beginner_mark ~= false)
                    
                    local nameColorData = {
                        color = {
                            r = xSettings.name_color_r or 255,
                            g = xSettings.name_color_g or 255,
                            b = xSettings.name_color_b or 255,
                            a = xSettings.name_color_a or 255
                        },
                        enabled = xSettings.use_custom_name_color or false
                    }
                    
                    local topTextColorData = {
                        color = {
                            r = xSettings.top_text_color_r or 255,
                            g = xSettings.top_text_color_g or 255,
                            b = xSettings.top_text_color_b or 255,
                            a = xSettings.top_text_color_a or 255
                        },
                        enabled = xSettings.use_custom_top_text_color or false
                    }
                    
                    TriggerClientEvent('ng-name:client:displayName', src, 
                        xPlayer.PlayerData.source,
                        charInfo.firstname, 
                        charInfo.lastname,
                        xSettings.nickname,
                        xSettings.use_nickname,
                        xSettings.streamer_mode,
                        xSettings.top_text,
                        xSettings.use_top_text,
                        isBeginner,
                        nameColorData,
                        topTextColorData
                    )
                end
            end
        end

        -- 新規プレイヤーの情報を他の全プレイヤーに送信
        local myCharInfo = Player.PlayerData.charinfo
        local isBeginner = IsPlayerBeginner(Player) and (settings and settings.show_beginner_mark ~= false)
        
        if (settings and settings.visibility) or (settings and settings.streamer_mode) or isBeginner then
            local nameColorData = {
                color = {
                    r = (settings and settings.name_color_r) or 255,
                    g = (settings and settings.name_color_g) or 255,
                    b = (settings and settings.name_color_b) or 255,
                    a = (settings and settings.name_color_a) or 255
                },
                enabled = (settings and settings.use_custom_name_color) or false
            }
            
            local topTextColorData = {
                color = {
                    r = (settings and settings.top_text_color_r) or 255,
                    g = (settings and settings.top_text_color_g) or 255,
                    b = (settings and settings.top_text_color_b) or 255,
                    a = (settings and settings.top_text_color_a) or 255
                },
                enabled = (settings and settings.use_custom_top_text_color) or false
            }
            
            TriggerClientEvent('ng-name:client:displayName', -1,
                src,
                myCharInfo.firstname,
                myCharInfo.lastname,
                settings and settings.nickname or nil,
                settings and settings.use_nickname or false,
                settings and settings.streamer_mode or false,
                settings and settings.top_text or nil,
                settings and settings.use_top_text or false,
                isBeginner,
                nameColorData,
                topTextColorData
            )
        end
    end
end)

-- 配信者モードの更新イベント（色情報保持を追加）
RegisterNetEvent('ng-name:server:updateStreamerMode', function(enabled)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local currentSettings = GetPlayerSettings(Player.PlayerData.citizenid) or {}
        
        local settings = {
            visibility = currentSettings.visibility,
            streamerMode = enabled,
            nickname = currentSettings.nickname,
            useNickname = currentSettings.use_nickname,
            topText = currentSettings.top_text,
            useTopText = currentSettings.use_top_text,
            showBeginnerMark = currentSettings.show_beginner_mark,
            nameColor = {
                r = currentSettings.name_color_r or 255,
                g = currentSettings.name_color_g or 255,
                b = currentSettings.name_color_b or 255,
                a = currentSettings.name_color_a or 255
            },
            useCustomNameColor = currentSettings.use_custom_name_color,
            topTextColor = {
                r = currentSettings.top_text_color_r or 255,
                g = currentSettings.top_text_color_g or 255,
                b = currentSettings.top_text_color_b or 255,
                a = currentSettings.top_text_color_a or 255
            },
            useCustomTopTextColor = currentSettings.use_custom_top_text_color
        }

        UpdatePlayerSettings(Player.PlayerData.citizenid, settings)
        TriggerClientEvent('ng-name:client:syncStreamerMode', -1, src, enabled)
    end
end)

-- 名前表示/非表示設定更新イベント
RegisterNetEvent('ng-name:server:updateVisibility', function(isVisible)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local currentSettings = GetPlayerSettings(Player.PlayerData.citizenid) or {}
        
        local settings = {
            visibility = isVisible,
            streamerMode = currentSettings.streamer_mode,
            nickname = currentSettings.nickname,
            useNickname = currentSettings.use_nickname,
            topText = currentSettings.top_text,
            useTopText = currentSettings.use_top_text,
            showBeginnerMark = currentSettings.show_beginner_mark,
            nameColor = {
                r = currentSettings.name_color_r or 255,
                g = currentSettings.name_color_g or 255,
                b = currentSettings.name_color_b or 255,
                a = currentSettings.name_color_a or 255
            },
            useCustomNameColor = currentSettings.use_custom_name_color,
            topTextColor = {
                r = currentSettings.top_text_color_r or 255,
                g = currentSettings.top_text_color_g or 255,
                b = currentSettings.top_text_color_b or 255,
                a = currentSettings.top_text_color_a or 255
            },
            useCustomTopTextColor = currentSettings.use_custom_top_text_color
        }

        UpdatePlayerSettings(Player.PlayerData.citizenid, settings)
        playerVisibility[src] = isVisible
        
        if isVisible then
            local charInfo = Player.PlayerData.charinfo
            local isBeginner = IsPlayerBeginner(Player) and (settings.showBeginnerMark ~= false)
            
            local nameColorData = {
                color = settings.nameColor,
                enabled = settings.useCustomNameColor
            }
            
            local topTextColorData = {
                color = settings.topTextColor,
                enabled = settings.useCustomTopTextColor
            }
            
            TriggerClientEvent('ng-name:client:displayName', -1, src, 
                charInfo.firstname, 
                charInfo.lastname, 
                settings.nickname, 
                settings.useNickname, 
                settings.streamerMode,
                settings.topText,
                settings.useTopText,
                isBeginner,
                nameColorData,
                topTextColorData
            )
        end
        
        TriggerClientEvent('ng-name:client:syncVisibility', -1, src, isVisible)
        
        local nameColorData = {
            color = settings.nameColor,
            enabled = settings.useCustomNameColor
        }
        
        local topTextColorData = {
            color = settings.topTextColor,
            enabled = settings.useCustomTopTextColor
        }
        
        TriggerClientEvent('ng-name:client:loadSettings', src, 
            isVisible, 
            settings.streamerMode, 
            settings.nickname, 
            settings.useNickname,
            settings.topText,
            settings.useTopText,
            settings.showBeginnerMark,
            nameColorData,
            topTextColorData
        )
    end
end)

RegisterNetEvent('ng-name:server:getPlayerName', function(targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(targetId)
    local RequestingPlayer = QBCore.Functions.GetPlayer(src)
    
    if not Player or not RequestingPlayer then return end

    local charInfo = Player.PlayerData.charinfo
    local settings = GetPlayerSettings(Player.PlayerData.citizenid) or {}
    
    playerVisibility[targetId] = settings.visibility

    -- 色情報を準備
    local nameColorData = {
        color = {
            r = settings.name_color_r or 255,
            g = settings.name_color_g or 255,
            b = settings.name_color_b or 255,
            a = settings.name_color_a or 255
        },
        enabled = settings.use_custom_name_color or false
    }
    
    local topTextColorData = {
        color = {
            r = settings.top_text_color_r or 255,
            g = settings.top_text_color_g or 255,
            b = settings.top_text_color_b or 255,
            a = settings.top_text_color_a or 255
        },
        enabled = settings.use_custom_top_text_color or false
    }

    if src == targetId then
        -- 自分の設定を更新（色情報も含む）
        TriggerClientEvent('ng-name:client:loadSettings', src,
            settings.visibility,
            settings.streamer_mode,
            settings.nickname,
            settings.use_nickname,
            settings.top_text,
            settings.use_top_text,
            settings.show_beginner_mark,
            nameColorData,
            topTextColorData
        )

        -- 全プレイヤーの情報を取得（色情報も含む）
        local Players = QBCore.Functions.GetPlayers()
        for _, playerSrc in pairs(Players) do
            if tonumber(playerSrc) ~= src then
                local xPlayer = QBCore.Functions.GetPlayer(tonumber(playerSrc))
                if xPlayer then
                    local xSettings = GetPlayerSettings(xPlayer.PlayerData.citizenid) or {}
                    local xCharInfo = xPlayer.PlayerData.charinfo
                    
                    if xSettings.visibility or xSettings.streamer_mode or (IsPlayerBeginner(xPlayer) and xSettings.show_beginner_mark) then
                        local isBeginner = IsPlayerBeginner(xPlayer) and (xSettings.show_beginner_mark ~= false)
                        
                        local xNameColorData = {
                            color = {
                                r = xSettings.name_color_r or 255,
                                g = xSettings.name_color_g or 255,
                                b = xSettings.name_color_b or 255,
                                a = xSettings.name_color_a or 255
                            },
                            enabled = xSettings.use_custom_name_color or false
                        }
                        
                        local xTopTextColorData = {
                            color = {
                                r = xSettings.top_text_color_r or 255,
                                g = xSettings.top_text_color_g or 255,
                                b = xSettings.top_text_color_b or 255,
                                a = xSettings.top_text_color_a or 255
                            },
                            enabled = xSettings.use_custom_top_text_color or false
                        }
                        
                        TriggerClientEvent('ng-name:client:displayName', src,
                            tonumber(playerSrc),
                            xCharInfo.firstname,
                            xCharInfo.lastname,
                            xSettings.nickname,
                            xSettings.use_nickname,
                            xSettings.streamer_mode,
                            xSettings.top_text,
                            xSettings.use_top_text,
                            isBeginner,
                            xNameColorData,
                            xTopTextColorData
                        )
                    end
                end
            end
        end

        -- 自分の情報を他のプレイヤーに送信（色情報も含む）
        if settings.visibility or settings.streamer_mode or (IsPlayerBeginner(Player) and settings.show_beginner_mark) then
            local isBeginner = IsPlayerBeginner(Player) and (settings.show_beginner_mark ~= false)
            
            TriggerClientEvent('ng-name:client:displayName', -1,
                targetId,
                charInfo.firstname,
                charInfo.lastname,
                settings.nickname,
                settings.use_nickname,
                settings.streamer_mode,
                settings.top_text,
                settings.use_top_text,
                isBeginner,
                nameColorData,
                topTextColorData
            )
        end
    else
        -- 他のプレイヤーの情報のみを要求した場合（色情報も含む）
        if settings.visibility or settings.streamer_mode or (IsPlayerBeginner(Player) and settings.show_beginner_mark) then
            local isBeginner = IsPlayerBeginner(Player) and (settings.show_beginner_mark ~= false)
            
            TriggerClientEvent('ng-name:client:displayName', src,
                targetId,
                charInfo.firstname,
                charInfo.lastname,
                settings.nickname,
                settings.use_nickname,
                settings.streamer_mode,
                settings.top_text,
                settings.use_top_text,
                isBeginner,
                nameColorData,
                topTextColorData
            )
        end
    end
end)

-- プレイヤー切断時の処理
AddEventHandler('playerDropped', function()
    local src = source
    playerVisibility[src] = nil
end)

-- スクリプト起動時のデバッグメッセージ
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
end)

-- スクリプト停止時のデバッグメッセージ
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
end)