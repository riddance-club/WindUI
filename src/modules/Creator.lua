local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local LocalizationService = cloneref(game:GetService("LocalizationService"))
local HttpService = cloneref(game:GetService("HttpService"))

local DynamicShapeModule = require("./DynamicShape")

local RenderStepped = RunService.Heartbeat

local Icons = require("./Icons")

Icons.SetIconsType("lucide")

local WindUI

local Creator
Creator = {
	Font = "rbxassetid://12187365364",
	Localization = nil,
	CanDraggable = true,
	Theme = nil,
	Themes = nil,
	Icons = Icons,
	-- Connections and font users are weak-keyed so destroyed UI does not
	-- keep them alive forever.
	Signals = setmetatable({}, { __mode = "k" }),
	-- Weak keys so destroyed UI (tooltips, tags, dropdown rows, ...) can be
	-- collected instead of accumulating for the lifetime of the script.
	Objects = setmetatable({}, { __mode = "k" }),
	LocalizationObjects = {},
	UIScale = 1,
	FontObjects = setmetatable({}, { __mode = "k" }),
	Language = string.match(LocalizationService.SystemLocaleId, "^[a-z]+"),
	Request = http_request or (syn and syn.request) or request,
	DefaultProperties = {
		ScreenGui = {
			ResetOnSpawn = false,
			ZIndexBehavior = "Sibling",
		},
		CanvasGroup = {
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(1, 1, 1),
		},
		Frame = {
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(1, 1, 1),
		},
		TextLabel = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Text = "",
			RichText = true,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 14,
		},
		TextButton = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 14,
		},
		TextBox = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			ClearTextOnFocus = false,
			Text = "",
			TextColor3 = Color3.new(0, 0, 0),
			TextSize = 14,
		},
		ImageLabel = {
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
		},
		ImageButton = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			AutoButtonColor = false,
		},
		UIListLayout = {
			SortOrder = "LayoutOrder",
		},
		ScrollingFrame = {
			ScrollBarImageTransparency = 1,
			BorderSizePixel = 0,
		},
		VideoFrame = {
			BorderSizePixel = 0,
		},
	},
	Colors = {
		Red = "#e53935",
		Orange = "#f57c00",
		Green = "#43a047",
		Blue = "#039be5",
		White = "#ffffff",
		Grey = "#484848",
	},
	ThemeFallbacks = nil,
	--[[Shapes = {
		["Square"] = "rbxassetid://82909646051652",
		["Square-Outline"] = "rbxassetid://72946211851948",

		["Squircle"] = "rbxassetid://80999662900595",
		["SquircleOutline"] = "rbxassetid://117788349049947",
		["Squircle-Outline"] = "rbxassetid://117817408534198",

		["SquircleOutline2"] = "rbxassetid://117817408534198",

		["Shadow-sm"] = "rbxassetid://84825982946844",

		["Squircle-TL-TR"] = "rbxassetid://73569156276236",
		["Squircle-BL-BR"] = "rbxassetid://93853842912264",
		["Squircle-TL-TR-Outline"] = "rbxassetid://136702870075563",
		["Squircle-BL-BR-Outline"] = "rbxassetid://75035847706564",

		["Glass-0.7"] = "rbxassetid://79047752995006",
		["Glass-1"] = "rbxassetid://97324581055162",
		["Glass-1.4"] = "rbxassetid://95071123641270",
	},]]
	ThemeChangeCallbacks = {},
}

function Creator.Init(WindUITable)
	WindUI = WindUITable

	Creator.ThemeFallbacks = require("../themes/Fallbacks")(Creator)

	Creator.UIScale = WindUITable.UIScale

	DynamicShapeModule:Init(Creator)
end

function Creator.AddSignal(Signal, Function)
	local conn = Signal:Connect(Function)
	Creator.Signals[conn] = true
	return conn
end

function Creator.DisconnectAll()
	local Signals = Creator.Signals
	for Connection in next, Signals do
		Connection:Disconnect()
	end
	table.clear(Signals)
end

