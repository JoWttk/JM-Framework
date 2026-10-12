---@class Levels
--- Registro de capítulos/níveis + progresso (o que está liberado e o último nível jogado).
---
--- ============================================================
---  COMO ADICIONAR UM NÍVEL NOVO
--- ============================================================
---  1) Crie o arquivo da cena em scenes/ (ex: scenes/levels/Chapter1/Chapter1_Level7.lua).
---  2) Adicione UMA linha na lista `levels` do capítulo certo, aqui embaixo:
---         { scene = "Chapter1_Level7" },
---     O card aparece sozinho no map selector (e ele já nasce bloqueado
---     até o jogador entrar nele pela primeira vez).
---
---  COMO ADICIONAR UM CAPÍTULO NOVO
---     Copie um bloco `{ id = ..., name = {...}, levels = {...} }` abaixo.
---
---  COMO LIBERAR O CAPÍTULO 3 (ou qualquer outro) NO FUTURO
---     Troque `locked = true` por `locked = false`, e preencha os níveis
---     com `scene = "NomeDaCena"`.
---
---  Campos opcionais de um nível:
---     name    = { en = "City", pt = "Cidade" }   -- texto do card (padrão: número do nível)
---     aliases = { "BigMkt" }                      -- outras cenas que contam como "estar neste nível"
--- ============================================================
local Levels = {}

local Save = require("engine.Save")

local PROGRESS_FILE = "progress.txt"

Levels.chapters = {
    {
        id = 1,
        name = { en = "Chapter 1", pt = "Capítulo 1" },
        levels = {
            { scene = "Chapter1_Level1" },
            { scene = "Chapter1_Level2" },
            { scene = "Chapter1_Level3" },
            { scene = "Chapter1_Level4" },
            { scene = "Chapter1_Level5" },
            { scene = "Chapter1_Level6" },
        },
    },
    {
        id = 2,
        name = { en = "Chapter 2", pt = "Capítulo 2" },
        levels = {
            { scene = "City", name = { en = "City", pt = "Cidade" }, aliases = { "BigMkt" } },
        },
    },
    {
        id = 3,
        name = { en = "Chapter 3", pt = "Capítulo 3" },
        locked = true, -- pronto, mas bloqueado: ainda não tem níveis jogáveis
        levels = {
            {}, {}, {}, -- slots vazios (sem `scene`) = cards bloqueados
        },
    },
}

-- ------------------------------------------------------------
--  Lista "achatada" (ordem de jogo) + busca por nome de cena
-- ------------------------------------------------------------
local flat = nil
local byScene = nil

local function build()
    flat, byScene = {}, {}
    for ci, chapter in ipairs(Levels.chapters) do
        for li, level in ipairs(chapter.levels) do
            local entry = { chapter = chapter, level = level, chapterIndex = ci, levelIndex = li }
            flat[#flat + 1] = entry
            entry.order = #flat
            if level.scene then
                byScene[level.scene] = entry
                for _, alias in ipairs(level.aliases or {}) do
                    byScene[alias] = entry
                end
            end
        end
    end
end

---Reconstrói as listas internas (chame se alterar `Levels.chapters` em tempo de execução).
function Levels.rebuild()
    flat, byScene = nil, nil
end

---@param scene string
---@return table|nil entry { chapter, level, chapterIndex, levelIndex, order }
function Levels.find(scene)
    if not flat then build() end
    return scene and byScene[scene] or nil
end

---@return table[] lista de todos os níveis na ordem de jogo
function Levels.all()
    if not flat then build() end
    return flat
end

-- ------------------------------------------------------------
--  Progresso (progress.txt)
-- ------------------------------------------------------------
local progress = nil

local function key(scene) return "lvl_" .. scene end

local function persist()
    Save.write(PROGRESS_FILE, progress)
end

local function firstPlayableScene()
    for _, e in ipairs(Levels.all()) do
        if e.level.scene and not e.chapter.locked then return e.level.scene end
    end
end

---Carrega o progresso do disco (faz automaticamente na primeira vez que for usado).
---Saves antigos (sem progress.txt) são migrados a partir da cena salva em player.txt.
function Levels.load()
    local data = Save.read(PROGRESS_FILE)
    if data then
        progress = data
        return
    end

    progress = {}

    local first = firstPlayableScene()
    if first then progress[key(first)] = true end

    local player = Save.read("player.txt")
    local entry = player and Levels.find(player.scene)
    if entry then
        for _, e in ipairs(Levels.all()) do
            if e.order <= entry.order and e.level.scene then
                progress[key(e.level.scene)] = true
            end
        end
        progress.last = entry.level.scene
    end

    persist()
end

local function ensure()
    if not progress then Levels.load() end
end

---@param scene string
---@return boolean
function Levels.isUnlocked(scene)
    ensure()
    return scene ~= nil and progress[key(scene)] == true
end

---Pode jogar? (capítulo não bloqueado + tem cena + já liberado)
---@param entry table item de Levels.all()
---@return boolean
function Levels.isPlayable(entry)
    if entry.chapter.locked then return false end
    if not entry.level.scene then return false end
    return Levels.isUnlocked(entry.level.scene)
end

---Libera um nível manualmente.
---@param scene string
function Levels.unlock(scene)
    ensure()
    if scene and not progress[key(scene)] then
        progress[key(scene)] = true
        persist()
    end
end

---Chamado pelo Scene.change toda vez que uma cena é carregada:
---entrar num nível = liberar ele e marcá-lo como "último nível jogado".
---@param scene string
function Levels.onEnter(scene)
    local entry = Levels.find(scene)
    if not entry or entry.chapter.locked then return end

    ensure()
    local s = entry.level.scene
    local changed = false
    if not progress[key(s)] then
        progress[key(s)] = true
        changed = true
    end
    if progress.last ~= s then
        progress.last = s
        changed = true
    end
    if changed then persist() end
end

---Último nível em que o jogador parou (ou nil).
---@return string|nil
function Levels.getLast()
    ensure()
    local last = progress.last
    local entry = last and Levels.find(last)
    if entry and not entry.chapter.locked then return last end
    return nil
end

---Texto localizado (aceita string simples ou tabela { en = "...", pt = "..." }).
---@param v string|table|nil
---@param fallback string|nil
---@return string
function Levels.text(v, fallback)
    if type(v) == "table" then
        return v[CurrentLanguage] or v.en or fallback or ""
    end
    return v or fallback or ""
end

return Levels
