Triggers = {}
function Triggers.draw()

  if TexturePalette.draw() then return end
  if Screen.term_active then return end
  if Player.dead then return end
  if not deja then return end

  env_light_setup()
      
  local left_x = sx + math.floor(30*scale)
  local left_y = sy + sh - left_underlay.height - math.floor(30*scale)
  
  if Screen.renderer == "opengl" then
    -- compass
    do
      compass.rotation = 360 - Player.direction
      env_draw(compass, left_x, left_y)
    end
  end
  
  env_draw(left_underlay, left_x, left_y)
  
  -- oxygen bar
  do
    local otwo_x = left_x + (280 * scale)
    local otwo_y = left_y + (160 * scale)
    local otwo_w = 340 * scale
    local otwo_h = 38 * scale
    
    local otwo_fill = math.floor(otwo_w * (Player.oxygen / 10800))
    Screen.fill_rect(otwo_x, otwo_y, otwo_fill, otwo_h,
                     env_adjust_glow({ 0.2, 0.4, 0.8, 1 }))
  end
  
  -- health bar
  do
    local life_x = left_x + (280 * scale)
    local life_y = left_y + (122 * scale)
    local life_w = 340 * scale
    local life_h = 38 * scale
    
    local life_amt = Player.life
    if life_amt > 0 then
      local life_fill = math.floor(life_w * math.min(150, life_amt) / 150)
      Screen.fill_rect(life_x, life_y, life_fill, life_h,
                       env_adjust_glow({ 0.8, 0, 0, 1 }))
    end
    if life_amt > 150 then
      local life_fill = math.floor(life_w * math.min(150, life_amt - 150) / 150)
      Screen.fill_rect(life_x, life_y, life_fill, life_h,
                       env_adjust_glow({ 0.8, 0.8, 0, 1 }))
    end
    if life_amt > 300 then
      local life_fill = math.floor(life_w * math.min(150, life_amt - 300) / 150)
      Screen.fill_rect(life_x, life_y, life_fill, life_h,
                       env_adjust_glow({ 0.8, 0, 0.8, 1 }))
    end
  end
  
    -- motion sensor
  if Player.motion_sensor.active then
    local sens_x = left_x + (50 * scale)
    local sens_y = left_y + (50 * scale)
    local sens_w = 220 * scale
    local sens_h = 220 * scale
    local sens_brad = 18 * scale
    local sens_rad = 110 * scale
    local sens_xcen = left_x + (160 * scale)
    local sens_ycen = left_y + (160 * scale)
    
    if Player.compass.nw then
      env_draw_glow(northwest, left_x, left_y)
    end
    if Player.compass.ne then
      env_draw_glow(northeast, left_x, left_y)
    end
    if Player.compass.sw then
      env_draw_glow(southwest, left_x, left_y)
    end
    if Player.compass.se then
      env_draw_glow(southeast, left_x, left_y)
    end
    
    for i = 1,#Player.motion_sensor.blips do
      local blip = Player.motion_sensor.blips[i - 1]
      local mult = blip.distance * sens_rad / 8
      local rad = math.rad(blip.direction)
      local xoff = sens_xcen + math.cos(rad) * mult
      local yoff = sens_ycen + math.sin(rad) * mult
      
      local alpha = 1.0
      local strength = 0.8
      if blip.intensity > 0 then
        alpha = 1.0 / (blip.intensity + 1)
        strength = 0.4
      end
      local color = { 0, strength, 0, alpha }
      if blip.type == "alien" then
        color = { strength, 0, 0, alpha }
      end
      if blip.type == "hostile player" then
        color = { strength, strength, 0, alpha }
      end
      
      Screen.fill_rect(math.floor(xoff - sens_brad/2),
                       math.floor(yoff - sens_brad/2),
                       sens_brad, sens_brad, env_adjust_glow(color))
      if blip.intensity == 0 then
        Screen.frame_rect(math.floor(xoff - sens_brad/2) - 1,
                         math.floor(yoff - sens_brad/2) - 1,
                         sens_brad + 2, sens_brad + 2,
                         env_adjust_glow({ 0, 0, 0, 0.3 }), 1)
      end
    end
  end

  env_draw(left_overlay, left_x, left_y)


  local top_x = sx + sw - top_underlay.width - math.floor(30*scale)
  local top_y = sy + math.floor(30*scale)
  env_draw(top_underlay, top_x, top_y)

  -- inventory
  do
    
    local inv_h = 270 * scale
    local inv_w = 450 * scale
    local inv_x = top_x + 90*scale
    local inv_y = top_y + 25*scale
    clip(inv_x, inv_y, inv_w, inv_h)
    
    -- header
    local sec = Player.inventory_sections.current
    local extra = nil
    if sec.type == "network statistics" then
      extra = net_header()
    end
    if extra then
      local tw, th = deja:measure_text(extra)
      deja:draw_text(extra, inv_x + inv_w - tw - dejawidth, inv_y, env_adjust_glow({ 0.6, 0.9, 0.6, 1 }))
      deja:draw_text(sec.name, inv_x, inv_y, env_adjust_glow({ 0.6, 0.9, 0.6, 1 }))
    else
      local tw, th = deja:measure_text(sec.name)
      deja:draw_text(sec.name, inv_x + (inv_w - tw)/2, inv_y, env_adjust_glow({ 0.6, 0.9, 0.6, 1 }))
    end
    
    -- content area
    inv_y = inv_y + dejaheight
    inv_h = inv_h - dejaheight
    
    if sec.type == "network statistics" then
      -- player list and rankings
      local gametype = Game.type
      if gametype == "netscript" then
        gametype = Game.scoring_mode
      end
 
      local mw, mh = deja:measure_text("99:99")
      local mx = inv_x + mw + dejawidth
      local mwh = mw + math.floor(dejawidth/2)

      for idx, p in ipairs(sorted_players()) do

        -- background with player and team colors
        Screen.fill_rect(inv_x, inv_y, mwh, dejaheight,
                         colortable[p.team.mnemonic])
        Screen.fill_rect(inv_x + mwh, inv_y, inv_w - mwh, dejaheight,
                         colortable[p.color.mnemonic])
        
        -- ranking text
        local score = player_ranking_text(gametype, p.ranking)
        local iw, ih = deja:measure_text(score)
        deja:draw_text(score, inv_x + mw - iw, inv_y, env_adjust_glow({ 1, 1, 1, 1}))
        
        -- player name
        deja:draw_text(p.name, mx, inv_y, env_adjust_glow({ 1, 1, 1, 1 }))
        
        inv_y = inv_y + 30*scale
      end
    else
      -- item list
      local mw, mh = deja:measure_text("999")
      local mx = inv_x + mw + dejawidth
      for i = 1,#ItemTypes do
        local item = Player.items[i - 1]
        local name = ItemTypes[i - 1]
        if (item.count > 0 and item.inventory_section == sec.type) and not (name == "knife") then
          local ct = string.format("%d", item.count)
          local iw, ih = deja:measure_text(ct)
          deja:draw_text(ct, inv_x + mw - iw, inv_y, env_adjust_glow({ 0.5, 0.8, 0.5, 1}))
          
          local iname
          if item.count == 1 then
            iname = item.singular
          else
            iname = item.plural
          end 
          deja:draw_text(iname, mx, inv_y, env_adjust_glow({ 0.5, 0.8, 0.5, 1 }))
          inv_y = inv_y + 30*scale
        end
      end
    end
    
    unclip()
  end
  
  env_draw(top_overlay, top_x, top_y)
  
  
  local right_x = sx + sw - right_underlay.width - math.floor(30*scale)
  local right_y = sy + sh - right_underlay.height - math.floor(30*scale)

  -- ammo
  if Player.weapons.current then
    local weapon = Player.weapons.current
    local wp = weapon.primary
    local ws = weapon.secondary
    local primary_ammo = nil
    local secondary_ammo = nil
    
    if wp and wp.ammo_type then
      primary_ammo = wp.ammo_type
    end
    
    if ws and ws.ammo_type then
      secondary_ammo = ws.ammo_type
      if secondary_ammo == primary_ammo then
        if Player.items[weapon.type.mnemonic].count < 2 then
          secondary_ammo = nil
        end
      end
    end
    
    if not (weapon.type == "alien weapon") then
      if primary_ammo or secondary_ammo then
        env_draw(right_underlay, right_x, right_y)
      end
      
      -- primary trigger
      if primary_ammo then
        local ammo_x = right_x + (60*scale)
        local ammo_y = right_y + (135*scale)
        local ammo_w = 200*scale
        local ammo_h = 20*scale
        Screen.frame_rect(ammo_x, ammo_y, ammo_w, ammo_h,
                          env_adjust_glow({ 0.3, 0.6, 0.3, 1 }), math.floor(3*scale))
  
        local item = Player.items[primary_ammo]
  
        -- loaded rounds
        Screen.fill_rect(ammo_x, ammo_y,
                         math.floor(ammo_w * (wp.rounds / wp.total_rounds)),
                         ammo_h,
                         env_adjust_glow({ 0.3, 0.6, 0.3, 1 }))
        if string.find(item.singular, "[(]x" .. wp.total_rounds) or string.find(item.singular, "FLECHETTE") then
          local bw, bh = blg:measure_text(wp.rounds)
          blg:draw_text(wp.rounds,
                        right_x + 190*scale - bw,
                        right_y + 130*scale - bh,
                        env_adjust_glow({ 0.3, 0.6, 0.3, 1 }))
          
          bsm:draw_text("/" .. wp.total_rounds,
                        right_x + 190*scale,
                        right_y + 127*scale - bsmheight,
                        env_adjust_glow({ 0.3, 0.6, 0.3, 1 }))
        else
          percent = math.ceil(wp.rounds * 100 / wp.total_rounds)
          
          local bw, bh = blg:measure_text(percent)
          blg:draw_text(percent,
                        right_x + 190*scale - bw,
                        right_y + 130*scale - bh,
                        env_adjust_glow({ 0.3, 0.6, 0.3, 1 }))
          
          bsm:draw_text("%",
                        right_x + 190*scale,
                        right_y + 127*scale - bsmheight,
                        env_adjust_glow({ 0.3, 0.6, 0.3, 1 }))
        end
        
        -- item reserve
        if item.count > 0 then
          local bw, bh = bsm:measure_text("x" .. item.count)
          bsm:draw_text("x" .. item.count,
                        right_x + 190*scale - bw,
                        right_y + 90*scale - bh,
                        env_adjust_glow({ 0.3, 0.6, 0.3, 1 }))
        end
      end
  
      -- secondary trigger
      if secondary_ammo then
        local ammo_x = right_x + (60*scale)
        local ammo_y = right_y + (165*scale)
        local ammo_w = 200*scale
        local ammo_h = 20*scale
        Screen.frame_rect(ammo_x, ammo_y, ammo_w, ammo_h,
                          env_adjust_glow({ 0.3, 0.6, 0.3, 1 }), math.floor(3*scale))
  
        local item = Player.items[secondary_ammo]
  
        -- loaded rounds
        local ammo_fill = math.floor(ammo_w * (ws.rounds / ws.total_rounds))
        Screen.fill_rect(ammo_x + (ammo_w - ammo_fill), ammo_y,
                         ammo_fill,
                         ammo_h,
                         env_adjust_glow({ 0.3, 0.6, 0.3, 1 }))
        if string.find(item.singular, "[(]x" .. ws.total_rounds) or string.find(item.singular, "FLECHETTE") then
          local bw, bh = blg:measure_text(ws.rounds)
          blg:draw_text(ws.rounds,
                        right_x + 190*scale - bw,
                        right_y + 185*scale,
                        env_adjust_glow({ 0.3, 0.6, 0.3, 1 }))
          
          bsm:draw_text("/" .. ws.total_rounds,
                        right_x + 190*scale,
                        right_y + 190*scale,
                        env_adjust_glow({ 0.3, 0.6, 0.3, 1 }))
        else
          percent = math.ceil(ws.rounds * 100 / ws.total_rounds)
          
          local bw, bh = blg:measure_text(percent)
          blg:draw_text(percent,
                        right_x + 190*scale - bw,
                        right_y + 185*scale,
                        env_adjust_glow({ 0.3, 0.6, 0.3, 1 }))
          
          bsm:draw_text("%",
                        right_x + 190*scale,
                        right_y + 190*scale,
                        env_adjust_glow({ 0.3, 0.6, 0.3, 1 }))
        end
        
        -- item reserve
        if (item.count > 0) and not (primary_ammo == secondary_ammo) then
          local bw, bh = bsm:measure_text("x" .. item.count)
          bsm:draw_text("x" .. item.count,
                        right_x + 190*scale - bw,
                        right_y + 225*scale,
                        env_adjust_glow({ 0.3, 0.6, 0.3, 1 }))
        end
      end
      
      if primary_ammo or secondary_ammo then
        env_draw(right_overlay, right_x, right_y)
      end

    end  
  end
  

