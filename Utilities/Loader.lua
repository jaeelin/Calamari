local Loader = {
	GetService = function(service)
		return cloneref and cloneref(game:GetService(service)) or game:GetService(service)
	end
}

local Players = Loader.GetService("Players")
local ContentProvider = Loader.GetService("ContentProvider")
local TweenService = Loader.GetService("TweenService")
local MarketplaceService = Loader.GetService("MarketplaceService")

local AssetLoader = loadstring(game:HttpGet("https://raw.githubusercontent.com/jaeelin/Calamari/refs/heads/main/Utilities/AssetLoader.lua"))()

local Assets = {
	Icon = AssetLoader:Get("", "Icon.png")
}

local function BuildGUI()
	local loader_gui = Instance.new("ScreenGui")
	loader_gui.DisplayOrder = 20
	loader_gui.ResetOnSpawn = false
	loader_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	loader_gui.IgnoreGuiInset = true
	loader_gui.Enabled = false
	loader_gui.Parent = (gethui and gethui()) or (cloneref and cloneref(Loader.GetService("CoreGui")) or Loader.GetService("CoreGui"))
	return loader_gui
end

local function Tween(Instance: Instance, Property: any, Duration: number, Style: Enum, Direction: string)
	local info = TweenInfo.new(Duration or 0.5, Style or Enum.EasingStyle.Sine, Direction or Enum.EasingDirection.Out)
	local tween = TweenService:Create(Instance, info, Property)
	
	tween:Play()
	
	return tween
end

local function Fade(Tweenable : {}, Direction: string, Duration: number)
	for _, info in next, Tweenable do
		local value = Direction == "in" and info.FadeIn or info.FadeOut
		local properties = {}
		
		properties[info.Property] = value
		
		Tween(info.Object, properties, Duration)
	end
end

local function Animate(Image: ImageLabel)
	local current = 1
	
	task.spawn(function()
		while task.wait(1 / 60) do
			current += 1
			
			if current > 119 then
				current = 1
			end

			local x = (current - 1) % 15
			local y = math.floor((current - 1) / 15)

			Image.ImageRectOffset = Vector2.new(x * 64, y * 64)
		end
	end)
end