function Creator.SafeCallback(Function, ...)
	if not Function then
		return
	end

	local Success, Event = pcall(Function, ...)
	if not Success then
		if WindUI and WindUI.Window and WindUI.Window.Debug then
			local _, i = Event:find(":%d+: ")

			warn("[ WindUI: DEBUG Mode ] " .. Event)

			return WindUI:Notify({
				Title = "DEBUG Mode: Error",
				Content = not i and Event or Event:sub(i + 1),
				Duration = 8,
			})
		end
	end
end

function Creator.Gradient(stops, props)
	if WindUI and WindUI.Gradient then
		return WindUI:Gradient(stops, props)
	end

	local colorSequence = {}
	local transparencySequence = {}

	for posStr, stop in next, stops do
		local position = tonumber(posStr)
		if position then
			position = math.clamp(position / 100, 0, 1)
			table.insert(colorSequence, ColorSequenceKeypoint.new(position, stop.Color))
			table.insert(transparencySequence, NumberSequenceKeypoint.new(position, stop.Transparency or 0))
		end
	end

	table.sort(colorSequence, function(a, b)
		return a.Time < b.Time
	end)
	table.sort(transparencySequence, function(a, b)
		return a.Time < b.Time
	end)

	if #colorSequence < 2 then
		error("ColorSequence requires at least 2 keypoints")
	end

	local gradientData = {
		Color = ColorSequence.new(colorSequence),
		Transparency = NumberSequence.new(transparencySequence),
	}

	if props then
		for k, v in pairs(props) do
			gradientData[k] = v
		end
	end

	return gradientData
end

function Creator.SetTheme(Theme)
	local PreviousTheme = Creator.Theme
	Creator.Theme = Theme
	Creator.ClearThemeCache()
	Creator.UpdateTheme(nil, false)

	for _, Callback in next, Creator.ThemeChangeCallbacks do
		Creator.SafeCallback(Callback, Theme, PreviousTheme)
	end
end

local FontCache = {}

local function NewFont(FontId, Weight, Style)
	local Key = FontId .. "|" .. Weight.Name .. "|" .. Style.Name
	local Cached = FontCache[Key]
	if not Cached then
		Cached = Font.new(FontId, Weight, Style)
		FontCache[Key] = Cached
	end
	return Cached
end

function Creator.AddFontObject(Object)
	Creator.FontObjects[Object] = true

	-- Only rebuild this object's FontFace if it was created with another font.
	-- (Previously every added label rebuilt a Font for *all* existing labels,
	-- which made element creation O(n^2).)
	local Face = Object.FontFace
	if Face and Face.Family ~= Creator.Font then
		Object.FontFace = NewFont(Creator.Font, Face.Weight, Face.Style)
	end
end

function Creator.UpdateFont(FontId)
	if Creator.Font == FontId then
		return
	end

	Creator.Font = FontId
	for Obj in next, Creator.FontObjects do
		local Face = Obj.FontFace
		Obj.FontFace = NewFont(FontId, Face.Weight, Face.Style)
	end
end

local function NewThemeCache()
	return setmetatable({}, { __mode = "k" })
end

local ThemeCache = NewThemeCache()
local ThemeCacheNil = {}

function Creator.ClearThemeCache()
	ThemeCache = NewThemeCache()
end

local function GetThemeValue(Property, Theme)
	local Value = Theme[Property]
	if Value == nil then
		return nil
	end

	local ValueType = typeof(Value)
	if ValueType == "string" then
		if string.sub(Value, 1, 1) == "#" then
			return Color3.fromHex(Value)
		end
		return Value
	elseif ValueType == "Color3" or ValueType == "number" then
		return Value
	elseif ValueType == "function" then
		return Value(Theme)
	end

	return Value
end

local function ResolveThemeProperty(Property, Theme, Depth)
	if not Theme or Depth > 8 then
		return nil
	end

	local Value = GetThemeValue(Property, Theme)
	if Value ~= nil then
		if typeof(Value) == "string" and string.sub(Value, 1, 1) ~= "#" then
			local Referenced = ResolveThemeProperty(Value, Theme, Depth + 1)
			if Referenced ~= nil then
				return Referenced
			end
		else
			return Value
		end
	end

	local FallbackProperty = Creator.ThemeFallbacks and Creator.ThemeFallbacks[Property]
	if FallbackProperty ~= nil then
		if typeof(FallbackProperty) == "string" and string.sub(FallbackProperty, 1, 1) ~= "#" then
			return ResolveThemeProperty(FallbackProperty, Theme, Depth + 1)
		end
		return GetThemeValue(Property, { [Property] = FallbackProperty })
	end

	local DarkTheme = Creator.Themes and Creator.Themes["Dark"]
	if DarkTheme and DarkTheme ~= Theme then
		Value = GetThemeValue(Property, DarkTheme)
		if Value ~= nil then
			if typeof(Value) == "string" and string.sub(Value, 1, 1) ~= "#" then
				return ResolveThemeProperty(Value, DarkTheme, Depth + 1)
			end
			return Value
		end
	end

	return nil
