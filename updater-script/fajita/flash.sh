ui_print "########################################"
ui_print "#       Windwos刷写包-${FILE_NAME[4]}"
ui_print "#       Windows Flash-${FILE_NAME[4]}"
ui_print "########################################"
ui_print "#   The update-script by 亦魔/Yemon     "
ui_print "########################################"
ui_print " "

PRODUCT="fajita"
# 部分型号和特殊情况可能无法获取正确代号，需要设置第二参数。Some models or scenarios might not retrieve the correct code, a second argument needs to be set.
PRODUCT2="OenPlus6T"

assert_product "$PRODUCT" || assert_product "$PRODUCT2" || abort "检查机型错误，Your device is not $PRODUCT"
assert_equal ${FILE_NAME[1]} "$PRODUCT" || assert_equal ${FILE_NAME[1]} "$PRODUCT2" || abort "刷机包和机型不匹配，This package is only suitable for $PRODUCT"
assert_equal "flash" "${FILE_NAME[0]}" || abort "检查刷机包类型错误，This is not Flash package"
sleep 1

#################################################
ui_print "- Windows 安装中..."
ui_print "- Windows installing..."

install_win  || abort "Windows 安装失败！Windows install failed"
sleep 1
bak_android_boot || abort "备份Android boot失败，backup android boot failed"
flash_img "boot$(get_ab)" "boot-fajita-v2.0rc2.img" || abort "刷入boot失败，flash boot failed"
sleep 1
################################################
# 这里插入针对机型的脚本（以及对占位符的使用）

################################################
ui_print "刷机完成，请重启到系统进入Windows。"
ui_print "Flash done.Reboot the system to enter Windows."