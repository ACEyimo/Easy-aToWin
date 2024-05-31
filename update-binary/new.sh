#!/sbin/sh

OUTFD=/proc/self/fd/$2
ZIPFILE="$3"

######此串代码抄自TWRP安装包#####
ui_print() {
  if $BOOTMODE; then
    echo "$1"
  else
    echo -e "ui_print $1\nui_print" >>$OUTFD
  fi
}
#我自己添加了一个返回错误码的函数，别的没动
abort() {
  local i=$?
  ui_print "$1"
  exit $i
}
BOOTMODE=false
ps | grep zygote | grep -v grep >/dev/null && BOOTMODE=true
$BOOTMODE || ps -A 2>/dev/null | grep zygote | grep -v grep >/dev/null && BOOTMODE=true
#####This code comes from TWRP#####
# bcdboot by 小太阳ACA/BigfootACA

ui_print "==========================================="
ui_print "    The update-binary by 亦魔/Yemon     "
ui_print "         build A.cc20240516             "
ui_print "      此包永久免费，请不要上当受骗        "
ui_print " The package is free, don't be tricked  "
ui_print "==========================================="
ui_print "   QQ/Email: 248807316/ACEyimo@qq.com    "
ui_print "            QQ群: 172952046             "
ui_print "      URL: Easy-aToWin.ACEyimo.cn         "
ui_print "==========================================="
ui_print " "
sleep 1

#定义全局常量
TOOLPATH=/tmp/FWT/bin/
DATAPATH=/tmp/FWT/data/
DISKPATH=/dev/block/sda
CONFPATH=/tmp/logfs/fwt.conf
LOGSPATH=/tmp/logfs/fwt.log

rm -rf /tmp/FWT/
mkdir -p /tmp/FWT/
unzip -o $ZIPFILE -d /tmp/FWT/
chmod +x ${TOOLPATH}*

rm -rf /tmp/logfs/
mkdir -p /tmp/logfs/
mount /dev/block/by-name/logfs /tmp/logfs
# touch $CONFPATH
# touch $LOGSPATH

#判断$1和$2是否一致的函数
assert_equal() {
  if [[ "$1" == "$2" ]]; then
    return 0
  else
    return 10
  fi
}

# 验证机型是不是跟预设值一致
assert_product() {
  if [[ "$(getprop ro.build.product)" == "$1" ||
  "$(getprop ro.product.device)" == "$1" ]]; then
    return 0
  else
    return 11
  fi
}

#############################

# FILE_NAME=( 刷机包类型 型号 刷入信息 占位符 版本 ）
FILE_NAME=(type model info placeholder version)
get_file_name() {
  local num="$1"
  local file_name=$(basename "$ZIPFILE")
  file_name="${file_name%.*}"
  if [ $(echo "$file_name" | tr '-' '\n' | wc -l) = 5 ]; then
    file_name=$(echo "$file_name" | cut -d '-' -f$num)
    echo "$file_name"
  else
    return 12
  fi
  return 0
}
get_file_name 3 >/dev/null || abort "检查文件名错误，your file name is not correct"
FILE_NAME[0]=$(get_file_name 1)
FILE_NAME[1]=$(get_file_name 2)
FILE_NAME[2]=$(get_file_name 3)
FILE_NAME[3]=$(get_file_name 4)
FILE_NAME[4]=$(get_file_name 5)

####################################

# 按分区名查找信息
get_part_info() {
  local name="$1"
  local num="$2"
  # 1=number，2=start，3=end，4=size，5=type
  ${TOOLPATH}parted -s ${DISKPATH} p | grep $name | awk -v i=$num '{print $i}' | tr -d '[:space:]' >/dev/null || return 20
  echo "$(${TOOLPATH}parted -s ${DISKPATH} p | grep $name | awk -v i=$num '{print $i}' | tr -d '[:space:]')"
}
get_max_part_num() {
  echo "$(${TOOLPATH}parted -s ${DISKPATH} p | tail -n2 | head -n1 | awk '{print $1}' | tr -d '[:blank:]')"
}
DISK_SIZE="$(${TOOLPATH}parted -s ${DISKPATH} p | head -n2 | tail -n1 | cut -d ':' -f2 | tr -d '[:blank:]')"

