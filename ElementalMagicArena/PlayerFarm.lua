local function stopFarm()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    -- 1. Apagar los módulos PRIMERO (Hitbox, AttackAll)
    toggleModules(false)
    
    if root then
        -- 2. Quitar la física del Farm (BodyPosition)
        local bp = root:FindFirstChild("FarmBP")
        if bp then bp:Destroy() end
        
        -- 3. 🔥 FIX DEL FLING: Anclar un segundo para evitar el bug
        root.Anchored = true 
        
        -- 4. Resetear velocidades a 0 (Evita que salgas disparado)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        
        -- 5. Teletransportar al suelo de la arena de forma segura
        -- (FARM_Y + 5 lo pone justo un poco arriba del suelo para que caiga suave)
        root.CFrame = CFrame.new(FARM_X, FARM_Y + 5, FARM_Z)
        
        -- 6. Desanclar para que recuperes el control normal
        root.Anchored = false
    end
    
    -- 7. Devolver el control al Humanoid
    if hum then 
        hum.PlatformStand = false 
        hum.Sit = false
    end
    
    -- 8. Hacer visible al personaje de nuevo
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end
        end
    end

    -- 9. Limpieza de UI y Bucles
    if gui then gui:Destroy(); gui = nil end
    updateUIFunc = nil
    if fpsCon then fpsCon:Disconnect(); fpsCon = nil end
    if uiLoop then task.cancel(uiLoop); uiLoop = nil end
    if weaponLoop then task.cancel(weaponLoop); weaponLoop = nil end
    if killTrackerCon then task.cancel(killTrackerCon); killTrackerCon = nil end
    if soulLoop then task.cancel(soulLoop); soulLoop = nil end
    
    playerStates = {}
end
