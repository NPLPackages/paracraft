--[[
author:yangguiyi
date:
Desc:
use lib:
local SummerCampSignView = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampSignView.lua") 
SummerCampSignView.ShowView()
]]

local TeacherText = {
    "把一颗孝心献给敬爱的父母;把一颗诚心献给亲爱的朋友;把一颗爱心献给友爱的世界;把一颗忠心献给热爱的党。",
    "春花奔放，繁衍美丽的诗章;紫燕归巢，永恒幸福的畅想;神州盈绿，升腾和谐的暖阳;移动架虹，织成祝福的丝网;建党一百周年，我们同心共创新辉煌!",
    "春天带走伤感，夏天带走烦恼，秋天带走忧愁，冬天带走孤寂，党带来幸福与安祥!和平与辉煌!建党一百载让我们祝福祖国祝福党，繁荣昌盛，国泰民安!",
    "从弱小到强大，从改革到发展，从进步到文明，从繁荣到昌盛，每一步都踏实稳健，今朝建党一百华诞，共同祈福祖国明天更美好!",
    "诞生于南湖游船，犹如升起的朝阳。高擎镰刀斧头，率领华夏儿女奋勇向前。亿万中国同胞，演奏改革开放的交响，奋勇跨越新时代。党的生日，举国同庆!",
    "当家作主翻身起，为民办事谋福泽，经济繁荣节节升，科技强国国运昌。七一建党节，祝福党事业恢宏，前途无量!",
    "党啊，亲爱的母亲，您用慈母的胸怀，温暖着华夏儿女的心田;党啊，亲爱的母亲，您用坚强的臂膀，挽起了高山大海。今日是您的生日，作为您的儿女，我们向您表示最诚挚的敬意!",
    "党啊，是您艰苦奋斗，不惧艰难险阻，带领亿万华夏儿女创辉煌;是您风雨兼程，牢记为民宗旨，引导炎黄子孙图富强。七一将到，为党祝福，为祖国祝福。",
    "党的儿女浴血奋战，华夏改地换天展新颜，看今朝锦绣河山，青谷幽幽绿绵延，党指引我们大步跨前，携手共建美好明天。七月一日，让我们同庆建党一百年!",
    "党的生日，可喜可贺，阳光普照，敲鼓打锣，笑声阵阵，载舞载歌，感激党恩，祝福祖国，繁荣富强，万民福泽，齐心协力，共建和谐，你我共享，幸福生活!",
    "风儿吹开了你的和蔼可亲，花儿绽放了你的笑容可掬，流水荡涤了你的纤尘不染。亲爱的党，将最美好的祝福送给你，生日快乐!",
    "党为民，得民心，领着民众翻了身，永远不忘它的恩!一百华诞表表心，坚决拥护党，祝愿祖国永年轻。",
    "绘百年画卷，展神州风采;传千载文明，阅满目春色;铺千里琴台，奏国韵谐律;建党一百年，历艰辛卓绝;献亿万真心，道无限深情。",
    "火红七月艳阳照，党的生日已来到。锣鼓喧天情灿烂，普天同庆党华诞。举国欢畅歌飞扬，华夏儿女心向党。军民同心幸福扬，愿党光辉万年长。",
    "建党节到了，我们都是党的女儿，是党养育了我们，我们才有了今日幸福的生活。让我们一起努力，继续奋斗，为我们的祖国更加繁荣做出一番贡献!",
    "今日普天同庆，今日锣鼓喧天。在这歌飞扬，情意长的日子里，让我们把祝福送给党，祝党生日快乐，越来越好!",
    "流光溢彩七月天空，欢歌笑语七月大地，迎风飞舞党旗飘扬，幸福欢歌唱给党听，建党节，祈福祖国永远繁荣昌盛，人们生活永远和谐美满，祝党生日快乐。",
    "群众心，众志情，齐聚祖国共繁荣，时代变，祖国强，世纪新篇国运旺，千古史，万千情，辉煌早已胜李唐，幸福时，党生日，携你一起庆国强。",
    "那年那月那时钟，二万五千里长征!亿万将士血与泪，斗转星移筑长城，不是英雄知豪杰!怎有今日山青青!",
    "七一匆匆到，党旗高高飘，幸福的歌儿把你绕，党的生日到，欢天喜地幸福抱，党的恩情要记牢，坚定信念不动摇，建党节祝愿我们的党再创辉煌，人们幸福安康。",
    "七一的曙光照亮黑暗，七一的宣言指引方向。七一的脚步走向辉煌，七一的红旗热血飞扬。历经风雨，先河开创。富强的中国屹立东方。美好的歌声唱响：在党的引领下，祝愿祖国盛昌。",
    "七一建党节来到，党的精神要传到，党的呵护无限好，社会稳定安全保，生活富裕有温饱，事业干劲直线跑，祝福祖国祝福党，繁荣昌盛永辉煌。",
    "七一是党生日，信息传祝福，收到便快乐，祝福党祝福中国也祝福你;就在这欢庆的时刻，让我们一同高举杯盏共庆祝：我们伟大的党，生日快乐!",
    "七一是你的节日，也是我的节日，因为你是子弟，我是人们，我们因为有你们而自豪!",
    "七月党旗高飘扬，红歌唱响华夏情，全国人们拥护党，党的引领放光芒，创建和谐新社会，带领全民奔幸福，双手合十送祝福，愿党引领万年长，祖国腾飞更辉煌!",
    "七月党旗格外艳，党的引领光芒照，创建和谐谋发展，带领人们奔小康，幸福指数一路升，全民脸上笑开颜，建党节里祝福党，党的引领写辉煌!",
    "七月天最艳，七月情最炫，七月歌最甜，只为纪念党，岁岁又年年。在同享喜悦的时刻，特送上美好的祝愿，愿我们在党的引领下，一年更比一年强!",
    "七月一，建党节，为祖国，道声喜，愿祖国，永繁荣;为党员，送祝福，祝愿党，永光辉;为人们，默祈祷，望人们，永安定;把心愿，送给你，盼望你，永开心。",
    "时隔一百载，党的生日不忘怀，困苦中诞生，磨难中成长，不懈奋斗，勇于创新，继往开来，心系百姓，宗旨不改。七月一日建党节，让我们感党恩，跟党走，永奋进!",
    "收集南北壮美风光，捧起东西流水温情，拥抱长城内外雄风，采集和谐幸福春光，高举旗帜随风飘扬，建党一百年之际，同欢情，共祝福：祖国未来无限辉煌!",
    "谁带领我们翻身得解放?是党。谁带领我们改革开放走向繁荣富强?是党。风雨一百年从弱小到坚强，是党带领我们走向辉煌!",
    "五千年热情冲云霄，亿万个梦想缀山川。党徽映照快乐的脸，烟花绽放灿烂的天。华夏风采今胜昔，炎黄子孙谱新篇。",
    "心连心，忆峥嵘岁月，万众一心拥护党;手牵手，创辉煌历程，众志成城壮山河;肩并肩，看美丽今朝，日新月异盛世景。建党节，铭伟业，共享幸福!",
    "星星之火已燎原，希望种子撒人间，无所畏惧直往前，一百年巨大贡献，祝福献与党，上下越千年，辉煌到永远!建党100周年快乐寄语",
    "雄狮怒吼国人醒，华夏先辈洗耻辱，巨龙腾飞九州欢，党的光辉照华夏，春风千里人心暖，党旗飘扬国富强，建党一百周年祝党更强大，国更繁荣!",
    "雄狮一吼惊世界，党的英明民安乐，改革春风吹九州，人们幸福创和谐，神州冲天国强大，军民同乐共庆贺;党生日，祝福党再创辉煌!",
    "烟花迎空绽放，党的生日灿烂辉煌;红歌深情唱响，党的生日盛世华章;鲜花洋溢芬芳，党的生日无尚荣光;和谐激扬希望，党的生日万寿无疆!",
    "一把镰刀，收获国家富强，收获人们安康;一把铁锤，打造钢铁国防，打造幸福生活。七一建党节，有党生活充满阳光!",
    "一百年的崎岖坎坷，一百年的寻找真理，一百年的历经风雨，一百年的思考真谛，一百年的奋发崛起，一百年的壮大屹立，没有党的引领，哪有今日天地。",
    "一百年的辛酸、一百年的璀璨，惦记在心头。思念的滋味，心知道!温暖的感觉，我知晓!祝福的真诚，您明了!普天同庆齐燃烛，万众齐心共祝福：生日快乐!",
    "一百年中国共中国建党一百周，人人拥护人人爱。党员个个扛大梁，带领人们奔小康。祖国走上好道路，人们过上好日子。",
    "一百载风雨洗礼，一百载峥嵘岁月，一百载日夜兼程，一百载辉煌成就。借五星之荣耀，扬民众之风采，庆建党之壮举，祝华夏之豪迈。",
    "一个信念跟党走，颗颗红心报党恩，红红火火搞改革，心心相印求发展，永志不忘强国家，向前向前永向前，党的生日立丰碑。",
    "一湖春水半湖烟，船载星辉荡九天。东方鸡鸣天欲晓，风华赤子凯歌旋。天瑞雪压花枝开，万首清吟屏底栽。庆祝建党一百载，春风振振送馨来!",
    "以北方豪爽的口气，以南方婉约的语调，以西域爽朗的气魄，以东方开放的胸怀，说同一句话：七一到，党生日快乐，国长治久安!",
    "忆往昔，多艰难，党带领我们向前;看今朝，多幸福，感谢党的好引领。建党节到了，祝福送给党，愿党更美好!",
    "用红色渲染您的旗帜，用红色浇注您的历史，用红色浸染你的文化，用红色传承你的精神，用红色的建设来烙印全国。建党一百华诞，祝您永远红红火火!",
    "有了我们党，来了新生活;有了我们党，弱国变强国;有了我们党，经济大搞活;有了我们党，人们小康乐;紧跟我们党，民撑顺风舵。",
    "又是一个金色的年轮，又是一个丰收的七月，在这美好的日子里，我们又迎来了七一这个光辉的节日。今天我们共聚一堂热烈庆祝我们党的生日，向我们伟大的党献上我们诚挚的祝福。",
    "华夏民欢腾，处处尽芬芳;建党一百载，日月谱华章;神州傲苍穹，华夏硕果香;政党续和谐，挥笔写安康;各族歌盛世，红党旗飞扬!",
    "壮哉华夏阳光照，美哉华夏环境傲;创先争优展新貌，民生康阜生活好;和气荡漾文明耀，谐风顺畅平安到;一百建党竞相告，幸福社会人欢笑。",
    "自主创新，走在前头;特色道路，大有干头;和谐事业，理论牵头;科学发展，不栽跟头;党之精神，先锋带头;辉煌建设，再添劲头!",
    "江河千里，七月的丰碑耸立不朽，神州大地，一百年的党史辉煌灿烂。",
    "党的风采，照亮未来;党的光辉，铭记在心;党的形象，当作榜样;党的情怀，大放光彩。建党一百周年，愿我们的党更加壮大。	",
    "建党一百树红旗，镰刀斧头劈荆棘;改革开放创佳绩，奥运长志气;科学发展千钧力，巨龙腾飞更无敌;祝愿我党永不谢，盛世中国寿天齐。",
    "建党一百载辉煌，它永载史册，悠悠一百载，见证了您的足迹;一百年前，您历经沧桑，驶出胜利的航向;一百年来，您乘风破浪，抒写美丽的华章。",
    "一百年的风雨同舟共进退，一百年的艰苦奋斗相携手，一百年的不离不弃共努力，一百年的团结互助为拼搏。建党一百周年纪念日，祝愿祖国未来更精彩!",
    "国泰民安日子美，欣欣向荣民心安;经济繁荣百业兴，科技强国步步高。七一建党节，祝福党的明天永远灿烂，永远辉煌!",
    "建党节到了，愿你以党员的标准要求自己，充分发挥排头兵作用。坚定不移抓事业，千方百计促增收，聚精会神保健康，一心一意谋平安。祝建党节幸福快乐。",
    "一百载风风雨雨，党永葆绚丽风采;一百年革新奋进，党带领人们走向富裕。中国的进步有点滴印记，中国生活的美好有您步步努力，今天您的生日，华夏儿女祝福您。七月，是金黄的收获季节;七月，是满心感动的岁月;七月，是送出赞歌的时节。",
}
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local httpwrapper_version = HttpWrapper.GetDevVersion();
local SummerCampSignView = NPL.export()

