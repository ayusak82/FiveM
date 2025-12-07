Config = {}

-- 初回ギフト車両のリスト
Config.VehicleOptions = {
    {
        model = 'tailgater2',
        label = 'Tailgater S',
        description = '４人乗りのセダン',
        image = 'car1.png',
        category = 'sedans'
    },
    {
        model = 'paradise',
        label = 'Paradise',
        description = '4人乗りのバン(積載可能)',
        image = 'car2.png',
        category = 'vans'
    },
    {
        model = 'double',
        label = 'Double-T',
        description = '二人乗りのバイク',
        image = 'car3.png',
        category = 'motorcycle'
    }
}

-- プレートの生成に使用する文字
Config.PlateLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
Config.PlateNumbers = '0123456789'
Config.PlateLength = 8

-- メッセージ設定
Config.Messages = {
    success = {
        vehicle_claimed = '車両を受け取りました！ガレージで確認できます。',
        ui_opened = '初回特典：無料車両を選択してください'
    },
    error = {
        already_claimed = 'すでに初回特典を受け取っています',
        failed_to_give = '車両の付与に失敗しました。管理者に連絡してください',
        no_selection = '車両を選択してください'
    }
}

-- サーバー側の設定
Config.DatabaseTable = 'player_firstcar_claimed'
Config.DefaultGarage = 'pillboxgarage'