end

function Creator.GetThemeProperty(Property, Theme)
	local TargetTheme = Theme or Creator.Theme
	if not TargetTheme then
		return nil
	end

	local Cache = ThemeCache[TargetTheme]
	if not Cache then
		Cache = {}
		ThemeCache[TargetTheme] = Cache
	end

	local Value = Cache[Property]
	if Value == nil then
		Value = ResolveThemeProperty(Property, TargetTheme, 0)
		Cache[Property] = Value == nil and ThemeCacheNil or Value
	end

	if Value == ThemeCacheNil then
		return nil
	end
	return Value
end

function Creator.AddThemeObject(Object, Properties, skipUpdate)
	local Existing = Creator.Objects[Object]
	if Existing then
		local ExistingProperties = Existing.Properties
		for prop, value in next, Properties do
			ExistingProperties[prop] = value
		end
	else
		-- The registry is weak-keyed, so the value must not reference the key.
		Creator.Objects[Object] = { Properties = Properties }
	end

	if not skipUpdate then
		Creator.UpdateTheme(Object, false)
	end
	return Object
end

function Creator.AddLangObject(idx)
	local currentObj = Creator.LocalizationObjects[idx]
	if not currentObj then
		return
	end

	local Object = currentObj.Object

	Creator.SetLangForObject(idx)

	return Object
end

local function ApplyThemeValue(Object, objData, Property, Value, isTween, isTweenTarget, Duration, EasingStyle, EasingDirection)
	if typeof(Value) == "Color3" then
		local Gradient = objData.Gradient
		if Gradient then
			Gradient:Destroy()
			objData.Gradient = nil
		end

		-- Repeated SetThemeTag calls (tab selection, hover, ...) often target
		-- the value that is already applied; don't build a tween for those.
		if Object[Property] == Value then
			return
		end

		if isTweenTarget then
			Creator.Tween(
				Object,
				Duration or 0.2,
				{ [Property] = Value },
				EasingStyle or Enum.EasingStyle.Quint,
				EasingDirection or Enum.EasingDirection.Out
			):Play()
		elseif isTween then
			Creator.Tween(Object, 0.08, { [Property] = Value }):Play()
		else
			Object[Property] = Value
		end
	elseif typeof(Value) == "number" then
		if Object[Property] == Value then
			return
		end

		if isTweenTarget then
			Creator.Tween(
				Object,
				Duration or 0.2,
				{ [Property] = Value },
				EasingStyle or Enum.EasingStyle.Quint,
				EasingDirection or Enum.EasingDirection.Out
			):Play()
		elseif isTween then
			Creator.Tween(Object, 0.08, { [Property] = Value }):Play()
		else
			Object[Property] = Value
		end
	elseif typeof(Value) == "table" and Value.Color and Value.Transparency then
		Object[Property] = Color3.new(1, 1, 1)

		local Gradient = objData.Gradient
		if not Gradient then
			Gradient = Instance.new("UIGradient")
			Gradient.Name = "LibraryGradient"
			Gradient.Parent = Object
			objData.Gradient = Gradient
		end

		Gradient.Color = Value.Color
		Gradient.Transparency = Value.Transparency

		for prop, propValue in next, Value do
			if prop ~= "Color" and prop ~= "Transparency" and Gradient[prop] ~= nil then
				Gradient[prop] = propValue
			end
		end
	end
end

