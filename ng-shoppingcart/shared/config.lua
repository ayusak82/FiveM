Config = {}

-- コマンド設定
Config.Command = 'cart' -- ショッピングカートをスポーンするコマンド

-- ショッピングカートモデル
Config.CartModel = 'prop_rub_trolley01a' -- 使用するカートのモデル

-- スポーン設定
Config.SpawnDistance = 2.5 -- プレイヤーの前方何メートルにスポーン
Config.MaxCartsPerPlayer = 1 -- 1人が同時にスポーンできるカートの最大数

-- カート移動設定
Config.CartMoveSpeed = 50.0 -- カートの移動速度 (0.5→2.0に変更)
Config.CartTurnSpeed = 3.0 -- カートの回転速度 (2.0→3.0に変更)

-- インタラクション設定
Config.InteractDistance = 2.5 -- カートとの相互作用距離
Config.RideKey = 38 -- 乗る/降りるキー (38 = E)
Config.CollectKey = 47 -- 回収キー (47 = G)

-- 移動キー設定
Config.MoveForwardKey = 32 -- 前進 (W)
Config.MoveBackwardKey = 33 -- 後退 (S)
Config.TurnLeftKey = 34 -- 左折 (A)
Config.TurnRightKey = 35 -- 右折 (D)

-- 3Dテキスト設定
Config.DrawDistance = 10.0 -- 3Dテキストの表示距離
Config.TextFont = 0 -- フォント (0 = 日本語対応)
Config.TextScale = 0.35 -- テキストサイズ

-- 座りモーション設定
Config.SitAnimation = {
    dict = 'timetable@ron@ig_3_couch',
    anim = 'base',
    flag = 1
}

-- カートオフセット (プレイヤーがカートのどこに座るか)
Config.SitOffset = {
    x = 0.0,
    y = -0.2,
    z = 0.5,
    heading = 180.0  -- 向きを180度回転(逆向き)
}

-- 通知設定
Config.Notifications = {
    spawned = 'ショッピングカートをスポーンしました',
    collected = 'ショッピングカートを回収しました',
    limit = 'すでにカートをスポーン済みです',
    noCart = '近くにカートがありません',
    inVehicle = '車両から降りてください',
    riding = 'カートに乗りました - [W/A/S/D]で移動 [E]で降りる',
    gotOff = 'カートから降りました'
}
