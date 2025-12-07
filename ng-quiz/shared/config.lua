Config = {}

-- NPC設定
Config.NPC = {
    model = 'a_m_m_business_01', -- NPCモデル
    coords = vector4(413.31, 5572.63, 779.84, 270.43), -- x, y, z, heading
    scenario = 'WORLD_HUMAN_CLIPBOARD', -- NPCのアニメーション
}

-- ターゲット設定
Config.Target = {
    label = 'クイズに挑戦する',
    icon = 'fas fa-question-circle',
    distance = 2.0
}

-- UI設定
Config.UI = {
    title = 'NPCクイズチャレンジ',
    description = 'お好きなクイズを選んで挑戦してください！',
    selectQuizText = 'クイズを選択してください',
    startButtonText = '開始',
    cancelButtonText = 'キャンセル'
}

-- FiveMサーバー用クイズ設定
Config.Quizzes = {
    -- ルールクイズ
    {
        id = 'rules',
        name = 'ルールクイズ',
        description = 'サーバーの基本ルールに関するクイズです',
        difficulty = '必須',
        icon = '📋',
        questions = {
            {
                question = 'VDM（Vehicle Death Match）とは何ですか？',
                options = {
                    { value = 1, label = '車での故意的な殺傷行為' },
                    { value = 2, label = '車の改造競争' },
                    { value = 3, label = '駐車場での集会' }
                },
                correct = 1
            },
            {
                question = 'RDM（Random Death Match）は禁止されていますか？',
                options = {
                    { value = 1, label = '完全に禁止' },
                    { value = 2, label = '自由' },
                    { value = 3, label = '時間帯による' }
                },
                correct = 1
            },
            {
                question = 'コンバットログ （Combat Log）とは何ですか？',
                options = {
                    { value = 1, label = 'シーン中にゲームを切断' },
                    { value = 2, label = 'プレイヤーを殺害すること' },
                    { value = 3, label = '(=^・^=)' }
                },
                correct = 1
            },
            {
                question = 'ゲーム内チャットの使用は？',
                options = {
                    { value = 1, label = '緊急時のみ' },
                    { value = 2, label = 'いつでも自由に使える' },
                    { value = 3, label = '完全に禁止' }
                },
                correct = 1
            },
            {
                question = 'ゴースティングはしてもよいか？',
                options = {
                    { value = 1, label = 'もちろん' },
                    { value = 2, label = '部分的に' },
                    { value = 3, label = '禁止' }
                },
                correct = 3
            }
        }
    },
    
    -- 街の事クイズ
    {
        id = 'city',
        name = '街の事クイズ',
        description = 'サーバー内の街や施設に関するクイズです',
        difficulty = '初級',
        icon = '🏙️',
        questions = {
            {
                question = '病院はどこにありますか？',
                options = {
                    { value = 1, label = '8040' },
                    { value = 2, label = '8075' },
                    { value = 3, label = '5020' }
                },
                correct = 1
            },
            {
                question = '警察署の本署はどこ？',
                options = {
                    { value = 1, label = '8047' },
                    { value = 2, label = '10110' },
                    { value = 3, label = '1000' }
                },
                correct = 1
            },
            {
                question = 'サバゲー会場の場所は？',
                options = {
                    { value = 1, label = '2525' },
                    { value = 2, label = '9006' },
                    { value = 3, label = '4649' }
                },
                correct = 2
            },
            {
                question = 'カジノがある場所は？',
                options = {
                    { value = 1, label = '9999' },
                    { value = 2, label = '1111' },
                    { value = 3, label = '7292' }
                },
                correct = 3
            },
            {
                question = '最も高い建物は？',
                options = {
                    { value = 1, label = '8062' },
                    { value = 2, label = '10000' },
                    { value = 3, label = '3.1415926535' }
                },
                correct = 1
            }
        }
    },
    
    -- 運営の事クイズ
    {
        id = 'admin',
        name = '運営の事クイズ',
        description = 'サーバー運営やシステムに関するクイズです',
        difficulty = '中級',
        icon = '⚙️',
        questions = {
            {
                question = '運営への連絡方法として正しいのは？',
                options = {
                    { value = 1, label = 'ゲーム内で直接' },
                    { value = 2, label = 'Discordチケット' },
                    { value = 3, label = 'リアル電話' }
                },
                correct = 2
            },
            {
                question = 'バグを発見した場合の対応は？',
                options = {
                    { value = 1, label = '利用して遊ぶ' },
                    { value = 2, label = '運営に報告する' },
                    { value = 3, label = '他の人に教える' }
                },
                correct = 2
            },
            {
                question = 'キャラクター作成の上限は？(サブスク加入者は除く)',
                options = {
                    { value = 1, label = '1人まで' },
                    { value = 2, label = '3人まで' },
                    { value = 3, label = '無制限' }
                },
                correct = 1
            },
            {
                question = '悪いプレイヤーの通報方法は？',
                options = {
                    { value = 1, label = 'Discordチケット' },
                    { value = 2, label = '直接対決' },
                    { value = 3, label = 'SNSで晒す' }
                },
                correct = 1
            },
            {
                question = 'サーバー再起動の頻度は？',
                options = {
                    { value = 1, label = '毎時間' },
                    { value = 2, label = '3時間おき' },
                    { value = 3, label = '不定期' }
                },
                correct = 2
            }
        }
    },
    
    -- その他クイズ
    {
        id = 'others',
        name = 'その他クイズ',
        description = 'RP知識や一般的なゲーム知識のクイズです',
        difficulty = '上級',
        icon = '🎯',
        questions = {
            {
                question = 'ゲーム内でストレス値が溜まった場合はどのようになる？',
                options = {
                    { value = 1, label = '発狂する' },
                    { value = 2, label = '画面が暗転して転倒する' },
                    { value = 3, label = '台パンしたくなる' }
                },
                correct = 2
            },
            {
                question = 'パワーゲーミングとは？',
                options = {
                    { value = 1, label = '強いキャラクターを作ること' },
                    { value = 2, label = '現実的でない行動をすること' },
                    { value = 3, label = 'ゲームを極めること' }
                },
                correct = 2
            },
            {
                question = '心なきとは？',
                options = {
                    { value = 1, label = 'メンタルが死んでるプレイヤーのこと' },
                    { value = 2, label = 'プレイヤー' },
                    { value = 3, label = 'NPC (Non Player Charactor)' }
                },
                correct = 3
            },
            {
                question = '水の中に潜ってしまった...',
                options = {
                    { value = 1, label = 'SHIFT + S' },
                    { value = 2, label = 'ALT + F4' },
                    { value = 3, label = 'CTRL + Z' }
                },
                correct = 1
            },
            {
                question = 'あゆさくを虐めてもいい？',
                options = {
                    { value = 1, label = 'もちろん' },
                    { value = 2, label = 'だめ' },
                    { value = 3, label = 'たぶん' }
                },
                correct = 2
            }
        }
    }
}