local function ApplyTheme(Object, objData, isTween, isTweenTarget, Duration, EasingStyle, EasingDirection)
	local Properties = objData.Properties
	if not Properties then
		return
	end

	for Property, ColorKey in next, Properties do
		local Value = Creator.GetThemeProperty(ColorKey, Creator.Theme)
		if Value ~= nil then
			ApplyThemeValue(Object, objData, Property, Value, isTween, isTweenTarget, Duration, EasingStyle, EasingDirection)
		else
			local Gradient = objData.Gradient
			if Gradient then
				Gradient:Destroy()
				objData.Gradient = nil
			end
		end
	end
end

function Creator.UpdateTheme(TargetObject, isTween, isTweenTarget, Duration, EasingStyle, EasingDirection)
	if TargetObject then
		local objData = Creator.Objects[TargetObject]
		if objData then
			ApplyTheme(TargetObject, objData, isTween, isTweenTarget, Duration, EasingStyle, EasingDirection)
		end
	else
		for Object, objData in next, Creator.Objects do
			ApplyTheme(Object, objData, isTween, isTweenTarget, Duration, EasingStyle, EasingDirection)
		end
	end
end

function Creator.SetThemeTag(Object, ThemeTag, Duration, EasingStyle, EasingDirection)
	-- Skip the immediate (non-tweened) application; otherwise the tween below
	-- starts from the value that was just written and does no visible work.
	Creator.AddThemeObject(Object, ThemeTag, true)
	Creator.UpdateTheme(Object, false, true, Duration, EasingStyle, EasingDirection)
end

function Creator.SetLangForObject(index)
	if Creator.Localization and Creator.Localization.Enabled then
		local data = Creator.LocalizationObjects[index]
		if not data then
			return
		end

		local obj = data.Object
		local translationId = data.TranslationId

		local translations = Creator.Localization.Translations[Creator.Language]
		if translations and translations[translationId] then
			obj.Text = translations[translationId]
		else
			local enTranslations = Creator.Localization
					and Creator.Localization.Translations
					and Creator.Localization.Translations.en
				or nil
			if enTranslations and enTranslations[translationId] then
				obj.Text = enTranslations[translationId]
			else
				obj.Text = "[" .. translationId .. "]"
			end
		end
	end
end

