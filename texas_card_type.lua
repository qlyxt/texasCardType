local DEBUG_CODE = true

--打印table
local dumpTb = function( t )  
    if not DEBUG_CODE then 
        return
    end
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end
--打印value
local printValue = function(...)
    if not DEBUG_CODE then 
        return 
    end
    print(...)
end
--深copy
local function deep_copy(orig)
    local copy
    if type(orig) == "table" then
      copy = {}
      for orig_key, orig_value in next, orig, nil do
        copy[deep_copy(orig_key)] = deep_copy(orig_value)
      end
      setmetatable(copy, deep_copy(getmetatable(orig)))
    else
      copy = orig
    end
    return copy
end
--浅copy
local function shallow_copy(orig)
    local copy
    if type(orig) == "table" then
      copy = {}
      for orig_key, orig_value in pairs(orig) do
        copy[orig_key] = orig_value
      end
    else -- number, string, boolean, etc
      copy = orig
    end
    return copy
end

-- 方块  梅花 红桃 黑桃
local CARD_COLOR_TYPE = {
    FANG_KUAI = 1,
    MEI_HUA = 2,
    HONG_TAO = 3,
    HEI_TAO = 4
}
--牌颜色类型文本
local CARD_COLOR_TYPE_TEXT = {
    [CARD_COLOR_TYPE.FANG_KUAI] = '方块',
    [CARD_COLOR_TYPE.MEI_HUA] = '梅花',
    [CARD_COLOR_TYPE.HONG_TAO] = '红桃',
    [CARD_COLOR_TYPE.HEI_TAO] = '黑桃',
}
-- 牌型
local CARD_TYPE = {
    ROYAL_STRAIGHT_FLUSH = 9, 
    STRAIGHT_FLUSH = 8,
    FOUR_OF_A_KIND = 7,
    FULL_HOUSE = 6,
    FLUSH = 5,
    STRAIGHT = 4,
    THREE_OF_A_KIND = 3,
    TWO_PAIRS = 2,
    PAIR = 1,
    HIGH_CARD = 0,
    NONE = -1,
}
--牌型文本
local CARD_TYPE_TEXT = {
    [CARD_TYPE.ROYAL_STRAIGHT_FLUSH] = '皇家同花顺',
    [CARD_TYPE.STRAIGHT_FLUSH] = '同花顺',
    [CARD_TYPE.FOUR_OF_A_KIND] = '四条',
    [CARD_TYPE.FULL_HOUSE] = '葫芦',
    [CARD_TYPE.FLUSH] = '同花',
    [CARD_TYPE.STRAIGHT] = '顺子',
    [CARD_TYPE.THREE_OF_A_KIND] = '三条',
    [CARD_TYPE.TWO_PAIRS] = '两对',
    [CARD_TYPE.PAIR] = '对子',
    [CARD_TYPE.HIGH_CARD] = '高牌',
}

-- dumpTb(CARD_TYPE)
-- dumpTb(CARD_TYPE_TEXT)

local hexToIntForCardNum_ = function(hexCardNum_)
    local num = math.fmod(hexCardNum_,16) --取模 或者 hexCardNum_%16
    local color = math.modf(hexCardNum_/16) --取整 返回整数、余数

    local tmpNum = num == 1 and 14 or num -- 最小数值是2，最大数值是14(A)
    local resInt = (color - 1) * 13 + tmpNum

    printValue('hexCardNum:'..hexCardNum_..'->'..CARD_COLOR_TYPE_TEXT[color]..num..'=>'..resInt)
    return resInt
end

local getCardTypeText = function (cardType_)
    printValue('牌型文本：'..CARD_TYPE_TEXT[cardType_])
    return CARD_TYPE_TEXT[cardType_]
end

