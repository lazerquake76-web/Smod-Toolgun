---These are the functions and variables that the toolgun script loads. This is a file for referece, NOT for including in your mod.

---Containers and functions that can be used by addons to add files to the spawn menu
sm.Smod = {}

---Containers that will be used to create item categories. Add your container here if you need to use the Toolgun's functions.
sm.Smod.itemContainers = {}

---This is used by the toolgun to call functions on other classes. Please do not insert manually.
sm.Smod.addonCallbacks = {}

---The addon's class on the server side. Required to call server functions.
sm.Smod.serverAddonStorage = {}

---Default circle icon for file containers
sm.Smod.defaultIcon = "$CONTENT_e7ca4a83-74b0-4a75-ab18-e62021fad28e/Gui/Icons/default.png"

---Storage for addons that add cusotm modes. Usage: table.insert( sm.Smod.modeAddons, { addon = self, key = addonKey, name = "BUTTON_NAME", player = sm.localPlayer.getPlayer() } )
sm.Smod.modeAddons = {}

---Main File Tree container. Only insert once per file.
sm.Smod.fileTreeContains = {}
---Mods File container. Only insert once per file.
sm.Smod.modFileContains = {}
---All File container. Only insert once per file.
sm.Smod.allFileContains = {}
---Parts File container. Only insert once per file.
sm.Smod.partsFileContains = {}
---Blocks File container. Only insert once per file.
sm.Smod.blocksFileContains = {}
---Item Widget container. Use the same key as the one you use for tableKey in sm.Smod.createFileContainer().
sm.Smod.toolgunWidgetContainers = {}

---Creates a item widget container from a table of valid items.
---@param itemTable table { {uuid = sm.uuid.new()}, {uuid = sm.uuid.new()}, ... }
---@param addonClass ToolClass The toolclass to call the callbacks from.
---@param hasTexture? boolean Optional. If the container has a image texture already. Defaults to flase.
---@param clickCallback? string Optional. The function name to call when an item is clicked, returns self, itemUuid. Defaults to "cl_basicItemClick"
---@param spawnCallback? string Optional. The function name to call when the player tries to spawn an item. Defaults to "cl_basicItemSpawn"
---@return table widgetContainer Contains items as itemSlot widgets.
function sm.Smod.createWidgetContainer( itemTable, addonClass, hasTexture, clickCallback, spawnCallback )

	local widgetContainer = {}
	local newUuid = tostring( sm.uuid.generateRandom() )
	
	if not clickCallback then
		clickCallback = "cl_basicItemClick"
	end
	if not spawnCallback then
		spawnCallback = "cl_basicItemSpawn"
	end

	sm.Smod.addonCallbacks[newUuid] = { addonClass = addonClass, clickCallback = clickCallback, spawnCallback = spawnCallback }

	for _, item in ipairs(itemTable) do
		if not item.imageTexture then
			local resource, group, name = sm.gui.getItemIconFromUuid(item.uuid)
			ItemImageWidget.ImageResource = resource
			ItemImageWidget.ImageGroup = group
			ItemImageWidget.ImageName = name
			ItemImageWidget.ImageTexture = nil
		else
			ItemImageWidget.ImageResource = nil
			ItemImageWidget.ImageGroup = nil
			ItemImageWidget.ImageName = nil
			ItemImageWidget.ImageTexture = item.imageTexture
		end
		if item.color then
			ItemImageWidget.Colour = item.color:getGuiColorStr()
		else
			ItemImageWidget.Colour = white:getGuiColorStr()
		end
		ItemRootWidget.onClick = "cl_onItemClick"
		ItemRootWidget.onClickData = {item = item, callbackUuid = newUuid, name = item.name}
		ItemImageWidget.onClick = "cl_onItemClick"
		ItemImageWidget.onClickData = {item = item, callbackUuid = newUuid, name = item.name}

		table.insert(widgetContainer, DeepCopy(ItemSlot))
	end
	return widgetContainer
end

---Creates a file container that can be added to the File Tree
---@param icon? string Optional. The path to the icon. Default to ed_icon_newfile.png
---@param iconColor? Color Optional. The color of the icon. Defaults to white
---@param name string The file's caption.
---@param tableKey any The key used to find the widgetContainer.
---@param offset integer The offset for the file container, use 23 to inset it by one, use 0 for none.
---@param hideable? boolean Optional. If the file's children should be hideable. Defaults to false
---@param contains? table Optional. The files this one should contain, { file1, file2 }. Defaults to {}
---@return Widget File The file that can be added to the File tree.
function sm.Smod.createFileContainer( icon, iconColor, name, tableKey, offset, hideable, contains )

	File.Childs = { FileContainer }
	File.height = FileDefaultHeight
	File.Name = name.."File"
	FileHideButton.Name = name.."Hide"

	FileContainer.x = offset

	FileName.Caption = name
	FileName.onClick = "cl_onFileClick"
	FileName.onClickData = { name = name, key = tableKey }

	if contains then
		for k, widget in ipairs(contains) do
			fileParents[widget.Name] = name
			table.insert ( File.Childs, widget )
			File.height = File.height + widget.height
		end
	end

	local height = File.height

	if hideable then
		FileHideButton.Enabled = true
		FileHideButton.Skin = "PrimaryButton"
		FileHideButton.onClick = "cl_onFileHide"
		FileHideButton.onClickData = { name = name, defaultHeight = height }
	else
		FileHideButton.Skin = "InventoryScrollBackground"
		FileHideButton.Enabled = false
	end

	if iconColor then
		FileIcon.Colour = iconColor:getGuiColorStr()
	else
		FileIcon.Colour = white:getGuiColorStr()
	end

	if icon then
		FileIcon.ImageTexture = icon
	else
		FileIcon.ImageTexture = "ed_icon_newfile.png"
	end

	return DeepCopy( File )

end