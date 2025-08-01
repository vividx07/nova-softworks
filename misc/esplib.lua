--[[
    esp-lib.lua (FULLY FIXED VERSION)
    A stable library for creating ESP visuals in Roblox using drawing.
    Provides functions to add boxes, health bars, names and distances to instances.
    Fixed crash issues and improved stability.
]]

-- // table
local esplib = getgenv().esplib
if not esplib then
    esplib = {
        box = {
            enabled = false,
            type = "normal", -- normal, corner
            padding = 1.15,
            fill = Color3.new(1,1,1),
            outline = Color3.new(0,0,0),
        },
        healthbar = {
            enabled = false,
            fill = Color3.new(0,1,0),
            outline = Color3.new(0,0,0),
        },
        name = {
            enabled = false,
            fill = Color3.new(1,1,1),
            size = 13,
        },
        distance = {
            enabled = false,
            fill = Color3.new(1,1,1),
            size = 13,
        },
        tracer = {
            enabled = false,
            fill = Color3.new(1,1,1),
            outline = Color3.new(0,0,0),
            from = "mouse", -- mouse, head, top, bottom, center
        },
    }
    getgenv().esplib = esplib
end

local espinstances = {}
local espfunctions = {}
local renderConnection = nil

-- // services
local run_service = game:GetService("RunService")
local players = game:GetService("Players")
local user_input_service = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

-- Improved safe removal function
local function safe_remove(obj)
    if obj and typeof(obj) == "Instance" and obj.Remove then
        local success, err = pcall(obj.Remove, obj)
        if not success then
            warn("Failed to remove object:", err)
        end
    end
end

-- More robust bounding box calculation
local function get_bounding_box(instance)
    local min, max = Vector2.new(math.huge, math.huge), Vector2.new(-math.huge, -math.huge)
    local onscreen = false

    if not instance or not instance.Parent then
        return min, max, false
    end

    local function process_part(part)
        local size = (part.Size / 2) * esplib.box.padding
        local cf = part.CFrame
        for _, offset in ipairs({
            Vector3.new( size.X,  size.Y,  size.Z),
            Vector3.new(-size.X,  size.Y,  size.Z),
            Vector3.new( size.X, -size.Y,  size.Z),
            Vector3.new(-size.X, -size.Y,  size.Z),
            Vector3.new( size.X,  size.Y, -size.Z),
            Vector3.new(-size.X,  size.Y, -size.Z),
            Vector3.new( size.X, -size.Y, -size.Z),
            Vector3.new(-size.X, -size.Y, -size.Z),
        }) do
            local success, pos, visible = pcall(function()
                return camera:WorldToViewportPoint(cf:PointToWorldSpace(offset))
            end)
            if success and visible then
                local v2 = Vector2.new(pos.X, pos.Y)
                min = min:Min(v2)
                max = max:Max(v2)
                onscreen = true
            end
        end
    end

    pcall(function()
        if instance:IsA("Model") then
            for _, p in ipairs(instance:GetChildren()) do
                if p:IsA("BasePart") then
                    process_part(p)
                elseif p:IsA("Accessory") then
                    local handle = p:FindFirstChild("Handle")
                    if handle and handle:IsA("BasePart") then
                        process_part(handle)
                    end
                end
            end
        elseif instance:IsA("BasePart") then
            process_part(instance)
        end
    end)

    return min, max, onscreen
end

-- More thorough cleanup function
local function cleanup_instance(instance)
    local data = espinstances[instance]
    if not data then return end

    -- Safely clean up all drawing objects
    local function safe_cleanup(tbl)
        if tbl then
            for _, v in pairs(tbl) do
                if type(v) == "table" then
                    safe_cleanup(v)
                else
                    safe_remove(v)
                end
            end
        end
    end

    safe_cleanup(data)
    espinstances[instance] = nil
end