end

function Triggers.resize()

  if TexturePalette.resize() then return end

  Screen.clip_rect.width = Screen.width
  Screen.clip_rect.x = 0
  Screen.clip_rect.height = Screen.height
  Screen.clip_rect.y = 0

  Screen.map_rect.width = Screen.width
  Screen.map_rect.x = 0
  Screen.map_rect.height = Screen.height
  Screen.map_rect.y = 0
  
  local h = math.min(Screen.height, Screen.width / 1.5)
  local w = math.min(Screen.width, h*2)
  Screen.world_rect.width = w
  Screen.world_rect.x = (Screen.width - w)/2
  Screen.world_rect.height = h
  Screen.world_rect.y = (Screen.height - h)/2
  
  h = math.min(Screen.height, Screen.width / 2)
  w = h*2
  Screen.term_rect.width = w
  Screen.term_rect.x = (Screen.width - w)/2
  Screen.term_rect.height = h
  Screen.term_rect.y = (Screen.height - h)/2

  sx = Screen.world_rect.x
  sy = Screen.world_rect.y
  sw = Screen.world_rect.width
  sh = Screen.world_rect.height
    
  scale = sh/1080

  deja = Fonts.new{file = "dejavu/DejaVuLGCSansCondensed-Bold.ttf", size = scale * 22.5, style = 0}
  dejawidth, dejaheight = deja:measure_text("  ")
  
  blg = Fonts.new{file = "squarishsans/Squarish_Sans_CT_Medium.ttf", size = scale * 45, style = 0}
  blgwidth, blgheight = blg:measure_text("  ")
  bsm = Fonts.new{file = "squarishsans/Squarish_Sans_CT_Medium.ttf", size = scale * 30, style = 0}
  bsmwidth, bsmheight = bsm:measure_text("  ")

  rescale(left_underlay)
  rescale(left_overlay)
  rescale(compass)
  rescale(northeast)
  rescale(southeast)
  rescale(northwest)
  rescale(southwest)
  rescale(right_underlay)
  rescale(right_overlay)
  rescale(top_underlay)
  rescale(top_overlay)
