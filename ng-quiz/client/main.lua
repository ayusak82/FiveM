local QBCore = exports['qb-core']:GetCoreObject()
local npcPed = nil
local npcSpawned = false
local currentQuiz = nil
local currentQuestionIndex = 0
local correctAnswers = 0
local isQuizActive = false

-- NPC生成関数
local function SpawnNPC()
    if npcSpawned then return end
    
    local model = Config.NPC.model
    local coords = Config.NPC.coords
    
    -- モデルをロード
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end
    
    -- NPCを生成
    npcPed = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    
    -- NPC設定
    SetEntityInvincible(npcPed, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    FreezeEntityPosition(npcPed, true)
    
    -- シナリオを適用
    if Config.NPC.scenario then
        TaskStartScenarioInPlace(npcPed, Config.NPC.scenario, 0, true)
    end
    
    -- ターゲット設定
    exports.ox_target:addLocalEntity(npcPed, {
        {
            name = 'ng_quiz_npc',
            label = Config.Target.label,
            icon = Config.Target.icon,
            distance = Config.Target.distance,
            onSelect = function()
                OpenQuizSelector()
            end
        }
    })
    
    npcSpawned = true
    --print('[ng-quiz] NPCが生成されました')
end

-- クイズ選択画面を開く
function OpenQuizSelector()
    if isQuizActive then return end
    
    --print('[ng-quiz] クイズ選択画面を開いています...')
    
    -- HTML UIを表示
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showQuizSelector',
        quizzes = Config.Quizzes,
        ui = Config.UI
    })
    
    isQuizActive = true
end

-- クイズを開始
function StartQuiz(quizId)
    --print(string.format('[ng-quiz] クイズを開始: %s', quizId))
    
    -- 選択されたクイズを取得
    for _, quiz in ipairs(Config.Quizzes) do
        if quiz.id == quizId then
            currentQuiz = quiz
            break
        end
    end
    
    if not currentQuiz then
        --print('[ng-quiz] エラー: クイズが見つかりません')
        return
    end
    
    -- 初期化
    currentQuestionIndex = 1
    correctAnswers = 0
    
    -- 最初の問題を表示
    ShowNextQuestion()
end

-- 次の問題を表示
function ShowNextQuestion()
    if currentQuestionIndex > #currentQuiz.questions then
        -- 全問題終了
        EndQuiz()
        return
    end
    
    local question = currentQuiz.questions[currentQuestionIndex]
    
    --print(string.format('[ng-quiz] 問題 %d/%d を表示', currentQuestionIndex, #currentQuiz.questions))
    
    SendNUIMessage({
        action = 'showQuestion',
        question = question,
        questionNumber = currentQuestionIndex,
        totalQuestions = #currentQuiz.questions,
        quizName = currentQuiz.name
    })
end

-- 回答を処理
function ProcessAnswer(answer)
    --print(string.format('[ng-quiz] 回答を処理: %d', answer))
    
    local question = currentQuiz.questions[currentQuestionIndex]
    local isCorrect = (answer == question.correct)
    
    if isCorrect then
        correctAnswers = correctAnswers + 1
    end
    
    -- 結果を表示
    SendNUIMessage({
        action = 'showResult',
        isCorrect = isCorrect,
        correctAnswer = question.options[question.correct].label,
        userAnswer = question.options[answer] and question.options[answer].label or '無効'
    })
    
    -- 次の問題へ
    currentQuestionIndex = currentQuestionIndex + 1
    
    -- 2秒後に次の問題または結果画面
    CreateThread(function()
        Wait(2000)
        ShowNextQuestion()
    end)
end

-- クイズ終了
function EndQuiz()
    local totalQuestions = #currentQuiz.questions
    local isSuccess = (correctAnswers == totalQuestions)
    
    --print(string.format('[ng-quiz] クイズ終了: %d/%d正解', correctAnswers, totalQuestions))
    
    -- 結果を表示
    SendNUIMessage({
        action = 'showFinalResult',
        success = isSuccess,
        correctAnswers = correctAnswers,
        totalQuestions = totalQuestions,
        quizName = currentQuiz.name,
        reward = isSuccess and Config.Rewards[currentQuiz.id] or nil
    })
    
    -- サーバーに結果を送信
    if isSuccess then
        TriggerServerEvent('ng-quiz:onSuccess', currentQuiz.id)
        lib.notify({
            title = Config.Messages.success.title,
            description = string.format(Config.Messages.success.description, Config.Rewards[currentQuiz.id].title),
            type = Config.Messages.success.type
        })
    else
        TriggerServerEvent('ng-quiz:onFailure', currentQuiz.id, correctAnswers, totalQuestions)
        lib.notify({
            title = Config.Messages.failure.title,
            description = string.format(Config.Messages.failure.description, correctAnswers, totalQuestions),
            type = Config.Messages.failure.type
        })
    end
    
    -- 5秒後にUIを閉じる
    CreateThread(function()
        Wait(5000)
        CloseQuizUI()
    end)
end

-- UIを閉じる
function CloseQuizUI()
    --print('[ng-quiz] UIを閉じています')
    
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'hideUI'
    })
    
    -- 状態をリセット
    currentQuiz = nil
    currentQuestionIndex = 0
    correctAnswers = 0
    isQuizActive = false
end

-- NUIコールバック処理
RegisterNUICallback('selectQuiz', function(data, cb)
    --print('[ng-quiz] NUIコールバック: selectQuiz 受信')
    --print(string.format('[ng-quiz] 受信データ: %s', json.encode(data)))
    if data.quizId then
        StartQuiz(data.quizId)
    else
        --print('[ng-quiz] エラー: quizIdが見つかりません')
    end
    cb('ok')
end)

RegisterNUICallback('answerQuestion', function(data, cb)
    --print('[ng-quiz] NUIコールバック: answerQuestion 受信')
    --print(string.format('[ng-quiz] 受信データ: %s', json.encode(data)))
    if data.answer then
        ProcessAnswer(data.answer)
    else
        --print('[ng-quiz] エラー: answerが見つかりません')
    end
    cb('ok')
end)

RegisterNUICallback('closeUI', function(data, cb)
    --print('[ng-quiz] NUIコールバック: closeUI 受信')
    CloseQuizUI()
    lib.notify(Config.Messages.cancelled)
    cb('ok')
end)

-- ESCキーでUIを閉じる
CreateThread(function()
    while true do
        Wait(0)
        if isQuizActive then
            if IsControlJustPressed(0, 322) then -- ESC key
                --print('[ng-quiz] ESCキーが押されました')
                CloseQuizUI()
                lib.notify(Config.Messages.cancelled)
            end
            -- マウスの無効化を防ぐ
            DisableControlAction(0, 1, true) -- マウス移動
            DisableControlAction(0, 2, true) -- マウス移動
        end
    end
end)

-- デバッグコマンド
RegisterCommand('testquiz', function()
    OpenQuizSelector()
end, false)

-- リソース開始時の処理
CreateThread(function()
    while not QBCore do
        Wait(100)
    end
    
    -- 少し待ってからNPCを生成
    Wait(2000)
    SpawnNPC()
end)

-- リソース終了時の処理
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if npcPed and DoesEntityExist(npcPed) then
            exports.ox_target:removeLocalEntity(npcPed, 'ng_quiz_npc')
            DeleteEntity(npcPed)
        end
        CloseQuizUI()
    end
end)