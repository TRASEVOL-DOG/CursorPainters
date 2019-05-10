if CASTLE_PREFETCH then
  CASTLE_PREFETCH({
    "assets/sheet.png",
    "assets/jump.wav",
    "assets/snake.wav"
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
end

function client.update()
  if ROLE then client.preupdate() end

  _update()
  
  if ROLE then client.postupdate() end
end

function client.draw()
  _draw()
end