local getCardType = function (holdCard_,publicCard_)
    local map = {}
    local allCards = {}

    for i,v in ipairs(holdCard_) do 
        table.insert(allCards,hexToIntForCardNum_(v))
    end
    for i,v in ipairs(publicCard_) do 
        table.insert(allCards,hexToIntForCardNum_(v))
    end
    dumpTb(allCards)  
   
    for i = 2,54 do 
        map[i]= false
    end

    for i,v in ipairs(allCards) do 
        map[v] = true
    end

    local colorCountTb = {}  --每个花色的张数
    local colorLinkMaxTb = {} --每个花色的最大连接数
    local uniColorCountMax = 0 --全局同花色张数的最大值
    local uniColorLinkMax = 0 --全局同颜色连接数的最大值
    for colorV = 0,4 do 
        local tmp_count = 0;
		local tmp_link = 0;
		local tmp_link_Max = 0;
        for numV = 1,14 do 
            local has_card = false
            if numV == 1 then 
                -- 考虑 A2345的情况
                has_card = map[14 + colorV * 13]
            else 
                has_card = map[numV + colorV * 13]
            end
           
           if has_card then 
                tmp_link = tmp_link + 1
                tmp_link_Max = math.max(tmp_link,tmp_link_Max)
                if numV ~= 1 then 
                    tmp_count = tmp_count + 1
                end
            else 
                tmp_link = 0
            end
        end
        colorCountTb[colorV] = tmp_count
        colorLinkMaxTb[colorV] = tmp_link_Max
    end
    for colorV = 0,4 do
        uniColorCountMax = math.max(colorCountTb[colorV],uniColorCountMax)
        uniColorLinkMax = math.max(colorLinkMaxTb[colorV],uniColorLinkMax)
    end


    local numLinkMax = 0 --最大的数字连接长度
    local sameNumTb = {} --每个数字重复的次数
    local tmp_num_link_max = 0
    for numV = 1,14 do 
        local tmp_count = 0
        local tmp_has_card = false
        for colorV = 0,4 do 
            local has_card = false
            if numV == 1 then 
                has_card = map[14 + colorV * 13]
            else 
                has_card = map[numV + colorV * 13]
            end
            if has_card then 
                tmp_has_card = true
                tmp_count = tmp_count + 1
            end
        end

        if numV ~= 1 then 
            sameNumTb[numV] = tmp_count
        end
        
        if tmp_has_card then 
            tmp_num_link_max = tmp_num_link_max + 1
            numLinkMax = math.max(tmp_num_link_max,numLinkMax)
        else 
            tmp_num_link_max = 0
        end
    end

    --全局相同数字的张数的第一大值和第二大值
    local uniSameNumMaxFirst = 0
    local uniSameNumMaxSecond = 0
    for numV = 2,14 do 
        if sameNumTb[numV] >= uniSameNumMaxFirst then 
            uniSameNumMaxSecond = uniSameNumMaxFirst
            uniSameNumMaxFirst = sameNumTb[numV]
        elseif sameNumTb[numV] >= uniSameNumMaxSecond then
            uniSameNumMaxSecond = sameNumTb[numV]
        end
    end

    --返回结果
    local resType = CARD_TYPE.NONE;
    if uniColorLinkMax >= 5 then 
        --皇家同花顺 或 同花顺
        --如果有同色AKQ 又是同花顺，那一定是皇家同花顺
        if (map[14] and map[13] and map[12] or 
            map[14 + 13] and map[13 + 13] and map[12 + 13] or
            map[14 + 26] and map[13 + 26] and map[12 + 26] or
            map[14 + 39] and map[13 + 39] and map[12 + 39])
        then 
            resType = CARD_TYPE.ROYAL_STRAIGHT_FLUSH;
        else 
            resType = CARD_TYPE.STRAIGHT_FLUSH;
        end
    elseif uniSameNumMaxFirst == 4 then 
        --四条
        resType = CARD_TYPE.FOUR_OF_A_KIND
    elseif uniSameNumMaxFirst == 3 and uniSameNumMaxSecond >=2 then 
        --葫芦
        resType = CARD_TYPE.FULL_HOUSE
    elseif uniColorCountMax >= 5 then 
        --同花
        resType = CARD_TYPE.FLUSH
    elseif numLinkMax >= 5 then 
        --顺子
        resType = CARD_TYPE.STRAIGHT
    elseif uniSameNumMaxFirst == 3 then 
        --三条
        resType = CARD_TYPE.THREE_OF_A_KIND
    elseif uniSameNumMaxFirst == 2 and uniSameNumMaxSecond == 2  then 
        --两对
        resType = CARD_TYPE.TWO_PAIRS
    elseif uniSameNumMaxFirst == 2 then 
        --对子
        resType = CARD_TYPE.PAIR
    else 
        --高牌
        resType = CARD_TYPE.HIGH_CARD
    end

    printValue('牌型:'..resType)
    return resType
end


--测试方法
local testFun_ = function()
    --方块  梅花 红桃 黑桃
    --方块 0x11 0x12 0x13 ....... 0x1a 0x1b 0x1c 0x1d
    --梅花 0x21 0x22 0x23 ....... 0x2a 0x2b 0x2c 0x2d
    --红桃 0x31 0x32 0x33 ....... 0x3a 0x3b 0x3c 0x3d
    --黑桃 0x41 0x42 0x43 ....... 0x4a 0x4b 0x4c 0x4d
    local allCardsTb = {
        {
            holdCards = {0x11,0x12},
            publicCards =  {0x1a,0x1b,0x1c}
        },
        {
            holdCards = {0x21,0x12},
            publicCards =  {0x13,0x14,0x15}
        },
        {
            holdCards = {0x21,0x12},
            publicCards =  {}
        },
        {
            holdCards = {0x21,0x12},
            publicCards =  {0x23,0x24,0x22,0x32}
        },
    }
    for _,value in ipairs(allCardsTb) do 
        local cardType = getCardType(value['holdCards'],value['publicCards'])
        getCardTypeText(cardType)
    end
end 

-- testFun_()


return {
    CARD_COLOR_TYPE = CARD_COLOR_TYPE,  --牌颜色枚举
    CARD_TYPE = CARD_TYPE,              --牌型枚举
    CARD_TYPE_TEXT = CARD_TYPE_TEXT,    --牌型文本枚举
    getCardType = getCardType,          --获取牌型的方法
    getCardTypeText = getCardTypeText   --获取牌型文本的方法
}

