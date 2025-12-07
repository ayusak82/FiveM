local QBCore = exports['qb-core']:GetCoreObject()
local isAdmin = false

-- 通知ヘルパー関数
function SendInvoiceNotification(message, type, title)
    if Config.Notifications.useOxNotify and lib and lib.notify then
        lib.notify({
            title = title or '請求書システム',
            description = message,
            type = type or 'info',
            duration = Config.Notifications.duration
        })
    else
        QBCore.Functions.Notify(message, type or 'info', Config.Notifications.duration)
    end
    
    if Config.Notifications.playSound then
        PlaySound(-1, Config.Notifications.soundName, Config.Notifications.soundSet, 0, 0, 1)
    end
end

function IsPlayerBoss()
    local Player = QBCore.Functions.GetPlayerData()
    if not Player or not Player.job then 
        return {
            isBoss = false
        }
    end

    -- QBX の場合
    if Config.QBType == 'qbx' then
        return {
            isBoss = Player.job.isboss == true
        }
    end

    -- QB-Core の場合は QBShared.Jobs から確認
    local job = QBCore.Shared.Jobs[Player.job.name]
    if not job or not job.grades then
        return {
            isBoss = false
        }
    end

    local gradeLevel = tostring(Player.job.grade.level)
    local gradeData = job.grades[gradeLevel]
    
    -- gradeData が存在し、明示的に isboss = true が設定されているか確認
    return {
        isBoss = gradeData and gradeData.isboss == true
    }
end

-- 日付フォーマット用のヘルパー関数を追加
local function FormatDateTime(mysqlDateTime)
    -- MySQL形式の日時文字列から年、月、日、時、分を抽出
    local year, month, day, hour, min = mysqlDateTime:match("(%d+)-(%d+)-(%d+) (%d+):(%d+)")
    if year then
        return string.format("%s年%s月%s日 %s:%s", year, month, day, hour, min)
    end
    return mysqlDateTime -- フォーマットできない場合は元の文字列を返す
end

-- 権限チェック
RegisterNetEvent('ng-invoice:client:permissionResponse', function(hasPermission)
    isAdmin = hasPermission
end)