# 处理并验证 ${FILE_NAME[2]} 的输入值是否合法
check_input_size() {
  local input_value=$(echo "${FILE_NAME[2]}" | tr -d 'gGBb')
  local disk_size=$(echo "$DISK_SIZE" | tr -d '[:space:][:alpha:]' | cut -d'.' -f1)

  if [[ "$input_value" == "auto" ]]; then
    if [[ "$disk_size" -lt 57 ]]; then
      return 22
    elif [[ "$disk_size" -ge 57 && "$disk_size" -le 64 ]]; then
      echo "38"
      return 0
    elif [[ "$disk_size" -le 128 ]]; then
      echo "70"
      return 0
    elif [[ "$disk_size" -le 256 ]]; then
      echo "120"
      return 0
    elif [[ "$disk_size" -le 512 ]]; then
      echo "240"
      return 0
    elif [[ "$disk_size" -gt 512 ]]; then
      echo "480"
      return 0
    fi
  fi

  if echo "$input_value" | grep -qiE '\.|[a-z]'; then
    return 21
  fi

  if [[ "$input_value" -gt 38 && "$input_value" -lt "$((disk_size - 19))" ]]; then
    echo "$input_value"
  else
    return 22
  fi
}

# 获取分区信息
userdata_info=(number ext4 start end)
esp_info=(number fat32 start end)
win_info=(number ntfs start end)
decl_part_info() {
  ui_print "正在初始化分区变量..."
  ui_print "Disk variable initialization..."
  local disk_size=$(echo "$DISK_SIZE" | tr -d '[:space:][:alpha:]' | cut -d'.' -f1)
  check_input_size >/dev/null || return $?
  local input_size=$(check_input_size)
  win_info[3]=$(echo "$DISK_SIZE" | tr -d '[:space:][:alpha:]')
  win_info[2]=$(($disk_size - $input_size))

  esp_info[3]=${win_info[2]}
  esp_info[2]=$((${esp_info[3]} - 1))

  userdata_info[3]=${esp_info[2]}
  userdata_info[2]=$(get_part_info userdata 2)
  userdata_info[0]=$(get_part_info userdata 1)

  esp_info[0]=$((${userdata_info[0]} + 1))
  win_info[0]=$((${esp_info[0]} + 1))
  sleep 1

  ui_print "分区变量初始化完成"
  ui_print "partition variable initialization complete"
}

run_part_tool() {
  decl_part_info || abort "输入的分区大小不合法，input size is not correct"
  get_userdata_end() {
    echo "$(get_part_info userdata 3)"
  }
  userdata_old_end=$(get_userdata_end)
  userdata_old_size=$(get_part_info userdata 4)

  # 先取消卸载userdata
  ${TOOLPATH}umount -A ${DISKPATH}${userdata_info[0]} ||
    if $? != 0; then
      ui_print "卸载userdata分区失败，此BUG无法解决"
      ui_print "Failed to unmount the userdata partition,this bug is currently unresolved."
    fi
  sleep 0.5
  # 调整userdata分区大小
  ui_print "正在调整userdata分区大小..."
  ui_print "Adjusting userdata partition size..."
  ${TOOLPATH}parted ${DISKPATH} resizepart ${userdata_info[0]} yes ${userdata_info[3]}GB yes >/dev/null
  sleep 1

  # 判断分区是否与预设值一致，否则执行无`yes`参数的命令
  if [[ "$(get_userdata_end)" == "${userdata_old_end}" ]]; then
    ui_print "调整userdata分区失败，尝试备选方案..."
    ui_print "Adjusting userdata partition failed,try alternative solution..."
    ${TOOLPATH}parted ${DISKPATH} resizepart ${userdata_info[0]} ${userdata_info[3]}GB yes >/dev/null
    if [[ "$(get_userdata_end)" == "${userdata_old_end}" ]]; then
      ${TOOLPATH}parted ${DISKPATH} resizepart ${userdata_info[0]} ${userdata_info[3]}GB >/dev/null
      if [[ "$(get_userdata_end)" == "${userdata_old_end}" ]]; then
        return 31
      fi
    fi
  fi

  userdata_new_size=$(get_part_info userdata 4)
  ui_print "userdata分区从${userdata_old_size}调整到${userdata_new_size}"
  ui_print "userdata partition from ${userdata_old_size} to ${userdata_new_size}"
  sleep 1

  ui_print "正在创建esp分区..."
  ui_print "Creating esp partition..."
  ${TOOLPATH}parted -s ${DISKPATH} mkpart esp ${esp_info[1]} ${esp_info[2]}GB ${esp_info[3]}GB || return 32
  sleep 1
  ui_print "esp分区创建成功,esp partition created"
  sleep 1

  ui_print "正在创建win分区..."
  ui_print "Creating win partition..."
  ${TOOLPATH}parted -s ${DISKPATH} mkpart win ${win_info[1]} ${win_info[2]}GB ${win_info[3]}GB || return 33
  sleep 1
  ui_print "win分区创建成功,win partition created"
  sleep 0.5

  ${TOOLPATH}parted -s ${DISKPATH} set ${esp_info[0]} esp on || return 34
}

