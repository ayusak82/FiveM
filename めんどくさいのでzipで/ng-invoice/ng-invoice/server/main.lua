local QBCore = exports['qb-core']:GetCoreObject()

-- Discord Webhook送信関数（先頭に移動）
local function SendToDiscord(invoiceData, action, forcedBy)
    if not Config.Webhook then return end
    
    -- 時刻のフォーマット
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    
    -- 請求者情報の取得
    local senderInfo = MySQL.single.await([[
        SELECT 
            CONCAT(
                COALESCE(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')), '不明'), ' ',
                COALESCE(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname')), '')
            ) as name
        FROM players 
        WHERE citizenid = ?
    ]], {invoiceData.sender_citizenid})

    -- 請求先情報の取得
    local recipientInfo = MySQL.single.await([[
        SELECT 
            CONCAT(
                COALESCE(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')), '不明'), ' ',
                COALESCE(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname')), '')
            ) as name
        FROM players 
        WHERE citizenid = ?
    ]], {invoiceData.recipient_citizenid})

    -- タイトルとカラーの設定
    local title, color
    if action == "create" then
        title = "新規請求書の作成"
        color = 3447003 -- 青
    elseif action == "paid" then
        title = "請求書の支払い完了"
        color = 5763719 -- 緑
    elseif action == "force" then
        title = "請求書の強制執行"
        color = 15548997 -- 赤
    end

    -- 基本フィールドの作成
    local fields = {
        {
            ["name"] = "請求者",
            ["value"] = string.format("%s (CitizenID: %s)", 
                senderInfo and senderInfo.name or "不明",
                invoiceData.sender_citizenid
            ),
            ["inline"] = true
        },
        {
            ["name"] = "請求先",
            ["value"] = string.format("%s (CitizenID: %s)",
                recipientInfo and recipientInfo.name or "不明",
                invoiceData.recipient_citizenid
            ),
            ["inline"] = true
        },
        {
            ["name"] = "内容",
            ["value"] = invoiceData.content,
            ["inline"] = false
        },
        {
            ["name"] = "金額",
            ["value"] = string.format("$%s", invoiceData.total_amount),
            ["inline"] = true
        }
    }

    -- 強制執行の場合、執行者情報を追加
    if action == "force" and forcedBy then
        local forcedByInfo = MySQL.single.await([[
            SELECT 
                CONCAT(
                    COALESCE(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')), '不明'), ' ',
                    COALESCE(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname')), '')
                ) as name
            FROM players 
            WHERE citizenid = ?
        ]], {forcedBy})

        table.insert(fields, {
            ["name"] = "強制執行者",
            ["value"] = string.format("%s (CitizenID: %s)",
                forcedByInfo and forcedByInfo.name or "不明",
                forcedBy
            ),
            ["inline"] = true
        })
    end

    -- Embedの作成
    local embed = {
        {
            ["title"] = title,
            ["color"] = color,
            ["fields"] = fields,
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    PerformHttpRequest(Config.Webhook, function(err, text, headers) end, 'POST', json.encode({
        username = "Invoice System",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- データベース初期化
local function InitializeDatabase()
    -- まずテーブルが存在するか確認
    local tableExists = MySQL.query.await([[
        SELECT COUNT(*) as count 
        FROM information_schema.tables 
        WHERE table_schema = DATABASE() 
        AND table_name = 'ng_invoices'
    ]])

    if tableExists[1].count == 0 then
        -- テーブルが存在しない場合は新規作成
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `ng_invoices` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `invoice_number` varchar(50) NOT NULL,
                `title` varchar(100) NOT NULL,
                `content` text NOT NULL,
                `sender_citizenid` varchar(50) NOT NULL,
                `sender_job` varchar(50) NOT NULL,
                `recipient_citizenid` varchar(50) NOT NULL,
                `total_amount` int(11) NOT NULL,
                `discount_rate` int NOT NULL DEFAULT 0,
                `is_personal` boolean NOT NULL DEFAULT FALSE,
                `status` enum('pending','paid','cancelled','seized') NOT NULL DEFAULT 'pending',
                `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
                `paid_at` timestamp NULL DEFAULT NULL,
                PRIMARY KEY (`id`),
                KEY `sender_citizenid` (`sender_citizenid`),
                KEY `recipient_citizenid` (`recipient_citizenid`),
                KEY `status` (`status`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
    else
        -- discount_rateカラムが存在するか確認
        local columnExists = MySQL.query.await([[
            SELECT COUNT(*) as count 
            FROM information_schema.columns 
            WHERE table_schema = DATABASE() 
            AND table_name = 'ng_invoices' 
            AND column_name = 'discount_rate'
        ]])

        if columnExists[1].count == 0 then
            -- discount_rateカラムが存在しない場合は追加
            MySQL.query.await([[
                ALTER TABLE `ng_invoices`
                ADD COLUMN `discount_rate` int NOT NULL DEFAULT 0 AFTER `total_amount`
            ]])
        end

        -- statusカラムにseizedを追加
        MySQL.query.await([[
            ALTER TABLE `ng_invoices` 
            MODIFY COLUMN `status` enum('pending','paid','cancelled','seized') NOT NULL DEFAULT 'pending'
        ]])
    end

    -- 押収車両テーブルの作成（player_vehiclesの全カラムを保存）
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `ng_seized_vehicles` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `invoice_id` int(11) NOT NULL,
            `license` varchar(255) DEFAULT NULL,
            `citizenid` varchar(50) NOT NULL,
            `vehicle` varchar(50) NOT NULL,
            `hash` varchar(50) DEFAULT NULL,
            `mods` longtext DEFAULT NULL,
            `plate` varchar(15) NOT NULL,
            `fakeplate` varchar(15) DEFAULT NULL,
            `garage` varchar(50) DEFAULT NULL,
            `fuel` int(11) DEFAULT 100,
            `engine` float DEFAULT 1000,
            `body` float DEFAULT 1000,
            `depotprice` int(11) DEFAULT 0,
            `drivingdistance` int(11) DEFAULT NULL,
            `status_original` text DEFAULT NULL,
            `balance` int(11) DEFAULT 0,
            `paymentamount` int(11) DEFAULT 0,
            `paymentsleft` int(11) DEFAULT 0,
            `financetime` int(11) DEFAULT 0,
            `glovebox` longtext DEFAULT NULL,
            `trunk` longtext DEFAULT NULL,
            `damage` longtext DEFAULT NULL,
            `garage_id` varchar(50) DEFAULT NULL,
            `nickname` varchar(50) DEFAULT NULL,
            `mileage` float DEFAULT 0,
            `seized_by` varchar(50) NOT NULL,
            `seized_job` varchar(50) NOT NULL,
            `seized_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `returned_at` timestamp NULL DEFAULT NULL,
            `status` enum('seized','returned') NOT NULL DEFAULT 'seized',
            PRIMARY KEY (`id`),
            KEY `invoice_id` (`invoice_id`),
            KEY `citizenid` (`citizenid`),
            KEY `plate` (`plate`),
            KEY `status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

-- 車両押収処理
local function SeizeVehicles(citizenid, invoiceId, seizedBy, seizedJob, remainingAmount)
    -- プレイヤーが所有する車両を取得（ガレージ内の車両のみ）
    local vehicles = MySQL.query.await('SELECT * FROM player_vehicles WHERE citizenid = ? AND state = 0', {citizenid})
    
    if not vehicles or #vehicles == 0 then
        return false, 0
    end
    
    local seizedCount = 0
    
    for _, vehicle in ipairs(vehicles) do
        -- 車両を押収テーブルに追加（全カラム保存）
        MySQL.insert.await([[
            INSERT INTO ng_seized_vehicles (
                invoice_id, citizenid, plate, vehicle, hash, mods, 
                license, fakeplate, garage, fuel, engine, body, 
                depotprice, drivingdistance, status_original, balance, 
                paymentamount, paymentsleft, financetime, glovebox, trunk, 
                damage, garage_id, nickname, mileage, seized_by, seized_job
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            invoiceId, 
            citizenid, 
            vehicle.plate, 
            vehicle.vehicle, 
            vehicle.hash,
            vehicle.mods,
            vehicle.license,
            vehicle.fakeplate,
            vehicle.garage,
            vehicle.fuel,
            vehicle.engine,
            vehicle.body,
            vehicle.depotprice,
            vehicle.drivingdistance,
            vehicle.status,
            vehicle.balance,
            vehicle.paymentamount,
            vehicle.paymentsleft,
            vehicle.financetime,
            vehicle.glovebox,
            vehicle.trunk,
            vehicle.damage,
            vehicle.garage_id,
            vehicle.nickname,
            vehicle.mileage,
            seizedBy, 
            seizedJob
        })
        
        -- 元のテーブルから削除
        MySQL.query.await('DELETE FROM player_vehicles WHERE plate = ?', {vehicle.plate})
        
        seizedCount = seizedCount + 1
    end
    
    return true, seizedCount
end

-- 車両返還処理
local function ReturnSeizedVehicles(citizenid, invoiceId)
    -- 押収された車両を取得
    local seizedVehicles = MySQL.query.await([[
        SELECT * FROM ng_seized_vehicles 
        WHERE citizenid = ? AND invoice_id = ? AND status = 'seized'
    ]], {citizenid, invoiceId})
    
    if not seizedVehicles or #seizedVehicles == 0 then
        return false, 0
    end
    
    local returnedCount = 0
    
    for _, vehicle in ipairs(seizedVehicles) do
        -- 車両をプレイヤーに返還（全カラム復元）
        MySQL.insert.await([[
            INSERT INTO player_vehicles (
                license, citizenid, vehicle, hash, mods, plate, 
                fakeplate, garage, fuel, engine, body, state, 
                depotprice, drivingdistance, status, balance, 
                paymentamount, paymentsleft, financetime, glovebox, trunk, 
                damage, in_garage, garage_id, nickname, mileage
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?)
        ]], {
            vehicle.license,
            vehicle.citizenid, 
            vehicle.vehicle, 
            vehicle.hash,
            vehicle.mods,
            vehicle.plate,
            vehicle.fakeplate,
            vehicle.garage,
            vehicle.fuel,
            vehicle.engine,
            vehicle.body,
            vehicle.depotprice,
            vehicle.drivingdistance,
            vehicle.status_original,
            vehicle.balance,
            vehicle.paymentamount,
            vehicle.paymentsleft,
            vehicle.financetime,
            vehicle.glovebox,
            vehicle.trunk,
            vehicle.damage,
            vehicle.garage_id,
            vehicle.nickname,
            vehicle.mileage
        })
        
        -- 押収テーブルを更新
        MySQL.update.await([[
            UPDATE ng_seized_vehicles 
            SET status = 'returned', returned_at = NOW() 
            WHERE id = ?
        ]], {vehicle.id})
        
        returnedCount = returnedCount + 1
    end
    
    return true, returnedCount
end

-- 特定のcitizenidの押収車両があるか確認
local function HasSeizedVehicles(citizenid)
    local result = MySQL.single.await([[
        SELECT COUNT(*) as count FROM ng_seized_vehicles 
        WHERE citizenid = ? AND status = 'seized'
    ]], {citizenid})
    
    return result and result.count > 0
end

-- 押収車両のinvoice_idを取得
local function GetSeizedVehicleInvoiceIds(citizenid)
    local results = MySQL.query.await([[
        SELECT DISTINCT invoice_id FROM ng_seized_vehicles 
        WHERE citizenid = ? AND status = 'seized'
    ]], {citizenid})
    
    local ids = {}
    if results then
        for _, row in ipairs(results) do
            table.insert(ids, row.invoice_id)
        end
    end
    return ids
end

-- プレイヤーデータの取得
lib.callback.register('ng-invoice:getPlayerData', function(source, targetId)
    local Player = QBCore.Functions.GetPlayer(targetId)
    if not Player then return nil end

    return {
        firstname = Player.PlayerData.charinfo.firstname,
        lastname = Player.PlayerData.charinfo.lastname,
        citizenid = Player.PlayerData.citizenid
    }
end)

-- 権限チェック
RegisterNetEvent('ng-invoice:server:checkPermission', function()
    local src = source
    local hasPermission = IsPlayerAceAllowed(src, Config.AdminGroup)
    TriggerClientEvent('ng-invoice:client:permissionResponse', src, hasPermission)
end)

-- 請求書番号生成
local function GenerateInvoiceNumber()
    return string.format("INV-%s-%04d", 
        os.date("%Y%m%d"),
        math.random(1, 999999)
    )
end

-- 請求内容の検証
local function ValidateInvoiceContent(job, content, amount)
    local lines = {}
    for line in content:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    local totalAmount = 0
    for _, line in ipairs(lines) do
        local found = false
        local itemLabel = line:match("(.-): %$")
        if itemLabel then
            for _, preset in ipairs(Config.JobInvoicePresets[job]) do
                if preset.label == itemLabel then
                    totalAmount = totalAmount + preset.amount
                    found = true
                    break
                end
            end
            if not found then return false end
        end
    end

    return totalAmount == amount
end

lib.callback.register('ng-invoice:createInvoice', function(source, data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false, 0 end

    if data.total_amount <= 0 then 
        TriggerClientEvent('QBCore:Notify', src, '無効な請求金額です', 'error')
        return false, 0 
    end
    
    -- 複数の受信者に対応
    local recipients = data.recipients
    if not recipients or #recipients == 0 then
        TriggerClientEvent('QBCore:Notify', src, '請求先が指定されていません', 'error')
        return false, 0
    end
    
    local successCount = 0
    
    -- 各受信者に対して請求書を作成
    for _, citizenid in ipairs(recipients) do
        local invoiceData = {
            invoice_number = GenerateInvoiceNumber(),
            title = data.title,
            content = data.content,
            sender_citizenid = Player.PlayerData.citizenid,
            sender_job = Player.PlayerData.job.name,
            recipient_citizenid = citizenid,
            total_amount = data.total_amount,
            discount_rate = data.discount_rate or 0,
            is_personal = data.is_personal,
            status = 'pending'
        }

        local success = MySQL.insert.await('INSERT INTO ng_invoices SET ?', {invoiceData})
        if success then
            successCount = successCount + 1
            
            -- Discord Webhookに通知
            SendToDiscord(invoiceData, "create")

            -- オンラインプレイヤーに通知（改良版）
            local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
            if targetPlayer then
                -- 専用イベントを使用
                TriggerClientEvent('ng-invoice:client:invoiceReceived', targetPlayer.PlayerData.source, invoiceData)
            end
        end
    end
    
    -- 少なくとも1つの請求書が作成できたか確認
    return successCount > 0, successCount
end)

-- 職業口座への入金処理
local function AddJobMoney(jobName, amount, reason)
    if Config.BankingSystem == 'renewed' then
        -- Renewed-Banking用の処理
        local success = exports['qb-management']:AddMoney(jobName, amount)
        if success then
            print(string.format("Job payment successful - Job: %s, Amount: %s", jobName, amount))
            return true
        else
            print(string.format("Failed to add money to job account - Job: %s", jobName))
            return false
        end
    elseif Config.BankingSystem == 'qb-management' then
        -- qb-management用の処理
        exports['qb-management']:AddMoney(jobName, amount)
        return true
    elseif Config.BankingSystem == 'qb' then
        -- QB-Banking用の処理（既存のコード）
        local result = MySQL.single.await('SELECT id FROM bank_accounts WHERE account_name = ? AND account_type = ?', {jobName, 'job'})
        
        if result then
            MySQL.update.await('UPDATE bank_accounts SET account_balance = account_balance + ? WHERE id = ?', 
                {amount, result.id})
            MySQL.insert.await('INSERT INTO bank_statements (account_name, amount, reason, statement_type) VALUES (?, ?, ?, ?)',
                {jobName, amount, reason or "Invoice Payment", 'deposit'})
            return true
        end
    else
        -- okokBanking用の処理（既存のコード）
        local society = MySQL.single.await('SELECT * FROM '..Config.Database.okok.societies..' WHERE society = ?', {jobName})
        
        if society then
            MySQL.update.await('UPDATE '..Config.Database.okok.societies..' SET value = value + ? WHERE society = ?', 
                {amount, jobName})
            MySQL.insert.await('INSERT INTO '..Config.Database.okok.transactions..' (receiver_identifier, receiver_name, sender_identifier, sender_name, date, value, type) VALUES (?, ?, ?, ?, ?, ?, ?)',
                {
                    jobName,
                    society.society_name,
                    'SYSTEM',
                    'System',
                    os.date('%Y-%m-%d %H:%M:%S'),
                    amount,
                    'invoice_payment'
                })
            return true
        end
    end
    return false
end

-- 口座残高確認関数の追加
local function GetJobBalance(jobName)
    if Config.BankingSystem == 'renewed' then
        -- Renewed-Banking用
        return exports['qb-management']:GetAccount(jobName)
    elseif Config.BankingSystem == 'qb-management' then
        -- qb-management用
        return exports['qb-management']:GetAccount(jobName)
    elseif Config.BankingSystem == 'qb' then
        -- QB-Banking用
        local result = MySQL.single.await('SELECT account_balance FROM bank_accounts WHERE account_name = ? AND account_type = ?', {jobName, 'job'})
        return result and result.account_balance or 0
    else
        -- okokBanking用
        local result = MySQL.single.await('SELECT value FROM '..Config.Database.okok.societies..' WHERE society = ?', {jobName})
        return result and result.value or 0
    end
end

-- 支払い処理の共通関数
local function ProcessPayment(amount, jobName, citizenId, isOnline, isPersonal)
    if isPersonal then
        -- 個人請求の場合の処理
        if isOnline then
            local sender = QBCore.Functions.GetPlayerByCitizenId(citizenId)
            if sender then
                sender.Functions.AddMoney('bank', amount, "invoice-received")
            end
        else
            local result = MySQL.single.await('SELECT money FROM players WHERE citizenid = ?', {citizenId})
            if result and result.money then
                local money = json.decode(result.money)
                money.bank = money.bank + amount
                MySQL.update.await('UPDATE players SET money = ? WHERE citizenid = ?', 
                    {json.encode(money), citizenId})
            end
        end
    else
        -- 職業による分配
        local ratio = Config.JobPaymentRatio[jobName] or 0
        local jobAmount = math.floor(amount * (ratio / 100))
        local personalAmount = amount - jobAmount

        -- 職業口座への入金
        AddJobMoney(jobName, jobAmount, "Invoice Payment")

        -- 個人口座への入金
        if isOnline then
            local sender = QBCore.Functions.GetPlayerByCitizenId(citizenId)
            if sender then
                sender.Functions.AddMoney('bank', personalAmount, "invoice-received")
            end
        else
            local result = MySQL.single.await('SELECT money FROM players WHERE citizenid = ?', {citizenId})
            if result and result.money then
                local money = json.decode(result.money)
                money.bank = money.bank + personalAmount
                MySQL.update.await('UPDATE players SET money = ? WHERE citizenid = ?', 
                    {json.encode(money), citizenId})
            end
        end
    end
end

-- 請求書の支払い
lib.callback.register('ng-invoice:payInvoice', function(source, invoiceId, paymentType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end

    -- 請求書の取得（pendingまたはseizedの請求書を取得）
    local invoice = MySQL.single.await('SELECT * FROM ng_invoices WHERE id = ? AND (status = ? OR status = ?)', 
        {invoiceId, 'pending', 'seized'})
    if not invoice then return false end

    -- 支払い対象者の確認
    if invoice.recipient_citizenid ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, '無効な請求書です', 'error')
        return false
    end

    -- 所持金チェック
    if Player.PlayerData.money[paymentType] < invoice.total_amount then
        TriggerClientEvent('QBCore:Notify', src, Config.Messages.not_enough_money, 'error')
        return false
    end

    -- 支払い処理
    Player.Functions.RemoveMoney(paymentType, invoice.total_amount, "invoice-payment")
    
    -- 請求者への入金処理
    local sender = QBCore.Functions.GetPlayerByCitizenId(invoice.sender_citizenid)

    -- 支払い成功時に Discord に通知
    SendToDiscord(invoice, "paid")
    
    -- 入金処理の実行
    ProcessPayment(
        invoice.total_amount, 
        invoice.sender_job, 
        invoice.sender_citizenid, 
        sender ~= nil, 
        invoice.is_personal
    )

    -- オンラインの請求者に通知
    if sender then
        TriggerClientEvent('QBCore:Notify', sender.PlayerData.source, "請求書の支払いを受け取りました", 'success')
    end

    -- 押収中の請求書の場合、車両を返還
    if invoice.status == 'seized' then
        local returnSuccess, returnedCount = ReturnSeizedVehicles(Player.PlayerData.citizenid, invoiceId)
        if returnSuccess and returnedCount > 0 then
            TriggerClientEvent('QBCore:Notify', src, 
                string.format('支払いが完了し、%d台の車両が返還されました', returnedCount), 
                'success')
        end
    end

    -- 請求書の削除
    MySQL.query.await('DELETE FROM ng_invoices WHERE id = ?', {invoiceId})

    return true
end)

-- 複数請求書の一括支払い
lib.callback.register('ng-invoice:payMultipleInvoices', function(source, invoiceIds, paymentType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false, 0 end
    
    if not invoiceIds or #invoiceIds == 0 then
        TriggerClientEvent('QBCore:Notify', src, '請求書が選択されていません', 'error')
        return false, 0
    end
    
    -- 請求書の取得（pendingまたはseizedの請求書を取得）
    local invoicesQuery = string.format('SELECT * FROM ng_invoices WHERE id IN (%s) AND (status = ? OR status = ?)', 
        table.concat(invoiceIds, ','))
    local invoices = MySQL.query.await(invoicesQuery, {'pending', 'seized'})
    
    if not invoices or #invoices == 0 then
        TriggerClientEvent('QBCore:Notify', src, '有効な請求書がありません', 'error')
        return false, 0
    end
    
    -- 本人宛の請求書のみフィルタリング
    local validInvoices = {}
    local totalAmount = 0
    
    for _, invoice in ipairs(invoices) do
        if invoice.recipient_citizenid == Player.PlayerData.citizenid then
            table.insert(validInvoices, invoice)
            totalAmount = totalAmount + invoice.total_amount
        end
    end
    
    if #validInvoices == 0 then
        TriggerClientEvent('QBCore:Notify', src, '支払い可能な請求書がありません', 'error')
        return false, 0
    end
    
    -- 所持金チェック
    if Player.PlayerData.money[paymentType] < totalAmount then
        TriggerClientEvent('QBCore:Notify', src, Config.Messages.not_enough_money, 'error')
        return false, 0
    end
    
    -- 支払い処理
    Player.Functions.RemoveMoney(paymentType, totalAmount, "bulk-invoice-payment")
    
    local totalReturnedVehicles = 0
    
    -- 各請求書の処理
    for _, invoice in ipairs(validInvoices) do
        -- 請求者へのお金の振り分け
        local sender = QBCore.Functions.GetPlayerByCitizenId(invoice.sender_citizenid)
        
        -- Discord通知
        SendToDiscord(invoice, "paid")
        
        -- 入金処理
        ProcessPayment(
            invoice.total_amount,
            invoice.sender_job,
            invoice.sender_citizenid,
            sender ~= nil,
            invoice.is_personal
        )
        
        -- オンラインの請求者に通知
        if sender then
            TriggerClientEvent('QBCore:Notify', sender.PlayerData.source, "請求書の支払いを受け取りました", 'success')
        end
        
        -- 押収中の請求書の場合、車両を返還
        if invoice.status == 'seized' then
            local returnSuccess, returnedCount = ReturnSeizedVehicles(Player.PlayerData.citizenid, invoice.id)
            if returnSuccess then
                totalReturnedVehicles = totalReturnedVehicles + returnedCount
            end
        end
        
        -- 請求書の削除
        MySQL.query.await('DELETE FROM ng_invoices WHERE id = ?', {invoice.id})
    end
    
    -- 車両が返還された場合は通知
    if totalReturnedVehicles > 0 then
        TriggerClientEvent('QBCore:Notify', src, 
            string.format('支払いが完了し、%d台の車両が返還されました', totalReturnedVehicles), 
            'success')
    end
    
    return true, totalAmount
end)

local function IsPlayerBoss(Player)
    if not Player or not Player.PlayerData or not Player.PlayerData.job then 
        return false
    end

    -- QBX の場合
    if Config.QBType == 'qbx' then
        return Player.PlayerData.job.isboss == true
    end

    -- QB-Core の場合は QBShared.Jobs から確認
    local job = QBCore.Shared.Jobs[Player.PlayerData.job.name]
    if not job or not job.grades then
        return false
    end

    local gradeLevel = tostring(Player.PlayerData.job.grade.level)
    local gradeData = job.grades[gradeLevel]
    
    return gradeData and gradeData.isboss == true
end

-- ボスメニュー用の請求書一覧取得コールバックの修正
lib.callback.register('ng-invoice:getBossInvoices', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return {} end

    -- ボス権限チェック
    if not IsPlayerBoss(Player) then
        TriggerClientEvent('QBCore:Notify', src, 'このメニューにアクセスする権限がありません', 'error')
        return {}
    end

    -- 該当ジョブの請求書を取得（collationを明示的に指定）
    local invoices = MySQL.query.await([[
        SELECT 
            i.id,
            i.invoice_number,
            i.title,
            i.content,
            i.sender_citizenid,
            i.sender_job,
            i.recipient_citizenid,
            i.total_amount,
            i.discount_rate,
            i.is_personal,
            i.status,
            DATE_FORMAT(i.created_at, '%Y年%m月%d日 %H:%i') as created_at,
            i.paid_at,
            CONCAT(
                COALESCE(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')), '不明'), ' ',
                COALESCE(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')), '')
            ) COLLATE utf8mb4_unicode_ci as recipient_name,
            CONCAT(
                COALESCE(JSON_UNQUOTE(JSON_EXTRACT(sp.charinfo, '$.firstname')), '不明'), ' ',
                COALESCE(JSON_UNQUOTE(JSON_EXTRACT(sp.charinfo, '$.lastname')), '')
            ) COLLATE utf8mb4_unicode_ci as sender_name
        FROM ng_invoices i
        LEFT JOIN players p ON p.citizenid COLLATE utf8mb4_unicode_ci = i.recipient_citizenid COLLATE utf8mb4_unicode_ci
        LEFT JOIN players sp ON sp.citizenid COLLATE utf8mb4_unicode_ci = i.sender_citizenid COLLATE utf8mb4_unicode_ci
        WHERE i.sender_job COLLATE utf8mb4_unicode_ci = ? COLLATE utf8mb4_unicode_ci
        ORDER BY i.created_at DESC
    ]], {Player.PlayerData.job.name})

    return invoices or {}
end)

-- 請求書の削除
lib.callback.register('ng-invoice:deleteInvoice', function(source, invoiceId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end

    -- ボス権限チェック
    if not IsPlayerBoss(Player) then
        return false
    end

    -- 請求書の所有権確認
    local invoice = MySQL.single.await('SELECT sender_job FROM ng_invoices WHERE id = ?', {invoiceId})
    if not invoice or invoice.sender_job ~= Player.PlayerData.job.name then
        return false
    end

    -- 削除処理
    local success = MySQL.update.await('DELETE FROM ng_invoices WHERE id = ?', {invoiceId})
    return success ~= nil
end)

-- 強制執行処理
lib.callback.register('ng-invoice:forcePayment', function(source, invoiceId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
 
    -- ボス権限チェック
    if not IsPlayerBoss(Player) then
        return false, Config.Messages.no_permission
    end
 
    -- 強制執行権限の確認
    if not Config.ForcePaymentJobs[Player.PlayerData.job.name] then
        return false, Config.Messages.no_permission
    end
 
    -- 請求書の取得と確認
    local invoice = MySQL.single.await('SELECT * FROM ng_invoices WHERE id = ? AND status = ?', 
        {invoiceId, 'pending'})
    if not invoice or invoice.sender_job ~= Player.PlayerData.job.name then
        return false, '無効な請求書です'
    end
 
    -- 支払い対象者の所持金確認
    local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(invoice.recipient_citizenid)
    local paidAmount = 0
    local remainingAmount = invoice.total_amount
    local vehiclesSeized = false
    local seizedCount = 0
    
    -- 残高チェックと引き落とし処理
    if targetPlayer then
        -- オンラインプレイヤーの場合
        local bankBalance = targetPlayer.PlayerData.money.bank or 0
        local cashBalance = targetPlayer.PlayerData.money.cash or 0
        local totalBalance = bankBalance + cashBalance
        
        -- 銀行から可能な限り引き落とし
        local bankDeduct = math.min(bankBalance, remainingAmount)
        if bankDeduct > 0 then
            targetPlayer.Functions.RemoveMoney('bank', bankDeduct, "forced-invoice-payment")
            paidAmount = paidAmount + bankDeduct
            remainingAmount = remainingAmount - bankDeduct
        end
        
        -- 残額があれば現金から引き落とし
        if remainingAmount > 0 then
            local cashDeduct = math.min(cashBalance, remainingAmount)
            if cashDeduct > 0 then
                targetPlayer.Functions.RemoveMoney('cash', cashDeduct, "forced-invoice-payment")
                paidAmount = paidAmount + cashDeduct
                remainingAmount = remainingAmount - cashDeduct
            end
        end
        
        -- まだ残額がある場合は車両押収
        if remainingAmount > 0 then
            local success, count = SeizeVehicles(
                invoice.recipient_citizenid, 
                invoiceId, 
                Player.PlayerData.citizenid, 
                Player.PlayerData.job.name,
                remainingAmount
            )
            if success then
                vehiclesSeized = true
                seizedCount = count
                -- 請求書のステータスを押収中に変更（削除しない）
                MySQL.update.await('UPDATE ng_invoices SET status = ? WHERE id = ?', {'seized', invoiceId})
                
                -- 対象者に通知
                TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 
                    string.format('支払いが完了できなかったため、%d台の車両が押収されました。残額$%sを支払うと車両が返還されます。', seizedCount, remainingAmount), 
                    'error', 10000)
                
                -- Webhook通知
                SendToDiscord(invoice, "force", Player.PlayerData.citizenid)
                
                return true, string.format('強制執行: $%s張收、残額$%sのため%d台の車両を押収しました', paidAmount, remainingAmount, seizedCount)
            else
                -- 車両もない場合
                TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, '請求書の強制執行が試みられましたが、所持金が不足しています', 'error')
                return false, '対象者の所持金が不足しており、押収可能な車両もありません'
            end
        end
    else
        -- オフラインプレイヤーの場合
        local result = MySQL.single.await('SELECT money FROM players WHERE citizenid = ?', {invoice.recipient_citizenid})
        if not result or not result.money then
            return false, '対象プレイヤーのデータが見つかりません'
        end
        
        local money = json.decode(result.money)
        local bankBalance = money.bank or 0
        local cashBalance = money.cash or 0
        
        -- 銀行から可能な限り引き落とし
        local bankDeduct = math.min(bankBalance, remainingAmount)
        if bankDeduct > 0 then
            money.bank = bankBalance - bankDeduct
            paidAmount = paidAmount + bankDeduct
            remainingAmount = remainingAmount - bankDeduct
        end
        
        -- 残額があれば現金から引き落とし
        if remainingAmount > 0 then
            local cashDeduct = math.min(cashBalance, remainingAmount)
            if cashDeduct > 0 then
                money.cash = cashBalance - cashDeduct
                paidAmount = paidAmount + cashDeduct
                remainingAmount = remainingAmount - cashDeduct
            end
        end
        
        -- データベース更新
        MySQL.update.await('UPDATE players SET money = ? WHERE citizenid = ?', 
            {json.encode(money), invoice.recipient_citizenid})
        
        -- まだ残額がある場合は車両押収
        if remainingAmount > 0 then
            local success, count = SeizeVehicles(
                invoice.recipient_citizenid, 
                invoiceId, 
                Player.PlayerData.citizenid, 
                Player.PlayerData.job.name,
                remainingAmount
            )
            if success then
                vehiclesSeized = true
                seizedCount = count
                -- 請求書のステータスを押収中に変更
                MySQL.update.await('UPDATE ng_invoices SET status = ? WHERE id = ?', {'seized', invoiceId})
                
                -- Webhook通知
                SendToDiscord(invoice, "force", Player.PlayerData.citizenid)
                
                return true, string.format('強制執行: $%s張收、残額$%sのため%d台の車両を押収しました', paidAmount, remainingAmount, seizedCount)
            else
                return false, '対象者の所持金が不足しており、押収可能な車両もありません'
            end
        end
    end
 
    -- 全額支払い完了の場合のみ、職業口座への入金と送信者への支払い処理
    if invoice.is_personal then
        -- 個人請求の場合、全額を送信者の個人口座へ
        local sender = QBCore.Functions.GetPlayerByCitizenId(invoice.sender_citizenid)
        if sender then
            sender.Functions.AddMoney('bank', invoice.total_amount, "forced-invoice-received")
        else
            local senderResult = MySQL.single.await('SELECT money FROM players WHERE citizenid = ?', {invoice.sender_citizenid})
            if senderResult and senderResult.money then
                local senderMoney = json.decode(senderResult.money)
                senderMoney.bank = (senderMoney.bank or 0) + invoice.total_amount
                MySQL.update.await('UPDATE players SET money = ? WHERE citizenid = ?', 
                    {json.encode(senderMoney), invoice.sender_citizenid})
            end
        end
    else
        -- 職業による分配
        local ratio = Config.JobPaymentRatio[invoice.sender_job] or 50
        local jobAmount = math.floor(invoice.total_amount * (ratio / 100))
        local personalAmount = invoice.total_amount - jobAmount
 
        -- 職業口座への入金
        AddJobMoney(invoice.sender_job, jobAmount, "Forced Invoice Payment")
 
        -- 送信者への個人支払い
        local sender = QBCore.Functions.GetPlayerByCitizenId(invoice.sender_citizenid)
        if sender then
            sender.Functions.AddMoney('bank', personalAmount, "forced-invoice-received")
        else
            local senderResult = MySQL.single.await('SELECT money FROM players WHERE citizenid = ?', {invoice.sender_citizenid})
            if senderResult and senderResult.money then
                local senderMoney = json.decode(senderResult.money)
                senderMoney.bank = (senderMoney.bank or 0) + personalAmount
                MySQL.update.await('UPDATE players SET money = ? WHERE citizenid = ?', 
                    {json.encode(senderMoney), invoice.sender_citizenid})
            end
        end
    end
 
    -- 請求書の削除
    MySQL.query.await('DELETE FROM ng_invoices WHERE id = ?', {invoiceId})
 
    -- 処理完了通知
    if targetPlayer then
        TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, '請求書が強制執行されました', 'error')
    end

    -- 強制執行成功時にWebhook通知を送信
    SendToDiscord(invoice, "force", Player.PlayerData.citizenid)

    return true, Config.Messages.force_payment_success
end)

-- 請求書一覧取得（送信者情報付き）
lib.callback.register('ng-invoice:getInvoices', function(source, type)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return {} end

    local citizenid = Player.PlayerData.citizenid

    -- 請求書を取得（pendingまたはseizedの請求書を取得）
    local invoices = MySQL.query.await([[
        SELECT 
            i.*,
            DATE_FORMAT(i.created_at, '%Y年%m月%d日 %H:%i') as created_at,
            CONCAT(
                COALESCE(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')), '不明'), ' ',
                COALESCE(JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname')), '')
            ) COLLATE utf8mb4_unicode_ci as sender_name
        FROM ng_invoices i
        LEFT JOIN players p ON p.citizenid COLLATE utf8mb4_unicode_ci = i.sender_citizenid COLLATE utf8mb4_unicode_ci
        WHERE i.recipient_citizenid = ? 
        AND (i.status = 'pending' OR i.status = 'seized')
        ORDER BY i.created_at DESC
    ]], {citizenid})

    if not invoices then return {} end

    return invoices
end)

-- デバッグ用：リソース起動時にメッセージを表示
CreateThread(function()
    print('Invoice system callbacks registered')
end)

-- リソース起動時の初期化
CreateThread(function()
    InitializeDatabase()
end)