function Creator:ChangeTranslationKey(object, newKey)
	if Creator.Localization and Creator.Localization.Enabled then
		local ParsedKey = string.match(newKey, "^" .. Creator.Localization.Prefix .. "(.+)")
		if ParsedKey then
			for i, data in ipairs(Creator.LocalizationObjects) do
				if data.Object == object then
					data.TranslationId = ParsedKey
					Creator.SetLangForObject(i)
					return
				end
			end

			table.insert(Creator.LocalizationObjects, {
				TranslationId = ParsedKey,
				Object = object,
			})
			Creator.SetLangForObject(#Creator.LocalizationObjects)
		end
	end
end

function Creator.UpdateLang(newLang)
	if newLang then
		Creator.Language = newLang
	end

	for i = 1, #Creator.LocalizationObjects do
		local data = Creator.LocalizationObjects[i]
		if data.Object and data.Object.Parent ~= nil then
			Creator.SetLangForObject(i)
		else
			Creator.LocalizationObjects[i] = nil
		end
	end
end

function Creator.SetLanguage(lang)
	Creator.Language = lang
	Creator.UpdateLang()
end

local IconCache = { [true] = {}, [false] = {} }

function Creator.Icon(Icon, formatdefault)
	if type(Icon) ~= "string" then
		return Icons.Icon2(Icon, nil, formatdefault ~= false)
	end

	local Formatted = formatdefault ~= false
	local Cache = IconCache[Formatted]
	local Cached = Cache[Icon]
	if Cached == nil then
		Cached = Icons.Icon2(Icon, nil, Formatted)
		Cache[Icon] = Cached == nil and false or Cached
	end

	if Cached == false then
		return nil
	end
	return Cached
end

function Creator.AddIcons(packName, iconsData)
	table.clear(IconCache[true])
	table.clear(IconCache[false])
	return Icons.AddIcons(packName, iconsData)
end

function Creator.New(ClassName, Properties, Children)
	local Object = Instance.new(ClassName)

	local Defaults = Creator.DefaultProperties[ClassName]
	if Defaults then
		for Prop, Value in next, Defaults do
			Object[Prop] = Value
		end
	end

	if Properties then
		for Prop, Value in next, Properties do
			if Prop ~= "ThemeTag" then
				Object[Prop] = Value
			end
			if Creator.Localization and Creator.Localization.Enabled and Prop == "Text" then
				local TranslationId = string.match(Value, "^" .. Creator.Localization.Prefix .. "(.+)")
				if TranslationId then
					local currentId = #Creator.LocalizationObjects + 1
					Creator.LocalizationObjects[currentId] = { TranslationId = TranslationId, Object = Object }

					Creator.SetLangForObject(currentId)
				end
			end
		end
	end

	for _, Child in next, Children or {} do
		Child.Parent = Object
	end

	if Properties then
		if Properties.ThemeTag then
			Creator.AddThemeObject(Object, Properties.ThemeTag)
		end
		if Properties.FontFace then
			Creator.AddFontObject(Object)
		end
	end
	return Object
end

function Creator.Tween(Object, Time, Properties, ...)
	return TweenService:Create(Object, TweenInfo.new(Time, ...), Properties)
end

--[[function Creator.NewRoundFrame(Radius, Type, Properties, Children, isButton, ReturnTable)
	local function getImageForType(shapeType)
		return Creator.Shapes[shapeType]
	end

	local function getSliceCenterForType(shapeType)
		return not table.find({ "Shadow-sm", "Glass-0.7", "Glass-1", "Glass-1.4" }, shapeType)
				and Rect.new(512 / 2, 512 / 2, 512 / 2, 512 / 2)
			or Rect.new(512, 512, 512, 512)
	end

	local Image = Creator.New(isButton and "ImageButton" or "ImageLabel", {
		Image = getImageForType(Type),
		ScaleType = "Slice",
		SliceCenter = getSliceCenterForType(Type),
		SliceScale = 1,
		BackgroundTransparency = 1,
		ThemeTag = Properties.ThemeTag and Properties.ThemeTag,
	}, Children)

	for k, v in pairs(Properties or {}) do
		if k ~= "ThemeTag" then
			Image[k] = v
		end
	end

	local function UpdateSliceScale(newRadius)
		local sliceScale = not table.find({ "Shadow-sm", "Glass-0.7", "Glass-1", "Glass-1.4" }, Type)
				and (newRadius / (512 / 2))
			or (newRadius / 512)
		Image.SliceScale = math.max(sliceScale, 0.0001)
	end

	local Wrapper = {}

	function Wrapper:SetRadius(newRadius)
		UpdateSliceScale(newRadius)
	end

	function Wrapper:SetType(newType)
		Type = newType
		Image.Image = getImageForType(newType)
		Image.SliceCenter = getSliceCenterForType(newType)
		UpdateSliceScale(Radius)
	end

	function Wrapper:UpdateShape(newRadius, newType)
		if newType then
			Type = newType
			Image.Image = getImageForType(newType)
			Image.SliceCenter = getSliceCenterForType(newType)
		end
		if newRadius then
			Radius = newRadius
		end
		UpdateSliceScale(Radius)
	end

	function Wrapper:GetRadius()
		return Radius
	end

	function Wrapper:GetType()
		return Type
	end

	UpdateSliceScale(Radius)

	return Image, ReturnTable and Wrapper or nil
end]]

function Creator.NewRoundFrame(Radius, Type, Properties, Children, IsButton, ReturnTable)
	return DynamicShapeModule:New(Radius, Type, Properties, Children, IsButton, nil)
end

local New = Creator.New
local Tween = Creator.Tween

function Creator.SetDraggable(can)
	Creator.CanDraggable = can
end

function Creator.Drag(mainFrame, dragFrames, ondrag)
	local CurInput = WindUI.GenerateGUID()

	local currentDragFrame = nil
	local dragging = false
	local dragStart, startPos
	local activeInput = nil

	local DragModule = {
		CanDraggable = true,
	}

	if not dragFrames or typeof(dragFrames) ~= "table" then
		dragFrames = { mainFrame }
	end

	local function update(input)
		if not dragging or not DragModule.CanDraggable then
			return
		end

		local delta = input.Position - dragStart
		-- Set the position directly instead of creating a new Tween per input
		-- event. InputChanged already fires at input rate, so the tween only
		-- added TweenService churn (and garbage) on the hottest path.
		mainFrame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end

	for _, dragFrame in ipairs(dragFrames) do
		dragFrame.InputBegan:Connect(function(input)
			if not DragModule.CanDraggable or dragging then
				return
			end

			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				if WindUI and WindUI.CurrentInput and WindUI.CurrentInput ~= CurInput then
					return
				end

				WindUI.CurrentInput = CurInput

				dragging = true
				activeInput = input
				currentDragFrame = dragFrame
				dragStart = input.Position
				startPos = mainFrame.Position

				if ondrag and typeof(ondrag) == "function" then
					ondrag(true, currentDragFrame)
				end
			end
		end)
	end

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if WindUI.CurrentInput and WindUI.CurrentInput ~= CurInput then
			return
		end

		if activeInput.UserInputType == Enum.UserInputType.MouseButton1 then
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				update(input)
			end
		elseif activeInput.UserInputType == Enum.UserInputType.Touch then
			if input == activeInput then
				update(input)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if not dragging or WindUI.CurrentInput ~= CurInput then
			return
		end

		if
			input == activeInput
			or (
				activeInput.UserInputType == Enum.UserInputType.MouseButton1
				and input.UserInputType == Enum.UserInputType.MouseButton1
			)
		then
			WindUI.CurrentInput = nil
			dragging = false
			activeInput = nil
			currentDragFrame = nil

			if ondrag and typeof(ondrag) == "function" then
				ondrag(false, nil)
			end
		end
	end)

	function DragModule:Set(v)
		DragModule.CanDraggable = v
	end

	return DragModule
