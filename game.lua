
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
    
    trace = {}
    for y = 0,159 do
      trace[y] = {}
    end
  
    canvas = new_surface(256, 160)
    target(canvas)
    cls()
    target()
  end
  
  canvas_d = {}
  if IS_SERVER then
  for y = 0,159 do
    local line = {}
    for x = 0,255 do
      line[x] = 0
    end
    canvas_d[y] = line
  end
  else
    for y = 0,159 do
      local line = {}
      for x = 0,255 do
        line[x] = 0
      end
      canvas_d[y] = line
    end
  end
  
  canvas_diff = {}

  init_network()
  
  spritesheet_grid(11,11)
  palt(0, false)
  
  my_cursor = create_cursor()
end

local sync_y = 0
local sync_k = 1
function _update()
  
  if not IS_SERVER then
    target(canvas)
    color(3)
    
    if my_id and client.share[1] then
      sync_y = (sync_y + sync_k) % 160
      for y = sync_y, sync_y+sync_k-1 do
        local s_l = client.share[1][y]
        if s_l then
          local cd_l = canvas_d[y]
          local t_l = trace[y]
          for x,v in pairs(s_l) do
            if v and not t_l[x] then
              cd_l[x] = v
              pset(x,y,v)
            end
          end
        end
      end
    end
    
    for y,l in pairs(canvas_diff) do
      local t_l = trace[y]
      for x,v in pairs(l) do
        if v then
          t_l[x] = nil
          pset(x,y,v)
        end
      end
      canvas_diff[y] = nil
    end
    target()
  
  
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
      elseif btn(4) then
        pal(2,0)
        pal(3,0)
        n = -3
      else
        n = 0
      end
      
      palt(1, true)
      spr(0, mx, my)
      palt(1, false)
      
      for y,l in pairs(cursor_d) do
        local c_l = canvas_d[my + y]
        local t_l = trace[my + y]
        if c_l then
          for x,v in pairs(l) do
            c_l[mx + x] = max(v+n, 0)
            t_l[mx + x] = true
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
      my_cursor.bk = btn(4)
      
      button = nil
      if btnv(1) > 150 then
        local x = btnv(0)
        if x > 216 then
          button = mid(flr((x - 216) / 13), 0, 2)
        end
      end
      
      if button and btnp(2) then
        if button == 1 and castle and castle.post then
          network.async(function() 
            castle.post.create({
              message = pick({"Everyone's an artist with CursorPainters!",
                              "CursorPainters rocks!",
                              "CursorPainters 4 life!",
                              "CursorPainters v2.0.0 when???",
                              "\\o/ !! CursorPainters !! \\o/",
                              "I looooove CursorPainters! <3"}),
              media = 'capture'
            })
          end)
        elseif button == 2 then
          show_self = not show_self
        end
      end
    end
  else
    for s in group("cursor") do
      if s.wipe then
        for i = 0,499 do
          local x, y = irnd(256), irnd(160)
          canvas_d[y][x] = max(canvas_d[y][x] - 1, 0)
        end
      end
    end
  end

  update_network()
end

function _draw()
  cls()

  spr_sheet(canvas, 0, 0)
  
  color(3)
  
  draw_topbar()
  draw_bottombar()

  cursor_target = nil
  
  draw_objects(0,2)
  
  if cursor_target then
    local s = cursor_target
    local x,y = s.x + 3, s.y - 1

    --if s.pic then
    --  rectfill(x-17, y-41, x+16, y-8, 0)
    --  spr_sheet(s.pic, x-16, y-40, 32, 32)
    --end
    
    if surface_exists("cur"..s.id) then
      rectfill(x-18, y-42, x+17, y-9, 0)
      rectfill(x-17, y-41, x+16, y-8, 1)
      spr_sheet("cur"..s.id, x-16, y-40, 32, 32)
    end
    
    if s.name then
      printp(0x3330, 0x3130, 0x3230, 0x3330)
      printp_color(3, 1, 0)
      local w = str_px_width(s.name)
      pprint(s.name, x - w/2 - 2, y - 15)
    end
  end
  
  draw_objects(3,4)
  
  if castle and not client.connected then
    local x, y = 128, 80
    local str
    if castle.user.isLoggedIn then
      if disconnected then
        str = "Disconnected :("
      else
        str = "Connecting"
        for i = 1,flr(t()/0.25)%4 do
          str = str.."."
        end
      end
    else
      str = "Please log-in to play!"
    end
    
    printp(0x3330, 0x3130, 0x3230, 0x3330)
    printp_color(3, 1, 0)
    local w = str_px_width(str)
    pprint(str, x - w/2 - 2, y - 15)
  end