###############################################################

# 在指定目录中查找'windata.wim'文件，或作为备选查找以'mtip'结尾的文件。仅输出找到的第一个文件。
find_windata() {
  local windata=$(echo "${FILE_NAME[2]}-${FILE_NAME[1]}")
  DIRS=(/usbstorage/ /sdcard/ /sdcard/Download/)

  i=0
  while [ $i -lt ${#DIRS[@]} ]; do
    dir="${DIRS[$i]}"
    bv=true
    ls $dir | grep ${windata} | grep '.wim$' >/dev/null || bv=false
    if $bv; then
      echo "${dir}$(ls $dir | grep ${windata} | grep '.wim$' | head -n1)"
      return 0
    fi
    ((i++))
  done

  i=0
  while [ $i -lt ${#DIRS[@]} ]; do
    dir="${DIRS[$i]}"
    bv=true
    ls $dir | grep '.mtip$' >/dev/null || bv=false
    if $bv; then
      echo "${dir}$(ls $dir | grep '.mtip$' | head -n1)"
      return 0
    fi
    ((i++))
  done
  return 41
}
# 格式化分区
format_part() {
  get_part_info esp 1 >/dev/null || abort "esp分区不存在，esp partition not exist"
  mkfs.fat -F32 -s1 /dev/block/by-name/esp
  sleep 0.5
  get_part_info win 1 >/dev/null || abort "win分区不存在，win partition not exist"
  mkfs.ntfs -f /dev/block/by-name/win
}
# 安装Windows
install_win() {
  find_windata >/dev/null || abort "未找到wim数据包，wim data not found"
  local windata=$(find_windata)
  ui_print "查找到/find: ${windata}"
  ui_print "正在格式化分区，Formatting partition"
  format_part
  sleep 0.5
  ui_print "格式化分区完成，Formatting partition completed"
  ui_print " "
  sleep 1

  ui_print "正在安装EFI，Installing EFI"
  ${TOOLPATH}umount -A /dev/block/by-name/esp
  rm -rf /tmp/esp/
  mkdir -p /tmp/esp/
  mount /dev/block/by-name/esp /tmp/esp/ || return 50
  tar -xf ${DATAPATH}efi.tar -C /tmp/esp/
  ${TOOLPATH}bcdboot /tmp/esp/EFI/Microsoft/Boot/BCD /dev/block/by-name/win || return 42
  ${TOOLPATH}umount -A /dev/block/by-name/esp
  rm -rf /tmp/esp/
  sleep 1
  ui_print "EFI安装完成，EFI installation completed"
  ui_print " "
  sleep 0.5

  ui_print "正在安装Windows，过程预计2-8分钟，请耐心等待"
  ui_print "Installing Windows.the process is expected to take 2-8 minutes, please wait"
  ${TOOLPATH}wimlib-imagex apply --quiet $windata /dev/block/by-name/win || return 43
  ui_print "Windows安装完成，Windows installation completed"
  ui_print " "
  sleep 0.5

}

###########################################################
# 获取a还是b分区
get_ab() {
  if $(getprop ro.build.ab_update); then
    echo $(getprop ro.boot.slot_suffix)
  else
    echo ""
  fi
}
# 备份某个分区为镜像
bak_img() {
  partname=$1
  filenaem=$2
  ${TOOLPATH}umount -A /dev/block/by-name/esp
  rm -rf /tmp/esp/
  mkdir -p /tmp/esp/
  mount /dev/block/by-name/esp /tmp/esp/ || return 50
  dd if=/dev/block/by-name/${partname} of=/tmp/esp/${filenaem} || local aaa=false
  ${TOOLPATH}umount -A /dev/block/by-name/esp
  rm -rf /tmp/esp/
  $aaa || return 51
}
# 备份安卓boot
bak_android_boot() {
  nowboot=$(get_ab)
  bak_img "boot${nowboot}" "android_boot.img" || return $?

  ${TOOLPATH}umount -A /dev/block/by-name/esp
  rm -rf /tmp/esp/
  mkdir -p /tmp/esp/
  mount /dev/block/by-name/esp /tmp/esp/ || return 50
  cp -f /tmp/esp/android_boot.img /sdcard/ || ui_print "发送安卓boot备份到/sdcard失败，send android_boot.img to /sdcard failed"
  ${TOOLPATH}umount -A /dev/block/by-name/esp
  rm -rf /tmp/esp/
}
# 刷入镜像
flash_img() {
  partname=$1
  filename=$2

  dd if=${DATAPATH}${filename} of=/dev/block/by-name/${partname} || local aaa=false
  $aaa || return 52
}

###############################################
# 恢复安卓boot
re_android_boot() {
  # 获取当前boot版本
  nowboot=$(get_ab)

  ${TOOLPATH}umount -A /dev/block/by-name/esp
  rm -rf /tmp/esp/
  mkdir -p /tmp/esp/

  cp /tmp/esp/android_boot.img ${DATAPATH} || return 1

  flash_img android_boot.img boot${now_boot} || return $?

  ui_print "安卓boot恢复成功，android_boot.img restored successfully"
}

re_part() {
  re_userdata_number=$1
  re_userdata_start=$2
  re_maxnuber=$(get_max_part_num)

  re_run_default() {
    d_userdata_number=$(get_part_info userdata 1)
    d_esp_number=$(get_part_info esp 1)
    d_win_number=$(get_part_info win 1)

    ${TOOLPATH}umount -A /dev/block/by-name/esp
    ${TOOLPATH}umount -A /dev/block/by-name/win
    ${TOOLPATH}umount -A /dev/block/by-name/userdata || echo "刷机包在data目录下会取消挂载失败，不影响后续执行"

    ${TOOLPATH}parted -s ${DISKPATH} rm $d_esp_number || return 71
    ${TOOLPATH}parted -s ${DISKPATH} rm $d_win_number || return 71
    sleep 0.5
    ${TOOLPATH}parted ${DISKPATH} resizepart ${d_userdata_number} yes 100% >/dev/null
    sleep 1

    # 判断分区是否与预设值一致，否则执行无`yes`参数的命令
    if [[ $(get_part_info userdata 3) != "${DISK_SIZE}" ]]; then
      ui_print "调整userdata分区失败，尝试备选方案..."
      ui_print "Adjusting userdata partition failed,try alternative solution..."
      ${TOOLPATH}parted ${DISKPATH} resizepart ${d_userdata_number} yes 100% yes >/dev/null
      if [[ $(get_part_info userdata 3) != "${DISK_SIZE}" ]]; then
        ${TOOLPATH}parted ${DISKPATH} resizepart ${d_userdata_number} 100% >/dev/null
        if [[ $(get_part_info userdata 3) != "${DISK_SIZE}" ]]; then
          return 72
        fi
      fi
    fi
  }

  re_run_auto() {
    a_number=$re_userdata_number
    ((a_number++))
    re_auto_error=0
    while [ $a_number -le $re_maxnuber ]; do
      ui_print "正在删除分区${a_number}，Deleting partition ${a_number}"
      ${TOOLPATH}sgdisk --delete=${a_number} ${DISKPATH} || ((re_auto_error++))
      sleep 0.5
      ((a_number++))
    done || return 75
    if [[ $re_auto_error != 0 ]]; then
      ui_print "${re_auto_error}个分区未正确排序，但依旧被执行了删除命令。"
      ui_print "${re_auto_error} partitions were not sorted correctly, but the delete command was executed"
    fi

    ${TOOLPATH}sgdisk --delete=${re_userdata_number} ${DISKPATH} || return 76

    ${TOOLPATH}parted ${DISKPATH} -s mkpart userdata ext4 ${re_userdata_start} 100% i || return 77
  }

  # 此函数未测试
  re_run_sgdisk() {
    ${TOOLPATH}umount -A /dev/block/by-name/esp
    rm -rf /tmp/esp/
    mkdir -p /tmp/esp/
    mount /dev/block/by-name/esp /tmp/esp/ || return 50

    local disk_size=$(echo "$DISK_SIZE" | tr -d '[:space:][:alpha:]' | cut -d'.' -f1)

    local device_size=32
    if [[ "$disk_size" -ge 57 && "$disk_size" -le 64 ]]; then
      device_size=64G
    elif [[ "$disk_size" -le 128 ]]; then
      device_size=128G
    elif [[ "$disk_size" -le 256 ]]; then
      device_size=256G
    elif [[ "$disk_size" -le 512 ]]; then
      device_size=512G
    elif [[ "$disk_size" -gt 512 ]]; then
      return 78
    fi
    local sgdisk_bak_file="/tmp/FWT/data/sgdisk-${device_size}.bak"
    ls /tmp/esp | grep -q sgdisk.bak && sgdisk_bak_file="/tmp/esp/sgdisk.bak"
    ${TOOLPATH}sgdisk -b=${sgdisk_bak_file} ${DISKPATH} || return 79
  }

  if [[ $(get_max_part_num) == ${re_userdata_number} && $(get_max_part_num) == $(get_part_info userdata 1) ]]; then
    ui_print "你的分区似乎是正确的,Your partition seems to be correct"
    return 0
  fi

  if [[ ${FILE_NAME[2]} == "default" ]]; then
    ui_print "执行默认方案..."
    re_run_default || abort "执行默认方案失败，default solution failed"
    return 0
  elif [[ ${FILE_NAME[2]} == "auto" ]]; then
    ui_print "执行自动方案..."
    re_run_auto || abort "执行自动方案失败，auto solution failed"
    return 0
  elif [[ ${FILE_NAME[2]} == "sgdisk" ]]; then
    ui_print "执行sgdisk方案..."
    re_run_sgdisk || abort "执行sgdisk方案失败，sgdisk solution failed"
    return 0
  else
    return 70
  fi
}

#############################################################

# 读写配置
read_conf() {
  local c_name="$1"
  local c_path="${2:-$CONFPATH}"

  if [ -z "$c_name" ]; then
    return 60
  fi
  if [ ! -f "$c_path" ]; then
    return 61
  fi

  local c_value=$(grep "^$c_name=" "$c_path" | cut -d'=' -f2-)

  if [ ! -z "$c_value" ]; then
    echo "$c_value"
    return 0
  else
    return 62
  fi
}

write_conf() {
  local c_name="$1"
  local c_value="$2"
  local c_path="${3:-$CONFPATH}"
  local c_all="${c_name}=${c_value}"

  if [ -z "$c_name" ] || [ -z "$c_value" ]; then
    return 60
  fi

  if [ ! -f "$c_path" ]; then
    return 61
  fi

  # 检查配置项是否已存在于文件中
  grep -q "^$c_name=" "$c_path"

  # 如果配置项不存在于文件中，则追加到文件末尾
  if [ $? -ne 0 ]; then
    echo "$c_name=$c_value" >>"$c_path"
  else
    # 如果配置项已存在，则使用 sed 更新其值
    sed -i "/^$c_name=/ s|=.*|$c_name=$c_value|" "$c_path"
  fi
  return 0
}

chmod +x "/tmp/FWT/META-INF/com/google/android/updater-script"
source "/tmp/FWT/META-INF/com/google/android/updater-script" || abort "未知错误导致脚本执行失败，unknown error caused script execution failure"
ui_print "==========================================="
sleep 0.5
ui_print "正在清理包缓存..."
ui_print "Cleaning package cache..."
rm -rf /tmp/FTW/
sleep 0.5
ui_print "执行完毕，Execution completed"

exit 0