end

Icons.Init(New, "Icon")

function Creator.SanitizeFilename(url)
	local filename = url:match("([^/]+)$") or url

	filename = filename:gsub("%.[^%.]+$", "")

	filename = filename:gsub("[^%w%-_]", "_")

	if #filename > 50 then
		filename = filename:sub(1, 50)
	end

	return filename
end

function Creator.Image(Img, Name, Corner, Folder, Type, IsThemeTag, Themed, ThemeTagName)
	Folder = Folder or "Temp"
	Name = Creator.SanitizeFilename(Name)

	local IconData = Creator.Icon(Img)

	local ImageFrame = New("Frame", {
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
	})

	if IconData then
		-- Build the icon label directly instead of creating a plain ImageLabel
		-- (plus corner) only to destroy it and build another one.
		local IconLabel = Icons.Image({
			Icon = Img,
			Size = UDim2.new(1, 0, 1, 0),
			Colors = {
				(IsThemeTag and (ThemeTagName or "Icon") or false),
				"Button",
			},
		}).IconFrame
		IconLabel.Parent = ImageFrame
		return ImageFrame
	end

	local ImageLabel = New("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ScaleType = "Crop",
		ThemeTag = Themed and {
			ImageColor3 = IsThemeTag and (ThemeTagName or "Icon") or nil,
		} or nil,
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, Corner),
		}),
	})
	ImageLabel.Parent = ImageFrame

	if string.find(Img, "http") and not string.find(Img, "roblox.com") then
		local FileName = "WindUI/" .. Folder .. "/assets/." .. Type .. "-" .. Name .. ".png"
		local success, response = pcall(function()
			task.spawn(function()
				local response = Creator.Request
						and Creator.Request({
							Url = Img,
							Method = "GET",
						}).Body
					or {}

				if not RunService:IsStudio() and writefile then
					writefile(FileName, response)
				end
				--ImageFrame.ImageLabel.Image = getcustomasset(FileName)

				local assetSuccess, asset = pcall(getcustomasset, FileName)
				if assetSuccess then
					ImageLabel.Image = asset
				else
					warn(
						string.format(
							"[ WindUI.Creator ] Failed to load custom asset '%s': %s",
							FileName,
							tostring(asset)
						)
					)
					ImageFrame:Destroy()

					return
				end
			end)
		end)
		if not success then
			warn(
				"[ WindUI.Creator ]  '" .. identifyexecutor()
					or "Studio" .. "' doesnt support the URL Images. Error: " .. response
			)

			ImageFrame:Destroy()
		end
	elseif Img == "" then
		ImageFrame.Visible = false
	else
		ImageLabel.Image = Img
	end

	return ImageFrame
