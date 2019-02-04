module("extensions.DragonKing", package.seeall)
extension = sgs.Package("DragonKing")

Nidhogg = sgs.General(extension, "Nidhogg", "god", 4)
DKzengyi = sgs.CreateMaxCardsSkill{
	name = "DKzengyi",
	extra_func = function(self, target)
		return target:getHp()
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
	on_effect = function(self, effect)
		effect.from:loseMark("@doushengMark")
		effect.to:drawCards(1,"DKzhenfen")
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
	events = {sgs.EventPhaseEnd},
	view_as_skill = DKzhenfenVS,
	can_trigger = function(self, player)
		return player:isAlive() and player:hasSkill(self:objectName()) and player:getMark("@doushengMark") > 0
			and player:getPhase() == sgs.Player_Draw
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:askForUseCard(player, "@@DKzhenfen", "@DKzhenfen")
		return false
	end
}
DKhaojieCard = sgs.CreateSkillCard{
	name = "DKhaojieCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, Self)
		return true
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