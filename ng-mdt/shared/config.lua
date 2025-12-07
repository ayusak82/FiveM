Config = {}

-- MDTを開くコマンド
Config.Command = 'mdt'

-- 罪状リスト (名前と罰金額)
Config.Crimes = {
    { label = 'テルミット強盗罪', fine = 5000000},
    { label = 'オイルリグ強盗罪', fine = 6250000},
    { label = '住宅強盗罪', fine = 6700000},
    { label = '店舗強盗罪', fine = 6700000},
    { label = 'ATM強盗罪', fine = 5000000},
    { label = '列車強盗罪', fine = 8300000},
    { label = 'フリーカ強盗罪', fine = 18750000},
    { label = '宝石強盗罪', fine = 12500000},
    { label = '豪華客船強盗罪', fine = 10000000},
    { label = 'ヒューメイン強盗罪', fine = 12500000},
    { label = 'パレト強盗罪', fine = 12500000},
    { label = 'ボブキャット強盗罪', fine = 9375000},
    { label = '金庫強盗罪', fine = 16000000},
    { label = 'アーティファクト強盗罪', fine = 16000000},
    { label = 'メイズバンク強盗罪', fine = 16000000},
    { label = '飛行場襲撃強盗罪', fine = 18750000},
    { label = 'アンダーグラウンド強盗罪', fine = 18750000},
    { label = 'カジノ強盗罪', fine = 25000000},
    { label = 'ユニオン強盗罪', fine = 31250000},
    { label = 'パシフィック強盗罪', fine = 37500000},
    { label = '殺人罪', fine = 2000000},
    { label = '殺人未遂', fine = 1000000},
    { label = '公務執行妨害 (逃走含む)', fine = 1000000},
    { label = '銃刀法違反', fine = 1000000},
    { label = '車両窃盗', fine = 1000000},
    { label = 'わいせつ罪', fine = 300000000},
    { label = 'テロ罪', fine = 300000000},
}

-- 危険度レベル
Config.DangerLevels = {
    { value = 'low', label = '低' },
    { value = 'medium', label = '中' },
    { value = 'high', label = '高' },
    { value = 'extreme', label = '最高' }
}

-- 検索結果の表示件数(ページあたり)
Config.ResultsPerPage = 50

-- 車両照会の距離設定
Config.VehicleCheckDistance = 5.0 -- 目の前の車両として認識する距離(メートル)

-- プロファイル写真の表示サイズ
Config.ProfilePhotoSize = '100px' -- 小さめサイズ

-- ロケール(将来的な多言語対応用)
Config.Locale = {
    -- メニュー
    menu_title = 'MDTメニュー',
    menu_create = '作成',
    menu_history = '履歴確認',
    menu_vehicle = '車両照会',
    menu_profile = 'プロファイル',
    
    -- 作成フォーム
    create_title = '記録作成',
    create_officers = '対応警察官',
    create_officers_desc = '対応した警察官を選択してください',
    create_crimes = '罪状',
    create_crimes_desc = '該当する罪状を選択してください',
    create_fine = '罰金額(一人あたり)',
    create_criminals = '犯人',
    create_criminals_desc = '犯人を選択してください',
    create_notes = '備考',
    create_notes_desc = '備考を入力してください(任意)',
    create_manual_input = '手動入力(CitizenID)',
    
    -- 履歴
    history_title = '履歴検索',
    history_search = '検索',
    history_results = '検索結果',
    history_no_results = '該当する記録が見つかりませんでした',
    
    -- 車両照会
    vehicle_title = '車両照会',
    vehicle_plate_input = 'ナンバープレートを入力',
    vehicle_check_nearby = '目の前の車両を照会',
    vehicle_no_vehicle = '近くに車両が見つかりません',
    vehicle_not_found = '該当する車両が見つかりませんでした',
    vehicle_info_title = '車両情報',
    vehicle_model = '車両モデル',
    vehicle_plate = 'ナンバープレート',
    vehicle_owner = '所有者',
    vehicle_citizenid = 'CitizenID',
    vehicle_color = '車両の色',
    vehicle_no_owner = '所有者なし',
    
    -- プロファイル
    profile_title = 'プロファイル管理',
    profile_create = '新規作成',
    profile_search = '検索',
    profile_wanted_list = '警戒リスト',
    profile_not_found = '該当するプロファイルが見つかりませんでした',
    profile_info_title = 'プロファイル詳細',
    profile_citizenid = 'CitizenID',
    profile_fingerprint = '指紋',
    profile_name = '名前',
    profile_alias = '別名/通称',
    profile_dob = '生年月日',
    profile_gender = '性別',
    profile_nationality = '国籍',
    profile_danger_level = '危険度',
    profile_organization = '所属組織/ギャング',
    profile_locations = '頻繁に出没する場所',
    profile_vehicles = '所有車両',
    profile_notes = '備考/メモ',
    profile_photo = '写真',
    profile_wanted = '警戒リスト登録',
    profile_created_by = '登録者',
    profile_created_at = '登録日時',
    profile_updated_at = '最終更新',
    profile_no_vehicles = '登録車両なし',
    profile_no_photo = '写真なし',
    
    -- ボタン
    btn_close = '閉じる',
    btn_edit = '編集',
    btn_delete = '削除',
    btn_confirm = '確定',
    btn_cancel = 'キャンセル',
    btn_back = '戻る',
    
    -- 通知
    notify_no_permission = '権限がありません',
    notify_not_police = '警察職のみ使用可能です',
    notify_created = '記録を作成しました',
    notify_updated = '記録を更新しました',
    notify_deleted = '記録を削除しました',
    notify_error = 'エラーが発生しました',
    notify_select_officer = '対応警察官を選択してください',
    notify_select_crime = '罪状を選択してください',
    notify_select_criminal = '犯人を選択してください',
    notify_boss_only = 'この操作はボスのみ実行可能です',
    notify_profile_created = 'プロファイルを作成しました',
    notify_profile_updated = 'プロファイルを更新しました',
    notify_profile_deleted = 'プロファイルを削除しました',
    notify_profile_exists = 'このCitizenIDのプロファイルは既に存在します',
    notify_required_fields = '必須項目を入力してください',
}