-- Improved add functions with better error handling
function espfunctions.add_box(instance)
    if not instance then return end
    if espinstances[instance] and espinstances[instance].box then return end

    local success, box = pcall(function()
        local new_box = {}
        
        local outline = Drawing.new("Square")
        outline.Thickness = 3
        outline.Filled = false
        outline.Transparency = 1
        outline.Visible = false
        outline.ZIndex = 1

        local fill = Drawing.new("Square")
        fill.Thickness = 1
        fill.Filled = false
        fill.Transparency = 1
        fill.Visible = false
        fill.ZIndex = 2

        new_box.outline = outline
        new_box.fill = fill

        if esplib.box.type == "corner" then
            new_box.corner_fill = {}
            new_box.corner_outline = {}
            for i = 1, 8 do
                local outline_line = Drawing.new("Line")
                outline_line.Thickness = 3
                outline_line.Transparency = 1
                outline_line.Visible = false
                outline_line.ZIndex = 1

                local fill_line = Drawing.new("Line")
                fill_line.Thickness = 1
                fill_line.Transparency = 1
                fill_line.Visible = false
                fill_line.ZIndex = 2

                table.insert(new_box.corner_fill, fill_line)
                table.insert(new_box.corner_outline, outline_line)
            end
        end

        return new_box
    end)

    if success and box then
        espinstances[instance] = espinstances[instance] or {}
        espinstances[instance].box = box
    else
        warn("Failed to create box ESP:", box)
    end
end

function espfunctions.add_healthbar(instance)
    if not instance then return end
    if espinstances[instance] and espinstances[instance].healthbar then return end

    local success, healthbar = pcall(function()
        local new_healthbar = {}
        
        local outline = Drawing.new("Square")
        outline.Thickness = 1
        outline.Filled = true
        outline.Transparency = 1
        outline.Visible = false
        outline.ZIndex = 1

        local fill = Drawing.new("Square")
        fill.Filled = true
        fill.Transparency = 1
        fill.Visible = false
        fill.ZIndex = 2

        new_healthbar.outline = outline
        new_healthbar.fill = fill
        
        return new_healthbar
    end)

    if success and healthbar then
        espinstances[instance] = espinstances[instance] or {}
        espinstances[instance].healthbar = healthbar
    else
        warn("Failed to create healthbar ESP:", healthbar)
    end
end

function espfunctions.add_name(instance)
    if not instance then return end
    if espinstances[instance] and espinstances[instance].name then return end

    local success, text = pcall(function()
        local new_text = Drawing.new("Text")
        new_text.Center = true
        new_text.Outline = true
        new_text.Font = 2
        new_text.Transparency = 1
        new_text.Visible = false
        new_text.ZIndex = 3
        return new_text
    end)

    if success and text then
        espinstances[instance] = espinstances[instance] or {}
        espinstances[instance].name = text
    else
        warn("Failed to create name ESP:", text)
    end
end

function espfunctions.add_distance(instance)
    if not instance then return end
    if espinstances[instance] and espinstances[instance].distance then return end

    local success, text = pcall(function()
        local new_text = Drawing.new("Text")
        new_text.Center = true
        new_text.Outline = true
        new_text.Font = 2
        new_text.Transparency = 1
        new_text.Visible = false
        new_text.ZIndex = 3
        return new_text
    end)

    if success and text then
        espinstances[instance] = espinstances[instance] or {}
        espinstances[instance].distance = text
    else
        warn("Failed to create distance ESP:", text)
    end
end

function espfunctions.add_tracer(instance)
    if not instance then return end
    if espinstances[instance] and espinstances[instance].tracer then return end

    local success, tracer = pcall(function()
        local new_tracer = {}
        
        local outline = Drawing.new("Line")
        outline.Thickness = 3
        outline.Transparency = 1
        outline.Visible = false
        outline.ZIndex = 1

        local fill = Drawing.new("Line")
        fill.Thickness = 1
        fill.Transparency = 1
        fill.Visible = false
        fill.ZIndex = 2

        new_tracer.outline = outline
        new_tracer.fill = fill
        
        return new_tracer
    end)

    if success and tracer then
        espinstances[instance] = espinstances[instance] or {}
        espinstances[instance].tracer = tracer
    else
        warn("Failed to create tracer ESP:", tracer)
    end
end

