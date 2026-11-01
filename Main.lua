if WaveCandyC then
    TabAutoFarm:AddToggle("AUTOFARM HALLOWEEN EVENT", WaveCandyC.Enabled, function(state)
        WaveCandyC.Enabled = state
        if state then WaveCandyC.Start() end
    end)
    
    TabAutoFarm:AddSlider("RADIO DE CARROÑEO", 100, 2000, WaveCandyC.SearchRadius, function(val) WaveCandyC.SearchRadius = val end)

    -- 🔥 SELECTOR DE ELEMENTO PARA EL AUTO FARM
    TabAutoFarm:AddSection("ELEMENTO AL RESPAWN")
    local farmElements = {
        "energy", "luz", "fuego", "agua", "hielo", "tierra", "aire", "oscuridad", 
        "lava", "veneno", "hierro", "espiritu", "destruccion", "cristal", "sonido", 
        "aurora", "fenix", "caos", "tecnología", "diamante", "amor", "demon", 
        "ilusion", "campos de fuerza", "relampago", "telequinesis", "life", "mirror", 
        "time", "sueño", "creacion", "espacio", "realidad", "dios de elementos"
    }

    TabAutoFarm:AddDropdown("ELEMENTO DEL FARM", farmElements, WaveCandyC.SelectedElement, function(val)
        WaveCandyC.SelectedElement = val
        Assets.Notify({Title = "Elemento Guardado", Text = "El AutoFarm usará: " .. string.upper(val), Type = "success"})
    end)
end
