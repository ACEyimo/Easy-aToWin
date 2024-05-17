# #!/bin/bash
# 建议使用bash执行
# 参数1 型号
# 参数2 版本
# 参数3 使用指定版本的update-binary，非必选，默认使用new.sh
WORKPATH=$(pwd)/
PRODUCT=$1
VERSION=$2
USE_binary=""

if [[ -z "$2"  || -z "$1" ]]; then
    echo "参数错误，请检查"
    exit 1
fi
if [[ -z "$3" ]]; then
    USE_binary="${WORKPATH}update-binary/new.sh"
else
    USE_binary="${WORKPATH}update-binary/$3/update-binary.sh"
fi

LONG_DIR_NAME="META-INF/com/google/android/"

rm -rf ${WORKPATH}temp/
mkdir -p ${WORKPATH}temp/part/${LONG_DIR_NAME}
mkdir -p ${WORKPATH}temp/flash/${LONG_DIR_NAME}
mkdir -p ${WORKPATH}temp/reset/${LONG_DIR_NAME}

cp -rf ${USE_binary} ${WORKPATH}temp/part/${LONG_DIR_NAME}update-binary
cp -rf ${USE_binary} ${WORKPATH}temp/flash/${LONG_DIR_NAME}update-binary
cp -rf ${USE_binary} ${WORKPATH}temp/reset/${LONG_DIR_NAME}update-binary

cp -rf ${WORKPATH}updater-script/${PRODUCT}/part.sh ${WORKPATH}temp/part/${LONG_DIR_NAME}updater-script
cp -rf ${WORKPATH}updater-script/${PRODUCT}/flash.sh ${WORKPATH}temp/flash/${LONG_DIR_NAME}updater-script
cp -rf ${WORKPATH}updater-script/${PRODUCT}/reset.sh ${WORKPATH}temp/reset/${LONG_DIR_NAME}updater-script

cp -rf ${WORKPATH}bin ${WORKPATH}temp/part/
cp -rf ${WORKPATH}bin ${WORKPATH}temp/flash/
cp -rf ${WORKPATH}bin ${WORKPATH}temp/reset/

mkdir -p ${WORKPATH}temp/part/data
mkdir -p ${WORKPATH}temp/flash/data
mkdir -p ${WORKPATH}temp/reset/data
cp -rf ${WORKPATH}data/efi.tar ${WORKPATH}temp/flash/data/efi.tar
cp -rf ${WORKPATH}data/${PRODUCT}/boot.img ${WORKPATH}temp/reset/data/boot.img || echo "发送boot就算失败了后续命令也要执行"

part_lins=0
flash_lins=0
reset_lins=0
if [[ -f ${WORKPATH}data/${PRODUCT}/out.list ]]; then
    touch ${WORKPATH}temp/part.list
    cat ${WORKPATH}data/${PRODUCT}/out.list | grep part | sed 's\part \\g' >${WORKPATH}temp/part.list
    touch ${WORKPATH}temp/flash.list
    cat ${WORKPATH}data/${PRODUCT}/out.list | grep flash | sed 's\flash \\g' >${WORKPATH}temp/flash.list
    touch ${WORKPATH}temp/reset.list
    cat ${WORKPATH}data/${PRODUCT}/out.list | grep reset | sed 's\reset \\g' >${WORKPATH}temp/reset.list

    part_lins=$(cat ${WORKPATH}temp/part.list | wc -l)
    flash_lins=$(cat ${WORKPATH}temp/flash.list | wc -l)
    reset_lins=$(cat ${WORKPATH}temp/reset.list | wc -l)
fi

for ((i = 1; i <= part_lins; i++)); do
    part_name=$(cat ${WORKPATH}temp/part.list | sed -n ${i}p)
    cp -rf ${WORKPATH}data/${PRODUCT}/${part_name} ${WORKPATH}temp/part/data/${part_name}
done
for ((i = 1; i <= flash_lins; i++)); do
    flash_name=$(cat ${WORKPATH}temp/flash.list | sed -n ${i}p)
    cp -rf ${WORKPATH}data/${PRODUCT}/${flash_name} ${WORKPATH}temp/flash/data/${flash_name}
done
for ((i = 1; i <= reset_lins; i++)); do
    reset_name=$(cat ${WORKPATH}temp/reset.list | sed -n ${i}p)
    cp -rf ${WORKPATH}data/${PRODUCT}/${reset_name} ${WORKPATH}temp/reset/data/${reset_name}
done

OUTPATH=${WORKPATH}out/${PRODUCT}
mkdir -p ${OUTPATH}

out_part=${OUTPATH}/part-${PRODUCT}-auto-null-${VERSION}.zip
out_flash=${OUTPATH}/flash-${PRODUCT}-Win11_21H2-null-${VERSION}.zip
out_reset=${OUTPATH}/reset-${PRODUCT}-default-null-${VERSION}.zip

chmod +x ${WORKPATH}temp/part/update-binary
7z a -tzip ${out_part} ${WORKPATH}temp/part/*
chmod +x ${WORKPATH}temp/flash/update-binary
7z a -tzip ${out_flash} ${WORKPATH}temp/flash/*
chmod +x ${WORKPATH}temp/reset/update-binary
7z a -tzip ${out_reset} ${WORKPATH}temp/reset/*

echo is Over and clear cache...
rm -rf ${WORKPATH}temp/
exit 0