end

function Triggers.init()
  colortable = { slate  = { 0.0, 0.4, 0.8, 0.6 },
                 red    = { 0.8, 0.0, 0.0, 0.6 },
                 violet = { 0.8, 0.0, 0.4, 0.6 },
                 yellow = { 0.8, 0.8, 0.0, 0.6 },
                 white  = { 0.8, 0.8, 0.8, 0.6 },
                 orange = { 0.8, 0.4, 0.0, 0.6 },
                 blue   = { 0.0, 0.0, 0.8, 0.6 },
                 green  = { 0.0, 0.8, 0.0, 0.6 } }
  
  left_underlay = Images.new{path = "resources/left_underlay.png"}
  left_overlay = Images.new{path = "resources/left_overlay.png"}
  compass = Images.new{path = "resources/compass.png"}
  northeast = Images.new{path = "resources/northeast.png"}
  southeast = Images.new{path = "resources/southeast.png"}
  northwest = Images.new{path = "resources/northwest.png"}
  southwest = Images.new{path = "resources/southwest.png"}
  right_underlay = Images.new{path = "resources/right_underlay.png"}
  right_overlay = Images.new{path = "resources/right_overlay.png"}
  top_underlay = Images.new{path = "resources/top_underlay.png"}
  top_overlay = Images.new{path = "resources/top_overlay.png"}

  Triggers.resize()