-- Main render loop with better performance and stability
local function render_loop()
    -- Create a copy of instances to avoid modification during iteration
    local instances_copy = {}
    for instance, data in pairs(espinstances) do
        if instance and instance.Parent then
            instances_copy[instance] = data
        else
            cleanup_instance(instance)
        end
    end

    for instance, data in pairs(instances_copy) do
        local success, err = pcall(function()
            if not instance or not instance.Parent then
                cleanup_instance(instance)
                return
            end

            if instance:IsA("Model") and not instance.PrimaryPart and not instance:FindFirstChildWhichIsA("BasePart") then
                return
            end

            local min, max, onscreen = get_bounding_box(instance)

            -- Box ESP
            if data.box and esplib.box.enabled then
                local box = data.box
                
                if onscreen then
                    local x, y = min.X, min.Y
                    local w, h = (max - min).X, (max - min).Y
                    
                    if w <= 0 or h <= 0 then
                        box.outline.Visible = false
                        box.fill.Visible = false
                        if box.corner_fill then
                            for _, line in ipairs(box.corner_fill) do
                                line.Visible = false
                            end
                        end
                        if box.corner_outline then
                            for _, line in ipairs(box.corner_outline) do
                                line.Visible = false
                            end
                        end
                        return
                    end

                    if esplib.box.type == "normal" then
                        box.outline.Position = min
                        box.outline.Size = max - min
                        box.outline.Color = esplib.box.outline
                        box.outline.Visible = true

                        box.fill.Position = min
                        box.fill.Size = max - min
                        box.fill.Color = esplib.box.fill
                        box.fill.Visible = true

                        if box.corner_fill then
                            for _, line in ipairs(box.corner_fill) do
                                line.Visible = false
                            end
                        end
                        if box.corner_outline then
                            for _, line in ipairs(box.corner_outline) do
                                line.Visible = false
                            end
                        end
                    elseif esplib.box.type == "corner" and box.corner_fill and box.corner_outline then
                        local len = math.min(w, h) * 0.25
                        local fill_color = esplib.box.fill
                        local outline_color = esplib.box.outline

                        local corners = {
                            { Vector2.new(x, y), Vector2.new(x + len, y) },
                            { Vector2.new(x, y), Vector2.new(x, y + len) },
                            { Vector2.new(x + w - len, y), Vector2.new(x + w, y) },
                            { Vector2.new(x + w, y), Vector2.new(x + w, y + len) },
                            { Vector2.new(x, y + h), Vector2.new(x + len, y + h) },
                            { Vector2.new(x, y + h - len), Vector2.new(x, y + h) },
                            { Vector2.new(x + w - len, y + h), Vector2.new(x + w, y + h) },
                            { Vector2.new(x + w, y + h - len), Vector2.new(x + w, y + h) },
                        }

                        for i = 1, math.min(8, #box.corner_fill, #box.corner_outline) do
                            local from, to = corners[i][1], corners[i][2]
                            local dir = (to - from).Unit
                            local oFrom = from - dir
                            local oTo = to + dir

                            box.corner_outline[i].From = oFrom
                            box.corner_outline[i].To = oTo
                            box.corner_outline[i].Color = outline_color
                            box.corner_outline[i].Visible = true

                            box.corner_fill[i].From = from
                            box.corner_fill[i].To = to
                            box.corner_fill[i].Color = fill_color
                            box.corner_fill[i].Visible = true
                        end

                        box.outline.Visible = false
                        box.fill.Visible = false
                    end
                else
                    box.outline.Visible = false
                    box.fill.Visible = false
                    if box.corner_fill then
                        for _, line in ipairs(box.corner_fill) do
                            line.Visible = false
                        end
                    end
                    if box.corner_outline then
                        for _, line in ipairs(box.corner_outline) do
                            line.Visible = false
                        end
                    end
                end
            elseif data.box then
                local box = data.box
                box.outline.Visible = false
                box.fill.Visible = false
                if box.corner_fill then
                    for _, line in ipairs(box.corner_fill) do
                        line.Visible = false
                    end
                end
                if box.corner_outline then
                    for _, line in ipairs(box.corner_outline) do
                        line.Visible = false
                    end
                end
            end

            -- Healthbar ESP
            if data.healthbar and esplib.healthbar.enabled then
                local outline, fill = data.healthbar.outline, data.healthbar.fill
                
                if onscreen then
                    local humanoid = instance:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.MaxHealth > 0 then
                        local height = max.Y - min.Y
                        local padding = 1
                        local x = min.X - 3 - 1 - padding
                        local y = min.Y - padding
                        local health = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                        local fillheight = height * health

                        outline.Color = esplib.healthbar.outline
                        outline.Position = Vector2.new(x, y)
                        outline.Size = Vector2.new(1 + 2 * padding, height + 2 * padding)
                        outline.Visible = true

                        fill.Color = esplib.healthbar.fill
                        fill.Position = Vector2.new(x + padding, y + (height + padding) - fillheight)
                        fill.Size = Vector2.new(1, fillheight)
                        fill.Visible = true
                    else
                        outline.Visible = false
                        fill.Visible = false
                    end
                else
                    outline.Visible = false
                    fill.Visible = false
                end
            elseif data.healthbar then
                data.healthbar.outline.Visible = false
                data.healthbar.fill.Visible = false
            end

            -- Name ESP
            if data.name and esplib.name.enabled then
                if onscreen then
                    local center_x = (min.X + max.X) / 2
                    local y = min.Y - 15

                    local name_str = tostring(instance.Name)
                    local humanoid = instance:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        local player = players:GetPlayerFromCharacter(instance)
                        if player then
                            name_str = tostring(player.DisplayName) or tostring(player.Name)
                        end
                    end

                    data.name.Text = name_str
                    data.name.Size = esplib.name.size
                    data.name.Color = esplib.name.fill
                    data.name.Position = Vector2.new(center_x, y)
                    data.name.Visible = true
                else
                    data.name.Visible = false
                end
            elseif data.name then
                data.name.Visible = false
            end

            -- Distance ESP
            if data.distance and esplib.distance.enabled then
                if onscreen then
                    local center_x = (min.X + max.X) / 2
                    local y = max.Y + 5
                    local dist = 999

                    if instance:IsA("Model") then
                        if instance.PrimaryPart then
                            dist = (camera.CFrame.Position - instance.PrimaryPart.Position).Magnitude
                        else
                            local part = instance:FindFirstChildWhichIsA("BasePart")
                            if part then
                                dist = (camera.CFrame.Position - part.Position).Magnitude
                            end
                        end
                    elseif instance:IsA("BasePart") then
                        dist = (camera.CFrame.Position - instance.Position).Magnitude
                    end

                    data.distance.Text = tostring(math.floor(dist)) .. "m"
                    data.distance.Size = esplib.distance.size
                    data.distance.Color = esplib.distance.fill
                    data.distance.Position = Vector2.new(center_x, y)
                    data.distance.Visible = true
                else
                    data.distance.Visible = false
                end
            elseif data.distance then
                data.distance.Visible = false
            end

            -- Tracer ESP
            if data.tracer and esplib.tracer.enabled then
                if onscreen then
                    local outline, fill = data.tracer.outline, data.tracer.fill
                    local from_pos = Vector2.new()
                    local to_pos = (min + max) / 2

                    if esplib.tracer.from == "mouse" then
                        local mouse_location = user_input_service:GetMouseLocation()
                        from_pos = Vector2.new(mouse_location.X, mouse_location.Y)
                    elseif esplib.tracer.from == "head" then
                        local head = instance:FindFirstChild("Head")
                        if head then
                            local pos, visible = camera:WorldToViewportPoint(head.Position)
                            if visible then
                                from_pos = Vector2.new(pos.X, pos.Y)
                            else
                                from_pos = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
                            end
                        else
                            from_pos = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
                        end
                    elseif esplib.tracer.from == "bottom" then
                        from_pos = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
                    elseif esplib.tracer.from == "center" then
                        from_pos = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
                    elseif esplib.tracer.from == "top" then
                        from_pos = Vector2.new(camera.ViewportSize.X/2, 0)
                    else
                        from_pos = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
                    end

                    outline.From = from_pos
                    outline.To = to_pos
                    outline.Color = esplib.tracer.outline
                    outline.Visible = true

                    fill.From = from_pos
                    fill.To = to_pos
                    fill.Color = esplib.tracer.fill
                    fill.Visible = true
                else
                    data.tracer.outline.Visible = false
                    data.tracer.fill.Visible = false
                end
            elseif data.tracer then
                data.tracer.outline.Visible = false
                data.tracer.fill.Visible = false
            end
        end)

        if not success then
            warn("Error rendering ESP for instance:", instance, "Error:", err)
            cleanup_instance(instance)
        end
    end
end

-- Improved cleanup function
function espfunctions.cleanup()
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
    
    for instance, _ in pairs(espinstances) do
        cleanup_instance(instance)
    end
    espinstances = {}
end

function espfunctions.remove_esp(instance)
    if instance then
        cleanup_instance(instance)
    end
end

-- Initialize render loop if not already running
if not renderConnection then
    renderConnection = run_service.RenderStepped:Connect(render_loop)
end

-- Expose functions
for k, v in pairs(espfunctions) do
    esplib[k] = v
end

-- Set all features to disabled by default (to prevent crashes when enabling)
esplib.box.enabled = false
esplib.healthbar.enabled = false
esplib.name.enabled = false
esplib.distance.enabled = false
esplib.tracer.enabled = false

return esplib
