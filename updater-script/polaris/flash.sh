ui_print "########################################"
ui_print "#       Windwos刷写包-${FILE_NAME[4]}"
ui_print "#       Windows Flash-${FILE_NAME[4]}"
ui_print "########################################"
ui_print "#   The update-script by 亦魔/Yemon     "
ui_print "########################################"
ui_print " "

PRODUCT="polaris"
# 部分型号和特殊情况可能无法获取正确代号，需要设置第二参数。
# Some models or scenarios might not retrieve the correct model, a second argument needs to be set.
PRODUCT2="raphaels"
# 设置刷入的 boot 镜像名字
# Set the name of the boot image to be flashed
boot_name="boot-polaris-v2.0rc2.img"

assert_product "$PRODUCT" || assert_product "$PRODUCT2" || abort "检查机型错误，Your device is not $PRODUCT"
assert_equal ${FILE_NAME[1]} "$PRODUCT" || assert_equal ${FILE_NAME[1]} "$PRODUCT2" || abort "刷机包和机型不匹配，This package is only suitable for $PRODUCT"
assert_equal "flash" "${FILE_NAME[0]}" || abort "检查刷机包类型错误，This is not Flash package"
sleep 1
################################################
# 这里插入特殊机型和占位符的脚本
# Insert script for special models and placeholders here
#################################################
ui_print "- Windows 安装中..."
ui_print "- Windows installing..."

install_win || abort "Windows 安装失败！Windows install failed"
sleep 1
bak_android_boot || abort "备份Android boot失败，backup android boot failed"
flash_img "boot$(get_ab)" "$boot_name" || abort "刷入boot失败，flash boot failed"
sleep 1
################################################
function flash_devcfg() {
    ui_print "- 正在备份devcfg..."
    ui_print "- backing up devcfg..."
    bak_img "devcfg_a" "devcfg_a_bak.img" || ui_print "备份devcfg失败，backup devcfg failed"
    bak_img "devcfg_b" "devcfg_b_bak.img" || ui_print "备份devcfg失败，backup devcfg failed"
    ui_print "- 正在刷入devcfg..."
    ui_print "- flashing devcfg..."
    flash_img "devcfg_a" "devcfg-polaris.img" || abort "刷入devcfg失败，flash devcfg failed"
    flash_img "devcfg_b" "devcfg-polaris.img" || abort "刷入devcfg失败，flash devcfg failed"
}
function bak_modem() {
    ui_print "- 正在备份基带..."
    ui_print "- backing up Modem..."
    bak_img "modem" "modem_bak.img" || ui_print "备份modem失败，backup modem failed"
    bak_img "modemst1" "modemst1_bak.img" || ui_print "备份modemst1失败，backup modemst1 failed"
    bak_img "modemst2" "modemst2_bak.img" || ui_print "备份modemst2失败，backup modemst2 failed"
    bak_img "fsg" "fsg_bak.img" || ui_print "备份fsg失败，backup fsg failed"
    bak_img "fsc" "fsc_bak.img" || ui_print "备份fsc失败，backup fsc failed"

    ui_print "- 正在发送备份到/sdcard/Easy-aToWin-bak/ ..."
    ui_print "- Sending backup to /sdcard/Easy-aToWin-bak/ ..."
    mkdir -p /sdcard/Easy-aToWin-bak | ui_print "创建备份目录失败，create backup dir failed"
    ${TOOLPATH}umount -A /dev/block/by-name/esp
    rm -rf /tmp/esp/
    mkdir -p /tmp/esp/
    mount /dev/block/by-name/esp /tmp/esp/ || return 50
    cp -rf /tmp/esp/modem_bak.img /sdcard/Easy-aToWin-bak/ || ui_print "发送基带备份失败，send modem backup failed"
    cp -rf /tmp/esp/modemst1_bak.img /sdcard/Easy-aToWin-bak/ || ui_print "发送基带备份失败，send modemst1 backup failed"
    cp -rf /tmp/esp/modemst2_bak.img /sdcard/Easy-aToWin-bak/ || ui_print "发送基带备份失败，send modemst2 backup failed"
    cp -rf /tmp/esp/fsg_bak.img /sdcard/Easy-aToWin-bak/ || ui_print "发送基带备份失败，send fsg backup failed"
    cp -rf /tmp/esp/fsc_bak.img /sdcard/Easy-aToWin-bak/ || ui_print "发送基带备份失败，send fsc backup failed"
    umount /tmp/esp/ && rm -rf /tmp/esp/

    ui_print "- 基带备份结束！"
    ui_print "- Modem backup done!"
}

case ${FILE_NAME[3]} in
"modem") bak_modem ;;
"devcfg") flash_devcfg ;;
"all")
    flash_devcfg
    bak_modem
    ;;
esac
################################################
ui_print "刷机完成，请重启到系统进入Windows。"
ui_print "Flash done.Reboot the system to enter Windows."
