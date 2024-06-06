ui_print "########################################"
ui_print "#       Windwos恢复包-${FILE_NAME[4]}"
ui_print "#       Windows Reset-${FILE_NAME[4]}"
ui_print "########################################"
ui_print "#   The update-script by 亦魔/Yemon     "
ui_print "########################################"
ui_print " "

PRODUCT="raphael"
# 部分型号和特殊情况可能无法获取正确代号，需要设置第二参数。
# Some models or scenarios might not retrieve the correct model, a second argument needs to be set.
PRODUCT2=""
# 设置userdata 分区的官方编号和起始位置（包含单位，比如MB）
# Set the official number and starting position of the userdata partition (including units, such as MB)
userdata_number="31"
userdata_start="2080375kB"

assert_product "$PRODUCT" || assert_product "$PRODUCT2" || abort "检查机型错误，Your device is not $PRODUCT"
assert_equal ${FILE_NAME[1]} "$PRODUCT" || assert_equal ${FILE_NAME[1]} "$PRODUCT2" || abort "刷机包和机型不匹配，This package is only suitable for $PRODUCT"
assert_equal "reset" "${FILE_NAME[0]}" || abort "检查刷机包类型错误，This is not Reset package"
sleep 1

################################################
# 这里插入特殊机型和占位符的脚本
# Insert script for special models and placeholders here
###############################################
# 恢复安卓boot的脚本，有可能出错，根据实际情况删除和保留
# The script to restore the Android boot, which may fail, delete it according to the situation or keep it
${TOOLPATH}umount -A /dev/block/by-name/esp
rm -rf /tmp/esp/
mkdir -p /tmp/esp/
cpAboot_status=true
cp /tmp/esp/android_boot.img ${DATAPATH} || cpAboot_status=false
sleep 1
#################################################
# 通用脚本，一般情况下无需修改
# The script is universal and typically requires no modification
ui_print "- 正在恢复分区..."
ui_print "- Restoring partitions..."
re_part $userdata_number $userdata_start || echo "执行错误会直接退出，所以这段命令永远不会被执行。Execution errors will result in a direct exit, so this command will not be executed"
################################################
# 这里插入特殊机型和占位符的脚本
# Insert script for special models and placeholders here
# ##############################################
# 恢复安卓boot的脚本，有可能出错，根据实际情况删除和保留
# The script to restore the Android boot, which may fail, delete it according to the situation or keep it
assert_equal "${FILE_NAME[3]}" "yes" && {
    if ${cpAboot_status}; then
        flash_img "boot$(get_ab)" "android_boot.img" || ui_print "恢复boot失败，restore boot failed"
    fi
} || echo null >/dev/null
##################################################
ui_print "恢复完成，请重启到recovery，并格式化data分区！"
ui_print "Reset done,reboot to recovery and format userdata!"
