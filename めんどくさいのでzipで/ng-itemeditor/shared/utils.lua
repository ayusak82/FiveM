Utils = {}

-- 設定の検証
Utils.ValidateConfig = function(config)
    if not config then return false, 'config is nil' end
    
    -- サウンド設定の検証
    if config.sound then
        if type(config.sound.volume) ~= 'number' or config.sound.volume < 0 or config.sound.volume > 1 then
            return false, 'Invalid sound volume'
        end
        if type(config.sound.maxDistance) ~= 'number' or config.sound.maxDistance < 0 then
            return false, 'Invalid sound maxDistance'
        end
        if type(config.sound.soundDelay) ~= 'number' or config.sound.soundDelay < 0 then
            return false, 'Invalid sound delay'
        end
    end
    
    -- アニメーション設定の検証
    if config.animation then
        if not config.animation.dict or type(config.animation.dict) ~= 'string' then
            return false, 'Invalid animation dict'
        end
        if not config.animation.anim or type(config.animation.anim) ~= 'string' then
            return false, 'Invalid animation name'
        end
        if type(config.animation.duration) ~= 'number' or config.animation.duration < 0 then
            return false, 'Invalid animation duration'
        end
    end
    
    -- エフェクト設定の検証
    if config.effect then
        if config.effect.type and not table.find(Config.EffectTypes, function(t) return t.value == config.effect.type end) then
            return false, 'Invalid effect type'
        end
        if type(config.effect.delay) ~= 'number' or config.effect.delay < 0 then
            return false, 'Invalid effect delay'
        end
        if type(config.effect.duration) ~= 'number' or config.effect.duration < 0 then
            return false, 'Invalid effect duration'
        end
    end
    
    -- 回復設定の検証
    if config.recovery then
        local fields = {'health', 'armour', 'food', 'water', 'time'}
        for _, field in ipairs(fields) do
            if type(config.recovery[field]) ~= 'number' then
                return false, 'Invalid recovery ' .. field
            end
        end
        if type(config.recovery.isInstant) ~= 'boolean' then
            return false, 'Invalid recovery isInstant'
        end
        if type(config.recovery.gradualTick) ~= 'number' or config.recovery.gradualTick < 0 then
            return false, 'Invalid recovery gradualTick'
        end
    end
    
    return true, nil
end

-- テーブル内の値を検索
function table.find(t, cb)
    for _, v in ipairs(t) do
        if cb(v) then return true end
    end
    return false
end

-- 設定のマージ
Utils.MergeConfig = function(target, source)
    if not target then target = {} end
    if not source then return target end
    
    for k, v in pairs(source) do
        if type(v) == 'table' then
            target[k] = Utils.MergeConfig(target[k], v)
        else
            target[k] = v
        end
    end
    
    return target
end

-- 設定からデフォルト値を削除
Utils.RemoveDefaults = function(config)
    local result = {}
    local default = Config.DefaultTemplate
    
    for k, v in pairs(config) do
        if type(v) == 'table' and default[k] then
            local subResult = {}
            local isDifferent = false
            
            for subK, subV in pairs(v) do
                if default[k][subK] ~= subV then
                    subResult[subK] = subV
                    isDifferent = true
                end
            end
            
            if isDifferent then
                result[k] = subResult
            end
        elseif default[k] ~= v then
            result[k] = v
        end
    end
    
    return result
end