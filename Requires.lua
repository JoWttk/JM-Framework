-- Tier 0: pure utilities, no game dependencies
Task = require("engine.Utils.task")
Signal = require("engine.Utils.signal")
Table = require("engine.Utils.Table")
Tween = require("engine.Utils.tween")

-- Tier 1: interface/dialog leaves
UI = require("engine.Interface.UI")
RichText = require("engine.Interface.RichText")
SimpleD = require("engine.DialogTypes.SimpleDialogue")

-- Tier 2: interface widgets built on tier 1
Text = require("engine.Interface.text")
Button = require("engine.Interface.button")
Bar = require("engine.Interface.bar")
VirtualKeyboard = require("engine.Interface.virtualKeyboard")

-- Tier 3: entity-system / shader leaves
Entity = require("engine.EntitySystem.Entity")
Components = require("engine.EntitySystem.Components")
Camera = require("engine.EntitySystem.Camera")
Platform = require("engine.EntitySystem.Platform")
Image = require("engine.EntitySystem.Image")
Dissolve = require("engine.Shaders.Dissolve")
SpotLight = require("engine.Shaders.SpotLight")

-- Tier 4: systems that need tiers 1-3
Input = require("engine.Input")                     -- needs SimpleD, UI
Dialogue = require("engine.DialogTypes.Dialogue")   -- needs Input
Readable = require("engine.EntitySystem.Readable")  -- needs Input, Tween
Window = require("engine.Interface.window")         -- needs RichText
Enemy = require("engine.EntitySystem.Enemy")        -- needs Text, Dissolve, Signal, Platform
Scene = require("engine.Scene")                     -- needs Table
Save = require("engine.Save")
AutoSave = require("engine.AutoSave")               -- needs Save
Progress = require("engine.Progress")               -- needs Save
MobileControls = require("engine.MobileControls")
Systems = require("engine.EntitySystem.Systems")    -- needs Components

-- Tier 5: engine modules that only touch a game-provided global (e.g. Player)
NPC = require("engine.EntitySystem.NPC")
Question = require("engine.EntitySystem.Question")
ScreenshotTaken = require("engine.Utils.screenshotTaken")
Camera = require("engine.EntitySystem.Camera")