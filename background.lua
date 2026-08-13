Background = Object:extend()

function Background:new(name)

    self.video = love.graphics.newVideo("sprites/"..name..".ogv")

end

function Background:testVideo()

    if self.video:isPlaying() then return end
    self.video:rewind()
    self.video:play()


end

function Background:update(dt)

    self:testVideo()

end

function Background:draw()

    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(self.video, 0, 0, 0, 2, 2)

end