end

function clip(x, y, w, h)
  local rect = Screen.clip_rect
  rect.x = x
  rect.y = y
  rect.width = w
  rect.height = h
end

function unclip()
  local rect = Screen.clip_rect
  rect.x = 0
  rect.y = 0
  rect.width = Screen.width
  rect.height = Screen.height
end

function rescale(img)
  img:rescale(img.unscaled_width * scale, img.unscaled_height * scale)
end


function format_time(ticks)
   local secs = math.floor(ticks / 30)
   return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

function net_header()
  if Game.time_remaining then
    return format_time(Game.time_remaining)
  elseif Game.kill_limit then
    local max_kills = 0
    for i = 1,#Game.players do
      max_kills = math.max(max_kills, Game.players[i - 1].kills)
    end
    return string.format("%d", Game.kill_limit - max_kills)
  end
  return nil
end

function player_ranking_text(gametype, ranking)
  if     gametype == "kill monsters" or
         gametype == "capture the flag" or
         gametype == "rugby" or
         gametype == "most points" then
    return string.format("%d", ranking)
  elseif gametype == "least points" then
    return string.format("%d", -ranking)
  elseif gametype == "cooperative play" then
    return string.format("%d%%", ranking)
  elseif gametype == "most time" or
         gametype == "least time" or
         gametype == "king of the hill" or
         gametype == "kill the man with the ball" or
         gametype == "defense" or
         gametype == "tag" then
    return format_time(math.abs(ranking))
  end
  return nil
