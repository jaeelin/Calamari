local AssetLoader = {}

AssetLoader.Version = "1.0.0"

AssetLoader.BaseFolder = "Calamari/assets/"
AssetLoader.GitHubBase = "https://raw.githubusercontent.com/jaeelin/Calamari/refs/heads/main/Assets/"

local function GetAsset(Path: string, Url: string)
	if not isfile(Path) then
		writefile(Path, game:HttpGet(Url))
	end

	return getcustomasset and getcustomasset(Path) or Path
end

function AssetLoader:Get(Folder: string, FileName: string)
	local path = string.format("%s%s/%s", self.BaseFolder, Folder, FileName)
	local url = string.format("%s%s/%s", self.GitHubBase, Folder, FileName)

	return GetAsset(path, url)
end

return AssetLoader
