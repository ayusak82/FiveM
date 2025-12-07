Config = {}

-- 警察ジョブ設定
Config.PoliceJobs = {
    'police',
}

-- 指紋採取機の設置場所
Config.FingerprintStations = {
    {
        name = "本署指紋採取機",
        coords = vector3(485.05, -989.24, 30.68),
        heading = 0.0,
        model = "prop_pc_02a", -- 指紋採取機のモデル（PCを使用）
        interactionDistance = 2.0
    },
    {
        name = "砂漠署指紋採取機",
        coords = vector3(1818.06, 3664.96, 34.08),
        heading = 208.48,
        model = "prop_pc_02a",
        interactionDistance = 2.0
    },
    {
        name = "北署指紋採取機",
        coords = vector3(-453.32, 5997.54, 27.45),
        heading = 134.93,
        model = "prop_pc_02a",
        interactionDistance = 2.0
    }
}

-- 指紋採取設定
Config.FingerprintSettings = {
    -- 指紋採取に必要な時間（秒）
    CollectionTime = 5,
    -- 同時に表示できる指紋の最大数
    MaxFingerprints = 5,
    -- 指紋採取機との相互作用距離
    InteractionDistance = 2.0
}

-- 証拠袋アイテム設定
Config.EvidenceBag = {
    -- 証拠袋のアイテム名
    ItemName = 'filled_evidence_bag',
    -- 指紋タイプの識別子（メタデータのtypeと一致させる）
    FingerprintType = 'fingerprint'
}

-- UI設定
Config.UI = {
    -- UIの位置設定
    Position = 'top-right',
    -- 通知表示時間（ミリ秒）
    NotificationTime = 5000
}

-- 言語設定
Config.Lang = {
    ['fingerprint_collected'] = '指紋が採取されました',
    ['fingerprint_copied'] = '指紋がクリップボードにコピーされました',
    ['no_permission'] = '権限がありません',
    ['collection_started'] = '指紋採取を開始します',
    ['collection_in_progress'] = '指紋採取中...',
    ['collection_completed'] = '指紋採取が完了しました',
    ['waiting_for_suspect'] = '容疑者の指紋採取を待機中...',
    ['no_fingerprints'] = '指紋が見つかりませんでした',
    ['evidence_bag_used'] = '証拠袋から指紋を取り出しました',
    ['invalid_evidence'] = '無効な証拠袋です',
    ['interact_station'] = '[E] 指紋採取機を使用',
    ['police_required'] = '警察官が必要です',
    ['suspect_approach'] = '容疑者は指紋採取機に近づいてください',
    ['press_e_to_scan'] = '[E] 指紋をスキャン',
    ['scanning_fingerprint'] = '指紋をスキャンしています...',
    ['station_in_use'] = 'この指紋採取機は使用中です'
}