dofile "$GAME_DATA/Scripts/game/AnimationUtil.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"

GGSettings = class()

---Use either a random uuid or the uuid of the tool. Any key works, as long as it doesn't overlap with another addon.
local addonKey = "3cffa438-b51a-4655-bc4c-3225f1fae8e2" -- or sm.uuid.random() works too


local debuging = false

local maxRange = 2000
local minDist = 1.2

local wireSegments = 20
local wireGravity = sm.vec3.new( 0, 0, -0.25)
local wireSag = 1
local oob = sm.vec3.new(-10000,-10000,-10000)

-- point stuff
local spring = 40
local damping = 4
--rigid stuff
local rigidSpring = 150
local rigidDamping = 15
local angularDamping = 20

local forceDist = 3

local white = sm.color.new(255,255,255)
local red = sm.color.new(255,0,0)
local green = sm.color.new(0,255,0)
local blue = sm.color.new(0,0,255)
local purple = sm.color.new(255,0,255)
local yellow = sm.color.new(255,255,0)
local wireColor = sm.color.new("480ba7")


---This autotools server onCreate
function GGSettings.server_onCreate( self )
    self.creationList = {}
    -- add the addon to the server to be able to use network
    sm.Smod.serverAddonStorage[addonKey] = { addon = self, key = addonKey }

end

---This autotools client onCreate
function GGSettings.client_onCreate( self )
    self.grabPosEffect = sm.effect.createEffect( "ToteBot - Sparks" )
	self.hasObject = false
	self.rigid = false
	self.objectDistance = 0
	self.cameraCountdown = 10

	self.wireEffects = {}
	for k = 1, 100 do
		local effect = sm.effect.createEffect( "Physgun - Wire" )
		effect:setParameter('Color', wireColor)
		self.wireEffects[k] = { effect = effect, position = oob }
	end
    -- add the button to the list of mode addons
    -- addon is always = to self, key is whatever you use for your addonKey, and the name is the button's caption.
    table.insert( sm.Smod.modeAddons, { addon = self, key = addonKey, name = "Physgun" } )
end

function GGSettings.client_onFixedUpdate( self )
	if self.cameraCountdown > 0 and self.cameraCountdown ~= 10 then -- stupid rotation camera setting
		self.cameraCountdown = self.cameraCountdown - 1
	elseif self.cameraCountdown <= 0 then
		self.cameraCountdown = 10
		sm.localPlayer.setLockedControls( false )
	end
end


---Use network calls like this 
---network:sendToServer( "sv_sendToAddon", {addon = addonKey, callback = "sv_myServerFunction", args = { any, thing, you, want } } )
---then the function will be function MyClass.sv_myServerFunction( self, args )...

---All _Toolgun_ functions are called even if the current mode isn't yours


local function clearObject( self )
	self.hasObject = false
	self.object = nil
	self.objectDistance = 0
	self.grabPosEffect:stopImmediate()
	for _, v in ipairs(self.wireEffects) do
		if v.effect:isPlaying() then
			v.effect:stopImmediate()
		end
	end
end

---When the tool is updated.
function GGSettings.client_Toolgun_onUpdate( self, network, dt )
    if self.tool:isLocal() and self.equipped then
        ---Wire Effect logic, remove if unwanted
		if self.hasObject then
				local currentCOM = self.object:getCenterOfMassPosition()
				local currentRot = self.object.worldRotation

				local grabOffsetWorld = currentRot * self.offsetLocal
				local grabPointWorld = currentCOM + grabOffsetWorld

				local firePos = sm.localPlayer.getFpBonePos( "pipe" )

				firePos = firePos + sm.camera.getRotation() * sm.vec3.new(0.25,-0.03,-0.035) -- move the effectPos to the holo-pipe on the toolgun

				local midPoint = ( firePos + grabPointWorld ) * 0.5
				local controlModifier = self.wireTarget or grabPointWorld
				local controlPoint = sm.vec3.lerp( midPoint, controlModifier, 0.8 ) + ( wireGravity * wireSag )

				local segments = math.min( math.max( math.floor( sm.vec3.getDistance(firePos, grabPointWorld) * 5 ), wireSegments ), 100 ) -- makes sure the value is inbetween 20 and 100
				for i = 1, segments do
					local t = i / segments

					local position = sm.vec3.bezier2( firePos, controlPoint, grabPointWorld, t )-- + ( sm.vec3.new( math.random(-100, 100), math.random(-100, 100), math.random(-100, 100) ) * 0.0001 )
					local particle = self.wireEffects[i]
					if particle then
						self.wireEffects[i].position = position
					end
				end

				for _, particle in ipairs(self.wireEffects) do
					local effect = particle.effect
					local postition = particle.position

					if not effect:isPlaying() then
						effect:start()
					end
					effect:setPosition(oob)
					if postition then
						effect:setPosition(postition)
					end
					particle.position = nil
				end
		end
		---Wire Effect logic, remove if unwanted
    end