local page = nil
function SummerCampSignView.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = SummerCampSignView.OnCreate
    page.OnClose = SummerCampSignView.CloseView
end

function SummerCampSignView.ShowView(close_cb)
    keepwork.sign_wall.get_my_greeting({}, function(err, message, data)
        -- print("vzzzzzzzzzzzzzzzzzzzzzzzzzzzz", err)
        -- echo(data, true)
        if err == 200 then
            SummerCampSignView.greeting_data = data.greeting
            SummerCampSignView.CloseCb = close_cb
            SummerCampSignView.InitData()

            local can_close = SummerCampSignView.CanClose()
            local view_width = 402
            local view_height = 445
            local params = {
                url = "script/apps/Aries/Creator/Game/Tasks/SummerCamp/SummerCampSignView.html",
                name = "SummerCampSignView.ShowView", 
                isShowTitleBar = false,
                DestroyOnClose = true,
                style = CommonCtrl.WindowFrame.ContainerStyle,
                allowDrag = can_close,
                enable_esc_key = can_close,
                zorder = 0,
                app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
                directPosition = true,
                align = "_ct",
                    x = -view_width/2,
                    y = -view_height/2,
                    width = view_width,
                    height = view_height,
            };
            System.App.Commands.Call("File.MCMLWindowFrame", params);
        end
    end)

