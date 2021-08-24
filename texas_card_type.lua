local DEBUG_CODE = true

--打印table
local dumpTb = function( t,info)  
    if not DEBUG_CODE then 
        return
    end
    if info then 
        print(info)
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

-- 方块 梅花 红桃 黑桃
local CARD_COLOR_TYPE = {
    DIAMOND = 1,
    CLUB = 2,
    HEART = 3,
    SPADE = 4 
}
--牌颜色类型文本
local CARD_COLOR_TYPE_TEXT = {
    [CARD_COLOR_TYPE.DIAMOND] = '方块',
    [CARD_COLOR_TYPE.CLUB] = '梅花',
    [CARD_COLOR_TYPE.HEART] = '红桃',
    [CARD_COLOR_TYPE.SPADE] = '黑桃',
}
--牌数字文本
local CARD_NUM_TEXT = {
    [1] = 'A',
    [2] = '2',
    [3] = '3',
    [4] = '4',
    [5] = '5',
    [6] = '6',
    [7] = '7',
    [8] = '8',
    [9] = '9',
    [10] = '10',
    [11] = 'J',
    [12] = 'Q',
    [13] = 'K',
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

--服务器下发的牌Sid转换为客户端牌Cid
local cardSid2Cid_ = function(cardSid_) 
    local hexCardNum_ = cardSid_
    local num = math.fmod(hexCardNum_,16) --取模 或者 hexCardNum_%16
    local color = math.modf(hexCardNum_/16) --取整 返回整数、余数

    local tmpNum = num == 1 and 14 or num -- 最小数值是2，最大数值是14(A)
    local resInt = (color - 1) * 13 + tmpNum --花色 0 - 3

    printValue('cardSid_:'..hexCardNum_..'->'..CARD_COLOR_TYPE_TEXT[color]..CARD_NUM_TEXT[num]..'=>'..resInt)
    return resInt
end
--客户端牌Cid转换为服务端牌Sid
local cardCid2Sid_ = function(cardCid_) 
    local num = math.fmod(cardCid_,13) --取模 或者 cardCid_%13
    local color = math.modf(cardCid_/13) --取整 返回整数、余数
    if num == 0 or num == 1 then 
        color = color - 1
        if num == 0 then 
            num = 13
        end
    end
    
    color = color + 1
    local tarHexNum = color * 16 + num

    printValue('cardCid_:'..cardCid_..'->'..CARD_COLOR_TYPE_TEXT[color]..CARD_NUM_TEXT[num]..'=>'..string.format("%#x",tarHexNum))
    return resInt
end
-- cardCid2Sid_(24)

local getCardTypeText = function (cardType_)
    printValue('牌型文本：'..CARD_TYPE_TEXT[cardType_])
    return CARD_TYPE_TEXT[cardType_]
end

local allCardsSidToCid_ = function(sids_,dstCids_)
    local allCards = dstCids_ or {}

    for i,v in ipairs(sids_) do 
        table.insert(allCards,cardSid2Cid_(v))
    end

    return allCards
end

--合并两个table
local mergeTb_ = function (tb1_,tb2_)
    local res = {}

    for _,V in pairs(tb1_) do 
        table.insert(res,V)
    end

    for _,V in pairs(tb2_) do 
        table.insert(res,V)
    end

    return res
end

--table 裁切子数组
local sliceTb_ = function (tarTb_,startIndex,endIndex_)
    local res = {}
    endIndex_ = endIndex_ or #tarTb_
    for index,value in ipairs(tarTb_) do 
        if index >= startIndex and index <= endIndex_ then 
            table.insert(res,value)
        end
    end
    -- dumpTb(res)
    return res
end

--获取牌型的内部方法
local getCardTypeInter_ = function (allCardsCid_) 
    local allCards = allCardsCid_ 
    local map = {}

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
    getCardTypeText(resType)
    return resType
end

local getCardType = function (holdCard_,publicCard_)
    local allCards = {}
    allCardsSidToCid_(holdCard_,allCards)
    allCardsSidToCid_(publicCard_,allCards)
    return getCardTypeInter_(allCards) 
end

local compareFun_ = function (objA_,objB_) 
    if not objA_ or not objB_ then 
        return false
    end 
    -- 为nil的情况必须返回false
    -- 相等的情况必须返回false (lua要求的坑点)
    return objA_.sortNum > objB_.sortNum 
end 

--检测table数组的长度是否超过默认5（顺子，高牌，同花，最多比较5张）
local checkTbLenThanX_ = function (tarTb_,xNum_)
    xNum_ = xNum_ or 5
    local tmp_len = #tarTb_
    if tmp_len > xNum_ then 
        for i = xNum_+1,tmp_len do 
            tarTb_[i] = nil
        end
    end
end

local analysisCardData_ = function(cids_)
    local res = {
        cidData = {},
        uniColor = {
            [0] = {},
            [1] = {},
            [2] = {},
            [3] = {}
        },
        smThourCards = {},
        smThreeCards = {},
        smSecondCards = {},
        smSingleCards = {},
    };
    local smCardData = {}
    for _,cidV in ipairs(cids_) do 
        local tmp_item = {
            rawCid = -1,
            num = -1,
            color = -1,
            sortNum = -1
        }
        tmp_item.rawCid = cidV
        
        local tmp_num = math.fmod(cidV,13) --取模 或者 hexCardNum_%16
        local tmp_color = math.modf(cidV/13) --取整 返回整数、余数
        if tmp_num == 0 or tmp_num == 1 then 
            tmp_color = tmp_color - 1
        end

        tmp_item.num = tmp_num
        tmp_item.color = tmp_color

        tmp_num = tmp_num == 0 and 13 or tmp_num
        tmp_num = tmp_num == 1 and 14 or tmp_num
      
        tmp_item.sortNum = tmp_num
        --
        table.insert(res.cidData,tmp_item)
        table.insert(res.uniColor[tmp_color],tmp_item)
        if  not smCardData[tmp_num] then 
            smCardData[tmp_num] = {}
        end
        table.insert(smCardData[tmp_num],tmp_item) 
    end

    for _,numObj in pairs(smCardData) do 
        if #numObj == 4 then 
            table.insert(res.smThourCards,numObj[1])
        elseif #numObj == 3 then 
            table.insert(res.smThreeCards,numObj[1])
        elseif #numObj == 2 then 
            table.insert(res.smSecondCards,numObj[1])
        elseif #numObj == 1 then 
            table.insert(res.smSingleCards,numObj[1])
        end 
    end

    table.sort(res.cidData,compareFun_)
    table.sort(res.smThourCards,compareFun_)
    table.sort(res.smThreeCards,compareFun_)
    table.sort(res.smSecondCards,compareFun_)
    table.sort(res.smSingleCards,compareFun_)
    table.sort(res.uniColor[0],compareFun_)
    table.sort(res.uniColor[1],compareFun_)
    table.sort(res.uniColor[2],compareFun_)
    table.sort(res.uniColor[3],compareFun_)

    -- for _,value in pairs(res) do 
    --     if type(value) == 'table' then 
    --         dumpTb(value);
    --     end
    -- end
    -- dumpTb(res.smSingleCards,'单牌：');
    return res
end

--牌值(逻辑牌值)比较
local sortNumCompare_ = function (cardData1_,cardData2_)
    for i = 1,#cardData1_ do 
        if cardData1_[i].sortNum > cardData2_[i].sortNum then 
            return 1
        elseif cardData1_[i].sortNum < cardData2_[i].sortNum then 
            return -1
        end
    end
    return 0
end

--获取最长的顺子(最多7张牌中)
local getMaxLengLink_ = function (cardData_)
    local tarRes = {}
    local lastCardNum_ = 0
   
    --首先判断有没有A
    if cardData_[1].sortNum == 14 then 
        table.insert(cardData_,shallow_copy(cardData_[1]))
    end

    for i=#cardData_ ,1,-1 do 
        if i == #cardData_ and cardData_[i].sortNum == 14 then 
            lastCardNum_ = 1
            table.insert(tarRes,cardData_[i])
        else 
            if cardData_[i].sortNum - lastCardNum_ == 1 or lastCardNum_ == 0 then 
                lastCardNum_ = cardData_[i].sortNum
                table.insert(tarRes,cardData_[i])
            elseif cardData_[i].sortNum - lastCardNum_ == 0 then 
            else 
                if #tarRes >= 5 then 
                    break
                end

                tarRes = {}
                lastCardNum_ = 0

                lastCardNum_ = cardData_[i].sortNum
                table.insert(tarRes,cardData_[i])
            end
        end
    end

    if #tarRes < 5 then 
        tarRes = {}
    end
  
    -- dumpTb(tarRes,'getMaxLengLink_:')
    return tarRes
end



--比较两个牌型大小 
-- 1： 手牌1 > 手牌2
-- -1： 手牌1 < 手牌2
-- 0： 手牌1 = 手牌2
local compareCardType = function(holdCard1_,holdCard2_,publicCard_)
    local allCards1 = {}
    local allCards2 = {}
    allCardsSidToCid_(holdCard1_,allCards1)
    allCardsSidToCid_(publicCard_,allCards1)
    allCardsSidToCid_(holdCard2_,allCards2)
    allCardsSidToCid_(publicCard_,allCards2)

    if DEBUG_CODE then 
        printValue('公共牌：')
        allCardsSidToCid_(publicCard_)
        printValue('手牌1：')
        allCardsSidToCid_(holdCard1_)
        printValue('手牌2：')
        allCardsSidToCid_(holdCard2_)
    end

    local cardType1 = getCardTypeInter_(allCards1)
    local cardType2 = getCardTypeInter_(allCards2)

    if cardType1 > cardType2 then 
        return 1
    elseif cardType1 < cardType2 then
        return -1
    else 
        local analysisData1 = analysisCardData_(allCards1)
        local analysisData2 = analysisCardData_(allCards2)

        if cardType1 == CARD_TYPE.STRAIGHT_FLUSH then 
            local tarColor 
            local uniColorTb = analysisData1.uniColor
            for i=0,3 do  
               if #uniColorTb[i] >= 5 then 
                   tarColor = i
                   break
               end
            end
            local maxLengLink1_ = getMaxLengLink_(analysisData1.uniColor[tarColor])
            local maxLengLink2_ = getMaxLengLink_(analysisData2.uniColor[tarColor])
            local tmpMaxLengLink1_ = sliceTb_(maxLengLink1_,#maxLengLink1_)
            local tmpMaxLengLink2_ = sliceTb_(maxLengLink2_,#maxLengLink2_)
            return sortNumCompare_(tmpMaxLengLink1_,tmpMaxLengLink2_) 
        elseif cardType1 == CARD_TYPE.FOUR_OF_A_KIND then
            return  sortNumCompare_(analysisData1.smThourCards,analysisData2.smThourCards)
        elseif cardType1 == CARD_TYPE.FULL_HOUSE then
             local smTC1_ = analysisData1.smThreeCards
             local smTC2_ = analysisData2.smThreeCards
             local smSC1_ = analysisData1.smSecondCards
             local smSC2_ = analysisData2.smSecondCards
             if #smTC1_ > 1 then 
                local tmp_tc1 = sliceTb_(smTC1_,2)
                smSC1_ = mergeTb_(smSC1_,tmp_tc1)
                table.sort(smSC1_,compareFun_)
                smTC1_ = sliceTb_(smTC1_,1,1)
             end
             if #smTC2_ > 1 then 
                local tmp_tc2 = sliceTb_(smTC2_,2)
                smSC2_ = mergeTb_(smSC2_,tmp_tc2)
                table.sort(smSC2_,compareFun_)
                smTC2_ = sliceTb_(smTC2_,1,1)
             end
             -- 比较
             local threeRes = sortNumCompare_(smTC1_,smTC2_)
             if threeRes ~= 0 then 
                 return threeRes
             else 
                 return sortNumCompare_(smSC1_,smSC2_) 
             end
        elseif cardType1 == CARD_TYPE.FLUSH then
             local tarColor 
             local uniColorTb = analysisData1.uniColor
             for i=0,3 do  
                if #uniColorTb[i] >= 5 then 
                    tarColor = i
                    break
                end
             end
             checkTbLenThanX_(analysisData1.uniColor[tarColor])
             checkTbLenThanX_(analysisData2.uniColor[tarColor])
             return sortNumCompare_(analysisData1.uniColor[tarColor],analysisData2.uniColor[tarColor]) 
        elseif cardType1 == CARD_TYPE.STRAIGHT then
             local maxLengLink1_ = getMaxLengLink_(analysisData1.cidData)
             local maxLengLink2_ = getMaxLengLink_(analysisData2.cidData)
             local tmpMaxLengLink1_ = sliceTb_(maxLengLink1_,#maxLengLink1_)
             local tmpMaxLengLink2_ = sliceTb_(maxLengLink2_,#maxLengLink2_)
             return sortNumCompare_(tmpMaxLengLink1_,tmpMaxLengLink2_) 
        elseif cardType1 == CARD_TYPE.THREE_OF_A_KIND then
            local threeRes = sortNumCompare_(analysisData1.smThreeCards,analysisData2.smThreeCards)
            if threeRes ~= 0 then 
                return threeRes
            else 
                checkTbLenThanX_(analysisData1.smSingleCards,2)
                checkTbLenThanX_(analysisData2.smSingleCards,2)
                return sortNumCompare_(analysisData1.smSingleCards,analysisData2.smSingleCards) 
            end
        elseif cardType1 == CARD_TYPE.TWO_PAIRS then
            local smSC1_ = analysisData1.smSecondCards
            local smSC2_ = analysisData2.smSecondCards
            if #smSC1_ > 2 then 
                local tmp_sc1 = sliceTb_(smSC1_,3)
                analysisData1.smSingleCards = mergeTb_(analysisData1.smSingleCards,tmp_sc1)
                table.sort(analysisData1.smSingleCards,compareFun_)
                smSC1_ = sliceTb_(smSC1_,1,2)
            end
            if #smSC2_ > 2 then 
                local tmp_sc2 = sliceTb_(smSC2_,3)
                analysisData2.smSingleCards = mergeTb_(analysisData2.smSingleCards,tmp_sc2)
                table.sort(analysisData2.smSingleCards,compareFun_)
                smSC2_ = sliceTb_(smSC2_,1,2)
            end
            
            local pairRes = sortNumCompare_(smSC1_,smSC2_)
            if pairRes ~= 0 then 
                return pairRes
            else 
                checkTbLenThanX_(analysisData1.smSingleCards,1)
                checkTbLenThanX_(analysisData2.smSingleCards,1)
                return sortNumCompare_(analysisData1.smSingleCards,analysisData2.smSingleCards) 
            end
        elseif cardType1 == CARD_TYPE.PAIR then
            local pairRes = sortNumCompare_(analysisData1.smSecondCards,analysisData2.smSecondCards)
            if pairRes ~= 0 then 
                return pairRes
            else 
                checkTbLenThanX_(analysisData1.smSingleCards,3)
                checkTbLenThanX_(analysisData2.smSingleCards,3)
                return sortNumCompare_(analysisData1.smSingleCards,analysisData2.smSingleCards) 
            end

        elseif cardType1 == CARD_TYPE.HIGH_CARD then
            checkTbLenThanX_(analysisData1.smSingleCards)
            checkTbLenThanX_(analysisData2.smSingleCards)
            return sortNumCompare_(analysisData1.smSingleCards,analysisData2.smSingleCards) 
        end
    end 
end


--测试牌型方法
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
--测试比牌
local testCompareFun_ = function()
    local allCardsTb = {
        {
            holdCards = {0x11,0x12},
            holdCards2 = {0x13,0x14},
            publicCards =  {0x1a,0x1b,0x1c,0x22,0x25}
        },
        {
            holdCards = {0x11,0x27},
            holdCards2 = {0x26,0x14},
            publicCards =  {0x12,0x13,0x14,0x15,0x17}
        },
    }
    for _,value in ipairs(allCardsTb) do 
        local res = compareCardType(value['holdCards'],value['holdCards2'],value['publicCards'])
        print('比牌结果:'..res)
    end
end

testCompareFun_()
return {
    CARD_COLOR_TYPE = CARD_COLOR_TYPE,  --牌颜色枚举
    CARD_TYPE = CARD_TYPE,              --牌型枚举
    CARD_TYPE_TEXT = CARD_TYPE_TEXT,    --牌型文本枚举
    getCardType = getCardType,          --获取牌型的方法
    getCardTypeText = getCardTypeText   --获取牌型文本的方法
}

