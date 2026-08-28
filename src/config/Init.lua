local cloneref = (cloneref or clonereference or function(instance) return instance end)

local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))

local Window 

local function isEqual(a, b)
    if a == b then
        return true
    end
    if a == nil or b == nil then
        if (a == nil or a == "" or (type(a) == "table" and next(a) == nil)) and (b == nil or b == "" or (type(b) == "table" and next(b) == nil)) then
            return true
        end
        return false
    end
    if typeof(a) == "Color3" and typeof(b) == "Color3" then
        return a:ToHex() == b:ToHex()
    end
    if typeof(a) == "EnumItem" and typeof(b) == "EnumItem" then
        return a == b
    end
    if typeof(a) == "EnumItem" and type(b) == "string" then
        return a.Name == b
    end
    if type(a) == "string" and typeof(b) == "EnumItem" then
        return a == b.Name
    end
    if type(a) == "table" and type(b) == "table" then
        for k, v in pairs(a) do
            if not isEqual(v, b[k]) then
                return false
            end
        end
        for k, v in pairs(b) do
            if a[k] == nil then
                return false
            end
        end
        return true
    end
    if tonumber(a) and tonumber(b) then
        return tonumber(a) == tonumber(b)
    end
    return tostring(a) == tostring(b)
end

local ConfigManager
ConfigManager = {
    Folder = nil,
    Path = nil,
    Configs = {},
    Parser = {
        Colorpicker = {
            Save = function(obj)
                local curVal = (typeof(obj.Value) == "Color3" and obj.Value) or (typeof(obj.Default) == "Color3" and obj.Default) or (typeof(obj.Color) == "Color3" and obj.Color)
                if not curVal then 
                    return nil 
                end

                local curTrans = obj.Transparency
                local defCol = (obj.__defaultValue and obj.__defaultValue.color) or (typeof(obj.Default) == "Color3" and obj.Default) or (typeof(obj.DefaultValue) == "Color3" and obj.DefaultValue) or (typeof(obj.Color) == "Color3" and obj.Color)
                local defTrans = (obj.__defaultValue and obj.__defaultValue.transparency) or obj.DefaultTransparency or (type(obj.Default) == "table" and obj.Default.Transparency)

                if defCol and curVal:ToHex() == defCol:ToHex() and curTrans == defTrans then
                    return nil
                end

                return {
                    __type = obj.__type,
                    value = curVal:ToHex(),
                    transparency = curTrans or nil,
                }
            end,
            Load = function(element, data)
                if element and element.Update and data and data.value then
                    local curHex = (typeof(element.Value) == "Color3" and element.Value:ToHex()) or (typeof(element.Color) == "Color3" and element.Color:ToHex())
                    if curHex == data.value and element.Transparency == data.transparency then
                        return
                    end
                    pcall(function()
                        element:Update(Color3.fromHex(data.value), data.transparency or nil)
                    end)
                end
            end
        },
        Dropdown = {
            Save = function(obj)
                local curVal = obj.Value
                if curVal == nil then
                    return nil
                end

                local defVal = obj.__defaultValue
                if defVal == nil then
                    defVal = obj.Default ~= nil and obj.Default or obj.DefaultValue
                end

                if isEqual(curVal, defVal) then
                    return nil
                end

                if type(curVal) == "table" and next(curVal) == nil and (defVal == nil or (type(defVal) == "table" and next(defVal) == nil)) then
                    return nil
                end

                return {
                    __type = obj.__type,
                    value = curVal,
                }
            end,
            Load = function(element, data)
                if element and element.Select and data and data.value ~= nil then
                    if isEqual(element.Value, data.value) then
                        return
                    end
                    pcall(function()
                        element:Select(data.value)
                    end)
                end
            end
        },
        Input = {
            Save = function(obj)
                local curVal = obj.Value
                if curVal == nil then
                    return nil
                end

                local defVal = obj.__defaultValue
                if defVal == nil then
                    defVal = obj.Default ~= nil and obj.Default or (obj.DefaultValue ~= nil and obj.DefaultValue or "")
                end

                if isEqual(curVal, defVal) then
                    return nil
                end

                return {
                    __type = obj.__type,
                    value = curVal,
                }
            end,
            Load = function(element, data)
                if element and element.Set and data and data.value ~= nil then
                    if tostring(element.Value) == tostring(data.value) then
                        return
                    end
                    pcall(function()
                        element:Set(data.value)
                    end)
                end
            end
        },
        Keybind = {
            Save = function(obj)
                local curVal = obj.Value
                if typeof(curVal) == "EnumItem" then
                    curVal = curVal.Name
                end
                if curVal == nil or curVal == "None" or curVal == "Unknown" then
                    curVal = ""
                end

                local defVal = obj.__defaultValue
                if defVal == nil then
                    defVal = obj.Default or obj.DefaultValue or ""
                end
                if typeof(defVal) == "EnumItem" then
                    defVal = defVal.Name
                end
                if defVal == nil or defVal == "None" or defVal == "Unknown" then
                    defVal = ""
                end

                if curVal == defVal then
                    return nil
                end

                if curVal == "" and (defVal == "" or defVal == nil) then
                    return nil
                end

                return {
                    __type = obj.__type,
                    value = curVal,
                }
            end,
            Load = function(element, data)
                if element and element.Set and data and data.value ~= nil then
                    local cur = element.Value
                    if typeof(cur) == "EnumItem" then
                        cur = cur.Name
                    end
                    if (cur == nil or cur == "None" or cur == "Unknown") and data.value == "" then
                        return
                    end
                    if cur == data.value then
                        return
                    end
                    pcall(function()
                        element:Set(data.value)
                    end)
                end
            end
        },
        Slider = {
            Save = function(obj)
                local curVal = (type(obj.Value) == "table" and (obj.Value.Default or obj.Value.Value)) or obj.Value
                if curVal == nil then
                    return nil
                end

                local defVal = obj.__defaultValue
                if defVal == nil then
                    defVal = (type(obj.Default) == "table" and (obj.Default.Default or obj.Default.Value)) or obj.Default or (type(obj.Value) == "table" and obj.Value.Default)
                end

                if defVal ~= nil and tonumber(curVal) and tonumber(defVal) and tonumber(curVal) == tonumber(defVal) then
                    return nil
                end

                if isEqual(curVal, defVal) then
                    return nil
                end

                return {
                    __type = obj.__type,
                    value = tonumber(curVal) or curVal,
                }
            end,
            Load = function(element, data)
                if element and element.Set and data and data.value ~= nil then
                    local cur = (type(element.Value) == "table" and (element.Value.Default or element.Value.Value)) or element.Value
                    local target = tonumber(data.value)
                    if target and cur and tonumber(cur) == target then
                        return
                    end
                    pcall(function()
                        element:Set(target or data.value)
                    end)
                end
            end
        },
        Toggle = {
            Save = function(obj)
                local curVal = obj.Value
                if curVal == nil then
                    return nil
                end

                local defVal = obj.__defaultValue
                if defVal == nil then
                    defVal = obj.Default ~= nil and obj.Default or (obj.DefaultValue ~= nil and obj.DefaultValue or false)
                end

                if curVal == defVal then
                    return nil
                end

                return {
                    __type = obj.__type,
                    value = curVal,
                }
            end,
            Load = function(element, data)
                if element and element.Set and data and data.value ~= nil then
                    if element.Value == data.value then
                        return
                    end
                    pcall(function()
                        element:Set(data.value)
                    end)
                end
            end
        },
    }
}