end

function SummerCampSignView.OnCreate()
    -- local parent  = ParaUI.GetUIObject("summer_decode_wxcode_root")
    -- _this = ParaUI.CreateUIObject("text","text","_lt",0,0,110,200);
    -- _this.text = "哈哈哈哈哈哈哈哈哈哈"
    -- _this.textscale = 1 
    -- parent:AddChild(_this);

    if SummerCampSignView.greeting_data then
        local text = SummerCampSignView.greeting_data.content
        local textAreaCtrl = page:FindControl("sign_text");
        local show_text = SummerCampSignView.GetShowTeacherText(text)
        textAreaCtrl:SetText(show_text)
    end
end

function SummerCampSignView.InitData()

end

function SummerCampSignView.GetShowTeacherText(teacher_text)
    local limit_num = 23
    local len = ParaMisc.GetUnicodeCharNum(teacher_text);
    if len > limit_num then
        local begain_index = 1
        local end_index = begain_index + limit_num-1
        local result = ""
        while end_index < len do
            local text = ParaMisc.UniSubString(teacher_text, begain_index, end_index) or "";
            result = result .. text .. "\r\n"
            begain_index = end_index + 1
            end_index = begain_index + limit_num-1
        end

        if begain_index < len and end_index >= len then
            end_index = len
            local text = ParaMisc.UniSubString(teacher_text, begain_index, end_index) or "";
            result = result .. text .. "\r\n"
        end

        return result
    end
    
    return teacher_text