end

-- DRAWS

function draw_cursor(s)
  local x,y = s.x, s.y

  if s.up then
    pal(0,1)
    pal(3,2)
    y = y - 1
  elseif s.dn then
    pal(2,1)
    pal(3,2)
    y = y + 1
  elseif s.bk then
    pal(2,0)
    pal(3,0)
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

function draw_topbar()
  rectfill(0,0,255,8,0)
  rectfill(0,9,255,9,1)
  rectfill(0,10,255,10,0)
  
  local stra, strb = ":: CursorPainters!", "by Trasevol_Dog ::"
  local wb = str_px_width(strb)
  local xb = 255 - wb
  print(stra, 0, -5, 1)
  print(strb, xb, -5, 1)
  clip(0,1,256,5)
  print(stra, 0, -5, 2)
  print(strb, xb, -5, 2)
  clip(0,1,256,3)
  print(stra, 0, -5, 3)
  print(strb, xb, -5, 3)
  clip()
  
  draw_info()
end

function draw_bottombar()
  if show_self then
    local s = my_cursor
    local x,y = 254, 148

    palt(0,false)
    palt(1,false)
    
    if surface_exists("cur"..(s.id or "/")) then
      rectfill(x-34, y-34, x, y, 0)
      rectfill(x-33, y-33, x, y, 1)
      spr_sheet("cur"..s.id, x-32, y-32, 32, 32)

      y = y - 32
    end
    
    if s.name then
      printp(0x3330, 0x3130, 0x3230, 0x3330)
      printp_color(3, 1, 0)
      local w = str_px_width(s.name)
      pprint(s.name, x - w - 2, y-16)
    end
  end

  rectfill(0,151,255,159,0)
  rectfill(0,150,255,150,1)
  rectfill(0,149,255,149,0)
  
  draw_credits(152-6)
  
  palt(0, true)
  palt(1, false)
  
  local x,y = 256-39, 152
  
  for i = 0,2 do
    spr(11, x, y-2)
    x = x + 3
    
    local s = 2+i*3
    if button == i then
      if btn(2) then
        spr(s+2, x, y)
      else
        spr(s+1, x, y)
      end
    else
      spr(s, x, y)
    end
    
    x = x + 10
  end
  
  if button then
    local str = ({
      [0] = "Clean-up. (hold)",
      [1] = "Post picture.",
      [2] = "See self."
    })[button]
    
    local w = str_px_width(str)
    
    printp(0x3330, 0x3130, 0x3230, 0x3330)
    printp_color(3, 1, 0)
    pprint(str, 256 - w - 4, y - 18)
  end
  
  palt(0, false)
  palt(1, true)
end

function draw_credits(y)
--  draw_text("Thank you to my Patreon supporters!",4,scrnh-18,0, 21, 22)
--  local str = "   ~~~   ^Joseph White^,  ^Spaceling^,  rotatetranslate,  Anne Le Clech,  Wojciech Rak,  HJS,  slono,  Austin East,  Zachary Cook,  Jefff,  Meru,  Bitzawolf,  Paul Nguyen,  Dan Lewis,  Christian Östman,  Dan Rees-Jones,  Reza Esmaili,  Andreas Bretteville,  Joel Jorgensen,  Marty Kovach,  Giles Graham,  Flo Devaux,  Cole Smith,  Thomas Wright,  HERVAN,  berkfrei,  Tim and Alexandra Swast,  Jearl,  Chris McCluskey,  Sam Loeschen,  Pat LaBine,  Collin Caldwell,  Andrew Reitano,  Qristy Overton,  Finn Ellis,  amy,  Brent Werness,  yunowadidis-musik,  Max Cahill,  hushcoil,  Jacel the Thing,  Gruber,  Pierre B.,  Sean S. LeBlanc,  Andrew Reist,  vaporstack,  Jakub Wasilewski"
--  local w = str_width(str)
--  local x = 4-((t*50)%w)
--  draw_text(str,x,scrnh-8,0, 0, 22)
--  draw_text(str,x+w,scrnh-8,0, 0, 22)
  
  local stra = "Thx to:"
  local strb = "  ---  Everyone at Castle!  ---  My awesome Patreons! ^Joseph White, ^Spaceling, rotatetranslate, Anne Le Clech, bbsamurai, HJS, slono, Austin East, Jefff, Meru, Bitzawolf, Paul Nguyen, Dan Lewis, Dan Rees-Jones, Reza Esmaili, Joel Jorgensen, Marty Kovach, Flo Devaux, Cole Smith, Thomas Wright, HERVAN, berkfrei, Tim and Alexandra Swast, Jearl, Johnathan Roatch, Raphael Gaschignard, Eiyeron, Sam Loeschen, Andrew Reitano, amy, Simon Stålhandske, yunowadidis-musik, Max Cahill, hushcoil, Gruber, Pierre B., Sean S. LeBlanc, Andrew Reist, vaporstack, Jakub Wasilewski"

  local wa = str_px_width(stra)+1
  local wb = str_px_width(strb)
  local wc = 256-40-wa
  local xc = wa
  
  local x = wa - (t() * 25 % wb)
  
  print(stra, 0, y, 1)
  
  clip(xc, y+3, wc, 16)
  print(strb, x, y, 1)
  print(strb, x + wb, y, 1)
  
  clip(0, y+3, 256, 8)
  print(stra, 0, y, 2)
  
  clip(xc, y+3, wc, 8)
  print(strb, x, y, 2)
  print(strb, x + wb, y, 2)
  
  clip(0,y+3,256,6)
  print(stra, 0, y, 3)
  
  clip(xc, y+3, wc, 6)
  print(strb, x, y, 3)
  print(strb, x + wb, y, 3)
  
  clip()
  
  y = y + 6
  scan_surface()
  for yy = y, y+8 do
    pset(wa+1, yy, max(pget(wa+1, yy) - 1, 0))
    pset(wa, yy,   max(pget(wa, yy) - 2, 0))
    
    pset(wa+wc-2, yy, max(pget(wa+wc-2, yy) - 1, 0))
    pset(wa+wc-1, yy, max(pget(wa+wc-1, yy) - 2, 0))
  end
