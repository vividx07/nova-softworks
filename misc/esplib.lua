--[[

    esp-lib.lua (FIXED VERSION)
    A library for creating esp visuals in roblox using drawing.
    Provides functions to add boxes, health bars, names and distances to instances.
    Written by tul (@.lutyeh) - Fixed version

]]

-- // table
local esplib = getgenv().esplib
if not esplib then
    esplib = {
        box = {
            enabled = true,
            type = "normal", -- normal, corner
            padding = 1.15,
            fill = Color3.new(1,1,1),
            outline = Color3.new(0,0,0),
        },
        healthbar = {
            enabled = true,
            fill = Color3.new(0,1,0),
            outline = Color3.new(0,0,0),
        },
        name = {
            enabled = true,
            fill = Color3.new(1,1,1),
            size = 13,
        },
        distance = {
            enabled = true,
            fill = Color3.new(1,1,1),
            size = 13,
        },
        tracer = {
            enabled = true,
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

local function safe_remove(obj)
    if obj and typeof(obj) == "Instance" and obj.Remove then
        pcall(function()
            obj:Remove()
        end)
    end
end

local function get_bounding_box(instance)
    local min, max = Vector2.new(math.huge, math.huge), Vector2.new(-math.huge, -math.huge)
    local onscreen = false

    if not instance or not instance.Parent then
        return min, max, false
    end

    pcall(function()
        if instance:IsA("Model") then
            for _, p in ipairs(instance:GetChildren()) do
                if p:IsA("BasePart") then
                    local size = (p.Size / 2) * esplib.box.padding
                    local cf = p.CFrame
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
                elseif p:IsA("Accessory") then
                    local handle = p:FindFirstChild("Handle")
                    if handle and handle:IsA("BasePart") then
                        local size = (handle.Size / 2) * esplib.box.padding
                        local cf = handle.CFrame
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
                end
            end
        elseif instance:IsA("BasePart") then
            local size = (instance.Size / 2)
            local cf = instance.CFrame
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
    end)

    return min, max, onscreen
end

local function cleanup_instance(instance)
    local data = espinstances[instance]
    if not data then return end

    pcall(function()
        if data.box then
            safe_remove(data.box.outline)
            safe_remove(data.box.fill)
            if data.box.corner_fill then
                for _, line in ipairs(data.box.corner_fill) do
                    safe_remove(line)
                end
            end
            if data.box.corner_outline then
                for _, line in ipairs(data.box.corner_outline) do
                    safe_remove(line)
                end
            end
        end
        if data.healthbar then
            safe_remove(data.healthbar.outline)
            safe_remove(data.healthbar.fill)
        end
        if data.name then
            safe_remove(data.name)
        end
        if data.distance then
            safe_remove(data.distance)
        end
        if data.tracer then
            safe_remove(data.tracer.outline)
            safe_remove(data.tracer.fill)
        end
    end)

    espinstances[instance] = nil
end

function espfunctions.add_box(instance)
    if not instance then return end
    if espinstances[instance] and espinstances[instance].box then return end

    local box = {}
    local success = pcall(function()
        local outline = Drawing.new("Square")
        outline.Thickness = 3
        outline.Filled = false
        outline.Transparency = 1
        outline.Visible = false

        local fill = Drawing.new("Square")
        fill.Thickness = 1
        fill.Filled = false
        fill.Transparency = 1
        fill.Visible = false

        box.outline = outline
        box.fill = fill

        box.corner_fill = {}
        box.corner_outline = {}
        for i = 1, 8 do
            local outline_line = Drawing.new("Line")
            outline_line.Thickness = 3
            outline_line.Transparency = 1
            outline_line.Visible = false

            local fill_line = Drawing.new("Line")
            fill_line.Thickness = 1
            fill_line.Transparency = 1
            fill_line.Visible = false

            table.insert(box.corner_fill, fill_line)
            table.insert(box.corner_outline, outline_line)
        end
    end)

    if not success then
        return
    end

    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].box = box
end

function espfunctions.add_healthbar(instance)
    if not instance then return end
    if espinstances[instance] and espinstances[instance].healthbar then return end

    local healthbar = {}
    local success = pcall(function()
        local outline = Drawing.new("Square")
        outline.Thickness = 1
        outline.Filled = true
        outline.Transparency = 1
        outline.Visible = false

        local fill = Drawing.new("Square")
        fill.Filled = true
        fill.Transparency = 1
        fill.Visible = false

        healthbar.outline = outline
        healthbar.fill = fill
    end)

    if not success then
        return
    end

    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].healthbar = healthbar
end

function espfunctions.add_name(instance)
    if not instance then return end
    if espinstances[instance] and espinstances[instance].name then return end

    local text = nil
    local success = pcall(function()
        text = Drawing.new("Text")
        text.Center = true
        text.Outline = true
        text.Font = 1
        text.Transparency = 1
        text.Visible = false
    end)

    if not success or not text then
        return
    end

    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].name = text
end

function espfunctions.add_distance(instance)
    if not instance then return end
    if espinstances[instance] and espinstances[instance].distance then return end

    local text = nil
    local success = pcall(function()
        text = Drawing.new("Text")
        text.Center = true
        text.Outline = true
        text.Font = 1
        text.Transparency = 1
        text.Visible = false
    end)

    if not success or not text then
        return
    end

    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].distance = text
end

