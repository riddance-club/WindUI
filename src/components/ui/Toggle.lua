local Toggle = {}

local Creator = require("../../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween

local UserInputService = game:GetService("UserInputService")

function Toggle.New(Value, Icon, IconSize, Parent, Callback, NewElement, Config)
	local Toggle = {
		GlassSpritesheet = {
			Id = "rbxassetid://77297718671545",
			MirroredId = "rbxassetid://92258969882244",
			Size = Vector2.new(102, 128),
			Total = 80,
			Cols = 10,
		},
	}

	function Toggle:GetGlassFrame(T: number): (string, Vector2, Vector2)
		local S = Toggle.GlassSpritesheet
		local Frame: number

		if T <= 0.4 then
			Frame = math.floor((T / 0.4) * (S.Total - 1))
		elseif T < 0.6 then
			Frame = S.Total - 1
		else
			Frame = math.floor(((T - 0.6) / 0.4) * (S.Total - 1))
		end

		Frame = math.clamp(Frame, 0, S.Total - 1)

		local Mirrored = T >= 0.6
		if Mirrored then
			Frame = (S.Total - 1) - Frame
		end

		local Id = Mirrored and S.MirroredId or S.Id

		return Id, S.Size, Vector2.new((Frame % S.Cols) * S.Size.X, math.floor(Frame / S.Cols) * S.Size.Y)
	end

	local Radius = 24 / 2
	local IconToggleFrame
	local IconData = Creator.Icon(Icon)
	if Icon and Icon ~= "" and IconData then
		IconToggleFrame = New("ImageLabel", {
			Size = UDim2.new(0, 20 - 7, 0, 20 - 7),
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Image = IconData[1],
			ImageRectOffset = IconData[2].ImageRectPosition,
			ImageRectSize = IconData[2].ImageRectSize,
			ImageTransparency = 1,
			ImageColor3 = Color3.new(0, 0, 0),
		})
	end

	local ToggleContainer = New("Frame", {
		Size = UDim2.new(0, 2, 0, 26),
		BackgroundTransparency = 1,
		Parent = Parent,
	})

	local ToggleFrame = Creator.NewRoundFrame(Radius, "Squircle", {
		ImageTransparency = 0.85,
		ThemeTag = {
			ImageColor3 = "Text",
		},
		Parent = ToggleContainer,
		Size = UDim2.new(0, NewElement and (24 + 24 + 4) or (24 * 1.7), 0, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Name = "ToggleFrame",
	}, {
		Creator.NewRoundFrame(Radius, "Squircle", {
			Size = UDim2.new(1, 0, 1, 0),
			Name = "Layer",
			ThemeTag = {
				ImageColor3 = "Toggle",
			},
			ImageTransparency = 1, -- 0
		}),
		Creator.NewRoundFrame(Radius, "Squircle", {
			Size = UDim2.new(0, NewElement and 30 or 20, 0, 20),
			Position = UDim2.new(0, 2, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			ImageTransparency = 0,
			ImageColor3 = Color3.new(1, 1, 1),
			ThemeTag = {
				ImageColor3 = "ToggleBar",
			},
			Name = "Frame",
		}, {
			IconToggleFrame,
			New("UIScale", {
				Scale = 1,
			}),
		}),
		New("TextButton", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Name = "Hitbox",
			Text = "",
		}),
	})

	local dragConnection
	local endConnection
	local startX
	local FrameWidth = NewElement and 30 or 20
	local ToggleWidth = ToggleFrame.Size.X.Offset

	function Toggle:Set(Toggled, isCallback, isAnim)
		if not isAnim then
			local Target = Toggled and UDim2.new(0, ToggleWidth - FrameWidth - 2, 0.5, 0)
				or UDim2.new(0, 2, 0.5, 0)
			Tween(ToggleFrame.Frame, 0.3, { Position = Target }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
		else
			if Toggled then
				ToggleFrame.Frame.Position = UDim2.new(0, ToggleWidth - FrameWidth - 2, 0.5, 0)
			else
				ToggleFrame.Frame.Position = UDim2.new(0, 2, 0.5, 0)
			end
		end

		Tween(ToggleFrame.Layer, 0.1, {
			ImageTransparency = Toggled and 0 or 1,
		}):Play()

		if IconToggleFrame then
			Tween(IconToggleFrame, 0.1, {
				ImageTransparency = Toggled and 0 or 1,
			}):Play()
		end

		isCallback = isCallback ~= false

		task.spawn(function()
			if Callback and isCallback then
				Creator.SafeCallback(Callback, Toggled)
			end
		end)
	end

	function Toggle:Animate(input, ToggleObj)
		if not Config.Window.IsToggleDragging then
			Config.Window.IsToggleDragging = true

			local startMouseX = input.Position.X
			local startMouseY = input.Position.Y
			local startFrameX = ToggleFrame.Frame.Position.X.Offset
			local isScrolling = false
			local hasDragged = false

			Tween(
				ToggleFrame.Frame.UIScale,
				0.28,
				{ Scale = 1.5 },
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.Out
			):Play()

			if dragConnection then
				dragConnection:Disconnect()
			end

			dragConnection = UserInputService.InputChanged:Connect(function(inputChanged)
				if not Config.Window.IsToggleDragging then
					return
				end
				if
					inputChanged.UserInputType ~= Enum.UserInputType.MouseMovement
					and inputChanged.UserInputType ~= Enum.UserInputType.Touch
				then
					return
				end
				if isScrolling then
					return
				end

				local deltaX = math.abs(inputChanged.Position.X - startMouseX)
				local deltaY = math.abs(inputChanged.Position.Y - startMouseY)

				if not hasDragged and deltaX > 8 then
					hasDragged = true
				end

				local mouseDelta = inputChanged.Position.X - startMouseX
				local newX = math.max(2, math.min(startFrameX + mouseDelta, ToggleWidth - FrameWidth - 2))


				-- Directly track the pointer; a 0.12s tween per mouse-move can
				-- never finish and just churns TweenService every frame.
				ToggleFrame.Frame.Position = UDim2.new(0, newX, 0.5, 0)
			end)

			if endConnection then
				endConnection:Disconnect()
			end

			endConnection = UserInputService.InputEnded:Connect(function(inputEnded)
				if not Config.Window.IsToggleDragging then
					return
				end
				if
					inputEnded.UserInputType ~= Enum.UserInputType.MouseButton1
					and inputEnded.UserInputType ~= Enum.UserInputType.Touch
				then
					return
				end

				Config.Window.IsToggleDragging = false

				if dragConnection then
					dragConnection:Disconnect()
					dragConnection = nil
				end
				if endConnection then
					endConnection:Disconnect()
					endConnection = nil
				end

				Config.WindUI.CurrentInput = nil

				if isScrolling then
					return
				end

				if not hasDragged then
					ToggleObj:Set(not ToggleObj.Value, true, false)
				else
					local currentX = ToggleFrame.Frame.Position.X.Offset
					local barCenter = currentX + FrameWidth / 2
					local newValue = barCenter > ToggleWidth / 2
					ToggleObj:Set(newValue, true, false)
				end

				Tween(
					ToggleFrame.Frame.UIScale,
					0.23,
					{ Scale = 1 },
					Enum.EasingStyle.Quint,
					Enum.EasingDirection.Out
				):Play()
			end)
		end
	end

	return ToggleContainer, Toggle
end

return Toggle