function ConfigManager:Init(WindowTable)
    if not WindowTable.Folder then
        warn("[ WindUI.ConfigManager ] Window.Folder is not specified.")
        return false
    end
    if RunService:IsStudio() or not writefile then
        warn("[ WindUI.ConfigManager ] The config system doesn't work in the studio.")
        return false
    end
    
    Window = WindowTable
    ConfigManager.Folder = Window.Folder
    ConfigManager.Path = "WindUI/" .. tostring(ConfigManager.Folder) .. "/config/"
    
    if not isfolder(ConfigManager.Path) then
        makefolder(ConfigManager.Path)
    end
    
    local files = ConfigManager:AllConfigs()
    
    for _, f in next, files do
        local fullPath = ConfigManager.Path .. f .. ".json"
        if isfile and readfile and isfile(fullPath) then
            ConfigManager.Configs[f] = readfile(fullPath)
        end
    end
    
    return ConfigManager
end

function ConfigManager:SetPath(customPath)
    if not customPath then
        warn("[ WindUI.ConfigManager ] Custom path is not specified.")
        return false
    end
    
    ConfigManager.Path = customPath
    if not customPath:match("/$") then
        ConfigManager.Path = customPath .. "/"
    end
    
    if not isfolder(ConfigManager.Path) then
        makefolder(ConfigManager.Path)
    end
    
    return true
