# Milenium UI Library Documentation

## Overview
The Milenium UI Library is a comprehensive Roblox Lua UI framework designed for creating customizable and interactive interfaces. This documentation covers all components, functions, and usage examples for the library.

## Table of Contents
1. [Initialization](#initialization)
2. [Window](#window)
3. [Tabs](#tabs)
4. [Sections](#sections)
5. [Elements](#elements)
   - [Toggle](#toggle)
   - [Slider](#slider)
   - [Dropdown](#dropdown)
   - [Color Picker](#color-picker)
   - [Textbox](#textbox)
   - [Keybind](#keybind)
   - [Button](#button)
   - [Label](#label)
6. [Utilities](#utilities)
7. [Configuration System](#configuration-system)
8. [Notification System](#notification-system)

---

## Initialization

```lua
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/your-repo/milenium-ui/main/library.lua"))()
```

## Window

Creates the main window container for all UI elements.

```lua
local window = library:window({
    name = "Milenium",
    suffix = "tech",
    gameInfo = "Milenium for Counter-Strike: Global Offensive",
    size = UDim2.new(0, 700, 0, 565)
})
```

**Properties:**
- `name`: Main window title
- `suffix`: Secondary title text
- `gameInfo`: Game information displayed in footer
- `size`: Window dimensions

**Methods:**
- `toggle_menu(boolean)`: Shows/hides the window

---

## Tabs

Organizes content into separate tabs.

```lua
local tab1, tab2, tab3 = window:tab({
    name = "Visuals",
    icon = "rbxassetid://6034767608",
    tabs = {"Main", "Misc", "Settings"}
})
```

**Properties:**
- `name`: Tab name
- `icon`: Tab icon image ID
- `tabs`: Array of sub-tab names

---

## Sections

Groups related elements together.

```lua
local section = tab1:section({
    name = "ESP",
    side = "left",
    size = 0.5,
    icon = "rbxassetid://6022668898",
    default = true,
    fading = true
})
```

**Properties:**
- `name`: Section title
- `side`: "left" or "right" alignment
- `size`: Relative height (0-1)
- `icon`: Section icon
- `default`: Whether expanded by default
- `fading`: Enable fade toggle

---

## Elements

### Toggle

Boolean switch element.

```lua
local toggle = section:toggle({
    name = "Enable ESP",
    flag = "esp_enabled",
    type = "toggle", -- or "checkbox"
    default = false,
    callback = function(state) print("ESP:", state) end
})
```

### Slider

Numeric range selector.

```lua
local slider = section:slider({
    name = "ESP Distance",
    min = 0,
    max = 1000,
    intervals = 10,
    default = 500,
    suffix = "m",
    flag = "esp_distance",
    callback = function(value) print("Distance:", value) end
})
```

### Dropdown

Single or multi-select menu.

```lua
local dropdown = section:dropdown({
    name = "ESP Targets",
    options = {"Enemies", "Teammates", "NPCs"},
    multi = true,
    flag = "esp_targets",
    callback = function(selection) print("Targets:", selection) end
})
```

### Color Picker

Color selection with transparency.

```lua
local colorpicker = section:colorpicker({
    name = "ESP Color",
    color = Color3.new(1, 0, 0),
    alpha = 0.5,
    flag = "esp_color",
    callback = function(color, alpha) print(color, alpha) end
})
```

### Textbox

Text input field.

```lua
local textbox = section:textbox({
    name = "ESP Tag",
    placeholder = "Enter tag...",
    default = "[ESP]",
    flag = "esp_tag",
    callback = function(text) print("Tag:", text) end
})
```

### Keybind

Key binding element.

```lua
local keybind = section:keybind({
    name = "ESP Toggle Key",
    key = Enum.KeyCode.LeftShift,
    mode = "Toggle", -- or "Hold", "Always"
    flag = "esp_toggle_key",
    callback = function(state) print("Key state:", state) end
})
```

### Button

Clickable button.

```lua
local button = section:button({
    name = "Refresh ESP",
    callback = function() print("Refreshing ESP") end
})
```

### Label

Text display element.

```lua
local label = section:label({
    name = "ESP Status",
    info = "Currently tracking 5 targets"
})
```

---

## Utilities

### Theme Management

```lua
-- Change accent color
library:update_theme("accent", Color3.new(0.5, 0, 1))

-- Apply theme to element
library:apply_theme(element, "accent", "TextColor3")
```

### Configuration System

```lua
-- Initialize config UI (call once)
library:init_config(window)

-- Save current settings
writefile("config.cfg", library:get_config())

-- Load saved settings
library:load_config(readfile("config.cfg"))
```

### Notifications

```lua
library.notifications:create_notification({
    name = "Success",
    info = "Settings saved successfully!",
    lifetime = 3
})
```

---

## Example Usage

```lua
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/vividx07/nova-softworks/main/misc/ui.lua"))()

-- Main Window
local window = library:window({
    name = "nova",
    suffix = "cc",
      gameInfo = "made by venox",
    size = UDim2.new(0, 650, 0, 500)
})

-- ===== COMBAT TAB (WITH SUBTABS) =====
local combatMain, combatAdvanced, combatConfig = window:tab({
    name = "Combat",
    tabs = {"Main", "Advanced", "Config"} -- Subtabs
})

-- Left Column (60% width)
local combatLeftCol = combatMain:column({size = 0.6})
local aimbotSection = combatLeftCol:section({
    name = "Aimbot",
    size = 0.5
})

aimbotSection:toggle({
    name = "Enable",
    flag = "aim_enable",
    callback = function(state)
        print(`AIMBOT {state and "ON" or "OFF"}`)
    end
})

-- Right Column (40% width)
local combatRightCol = combatMain:column({size = 0.4})
local fovSection = combatRightCol:section({
    name = "Settings",
    size = 0.7
})

fovSection:slider({
    name = "FOV",
    min = 1,
    max = 180,
    callback = function(val)
        print(`FOV: {val}°`)
    end
})

-- ===== VISUALS TAB (WITH SUBTABS) =====
local visualsESP, visualsChams, visualsWorld = window:tab({
    name = "Visuals",
    tabs = {"ESP", "Chams", "World"}
})

-- ESP Subtab
local espCol = visualsESP:column({})
espCol:section({name = "Players"}):toggle({
    name = "Box ESP",
    callback = function(s) print(`BOX ESP: {s}`) end
})

-- ===== CONFIG TAB =====
local configTab = window:tab({name = "Config"})
local configCol = configTab:column({size = 0.3}) -- Narrow column

configCol:section({name = "Presets"}):dropdown({
    name = "Profile",
    options = {"Rage", "Legit", "Default"},
    callback = function(opt)
        print(`LOADED PROFILE: {opt}`)
    end
})

-- Keybind Example
local keybindSection = configCol:section({name = "Controls"})
keybindSection:keybind({
    name = "Menu Key",
    default = Enum.KeyCode.Insert,
    callback = function(state)
        print(`MENU KEY: {state and "PRESSED" or "RELEASED"}`)
    end
})

-- Init config system (for saving/loading)
library:init_config(window)
```

This documentation covers all major components of the Milenium UI Library. For advanced usage, refer to the source code comments and examples.
