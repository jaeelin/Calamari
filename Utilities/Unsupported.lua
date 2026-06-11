local Loader = {
	GetService = function(service)
		return cloneref and cloneref(game:GetService(service)) or game:GetService(service)
	end
}

local Players = Loader.GetService("Players")
local ContentProvider = Loader.GetService("ContentProvider")
local TweenService = Loader.GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

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

function Loader.New()
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
	container.Position = UDim2.new(0.5, 0, 0.03, 0)
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
	main_title.Position = UDim2.new(0, 0, 0.33, 0)
	main_title.Size = UDim2.new(1, 0, 0.05, 0)
	main_title.FontFace = Font.new("rbxassetid://12187365364")
	main_title.TextColor3 = Color3.fromRGB(200, 180, 255)
	main_title.TextScaled = true
	
	local text_constraint = Instance.new("UITextSizeConstraint")
	text_constraint.Parent = main_title
	text_constraint.MaxTextSize = 30
	
	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Parent = background
	description.BackgroundColor3 = Color3.fromRGB(200, 180, 255)
	description.BackgroundTransparency = 1
	description.TextTransparency = 1
	description.BorderColor3 = Color3.fromRGB(0, 0, 0)
	description.BorderSizePixel = 0
	description.Position = UDim2.new(0.085, 0, 0.38, 0)
	description.Size = UDim2.new(0.825, 0, 0.02, 0)
	description.Font = Enum.Font.Gotham
	description.Text = "https://discord.com/invite/jWXrcr74a9"
	description.TextColor3 = Color3.fromRGB(200, 180, 255)
	description.TextScaled = true
	description.TextSize = 14
	description.TextWrapped = true
	
	local text_constraint_2 = Instance.new("UITextSizeConstraint")
	text_constraint_2.Parent = description
	text_constraint_2.MaxTextSize = 20
	
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Parent = background
	text.BackgroundColor3 = Color3.fromRGB(200, 180, 255)
	text.BackgroundTransparency = 1
	text.TextTransparency = 1
	text.BorderColor3 = Color3.fromRGB(0, 0, 0)
	text.BorderSizePixel = 0
	text.Position = UDim2.new(0, 0, 0.486, 0)
	text.Size = UDim2.new(1, 0, 0.035, 0)
	text.Font = Enum.Font.Gotham
	text.Text = string.format("Hello %s, Calamari does NOT support this game!", LocalPlayer.Name)
	text.TextColor3 = Color3.fromRGB(200, 180, 255)
	text.TextScaled = true
	text.TextSize = 14
	text.TextWrapped = true

	local text_constraint_3 = Instance.new("UITextSizeConstraint")
	text_constraint_3.Parent = text
	text_constraint_3.MaxTextSize = 25
	
	local text2 = Instance.new("TextLabel")
	text2.Name = "Text2"
	text2.Parent = background
	text2.BackgroundColor3 = Color3.fromRGB(200, 180, 255)
	text2.BackgroundTransparency = 1
	text2.TextTransparency = 1
	text2.BorderColor3 = Color3.fromRGB(0, 0, 0)
	text2.BorderSizePixel = 0
	text2.Position = UDim2.new(0, 0, 0.519, 0)
	text2.Size = UDim2.new(1, 0, 0.04, 0)
	text2.Font = Enum.Font.Gotham
	text2.Text = "If you would like to request a script for this game, please join our discord server."
	text2.TextColor3 = Color3.fromRGB(200, 180, 255)
	text2.TextScaled = true
	text2.TextSize = 14
	text2.TextWrapped = true
	
	local text_constraint_4 = Instance.new("UITextSizeConstraint")
	text_constraint_4.Parent = text2
	text_constraint_4.MaxTextSize = 25
	
	local discord = Instance.new("TextButton")
	discord.Name = "Discord"
	discord.Parent = background
	discord.AnchorPoint = Vector2.new(0.5, 0)
	discord.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	discord.BackgroundTransparency = 1
	discord.TextTransparency = 1
	discord.BorderColor3 = Color3.fromRGB(0, 0, 0)
	discord.BorderSizePixel = 0
	discord.Position = UDim2.new(0.5, 0, 0.6, 0)
	discord.Size = UDim2.new(0.25, 0, 0.055, 0)
	discord.Font = Enum.Font.SourceSans
	discord.Text = "Copy discord"
	discord.TextColor3 = Color3.fromRGB(200, 180, 255)
	discord.TextScaled = true
	discord.TextSize = 14
	discord.TextWrapped = true
	
	local ui_corner_2 = Instance.new("UICorner")
	ui_corner_2.CornerRadius = UDim.new(0.1, 0)
	ui_corner_2.Parent = discord
	
	local text_constraint_5 = Instance.new("UITextSizeConstraint")
	text_constraint_5.Parent = discord
	text_constraint_5.MaxTextSize = 30
	
	local ui_stroke_2 = Instance.new("UIStroke")
	ui_stroke_2.Parent = discord
	ui_stroke_2.Transparency = 1
	ui_stroke_2.Color = Color3.fromRGB(200, 180, 255)
	ui_stroke_2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	
	local tweenable = {
		{Object = background, Property = "BackgroundTransparency", FadeIn = 0.2, FadeOut = 1},
		{Object = container, Property = "ImageTransparency", FadeIn = 0, FadeOut = 1},
		{Object = ui_stroke, Property = "Transparency", FadeIn = 0, FadeOut = 1},
		{Object = main_title, Property = "TextTransparency", FadeIn = 0, FadeOut = 1},
		{Object = description, Property = "TextTransparency", FadeIn = 0, FadeOut = 1},
		{Object = text, Property = "TextTransparency", FadeIn = 0, FadeOut = 1},
		{Object = text2, Property = "TextTransparency", FadeIn = 0, FadeOut = 1},
		{Object = discord, Property = "BackgroundTransparency", FadeIn = 0, FadeOut = 1},
		{Object = discord, Property = "TextTransparency", FadeIn = 0, FadeOut = 1},
		{Object = ui_stroke_2, Property = "Transparency", FadeIn = 0, FadeOut = 1},
	}
	
	Fade(tweenable, "in", 0.5)
	
	function WindowFunctions:Unload()
		Fade(tweenable, "out", 0.5)
		
		task.wait(0.5)
		
		gui:Destroy()
	end
	
	gui.Enabled = true
	
	discord.MouseButton1Click:Connect(function()
		setclipboard("https://discord.com/invite/jWXrcr74a9")
		WindowFunctions:Unload()
	end)

	return WindowFunctions
end

local main = Loader.New()

return Loader
