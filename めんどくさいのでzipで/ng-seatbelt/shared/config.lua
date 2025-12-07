Config = {}

-- 警告音の設定
Config.WarningSoundFile = 'TIMER_STOP' -- 警告音のファイル名
Config.WarningSoundSet = 'HUD_MINI_GAME_SOUNDSET' -- 警告音のサウンドセット
Config.WarningSoundVolume = 1.0 -- 警告音の音量（0.0 〜 1.0）
Config.WarningSoundInterval = 2000 -- 警告音が鳴る間隔（ミリ秒）

-- 速度制限の設定
Config.SpeedLimit = 20.0 -- この速度（km/h）以上で警告音が鳴り始める

-- シートベルトの状態をチェックするイベント名（別スクリプトと連携）
Config.SeatbeltStateEvent = 'seatbelt:client:ToggleSeatbelt' -- シートベルトの状態を受け取るイベント名