end

function ConfigManager:CreateConfig(configFilename, autoload)
    local ConfigModule = {
        Path = ConfigManager.Path .. configFilename .. ".json",
        Elements = {},
        CustomData = {},
        AutoLoad = autoload or false,
        Version = 1.2,
    }
    
    if not configFilename then
        return false, "No config file is selected"
    end
    
    function ConfigModule:SetAsCurrent()
        Window:SetCurrentConfig(ConfigModule)
    end
    
    function ConfigModule:Register(Name, Element)
        if Element and type(Element) == "table" then
            if Element.__defaultValue == nil then
                if Element.__type == "Slider" then
                    if type(Element.Value) == "table" then
                        Element.__defaultValue = Element.Value.Default or Element.Value.Value
                    else
                        Element.__defaultValue = Element.Value ~= nil and Element.Value or Element.Default
                    end
                elseif Element.__type == "Colorpicker" then
                    local col = (typeof(Element.Value) == "Color3" and Element.Value) or (typeof(Element.Default) == "Color3" and Element.Default) or (typeof(Element.Color) == "Color3" and Element.Color)
                    local trans = Element.Transparency or Element.DefaultTransparency or (type(Element.Default) == "table" and Element.Default.Transparency)
                    Element.__defaultValue = {
                        color = col,
                        transparency = trans
                    }
                elseif Element.__type == "Toggle" then
                    if Element.Default ~= nil then
                        Element.__defaultValue = Element.Default
                    elseif Element.Value ~= nil then
                        Element.__defaultValue = Element.Value
                    else
                        Element.__defaultValue = false
                    end
                elseif Element.__type == "Dropdown" then
                    local val = Element.Default ~= nil and Element.Default or (Element.DefaultValue ~= nil and Element.DefaultValue or Element.Value)
                    if type(val) == "table" then
                        local clone = {}
                        for k, v in pairs(val) do
                            clone[k] = v
                        end
                        Element.__defaultValue = clone
                    else
                        Element.__defaultValue = val
                    end
                elseif Element.__type == "Keybind" then
                    local k = Element.Default or Element.DefaultValue or Element.Value or ""
                    if typeof(k) == "EnumItem" then
                        k = k.Name
                    end
                    if k == "None" or k == "Unknown" then
                        k = ""
                    end
                    Element.__defaultValue = k
                elseif Element.__type == "Input" then
                    Element.__defaultValue = Element.Default ~= nil and Element.Default or (Element.DefaultValue ~= nil and Element.DefaultValue or (Element.Value ~= nil and Element.Value or ""))
                else
                    Element.__defaultValue = Element.Default ~= nil and Element.Default or Element.Value
                end
            end
        end
        ConfigModule.Elements[Name] = Element
    end
    
    function ConfigModule:Set(key, value)
        ConfigModule.CustomData[key] = value
    end
    
    function ConfigModule:Get(key)
        return ConfigModule.CustomData[key]
    end
    
    function ConfigModule:SetAutoLoad(Value)
        ConfigModule.AutoLoad = Value
    end
    
    function ConfigModule:Save()
        if Window and Window.PendingFlags then
            for flag, element in next, Window.PendingFlags do
                ConfigModule:Register(flag, element)
            end
        end
        
        local saveData = {
            __version = ConfigModule.Version,
            __elements = {},
            __autoload = ConfigModule.AutoLoad,
            __custom = ConfigModule.CustomData
        }
        
        for name, element in next, ConfigModule.Elements do
            if ConfigManager.Parser[element.__type] then
                local parsed = ConfigManager.Parser[element.__type].Save(element)
                if parsed ~= nil then
                    saveData.__elements[tostring(name)] = parsed
                end
            end
        end
        
        local jsonData = HttpService:JSONEncode(saveData)
        if writefile then 
            writefile(ConfigModule.Path, jsonData)
        end
        
        return saveData
    end
    
    function ConfigModule:Load()
        if isfile and not isfile(ConfigModule.Path) then 
            return false, "Config file does not exist" 
        end
        
        local success, loadData = pcall(function()
            local readfile = readfile or function() 
                warn("[ WindUI.ConfigManager ] The config system doesn't work in the studio.") 
                return nil 
            end
            return HttpService:JSONDecode(readfile(ConfigModule.Path))
        end)
        
        if not success then
            return false, "Failed to parse config file"
        end
        
        if not loadData.__version then
            local migratedData = {
                __version = ConfigModule.Version,
                __elements = loadData,
                __custom = {}
            }
            loadData = migratedData
        end
        
        if Window and Window.PendingFlags then
            for flag, element in next, Window.PendingFlags do
                ConfigModule:Register(flag, element)
            end
        end
        
        local frameBudget = 0.006
        local startClock = os.clock()
        
        for name, data in next, (loadData.__elements or {}) do
            local element = ConfigModule.Elements[name]
            if element and data and data.__type and ConfigManager.Parser[data.__type] then
                ConfigManager.Parser[data.__type].Load(element, data)
                if os.clock() - startClock > frameBudget then
                    task.wait()
                    startClock = os.clock()
                end
            end
        end
        
        ConfigModule.CustomData = loadData.__custom or {}
        
        return ConfigModule.CustomData
    end
    
    function ConfigModule:Delete()
        if not delfile then
            return false, "delfile function is not available"
        end
        
        if not isfile(ConfigModule.Path) then
            return false, "Config file does not exist"
        end
        
        local success, err = pcall(function()
            delfile(ConfigModule.Path)
        end)
        
        if not success then
            return false, "Failed to delete config file: " .. tostring(err)
        end
        
        ConfigManager.Configs[configFilename] = nil
        
        if Window.CurrentConfig == ConfigModule then
            Window.CurrentConfig = nil
        end
        
        return true, "Config deleted successfully"
    end
    
    function ConfigModule:GetData()
        return {
            elements = ConfigModule.Elements,
            custom = ConfigModule.CustomData,
            autoload = ConfigModule.AutoLoad
        }
    end
    
    if Window and Window.PendingFlags then
        for flag, element in next, Window.PendingFlags do
            ConfigModule:Register(flag, element)
        end
    end
    
    if isfile(ConfigModule.Path) then
        local success, configData = pcall(function()
            return HttpService:JSONDecode(readfile(ConfigModule.Path))
        end)
        
        if success and configData and configData.__autoload then
            ConfigModule.AutoLoad = true
            
            task.spawn(function()
                task.wait(0.5)
                local success, result = pcall(function()
                    return ConfigModule:Load()
                end)
                if success then
                    if Window.Debug then print("[ WindUI.ConfigManager ] AutoLoaded config: " .. configFilename) end
                else
                    warn("[ WindUI.ConfigManager ] Failed to AutoLoad config: " .. configFilename .. " - " .. tostring(result))
                end
            end)
        end
    end
    
    ConfigModule:SetAsCurrent()
    ConfigManager.Configs[configFilename] = ConfigModule
    return ConfigModule
