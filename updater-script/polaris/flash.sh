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
PRODUCT2=""
# 设置刷入的 boot 镜像名字
# Set the name of the boot image to be flashed
boot_name="boot-polaris-v2.0rc2.img"
echo ${FILE_NAME[2]} | grep -qiE "audio|音频|声音" && boot_name="boot-polaris-audio.img"
echo ${FILE_NAME[2]} | grep -qiE "audio|音频|声音" && ui_print "- 使用音频版 UEFI 镜像，Use audio version UEFI image."

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
    bak_img "modem" "modem_bak.img" || return $?
    bak_img "modemst1" "modemst1_bak.img" || return $?
    bak_img "modemst2" "modemst2_bak.img" || return $?
    bak_img "fsg" "fsg_bak.img" || return $?
    bak_img "fsc" "fsc_bak.img" || return $?
    ui_print "- 备份完成，done"
    ui_print ""

    ui_print "- 正在生成 恢复基带包..."
    ui_print "- generating Modem recovery package..."
    rm -rf /tmp/ReModem
    mkdir -p /tmp/ReModem/META-INF/com/google/android/
    ${TOOLPATH}umount -A /dev/block/by-name/esp
    rm -rf /tmp/esp/
    mkdir -p /tmp/esp/
    mount /dev/block/by-name/esp /tmp/esp/ || return 50
    cp -rf /tmp/esp/modem_bak.img /tmp/esp/modemst1_bak.img /tmp/esp/modemst2_bak.img /tmp/esp/fsg_bak.img /tmp/esp/fsc_bak.img /tmp/ReModem/ || return $?
    umount /tmp/esp/ && rm -rf /tmp/esp/

    cp -rf ${DATAPATH}re_modem.sh /tmp/ReModem/META-INF/com/google/android/re_modem.sh || return $?
    mv /tmp/ReModem/META-INF/com/google/android/re_modem.sh /tmp/ReModem/META-INF/com/google/android/update-binary || return $?
    touch /tmp/ReModem/META-INF/com/google/android/updater-script || return $?
    echo "null" >/tmp/ReModem/META-INF/com/google/android/updater-script

    device_serialno=$(getprop ro.serialno)
    device_serialno="device_serialno=$device_serialno"
    boot_serialno=$(getprop ro.boot.serialno)
    boot_serialno="boot_serialno=$boot_serialno"
    sed -i "s/device_serialno=abcdef/$device_serialno/g" /tmp/ReModem/META-INF/com/google/android/update-binary
    sed -i "s/boot_serialno=abcdef/$boot_serialno/g" /tmp/ReModem/META-INF/com/google/android/update-binary
    ${TOOLPATH}7zzs-arm64 a -tzip -mmt /tmp/re_modem.zip /tmp/ReModem/* || return 7
    ui_print "- 生成完成，done"

    ui_print "- 复制 re_modem.zip 到 sdcard/ ..."
    ui_print "- Copy re_modem.zip to sdcard/ ..."
    cp -rf /tmp/re_modem.zip /sdcard/re_modem.zip || ui_print "复制失败，请到 /tmp/ 目录自取。Copy failed, please copy it from /tmp/ directory."


    ui_print "- 基带备份结束！"
    ui_print "- Modem backup done!"
}

case ${FILE_NAME[3]} in
"modem") bak_modem || abort "基带备份失败，Modem backup failed" ;;
"devcfg") flash_devcfg ;;
"all")
    flash_devcfg
    bak_modem || abort "基带备份失败，Modem backup failed"
    ;;
esac
################################################
ui_print "刷机完成，请重启到系统进入Windows。"
ui_print "Flash done.Reboot the system to enter Windows."
