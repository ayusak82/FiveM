Config = {}

-- 制限される車両のリスト
Config.RestrictedVehicles = {
    [`police`] = true,  -- 警察車両
    [`police2`] = true,
    [`police3`] = true,
    [`police4`] = true,
    [`ambulance`] = true,  -- 救急車
    [`firetruk`] = true,  -- 消防車
}

-- 画面表示の設定
Config.DisplayText = '犯罪禁止車両です'
Config.Position = {
    x = 0.5,    -- 画面中央
    y = 0.1     -- 画面上部（0.0が最上部）
}
Config.Scale = 0.7        -- テキストサイズ
Config.Font = 4           -- フォントタイプ
Config.Color = {          -- テキストカラー
    r = 255,    -- 赤
    g = 0,      -- 緑
    b = 0,      -- 青
    a = 255     -- 透明度
}