SUGAR_SERVER_MODE = true

require("sugarcoat/sugarcoat")
sugar.utility.using_package(sugar.S, true)

require("nnetwork")
start_server(8)

require("game")

function server.load()
  IS_SERVER = true

  init_sugar("CursorPainters!", 256, 160, 3)
  set_frame_waiting(50)
  
  _init()
end

function server.update()
  if ROLE then server.preupdate() end

  _update()
  
  if ROLE then server.postupdate() end
end