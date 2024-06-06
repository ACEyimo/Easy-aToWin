#!/bin/bash

# 初始化变量
# Initialize variables
WORKPATH=$(pwd)/
PRODUCT=""
VERSION=""
add_version=""
all_version=""
input_update_binary=""
output_file="all"
###############################################################
# 输出帮助文档
# Output help document
if $(echo $@ | grep -qi "\-h"); then
  echo "中文："
  echo "-i 使用指定的update-binary，默认为new.sh"
  echo "-o 输出指定的包，默认输出所有包"
  echo "-v 追加一个小版本号"
  echo "-V 设置完整版本号"
  echo "English:"
  echo "-i Use the specified update-binary, the default is new.sh"
  echo "-o Output the specified package, the default is all"
  echo "-v Append a small version number"
  echo "-V Set full version"
  exit 0
fi
# 检测是否要初始化一个新机型
# Check if a new model needs to be initialized
if [[ "$1" == "init" ]] && [[ -n "$2" ]]; then
  mkdir -p "${WORKPATH}data/$2"
  touch "${WORKPATH}data/$2/out.list"
  echo -e "part_data=()\nflash_data=(\n    boot.img\n)\nreset_data=()" >"${WORKPATH}data/$2/out.list"

  mkdir -p "${WORKPATH}updater-script/$2"
  touch "${WORKPATH}updater-script/$2/append.list"
  echo 'part_version=""' >>"${WORKPATH}updater-script/$2/append.list"
  echo 'flash_version=""' >>"${WORKPATH}updater-script/$2/append.list"
  echo 'reset_version=""' >>"${WORKPATH}updater-script/$2/append.list"

  cp -rf ${WORKPATH}updater-script/part.sh "${WORKPATH}updater-script/$2"
  cp -rf ${WORKPATH}updater-script/flash.sh "${WORKPATH}updater-script/$2"
  cp -rf ${WORKPATH}updater-script/reset.sh "${WORKPATH}updater-script/$2"

  echo "初始化${2}完成，编辑updater-script/${2}/下的文件完成适配"
  echo "Initialize ${2} complete, edit the file under updater-script/${2} to complete the adaptation"
  exit 0
fi

# 判断是否支持该型号
# Determine if the model is supported
if [[ -n "$1" ]]; then
  if [ -d "${WORKPATH}data/$1" ] && [ -d "${WORKPATH}updater-script/$1" ]; then
    PRODUCT=$1
  else
    echo -e "型号错误，请检查\nmodel error, please check\e"
    exit 3
  fi
else
  echo -e "请输入型号\nPlease enter the model\n"
  exit 3
fi

# -i 使用指定的update-binary，默认为new.sh | uses the specified update-binary, the default is new.sh
# -o 输出指定的包，默认为all | output the specified package, the default is all
# -v 追加版本号 | append version
# -V 设置完整版本号 | set full version
# 具体参照开发文档/Read the development documentation for more details
shift
while getopts "i:o:v:V:" opt; do
  case $opt in
  i) input_update_binary="$OPTARG" ;;
  o) output_file="$OPTARG" ;;
  v) add_version=$(echo $OPTARG | sed 's/\.//g') ;;
  V) all_version="$OPTARG" ;;
  *)
    echo -e "无效的选项或参数\nInvalid option or parameter missing\n"
    exit 2
    ;;
  esac
done
###############################################
# 处理$input_update_binary，将变量设置为绝对目录
# 如果未指定版本，则默认使用updata-binary/new.sh
# Handle $input_update_binary, set the variable to the absolute directory
# If the version is not specified, the default is to use updata-binary/new.sh
if [[ -z "$input_update_binary" ]]; then
  if [[ -f "${WORKPATH}update-binary/new.sh" ]]; then
    input_update_binary="${WORKPATH}update-binary/new.sh"
  else
    echo "未找到update-binary/new.sh，请检查"
    exit 1
  fi
else
  [[ "${input_update_binary}" != *".sh" ]] && input_update_binary="${input_update_binary}.sh"

  if [[ -f "${WORKPATH}update-binary/${input_update_binary}" ]]; then
    input_update_binary="${WORKPATH}update-binary/${input_update_binary}"
  else
    echo "未找到${input_update_binary}，请检查"
    exit 4
  fi
