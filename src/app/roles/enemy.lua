--
-- Author: yjun
-- Date: 2014-09-24 14:25:33
--
local Progress = import("..ui.Progress")

local Enemy = class("Enemy", function()
	return ccs.Armature:create("tauren")
	end)

function Enemy:ctor()
	self.progress = Progress.new("ui/hp_black_small.png", "ui/hp_red_small.png")
	local size = self:getContentSize()
	self.progress:setPosition(size.width/7, size.height - 120)
	self:addChild(self.progress)

	self.attack = 50
	self.Hp = 500
	self.maxHp = 500
	self:setScaleX(0.8)
	self:setScaleY(0.8)
    self:setLocalZOrder(10)
	self:addStateMachine()
	self:setPosition(cc.p(display.right-self:getBoundingBox().width, display.cy))

	local function animationEvent(armatureBack,movementType,movementID)
		if movementType == ccs.MovementEventType.complete and (movementID == "attack" or movementID == "smitten") then
			self:doEvent("stop")
		end
	end

	self:getAnimation():setMovementEventCallFunc(animationEvent)
end

function Enemy:idle()
	transition.stopTarget(self)
	self:getAnimation():playWithIndex(0)
	self:getAnimation():setSpeedScale(0.8)
end

function Enemy:walkTo(pos, callback)

	local function moveStop()
		self:doEvent("stop")
		if callback then
			callback()
		end
	end

	if self.moveAction then
		self:stopAction(self.moveAction)
		self.moveAction = nil
	end

	local currentPos = cc.p(self:getPosition())
	local destPos = cc.p(pos.x, pos.y)
	if pos.x < currentPos.x then
		self:setScaleX(-0.8)
	else
		self:setScaleX(0.8)
	end

	local posDiff = cc.pGetDistance(currentPos, destPos)
	self.moveAction = transition.sequence(
		{cc.MoveTo:create(5 * posDiff / display.width, cc.p(pos.x,pos.y)), 
		cc.CallFunc:create(moveStop)})

	if self:getAnimation():getCurrentMovementID() ~= "run" then
		self:getAnimation():playWithIndex(1)
	end

	self:runAction(self.moveAction)
	return true
end

function Enemy:attackEnemy()
	transition.stopTarget(self)
	self:getAnimation():playWithIndex(2)

    -- local animation = display.getAnimationCache("player1-attack")
    -- transition.playAnimationOnce(self, animation, false, attackEnd)
end

function Enemy:hit()	
	transition.stopTarget(self)
	self:getAnimation():playWithIndex(3)
	self.Hp = self.Hp - self.attack
	if self.Hp < 0 then
		self.Hp = 0
	end
	self.progress:setProgress(self.Hp/self.maxHp*100)
end

function Enemy:updateHpBar()
	self.progress:setProgress(self.Hp/self.maxHp)
end

function Enemy:dead()
	local world = PhysicsManager:getInstance()
	world:removeBody(self.body, true)
	self.body = nil
	transition.playAnimationOnce(self, display.getAnimationCache("player1-dead"))
end

function Enemy:doEvent(event, ...)
	self.fsm_:doEvent(event, ...)
end

function Enemy:getState()
	return self.fsm_:getState()
end

function Enemy:addStateMachine()
	self.fsm_ = {}
	cc.GameObject.extend(self.fsm_)
	:addComponent("components.behavior.StateMachine")
	:exportMethods()

	self.fsm_:setupState({
		initial = "idle",

		events = {
            -- t1:clickScreen; t2:clickEnemy; t3:beKilled; t4:stop
            {name = "clickScreen", from = {"idle", "attack"},   to = "walk" },
            {name = "clickEnemy",  from = {"idle", "walk"},  to = "attack"},
            {name = "beKilled", from = {"idle", "walk", "attack", "hit"},  to = "dead"},
            {name = "beHit", from = {"idle", "walk", "attack"}, to = "hit"},
            {name = "stop", from = {"walk", "attack", "hit"}, to = "idle"},
            },

            callbacks = {
            onidle = function (event) self:idle() end,
            onwalk = function (event) self:walkTo(event.args[1], event.args[2]) end,
            onattack = function (event) self:attackEnemy() end,
            onhit = function (event) self:hit() end,
            ondead = function (event) self:dead() end
            },
            })

end

return Enemy