end

function ConfigManager:Config(configFilename, autoload)
    return ConfigManager:CreateConfig(configFilename, autoload)
end

function ConfigManager:GetAutoLoadConfigs()
    local autoloadConfigs = {}
    
    for configName, configModule in pairs(ConfigManager.Configs) do
        if configModule.AutoLoad then
            table.insert(autoloadConfigs, configName)
        end
    end
    
    return autoloadConfigs
end

function ConfigManager:DeleteConfig(configName)
    if not delfile then
        return false, "delfile function is not available"
    end
    
    local configPath = ConfigManager.Path .. configName .. ".json"
    
    if not isfile(configPath) then
        return false, "Config file does not exist"
    end
    
    local success, err = pcall(function()
        delfile(configPath)
    end)
    
    if not success then
        return false, "Failed to delete config file: " .. tostring(err)
    end
    
    ConfigManager.Configs[configName] = nil
    
    if Window.CurrentConfig and Window.CurrentConfig.Path == configPath then
        Window.CurrentConfig = nil
    end
    
    return true, "Config deleted successfully"
end

function ConfigManager:AllConfigs()
    if not listfiles then return {} end
    
    local files = {}
    if not isfolder(ConfigManager.Path) then
        makefolder(ConfigManager.Path)
        return files
    end
    
    for _, file in next, listfiles(ConfigManager.Path) do
        local name = file:match("([^\\/]+)%.json$")
        if name then
            table.insert(files, name)
        end
    end
    
    return files
end

function ConfigManager:GetConfig(configName)
    return ConfigManager.Configs[configName]
end

return ConfigManager
