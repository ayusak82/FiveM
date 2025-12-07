Config = {}

Config.Buildings = {
    ['pillbox'] = {
        label = 'Pillbox Hospital',
        floors = {
            {
                label = '1階',
                coords = vec3(342.29, -585.32, 28.8),
                heading = 70.0
            },
            {
                label = '2階',
                coords = vec3(332.15, -595.61, 43.28),
                heading = 70.0
            },
            {
                label = '3階',
                coords = vec3(338.82, -583.95, 74.16),
                heading = 70.0
            },
            -- 必要に応じて階層を追加
        }
    },
    ['sample_building'] = {
        label = 'Sample Building',
        floors = {
            {
                label = '1階',
                coords = vector3(-906.63, -451.82, 39.61),
                heading = 70.0
            },
            {
                label = 'お店',
                coords = vector3(-905.54, -449.68, 160.98),
                heading = 70.0
            },
            -- 必要に応じて階層を追加
        }
    },
    -- 他の建物を追加可能
}