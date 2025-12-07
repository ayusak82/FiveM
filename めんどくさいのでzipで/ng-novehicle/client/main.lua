local QBCore = exports['qb-core']:GetCoreObject()
local displayText = false

-- テキスト表示関数
local function DrawText()
    SetTextScale(Config.Scale, Config.Scale)
    SetTextFont(Config.Font)
    SetTextColour(Config.Color.r, Config.Color.g, Config.Color.b, Config.Color.a)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(Config.DisplayText)
    DrawText(Config.Position.x, Config.Position.y)
end

-- メインループ
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            local model = GetEntityModel(vehicle)
            
            if Config.RestrictedVehicles[model] then
                sleep = 0
                DrawText()
            else
                sleep = 1000
            end
        end
        
        Wait(sleep)
    end
end)