function Loader.New(Settings: {any})
	local supported = Settings.Supported or false
	
	local assets_list = {}
	
	for _, asset in next, Assets do
		table.insert(assets_list, asset)
	end

	ContentProvider:PreloadAsync(assets_list)
	
	local WindowFunctions = {}

	local gui = BuildGUI()

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Parent = gui
	background.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	background.BackgroundTransparency = 1
	background.BorderColor3 = Color3.fromRGB(0, 0, 0)
	background.BorderSizePixel = 0
	background.Size = UDim2.new(1, 0, 1, 0)
	
	local container = Instance.new("ImageLabel")
	container.Name = "Container"
	container.Parent = background
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.BackgroundColor3 = Color3.fromRGB(200, 180, 255)
	container.BackgroundTransparency = 1
	container.ImageTransparency = 1
	container.ImageColor3 = Color3.fromRGB(255, 200, 200)
	container.BorderColor3 = Color3.fromRGB(0, 0, 0)
	container.BorderSizePixel = 0
	container.Position = UDim2.new(0.5, 0, 0.25, 0)
	container.Size = UDim2.new(0.15, 0, 0.3, 0)
	container.Image = Assets.Icon
	container.ScaleType = Enum.ScaleType.Crop
	
	local ui_stroke = Instance.new("UIStroke")
	ui_stroke.Parent = container
	ui_stroke.Color = Color3.fromRGB(200, 180, 255)
	ui_stroke.Thickness = 1.5
	ui_stroke.Transparency = 1
	ui_stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	
	local ui_corner = Instance.new("UICorner")
	ui_corner.CornerRadius = UDim.new(0.1, 0)
	ui_corner.Parent = container

	local main_title = Instance.new("TextLabel")
	main_title.Parent = background
	main_title.Text = "Calamari.xxx"
	main_title.BackgroundTransparency = 1
	main_title.TextTransparency = 1
	main_title.Position = UDim2.new(0, 0, 0.55, 0)
	main_title.Size = UDim2.new(1, 0, 0.05, 0)
	main_title.FontFace = Font.new("rbxassetid://12187365364")
	main_title.TextColor3 = Color3.fromRGB(200, 180, 255)
	main_title.TextScaled = true
	
	local text_constraint = Instance.new("UITextSizeConstraint")
	text_constraint.Parent = main_title
	text_constraint.MaxTextSize = 25
	
	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Parent = background
	description.BackgroundColor3 = Color3.fromRGB(200, 180, 255)
	description.BackgroundTransparency = 1
	description.TextTransparency = 1
	description.BorderColor3 = Color3.fromRGB(0, 0, 0)
	description.BorderSizePixel = 0
	description.Position = UDim2.new(0.085, 0, 0.6, 0)
	description.Size = UDim2.new(0.825, 0, 0.035, 0)
	description.Font = Enum.Font.Gotham
	description.Text = "https://discord.com/invite/jWXrcr74a9"
	description.TextColor3 = Color3.fromRGB(200, 180, 255)
	description.TextScaled = true
	description.TextSize = 14
	description.TextWrapped = true
	
	local text_constraint_2 = Instance.new("UITextSizeConstraint")
	text_constraint_2.Parent = description
	text_constraint_2.MaxTextSize = 20
	
	local game_info = Instance.new("TextLabel")
	game_info.Name = "game_info"
	game_info.Parent = background
	game_info.BackgroundColor3 = Color3.fromRGB(200, 180, 255)
	game_info.BackgroundTransparency = 1
	game_info.TextTransparency = 1
	game_info.BorderColor3 = Color3.fromRGB(0, 0, 0)
	game_info.BorderSizePixel = 0
	game_info.Position = UDim2.new(0, 0, 0.85, 0)
	game_info.Size = UDim2.new(1, 0, 0.05, 0)
	game_info.Font = Enum.Font.Gotham
	game_info.Text = string.format("Game Detected | %s",  MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Asset).Name)

	game_info.TextColor3 = Color3.fromRGB(200, 180, 255)
	game_info.TextScaled = true
	game_info.TextSize = 14
	game_info.TextWrapped = true

	local text_constraint_3 = Instance.new("UITextSizeConstraint")
	text_constraint_3.Parent = game_info
	text_constraint_3.MaxTextSize = 25
	
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Parent = background
	status.BackgroundColor3 = Color3.fromRGB(200, 180, 255)
	status.BackgroundTransparency = 1
	status.TextTransparency = 1
	status.BorderColor3 = Color3.fromRGB(0, 0, 0)
	status.BorderSizePixel = 0
	status.Position = UDim2.new(0, 0, 0.9, 0)
	status.Size = UDim2.new(1, 0, 0.05, 0)
	status.Font = Enum.Font.Gotham
	status.Text = string.format("Status | %s", supported and "Supported" or "Unsupported")
	status.TextColor3 = Color3.fromRGB(200, 180, 255)
	status.TextScaled = true
	status.TextSize = 14
	status.TextWrapped = true
	
	local text_constraint_4 = Instance.new("UITextSizeConstraint")
	text_constraint_4.Parent = status
	text_constraint_4.MaxTextSize = 25
	
	local circular_loading = Instance.new("ImageLabel")
	circular_loading.Name = "Loading"
	circular_loading.Parent = background
	circular_loading.AnchorPoint = Vector2.new(0.5, 0.5)
	circular_loading.BackgroundColor3 = Color3.fromRGB(200, 180, 255)
	circular_loading.BackgroundTransparency = 1
	circular_loading.ImageTransparency = 1
	circular_loading.BorderColor3 = Color3.fromRGB(0, 0, 0)
	circular_loading.BorderSizePixel = 0
	circular_loading.Position = UDim2.new(0.5, 0, 0.75, 0)
	circular_loading.Size = UDim2.new(0.025, 0, 0.05, 0)
	circular_loading.Image = "http://www.roblox.com/asset/?id=138092500933483"
	circular_loading.ImageColor3 = Color3.fromRGB(200, 180, 255)
	circular_loading.ImageRectSize = Vector2.new(63, 63)
	circular_loading.ScaleType = Enum.ScaleType.Fit
	
	local tweenable = {
		{Object = background, Property = "BackgroundTransparency", FadeIn = 0.2, FadeOut = 1},
		{Object = container, Property = "ImageTransparency", FadeIn = 0, FadeOut = 1},
		{Object = ui_stroke, Property = "Transparency", FadeIn = 0, FadeOut = 1},
		{Object = main_title, Property = "TextTransparency", FadeIn = 0, FadeOut = 1},
		{Object = description, Property = "TextTransparency", FadeIn = 0, FadeOut = 1},
		{Object = game_info, Property = "TextTransparency", FadeIn = 0, FadeOut = 1},
		{Object = status, Property = "TextTransparency", FadeIn = 0, FadeOut = 1},
		{Object = circular_loading, Property = "ImageTransparency", FadeIn = 0, FadeOut = 1},
	}
	
	Fade(tweenable, "in", 0.5)
	
	Animate(circular_loading)
	
	function WindowFunctions:Unload()
		Fade(tweenable, "out", 0.5)
		
		task.wait(0.5)
		
		gui:Destroy()
	end
	
	gui.Enabled = true
	
	task.wait(5)
	
	if supported and Settings.Script then
		loadstring(Settings.Script)()
	else
		loadstring(game:HttpGet("https://raw.githubusercontent.com/jaeelin/Test/refs/heads/main/Unsupported.lua"))()
	end
	
	WindowFunctions:Unload()

	return WindowFunctions
end

local Settings = {
	Supported = true,
	Script = nil
}

local success, result = pcall(function()
	return game:HttpGet(string.format("https://raw.githubusercontent.com/jaeelin/Calamari/refs/heads/main/Scripts/%s.lua", game.GameId))
end)

if success and result and #result > 0 then
	Settings.Script = result
else
	Settings.Supported = false
end

local main = Loader.New(Settings)

return Loader