end

---When the tool is equipped.
function GGSettings.client_Toolgun_onEquip( self, network, animate )
    clearObject( self )
    if self.tool:isLocal() then

		self.sensitivity = sm.localPlayer.getAimSensitivity() * 2

		self.binds = { -- keybindings

		Reload = sm.gui.getKeyBinding("Reload", true),
		Primary = sm.gui.getKeyBinding("Create", true),
		Secondary = sm.gui.getKeyBinding("Attack", true),
		ToggleFWD = sm.gui.getKeyBinding("NextCreateRotation", true),
		ToggleBWD = sm.gui.getKeyBinding("PreviousCreateRotation", true),
		Rigid = sm.gui.getKeyBinding("Attack", true) .. " + " .. sm.gui.getKeyBinding("Sprint", true)
		}
	end
end

---When the tool is unequipped.
function GGSettings.client_Toolgun_onUnequip( self, network, animate )
	self.equipped = false
	clearObject( self )

	if self.isRotating then
		sm.camera.setCameraState(1) -- sets camera to defualt
		sm.localPlayer.setLockedControls(true)
		sm.localPlayer.setDirection( self.savedPlayerDirection )
		self.cameraCountdown = 1
		self.isRotating = false
	end
end

---Is called every client fixed update.
function GGSettings.client_Toolgun_onFixedUpdate( self, network, dt )

	if self.hasObject then
		if sm.exists( self.object ) then -- checks if the body still exists
			local grabPos
			if not self.tool:isInFirstPersonView() then -- FP/TP target position sets
				local cameraDirection = sm.camera.getDirection()
				grabPos = sm.camera.getPosition() + cameraDirection * cameraDirection:dot( GetOwnerPosition( self.tool ) - sm.camera.getPosition() )
				grabPos = grabPos + cameraDirection * self.objectDistance
			else
				grabPos = sm.camera.getPosition() + sm.camera.getDirection() * self.objectDistance
			end

			if not self.rigid then
				self.targetPos = grabPos
				self.wireTarget = grabPos

				local params = {object = self.object, targetPos = self.targetPos, offsetLocal = self.offsetLocal, objectMass = self.objectMass, dt = dt}
				if not sm.isHost then
                    network:sendToServer( "sv_sendToAddon", { addon = addonKey, callback = "server_applyImpulse", args = params } )
				end
				self.server_applyImpulse( self, params )
			else
				self.targetPos = grabPos + ( self.targetRotation * self.localOffset )
				self.wireTarget = grabPos

				local params = {object = self.object, targetPos = self.targetPos, targetRot = self.targetRotation, objectMass = self.objectMass, cornerOffsets = self.cornerOffsets, dt = dt}
				if not sm.isHost then
                    network:sendToServer( "sv_sendToAddon", { addon = addonKey, callback = "server_applyImpulseRigid", args = params } )
				end
				self.server_applyImpulseRigid( self, params )
			end

			local currentCOM = self.object:getCenterOfMassPosition()
			local currentRot = self.object.worldRotation

			local grabOffsetWorld = currentRot * self.offsetLocal
			local grabPointWorld = currentCOM + grabOffsetWorld

			self.grabPosEffect:setPosition( grabPointWorld )
			self.grabPosEffect:setRotation( currentRot )

			if self.isRotating then -- rotate with mouse

				local x, y = sm.localPlayer.getMouseDelta()

				local deltaRot = sm.quat.angleAxis( -y * self.sensitivity, sm.vec3.new(1,0,0) ) * sm.quat.angleAxis( -x * self.sensitivity, sm.vec3.new(0,0,1) )

				local cameraRotation = sm.camera.getRotation()
				self.targetRotation = ( cameraRotation * deltaRot * cameraRotation:inverse() ) * self.targetRotation
				self.targetRotation = self.targetRotation:normalize()

			end

		else
			clearObject( self )
			if self.isRotating then
				sm.camera.setCameraState(1) -- sets camera to defualt
				sm.localPlayer.setLockedControls(true)
				sm.localPlayer.setDirection( self.savedPlayerDirection )
				self.cameraCountdown = 1
				self.isRotating = false
			end
		end
	end

end

---When the tool is toggled. isActive is true when the current mode is yours.
function GGSettings.client_Toolgun_onToggle( self, network, backwards, isActive )

	if self.hasObject then
		if not backwards then
			self.objectDistance = self.objectDistance + 0.25
		else
			self.objectDistance = self.objectDistance - 0.25
		end
		if self.objectDistance < minDist then
			self.objectDistance = minDist
		end
	end

end

