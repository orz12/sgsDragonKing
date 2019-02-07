module("extensions.DragonKing", package.seeall)
extension = sgs.Package("DragonKing")

Nidhogg = sgs.General(extension, "Nidhogg", "god", 3)
DKzengyi = sgs.CreateMaxCardsSkill{
	name = "DKzengyi",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			return target:getHp() - target:getMark("DKzhenfen_debuff")
		--else
		--	return 1
		end
	end
}

DKdousheng = sgs.CreateTriggerSkill{
	name = "DKdousheng" ,
	events = {sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and use.card:getSuit() == sgs.Card_Diamond then
				player:gainMark("@doushengMark", 2)
			end
		elseif event == sgs.CardResponded then
			local response = data:toCardResponse()
			if response.m_isUse then
				if response.m_card and response.m_card:getHandlingMethod() == sgs.Card_MethodUse and response.m_card:getSuit() == sgs.Card_Diamond then
					player:gainMark("@doushengMark", 2)
				end
			end
		elseif player:getPhase() == sgs.Player_RoundStart then
			player:gainMark("@doushengMark", 2)
		end
		return false
	end
}

DKzhenfenCard = sgs.CreateSkillCard{
	name = "DKzhenfenCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets < player:getMark("@doushengMark")
	end,
	--on_effect = function(self, effect)
	--	effect.from:loseMark("@doushengMark")
	--	effect.to:drawCards(1,"DKzhenfen")
	--end
	on_use = function(self, room, source, targets)
		source:loseMark("@doushengMark",#targets)
		for _, p in ipairs(targets) do
			p:drawCards(1,"DKzhenfen")
		end
		--source:gainMark("DKzhenfen_debuff",#targets)
		source:addMark("DKzhenfen_debuff",#targets)
	end
}
DKzhenfenVS = sgs.CreateZeroCardViewAsSkill{
	name = "DKzhenfen",
	response_pattern = "@@DKzhenfen",
	view_as = function()
		return DKzhenfenCard:clone()
	end
}
DKzhenfen = sgs.CreateTriggerSkill{
	name = "DKzhenfen",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd, sgs.EventPhaseChanging},
	view_as_skill = DKzhenfenVS,
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseEnd and player:getMark("@doushengMark") > 0 and player:getPhase() == sgs.Player_Draw then
			local room = player:getRoom()
			room:askForUseCard(player, "@@DKzhenfen", "@DKzhenfen")
		elseif event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive then
			player:loseAllMarks("DKzhenfen_debuff")
		end
		return false
	end
}
DKhaojieCard = sgs.CreateSkillCard{
	name = "DKhaojieCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, Self)
		return to_select:getHp() > 1
	end,
	on_use = function(self, room, source, targets)
		source:loseMark("@doushengMark",10)
		for _, p in ipairs(targets) do
			room:loseHp(p)
		end
	end
}
DKhaojie = sgs.CreateZeroCardViewAsSkill{
	name = "DKhaojie" ,
	view_as = function(self, card)
		return DKhaojieCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return player:getMark("@doushengMark") > 9 and not player:hasUsed("#DKhaojieCard")
	end
}
Nidhogg:addSkill(DKzengyi)--增益
Nidhogg:addSkill(DKdousheng)--斗胜
Nidhogg:addSkill(DKzhenfen)--振奋
Nidhogg:addSkill(DKhaojie)--浩劫

Constantine = sgs.General(extension, "Constantine", "god", 3)

DKluanshi = sgs.CreateTriggerSkill{
	name = "DKluanshi" ,
	events = {sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseStart, sgs.GameStart} ,
	frequency = sgs.Skill_Compulsory ,
	on_trigger = function(self, event, player, data)
		if event == sgs.CardUsed then
			if player:getPhase() ~= sgs.Player_NotActive then return end
			local use = data:toCardUse()
			if use.card and use.card:getSuit() == sgs.Card_Heart then
				player:gainMark("@luanMark", 2)
			end
		elseif event == sgs.CardResponded then
			if player:getPhase() ~= sgs.Player_NotActive then return end
			local response = data:toCardResponse()
			if response.m_isUse then
				if response.m_card and response.m_card:getHandlingMethod() == sgs.Card_MethodUse and response.m_card:getSuit() == sgs.Card_Heart then
					player:gainMark("@luanMark", 2)
				end
			end
		elseif event == sgs.GameStart then
			player:gainMark("@luanMark", 2)
		elseif player:getPhase() == sgs.Player_RoundStart then
			player:gainMark("@luanMark", 2)
		end
		return false
	end
}

DKchongsheng = sgs.CreateTriggerSkill{
	name = "DKchongsheng",
	events = {sgs.Death, sgs.TurnedOver} ,
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
			death.who:loseAllMarks("jiuzhi_used")
			if death.who:objectName() == player:objectName() or player:getMark("@luanMark") < 12 or not player:faceUp() then return end
			if room:askForSkillInvoke(player, self:objectName()) then
				player:loseMark("@luanMark", 12)
				player:turnOver()
				local ally = sgs.QVariant()
				ally:setValue(death.who)
				room:setPlayerProperty(player, "wait_for_reviving", ally)
			end
		else
			local ally = player:property("wait_for_reviving"):toPlayer()
			if ally ~= nil then
				room:revivePlayer(ally)
				room:setPlayerProperty(ally, "hp", sgs.QVariant(math.min(3, ally:getMaxHp())))

				local log = sgs.LogMessage()
				log.type = "#Revive"
				log.from = ally
				room:sendLog(log)
		        ally:drawCards(2)
				room:setPlayerProperty(player, "wait_for_reviving", sgs.QVariant())
			end
		end
	end,
	--can_trigger = function(self, player)
	--	return player ~= nil
	--end
}

DKjiuzhiCard = sgs.CreateSkillCard{
	name = "DKjiuzhiCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:isWounded()) and (to_select:getMark("jiuzhi_used") < 2)
	end,
	feasible = function(self, targets)
		if #targets == 1 then
			return targets[1]:isWounded() and targets[1]:getMark("jiuzhi_used") < 2
		end
		return #targets == 0 and sgs.Self:isWounded() and sgs.Self:getMark("jiuzhi_used") < 2
	end,
	on_use = function(self, room, source, targets)
		source:loseMark("@luanMark",5)
		local target = targets[1] or source
		local effect = sgs.CardEffectStruct()
		effect.card = self
		effect.from = source
		effect.to = target
		room:cardEffect(effect)
	end,
	on_effect = function(self, effect)
		local dest = effect.to
		dest:addMark("jiuzhi_used")
		local room = dest:getRoom()
		local recover = sgs.RecoverStruct()
		recover.card = self
		recover.who = effect.from
		room:recover(dest, recover)
		dest:drawCards(1)
	end
}
DKjiuzhi = sgs.CreateZeroCardViewAsSkill{
	name = "DKjiuzhi", 
	view_as = function(self, card) 
		return DKjiuzhiCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return player:getMark("@luanMark") > 4-- and not player:hasUsed("#DKjiuzhiCard")
	end,
}

Constantine:addSkill(DKluanshi)
Constantine:addSkill(DKchongsheng)
Constantine:addSkill(DKjiuzhi)
