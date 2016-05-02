local RoundTimerTime = "RT_Timer"
local RoundTimerMode = "RT_Mode"

local EntNum = 1

if SERVER then

	function RT_StartTimer(time,mode)
		RT_Timer("setmode",mode)
		RT_Timer("set",time)
	end
	
	local NextThink = 0

	function RT_TimerThink(time)
		if NextThink <= RealTime() then

			local Timer = RT_Timer("get")
			local Mode = RT_Timer("getmode")
	
			RT_GetSounds(Timer,Mode)
		
			if Timer > 0 then
				RT_Timer("add",-1)
			else
			
			
				if Mode == "Deathmatch" then
				
					RT_StartTimer(10,"Round End") -- Leaderboard Phase
					-- SHOW LEADERBOARDS, FREEZE ALL PLAYERS, ENABLE SLOW MOTION
					RT_ShowScoreboard(true)
					RT_EnableSlowMotion(true)
					RT_EnableMovement(false)
					RT_AwardPlayers()					
					
				elseif Mode == "Round End" then
				
					RT_StartTimer(60,"Warm Up") -- Quick warump before match
					-- HIDE LEADERBOARDS, CLEANUP THE MAP, START THE WARMUP PHASE, UNFREEZE PLAYERS, DISABLE SLOW MOTION
					RT_ShowScoreboard(false)
					game.CleanUpMap()
					RT_RespawnPlayers()
					RT_EnableSlowMotion(false)
					RT_EnableMovement(true)

				elseif Mode == "Warm Up" then
				
					RT_StartTimer(10,"Round Start") -- Buy menu stage
					-- CLEANUP THE MAP, FREEZE ALL PLAYERS, START THE ROUND START COUNTDOWN
					
					game.CleanUpMap()
					RT_RespawnPlayers()
					timer.Simple(1, function()
						RT_EnableMovement(false)
					end)
					
				elseif Mode == "Round Start" then
				
					RT_PlaySound("ut/start2.wav","game")
					RT_StartTimer(120,"Deathmatch")
					-- UNFREEZE ALL PLAYERS
					RT_EnableMovement(true)
					
					--[[
					local Drone = ents.Create("dronesrewrite_walkart")
					Drone:SetPos(Vector(0,0,0))
					Drone:SetAngles(Angle(0,0,0))
					Drone.Owner = Entity(0)
					Drone:Spawn()
					Drone:Activate()
					Drone:AddModule("AI Attack")
					Drone:AddModule("AI Follow enemy")
					--]]
					
				end
				
			end
			
			NextThink = RealTime() + 1
			
		end
	end
	
	hook.Add("Think","RT_TimerThink",RT_TimerThink)
	
	function RT_ShowScoreboard(bool)
		for k,v in pairs(player.GetAll()) do
			if bool then
				v:SendLua("gmod.GetGamemode():ScoreboardShow()")
			else
				v:SendLua("gmod.GetGamemode():ScoreboardHide()")
			end
		end
	end
	
	function RT_EnableMovement(bool)
		for k,v in pairs(player.GetAll()) do
			if bool then
				v:UnLock()
			else
				v:Lock()
			end
		end
	end
	
	function RT_EnableSlowMotion(bool)
		if bool then
			game.SetTimeScale( 0.1 )
		else
			game.SetTimeScale( 1 )
		end
	end
	
	function RT_RespawnPlayers()
		for k,v in pairs(player.GetAll()) do
			v:SetFrags(0)
			v:SetDeaths(0)
			v:RemoveAllItems()
			v:Spawn()
		end
	end
	
	function RT_Commands(ply,cmd,args,argStr)
	
		if ply ~= Entity(EntNum) and ply:IsPlayer() and not ply:IsSuperAdmin() then
			return
		end

		if cmd == "starttimer" then
			RT_StartTimer(0,"Deathmatch")
		elseif cmd == "stoptimer" then
			RT_StartTimer(0,"Error")
		end
	
	end
	
	concommand.Add( "starttimer", RT_Commands )
	concommand.Add( "stoptimer", RT_Commands )
	
	local Sounds = {}
	
	Sounds[1] = "ut/cd1.wav"
	Sounds[2] = "ut/cd2.wav"
	Sounds[3] = "ut/cd3.wav"
	Sounds[4] = "ut/cd4.wav"
	Sounds[5] = "ut/cd5.wav"
	
	Sounds[6] = "ut/cd6.wav"
	Sounds[7] = "ut/cd7.wav"
	Sounds[8] = "ut/cd8.wav"
	Sounds[9] = "ut/cd9.wav"
	Sounds[10] = "ut/cd10.wav"
	
	Sounds[30] = "ut/cd30.wav"
	Sounds[58] = "#music"
	Sounds[60] = "ut/cd1min.wav"
	Sounds[180] = "ut/cd3min.wav"
	Sounds[300] = "ut/cd5min.wav"
	
	function RT_GetSounds(time,mode)
		
		time = time - 1
	
		if mode == "Deathmatch" or mode == "Round Start" then
			if Sounds[time] then
			
				local SoundToPlayer = Sounds[time]
				local SoundType = "game"
			
				if SoundToPlayer == "#music" then
					SoundToPlayer = "ut/music" .. math.random(1,4) .. ".mp3"
				end
			
				RT_PlaySound(SoundToPlayer,SoundType)	
				
			end
		end
	
	end
	
	util.AddNetworkString( "RT_NetworkSound" )
	
	function RT_PlaySound(sound,soundtype)
		net.Start("RT_NetworkSound")
			net.WriteString(sound)	
			--net.WriteString(soundtype)
		net.Broadcast()
	end
	
	function RT_AwardPlayers()

		local Scores = RT_GetScores()
		
		local PlayerCount = table.Count(Scores)
		
		for k,data in pairs(Scores) do
		
			local Multiplier = 0.5 + ( PlayerCount * 0.5 * (1/5) )
			local position = k
			local ply = data.ply
			local kills = data.kills
			local deaths = data.deaths
			
			if ply and ply:IsValid() then
				if position == 1 then
					SimpleXPAddXPText(ply,1000 * Multiplier,"1ST PLACE VICTORY",false)
				elseif position == 2 then
					SimpleXPAddXPText(ply,500 * Multiplier,"2ND PLACE VICTORY",false)
				elseif position == 3 then
					SimpleXPAddXPText(ply,250 * Multiplier,"3RD PLACE VICTORY",false)
				else
					SimpleXPAddXPText(ply,100 * Multiplier,"PARTICIPATION AWARD",false)
				end
			end

		end

	end
	