fi

# 定义$VERSION常量
# Define the $VERSION constant
function sum_version() {
  function print_version() {
    local aaa=$(printf "%d" "'${1:0:1}")
    let aaa=$aaa-64
    local bbb=$(printf "%d" "'${1:1:1}")
    let bbb=$bbb-64
    local ccc=$(printf "%d" "'${1:2:1}")
    let ccc=$ccc-64
    echo v$aaa.$bbb.$ccc
  }
  # 如果使用版本为new.sh时，使用最新版本进行转换，否则直接转换
  # if use new.sh, use the latest version for conversion, otherwise directly convert
  if [[ "${input_update_binary}" == *"/new.sh" ]]; then
    local zzzz=$(ls -v ${WORKPATH}update-binary/ | tail -n2 | head -n1 | tr '[:lower:]' '[:upper:]')
    print_version $zzzz
  else
    local zzzz=$(basename $input_update_binary | tr '[:lower:]' '[:upper:]')
    print_version $zzzz
  fi
}

# 读取追加版本号配置文件（append.list）
# Read the append version configuration file(append.list)
source ${WORKPATH}updater-script/${PRODUCT}/append.list
part_v_n=false
flash_v_n=false
reset_v_n=false
# 根据读取到的配置，判断输出时是否需要追加版本
# Based on the read configuration, determine whether to add a version when outputting
if [[ -z $all_version ]]; then
  [[ -n $part_version ]] && part_v_n=true
  [[ -n $flash_version ]] && flash_v_n=true
  [[ -n $reset_version ]] && reset_v_n=true
fi
# 如果主动设置全量版本，则不需要改动
# If you set the full version actively, no changes are needed
if [[ -z $all_version ]] && [[ -n $add_version ]]; then
  case $output_file in
  part | p)
    part_v_n=true
    echo -e "part_version=\"${add_version}\"\nflash_version=\"${flash_version}\"\nreset_version=\"${reset_version}\"" >${WORKPATH}updater-script/${PRODUCT}/append.list
    ;;
  flash | f)
    flash_v_n=true
    echo -e "part_version=\"${part_version}\"\nflash_version=\"${add_version}\"\nreset_version=\"${reset_version}\"" >${WORKPATH}updater-script/${PRODUCT}/append.list
    ;;
  reset | r)
    reset_v_n=true
    echo -e "part_version=\"${part_version}\"\nflash_version=\"${flash_version}\"\nreset_version=\"${add_version}\"" >${WORKPATH}updater-script/${PRODUCT}/append.list
    ;;
  all)
    part_v_n=true
    flash_v_n=true
    reset_v_n=true
    echo -e "part_version=\"${add_version}\"\nflash_version=\"${flash_version}\"\nreset_version=\"${reset_version}\"" >${WORKPATH}updater-script/${PRODUCT}/append.list
    source ${WORKPATH}updater-script/${PRODUCT}/append.list
    echo -e "part_version=\"${part_version}\"\nflash_version=\"${add_version}\"\nreset_version=\"${reset_version}\"" >${WORKPATH}updater-script/${PRODUCT}/append.list
    source ${WORKPATH}updater-script/${PRODUCT}/append.list
    echo -e "part_version=\"${part_version}\"\nflash_version=\"${flash_version}\"\nreset_version=\"${add_version}\"" >${WORKPATH}updater-script/${PRODUCT}/append.list
    ;;
  *)
    echo "未知包名: $output_file"
    exit 1
    ;;
  esac
fi
## 如果设置了完整版本，则直接使用完整版本定义到$VERSION
## If the full version is set, use the full version definition to $VERSION
if [[ -n $all_version ]]; then
  VERSION=${all_version}
else
  VERSION=$(sum_version)
fi