-- 成功時の報酬設定（クイズごとに異なる報酬）
Config.Rewards = {
    ['rules'] = {
        money = 0,
        item = {
            name = 'stickynote',
            count = 1,
            metadata = {
                title = 'とある薬物のレシピ',
                description = 'とある薬物の製造に必要な謎めいた数字が記されている... (1,2,3,5,8)'
            }
        },
        title = 'とある薬物のレシピ'
    },
    ['city'] = {
        money = 0,
        item = {
            name = 'stickynote',
            count = 1,
            metadata = {
                title = 'とある薬物のレシピ',
                description = 'とある薬物の製造に必要な謎めいた数字が記されている... (8,3,11)'
            }
        },
        title = 'とある薬物のレシピ'
    },
    ['admin'] = {
        money = 0,
        item = {
            name = 'stickynote',
            count = 1,
            metadata = {
                title = 'とある薬物のレシピ',
                description = 'とある薬物の製造に必要な謎めいた数字が記されている... (15,4,4,3)'
            }
        },
        title = 'とある薬物のレシピ'
    },
    ['others'] = {
        money = 0,
        item = {
            name = 'stickynote',
            count = 1,
            metadata = {
                title = 'とある薬物のレシピ',
                description = 'とある薬物の製造に必要な謎めいた数字が記されている... (13,10,5,7)'
            }
        },
        title = 'とある薬物のレシピ'
    }
}

-- メッセージ設定
Config.Messages = {
    success = {
        title = '🎉 おめでとうございます！',
        description = '全問正解です！「%s」のstickynoteを獲得しました！',
        type = 'success'
    },
    failure = {
        title = '❌ 残念...',
        description = '不正解がありました。正解数: %d/%d問\nもう一度挑戦してみてください！',
        type = 'error'
    },
    cancelled = {
        title = 'クイズ中止',
        description = 'クイズを中止しました。',
        type = 'inform'
    }
}