end

function Creator.Color3ToHSB(color)
	local r, g, b = color.R, color.G, color.B
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	local delta = max - min

	local h = 0
	if delta ~= 0 then
		if max == r then
			h = (g - b) / delta % 6
		elseif max == g then
			h = (b - r) / delta + 2
		else
			h = (r - g) / delta + 4
		end
		h = h * 60
	else
		h = 0
	end

	local s = (max == 0) and 0 or (delta / max)
	local v = max

	return {
		h = math.floor(h + 0.5),
		s = s,
		b = v,
	}
end

function Creator.GetPerceivedBrightness(color)
	local r = color.R
	local g = color.G
	local b = color.B
	return 0.299 * r + 0.587 * g + 0.114 * b
end

function Creator.GetTextColorForHSB(color, contrast)
	local hsb = Creator.Color3ToHSB(color)
	local h, s, b = hsb.h, hsb.s, hsb.b
	if Creator.GetPerceivedBrightness(color) > (contrast or 0.5) then
		return Color3.fromHSV(h / 360, 0, 0.05)
	else
		return Color3.fromHSV(h / 360, 0, 0.98)
	end
end

function Creator.GetAverageColor(gradient)
	local r, g, b = 0, 0, 0
	local keypoints = gradient.Color.Keypoints
	for _, k in ipairs(keypoints) do
		-- bruh
		r = r + k.Value.R
		g = g + k.Value.G
		b = b + k.Value.B
	end
	local n = #keypoints
	return Color3.new(r / n, g / n, b / n)
end

function Creator:GenerateUniqueID()
	return HttpService:GenerateGUID(false)
end

function Creator:OnThemeChange(callback)
	if typeof(callback) ~= "function" then
		return
	end

	local id = HttpService:GenerateGUID(false)
	Creator.ThemeChangeCallbacks[id] = callback

	return {
		Disconnect = function()
			Creator.ThemeChangeCallbacks[id] = nil
		end,
	}
end

function Creator:AddColor(base, add, weight)
	weight = math.clamp(weight or 1, 0, 1)
	if typeof(add) == "string" then
		add = Color3.fromHex(add)
	end

	return function(theme)
		local baseColor
		if typeof(base) == "string" and string.sub(base, 1, 1) ~= "#" then
			baseColor = Creator.GetThemeProperty(base, theme)
		elseif typeof(base) == "string" then
			baseColor = Color3.fromHex(base)
		else
			baseColor = base
		end

		if not baseColor or typeof(baseColor) ~= "Color3" then
			return nil
		end

		return Color3.new(
			math.clamp(baseColor.R + add.R * weight, 0, 1),
			math.clamp(baseColor.G + add.G * weight, 0, 1),
			math.clamp(baseColor.B + add.B * weight, 0, 1)
		)
	end
end

function Creator:GetElementPosition(elements, targetIndex, isHStack)
	if type(targetIndex) ~= "number" or targetIndex ~= math.floor(targetIndex) then
		return nil, 1
	end

	local maxIndex = #elements
	if maxIndex == 0 or targetIndex < 1 or targetIndex > maxIndex then
		return nil, 2
	end

	local function isDelimiter(el)
		if el == nil then
			return true
		end
		local t = el.__type
		return t == "Divider" or t == "Space" or t == "Section"
	end

	if isDelimiter(elements[targetIndex]) then
		return nil, 3
	end

	-- Walk to the group boundaries instead of scanning the whole element list.
	local groupStart = targetIndex
	while groupStart > 1 and not isDelimiter(elements[groupStart - 1]) do
		groupStart = groupStart - 1
	end

	local groupEnd = targetIndex
	while groupEnd < maxIndex and not isDelimiter(elements[groupEnd + 1]) do
		groupEnd = groupEnd + 1
	end

	local pos = targetIndex - groupStart + 1
	local size = groupEnd - groupStart + 1

	if size == 1 then
		return "Squircle"
	end
	if pos == 1 then
		return isHStack and "SquircleH-TL-TR" or "Squircle-TL-TR"
	end
	if pos == size then
		return isHStack and "SquircleH-BL-BR" or "Squircle-BL-BR"
	end
	return "Square"
end

return Creator
