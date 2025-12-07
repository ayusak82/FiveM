Config = {}

-- デバッグモード（trueにするとゾーンが視覚化されます）
Config.Debug = false

-- 降車後のバイク削除タイマー（秒）
Config.DismountTimer = 180

-- 車両鍵システム設定
Config.GiveKeys = true -- trueでレンタル時に鍵を付与

-- 3Dテキスト表示設定
Config.Show3DText = true
Config.TextScale = 0.8
Config.TextFont = 0

-- マーカー設定
Config.ShowMarker = true
Config.MarkerType = 1 -- 円柱マーカー
Config.MarkerSize = vector3(3.0, 3.0, 1.0)
Config.MarkerColor = {r = 0, g = 150, b = 255, a = 100} -- 青色、半透明
Config.MarkerBobUpDown = true

-- レンタルポイントの設定
Config.RentalPoints = {
    {
        name = "レンタルポイント1", -- ポイント名
        coords = vector3(-1034.39, -2732.35, 20.17), -- 座標
        radius = 3.0, -- ゾーンの半径
        bikeModel = "faggio", -- スポーンするバイクのモデル名
        spawnCoords = vector4(-992.91, -2752.35, 19.65, 257.96), -- バイクのスポーン座標（x, y, z, heading）
    },
    -- 必要に応じてレンタルポイントを追加してください
    -- {
    --     name = "レンタルポイント3",
    --     coords = vector3(x, y, z),
    --     radius = 3.0,
    --     bikeModel = "tribike",
    --     spawnCoords = vector4(x, y, z, heading),
    -- },
}

-- 通知メッセージ
Config.Notifications = {
    rental_success = "バイクをレンタルしました（鍵を受け取りました）",
    rental_failed = "バイクのレンタルに失敗しました",
    already_rented = "既にバイクをレンタルしています",
    bike_deleted = "レンタルバイクが削除されました",
    dismount_warning = "降車後180秒でバイクが削除されます",
    timer_cancelled = "タイマーがキャンセルされました",
    press_to_rent = "[E] バイクをレンタル",
}
