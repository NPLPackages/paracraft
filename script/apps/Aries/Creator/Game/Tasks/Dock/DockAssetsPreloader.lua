--[[
Title: DockAssetsPreloader
Author(s): leio
Date: 2020/10/29
Desc:  
Use Lib:
-------------------------------------------------------
local DockAssetsPreloader = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockAssetsPreloader.lua");
DockAssetsPreloader.Start();
--]]
NPL.load("(gl)script/ide/FileLoader.lua");
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/kids/3DMapSystemUI/MiniGames/SwfLoadingBarPage.lua");
local DockAssetsPreloader = NPL.export();

-- NOTE:this is generated by https://github.com/tatfook/ParacraftAssetList
-- don't change this by manuallly
local assets = {
  "Texture/Aries/Creator/keepwork/explorer_32bits.png",
  "Texture/Aries/Creator/keepwork/worldshare_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/biaoji_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/btn_beibao_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/btn_chuangzao_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/btn_haoyou_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/btn_home_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/btn_huiyuan_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/btn_renwu_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/btn_shangcheng_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/btn_tangsuo_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/btn_xitong_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/btn_xuexi_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/btn_xuexiao_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/btn_ziyuan_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/btn2_chengzhangrenwu_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/btn2_chengzhangriji_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/btn2_dasai_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/btn2_guanwang_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/btn2_ketang_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/btn2_shizhan_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/btn2_yonghushequ_32bits.png",
  "Texture/Aries/Creator/keepwork/dock/ditu_32bits.png",
  "Texture/Aries/Creator/keepwork/UserInfo/blue_v_32bits.png",
  "Texture/Aries/Creator/keepwork/UserInfo/crown_32bits.png",
  "Texture/Aries/Creator/keepwork/UserInfo/renwu_32bits.png",
  "Texture/Aries/Creator/keepwork/UserInfo/T_32bits.png",
  "Texture/Aries/Creator/keepwork/UserInfo/T_gray_32bits.png",
  "Texture/Aries/Creator/keepwork/UserInfo/V_32bits.png",
  "Texture/Aries/Creator/keepwork/UserInfo/V_gray_32bits.png",
  "Texture/Aries/Creator/keepwork/UserInfo/VT_32bits.png",
  "Texture/Aries/Creator/keepwork/UserInfo/VT_gray_32bits.png",
  "Texture/Aries/Creator/keepwork/Window/button/btn_huangse_32bits.png",
  "Texture/Aries/Creator/keepwork/Window/button/btn_huise_32bits.png",
  "Texture/Aries/Creator/keepwork/Window/button/btn_lvse_32bits.png",
  "Texture/Aries/Creator/keepwork/Window/dakuang_32bits.png",
  "Texture/Aries/Creator/keepwork/Window/dakuang2_32bits.png",
  "Texture/Aries/Creator/keepwork/Window/guanbi_32bits.png",
  "Texture/Aries/Creator/keepwork/Window/title/biaoti_32bits.png",
  "Texture/Aries/Creator/keepwork/Window/title/biaoti_beibao_32bits.png",
  "Texture/Aries/Creator/keepwork/Window/title/biaoti_chuangzao_32bits.png",
  "Texture/Aries/Creator/keepwork/Window/title/biaoti_haoyou_32bits.png",
  "Texture/Aries/Creator/keepwork/Window/title/biaoti_shangcheng_32bits.png",
  "Texture/Aries/Creator/keepwork/Window/title/biaoti_tansuo_32bits.png",
  "Texture/Aries/Creator/keepwork/Window/title/biaoti_tishi_32bits.png",
  "Texture/Aries/Creator/keepwork/Window/title/biaoti_vip_32bits.png",
  "Texture/Aries/Creator/keepwork/Window/title/biaoti_xitong_32bits.png",
  "Texture/Aries/Creator/keepwork/Window/title/biaoti_xuexi_32bits.png",
  "Texture/Aries/Creator/keepwork/Window/title/biaoti_xuexiao_32bits.png",
  "Texture/Aries/Creator/keepwork/Window/title/biaoti_ziyuan_32bits.png",
  "Texture/Aries/Creator/keepwork/Window/tooltip/tipbj_32bits.png",
  "Texture/Aries/Creator/keepwork/Window/tooltip/tipkuang_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/btn_guang_25X24_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/btn_shijie_84X23_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/btn_yinyue1_25X24_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/btn_yinyue2_25X24_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/dikuang_64X64_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/dikuang2_26X26_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/dikuang3_26X26_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/dikuang4_192X351_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/icon_bukexuan_24X24_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/icon_didian_12X15_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/icon_kexuan_24X24_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/icon_yiruzhu_24X24_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/icon_yixuan_24X24_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/number/1_15X14_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/number/10_15X14_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/number/2_15X14_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/number/3_15X14_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/number/4_15X14_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/number/5_15X14_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/number/6_15X14_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/number/7_15X14_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/number/8_15X14_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/number/9_15X14_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/tupiandi_32X32_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/tupiandi2_32X32_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/xuanzhong_36X36_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/xuexiao_54X49_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/zhiding_43X47_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/zi_bingxing_96X25_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/zi_bukexuan_39X15_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/zi_kexuan_27X15_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/zi_quxiao_47X11_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/zi_sanwei_96X25_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/zi_shewei_47X11_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/zi_yiruzhu_39X15_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/zi_yixuan_27X15_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/zi_zanwushijie_221X46_32bits.png",
  "Texture/Aries/Creator/keepwork/ParaWorld/zuopkuang_266X134_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/dialog/dialog_440X93_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/dialog/guanbi_22X22_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/dialog/xiala_12X38_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/bianji_20X20_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/biaoti_128X64_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_add_guanzhudi_99X30_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_bianji_24X24_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_cancel_16X16_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_confirm_16X16_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_genghuan_38X39_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_gerenwangzhan_38X38_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_guanzhu_32X32_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_guanzhudi_99X30_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_jia_11X11_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_jian_10X3_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_jingru_40X40_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_ladong_20X8_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_ladongdi_10x130_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_qiehuanyou_12X21_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_qiehuanzuo_12X21_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_quxiaoguanzhu_99X30_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_shanchu_40X40_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_shuaxin_40X40_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_wenjian_40X40_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_xuanzhuanyou_40X35_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_xuanzhuanzou_40X35_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/btn_zuop_90X34_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/fengexian_1X45_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/fenshudi_76X41_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/icon_dianzan_16X16_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/icon_liulan_16X12_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/icon_xinxi_18X16_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/number/0_16X20_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/number/1_16X20_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/number/2_16X20_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/number/3_16X20_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/number/4_16X20_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/number/5_16X20_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/number/6_16X20_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/number/7_16X20_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/number/8_16X20_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/number/9_16X20_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/number/dian_7X7_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/renwukuang_339X529_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/shuruzhuangdi_16X16_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/suosi_28X31_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/tipbj_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/tipX_19X20_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/tixingzi_332X50_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/wenzidi_70X24_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/zi_diqu_33X16_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/zi_fensi_34X15_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/zi_guangzhu_34X16_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/zi_guanzhu_30X15_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/zi_shengri_32X15_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/zi_xuexiao_34X17_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/zi_yiguanzhu_46X15_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/zi_zhanghao_34X16_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/zi_zhishidou_50X16_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/zuopkuang_32X32_32bits.png",
  "Texture/Aries/Creator/keepwork/ggs/user/zuopkuang_selected_32X32_32bits.png",
  "Texture/Aries/Creator/keepwork/map/btn_E_32X32_32bits.png",
  "Texture/Aries/Creator/keepwork/map/btn_localmap_32bits.png",
  "Texture/Aries/Creator/keepwork/map/btn_R_32X32_32bits.png",
  "Texture/Aries/Creator/keepwork/map/btn_spawnpoint_32bits.png",
  "Texture/Aries/Creator/keepwork/map/btn_worldmap_32bits.png",
  "Texture/Aries/Creator/keepwork/map/maparrow_32bits.png"
}

