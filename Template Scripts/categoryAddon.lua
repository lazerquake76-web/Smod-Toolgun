CategoryAddon = class()

local addonUuid = sm.uuid.generateRandom() -- your autotools uuid or sm.uuid.generateRandom()

-- the function to set up the addon
local function runAddon( self )
    local itemTable = sm.localPlayer.getInventory() -- you can use items in a container to create your item table.
    itemTable = { { uuid = sm.uuid.new("8984bdbf-521e-4eed-b3c4-2b5e287eb879") } } -- the table of items that the toolgun uses to create the item list. It HAS to be in container format.

    -- let the toolgun create a widget container so it can call our functions later. Use a unique uuid as the key so there's no conflict with other addons
    sm.Smod.toolgunWidgetContainers[addonUuid] = sm.Smod.createWidgetContainer( itemTable, self )

    sm.log.info( "loaded Smod Toolgun addon: CategoryAddon" ) -- log when the addon was loaded, helpful for debugging
    -- insert a file into the file tree with the same key as the widget container.
    table.insert( sm.Smod.modFileContains, sm.Smod.createFileContainer( nil, nil, "Template", addonUuid, 23, false, nil ) )
end

function CategoryAddon.server_onCreate( self )
    -- you need to add the addon here on the server so the toolgun can call your functions from the server
    sm.Smod.serverAddonStorage[addonUuid] = { addon = self }
end

function CategoryAddon.client_onCreate( self )
    -- run the addon set up.
    runAddon( self )
end

function CategoryAddon.cl_basicItemClick( self, uuid )
    -- pretty much useless for most addons, it's only here incase you need something special
end

function CategoryAddon.cl_basicItemSpawn( self, uuid, location, rotation, network )
    -- This is where adding the addon to the server becomes useful, the key is the same here so it knows what addon your talking about.
    network:sendToServer( "sv_sendToAddon", {addon = addonUuid, callback = "sv_spawnUnit", args = { uuid = uuid, position = location, rotation = rotation } } )
end

function CategoryAddon.sv_spawnUnit( self, args )
    -- spawning the item, in the case of this template it is a unit.
    sm.unit.createUnit( args.uuid, args.position )
end