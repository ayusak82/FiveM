Config = {}

-- コマンド名
Config.Command = 'doorinfo'

-- デフォルトのドア設定
Config.DefaultDoorSettings = {
    locked = true,
    pickable = false,
    distance = 2.0,
    authorizedJobs = { 'police' }
}

-- ドアの種類
Config.DoorTypes = {
    ['door'] = '単一ドア',
    ['double'] = '両開きドア',
    ['sliding'] = 'スライドドア',
    ['doublesliding'] = '両開きスライドドア',
    ['garage'] = 'ガレージドア'
}

-- UIの設定
Config.UI = {
    position = 'right-center',
    icon = 'door-open',
    title = 'ドア情報取得',
    description = 'ドア情報をクリップボードにコピーします'
}