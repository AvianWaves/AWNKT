--
-- Avian Waves NK2 Toolkit for Script-Based MIDI Control Surface (AWNKT)
--
-- Author: Avian Waves, LLC
-- Website: https://www.avianwaves.com
-- Project Repository: https://github.com/AvianWaves/AWNKT
-- License: Apache License, 2.0 - https://opensource.org/licenses/Apache-2.0
-- 

local path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = path .. "?.lua"
require("__AWNKT-Lib")

startTime = os.time()

function run()
  is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
  if is_new then
    local trackNum = tonumber(reaper.GetExtState("AvianWaves.AWNKT", "TrackRoot")) + 7
    AWNKT_SetTrackPan(trackNum, val)
  end
  
  local scriptDuration = tonumber(reaper.GetExtState("AvianWaves.AWNKT", "S_ScriptDuration"))
  local nowTime = os.time()
  local elapsedTime = os.difftime(nowTime, startTime)
  
  if elapsedTime < scriptDuration then
    reaper.defer(run)
  end
end

function onexit()
end

reaper.defer(run)
reaper.atexit(onexit)

-- reaper.ShowConsoleMsg(name .. " rel: " .. rel .. " res: " .. res .. " val = " .. val .. "\n")

