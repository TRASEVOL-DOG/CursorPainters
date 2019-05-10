if CASTLE_PREFETCH then
  CASTLE_PREFETCH({
    "game.lua",
    "object.lua",
    "nnetwork.lua",
    "https://raw.githubusercontent.com/castle-games/share.lua/master/cs.lua",
    "https://raw.githubusercontent.com/castle-games/share.lua/master/state.lua",
    "assets/sheet.png",
    "assets/Lithify.ttf",
  })
end

require("sugarcoat/sugarcoat")
sugar.utility.using_package(sugar.S, true)

require("nnetwork")
start_client()

require("game")

function client.load()
  init_sugar("CursorPainters!", 256, 160, 3)
  screen_render_integer_scale(false)
--  screen_resizeable(true)
  
--  set_frame_waiting(30)
  
--  use_palette(palettes.bubblegum16)
  
  define_controls()
  load_assets()
  
  _init()
  
  init_done = true
end

function client.update()
  if not init_done then return end

  if ROLE then client.preupdate() end

  _update()
  
  if ROLE then client.postupdate() end
end

function client.draw()
  if not init_done then return end
  
  _draw()
end