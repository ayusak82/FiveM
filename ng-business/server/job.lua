-- ============================================
-- SERVER JOB - ng-business
-- ============================================

-- Create job
RegisterNetEvent('ng-business:server:createJob', function(data)
    local source = source
    
    if not IsPlayerAceAllowed(source, 'command.admin') then
        ErrorPrint('Player', source, 'attempted to create job without permission')
        return
    end
    
    DebugPrint('Creating job:', data.job_name)
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- Check if job already exists
    local existing = MySQL.scalar.await('SELECT id FROM business_jobs WHERE job_name = ?', {data.job_name})
    if existing then
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Job already exists', 5000, 'error', true)
        ErrorPrint('Job already exists:', data.job_name)
        return
    end
    
    -- Insert into database
    local insertId = MySQL.insert.await([[
        INSERT INTO business_jobs (job_name, label, boss_menu_coords, enabled, created_by)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        data.job_name,
        data.label,
        data.boss_menu_coords and json.encode(data.boss_menu_coords) or nil,
        1,
        Player.PlayerData.citizenid
    })
    
    if insertId then
        -- Add to BusinessData
        BusinessData.jobs[data.job_name] = {
            jobName = data.job_name,
            label = data.label,
            bossMenuCoords = data.boss_menu_coords and vector3(data.boss_menu_coords.x, data.boss_menu_coords.y, data.boss_menu_coords.z) or nil,
            enabled = true
        }
        
        -- Notify all clients
        TriggerClientEvent('ng-business:client:updateJobs', -1, BusinessData.jobs)
        TriggerClientEvent('okokNotify:Alert', source, 'Success', 'Job created successfully', 5000, 'success', true)
        SuccessPrint('Job created:', data.job_name, 'by', Player.PlayerData.citizenid)
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Failed to create job', 5000, 'error', true)
        ErrorPrint('Failed to create job:', data.job_name)
    end
end)

-- Open boss menu
RegisterNetEvent('ng-business:server:openBossMenu', function(jobName)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local job = BusinessData.jobs[jobName]
    if not job then
        ErrorPrint('Job not found:', jobName)
        return
    end
    
    -- Check if player has the job
    if Player.PlayerData.job.name ~= jobName then
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'You do not work for this business', 5000, 'error', true)
        return
    end
    
    -- Check if player is boss (grade 4 in QBCore)
    if Player.PlayerData.job.grade.level < 4 then
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'You are not authorized to access the boss menu', 5000, 'error', true)
        return
    end
    
    DebugPrint('Player', source, 'opening boss menu for job:', jobName)
    
    -- Get job-specific data
    local jobStashes = {}
    local jobTrays = {}
    local jobCrafting = {}
    local jobLockers = {}
    
    for _, stash in pairs(BusinessData.stashes) do
        for _, job in ipairs(stash.jobs) do
            if job == jobName then
                table.insert(jobStashes, stash)
                break
            end
        end
    end
    
    for _, tray in pairs(BusinessData.trays) do
        for _, job in ipairs(tray.jobs) do
            if job == jobName then
                table.insert(jobTrays, tray)
                break
            end
        end
    end
    
    for _, station in pairs(BusinessData.crafting) do
        for _, job in ipairs(station.jobs) do
            if job == jobName then
                table.insert(jobCrafting, station)
                break
            end
        end
    end
    
    for _, locker in pairs(BusinessData.lockers) do
        for _, job in ipairs(locker.jobs) do
            if job == jobName then
                table.insert(jobLockers, locker)
                break
            end
        end
    end
    
    -- Send data to client
    TriggerClientEvent('ng-business:client:openBossMenu', source, {
        job = job,
        stashes = jobStashes,
        trays = jobTrays,
        crafting = jobCrafting,
        lockers = jobLockers
    })
end)

-- Delete job
RegisterNetEvent('ng-business:server:deleteJob', function(jobName)
    local source = source
    
    if not IsPlayerAceAllowed(source, 'command.admin') then
        ErrorPrint('Player', source, 'attempted to delete job without permission')
        return
    end
    
    DebugPrint('Deleting job:', jobName)
    
    local affectedRows = MySQL.update.await('DELETE FROM business_jobs WHERE job_name = ?', {jobName})
    
    if affectedRows > 0 then
        BusinessData.jobs[jobName] = nil
        TriggerClientEvent('ng-business:client:updateJobs', -1, BusinessData.jobs)
        TriggerClientEvent('okokNotify:Alert', source, 'Success', 'Job deleted successfully', 5000, 'success', true)
        SuccessPrint('Job deleted:', jobName)
    else
        TriggerClientEvent('okokNotify:Alert', source, 'Error', 'Failed to delete job', 5000, 'error', true)
        ErrorPrint('Failed to delete job:', jobName)
    end
end)

DebugPrint('Job module loaded')