end

function RT_Timer(Method,Value)

	if not Method then
		Method = "none"
	end
	
	if not Value then
		if Method == "getmode" or Value == "setmode" then
			Value = "ERROR"
		else
			Value = 0
		end
	end

	Method = string.lower(Method)
	
	if type(Value) == "number" then
		Value = math.floor(Value)
	end

	local World = Entity(EntNum)
	
	if Method == "get" then
		return World:GetNWInt(RoundTimerTime,Value)
	elseif Method == "set" then
		return World:SetNWInt(RoundTimerTime,Value)
	elseif Method == "add" then
		return World:SetNWInt(RoundTimerTime,World:GetNWInt(RoundTimerTime,Value) + Value)
	elseif Method == "setmode" then
		return World:SetNWString(RoundTimerMode,Value)
	elseif Method == "getmode" then
		return World:GetNWString(RoundTimerMode,Value)
	end

end

function RT_GetScores()

	local Scores = {}

	for k,v in pairs(player.GetAll()) do
		 Scores[k] = {ply = v, kills = v:Frags(), deaths = v:Deaths()}
	end
	
	table.sort( Scores, 
		function( a, b )
			if a.kills == b.kills then
				return a.deaths < b.deaths
			else
				return a.kills > b.kills
			end
		end 
	)
	
	return Scores

end


if CLIENT then

	local Scores = nil
	
	net.Receive("RT_NetworkSound", function(len)
		local GetSound = net.ReadString()
		LocalPlayer():EmitSound(GetSound)
	end)
	
	function RT_DrawHud()
		local Mode = RT_Timer("getmode")
		local Time = RT_Timer("get")
		draw.DrawText( string.upper(Mode), "DermaLarge", ScrW() * 0.5, 0 + 25, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
		draw.DrawText( string.FormattedTime(Time, "%01i:%02i" ), "DermaLarge", ScrW() * 0.5, 0 + 25 + 25, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
	end
	
	hook.Add("HUDPaint","RT_DrawHud",RT_DrawHud)
	
end