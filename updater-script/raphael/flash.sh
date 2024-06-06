ui_print "########################################"
ui_print "#       Windwos刷写包-${FILE_NAME[4]}"
ui_print "#       Windows Flash-${FILE_NAME[4]}"
ui_print "########################################"
ui_print "#   The update-script by 亦魔/Yemon     "
ui_print "########################################"
ui_print " "

PRODUCT="raphael"
# 部分型号和特殊情况可能无法获取正确代号，需要设置第二参数。
# Some models or scenarios might not retrieve the correct model, a second argument needs to be set.
PRODUCT2="raphaels"
# 设置刷入的 boot 镜像名字
# Set the name of the boot image to be flashed
boot_name="xiaomi-raphael.img"

assert_product "$PRODUCT" || assert_product "$PRODUCT2" || abort "检查机型错误，Your device is not $PRODUCT"
assert_equal ${FILE_NAME[1]} "$PRODUCT" || assert_equal ${FILE_NAME[1]} "$PRODUCT2" || abort "刷机包和机型不匹配，This package is only suitable for $PRODUCT"
assert_equal "flash" "${FILE_NAME[0]}" || abort "检查刷机包类型错误，This is not Flash package"
sleep 1
################################################
# 这里插入特殊机型和占位符的脚本
# Insert script for special models and placeholders here
#################################################
# 通用脚本，一般情况下无需修改
# The script is universal and typically requires no modification
ui_print "- Windows 安装中..."
ui_print "- Windows installing..."

install_win || abort "Windows 安装失败！Windows install failed"
sleep 1
bak_android_boot || abort "备份Android boot失败，backup android boot failed"
flash_img "boot$(get_ab)" "$boot_name" || abort "刷入boot失败，flash boot failed"
sleep 1
################################################
# 这里插入特殊机型和占位符的脚本
# Insert script for special models and placeholders here
################################################
ui_print "刷机完成，请重启到系统进入Windows。"
ui_print "Flash done.Reboot the system to enter Windows."
