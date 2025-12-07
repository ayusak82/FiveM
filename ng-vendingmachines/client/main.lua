local QBCore = exports['qb-core']:GetCoreObject()

-- 自販機オブジェクトのキャッシュ
local createdMachines = {}

-- プレイヤーデータ
local PlayerData = {}
local PlayerJob = {}

-- 3Dテキスト描画用のスレッド制御
local renderThread = false

-- 初期化
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    PlayerJob = PlayerData.job
    InitVendingMachines()
    StartRenderThread()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

-- 3Dテキストを描画する関数
function Draw3DText(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = #(vector3(px, py, pz) - vector3(coords.x, coords.y, coords.z))
    
    if onScreen and dist < 20.0 then
        local scale = (1 / dist) * 2
        local fov = (1 / GetGameplayCamFov()) * 100
        scale = scale * fov
        
        SetTextScale(0.0 * scale, 0.55 * scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- 3Dテキスト描画スレッドを開始
function StartRenderThread()
    if renderThread then return end
    renderThread = true
    
    CreateThread(function()
        while renderThread do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local shouldDraw = false
            
            for machineId, entity in pairs(createdMachines) do
                if DoesEntityExist(entity) then
                    local machineCoords = GetEntityCoords(entity)
                    local distance = #(playerCoords - machineCoords)
                    
                    if distance < 20.0 then
                        shouldDraw = true
                        local machineData = Config.VendingMachines[machineId]
                        if machineData and machineData.label then
                            -- 自販機の上部にテキストを表示（+1.5メートル上）
                            local textCoords = vector3(machineCoords.x, machineCoords.y, machineCoords.z + 1.5)
                            Draw3DText(textCoords, machineData.label)
                        end
                    end
                end
            end
            
            -- 近くに自販機がない場合は待機時間を長くする
            Wait(shouldDraw and 0 or 1000)
        end
    end)
end

-- 3Dテキスト描画スレッドを停止
function StopRenderThread()
    renderThread = false
end

-- 自販機の初期化
function InitVendingMachines()
    for machineId, machine in pairs(Config.VendingMachines) do
        CreateVendingMachine(machineId, machine)
    end
end

-- 自販機オブジェクトの作成
function CreateVendingMachine(machineId, machineData)
    -- オブジェクトが既に存在する場合は削除
    if createdMachines[machineId] then
        DeleteEntity(createdMachines[machineId])
        createdMachines[machineId] = nil
    end
    
    -- 座標取得
    local coords = machineData.coords
    
    -- モデルのロード
    local modelHash = machineData.model
    if type(modelHash) == 'string' then
        modelHash = joaat(modelHash)
    end
    
    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Wait(10)
        end
    end
    
    -- オブジェクト作成
    local obj = CreateObject(modelHash, coords.x, coords.y, coords.z - 1.0, false, false, false)
    SetEntityHeading(obj, coords.w)
    FreezeEntityPosition(obj, true)
    
    -- 重要: 一時エンティティとして設定（リソース停止時に自動的に削除）
    SetEntityAsMissionEntity(obj, false, true)
    
    createdMachines[machineId] = obj
    
    -- ox_targetの設定
    if Config.UseTarget then
        exports.ox_target:addLocalEntity(obj, {
            {
                name = 'vending_machine_use_' .. machineId,
                icon = 'fas fa-shopping-basket',
                label = Config.Text.interact,
                distance = 2.0,
                onSelect = function()
                    OpenVendingMachine(machineId)
                end
            },
            {
                name = 'vending_machine_manage_' .. machineId,
                icon = 'fas fa-cogs',
                label = Config.Text.manage,
                distance = 2.0,
                canInteract = function()
                    return HasMachinePermission(machineId)
                end,
                onSelect = function()
                    OpenManagementMenu(machineId)
                end
            }
        })
    end
    
    if Config.Debug then
        print('自販機作成: ID=' .. machineId .. ', モデル=' .. modelHash)
    end
end

-- 権限の確認
function HasMachinePermission(machineId)
    local machineJobs = Config.VendingMachines[machineId].jobs
    
    if not machineJobs or not PlayerJob then
        return false
    end
    
    local requiredGrade = machineJobs[PlayerJob.name]
    if requiredGrade and PlayerJob.grade.level >= requiredGrade then
        return true
    end
    
    return false
end

-- 自販機メニューを開く
function OpenVendingMachine(machineId)
    -- 自販機データを取得
    lib.callback('ng-vendingmachines:server:getMachineData', false, function(machineData)
        if not machineData then
            QBCore.Functions.Notify('自販機データが読み込めませんでした', 'error')
            return
        end
        
        -- アイテム情報を取得
        local items = {}
        for itemName, data in pairs(machineData) do
            if QBCore.Shared.Items[itemName] then
                local item = QBCore.Shared.Items[itemName]
                table.insert(items, {
                    name = itemName,
                    label = item.label,
                    price = data.price,
                    stock = data.stock,
                    description = '価格: $' .. data.price .. ' | 在庫: ' .. data.stock,
                    disabled = data.stock <= 0
                })
            end
        end
        
        -- 商品がない場合
        if #items == 0 then
            QBCore.Functions.Notify('この自販機には商品がありません', 'error')
            return
        end
        
        -- アイテムを価格順にソート
        table.sort(items, function(a, b)
            return a.price < b.price
        end)
        
        -- メニューオプション
        local options = {}
        for _, item in ipairs(items) do
            table.insert(options, {
                title = item.label,
                description = item.description,
                icon = 'box',
                disabled = item.disabled,
                onSelect = function()
                    OpenPurchaseMenu(machineId, item)
                end
            })
        end
        
        -- メニューを表示
        lib.registerContext({
            id = 'vending_menu_' .. machineId,
            title = Config.UI.title,
            options = options
        })
        
        lib.showContext('vending_menu_' .. machineId)
    end, machineId)
end

-- 購入メニューを開く（新規関数）
function OpenPurchaseMenu(machineId, item)
    local maxAmount = math.min(10, item.stock) -- 最大で10個、または在庫数まで
    
    -- 購入情報入力
    local input = lib.inputDialog(item.label .. ' - 購入', {
        {type = 'number', label = '購入数', description = '購入する数量を入力してください', min = 1, max = maxAmount, default = 1},
        {type = 'select', label = '支払い方法', options = {
            {value = 'cash', label = '現金で支払う'},
            {value = 'bank', label = '銀行で支払う'}
        }}
    })
    
    if input and input[1] and input[2] then
        local amount = input[1]
        local paymentType = input[2]
        
        -- 総額の計算
        local totalPrice = item.price * amount
        
        -- 確認ダイアログ
        local confirm = lib.alertDialog({
            header = '購入確認',
            content = item.label .. ' x' .. amount .. 'を $' .. totalPrice .. ' で購入しますか？\n支払い方法: ' .. (paymentType == 'cash' and '現金' or '銀行'),
            centered = true,
            cancel = true
        })
        
        if confirm == 'confirm' then
            PurchaseItems(machineId, item.name, amount, paymentType)
        end
    end
end

-- 商品を購入
function PurchaseItems(machineId, itemName, amount, paymentType)
    lib.callback('ng-vendingmachines:server:purchaseItem', false, function(success, message)
        if success then
            -- 購入成功のアニメーション
            local ped = PlayerPedId()
            TaskStartScenarioInPlace(ped, "PROP_HUMAN_ATM", 0, true)
            Wait(2000)
            ClearPedTasks(ped)
            
            -- メニューを更新（最新の在庫を表示）
            OpenVendingMachine(machineId)
        else
            QBCore.Functions.Notify(message, 'error')
        end
    end, machineId, itemName, amount, paymentType)
end

-- 管理メニューを開く
function OpenManagementMenu(machineId)
    -- 権限チェック
    if not HasMachinePermission(machineId) then
        QBCore.Functions.Notify(Config.Text.noPerms, 'error')
        return
    end
    
    -- 自販機データを取得
    lib.callback('ng-vendingmachines:server:getMachineData', false, function(machineData)
        if not machineData then
            QBCore.Functions.Notify('自販機データが読み込めませんでした', 'error')
            return
        end
        
        -- アイテム情報を取得
        local items = {}
        for itemName, data in pairs(machineData) do
            if QBCore.Shared.Items[itemName] then
                local item = QBCore.Shared.Items[itemName]
                table.insert(items, {
                    name = itemName,
                    label = item.label,
                    price = data.price,
                    stock = data.stock,
                    description = '価格: $' .. data.price .. ' | 在庫: ' .. data.stock
                })
            end
        end
        
        -- アイテムを名前順にソート
        table.sort(items, function(a, b)
            return a.label < b.label
        end)
        
        -- 管理メニューのオプション
        local options = {
            {
                title = '新しいアイテムを追加',
                description = '自販機に新しい商品を追加します',
                icon = 'plus-circle',
                onSelect = function()
                    OpenAddItemMenu(machineId)
                end
            }
        }
        
        -- 各アイテムの管理オプション
        for _, item in ipairs(items) do
            table.insert(options, {
                title = item.label,
                description = item.description,
                icon = 'box',
                menu = 'item_options_' .. item.name
            })
        end
        
        -- メインメニュー
        lib.registerContext({
            id = 'machine_management_' .. machineId,
            title = Config.UI.adminTitle,
            options = options
        })
        
        -- 各アイテムのサブメニュー
        for _, item in ipairs(items) do
            lib.registerContext({
                id = 'item_options_' .. item.name,
                title = item.label .. ' - 管理',
                menu = 'machine_management_' .. machineId,
                options = {
                    {
                        title = '在庫を補充',
                        description = '現在の在庫: ' .. item.stock,
                        icon = 'plus',
                        onSelect = function()
                            local input = lib.inputDialog('在庫補充', {
                                {type = 'number', label = '補充する数', description = 'アイテムが必要です', min = 1, max = 50, default = 10}
                            })
                            
                            if input and input[1] then
                                RestockItem(machineId, item.name, input[1])
                            end
                        end
                    },
                    {
                        title = '価格を変更',
                        description = '現在の価格: $' .. item.price,
                        icon = 'dollar-sign',
                        onSelect = function()
                            local input = lib.inputDialog('価格変更', {
                                {type = 'number', label = '新しい価格', description = '新しい価格を入力してください', min = 1, max = 10000000, default = item.price}
                            })
                            
                            if input and input[1] then
                                UpdatePrice(machineId, item.name, input[1])
                            end
                        end
                    },
                    {
                        title = 'アイテムを削除',
                        description = '商品を自販機から削除します',
                        icon = 'trash',
                        onSelect = function()
                            local confirm = lib.alertDialog({
                                header = '商品削除の確認',
                                content = item.label .. 'を自販機から削除しますか？残りの在庫は返却されます。',
                                centered = true,
                                cancel = true
                            })
                            
                            if confirm == 'confirm' then
                                RemoveItem(machineId, item.name)
                            end
                        end
                    }
                }
            })
        end
        
        lib.showContext('machine_management_' .. machineId)
    end, machineId)
end

-- 新しいアイテムを追加するメニュー
function OpenAddItemMenu(machineId)
    -- インベントリからアイテムを選択
    local PlayerData = QBCore.Functions.GetPlayerData()
    local inventory = PlayerData.items
    
    -- 選択可能なアイテムのリストを作成
    local itemOptions = {}
    local itemsAlready = {}
    
    -- すでに自販機に登録されているアイテムを確認
    lib.callback('ng-vendingmachines:server:getMachineData', false, function(machineData)
        if machineData then
            for itemName, _ in pairs(machineData) do
                itemsAlready[itemName] = true
            end
        end
        
        -- インベントリからアイテムの選択肢を作成
        for _, item in pairs(inventory) do
            if item and not itemsAlready[item.name] then
                -- アイテムの数量フィールドをチェック（amount または count）
                local itemCount = item.amount or item.count or 0
                table.insert(itemOptions, {
                    value = item.name,
                    label = item.label .. ' (' .. itemCount .. '個所持)'
                })
            end
        end
        
        -- アイテムが一つもない場合
        if #itemOptions == 0 then
            QBCore.Functions.Notify('追加可能なアイテムがありません', 'error')
            return
        end
        
        -- 追加するアイテムの情報入力
        local input = lib.inputDialog('新しいアイテムを追加', {
            {type = 'select', label = 'アイテム', options = itemOptions},
            {type = 'number', label = '価格', description = '販売価格を設定してください', min = 1, max = 10000000, default = 50},
            {type = 'number', label = '初期在庫', description = 'アイテムが必要です', min = 1, max = 1000, default = 10}
        })
        
        if input and input[1] and input[2] and input[3] then
            -- アイテム追加処理
            AddNewItem(machineId, input[1], input[2], input[3])
        end
    end, machineId)
end

-- 新しいアイテムを追加
function AddNewItem(machineId, itemName, price, stock)
    lib.callback('ng-vendingmachines:server:addNewItem', false, function(success, message)
        if success then
            QBCore.Functions.Notify(message, 'success')
            -- 管理メニューを更新
            OpenManagementMenu(machineId)
        else
            QBCore.Functions.Notify(message, 'error')
        end
    end, machineId, itemName, price, stock)
end

-- アイテムを削除
function RemoveItem(machineId, itemName)
    lib.callback('ng-vendingmachines:server:removeItem', false, function(success, message)
        if success then
            QBCore.Functions.Notify(message, 'success')
            -- 管理メニューを更新
            OpenManagementMenu(machineId)
        else
            QBCore.Functions.Notify(message, 'error')
        end
    end, machineId, itemName)
end

-- 在庫を補充
function RestockItem(machineId, itemName, amount)
    lib.callback('ng-vendingmachines:server:restockItem', false, function(success, message)
        if success then
            QBCore.Functions.Notify(message, 'success')
            -- 管理メニューを更新
            OpenManagementMenu(machineId)
        else
            QBCore.Functions.Notify(message, 'error')
        end
    end, machineId, itemName, amount)
end

-- 価格を更新
function UpdatePrice(machineId, itemName, newPrice)
    lib.callback('ng-vendingmachines:server:updatePrice', false, function(success, message)
        if success then
            QBCore.Functions.Notify(message, 'success')
            -- 管理メニューを更新
            OpenManagementMenu(machineId)
        else
            QBCore.Functions.Notify(message, 'error')
        end
    end, machineId, itemName, newPrice)
end

-- 新しい自販機を作成（管理者コマンド用）
RegisterNetEvent('ng-vendingmachines:client:createNewMachine', function()
    -- 自販機モデルの選択
    local modelOptions = {}
    for _, model in ipairs(Config.AvailableModels) do
        table.insert(modelOptions, {
            value = model.model,
            label = model.label
        })
    end
    
    -- 職業権限の設定
    local input = lib.inputDialog('新しい自販機の作成', {
        {type = 'select', label = 'モデル', options = modelOptions},
        {type = 'input', label = '管理職業（例: police,ambulance）', description = 'カンマ区切りで入力'},
        {type = 'number', label = '必要階級', description = '管理に必要な最低階級', min = 0, max = 10, default = 1},
        {type = 'input', label = 'ラベル', description = '自販機の説明（任意）'}
    })
    
    if not input or not input[1] or not input[2] or not input[3] then
        QBCore.Functions.Notify('情報が不足しています', 'error')
        return
    end
    
    -- プレイヤーの位置を取得
    local playerPos = GetEntityCoords(PlayerPedId())
    local playerHeading = GetEntityHeading(PlayerPedId())
    
    -- 職業権限を解析
    local jobsString = input[2]
    local jobsTable = {}
    
    for job in string.gmatch(jobsString, '([^,]+)') do
        jobsTable[job:gsub("^%s*(.-)%s*$", "%1")] = tonumber(input[3])
    end
    
    -- 新しい自販機データ
    local newMachineData = {
        coords = vector4(playerPos.x, playerPos.y, playerPos.z, playerHeading),
        model = input[1],
        jobs = jobsTable,
        label = input[4] or '自販機'
    }
    
    -- サーバーに送信
    TriggerServerEvent('ng-vendingmachines:server:addNewMachine', newMachineData)
end)

-- リソース起動時の初期化
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    PlayerData = QBCore.Functions.GetPlayerData()
    PlayerJob = PlayerData.job
    Wait(1000) -- サーバー側の準備を待つ
    InitVendingMachines()
    StartRenderThread()
end)

-- 自販機情報の更新（サーバーからの通知）
RegisterNetEvent('ng-vendingmachines:client:updateVendingMachines', function(newMachines)
    Config.VendingMachines = newMachines
    -- 現在のすべての自販機を再読み込み
    for _, entity in pairs(createdMachines) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
    createdMachines = {}
    
    -- 新しい設定で自販機を初期化
    InitVendingMachines()
end)

-- リソース終了時の処理を追加
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- 3Dテキスト描画を停止
    StopRenderThread()
    
    -- すべての自販機を削除
    for machineId, entity in pairs(createdMachines) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
    
    createdMachines = {}
    
    if Config.Debug then
        print('リソース停止: すべての自販機を削除しました')
    end
end)