-- 請求書作成メニュー
local function OpenCreateInvoiceMenu()
    -- 近くのプレイヤーを取得
    local playerPed = PlayerPedId()
    local players = GetActivePlayers()
    local nearbyPlayers = {}

    for _, player in ipairs(players) do
        local targetPed = GetPlayerPed(player)
        local targetCoords = GetEntityCoords(targetPed)
        local distance = #(GetEntityCoords(playerPed) - targetCoords)
        
        if distance <= 3.0 and player ~= PlayerId() then
            local targetId = GetPlayerServerId(player)
            local playerData = lib.callback.await('ng-invoice:getPlayerData', false, targetId)
            if playerData then
                table.insert(nearbyPlayers, {
                    label = string.format("%s [%s] [%s]", 
                        playerData.firstname .. " " .. playerData.lastname,
                        targetId,
                        playerData.citizenid
                    ),
                    value = playerData.citizenid
                })
            end
        end
    end

    if #nearbyPlayers == 0 then
        QBCore.Functions.Notify('近くにプレイヤーがいません', 'error')
        return
    end

    local playerJob = QBCore.Functions.GetPlayerData().job.name
    local hasJobAccess = Config.JobList[playerJob] or false
    local inputElements = {
        {
            type = 'input',
            label = '請求書名',
            placeholder = '請求書の名前を入力してください',
            required = true
        }
    }

    -- プリセット選択肢の作成（対象職業のみ）
    if hasJobAccess and Config.JobInvoicePresets[playerJob] then
        local presetOptions = {}
        for _, preset in ipairs(Config.JobInvoicePresets[playerJob]) do
            table.insert(presetOptions, {
                label = string.format("%s ($%s)", preset.label, preset.amount),
                value = preset.label,
                description = preset.amount
            })
        end
        
        table.insert(inputElements, {
            type = 'multi-select',
            label = '請求内容',
            options = presetOptions
        })
    end

    -- 割引入力フィールドを追加
    table.insert(inputElements, {
        type = 'number',
        label = '割引率 (%)',
        description = '0-100までの割引率を入力してください',
        default = 0,
        min = 0,
        max = 100
    })

    -- その他の金額入力フィールド（すべての職業で使用可能）
    table.insert(inputElements, {
        type = 'number',
        label = 'その他の金額',
        description = '請求金額を入力してください',
        default = 0,
        min = 0
    })

    -- プリセット職業の場合のみ個人請求オプションを表示
    if hasJobAccess then
        table.insert(inputElements, {
            type = 'checkbox',
            label = '個人請求',
            description = 'チェックを入れると全額が個人の手持ちになります'
        })
    end

    table.insert(inputElements, {
        type = 'multi-select',
        label = '請求先 (複数選択可)',
        options = nearbyPlayers,
        required = true
    })

    local input = lib.inputDialog('請求書作成', inputElements)
    if not input then return end

    local totalAmount = 0
    local selectedContents = {}
    local contentIndex = 2
    local discountIndex = hasJobAccess and (Config.JobInvoicePresets[playerJob] and 3 or 2) or 2
    local otherAmountIndex = hasJobAccess and (Config.JobInvoicePresets[playerJob] and 4 or 3) or 3
    local recipientIndex = hasJobAccess and (Config.JobInvoicePresets[playerJob] and 6 or 5) or 4

    -- プリセットがある職業の場合の金額計算
    if hasJobAccess and Config.JobInvoicePresets[playerJob] then
        if input[contentIndex] then
            for _, selectedLabel in ipairs(input[contentIndex]) do
                for _, preset in ipairs(Config.JobInvoicePresets[playerJob]) do
                    if preset.label == selectedLabel then
                        totalAmount = totalAmount + preset.amount
                        table.insert(selectedContents, string.format("%s: $%s", preset.label, preset.amount))
                        break
                    end
                end
            end
        end
    end

    -- その他の金額の処理
    if input[otherAmountIndex] and input[otherAmountIndex] > 0 then
        totalAmount = totalAmount + input[otherAmountIndex]
        table.insert(selectedContents, string.format("その他: $%s", input[otherAmountIndex]))
    end

    -- 割引の適用
    local discountRate = input[discountIndex] or 0
    if discountRate > 0 then
        local discountAmount = math.floor(totalAmount * (discountRate / 100))
        totalAmount = totalAmount - discountAmount
        table.insert(selectedContents, string.format("割引 (%s%%): -$%s", discountRate, discountAmount))
    end

    -- 金額チェック
    if totalAmount == 0 then
        QBCore.Functions.Notify('金額を入力してください', 'error')
        return
    end

    -- 個人請求フラグ（プリセット職業の場合のみ）
    local isPersonal = false
    if hasJobAccess then
        local personalIndex = hasJobAccess and (Config.JobInvoicePresets[playerJob] and 5 or 4) or 4
        isPersonal = input[personalIndex] and true or false
    end

    -- 請求書作成（複数の受信者対応）
    local recipients = input[recipientIndex]
    if type(recipients) ~= 'table' then
        recipients = {recipients} -- 単一選択の場合はテーブルに変換
    end
    
    local invoiceData = {
        title = input[1],
        content = #selectedContents > 0 and table.concat(selectedContents, "\n") or string.format("その他: $%s", totalAmount),
        total_amount = totalAmount,
        recipients = recipients,
        is_personal = isPersonal,
        discount_rate = discountRate
    }
    
    local success, count = lib.callback.await('ng-invoice:createInvoice', false, invoiceData)

    if success then
        QBCore.Functions.Notify(string.format('%d人に%s', count, Config.Messages.invoice_created), 'success')
    else
        QBCore.Functions.Notify('請求書の作成に失敗しました', 'error')
    end
end

-- OpenPaymentMethodMenu関数内の修正
local function OpenPaymentMethodMenu(invoice)
    local contentText = string.format(
        '請求金額: $%s\n%s\n\n支払い方法を選択してください',
        invoice.total_amount,
        invoice.discount_rate > 0 and string.format('(割引率: %s%%適用済み)', invoice.discount_rate) or ''
    )

    local alert = lib.alertDialog({
        header = '支払い方法の選択',
        content = contentText,
        cancel = true,
        labels = {
            confirm = 'キャッシュで支払う',
            cancel = '銀行で支払う'
        }
    })

    if alert then
        local paymentType = alert == 'confirm' and 'cash' or 'bank'
        local success = lib.callback.await('ng-invoice:payInvoice', false, invoice.id, paymentType)
        if success then
            QBCore.Functions.Notify(Config.Messages.invoice_paid, 'success')
            OpenPaymentMenu() -- メニューを更新
        end
    end
end