---When the tool is toggled. primaryState and secondaryState are = to nil if the current mode is not yours.
function GGSettings.client_Toolgun_onEquippedUpdate( self, network, primaryState, secondaryState, forceBuildActive, raycastResult )
    if self.tool:isLocal() and primaryState then

		if not self.hasObject and not forceBuildActive then
			if not self.rigid then
				sm.gui.setInteractionText( self.binds.Primary, "Grab Body | ", self.binds.Rigid, "Swap to rigid", "" )
			else
				sm.gui.setInteractionText( self.binds.Primary, "Grab Body | ", self.binds.Rigid, "Swap to point", "" )
			end
		elseif not forceBuildActive then
			if not self.rigid then
				sm.gui.setInteractionText( self.binds.Primary, "Release Body | ", self.binds.Rigid, "Swap to rigid", "" )
			else
				sm.gui.setInteractionText( self.binds.Primary, "Release Body | ", self.binds.Rigid, "Swap to point", "" )
			end
		end

        self.equipped = true
        
        if primaryState == sm.tool.interactState.start and not forceBuildActive and not self.hasObject then
			local firstPerson = self.tool:isInFirstPersonView()
			local cameraPos = sm.camera.getPosition()
			local cameraDir = sm.camera.getDirection()

            local hit, result
			if not firstPerson then
				local raycastPos = sm.camera.getPosition() + sm.camera.getDirection() * sm.camera.getDirection():dot( GetOwnerPosition( self.tool ) - sm.camera.getPosition() )
				hit, result = sm.localPlayer.getRaycast( maxRange, raycastPos, sm.camera.getDirection() )
			else 
				hit, result = sm.physics.raycast( cameraPos, cameraPos + cameraDir * maxRange,self.tool:getOwner():getCharacter() )
			end

			if hit and (result.type == "body" or result.type == "joint") then

				if result.type == "body" then
					self.object = result:getBody()
				elseif result.type == "joint" then
					local joint = result:getJoint()
					if sm.exists( joint:getShapeB() ) then
						self.object = joint:getShapeB():getBody()
					else
						self.object = joint:getShapeA():getBody()
					end
				end

				if self.object:isDynamic() then

					--calculate distance
					local distance = sm.vec3.getDistance( result.originWorld, result.pointWorld )
					--set up object
					self.hasObject = true

					-- setup for rigid mode
					local minWorld, maxWorld = self.object:getWorldAabb()
					local centerWorld = (minWorld + maxWorld) * 0.5
					self.localOffset = self.object.worldRotation:inverse() * ( centerWorld - result.pointWorld )
					self.targetRotation = self.object.worldRotation

					local minLocal, maxLocal = self.object:getLocalAabb()

					local halfExtents = (minLocal - maxLocal) * 0.5 * 0.25

					self.cornerOffsets = {}
					for i = 0, 7 do
						local offset = sm.vec3.new(
							(i % 2 == 0) and -halfExtents.x or halfExtents.x,
							(math.floor(i/2) % 2 == 0) and -halfExtents.y or halfExtents.y,
							(math.floor(i/4) % 2 == 0) and -halfExtents.z or halfExtents.z
						)

						self.cornerOffsets[#self.cornerOffsets+1] = offset
					end

					-- effects
					self.grabPosEffect:setPosition( result.pointWorld )
					self.grabPosEffect:setRotation( sm.quat.inverse(sm.camera.getRotation()) )
					self.grabPosEffect:start()

					self.objectDistance = distance

					local pointWorld = result.pointWorld

					local offsetWorld = pointWorld - self.object:getCenterOfMassPosition()
					self.offsetLocal = self.object.worldRotation:inverse() * offsetWorld
					
					self.objectMass = self.object:getMass()
				end
			end

		elseif secondaryState == sm.tool.interactState.start and not forceBuildActive then

			local backwards = sm.localPlayer.getWantsSprint()

            if not self.rigid and backwards then
                sm.gui.displayAlertText("Rigid", 3, true)
                self.rigid = true
                if sm.exists( self.object ) then
                    self.targetRotation = self.object.worldRotation
                end
            elseif backwards then
                sm.gui.displayAlertText("Point", 3, true)
                self.rigid = false

                if self.isRotating then
                    sm.camera.setCameraState(1) -- sets camera to defualt
                    sm.localPlayer.setLockedControls(true)
                    sm.localPlayer.setDirection( self.savedPlayerDirection )
                    self.cameraCountdown = 1
                    self.isRotating = false
                end
            end

            if self.hasObject and not backwards then
                if self.rigid then
                    if self.isRotating then
                        sm.camera.setCameraState(1) -- sets camera to defualt
                        sm.localPlayer.setLockedControls(true)
                        sm.localPlayer.setDirection( self.savedPlayerDirection )
                        self.cameraCountdown = 1
                        self.isRotating = false
                    else 
                        local FOV = sm.camera.getFov()
                        self.cameraDisplacement = sm.camera.getPosition() - sm.localPlayer.getPlayer():getCharacter():getWorldPosition()
                        self.savedCameraDirection = sm.camera.getDirection()
                        self.savedPlayerDirection = sm.localPlayer.getDirection()
                        sm.camera.setCameraState(2) -- sets camera to cutsceneFP
                        sm.camera.setPosition( sm.localPlayer.getPlayer():getCharacter():getWorldPosition() + self.cameraDisplacement )
                        sm.camera.setDirection( self.savedCameraDirection )
                        sm.camera.setFov( FOV )
                        self.isRotating = true
                    end
                end
            end
			
		elseif primaryState == sm.tool.interactState.start and self.hasObject and not forceBuildActive then
			clearObject( self )

			if self.isRotating then
				sm.camera.setCameraState(1) -- sets camera to defualt
				sm.localPlayer.setLockedControls(true)
				sm.localPlayer.setDirection( self.savedPlayerDirection )
				self.cameraCountdown = 1
				self.isRotating = false
			end
		end
       
    else
        self.equipped = false
		if self.hasObject then
			clearObject(self)
		end
    end
end

---is called on client tool destroy.
function GGSettings.client_Toolgun_onDestroy( self, network )
	clearObject( self )

	if self.isRotating then
		sm.camera.setCameraState(1) -- sets camera to defualt
		sm.localPlayer.setLockedControls(true)
		sm.localPlayer.setDirection( self.savedPlayerDirection )
		self.cameraCountdown = 1
		self.isRotating = false
	end
end

---is called when the tool is equipped while seated.
function GGSettings.client_Toolgun_equipWhileSeated( self, network )
    
end

---is called every server fixed update.
function GGSettings.server_Toolgun_onFixedUpdate( self, network, dt )
end

function GGSettings.server_applyImpulse( self, params )

	local currentCOM = params.object:getCenterOfMassPosition()
	local currentRot = params.object.worldRotation

	local grabOffsetWorld = currentRot * params.offsetLocal
	local grabPointWorld = currentCOM + grabOffsetWorld
	local displacement = params.targetPos - grabPointWorld
	local velocity = params.object:getVelocity()
	local angularVelocity = params.object:getAngularVelocity()
	local velocityPoint = velocity + angularVelocity:cross( grabOffsetWorld )

	local force = displacement * spring - velocityPoint * damping

	local impulse = force * (params.objectMass) * params.dt
	sm.physics.applyImpulse( params.object, impulse, true, currentRot * params.offsetLocal )

end

function GGSettings.server_applyImpulseRigid( self, params ) -- impulse server math for clients (only sends params for stuff that has client only functions)

	local targetPosition = params.targetPos
	
	local minWorld, maxWorld = params.object:getWorldAabb()
	local centerWorld = (minWorld + maxWorld) * 0.5
	local currentRot = params.object.worldRotation

	local mass = params.object:getMass()

	for _, corner in ipairs(params.cornerOffsets) do
		local worldOffset = currentRot * corner
		local targetCorner = targetPosition + params.targetRot * corner
		local currentCorner = centerWorld + worldOffset
		if debuging then -- debug arrow
			sm.debugDraw.flashArrow(currentCorner, targetCorner, blue, 0.01)
		end
		local displacement = targetCorner - currentCorner

		local linVel = params.object:getVelocity()
		local angVel = params.object:getAngularVelocity()
		local pointVel = linVel + angVel:cross(worldOffset)

		local force = displacement * rigidSpring - pointVel * rigidDamping
		local impulse = force * (mass/angularDamping) * params.dt

		sm.physics.applyImpulse(params.object, impulse, true, worldOffset)
	end

	if debuging then -- debug visuals
		local min, max = params.object:getLocalAabb()

		local halfExtents = (min - max) * 0.5 * 0.25

		local minOffset = -halfExtents
		local maxOffset = halfExtents

		--target bounding box
		sm.debugDraw.flashSphere(targetPosition, 0.125, white, 0.01)
		sm.debugDraw.flashBox(minOffset, maxOffset, targetPosition, params.targetRot, white, 0.01)
		--current bounding box
		sm.debugDraw.flashSphere(centerWorld, 0.125, green, 0.01)
		sm.debugDraw.flashBox(minOffset, maxOffset, centerWorld, currentRot, green, 0.01)
	end
end

---is called when the tool is destroyed on the server.
function GGSettings.server_Toolgun_onDestroy( self, network )
end

function GGSettings.server_onFixedUpdate( self, dt ) -- if you need to use dt it's best to use your own update function instead of the toolguns.
end