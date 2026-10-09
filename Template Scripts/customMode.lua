CustomModeAddon = class()

---Use either a random uuid or the uuid of the tool. Any key works, as long as it doesn't overlap with another addon.
local addonKey = "" -- or sm.uuid.generateRandom() works too

---This autotools server onCreate. self works with server_Toolgun_ functions.
function CustomModeAddon.server_onCreate( self )
end

---This autotools client onCreate. self works with client_Toolgun_ functions.
function CustomModeAddon.client_onCreate( self )
end


---Use network calls like this 
---network:sendToServer( "sv_sendToAddon", {addon = addonKey, callback = "sv_myServerFunction", args = { any, thing, you, want } } )
---then the function will be function MyClass.sv_myServerFunction( self, args )
---args is the same table as args in the network call.

---All _Toolgun_ functions are called even if the current mode isn't yours.


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
end

---is called on client tool destroy.
function CustomModeAddon.client_Toolgun_onDestroy( self, network )
end

---is called when the tool is equipped while seated.
function CustomModeAddon.client_Toolgun_equipWhileSeated( self, network )
    
end


-- server


---is called every server fixed update.
function CustomModeAddon.server_Toolgun_onFixedUpdate( self, network, dt )
end

---is called when the tool is destroyed on the server.
function CustomModeAddon.server_Toolgun_onDestroy( self, network )
    self:sv_clearList()
end