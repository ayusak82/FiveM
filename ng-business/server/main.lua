-- ============================================
-- SERVER MAIN - ng-business
-- ============================================

QBCore = exports['qb-core']:GetCoreObject()

-- Global data storage
BusinessData = {
    jobs = {},
    stashes = {},
    trays = {},
    crafting = {},
    lockers = {},
    blips = {}
}

-- Debug print function (Global for all server modules)
function DebugPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^3[DEBUG]^7 ' .. message)
end

-- Error print function (Global for all server modules)
function ErrorPrint(...)
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^1[ERROR]^7 ' .. message)
end

-- Success print function (Global for all server modules)
function SuccessPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^2[SUCCESS]^7 ' .. message)
end

-- Warning print function (Global for all server modules)
function WarnPrint(...)
    if not Config.Debug then return end
    local args = {...}
    local message = ''
    for i = 1, #args do
        message = message .. tostring(args[i]) .. ' '
    end
    print('^5[WARNING]^7 ' .. message)
end

-- ============================================
-- DATABASE SETUP
-- ============================================

-- Create database tables
local function CreateDatabaseTables()
    DebugPrint('Creating database tables...')
    
    -- Business Stashes Table
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `business_stashes` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `stash_id` VARCHAR(50) NOT NULL UNIQUE,
            `label` VARCHAR(100) NOT NULL,
            `coords` TEXT NOT NULL,
            `slots` INT(11) NOT NULL DEFAULT 50,
            `weight` INT(11) NOT NULL DEFAULT 100000,
            `jobs` TEXT NULL,
            `min_grade` INT(11) NOT NULL DEFAULT 0,
            `blip_enabled` TINYINT(1) NOT NULL DEFAULT 0,
            `blip_sprite` INT(11) NOT NULL DEFAULT 50,
            `blip_color` INT(11) NOT NULL DEFAULT 3,
            `blip_scale` FLOAT NOT NULL DEFAULT 0.7,
            `created_by` VARCHAR(50) NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    
    -- Business Trays Table
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `business_trays` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `tray_id` VARCHAR(50) NOT NULL UNIQUE,
            `label` VARCHAR(100) NOT NULL,
            `coords` TEXT NOT NULL,
            `slots` INT(11) NOT NULL DEFAULT 10,
            `weight` INT(11) NOT NULL DEFAULT 10000,
            `jobs` TEXT NULL,
            `min_grade` INT(11) NOT NULL DEFAULT 0,
            `blip_enabled` TINYINT(1) NOT NULL DEFAULT 0,
            `blip_sprite` INT(11) NOT NULL DEFAULT 50,
            `blip_color` INT(11) NOT NULL DEFAULT 3,
            `blip_scale` FLOAT NOT NULL DEFAULT 0.7,
            `created_by` VARCHAR(50) NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    
    -- Business Crafting Table
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `business_crafting` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `crafting_id` VARCHAR(50) NOT NULL UNIQUE,
            `label` VARCHAR(100) NOT NULL,
            `coords` TEXT NOT NULL,
            `jobs` TEXT NULL,
            `min_grade` INT(11) NOT NULL DEFAULT 0,
            `recipes` LONGTEXT NOT NULL,
            `blip_enabled` TINYINT(1) NOT NULL DEFAULT 0,
            `blip_sprite` INT(11) NOT NULL DEFAULT 566,
            `blip_color` INT(11) NOT NULL DEFAULT 3,
            `blip_scale` FLOAT NOT NULL DEFAULT 0.7,
            `created_by` VARCHAR(50) NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    
    -- Business Lockers Table
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `business_lockers` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `locker_id` VARCHAR(50) NOT NULL UNIQUE,
            `label` VARCHAR(100) NOT NULL,
            `coords` TEXT NOT NULL,
            `slots` INT(11) NOT NULL DEFAULT 30,
            `weight` INT(11) NOT NULL DEFAULT 50000,
            `jobs` TEXT NULL,
            `min_grade` INT(11) NOT NULL DEFAULT 0,
            `personal` TINYINT(1) NOT NULL DEFAULT 1,
            `blip_enabled` TINYINT(1) NOT NULL DEFAULT 0,
            `blip_sprite` INT(11) NOT NULL DEFAULT 50,
            `blip_color` INT(11) NOT NULL DEFAULT 3,
            `blip_scale` FLOAT NOT NULL DEFAULT 0.7,
            `created_by` VARCHAR(50) NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    
    -- Business Blips Table
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `business_blips` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `label` VARCHAR(100) NOT NULL,
            `coords` TEXT NOT NULL,
            `sprite` INT(11) NOT NULL DEFAULT 1,
            `color` INT(11) NOT NULL DEFAULT 0,
            `scale` FLOAT NOT NULL DEFAULT 0.8,
            `created_by` VARCHAR(50) NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    
    -- Business Jobs Table
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `business_jobs` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `job_name` VARCHAR(50) NOT NULL UNIQUE,
            `label` VARCHAR(100) NOT NULL,
            `boss_menu_coords` TEXT NULL,
            `enabled` TINYINT(1) NOT NULL DEFAULT 1,
            `created_by` VARCHAR(50) NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    
    SuccessPrint('Database tables created successfully')
end

