local Controller = {}

function Controller:new(battle)
    self.battle = battle
    self.current_state = nil
    self.Commands = {}
    self:resetCommands()
end

function Controller:getState()
    return self.current_state
end

function Controller:setState(state)
    self.current_state = state
end

function Controller:drawBackground()
    self.battle.Bg:draw()
end

function Controller:drawForeground()

    for i = 1, #self.battle.party_members do
        self.battle.party_members[i]:draw()
    end

    for i = 1,#self.battle.enemies do
        if self.battle.enemies[i] then
            self.battle.enemies[i]:draw()
        end
    end

    self.battle.Enemysub:draw(self.battle.current_state, self.battle.enemies)
    for __, sub in pairs(self.battle.Enemysubsubs) do
        sub:draw(self.battle.current_state, self.battle.enemies)
    end
    self.battle.PartyMemberSub:draw(self.battle.current_state, self.battle.enemies)
    self.battle.ItemSub:draw(self.battle.current_state, self.battle.enemies)

    self.battle.Box:draw()

end

function Controller:update(dt)
        for i = 1, #self.battle.enemies do
        if self.battle.enemies[i] then
            self.battle.enemies[i]:update(dt, self.current_state, self.battle.enemies)
        end
    end

    for i = 1, #self.battle.party_members do
        self.battle.party_members[i]:update(dt)
    end

    self.battle.Bg:update(dt)

    Sole:update(dt, self.battle.current_state)

    self.battle.Box:update(dt)

    --print(love.mouse.getX().." , "..love.mouse.getY()) --I use this when checking positions in the UI.

    if not self.battle.MUS_Battlemusic:isPlaying() then
        love.audio.play(self.battle.MUS_Battlemusic)
    end
end

function Controller:resetCommands()
    for i = 1, #self.battle.enemies do
        self.Commands[i] = {}
    end
end

function Controller:setCommand(partymemberindex, n, misc)--TODO Rename to Controller:setCommand()
    self.Commands[partymemberindex][n] = misc
end

function Controller:runCommand(partymemberindex, n)
    return self.Commands[partymemberindex][n]()
end

function Controller:getCommand(partymemberindex, n)
    return self.Commands[partymemberindex][n]
end

return Controller