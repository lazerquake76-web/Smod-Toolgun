UnitAddon = class()

local addonUuid = "aec00861-a341-4bc6-bc14-664dda5def27"

local Path = "$SURVIVAL_DATA/Gui/NodeIcons/"

-- the function to set up the addon
local function runAddon( self )
    -- table of unit uuids formatted in the same way a container is. Also contains custom icons.
    local unitTable = {
        { uuid = sm.uuid.new("8984bdbf-521e-4eed-b3c4-2b5e287eb879"), imageTexture = Path.."TotebotGreenIcon.png", name = "Green Totebot" },
        { uuid = sm.uuid.new("9360d346-3ff2-4925-a068-660cf5dd5267"), imageTexture = Path.."TotebotRedIcon.png", name = "Red Totebot" },
        { uuid = sm.uuid.new("2dea48a4-6a79-11ed-a1eb-0242ac120002"), imageTexture = Path.."TotebotYellowIcon.png", name = "Yellow Totebot" },
        { uuid = sm.uuid.new("58992f50-ca36-44e1-8c47-4996d89d6a9a"), imageTexture = Path.."TotebotBlueIcon.png", name = "Blue Totebot" },
        { uuid = sm.uuid.new("c8bfb8f3-7efc-49ac-875a-eb85ac0614db"), imageTexture = Path.."HaybotIcon.png", name = "Haybot" },
        { uuid = sm.uuid.new("9f4fde94-312f-4417-b13b-84029c5d6b52"), imageTexture = Path.."FarmbotIcon.png", name = "Farmbot" },
        { uuid = sm.uuid.new("04761b4a-a83e-4736-b565-120bc776edb2"), imageTexture = Path.."TapebotIcon.png", name = "Tapebot" },
        { uuid = sm.uuid.new("c3d31c47-0c9b-4b07-9bd4-8f022dc4333e"), imageTexture = Path.."TapebotRedIcon.png", name = "Red Tapebot" },
        { uuid = sm.uuid.new("92da8324-3cfe-4529-ac1c-c71facda50a3"), imageTexture = sm.Smod.defaultIcon, name = "Minerbot", color = sm.color.new( "14deb9ff" ) },
        { uuid = sm.uuid.new("b837888a-0480-4a34-bc34-d72261a14385"), imageTexture = sm.Smod.defaultIcon, name = "Cablebot", color = sm.color.new( "22700cff" ) },
        { uuid = sm.uuid.new("c68914f8-d769-4638-9071-f7dbd1d97351"), imageTexture = Path.."TapebotIcon.png", name = "Green Tapebot", color = sm.color.new( "27c451ff" ) }, -- green
        { uuid = sm.uuid.new("97efd943-d176-479a-a6f4-46373327ddcd"), imageTexture = Path.."TapebotIcon.png", name = "Yellow Tapebot", color = sm.color.new( "c9c71eff" ) }, -- yellow
        { uuid = sm.uuid.new("264a563a-e304-430f-a462-9963c77624e9"), imageTexture = Path.."WocIcon.png", name = "Woc" },
        { uuid = sm.uuid.new("48c03f69-3ec8-454c-8d1a-fa09083363b1"), imageTexture = Path.."GlowgorpIcon.png", name = "Glowbug" }
    }

    -- let the toolgun create a widget container so it can call our functions later. Use the tools uuid as the key so there's no conflict with other addons
    sm.Smod.toolgunWidgetContainers[addonUuid] = sm.Smod.createWidgetContainer( unitTable, self )

    sm.log.info( "loaded Smod Toolgun addon: UnitAddon" )
    -- insert a file into the file tree with the same key as the widget container.
    table.insert( sm.Smod.modFileContains, sm.Smod.createFileContainer( nil, nil, "Units", addonUuid, 23, false, nil ) )
end

function UnitAddon.server_onCreate( self )
    -- you need to add the addon here on the server so the toolgun can call your functions from the server
    sm.Smod.serverAddonStorage[addonUuid] = { addon = self }
end

function UnitAddon.client_onCreate( self )
    -- run the addon set up.
    runAddon( self )
end

function UnitAddon.cl_basicItemClick( self, uuid )
    -- pretty much useless for most addons, it's only here incase you need something special
end

function UnitAddon.cl_basicItemSpawn( self, uuid, location, rotation, network )
    -- This is where adding the addon to the server becomes useful, the key is the same here so it knows what addon your talking about.
    network:sendToServer( "sv_sendToAddon", {addon = addonUuid, callback = "sv_spawnUnit", args = { uuid = uuid, position = location, rotation = rotation } } )
end

function UnitAddon.sv_spawnUnit( self, args )
    -- spawning the unit
    sm.unit.createUnit( args.uuid, args.position )
end