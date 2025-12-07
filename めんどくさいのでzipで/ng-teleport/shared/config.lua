Config = {}

-- クールダウン設定（分）
Config.Cooldown = 1

-- HP要件設定（%）
Config.RequiredHealth = 100

-- Discord Webhook 設定
Config.DiscordWebhook = {
    url = 'YOUR_DISCORD_WEBHOOK_URL_HERE',  -- あなたのWebhook URLを入力
    botName = 'Teleport Logs',
    colors = {
        success = 3066993,  -- Green
        error = 15158332    -- Red
    }
}

-- ブラックリストゾーン設定
Config.BlacklistZones = {
    -- Example:
    --[[
    {
        name = "カジノ内部",
        points = {
            vector2(1100.0, 220.0),
            vector2(1100.0, 240.0),
            vector2(1120.0, 240.0),
            vector2(1120.0, 220.0)
        }
    }
    ]]
}

-- テレポート先の設定（ジョブごと）
Config.TeleportLocations = {
    ['police'] = {
        label = '警察署',
        locations = {
            {
                label = '警察署',
                coords = vector4(91.18, -380.42, 85.33, 209.01)
            },
            {
                label = '北警察署',
                coords = vector4(-434.86, 6016.25, 31.49, 314.15)
            }
        }
    },
    ['ambulance'] = {
        label = '病院',
        locations = {
            {
                label = 'ピルボックス病院',
                coords = vector4(306.16, -560.55, 43.32, 126.41)
            },
            {
                label = '北病院',
                coords = vector4(-247.74, 6331.51, 32.43, 222.18)
            }
        }
    }
}

-- エフェクト設定
Config.Effects = {
    screen = {
        pre = {
            type = "SWITCH_OUT",
            duration = 3000,
            start = 0.1,
            ["end"] = 1.0
        },
        post = {
            type = "SWITCH_IN",
            duration = 3000,
            start = 1.0,
            ["end"] = 0.0
        }
    },
    particle = {
        pre = {
            dict = "core",
            name = "ent_sht_electrical_box",
            duration = 2000,
            scale = 2.0,
            offset = vector3(0.0, 0.0, -1.0)
        },
        post = {
            dict = "core",
            name = "exp_air_molotov",
            duration = 2000,
            scale = 1.0,
            offset = vector3(0.0, 0.0, -1.0)
        }
    },
    sounds = {
        pre = {
            name = "5_SEC_WARNING",
            dict = "HUD_MINI_GAME_SOUNDSET",
            duration = 1000
        },
        post = {
            name = "Teleport",
            dict = "GTAO_FM_Events_Soundset",
            duration = 1000
        }
    }
}