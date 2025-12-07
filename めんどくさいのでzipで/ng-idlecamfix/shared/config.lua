Config = {}

-- アイドルカメラ防止の設定
Config.DisableIdleCamera = true -- アイドルカメラを無効にするかどうか
Config.SimulateInput = true -- 入力をシミュレートしてカメラ動作を防止するかどうか
Config.InputInterval = 10000 -- 入力シミュレーションの間隔（ミリ秒）

-- アイドル状態の検出
Config.IdleCheckInterval = 1000 -- アイドル状態チェックの間隔（ミリ秒）

-- カメラリセット設定
Config.ResetCameraOnIdle = true -- アイドル検出時にカメラをリセットするかどうか
Config.PreferredCamMode = 1 -- 優先されるカメラモード (1: 3人称, 4: 1人称)

-- デバッグ設定
Config.Debug = false -- デバッグ情報を表示するかどうか
Config.ShowNotifications = false -- 通知を表示するかどうか