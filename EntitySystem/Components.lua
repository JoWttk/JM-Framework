---@class Components
---@field Position table<number, {x: number, y: number}> Entity position components
---@field Velocity table<number, {x: number, y: number}> Entity velocity components
---@field Sprite table<number, {image: love.Image, scale: number, flip: boolean}> Entity sprite components
---@field Animation table<number, {animations: table, current: string, frame: number, timer: number, speed: number}> Entity animation components
---@field Collider table<number, {x: number, y: number, w: number, h: number}> Entity collider components
local Components = {}

Components.Position = {}
Components.Velocity = {}
Components.Sprite = {}
Components.Animation = {}
Components.Collider = {}

return Components