end

function sorted_players()
  local tbl = {}
  for i = 1,#Game.players do
    table.insert(tbl, Game.players[i - 1])
  end
  local sortfunc = function(a, b)
    if a.ranking ~= b.ranking then return a.ranking > b.ranking end
    return a.index < b.index
  end
  table.sort(tbl, sortfunc)
  return tbl
end

function env_light_setup()
  local ambient = Lighting.ambient_light
  local weapon = Lighting.weapon_flash
  local combined = math.min(1, ambient*2 + weapon)
  if weapon > ambient then
    combined = math.min(1, weapon*2 + ambient)
  end
  env_level = 0.5 + combined/2
  env_level_glow = 1 -- 0.75 + combined/4
  
  env_color = nil
  env_color_glow = nil
  if Lighting.liquid_fader.active and (Lighting.liquid_fader.type == "soft tint") then
    env_color = Lighting.liquid_fader.color
    env_color.a = env_color.a*0.67
    env_level = env_level * (1 - env_color.a)
    env_color.r = env_color.r * env_color.a
    env_color.g = env_color.g * env_color.a
    env_color.b = env_color.b * env_color.a
    
    env_color_glow = Lighting.liquid_fader.color
    env_color_glow.a = env_color_glow.a*0.33
    env_level_glow = env_level_glow * (1 - env_color_glow.a)
    env_color_glow.r = env_color_glow.r * env_color_glow.a
    env_color_glow.g = env_color_glow.g * env_color_glow.a
    env_color_glow.b = env_color_glow.b * env_color_glow.a
  end
end

function env_draw(img, x, y)
  if not img then return end
  tint_color = img.tint_color
  img.tint_color = env_adjust({ tint_color.r, tint_color.g, tint_color.b, tint_color.a })
  img:draw(x, y)
  img.tint_color = tint_color
end
function env_draw_glow(img, x, y)
  if not img then return end
  tint_color = img.tint_color
  img.tint_color = env_adjust_glow({ tint_color.r, tint_color.g, tint_color.b, tint_color.a })
  img:draw(x, y)
  img.tint_color = tint_color
end

function env_adjust(color)
  color[1] = color[1] * env_level
  color[2] = color[2] * env_level
  color[3] = color[3] * env_level
  if env_color then
    color[1] = color[1] + env_color.r
    color[2] = color[2] + env_color.g
    color[3] = color[3] + env_color.b
  end
  return color
end

function env_adjust_glow(color)
  color[1] = color[1] * env_level_glow
  color[2] = color[2] * env_level_glow
  color[3] = color[3] * env_level_glow
  if env_color_glow then
    color[1] = color[1] + env_color_glow.r
    color[2] = color[2] + env_color_glow.g
    color[3] = color[3] + env_color_glow.b
  end
  return color
end

-- BEGIN texture palette utility
--
-- Use: in Triggers.draw: "if TexturePalette.draw() then return end"
--    in Triggers.resize: "if TexturePalette.resize() then return end"

TexturePalette = {}
TexturePalette.active = false

function TexturePalette.check_active()
  local old_active = TexturePalette.active
  local new_active = false
  if Player.texture_palette.size > 0 then new_active = true end
  TexturePalette.active = new_active

  if old_active and not new_active then
    Screen.crosshairs.lua_hud = TexturePalette.saved_crosshairs_lua_hud
    Triggers.resize()
  elseif new_active and not old_active then
    TexturePalette.palette_cache = {}
    TexturePalette.saved_crosshairs_lua_hud = Screen.crosshairs.lua_hud
    Screen.crosshairs.lua_hud = false
    TexturePalette.resize()
  end
  return TexturePalette.active
end

function TexturePalette.get_shape(slot)
  local key = string.format("%d %d", slot.collection, slot.texture_index)
  local shp = TexturePalette.palette_cache[key]
  if not shp then
    shp = Shapes.new{collection = slot.collection, texture_index = slot.texture_index, type = slot.type}
    TexturePalette.palette_cache[key] = shp
  end
  return shp
end