-- 複数の請求書支払い用メソッド
local function PayMultipleInvoices(invoiceIds, paymentType)
    local success, totalAmount = lib.callback.await('ng-invoice:payMultipleInvoices', false, invoiceIds, paymentType)
    if success then
        QBCore.Functions.Notify(string.format('%d件の請求書を$%sで支払いました', #invoiceIds, totalAmount), 'success')
        return true
    else
        QBCore.Functions.Notify('支払いに失敗しました', 'error')
        return false
    end
end

-- 支払い方法選択メニュー（複数請求書用）
local function OpenBulkPaymentMethodMenu(selectedInvoices)
    local totalAmount = 0
    for _, invoice in ipairs(selectedInvoices) do
        totalAmount = totalAmount + invoice.total_amount
    end

    local contentText = string.format(
        '合計%d件の請求書\n合計金額: $%s\n\n支払い方法を選択してください',
        #selectedInvoices,
        totalAmount
    )

    local alert = lib.alertDialog({
        header = 'まとめて支払い - 支払い方法の選択',
        content = contentText,
        cancel = true,
        labels = {
            confirm = 'キャッシュで支払う',
            cancel = '銀行で支払う'
        }
    })

    if alert then
        local paymentType = alert == 'confirm' and 'cash' or 'bank'
        local invoiceIds = {}
        for _, invoice in ipairs(selectedInvoices) do
            table.insert(invoiceIds, invoice.id)
        end
        return PayMultipleInvoices(invoiceIds, paymentType)
    end
    return false
end

-- 前方宣言
local OpenPaymentMenu

-- 複数請求書選択メニュー
function OpenBulkPaymentSelectionMenu(pendingInvoices)
    if #pendingInvoices == 0 then
        QBCore.Functions.Notify('未払いの請求書はありません', 'info')
        return
    end

    local totalAmount = 0
    local selectedInvoices = {}
    
    -- 請求書のチェックボックス選択肢を作成
    local checkboxOptions = {}
    for _, invoice in ipairs(pendingInvoices) do
        local statusLabel = invoice.status == 'seized' and ' [車両押収中]' or ''
        table.insert(checkboxOptions, {
            label = string.format("%s - $%s [%s]%s", 
                invoice.sender_name or "不明", 
                invoice.total_amount, 
                invoice.sender_job,
                statusLabel
            ),
            description = string.format('%s\n作成日: %s', invoice.content, invoice.created_at),
            value = invoice.id
        })
    end
    
    -- 複数選択ダイアログを表示
    local input = lib.inputDialog('まとめて支払い', {
        {
            type = 'multi-select',
            label = '支払う請求書を選択',
            options = checkboxOptions,
            required = true
        }
    })
    
    if not input or #input[1] == 0 then return end
    
    -- 選択された請求書のIDを取得
    local selectedIds = input[1]
    
    -- 選択された請求書を取得して合計金額を計算
    for _, invoice in ipairs(pendingInvoices) do
        for _, id in ipairs(selectedIds) do
            if invoice.id == id then
                table.insert(selectedInvoices, invoice)
                totalAmount = totalAmount + invoice.total_amount
                break
            end
        end
    end
    
    if #selectedInvoices == 0 then
        QBCore.Functions.Notify('請求書が選択されていません', 'error')
        return
    end
    
    -- 確認ダイアログを表示
    local confirm = lib.alertDialog({
        header = 'まとめて支払いの確認',
        content = string.format('選択した%d件の請求書\n合計金額: $%s\n\n支払いを続けますか？', 
            #selectedInvoices, 
            totalAmount
        ),
        cancel = true,
        labels = {
            confirm = '支払う',
            cancel = 'キャンセル'
        }
    })
    
    if confirm == 'confirm' then
        OpenBulkPaymentMethodMenu(selectedInvoices)
    end
end

-- 支払いメニュー
OpenPaymentMenu = function()
    local invoices = lib.callback.await('ng-invoice:getInvoices', false, 'received')
    
    if not invoices then 
        QBCore.Functions.Notify('未払いの請求書はありません', 'info')
        return 
    end

    -- ステータスがpendingまたはseizedの請求書のみ表示
    local pendingInvoices = {}
    for _, invoice in ipairs(invoices) do
        if invoice.status == 'pending' or invoice.status == 'seized' then
            table.insert(pendingInvoices, invoice)
        end
    end

    if #pendingInvoices == 0 then
        QBCore.Functions.Notify('未払いの請求書はありません', 'info')
        return
    end

    local options = {}
    
    -- 個別の請求書リスト
    for _, invoice in ipairs(pendingInvoices) do
        local statusText = invoice.status == 'seized' and ' [車両押収中]' or ''
        local titleColor = invoice.status == 'seized' and '~r~' or ''
        
        table.insert(options, {
            title = string.format("%s%s [%s]%s", titleColor, invoice.sender_name or "不明", invoice.sender_citizenid, statusText),
            description = string.format('職業: %s\n%s\n合計金額: $%s\n作成日: %s%s',
                invoice.sender_job,
                invoice.content,
                invoice.total_amount,
                invoice.created_at,
                invoice.status == 'seized' and '\n※支払い完了で車両が返還されます' or ''
            ),
            metadata = {
                {label = '請求内容', value = invoice.content},
                {label = '請求者', value = invoice.sender_name},
                {label = '職業', value = invoice.sender_job},
                {label = '金額', value = '$' .. invoice.total_amount},
                {label = '割引率', value = invoice.discount_rate .. '%'},
                {label = '作成日時', value = invoice.created_at},
                {label = 'ステータス', value = invoice.status == 'seized' and '車両押収中' or '未払い'}
            },
            onSelect = function()
                local contentText = string.format('請求者: %s [%s]\n職業: %s\n\n請求内容:\n%s\n\n合計金額: $%s\n作成日時: %s',
                    invoice.sender_name or "不明",
                    invoice.sender_citizenid,
                    invoice.sender_job,
                    invoice.content,
                    invoice.total_amount,
                    invoice.created_at
                )
                
                if invoice.status == 'seized' then
                    contentText = contentText .. '\n\n※この請求書の支払いを完了すると、押収された車両が返還されます。'
                end
                
                contentText = contentText .. '\n\n支払い方法を選択しますか？'
                
                local alert = lib.alertDialog({
                    header = invoice.status == 'seized' and '請求書の支払い (車両押収中)' or '請求書の支払い',
                    content = contentText,
                    cancel = true,
                    labels = {
                        confirm = '支払う',
                        cancel = 'キャンセル'
                    }
                })

                if alert == 'confirm' then
                    OpenPaymentMethodMenu(invoice)
                end
            end
        })
    end

    -- 複数支払いメニューを最上部に追加
    table.insert(options, 1, {
        title = 'まとめて支払い',
        description = string.format('%d件の請求書をまとめて支払います', #pendingInvoices),
        arrow = true,
        onSelect = function()
            OpenBulkPaymentSelectionMenu(pendingInvoices)
        end
    })

    lib.registerContext({
        id = 'invoice_payment_menu',
        title = '請求書支払い',
        options = options
    })

    lib.showContext('invoice_payment_menu')
end

-- ボスメニュー用の請求書リスト表示
local function OpenBossInvoiceMenu()
    local Player = QBCore.Functions.GetPlayerData()
    if not IsPlayerBoss(Player) then
        QBCore.Functions.Notify('このメニューにアクセスする権限がありません', 'error')
        return
    end

    local invoices = lib.callback.await('ng-invoice:getBossInvoices', false)
    if not invoices or #invoices == 0 then
        QBCore.Functions.Notify('請求書がありません', 'info')
        return
    end

    local options = {}
    for _, invoice in ipairs(invoices) do
        local status_text = '未払い'
        if invoice.status == 'paid' then
            status_text = '支払済'
        elseif invoice.status == 'seized' then
            status_text = '車両押収中'
        end
        local amount_text = string.format('$%s', invoice.total_amount)
        
        table.insert(options, {
            title = string.format('%s - %s', invoice.title, status_text),
            description = string.format('請求先: %s\n金額: %s',
                invoice.recipient_name,
                amount_text
            ),
            metadata = {
                {label = '請求内容', value = invoice.content},
                {label = '請求者', value = invoice.sender_name},
                {label = '割引率', value = invoice.discount_rate .. '%'},
                {label = '作成日時', value = FormatDateTime(invoice.created_at)}
            },
            onSelect = function()
                -- プレイヤーデータの取得
                local PlayerData = QBCore.Functions.GetPlayerData()
                local isForcePaymentAllowed = Config.ForcePaymentJobs[PlayerData.job.name]
                
                local labels = {
                    cancel = '削除',
                    confirm = isForcePaymentAllowed and '強制執行' or nil
                }

                local alert = lib.alertDialog({
                    header = '請求書の操作',
                    content = string.format('請求書ID: %d\n請求先: %s\n金額: %s\n\n操作を選択してください',
                        invoice.id,
                        invoice.recipient_name,
                        amount_text
                    ),
                    labels = labels,
                    cancel = true
                })

                if alert == 'confirm' and isForcePaymentAllowed then
                    -- 強制執行の確認画面
                    local confirmForce = lib.alertDialog({
                        header = '強制執行の確認',
                        content = string.format('以下の請求書を強制執行しますか？\n\n請求先: %s\n金額: %s\n\n※この操作は取り消せません。\n※所持金が不足している場合、車両が押収されます。',
                            invoice.recipient_name,
                            amount_text
                        ),
                        labels = {
                            confirm = '実行する',
                            cancel = 'キャンセル'
                        }
                    })

                    if confirmForce == 'confirm' then
                        -- 強制執行処理
                        local success, message = lib.callback.await('ng-invoice:forcePayment', false, invoice.id)
                        QBCore.Functions.Notify(message, success and 'success' or 'error')
                        if success then
                            OpenBossInvoiceMenu() -- メニューを更新
                        end
                    end
                elseif alert == 'cancel' then
                    -- 削除の確認画面
                    local confirmDelete = lib.alertDialog({
                        header = '請求書削除の確認',
                        content = string.format('以下の請求書を削除しますか？\n\n請求先: %s\n金額: %s\n\n※この操作は取り消せません。',
                            invoice.recipient_name,
                            amount_text
                        ),
                        labels = {
                            confirm = '削除する',
                            cancel = 'キャンセル'
                        }
                    })

                    if confirmDelete == 'confirm' then
                        -- 削除処理
                        local success = lib.callback.await('ng-invoice:deleteInvoice', false, invoice.id)
                        if success then
                            QBCore.Functions.Notify('請求書を削除しました', 'success')
                            OpenBossInvoiceMenu() -- メニューを更新
                        else
                            QBCore.Functions.Notify('削除に失敗しました', 'error')
                        end
                    end
                end
            end
        })
    end

    lib.registerContext({
        id = 'boss_invoice_menu',
        title = '請求書リスト（ボスメニュー）',
        options = options
    })

    lib.showContext('boss_invoice_menu')
end

-- メインメニュー
local function OpenMainMenu()
    local Player = QBCore.Functions.GetPlayerData()
    local options = {
        {
            title = '請求書作成',
            description = '新しい請求書を作成します',
            arrow = true,
            onSelect = function()
                OpenCreateInvoiceMenu()
            end
        },
        {
            title = '請求書支払い',
            description = '受信した請求書の確認と支払い',
            arrow = true,
            onSelect = function()
                OpenPaymentMenu()
            end
        }
    }

    -- ボスメニューの追加
    local isBoss = false
    if Config.QBType == 'qbx' then
        isBoss = Player.job.isboss == true
    else
        -- QB-Core の場合は QBShared.Jobs から確認
        local job = QBCore.Shared.Jobs[Player.job.name]
        if job and job.grades then
            local gradeLevel = tostring(Player.job.grade.level)
            local gradeData = job.grades[gradeLevel]
            isBoss = gradeData and gradeData.isboss == true
        end
    end

    if isBoss then
        table.insert(options, {
            title = '請求書リスト（ボス）',
            description = 'ジョブの請求書一覧を表示',
            arrow = true,
            onSelect = function()
                OpenBossInvoiceMenu()
            end
        })
    end

    lib.registerContext({
        id = 'invoice_main_menu',
        title = '請求書システム',
        options = options
    })

    lib.showContext('invoice_main_menu')
end

-- 請求書受信イベント
RegisterNetEvent('ng-invoice:client:invoiceReceived', function(invoiceData)
    -- 基本通知
    SendInvoiceNotification(Config.Messages.invoice_received, 'info')
    
    -- 詳細表示設定がある場合
    if Config.Notifications.showInvoiceDetails then
        SendInvoiceNotification(string.format('金額: $%s - 請求者: %s', 
            invoiceData.total_amount,
            invoiceData.sender_job), 'info')
    end
end)

-- キーバインドの登録
RegisterCommand('+openInvoice', function()
    if LocalPlayer.state.dead then return end
    OpenMainMenu()
end, false)

RegisterKeyMapping('+openInvoice', '請求書システムを開く', 'keyboard', Config.OpenKey)

-- 初期化
CreateThread(function()
    TriggerServerEvent('ng-invoice:server:checkPermission')
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('ng-invoice:server:checkPermission')
end)
