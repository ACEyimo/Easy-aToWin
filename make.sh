#!/bin/bash

# 初始化变量
WORKPATH=$(pwd)/
PRODUCT=""
VERSION=""
add_version=""
all_version=""
input_update_binary=""
output_file="all"

# 检测是否要初始化一个新机型
if [[ "$1" == "init" ]] && [[ -n "$2" ]]; then
  mkdir -p "${WORKPATH}data/$2"
  cp -rf ${WORKPATH}data/out.list "${WORKPATH}data/$2"

  mkdir -p "${WORKPATH}updater-script/$2"
  cp -rf ${WORKPATH}updater-script/append.list "${WORKPATH}updater-script/$2"
  cp -rf ${WORKPATH}updater-script/part.sh "${WORKPATH}updater-script/$2"
  cp -rf ${WORKPATH}updater-script/flash.sh "${WORKPATH}updater-script/$2"
  cp -rf ${WORKPATH}updater-script/reset.sh "${WORKPATH}updater-script/$2"

  echo "初始化${2}完成，编辑updater-script/${2}/下的文件完成适配"
  echo "Initialize ${2} complete, edit the file under updater-script/${2} to complete the adaptation"
  exit 0
fi

# 判断型号是否合法
if [[ -n "$1" ]]; then
  if [ -d "${WORKPATH}data/$1" ] && [ -d "${WORKPATH}updater-script/$1" ]; then
    PRODUCT=$1
  else
    echo "型号错误，请检查"
    exit 3
  fi
else
  echo "请输入型号"
  exit 3
fi

# -i 使用指定的update-binary，默认为new.sh
# -o 输出指定的包，默认为all
# -v 追加版本号
# -V 设置版本号
shift
while getopts "i:o:v:V:" opt; do
  case $opt in
  i)
    input_update_binary="$OPTARG"
    echo
    ;;
  o)
    output_file="$OPTARG"
    echo $output_file
    ;;
  v)
    add_version=$(echo $OPTARG | sed 's/\.//g')
    echo $add_version
    ;;
  V)
    all_version="$OPTARG"
    ;;
  *)
    echo -e "无效的选项或参数。\nInvalid option or parameter missing."
    exit 2
    ;;
  esac
done

# 处理input_update_binary，以绝对目录运行。首选判断是否被主动设置，如果主动设置则去除掉.sh后缀再添加回来（主要避免设置时添加了.sh后缀）。如果未空则默认使用new
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

function to_version() {
  local aaa=$(printf "%d" "'${1:0:1}")
  let aaa=$aaa-64
  local bbb=$(printf "%d" "'${1:1:1}")
  let bbb=$bbb-64
  local ccc=$(printf "%d" "'${1:2:1}")
  let ccc=$ccc-64
  echo v$aaa.$bbb.$ccc
}
function sum_version() {
  if [[ "${input_update_binary}" == *"/new.sh" ]]; then
    local zzzz=$(ls -v ${WORKPATH}update-binary/ | tail -n2 | head -n1 | tr '[:lower:]' '[:upper:]')
    to_version $zzzz
  else
    local zzzz=$(basename $input_update_binary | tr '[:lower:]' '[:upper:]')
    to_version $zzzz
  fi
}

# 定义Version变量。如果input_update_binary为new.sh，则使用倒数第二个，否则使用指定的
if [[ -n $all_version ]]; then
  VERSION=$all_version
else
  if [[ -n $add_version ]]; then
    VERSION=$(sum_version).$add_version
  else
    VERSION=$(sum_version)
  fi
fi

