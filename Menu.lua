local selectedLayout = "Default"
local musicEnabled = true

CreateOnboarding({
    OnComplete = function(layout, musicEnabled)
        selectedLayout = layout
        musicEnabled = musicEnabled

        -- Load EZR features
        local EZR = loadstring(game:HttpGet("https://raw.githubusercontent.com/EzarGG/GUI/refs/heads/main/EZR.lua"))()

        -- Example: Add EZR toggles to your UI
        -- (This depends on your layout's API)
        -- e.g.:
        -- layout:AddToggle("Hitboxes", function(v) EZR.ToggleHitboxes(v) end)
        -- layout:AddSlider("Hitbox Size", 0, 20, 5, function(v) EZR.SetHitboxScale(v) end)

        -- Optional: Load music player
        if musicEnabled then
            loadstring(game:HttpGet("https://xan.bar/musicplayershowcase.lua"))()
        end
    end
})
