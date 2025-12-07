local QBCore = exports['qb-core']:GetCoreObject()

-- パーティクルエフェクトの準備
local function PrepareParticle(dict)
    if not HasNamedPtfxAssetLoaded(dict) then
        RequestNamedPtfxAsset(dict)
        while not HasNamedPtfxAssetLoaded(dict) do
            Wait(0)
        end
    end
    UseParticleFxAssetNextCall(dict)
end

-- パーティクルエフェクトの再生
local function PlayParticleEffect(effect, coords)
    if not effect or not coords then return end
    
    PrepareParticle(effect.dict)
    
    local particleCoords = coords + effect.offset
    local particle = StartParticleFxLoopedAtCoord(
        effect.name,
        particleCoords.x, particleCoords.y, particleCoords.z,
        0.0, 0.0, 0.0,  -- 回転
        effect.scale,    -- スケール
        false, false, false, false
    )
    
    return particle
end

-- サウンドの再生
local function PlaySound(sound)
    if not sound then return end
    
    if sound.dict then
        PlaySoundFrontend(-1, sound.name, sound.dict, false)
    else
        PlaySoundFrontend(-1, sound.name, nil, false)
    end
end

-- スクリーンエフェクトの再生
local function PlayScreenEffect(effect)
    if not effect then return end
    
    StartScreenEffect(effect.type, 0, true)
    Wait(effect.duration)
    StopScreenEffect(effect.type)
end

-- テレポート前のエフェクト
RegisterNetEvent('ng-teleport:client:PlayPreTeleportEffects', function(coords)
    if not Config.Effects then return end
    
    -- スクリーンエフェクト
    if Config.Effects.screen and Config.Effects.screen.pre then
        PlayScreenEffect(Config.Effects.screen.pre)
    end
    
    -- パーティクルエフェクト
    local particle
    if Config.Effects.particle and Config.Effects.particle.pre then
        particle = PlayParticleEffect(Config.Effects.particle.pre, coords)
    end
    
    -- サウンド
    if Config.Effects.sounds and Config.Effects.sounds.pre then
        PlaySound(Config.Effects.sounds.pre)
    end
    
    -- パーティクルの終了を遅延実行
    if particle then
        SetTimeout(Config.Effects.particle.pre.duration, function()
            StopParticleFxLooped(particle, false)
            RemoveParticleFx(particle, false)
        end)
    end
end)

-- テレポート後のエフェクト
RegisterNetEvent('ng-teleport:client:PlayPostTeleportEffects', function(coords)
    if not Config.Effects then return end
    
    -- スクリーンエフェクト
    if Config.Effects.screen and Config.Effects.screen.post then
        PlayScreenEffect(Config.Effects.screen.post)
    end
    
    -- パーティクルエフェクト
    local particle
    if Config.Effects.particle and Config.Effects.particle.post then
        particle = PlayParticleEffect(Config.Effects.particle.post, coords)
    end
    
    -- サウンド
    if Config.Effects.sounds and Config.Effects.sounds.post then
        PlaySound(Config.Effects.sounds.post)
    end
    
    -- パーティクルの終了を遅延実行
    if particle then
        SetTimeout(Config.Effects.particle.post.duration, function()
            StopParticleFxLooped(particle, false)
            RemoveParticleFx(particle, false)
        end)
    end
end)