###########################################
# 制作并输出刷机包
# Make and output the flashing package
function make_zip() {
  local LONG_DIR_NAME="META-INF/com/google/android/"
  local make_type=$1
  local make_name=$2
  # 清理并创建临时目录
  # Clean up and create temporary directory
  rm -rf ${WORKPATH}temp/
  mkdir -p ${WORKPATH}temp/${LONG_DIR_NAME}
  cp -rf ${input_update_binary} ${WORKPATH}temp/${LONG_DIR_NAME}update-binary
  cp -rf ${WORKPATH}updater-script/${PRODUCT}/${make_type}.sh ${WORKPATH}temp/${LONG_DIR_NAME}updater-script
  cp -rf ${WORKPATH}bin/ ${WORKPATH}temp/
  rm -rf ${WORKPATH}temp/bin/7zzs-x86_64
  mkdir -p ${WORKPATH}temp/data
  # 读取需要输出的到刷机包的文件
  # Read the files to be output to the flashing package
  source ${WORKPATH}data/${PRODUCT}/out.list
  case $make_type in
  part) make_type=(${part_data[*]}) ;;
  flash)
    make_type=(${flash_data[*]})
    cp -rf ${WORKPATH}data/efi.tar ${WORKPATH}temp/data/efi.tar
    ;;
  reset) make_type=(${reset_data[*]}) ;;
  esac
  if [[ -f ${WORKPATH}data/${PRODUCT}/out.list ]]; then
    for filename in ${make_type[@]}; do
      cp -rf ${WORKPATH}data/${PRODUCT}/${filename} ${WORKPATH}temp/data/${filename}
    done
  else
    echo "没有找到 out.list Not Found"
    exit 1
  fi
  # 使用7zip 进行创建刷机包
  # Use 7zip to create the flashing package

  local OUTPATH=${WORKPATH}out/${PRODUCT}
  mkdir -p ${OUTPATH}
  local output_file=${OUTPATH}/${make_name}
  chmod +x ${WORKPATH}temp/${LONG_DIR_NAME}update-binary

  if $(uname -m | grep -qi "x86_64"); then
    chmod +x ${WORKPATH}bin/7zzs-x86_64
    ${WORKPATH}bin/7zzs-x86_64 a -tzip -mmt ${output_file} ${WORKPATH}temp/*
    rm -rf ${WORKPATH}temp
    return 0
  fi
  if $(uname -m | grep -qie "aarch64|arm64"); then
    chmod +x ${WORKPATH}bin/7zzs-arm64
    ${WORKPATH}bin/7zzs-arm64a -tzip -mmt ${output_file} ${WORKPATH}temp/*
    rm -rf ${WORKPATH}temp
    return 0
  fi
  7z a -tzip -mmt ${output_file} ${WORKPATH}temp/*
  rm -rf ${WORKPATH}temp
}

# 检测$output_file的值，输出指定包和设置版本
# chcake $output_file and output the specified package and set the version
source ${WORKPATH}updater-script/${PRODUCT}/append.list

out_version=${VERSION}

case $output_file in
part | p)
  $part_v_n && out_version=${VERSION}.$part_version
  make_zip "part" "part-${PRODUCT}-auto-null-${out_version}.zip"
  ;;
flash | f)
  $flash_v_n && out_version=${VERSION}.$flash_version
  make_zip "flash" "flash-${PRODUCT}-Win11_21H2-null-${out_version}.zip"
  ;;
reset | r)
  $reset_v_n && out_version=${VERSION}.$reset_version
  make_zip "reset" "reset-${PRODUCT}-default-null-${out_version}.zip"
  ;;
all)
  $part_v_n && out_version=${VERSION}.$part_version
  make_zip "part" "part-${PRODUCT}-auto-null-${out_version}.zip"

  $flash_v_n && out_version=${VERSION}.$flash_version
  make_zip "flash" "flash-${PRODUCT}-Win11_21H2-null-${out_version}.zip"

  $reset_v_n && out_version=${VERSION}.$reset_version
  make_zip "reset" "reset-${PRODUCT}-default-null-${out_version}.zip"
  ;;
*)
  echo "未知包名: $output_file"
  echo "Unknown package name: $output_file"
  exit 1
  ;;
esac
echo ""
echo ""
echo "use binary: $input_update_binary"
echo "out version: $out_version"
