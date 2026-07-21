### What is JM Framework? ###
JM Framework is a Love2D Framework with utilitaries for your games!

### Where can I use it? ###
You can use it in your games made with Love2D.

### How can I use it? ###
You can install the framework on Github and add this to your project.
After adding the framework to your project, you can require it inside your code.
```lua
local engine = require("engine")
```

<br>
<br>

**EXAMPLE: *Platform***
```lua
local Platform = require("engine/EntitySystem/Platform.lua")
local P = Platform.new(
    100, -- X position
    100, -- Y position
    32, -- Width
    32, -- Height
    {0,0,0}, -- Color (0,0,0 = black)
    "assets/image.png", -- Texture image (Optional)
    "platform", -- tag
    true, -- CanCollide
    1, -- Alpha (transparency | 0-1)
    true, -- Visible (true or false)
    true, -- Breakable
    "all", -- The direction that you can break the platform
    function()
        print("Breaked the platform") -- Function that runs after you broke the platform
    end,
    true, -- Tile texture | false = SCALE the image (if scale > img size); true = REPEAT the image (if scale > img size)
    1, -- layer,
    false -- pushable
)
```