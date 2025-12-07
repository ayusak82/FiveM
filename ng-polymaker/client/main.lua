local QBCore = exports['qb-core']:GetCoreObject()
local points = {}
local isCreating = false

-- キーマッピング用の定数
local KEYS = {
    ['E'] = 38,
    ['X'] = 73,
    ['ENTER'] = 191,
    ['ESC'] = 322
}

-- ポイント追加関数
local function AddPoint()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    table.insert(points, vector2(coords.x, coords.y))
    lib.notify({
        title = 'ポイント追加',
        description = string.format('X: %.2f, Y: %.2f', coords.x, coords.y),
        type = 'success'
    })
end

-- 最後のポイント削除関数
local function RemoveLastPoint()
    if #points > 0 then
        table.remove(points)
        lib.notify({
            title = 'ポイント削除',
            description = '最後のポイントを削除しました',
            type = 'info'
        })
    end
end

-- ポイントをクリップボードにコピー
local function CopyToClipboard()
    if #points == 0 then
        lib.notify({
            title = 'エラー',
            description = Config.Text.noPoints,
            type = 'error'
        })
        return
    end

    local text = ""
    for i, point in ipairs(points) do
        text = text .. string.format("vector2(%.2f, %.2f)", point.x, point.y)
        if i < #points then
            text = text .. ",\n"
        end
    end

    lib.setClipboard(text)
    lib.notify({
        title = 'コピー完了',
        description = Config.Text.copied,
        type = 'success'
    })
end

-- キー入力の監視
local function HandleKeypress()
    if IsControlJustPressed(0, KEYS[Config.Keys.addPoint]) then
        AddPoint()
    elseif IsControlJustPressed(0, KEYS[Config.Keys.removePoint]) then
        RemoveLastPoint()
    elseif IsControlJustPressed(0, KEYS[Config.Keys.finish]) then
        CopyToClipboard()
        isCreating = false
        lib.hideTextUI()
    elseif IsControlJustPressed(0, KEYS[Config.Keys.cancel]) then
        points = {}
        isCreating = false
        lib.hideTextUI()
        lib.notify({
            title = 'キャンセル',
            description = Config.Text.cancelled,
            type = 'error'
        })
    end
end

-- 操作説明の表示
local function ShowInstructions()
    lib.showTextUI(
        '[E] ポイントを追加  [X] 前のポイントを削除  [ENTER] 完了  [ESC] キャンセル', {
        position = "top-center",
        style = {
            borderRadius = 0,
            backgroundColor = '#1A1A1A',
            color = 'white'
        }
    })
end

-- メインループ
CreateThread(function()
    while true do
        Wait(0)
        if isCreating then
            HandleKeypress()
        end
    end
end)

-- コマンドの登録
RegisterCommand(Config.Command.name, function()
    points = {}
    isCreating = true
    ShowInstructions()
    lib.notify({
        title = 'ポリゾーン作成開始',
        description = 'ポイントを設定してください',
        type = 'info'
    })
end, false)

TriggerEvent('chat:addSuggestion', '/' .. Config.Command.name, Config.Command.description)