# 制作 update.zip
function make_zip() {
  local LONG_DIR_NAME="META-INF/com/google/android/"
  local make_type=$1
  local make_name=$2

  rm -rf ${WORKPATH}temp/
  mkdir -p ${WORKPATH}temp/${LONG_DIR_NAME}
  cp -rf ${input_update_binary} ${WORKPATH}temp/${LONG_DIR_NAME}update-binary
  cp -rf ${WORKPATH}updater-script/${PRODUCT}/${make_type}.sh ${WORKPATH}temp/${LONG_DIR_NAME}updater-script
  cp -rf ${WORKPATH}bin/ ${WORKPATH}temp/
  mkdir -p ${WORKPATH}temp/data

  if [[ "${make_type}" == "flash" ]]; then
    cp -rf ${WORKPATH}data/efi.tar ${WORKPATH}temp/data/efi.tar
  fi

  if [[ -f ${WORKPATH}data/${PRODUCT}/out.list ]]; then
    touch ${WORKPATH}temp/out.list
    cat ${WORKPATH}data/${PRODUCT}/out.list | grep ${make_type} | awk '{print $2}' >${WORKPATH}temp/out.list
    local lins=$(cat ${WORKPATH}temp/out.list | wc -l)
    for ((i = 1; i <= lins; i++)); do
      local name=$(cat ${WORKPATH}temp/out.list | sed -n ${i}p)
      cp -rf ${WORKPATH}data/${PRODUCT}/${name} ${WORKPATH}temp/data/${name}
    done
  else
    echo "没有找到out.list"
    exit 1
  fi
  rm -rf ${WORKPATH}temp/out.list
  local OUTPATH=${WORKPATH}out/${PRODUCT}
  mkdir -p ${OUTPATH}
  local out_file=${OUTPATH}/${make_name}
  chmod +x ${WORKPATH}temp/update-binary
  7z a -tzip ${out_file} ${WORKPATH}temp/*
  rm -rf ${WORKPATH}temp
}

# 处理out_file，只接受part或p flash或f reset或r
case $output_file in
part | p)
  source ${WORKPATH}updater-script/${PRODUCT}/append.list
  if [[ -z $add_version ]] && [[ -n $part_version ]]; then
    VERSION2=${VERSION}.${part_version}
  else
    if [[ -n $add_version ]]; then
      VERSION2=${VERSION}
      echo -e "part_version=\"${add_version}\"\nflash_version=\"${flash_version}\"\nreset_version=\"${reset_version}\"" >${WORKPATH}updater-script/${PRODUCT}/append.list
    fi
  fi
  make_zip "part" "part-${PRODUCT}-auto-null-${VERSION2}.zip"
  ;;
flash | f)
  source ${WORKPATH}updater-script/${PRODUCT}/append.list
  if [[ -z $add_version ]] && [[ -n $flash_version ]]; then
    VERSION2=${VERSION}.${flash_version}
  else
    if [[ -n $add_version ]]; then
      VERSION2=${VERSION}
      echo -e "part_version=\"${part_version}\"\nflash_version=\"${add_version}\"\nreset_version=\"${reset_version}\"" >${WORKPATH}updater-script/${PRODUCT}/append.list
    fi
  fi
  make_zip "flash" "flash-${PRODUCT}-Win11_21H2-null-${VERSION2}.zip"
  ;;
reset | r)
  source ${WORKPATH}updater-script/${PRODUCT}/append.list
  if [[ -z $add_version ]] && [[ -n $reset_version ]]; then
    VERSION2=${VERSION}.${reset_version}
  else
    if [[ -n $add_version ]]; then
      VERSION2=${VERSION}
      echo -e "part_version=\"${part_version}\"\nflash_version=\"${flash_version}\"\nreset_version=\"${add_version}\"" >${WORKPATH}updater-script/${PRODUCT}/append.list
    fi
  fi
  make_zip "reset" "reset-${PRODUCT}-default-null-${VERSION2}.zip"
  ;;
all)
  source ${WORKPATH}updater-script/${PRODUCT}/append.list
  if [[ -z $add_version ]] && [[ -n $part_version ]]; then
    VERSION2=${VERSION}.${part_version}
  else
    if [[ -n $add_version ]]; then
      VERSION2=${VERSION}
      echo -e "part_version=\"${add_version}\"\nflash_version=\"${flash_version}\"\nreset_version=\"${reset_version}\"" >${WORKPATH}updater-script/${PRODUCT}/append.list
    fi
  fi
  make_zip "part" "part-${PRODUCT}-auto-null-${VERSION2}.zip"

  source ${WORKPATH}updater-script/${PRODUCT}/append.list
  if [[ -z $add_version ]] && [[ -n $flash_version ]]; then
    VERSION2=${VERSION}.${flash_version}
  else
    if [[ -n $add_version ]]; then
      VERSION2=${VERSION}
      echo -e "part_version=\"${part_version}\"\nflash_version=\"${add_version}\"\nreset_version=\"${reset_version}\"" >${WORKPATH}updater-script/${PRODUCT}/append.list
    fi
  fi
  make_zip "flash" "flash-${PRODUCT}-Win11_21H2-null-${VERSION2}.zip"

  source ${WORKPATH}updater-script/${PRODUCT}/append.list
  if [[ -z $add_version ]] && [[ -n $reset_version ]]; then
    VERSION2=${VERSION}.${reset_version}
  else
    if [[ -n $add_version ]]; then
      VERSION2=${VERSION}
      echo -e "part_version=\"${part_version}\"\nflash_version=\"${flash_version}\"\nreset_version=\"${add_version}\"" >${WORKPATH}updater-script/${PRODUCT}/append.list
    fi
  fi
  make_zip "reset" "reset-${PRODUCT}-default-null-${VERSION2}.zip"
  ;;
*)
  echo "未知包名: $out_file"
  exit 1
  ;;
esac

echo "Version: $VERSION"
echo "input_update_binary: $input_update_binary"
echo "all_version: $all_version"
echo "add_version: $add_version"
