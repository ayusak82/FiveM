Config = {}

-- コマンド設定
Config.Commands = {
    vector3 = 'gv3',  -- vector3を取得するコマンド
    vector4 = 'gv4'   -- vector4を取得するコマンド（heading含む）
}

-- コピーフォーマット設定
Config.Format = {
    vector3 = 'vector3(%s, %s, %s)',          -- vector3のフォーマット
    vector4 = 'vector4(%s, %s, %s, %s)',      -- vector4のフォーマット
    decimal_places = 2                         -- 小数点以下の桁数
}