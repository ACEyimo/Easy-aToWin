ui_print "########################################"
ui_print "#       Windwos分区包-${FILE_NAME[4]}"
ui_print "#       Windows Part-${FILE_NAME[4]}"
ui_print "########################################"
ui_print "#   The update-script by 亦魔/Yemon     "
ui_print "########################################"
ui_print " "

PRODUCT=""
# 部分型号和特殊情况可能无法获取正确代号，需要设置第二参数。Some models or scenarios might not retrieve the correct code, a second argument needs to be set.
PRODUCT2=""

assert_product "$PRODUCT" || assert_product "$PRODUCT2" || abort "检查机型错误，Your device is not $PRODUCT"
assert_equal ${FILE_NAME[1]} "$PRODUCT" || assert_equal ${FILE_NAME[1]} "$PRODUCT2" || abort "刷机包和机型不匹配，This package is only suitable for $PRODUCT"
assert_equal "part" "${FILE_NAME[0]}" || abort "检查刷机包类型错误，This is not Part package"
sleep 1

#################################################
ui_print "- 正在分区中...."
ui_print "- partitioning..."

run_part_tool || abort "分区失败！Partition failed!"
sleep 1
################################################
# 这里插入针对机型的脚本（以及对占位符的使用）

################################################
ui_print "分区完成，请重启到recovery，并格式化data分区！"
ui_print "partition done,reboot to recovery and format userdata!"