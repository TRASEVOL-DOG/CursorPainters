if castle then
  cs = require("https://raw.githubusercontent.com/castle-games/share.lua/master/cs.lua")
else
  cs = require("cs")
end

network_t = 0
my_id = nil

cursors = {}

function init_network()
  if IS_SERVER then
    server.share[1] = {} -- canvas_d
    server.share[2] = {} -- cursors
    
    new_client = {}
  end
end

function update_network()
  network_t = network_t - dt()
  if network_t > 0 then
    return
  end
  
  if IS_SERVER then
    server_output()
  else
    client_output()
  end
  
  network_t = 0.05
end



function client_input(diff)
  my_id = client.id
  
  if diff[1] then
    --target(canvas)
    --for y, l_d in pairs(diff[1]) do
    --  --local cl_d = canvas_d[y]
    --  for x, v in pairs(l_d) do
    --    pset(x,y,v)
    --    --cl_d[x] = v
    --  end
    --end
    --target()
    
    for y, l_d in pairs(diff[1]) do
      local cl_d = canvas_diff[y] or {}
      for x, v in pairs(l_d) do
        cl_d[x] = v
      end
      canvas_diff[y] = cl_d
    end
  end
  
  for id, s in pairs(cursors) do
    if not client.share[2][id] then
      deregister_object(s)
      cursors[id] = nil
    end
  end
  
  for id, s_d in pairs(client.share[2]) do
    local s = cursors[id]
    if not s then
      if id == my_id then
        s = my_cursor
        s.id = my_id
      else
        s = create_cursor(id)
      end
      
      cursors[id] = s
    end
    
    if id ~= my_id then
      s.x, s.y, s.dn, s.up, s.bk = unpack(s_d)
      s.bk = s_d[5]
    end
    
    if not s.name then
      s.name = s_d[6]
      local url = s_d[7]
      if url then
        network.async(function()
          s.pic = load_png("cur"..id, url)
          love.graphics.setCanvas()
        end)
      end
    end
  end
  
  if diff[3] and diff[3] ~= nil and palette_sync then
    for i = 0,3 do
      local c = diff[3][i]
      if c then
        plt[i].r = c.r or plt[i].r
        plt[i].g = c.g or plt[i].g
        plt[i].b = c.b or plt[i].b
      end
    end
    log("Loading palette from server.")
    use_palette({
      flr(plt[0].r*255)*256*256 +flr(plt[0].g*255)*256 +flr(plt[0].b*255),
      flr(plt[1].r*255)*256*256 +flr(plt[1].g*255)*256 +flr(plt[1].b*255),
      flr(plt[2].r*255)*256*256 +flr(plt[2].g*255)*256 +flr(plt[2].b*255),
      flr(plt[3].r*255)*256*256 +flr(plt[3].g*255)*256 +flr(plt[3].b*255),
    })
  end
end

function client_output()
  client.home[1] = canvas_d
  client.home[2] = flr(btnv(0))
  client.home[3] = flr(btnv(1))
  client.home[4] = btn(2)
  client.home[5] = btn(3)
  client.home[6] = btn(4)
  
  if not client.home[7] and castle and castle.user.isLoggedIn then
    local info = castle.user.getMe()
    if info then
      --client.home[7] = info.username
      client.home[7] = info.name or info.username
      client.home[8] = info.photoUrl
    end
  end
  
  client.home[9] = (button == 0 and btn(2))
end

function client_connect()
  log("Connected to server!", "n")
  
  my_id = client.id
end

function client_disconnect()
  log("Disconnected from server!", "n")
  disconnected = true
end


function server_input(id, diff)
  if id then
    local ho = diff
    if new_client[id] then
      new_client[id] = false
    elseif ho[1] then
      for y, l_d in pairs(ho[1]) do
        local cl_d = canvas_d[y]
        for x, v in pairs(l_d) do
          if v then
            cl_d[x] = v
          end
        end
      end
    end
    
    local s = cursors[id]
    ho = server.homes[id]
    s.x, s.y = ho[2], ho[3]
    s.dn, s.up, s.bk = ho[4], ho[5], ho[6]
    
    if not s.name then
      s.name = ho[7] or "Guest"
      s.pic = ho[8]
    end
    
    s.wipe = ho[9]
    
    if diff[10] then
      if not server.share[3] then
        server.share[3] = {}
      end
    
      for i = 0,3 do
        local sc = server.share[3][i]
        if not sc then
          sc = {}
          server.share[3][i] = sc
        end
        
        local c = diff[10][i]
        if c then
          sc.r = c.r or sc.r
          sc.g = c.g or sc.g
          sc.b = c.b or sc.b
          
          log(sc.r.." - "..sc.g.." - "..sc.b)
        end
      end
      log("Taking palette from client.")
      server.share[3]:__relevance(function(self, client_id) if client_id == id then return false else return true end end)
    end
  end
end

function server_output()
  server.share[1] = canvas_d
  
  for id, s in pairs(cursors) do
    server.share[2][id] = {
      s.x, s.y,
      s.dn, s.up, s.bk,
      s.name, s.pic
    }
  end
end

function server_new_client(id)
  log("New client: #"..id, "n")

  cursors[id] = create_cursor(id)
  new_client[id] = true
end

function server_lost_client(id)
  log("Client #"..id.." disconnected.", "n")

  deregister_object(cursors[id])
  server.share[2][id] = nil
  cursors[id] = nil
end



-- look-up table

-- client.home = {
--   
-- }


-- server.share = {
--
-- }


function start_client()
  client = cs.client
  
  if castle then
    client.useCastleConfig()
  else
    start_client = function()
      client.enabled = true
      client.start('127.0.0.1:22122') -- IP address ('127.0.0.1' is same computer) and port of server
      
      love.update, love.draw = client.update, client.draw
      client.load()
      
      ROLE = client
    end
  end
  
  client.changed = client_input
  client.connect = client_connect
  client.disconnect = client_disconnect
end

function start_server(max_clients)
  server = cs.server
  server.maxClients = max_clients
  
  if castle then
    server.useCastleConfig()
  else
    start_server = function()
      server.enabled = true
      server.start('22122') -- Port of server
      
      love.update = server.update
      server.load()
      
      ROLE = server
    end
  end
  
  server.changed = server_input
  server.connect = server_new_client
  server.disconnect = server_lost_client
end