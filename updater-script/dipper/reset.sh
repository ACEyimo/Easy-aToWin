ui_print "########################################"
ui_print "#       Windwos恢复包-${FILE_NAME[4]}"
ui_print "#       Windows Reset-${FILE_NAME[4]}"
ui_print "########################################"
ui_print "#   The update-script by 亦魔/Yemon     "
ui_print "########################################"
ui_print " "

PRODUCT="dipper"
# 部分型号和特殊情况可能无法获取正确代号，需要设置第二参数。
# Some models or scenarios might not retrieve the correct model, a second argument needs to be set.
PRODUCT2=""
# 设置userdata 分区的官方编号和起始位置（包含单位，比如MB）
# Set the official number and starting position of the userdata partition (including units, such as MB)
userdata_number="21"
userdata_start="1611MB"

assert_product "$PRODUCT" || assert_product "$PRODUCT2" || abort "检查机型错误，Your device is not $PRODUCT"
assert_equal ${FILE_NAME[1]} "$PRODUCT" || assert_equal ${FILE_NAME[1]} "$PRODUCT2" || abort "刷机包和机型不匹配，This package is only suitable for $PRODUCT"
assert_equal "reset" "${FILE_NAME[0]}" || abort "检查刷机包类型错误，This is not Reset package"
sleep 1

################################################
# 这里插入特殊机型和占位符的脚本
# Insert script for special models and placeholders here
function re_modem {
    ui_print "- 正在恢复modem分区..."
    ui_print "- Restoring modem partition..."
    ${TOOLPATH}umount -A /dev/block/by-name/esp
    rm -rf /tmp/esp/
    mkdir -p /tmp/esp/
    mount /dev/block/by-name/esp /tmp/esp/ || return 50

    cp -rf /tmp/esp/modem_bak.img ${DATAPATH} && flash_img "modem" "modem_bak.img" || abort "恢复modem失败，restore modem failed"
    cp -rf /tmp/esp/modemst1_bak.img ${DATAPATH} && flash_img "modemst1" "modemst1_bak.img" || abort "恢复modemst1失败，restore modemst1 failed"
    cp -rf /tmp/esp/modemst2_bak.img ${DATAPATH} && flash_img "modemst2" "modemst2_bak.img" || abort "恢复modemst2失败，restore modemst2 failed"
    cp -rf /tmp/esp/fsg_bak.img ${DATAPATH} && flash_img "fsg" "fsg_bak.img" || abort "恢复fsg失败，restore fsg failed"
    cp -rf /tmp/esp/fsc_bak.img ${DATAPATH} && flash_img "fsc" "fsc_bak.img" || abort "恢复fsc失败，restore fsc failed"

    ${TOOLPATH}umount -A /dev/block/by-name/esp && rm -rf /tmp/esp/

    ui_print "- 恢复modem成功，restore modem success"
}
function re_devcfg {
    ui_print "- 正在恢复devcfg分区..."
    ui_print "- Restoring devcfg partition..."
    ${TOOLPATH}umount -A /dev/block/by-name/esp
    rm -rf /tmp/esp/
    mkdir -p /tmp/esp/
    mount /dev/block/by-name/esp /tmp/esp/ || return 50

    cp -rf /tmp/esp/devcfg_bak.img ${DATAPATH} && flash_img "devcfg" "devcfg_bak.img" || abort "恢复devcfg失败，restore devcfg failed"

    ${TOOLPATH}umount -A /dev/block/by-name/esp && rm -rf /tmp/esp/

    ui_print "- 恢复devcfg成功，restore devcfg success"

}

if [ ${FILE_NAME[3]} == "all" ]; then
    re_android_boot
    re_modem
    re_devcfg
fi
echo ${FILE_NAME[3]} | grep -iq "modem" && re_modem
echo ${FILE_NAME[3]} | grep -iq "devcfg" && re_devcfg
echo ${FILE_NAME[3]} | grep -iq "boot" && re_android_boot
#################################################
# 通用脚本，一般情况下无需修改
# The script is universal and typically requires no modification
ui_print "- 正在恢复分区..."
ui_print "- Restoring partitions..."
re_part $userdata_number $userdata_start || echo "执行错误会直接退出，所以这段命令永远不会被执行。Execution errors will result in a direct exit, so this command will not be executed"
################################################
# 这里插入特殊机型和占位符的脚本
# Insert script for special models and placeholders here
##################################################
ui_print "恢复完成，请重启到recovery，并格式化data分区！"
ui_print "Reset done,reboot to recovery and format userdata!"