end

function SummerCampSignView.OnMouseOverWordChange(word, line, from, to)
end

function SummerCampSignView.OnTextChange(name, mcmlNode)
    -- local text = page:GetValue("sign_text") or "";
    -- text = string.gsub(text, "\r\n", "")

    -- local editbox = ParaUI.GetUIObject("summer_sign_code")

    -- local textAreaCtrl = page:FindControl("sign_text");
    -- local thisLine = ParaUI.GetUIObject(textAreaCtrl.RootNode:GetChild(1).editor_id)
    -- local pos = thisLine:GetCaretPosition();
    -- local width = thisLine:GetTextSize();
end

function SummerCampSignView.OnClickTeacher()
    local textAreaCtrl = page:FindControl("sign_text");
    local random_key = math.random(1, #TeacherText)

    local show_text = SummerCampSignView.GetShowTeacherText(TeacherText[random_key])
    textAreaCtrl:SetText(show_text)
end

function SummerCampSignView.OnClickCommit()
    local text = page:GetValue("sign_text") or "";
    text = string.gsub(text, "\r\n", "")
    if text == "" then
        GameLogic.AddBBS("sign_view", L"请输入文字", 5000, "255 0 0");
        return
    end
    -- greeting={
    --     content="壮哉华夏阳光照，美哉华夏环境傲;创先争优展新貌，民生康阜生活好;和气荡漾文明耀，谐风顺畅平安到;一百建党竞相告，幸福社会人欢笑。",
    --     createdAt="2021-06-28T08:01:50.000Z",
    --     id=1,
    --     updatedAt="2021-06-28T08:01:50.000Z",
    --     userId=1326 
    --   } 

    local len = ParaMisc.GetUnicodeCharNum(text)
    if len > 140 then
        GameLogic.AddBBS("sign_view", L"字数超过上限，请删减字数", 5000, "255 0 0");
        return
    end

    local greeting_data = SummerCampSignView.greeting_data
    if greeting_data then
        keepwork.sign_wall.change_greeting({
            router_params = {id = greeting_data.id},
            content = text,
        }, function(err, message, data)
            if err == 200 then
                page:CloseWindow();
                SummerCampSignView.CloseView()
                GameLogic.AddBBS("sign_view", L"修改成功", 5000, "0 255 0");
            elseif data and data.message then
                GameLogic.AddBBS("sign_view", data.message, 5000, "255 0 0");
            else
                GameLogic.AddBBS("sign_view", L"修改失败，请稍后重试", 5000, "255 0 0");
            end
        end)
    else
        keepwork.sign_wall.post_greeting({
            content = text,
        }, function(err, message, data)
            if err == 200 then
                page:CloseWindow();
                SummerCampSignView.CloseView()
                GameLogic.AddBBS("sign_view", L"提交成功", 5000, "0 255 0");
            elseif data and data.message then
                GameLogic.AddBBS("sign_view", data.message, 5000, "255 0 0");
            else
                GameLogic.AddBBS("sign_view", L"提交失败，请稍后重试", 5000, "255 0 0");
            end
        end)
    end

end

function SummerCampSignView.CloseView()
    if SummerCampSignView.CloseCb then
        SummerCampSignView.CloseCb()
    end
end

function SummerCampSignView.CanClose()
    return SummerCampSignView.greeting_data ~= nil
end

function SummerCampSignView.GetTeacherText()
    return TeacherText
end