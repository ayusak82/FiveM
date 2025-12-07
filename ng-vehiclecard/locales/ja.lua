Locale = {}

-- 一般メッセージ
Locale.vehicle_spawned = '車両をスポーンしました'
Locale.vehicle_stored = '車両をカードに戻しました'
Locale.vehicle_despawned = '放置車両が自動削除されました'
Locale.card_broken = '車両カードが壊れてしまいました'
Locale.no_space = 'スポーン位置に障害物があります'
Locale.too_far = '車両から離れすぎています'
Locale.not_your_vehicle = 'これはあなたの車両ではありません'
Locale.no_vehicle_nearby = '近くに車両がありません'
Locale.already_spawned = 'この車両カードの車両は既にスポーンされています'

-- ショップ
Locale.shop_marker = '[E] 車両カードショップ'
Locale.shop_title = '車両カードショップ'
Locale.shop_description = '車両カードを購入できます'
Locale.shop_buy = '購入'
Locale.shop_price = '価格: $%s'
Locale.shop_uses = '使用回数: %s回'
Locale.shop_success = '車両カードを購入しました'
Locale.shop_no_money = 'お金が足りません'
Locale.shop_full_inventory = 'インベントリがいっぱいです'

-- コマンド
Locale.cmd_create_usage = '使用方法: /createvehiclecard [プレイヤーID] [車両モデル] [使用回数(任意)]'
Locale.cmd_give_usage = '使用方法: /givevehiclecard [プレイヤーID] [車両モデル] [使用回数(任意)]'
Locale.cmd_invalid_player = '無効なプレイヤーIDです'
Locale.cmd_player_offline = 'プレイヤーがオフラインです'
Locale.cmd_invalid_model = '無効な車両モデルです'
Locale.cmd_created = '%s の車両カード (使用回数: %s) を作成しました'
Locale.cmd_given = '%s に %s の車両カード (使用回数: %s) を付与しました'
Locale.cmd_received = '%s の車両カードを受け取りました'
Locale.cmd_no_permission = 'このコマンドを使用する権限がありません'

-- スターター
Locale.starter_received = 'スターターパックの車両カードを受け取りました'

-- エラー
Locale.error_general = 'エラーが発生しました'
Locale.error_spawn = '車両のスポーンに失敗しました'
Locale.error_store = '車両の格納に失敗しました'

return Locale
