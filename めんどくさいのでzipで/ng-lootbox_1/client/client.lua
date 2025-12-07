if GetConvar('sv_environment', 'prod') == 'debug' then
  RegisterCommand('nui', function()
      if IsPauseMenuActive() then return end
      SetNuiFocus(true, true)
  end)
end

-- NUIメッセージ送信用のヘルパー関数
local function SendReactMessage(action, data)
  Bridge.Debug("Sending NUI message:", action)
  SendNUIMessage({
      action = action,
      data = data
  })
end

-- ガチャ実行イベント
RegisterNetEvent("ng-lootbox:RollCase", function(lootPool, winner)
  Bridge.Debug("Received RollCase event")
  Bridge.Debug("Loot pool size:", #lootPool)
  Bridge.Debug("Winner index:", winner)
  
  -- UIを表示
  SetNuiFocus(true, false)
  SendReactMessage('setLootData', {
      pool = lootPool,
      winner = winner
  })
end)

-- アイテム使用イベント
RegisterNetEvent("ng-lootbox:useItem", function(data)
  print("^3[DEBUG] Item use event received:", data.name)
  TriggerServerEvent('ng-lootbox:useGacha', data.name)
end)

-- アイテム使用をエクスポート
exports('useItem', function(data, slot)
  Bridge.Debug("useItem called:", data.name)
  TriggerServerEvent('ng-lootbox:useGacha', data.name)
  return false
end)

-- UIからの完了コールバック
RegisterNUICallback('finished', function(data, cb)
  print("^3[DEBUG] Gacha finished callback received")
  SetNuiFocus(false, false)
  TriggerServerEvent('ng-lootbox:getQueuedItem')
  cb({})
end)

-- テスト用コマンド
RegisterCommand('testgacha', function()
  print("^3[DEBUG] Testing gacha system")
  TriggerServerEvent('ng-lootbox:testGacha')
end)

-- ox_inventoryのアイテム使用をフック
exports('useItem', function(data, slot)
  print("^3[DEBUG] useItem export triggered:", data.name)
  
  -- サーバー側のCASESテーブルと同期を取るため、一度サーバーに確認を取る
  TriggerServerEvent('ng-lootbox:checkItem', data.name)
  return false
end)

-- アイテムチェックの結果を受け取る
RegisterNetEvent('ng-lootbox:itemCheckResult', function(itemName, isValid)
  print("^3[DEBUG] Item check result:", itemName, isValid)
  if isValid then
      TriggerEvent('ng-lootbox:useItem', {name = itemName})
  end
end)

-- デバッグ用：NUIの状態をリセット
RegisterCommand('resetgacha', function()
  SetNuiFocus(false, false)
  print("^3[DEBUG] Reset NUI focus")
end)