-- Load all business data from database
local function LoadBusinessData()
    DebugPrint('Loading business data from database...')
    
    -- Load jobs
    local jobs = MySQL.query.await('SELECT * FROM business_jobs WHERE enabled = 1')
    if jobs then
        for _, job in ipairs(jobs) do
            local bossMenuCoords = job.boss_menu_coords and json.decode(job.boss_menu_coords) or nil
            
            BusinessData.jobs[job.job_name] = {
                jobName = job.job_name,
                label = job.label,
                bossMenuCoords = bossMenuCoords and vector3(bossMenuCoords.x, bossMenuCoords.y, bossMenuCoords.z) or nil,
                enabled = job.enabled == 1
            }
        end
        SuccessPrint('Loaded', #jobs, 'jobs from database')
    end
    
    -- Load stashes
    local stashes = MySQL.query.await('SELECT * FROM business_stashes')
    if stashes then
        for _, stash in ipairs(stashes) do
            local coords = json.decode(stash.coords)
            local jobs = stash.jobs and json.decode(stash.jobs) or {}
            
            BusinessData.stashes[stash.stash_id] = {
                id = stash.stash_id,
                label = stash.label,
                coords = vector3(coords.x, coords.y, coords.z),
                slots = stash.slots,
                weight = stash.weight,
                jobs = jobs,
                minGrade = stash.min_grade,
                blip = {
                    enabled = stash.blip_enabled == 1,
                    sprite = stash.blip_sprite,
                    color = stash.blip_color,
                    scale = stash.blip_scale
                }
            }
        end
        SuccessPrint('Loaded', #stashes, 'stashes from database')
    end
    
    -- Load trays
    local trays = MySQL.query.await('SELECT * FROM business_trays')
    if trays then
        for _, tray in ipairs(trays) do
            local coords = json.decode(tray.coords)
            local jobs = tray.jobs and json.decode(tray.jobs) or {}
            
            BusinessData.trays[tray.tray_id] = {
                id = tray.tray_id,
                label = tray.label,
                coords = vector3(coords.x, coords.y, coords.z),
                slots = tray.slots,
                weight = tray.weight,
                jobs = jobs,
                minGrade = tray.min_grade,
                blip = {
                    enabled = tray.blip_enabled == 1,
                    sprite = tray.blip_sprite,
                    color = tray.blip_color,
                    scale = tray.blip_scale
                }
            }
        end
        SuccessPrint('Loaded', #trays, 'trays from database')
    end
    
    -- Load crafting stations
    local crafting = MySQL.query.await('SELECT * FROM business_crafting')
    if crafting then
        for _, craft in ipairs(crafting) do
            local coords = json.decode(craft.coords)
            local jobs = craft.jobs and json.decode(craft.jobs) or {}
            local recipes = json.decode(craft.recipes)
            
            BusinessData.crafting[craft.crafting_id] = {
                id = craft.crafting_id,
                label = craft.label,
                coords = vector3(coords.x, coords.y, coords.z),
                jobs = jobs,
                minGrade = craft.min_grade,
                recipes = recipes,
                blip = {
                    enabled = craft.blip_enabled == 1,
                    sprite = craft.blip_sprite,
                    color = craft.blip_color,
                    scale = craft.blip_scale
                }
            }
        end
        SuccessPrint('Loaded', #crafting, 'crafting stations from database')
    end
    
    -- Load lockers
    local lockers = MySQL.query.await('SELECT * FROM business_lockers')
    if lockers then
        for _, locker in ipairs(lockers) do
            local coords = json.decode(locker.coords)
            local jobs = locker.jobs and json.decode(locker.jobs) or {}
            
            BusinessData.lockers[locker.locker_id] = {
                id = locker.locker_id,
                label = locker.label,
                coords = vector3(coords.x, coords.y, coords.z),
                slots = locker.slots,
                weight = locker.weight,
                jobs = jobs,
                minGrade = locker.min_grade,
                personal = locker.personal == 1,
                blip = {
                    enabled = locker.blip_enabled == 1,
                    sprite = locker.blip_sprite,
                    color = locker.blip_color,
                    scale = locker.blip_scale
                }
            }
        end
        SuccessPrint('Loaded', #lockers, 'lockers from database')
    end
    
    -- Load blips
    local blips = MySQL.query.await('SELECT * FROM business_blips')
    if blips then
        for _, blip in ipairs(blips) do
            local coords = json.decode(blip.coords)
            
            BusinessData.blips[blip.id] = {
                id = blip.id,
                label = blip.label,
                coords = vector3(coords.x, coords.y, coords.z),
                sprite = blip.sprite,
                color = blip.color,
                scale = blip.scale
            }
        end
        SuccessPrint('Loaded', #blips, 'custom blips from database')
    end
end

-- ============================================
-- ADMIN CHECK
-- ============================================

local function IsAdmin(source)
    if not source then return false end
    return IsPlayerAceAllowed(source, 'command.admin')
end

lib.callback.register('ng-business:server:isAdmin', function(source)
    return IsAdmin(source)
end)

-- ============================================
-- GET BUSINESS DATA
-- ============================================

lib.callback.register('ng-business:server:getBusinessData', function(source)
    DebugPrint('Client', source, 'requested business data')
    return BusinessData
end)

-- ============================================
-- RESOURCE START
-- ============================================

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print('^2========================================^7')
    print('^2ng-business^7 - Business Management System')
    print('^2Version:^7 1.0.0')
    print('^2Author:^7 NCCGr')
    print('^2========================================^7')
    
    -- Create database tables
    CreateDatabaseTables()
    
    -- Wait a moment for tables to be created
    Wait(1000)
    
    -- Load business data
    LoadBusinessData()
    
    SuccessPrint('ng-business server started successfully')
end)
