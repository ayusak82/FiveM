--[[
    ng-gacha - QBCore Item Registration
    Author: NCCGr
    Contact: Discord: ayusak
    
    以下の内容を qb-core/shared/items.lua に追加してください
]]

--[[

-- ガチャチケット（ガチャを作成するためのアイテム）
['gacha_ticket'] = {
    ['name'] = 'gacha_ticket',
    ['label'] = 'ガチャチケット',
    ['weight'] = 10,
    ['type'] = 'item',
    ['image'] = 'gacha_ticket.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'オリジナルガチャを作成できるチケット'
},

-- ガチャマシン（作成されたガチャを開くアイテム）
['gacha_machine'] = {
    ['name'] = 'gacha_machine',
    ['label'] = 'ガチャマシン',
    ['weight'] = 500,
    ['type'] = 'item',
    ['image'] = 'gacha_machine.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'ガチャを開く'
},

-- ガチャコイン（ガチャを回すための通貨アイテム）
['gacha_coin'] = {
    ['name'] = 'gacha_coin',
    ['label'] = 'ガチャコイン',
    ['weight'] = 1,
    ['type'] = 'item',
    ['image'] = 'gacha_coin.png',
    ['unique'] = false,
    ['useable'] = false,
    ['shouldClose'] = false,
    ['combinable'] = nil,
    ['description'] = 'ガチャを回すためのコイン'
},

]]
