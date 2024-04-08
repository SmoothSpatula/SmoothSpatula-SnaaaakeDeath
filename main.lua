-- Snake Death v1.0.3
-- SmoothSpatula

log.info("Successfully loaded ".._ENV["!guid"]..".")
mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.hfuncs then Helper = v end end end)

-- ========== Audio ==========

local death_sfx = gm.audio_create_stream(_ENV["!plugins_mod_folder_path"].."/SnakeDeath.ogg")
if death_sfx ~= -1 then log.info("Loaded death sfx.")
else log.info("Failed to load death sfx.") end

local global_death_sfx = gm.audio_create_stream(_ENV["!plugins_mod_folder_path"].."/snake-snake-snaaaake.ogg")
if global_death_sfx ~= -1 then log.info("Loaded global death sfx.")
else log.info("Failed to load global death sfx.") end

-- ========== ImGui ==========

local snake_death_enabled = true
gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.Checkbox("Enable Snaaaake Death", snake_death_enabled)
    if clicked then
        snake_death_enabled = new_value
    end
end)

-- ========== Utils ==========

-- Compute the euclidian distance between two points
function distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt ( dx * dx + dy * dy )
end

-- Compute the norm of a 2D vector
function norm(x1, y1)
    return math.sqrt(x1 * x1 + y1 * y1)
end

-- ========== Main ==========

-- Get the client player instance
local player = nil
gm.pre_script_hook(gm.constants.__input_system_tick, function()
    if player == nil then
        player = Helper.get_client_player()
    end
end)

-- Play a custom sound when a player die and when all the players are dead 
gm.post_script_hook(gm.constants.actor_set_dead, function(self, other, result, args)
    if gm.actor_is_player(args[1]) and snake_death_enabled then
        local player_dead = args[1].value

        local dist = distance(player.x, player.y, player_dead.x, player_dead.y)

        local x_offset = player_dead.x - player.x
        local y_offset = player_dead.y - player.y
        
        if dist > 1000 then
            local norm = norm(x_offset, y_offset)
            x_offset = 1000 * x_offset/norm
            y_offset = 1000 * y_offset/norm
        end

        -- Play a sound when someone dies
        gm.sound_play_at(death_sfx, 1, 1, player.x + x_offset, player.y + y_offset, 500000)

        for i = 1, #gm.CInstance.instances_active do
            local inst = gm.CInstance.instances_active[i]
            if inst.object_index == gm.constants.oP and gm.actor_is_alive(inst.id) then return end
        end
        
        -- Play a sound when everyone is dead
        gm.sound_play_global(global_death_sfx, 1, 1)
    end 
end)

-- Reset the player when the run is finished
gm.post_script_hook(gm.constants.run_destroy, function(self, other, result, args)
    player = nil
end)
