Config = {}

-- デバッグモード
Config.Debug = true

-- 鉄骨の設定
Config.SteelBeam = {
    -- 開始地点
    StartPoint = vector3(31.62, -678.90, 250.41),
    
    -- 終了地点
    EndPoint = vector3(128.82, -722.77, 258.75),
    
    -- 鉄骨のモデル
    Model = 'prop_constr_beams_01', -- 建設用の鉄骨
    
    -- 鉄骨の間隔(メートル)
    BeamSpacing = 5.0,
    
    -- 鉄骨の回転設定
    AutoRotation = true, -- trueの場合、次の鉄骨に向かって自動回転
    
    -- 鉄骨の配置高さ調整
    HeightAdjust = 0.0, -- 必要に応じて高さを調整
}

-- 鉄骨の表示距離
Config.RenderDistance = 200.0

-- リソース開始時に自動スポーン
Config.AutoSpawnOnStart = true