# LANE-Animation
The import library to [LANE](https://github.com/PancakeFriday/LANE).

Using the library
===

Download the file `Lane-Animation.lua` and import it into the project via
```Lua
Animation = require "Lane-Animation.lua"
```

For a tl;dr version, clone this repository and run it.

Initializing an animation
---

Having an animation file on your computer (for example, you could download test.ani from this repository), initialize the file using
```Lua
-- Create an animation instance
testani = Animation("test.ani")
-- Set the current animation
testani:setCurrent("shooting")
-- Start the playback
testani:play()
```

Updating and drawing
---

Don't forget to include the `testani:draw()` and `testani:update(dt)` methods (hint: you can adjust the playback speed by giving an adjusted dt parameter to the update function).

Function reference
---

After you have created your instance via `ani = Animation("test.ani")`, it has several methods:
- `ani:getNames()`: Returns a table containing all animation names.
- `ani:setCurrent(n)`: Set the current animation.
- `ani:play()`: Start playback of the animation.
- `ani:stop()`: Stop playback and set time to 0.
- `ani:pause()`: Pause playback.
- `ani:draw()`: Draw the animation.
- `ani:update(dt)`: Increase time index by dt, if the animation is running.