end

function draw_info()
  local x = 128
  
  palt(0,true)
  palt(1,false)
  
  spr(11, x-4, -1, 1, 1, false, true)
  spr(11, x-3, -1, 1, 1, true, true)
  
  x = x
  
  local hover
  if btnv(1) < 10 and btnv(0) >= x-4 and btnv(0) < x+5 then
    if btn(2) then
      spr(14, x-2, 1)
    else
      spr(13, x-2, 1)
    end
    hover = true
  else
    spr(12, x-2, 1)
  end
  
  if hover then
    local strs = {
      "CursorPainters v1.0.0",
      "",
      "Controls:",
      "- Left-Mouse-Button:",
      "    Dark Cursor",
      "- Right-mouse-Button:",
      "    Lift Cursor",
      "- Middle-Mouse-Button:",
      "    Eraser Cursor",
      "",
      "Have fun making art!"
    }
    
    local w = 0
    local h = 0
    for str in all(strs) do
      if str == "" then
        h = h + 4
      else
        h = h + 10
        w = max(w, str_px_width(str))
      end
    end
    w = w + 8
    
    local x = x - w/2
    local y = 11
    rectfill(x-2, y-2, x+w+1, y+h+1, 0)
    rect(x-1, y-1, x+w, y+h, 1)
    
    x = x + 4
    y = y - 4
    
    for str in all(strs) do
      if str == "" then
        y = y + 4
      else
        print(str, x, y+1, 1)
        print(str, x, y, 3)
        y = y + 10
      end
    end
  end
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
    bk = false,
    draw = draw_cursor,
    regs = {"cursor"}
  }
  
  if id == my_id then
    add(s.regs, "to_draw4")
  else
    add(s.regs, "to_draw2")
  end
  
  register_object(s)
  
  log("New cursor! #"..(id or "nil"), "/")
  
  return s
end


-- MISC INIT

local _D = require("sugarcoat/gfx_vault") -- cheating here
function load_assets()
  load_png("spritesheet", "assets/sheet.png", nil, true)
  
  load_font("assets/Lithify.ttf", 16, "lithify", true)
  load_font("assets/HapticPro.ttf", 16, "haptic", false)
  load_font("assets/SinsGold.ttf", 16, "sins", false)
  
  -- and cheating there
  _D.font_list["lithify"]:setFallbacks(_D.font_list["haptic"], _D.font_list["sins"])
  
--  load_sfx("assets/jump.wav", "jump", 1)
--  load_sfx("assets/snake.wav", "snek", 0.5)
end

function define_controls()
  register_btn(0, 0, input_id("mouse_position", "x"))
  register_btn(1, 0, input_id("mouse_position", "y"))
  register_btn(2, 0, input_id("mouse_button", "lb"))
  register_btn(3, 0, input_id("mouse_button", "rb"))
  register_btn(4, 0, input_id("mouse_button", "mb"))
end
