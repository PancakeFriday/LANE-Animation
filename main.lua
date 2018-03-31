local Animation = require "LANE-Animation"

love.graphics.setDefaultFilter("nearest","nearest")

function love.load()
	testani = Animation("test.ani")
	if not testani:setCurrent("shooting") then
		error("Animation does not exist")
	end
	testani:play()
end

function love.update(dt)
	testani:update(2*dt)
end

function love.draw()
	local ww, wh = love.graphics.getDimensions()
	love.graphics.push()
	love.graphics.translate(ww/2, wh/2)
	love.graphics.scale(4,4)

	testani:draw()

	love.graphics.pop()
end
