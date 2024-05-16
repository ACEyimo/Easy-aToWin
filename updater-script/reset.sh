ui_print "########################################"
ui_print "#       Windwos恢复包-${FILE_NAME[4]}"
ui_print "#       Windows Reset-${FILE_NAME[4]}"
ui_print "########################################"
ui_print "#   The update-script by 亦魔/Yemon     "
ui_print "#   QQ/Email: 248807316/ACEyimo@qq.com  "
ui_print "#           QQ群: 172952046             "
ui_print "########################################"
ui_print " "

PRODUCT=""
# 部分型号和特殊情况可能无法获取正确代号，需要设置第二参数。Some models or scenarios might not retrieve the correct code, a second argument needs to be set.
PRODUCT2=""

assert_product "$PRODUCT" || assert_product "$PRODUCT2" || abort "检查机型错误，Your device is not $PRODUCT"
assert_equal ${FILE_NAME[1]} "$PRODUCT" || assert_equal ${FILE_NAME[1]} "$PRODUCT2" || abort "刷机包和机型不匹配，This package is only suitable for $PRODUCT"
assert_equal "reset" "${FILE_NAME[0]}" || abort "检查刷机包类型错误，This is not Reset package"
sleep 1

#################################################
${TOOLPATH}umount -A /dev/block/by-name/esp
rm -rf /tmp/esp/
mkdir -p /tmp/esp/
cpAboot_status=true
cp /tmp/esp/android_boot.img ${DATAPATH} || cpAboot_status=false
sleep 1
ui_print "- 正在恢复分区..."
ui_print "- Restoring partitions..."
# 下面这行需要手动修改，否则会影响auto模式的执行
re_part userdata_number userdata_start || echo "执行错误会直接退出，所以这段命令永远不会被执行。Execution errors will result in a direct exit, so this command will not be executed"

assert_equal "${FILE_NAME[3]}" "yes" && {
    if ${cpAboot_status}; then 
    flash_img "boot$(get_ab)" "android_boot.img" || ui_print "恢复boot失败，restore boot failed"
    fi
} || echo null > /dev/null
##################################################
# 这里插入针对机型的脚本（以及对占位符的使用）

##################################################
ui_print "恢复完成，请重启到recovery，并格式化data分区！"
ui_print "Reset done,reboot to recovery and format userdata!"