function espfunctions.add_tracer(instance)
    if not instance then return end
    if espinstances[instance] and espinstances[instance].tracer then return end

    local tracer = {}
    local success = pcall(function()
        local outline = Drawing.new("Line")
        outline.Thickness = 3
        outline.Transparency = 1
        outline.Visible = false

        local fill = Drawing.new("Line")
        fill.Thickness = 1
        fill.Transparency = 1
        fill.Visible = false

        tracer.outline = outline
        tracer.fill = fill
    end)

    if not success then
        return
    end

    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].tracer = tracer
end

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
    if instance and espinstances[instance] then
        cleanup_instance(instance)
    end
end

if esplib.name.enabled and not data.name then esplib.add_name(instance) data = espinstances[instance] end
if esplib.box.enabled and not data.box then esplib.add_box(instance) data = espinstances[instance] end
if esplib.distance.enabled and not data.distance then esplib.add_distance(instance) data = espinstances[instance] end
if esplib.tracer.enabled and not data.tracer then esplib.add_tracer(instance) data = espinstances[instance] end
if esplib.healthbar.enabled and not data.healthbar then esplib.add_healthbar(instance) data = espinstances[instance] end
local function render_loop()
    local instances_copy = {}
    for instance, data in pairs(espinstances) do
        instances_copy[instance] = data
    end

    for instance, data in pairs(instances_copy) do
        pcall(function()
            if not instance or not instance.Parent then
                cleanup_instance(instance)
                return
            end

            if instance:IsA("Model") and not instance.PrimaryPart and not instance:FindFirstChildWhichIsA("BasePart") then
                return
            end

            local min, max, onscreen = get_bounding_box(instance)

            if data.box then
                local box = data.box
                pcall(function()
                    if esplib.box.enabled and onscreen then
                        local x, y = min.X, min.Y
                        local w, h = (max - min).X, (max - min).Y
                        
                        if w <= 0 or h <= 0 then
                            box.outline.Visible = false
                            box.fill.Visible = false
                            for _, line in ipairs(box.corner_fill or {}) do
                                line.Visible = false
                            end
                            for _, line in ipairs(box.corner_outline or {}) do
                                line.Visible = false
                            end
                            return
                        end

                        local len = math.min(w, h) * 0.25

                        if esplib.box.type == "normal" then
                            box.outline.Position = min
                            box.outline.Size = max - min
                            box.outline.Color = esplib.box.outline
                            box.outline.Visible = true

                            box.fill.Position = min
                            box.fill.Size = max - min
                            box.fill.Color = esplib.box.fill
                            box.fill.Visible = true

                            for _, line in ipairs(box.corner_fill or {}) do
                                line.Visible = false
                            end
                            for _, line in ipairs(box.corner_outline or {}) do
                                line.Visible = false
                            end

                        elseif esplib.box.type == "corner" then
                            local fill_lines = box.corner_fill or {}
                            local outline_lines = box.corner_outline or {}
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

                            for i = 1, math.min(8, #fill_lines, #outline_lines) do
                                local from, to = corners[i][1], corners[i][2]
                                local dir = (to - from).Unit
                                local oFrom = from - dir
                                local oTo = to + dir

                                local o = outline_lines[i]
                                if o then
                                    o.From = oFrom
                                    o.To = oTo
                                    o.Color = outline_color
                                    o.Visible = true
                                end

                                local f = fill_lines[i]
                                if f then
                                    f.From = from
                                    f.To = to
                                    f.Color = fill_color
                                    f.Visible = true
                                end
                            end

                            box.outline.Visible = false
                            box.fill.Visible = false
                        end
                    else
                        box.outline.Visible = false
                        box.fill.Visible = false
                        for _, line in ipairs(box.corner_fill or {}) do
                            line.Visible = false
                        end
                        for _, line in ipairs(box.corner_outline or {}) do
                            line.Visible = false
                        end
                    end
                end)
            end

            if data.healthbar then
                pcall(function()
                    local outline, fill = data.healthbar.outline, data.healthbar.fill

                    if not esplib.healthbar.enabled or not onscreen then
                        outline.Visible = false
                        fill.Visible = false
                    else
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
                    end
                end)
            end

            if data.name then
                pcall(function()
                    if esplib.name.enabled and onscreen then
                        local text = data.name
                        local center_x = (min.X + max.X) / 2
                        local y = min.Y - 15

                        local name_str = tostring(instance.Name)
                        local humanoid = instance:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            local player = players:GetPlayerFromCharacter(instance)
                            if player then
                                name_str = tostring(player.Name)
                            end
                        end

                        text.Text = name_str
                        text.Size = esplib.name.size
                        text.Color = esplib.name.fill
                        text.Position = Vector2.new(center_x, y)
                        text.Visible = true
                    else
                        data.name.Visible = false
                    end
                end)
            end

            if data.distance then
                pcall(function()
                    if esplib.distance.enabled and onscreen then
                        local text = data.distance
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

                        text.Text = tostring(math.floor(dist)) .. "m"
                        text.Size = esplib.distance.size
                        text.Color = esplib.distance.fill
                        text.Position = Vector2.new(center_x, y)
                        text.Visible = true
                    else
                        data.distance.Visible = false
                    end
                end)
            end

            if data.tracer then
                pcall(function()
                    if esplib.tracer.enabled and onscreen then
                        local outline, fill = data.tracer.outline, data.tracer.fill

                        local from_pos = Vector2.new()
                        local to_pos = Vector2.new()

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

                        to_pos = (min + max) / 2

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
                end)
            end
        end)
    end
end

if renderConnection then
    renderConnection:Disconnect()
end

renderConnection = run_service.RenderStepped:Connect(render_loop)

for k, v in pairs(espfunctions) do
    esplib[k] = v
end

return esplib