DockAssetsPreloader.cur_time = 0;
DockAssetsPreloader.timeout = 30000;
DockAssetsPreloader.timer = nil;
function DockAssetsPreloader.Start(callback)
    if(DockAssetsPreloader.is_start)then
        if(callback)then
            callback();
        end
        return
    end
    DockAssetsPreloader.is_start = true
    DockAssetsPreloader.cur_time = 0;

    local fileLoader = CommonCtrl.FileLoader:new{
	    download_list = DockAssetsPreloader.GetDownloadList(),--下载文件列表
	    logname = "log/mc_textures_loader",--log文件地址
    }
    fileLoader:Start();



    Map3DSystem.App.MiniGames.SwfLoadingBarPage.ShowPage({ 
        show_background = true, 
    });

    local timer = commonlib.Timer:new({callbackFunc = function(timer)
        DockAssetsPreloader.cur_time = DockAssetsPreloader.cur_time + timer.delta;
        local percent = fileLoader:GetPercent();
        Map3DSystem.App.MiniGames.SwfLoadingBarPage.Update(percent);
        Map3DSystem.App.MiniGames.SwfLoadingBarPage.UpdateText(L"下载贴图中，首次加载会比较慢，请耐心等待");

        if(percent >= 1 or DockAssetsPreloader.cur_time > DockAssetsPreloader.timeout)then
            Map3DSystem.App.MiniGames.SwfLoadingBarPage.ClosePage();
            if(callback)then
                callback();
            end 
            -- kill timer
            timer:Change()
            return
        end
    end})
    timer:Change(0, 100);
end
function DockAssetsPreloader.FillAssets(loader)
    if(not loader)then
        return
    end
    for k,v in ipairs(assets) do
        loader:AddAssets(v);
    end
end
function DockAssetsPreloader.GetDownloadList()
    local list = {};
    for k,v in ipairs(assets) do
        table.insert(list,{
            filename = v,
            filesize = 1,
        });
    end
    return list;
end