function TexturePalette.draw_shape(slot, x, y, size)
  local shp = TexturePalette.get_shape(slot)
  if not shp then return end
  if shp.width > shp.height then
    shp:rescale(size, shp.unscaled_height * size / shp.unscaled_width)
    shp:draw(x, y + (size - shp.height)/2)
  else
    shp:rescale(shp.unscaled_width * size / shp.unscaled_height, size)
    shp:draw(x + (size - shp.width)/2, y)
  end
end

function TexturePalette.draw(hr)
  if not TexturePalette.check_active() then return false end

  local hr = TexturePalette.hud_rect
  local tcount = Player.texture_palette.size
  local size
  if     tcount <=   5 then size = 128
  elseif tcount <=  16 then size =  80
  elseif tcount <=  36 then size =  53
  elseif tcount <=  64 then size =  40
  elseif tcount <= 100 then size =  32
  elseif tcount <= 144 then size =  26
  else                      size =  20
  end
  size = size * hr.scale

  local rows = math.floor(hr.height/size)
  local cols = math.floor(hr.width/size)
  local x_offset = hr.x + (hr.width - cols * size)/2
  local y_offset = hr.y + (hr.height - rows * size)/2

  for i = 0,tcount - 1 do
    TexturePalette.draw_shape(
      Player.texture_palette.slots[i],
      (i % cols) * size + x_offset + hr.scale/2,
      math.floor(i / cols) * size + y_offset + hr.scale/2,
      size - hr.scale)
  end

  if Player.texture_palette.highlight then
    local i = Player.texture_palette.highlight
    Screen.frame_rect(
      (i % cols) * size + x_offset,
      math.floor(i / cols) * size + y_offset,
      size, size,
      InterfaceColors["inventory text"],
      hr.scale)
  end

  return true
end

function TexturePalette.resize()
  if not TexturePalette.check_active() then return false end

  local ww = Screen.width
  local wh = Screen.height

  -- calculate HUD area
  TexturePalette.hud_rect = {}
  local hudsize = Screen.hud_size_preference
  TexturePalette.hud_rect.width = 640
  if hudsize == SizePreferences["double"] then
    if wh >= 960 and ww >= 1280 then
      TexturePalette.hud_rect.width = 1280
    end
  elseif hudsize == SizePreferences["largest"] then
    TexturePalette.hud_rect.width = math.min(ww, math.max(640, (4 * wh) / 3));
  end

  TexturePalette.hud_rect.height = TexturePalette.hud_rect.width / 4
  TexturePalette.hud_rect.x = math.floor((ww - TexturePalette.hud_rect.width) / 2)
  TexturePalette.hud_rect.y = math.floor(wh - TexturePalette.hud_rect.height)

  TexturePalette.hud_rect.scale = TexturePalette.hud_rect.width / 640

  -- remove HUD height from rest of calculations
  wh = TexturePalette.hud_rect.y

  -- calculate terminal area
  local termsize = Screen.term_size_preference
  Screen.term_rect.width = 640
  if termsize == SizePreferences["double"] then
    if wh >= 640 and ww >= 1280 then
      Screen.term_rect.width = 1280
    end
  elseif termsize == SizePreferences["largest"] then
    Screen.term_rect.width = math.min(ww, math.max(640, 2 * wh))
  end

  Screen.term_rect.height = Screen.term_rect.width / 2
  Screen.term_rect.x = math.floor((ww - Screen.term_rect.width) / 2)
  Screen.term_rect.y = math.floor((wh - Screen.term_rect.height) / 2)

  -- calculate world-view area
  Screen.world_rect.width = math.min(ww, math.max(640, 2 * wh))
  Screen.world_rect.height = Screen.world_rect.width / 2
  Screen.world_rect.x = math.floor((ww - Screen.world_rect.width) / 2)
  Screen.world_rect.y = math.floor((wh - Screen.world_rect.height) / 2)

  -- calculate map area
  if Screen.map_overlay_active then
    -- overlay just matches world-view
    Screen.map_rect.width = Screen.world_rect.width
    Screen.map_rect.height = Screen.world_rect.height
    Screen.map_rect.x = Screen.world_rect.x
    Screen.map_rect.y = Screen.world_rect.y
  else
    Screen.map_rect.width = ww
    Screen.map_rect.height = wh
    Screen.map_rect.x = 0
    Screen.map_rect.y = 0
  end

  Screen.clip_rect.width = Screen.width
  Screen.clip_rect.height = Screen.height
  Screen.clip_rect.x = 0
  Screen.clip_rect.y = 0

  return true
end

-- END texture palette utility
