Soul = Object:extend()

function Soul:new()
    self.image = love.graphics.newImage("sprites/soul.png")
    self.x = 0
    self.y = 0
    self.size = 1.5

    self.currentmenuposition = 1

    self.top = 200
    self.bottom = 483
    self.left = 500
    self.right = 783
end

function Soul:updatePos(delta)
    love.audio.play(SND_MENUMOVE)
    local specialcase = false
    if delta == 1 then
        if self.currentmenuposition + delta > #self.positions then
            self.currentmenuposition = 1
            specialcase = true
        end
    elseif delta == -1 then
        if self.currentmenuposition + delta < 1 then
            self.currentmenuposition = #self.positions
            specialcase = true
        end
    end
    if not specialcase then
        self.currentmenuposition = self.currentmenuposition + delta
    end
end

function Soul:updateLimits(Box)
    self.topLimit = Box.top
    self.bottomLimit = Box.bottom - (18 * self.size)
    self.leftLimit = Box.left
    self.rightLimit = Box.right - (18 * self.size)
end

function Soul:centerInBox()
    self.x = (self.rightLimit - self.leftLimit)/2 + self.leftLimit
    self.y = (self.bottomLimit - self.topLimit)/2 + self.topLimit
end

function Soul:updatePosArray(posarray)
        self.positions = posarray
        self.currentmenuposition = 1
end

function Soul:move(dt)

    if love.keyboard.isDown("up") then
        self.y = self.y - 360*dt
    elseif love.keyboard.isDown("down") then
        self.y = self.y + 360*dt
    end

    if love.keyboard.isDown("right") then
        self.x = self.x + 360*dt
    elseif love.keyboard.isDown("left") then
        self.x = self.x - 360*dt
    end

    if self.x > self.rightLimit then
        self.x = self.rightLimit
    elseif self.x < self.leftLimit then
        self.x = self.leftLimit
    end

    if self.y > self.bottomLimit then
        self.y = self.bottomLimit
    elseif self.y < self.topLimit then
        self.y = self.topLimit
    end
end

function Soul:update(dt, localcurrentstate)

    if localcurrentstate == "BULLETS" then

        self:move(dt)

    end

    --TODO Collision checks with bullets
    
end

function Soul:draw(localcurrentstate)
    if self.positions and (localcurrentstate == "ATTACKUI" or localcurrentstate == "ACTUI" or localcurrentstate == "ACTSUBSUB" or localcurrentstate == "SPAREUI" or localcurrentstate == "ITEMUI" or localcurrentstate == "MEMBERUI") then
        self.x = self.positions[self.currentmenuposition][2]
        self.y = self.positions[self.currentmenuposition][3]+8
        love.graphics.draw(self.image, self.x, self.y, 0, self.size, self.size)
    end
    if localcurrentstate == "BULLETS" then
        love.graphics.draw(self.image, self.x, self.y, 0, self.size, self.size)
    end
end