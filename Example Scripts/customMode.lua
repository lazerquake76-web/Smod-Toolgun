CustomModeAddon = class()

---Use either a random uuid or the uuid of the tool. Any key works, as long as it doesn't overlap with another addon.
local addonKey = "e8219b3a-4841-44ef-adf6-50ab252f1af8" -- or sm.uuid.random() works too

---This autotools server onCreate
function CustomModeAddon.server_onCreate( self )
    self.creationList = {}
    -- add the addon to the server to be able to use network
    sm.Smod.serverAddonStorage[addonKey] = { addon = self, key = addonKey }

end

---This autotools client onCreate
function CustomModeAddon.client_onCreate( self )
    -- add the button to the list of mode addons
    -- addon is always = to self, key is whatever you use for your addonKey, and the name is the button's caption.
    table.insert( sm.Smod.modeAddons, { addon = self, key = addonKey, name = "Antigrav" } )
end


---Use network calls like this 
---network:sendToServer( "sv_sendToAddon", {addon = addonKey, callback = "sv_myServerFunction", args = { any, thing, you, want } } )
---then the function will be function MyClass.sv_myServerFunction( self, args )...

---All _Toolgun_ functions are called even if the current mode isn't yours


---When the tool is updated.
function CustomModeAddon.client_Toolgun_onUpdate( self, network, dt )
end

---When the tool is equipped.
function CustomModeAddon.client_Toolgun_onEquip( self, network, animate )
end

---When the tool is unequipped.
function CustomModeAddon.client_Toolgun_onUnequip( self, network, animate )
end

---Is called every client fixed update.
function CustomModeAddon.client_Toolgun_onFixedUpdate( self, network, dt )
end

---When the tool is toggled. isActive is true when the current mode is yours.
function CustomModeAddon.client_Toolgun_onToggle( self, network, backwards, isActive )
end

---When the tool is toggled. primaryState and secondaryState are = to nil if the current mode is not yours.
function CustomModeAddon.client_Toolgun_onEquippedUpdate( self, network, primaryState, secondaryState, forcebuildforceBuildActive, raycastResult )
    if self.tool:isLocal() and primaryState then
        local hit, result = raycastResult.hit, raycastResult.result

        if hit and result.type == "body" then
            local body = result:getBody()

            sm.visualization.setCreationBodies(body:getCreationBodies())
            sm.visualization.setCreationVisible(true)
            sm.visualization.setCreationFreePlacement( false )
            sm.visualization.setCreationValid( true, true )

            if primaryState == sm.tool.interactState.start then
                if result:getBody():isDynamic() then
                    network:sendToServer( "sv_sendToAddon", {addon = addonKey, callback = "sv_addToList", args = { body = result:getBody() } } )
                end
            end
        end
        if secondaryState == sm.tool.interactState.start then
            network:sendToServer( "sv_sendToAddon", {addon = addonKey, callback = "sv_clearList", args = {} } )
        end
    end
end

---is called on client tool destroy.
function CustomModeAddon.client_Toolgun_onDestroy( self, network )
end

---is called when the tool is equipped while seated.
function CustomModeAddon.client_Toolgun_equipWhileSeated( self, network )
    
end

---is called every server fixed update.
function CustomModeAddon.server_Toolgun_onFixedUpdate( self, network, dt )
end

---is called when the tool is destroyed on the server.
function CustomModeAddon.server_Toolgun_onDestroy( self, network )
    self:sv_clearList()
end

function CustomModeAddon.server_onFixedUpdate( self, dt ) -- if you need to use dt it's best to use your own update function instead of the toolguns.
    for k, v in pairs(self.creationList) do
        if sm.exists( v ) then
            for _, body in pairs( v:getCreationBodies() ) do
                local force = sm.vec3.new( 0, 0, 1.045 ) * body.mass
                local impulse = force * sm.physics.getGravity()
                sm.physics.applyImpulse( body, impulse * dt, true )
            end
        else
            self.creationList[k] = nil
        end
    end
end

function CustomModeAddon.sv_addToList( self, args )
    for k, v in pairs( self.creationList ) do
        if v == args.body then
            self.creationList[k] = nil
            return
        end
    end
    table.insert( self.creationList, args.body )
end

function CustomModeAddon.sv_clearList( self, args )
    self.creationList = {}
end