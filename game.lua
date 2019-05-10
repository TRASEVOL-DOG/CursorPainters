
require("nnetwork")
require("object")



-- CORE

function _init()
  init_object_mgr(
    "cursor"
  )
  
  if not IS_SERVER then
    cursor_d = {}
    for y = 0,8 do
      local line = {}
      for x = 0,6 do
        local v = sget(x, y)
        if v ~= 1 then
          line[x] = v
        end
      end
      cursor_d[y] = line
    end
  
    canvas = new_surface(256, 160)
    target(canvas)
    cls()
    target()
  end
  
  canvas_d = {}
  for y = 0,159 do
    local line = {}
    for x = 0,255 do
      line[x] = 0
    end
    canvas_d[y] = line
  end
  
  canvas_diff = {}

  init_network()
  
  spritesheet_grid(11,11)
  palt(0, false)
end

function _update()
  if not IS_SERVER then
    local mx, my = flr(btnv(0)), flr(btnv(1))
    
    if not btn(3) then
      target(canvas)
    
      palt(0, false)
      palt(1, true)
      
      local n
      if btn(2) then
        pal(2,1)
        pal(3,2)
        my = my + 1
        n = -1
      else
        n = 0
      end
      
      palt(1, true)
      spr(0, mx, my)
      palt(1, false)
      
      for y,l in pairs(cursor_d) do
        local c_l = canvas_d[my + y]
        if c_l then
          for x,v in pairs(l) do
            c_l[mx + x] = max(v+n, 0)
          end
        end
      end
      
      pal(2,2)
      pal(3,3)
      
      target()
    end
    
    if my_cursor then
      my_cursor.x = btnv(0)
      my_cursor.y = btnv(1)
      my_cursor.dn = btn(2)
      my_cursor.up = btn(3)
    end
  end

  update_network()
end

function _draw()
  cls()

  spr_sheet(canvas, 0, 0)
  
  rectfill(0,0,255,8,0)
  rectfill(0,9,255,9,1)
  rectfill(0,10,255,10,0)
  
  local stra, strb = ":: CursorPainters!  v1.0.0", "by Trasevol_Dog ::"
  local wb = str_px_width(strb)
  print(stra, 0, -5, 1)
  print(strb, 255 - wb, -5, 1)
  clip(0,1,256,5)
  print(stra, 0, -5, 2)
  print(strb, 255 - wb, -5, 2)
  clip(0,1,256,3)
  print(stra, 0, -5, 3)
  print(strb, 255 - wb, -5, 3)
  clip()
  
  rectfill(0,151,255,159,0)
  rectfill(0,150,255,150,1)
  rectfill(0,149,255,149,0)

  cursor_target = nil
  
  draw_objects(0,2)
  
  if cursor_target then
    local s = cursor_target
    local x,y = s.x + 3, s.y - 1

    if s.pic then
      rectfill(x-17, y-41, x+16, y-8, 0)
      spr_sheet(s.pic, x-16, y-40, 32, 32)
    end
    
    printp(0x3330, 0x3130, 0x3230, 0x3330)
    printp_color(3, 1, 0)
    local w = str_px_width(s.name)
    pprint(s.name, x - w/2 - 2, y - 15)
  end
  
  draw_objects(3,4)
end

-- DRAWS

function draw_cursor(s)
  local x,y = s.x, s.y

  if s.dn then
    pal(2,1)
    pal(3,2)
    y = y + 1
  elseif s.up then
    pal(0,1)
    pal(3,2)
    y = y - 1
  end
  
  palt(1, true)
  spr(0, x, y)
  
  if s.id == my_id then
    pal(3,3)
  else
    if my_cursor and my_cursor.x > s.x and my_cursor.x < s.x + 7 and my_cursor.y > s.y and my_cursor.y < s.y + 9 then
      cursor_target = s
      pal(3,3)
    else
      pal(3,2)
    end
  end
  
  spr(1, x-1, y-1)
  palt(1, false)
  
  pal(0,0)
  pal(2,2)
  pal(3,3)
end


-- CREATES

function create_cursor(id)
  local s = {
    id = id,
    name = nil,
    pic = nil,
    x = 0,
    y = 0,
    dn = false,
    up = false,
    draw = draw_cursor,
    regs = {"cursor"}
  }
  
  if id == my_id then
    add(s.regs, "to_draw4")
  else
    add(s.regs, "to_draw2")
  end
  
  register_object(s)
  
  log("New cursor! #"..id, "/")
  
  return s
end


-- MISC INIT

function load_assets()
  load_png("spritesheet", "assets/sheet.png", nil, true)
  
  load_font("assets/Lithify.ttf", 16, "lithify", true)
  
--  load_sfx("assets/jump.wav", "jump", 1)
--  load_sfx("assets/snake.wav", "snek", 0.5)
end

function define_controls()
  register_btn(0, 0, input_id("mouse_position", "x"))
  register_btn(1, 0, input_id("mouse_position", "y"))
  register_btn(2, 0, input_id("mouse_button", "lb"))
  register_btn(3, 0, input_id("mouse_button", "rb"))
end
