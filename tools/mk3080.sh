
tempapp="example/$2"

function files_cp()
{
	cd -
    rm -rf prebuild/*
    mkdir -p prebuild/lib; mkdir -p prebuild/include
    cp Living_SDK/out/$2@$3/libraries/*.a prebuild/lib/
    cp Living_SDK/framework/protocol/linkkit/sdk/lib/Cortex-M4/awss_security.a prebuild/lib/
    cp Living_SDK/framework/protocol/linkkit/sdk/lib/Cortex-M4/libaiotss.a prebuild/lib/
    cp Living_SDK/platform/mcu/rtl8710bn/lib/*.a prebuild/lib/
    cp -rf Living_SDK/platform/mcu/rtl8710bn/script prebuild/lib/
    rm -f prebuild/lib/$2.a

	cp -rfa Living_SDK/include/* prebuild/include
	cp -rfa Living_SDK/utility/cjson/include/* prebuild/include
	cp -rfa Living_SDK/framework/uOTA/inc/ota_service.h prebuild/include
	cp -rfa Living_SDK/framework/protocol/linkkit/sdk/iotx-sdk-c_clone/include/* prebuild/include
	cp -rfa Living_SDK/framework/protocol/linkkit/sdk/iotx-sdk-c_clone/src/infra/utils/misc/*.h prebuild/include
	cp -rfa Living_SDK/framework/protocol/linkkit/sdk/iotx-sdk-c_clone/src/infra/log/*.h prebuild/include

	cp --parents Living_SDK/kernel/rhino/core/include/* prebuild/include
	cp --parents Living_SDK/kernel/vfs/include/*.h prebuild/include
		mv prebuild/include/Living_SDK/kernel prebuild/include

	cp --parents Living_SDK/framework/netmgr/include/*.h prebuild/include
		mv prebuild/include/Living_SDK/framework prebuild/include

	cp --parents Living_SDK/platform/mcu/include/* prebuild/include
	cp --parents Living_SDK/platform/arch/arm/armv7m/gcc/m4/*.h prebuild/include
		mv prebuild/include/Living_SDK/platform prebuild/include

	cp --parents Living_SDK/board/$3/*.h prebuild/include
		mv prebuild/include/Living_SDK/board prebuild/include

	rm -rf prebuild/include/Living_SDK
	cp -f Products/$1/$2/$2.mk_old Products/$1/$2/$2.mk
}

function build_bin()
{
	mkdir -p out
	OUT=out/$2@$3
	rm -rf $OUT
	mkdir -p $OUT
	app_ver=$(sed -n '/CONFIG_FIRMWARE_VERSION\ =/p' Products/$1/$2/$2.mk| sed -e 's/ //g' -e 's/\r//g')
	echo "make version--framework.a $1 APP_NAME=$2 BOARD=$3 ARGS=$4 $app_ver"
	cd Service/version
	make clean; make APP=$2 PLATFORM=$3 BOARD=$3 CONFIG_SERVER_REGION=$4 CONFIG_SERVER_ENV=$5 CONFIG_DEBUG=$6 $app_ver $7
	cd -

	echo "make app"
	cd Products/$1/$2
	make clean; make APP=$2 PLATFORM=$3 BOARD=$3 CONFIG_SERVER_REGION=$4 CONFIG_SERVER_ENV=$5 CONFIG_DEBUG=$6 $7
	cd -
	##  build elf
	cd prebuild/lib
	CHIP=rtl8710bn
	CC=arm-none-eabi-gcc
	OBJCOPY=arm-none-eabi-objcopy
	STRIP=arm-none-eabi-strip
	ARCH=arch_armv7m
	p=prebuild/lib
	CHIP_LIBS="-Wl,--end-group -Wl,-no-whole-archive -Wl,--gc-sections -Wl,--cref -L ./$p/ -l_platform -l_wlan -l_wps -l_p2p -l_rtlstd -T ./$p/script/rlx8711B-symbol-v02-img2_xip1_mxchip.ld -mcpu=cortex-m4 -mthumb -Os -nostartfiles -Wl,--no-enum-size-warning -Wl,--no-wchar-size-warning -Wl,--gc-sections -Wl,--cref --specs=nano.specs -u _printf_float "
	if [[ "$2" == httpapp ]] || [[ "$2" == coapapp ]];then
		COMMON_LIBS="$p/$2.a  $p/board_$3.a  $p/$CHIP.a  $p/vcall.a  $p/kernel_init.a  $p/auto_component.a   $p/libiot_sdk.a $p/iotx-hal.a  $p/netmgr.a  $p/framework.a  $p/cjson.a  $p/cli.a   $p/$ARCH.a  $p/newlib_stub.a  $p/rhino.a  $p/digest_algorithm.a  $p/net.a $p/rtl8710bn_SDK.a  $p/rtl8710bn_Peripheral_Drivers.a $p/log.a  $p/activation.a  $p/chip_code.a  $p/imbedtls.a  $p/kv.a  $p/yloop.a  $p/hal.a  $p/alicrypto.a  $p/vfs.a  $p/vfs_device.a   $p/awss_security.a $p/libaiotss.a "
	else
		COMMON_LIBS="$p/$2.a  $p/board_$3.a  $p/$CHIP.a  $p/vcall.a  $p/kernel_init.a  $p/auto_component.a   $p/libiot_sdk.a $p/iotx-hal.a  $p/netmgr.a  $p/framework.a  $p/cjson.a  $p/ota.a  $p/cli.a  $p/ota_hal.a  $p/$ARCH.a  $p/newlib_stub.a  $p/rhino.a  $p/digest_algorithm.a  $p/net.a $p/rtl8710bn_SDK.a  $p/rtl8710bn_Peripheral_Drivers.a $p/log.a  $p/activation.a  $p/chip_code.a  $p/imbedtls.a  $p/kv.a  $p/yloop.a  $p/hal.a  $p/ota_transport.a  $p/ota_download.a  $p/ota_verify.a  $p/base64.a  $p/alicrypto.a  $p/vfs.a  $p/vfs_device.a   $p/awss_security.a $p/libaiotss.a "
	fi
	cd -
 	$CC --static -Wl,-static -Wl,--warn-common -Wl,-Map,$OUT/$2@$3.map  -Wl,--whole-archive -Wl,--start-group  ${COMMON_LIBS} ${CHIP_LIBS}  -o $OUT/$2@$3.elf

	## generate map & strip elf
	 /usr/bin/python ./tools/scripts/map_parse_gcc.py $OUT/$2@$3.map > $OUT/$2@$3_map.csv
	$STRIP  -o $OUT/$2@$3.stripped.elf  $OUT/$2@$3.elf
	/usr/bin/python ./tools/scripts/map_parse_gcc.py $OUT/$2@$3.map

	## gen bin
	$OBJCOPY -O binary -R .eh_frame -R .init -R .fini -R .comment -R .ARM.attributes  $OUT/$2@$3.stripped.elf $OUT/$2@$3.bin
	$OBJCOPY -O ihex -R .eh_frame -R .init -R .fini -R .comment -R .ARM.attributes  $OUT/$2@$3.stripped.elf $OUT/$2@$3.hex

	$OBJCOPY -j .xip_image2.text -Obinary $OUT/$2@$3.elf $OUT/$2@$3.text.bin
	$OBJCOPY  -j .ram_image2.entry -j .ram_image2.text -j .ram_image2.data -Obinary $OUT/$2@$3.elf $OUT/$2@$3.data.bin
	/usr/bin/python ./tools/rtl8710bn/pick.py $OUT/$2@$3.text.bin $OUT/$2@$3.data.bin $OUT/$2@$3.bin
	/usr/bin/python ./tools/scripts/gen_common_bin_output_file.py -o $OUT/$2@$3.all.bin -f 0x000000 ./Living_SDK/board/$3/boot.bin
	/usr/bin/python ./tools/scripts/gen_common_bin_output_file.py -o $OUT/$2@$3.all.bin -f 0x013000 $OUT/$2@$3.bin
	/usr/bin/python ./tools/scripts/gen_common_bin_output_file.py -o $OUT/$2@$3.all.bin -f 0x0D0000 ./Living_SDK/board/$3/ate.bin
	/usr/bin/python ./tools/scripts/ota_gen_md5_bin.py $OUT/$2@$3.bin
	cp -f $OUT/$2@$3.bin $OUT/$2@$3.ota.bin
	/usr/bin/python ./tools/scripts/ota_gen_md5_bin.py $OUT/$2@$3.bin
	mv out/readme.txt $OUT
}

## check toolchain ##
if [ ! -f Living_SDK/build/compiler/gcc-arm-none-eabi/Linux64/bin/arm-none-eabi-gcc ];then
        echo "download toolchain"
        mkdir -p Living_SDK;mkdir -p Living_SDK/build;mkdir -p Living_SDK/build/compiler;mkdir -p Living_SDK/build/compiler/gcc-arm-none-eabi
        cd tools && git clone --depth=1 https://gitee.com/alios-things/gcc-arm-none-eabi-linux.git && mv gcc-arm-none-eabi-linux/main ../Living_SDK/build/compiler/gcc-arm-none-eabi/ && mv ../Living_SDK/build/compiler/gcc-arm-none-eabi/main ../Living_SDK/build/compiler/gcc-arm-none-eabi/Linux64 && rm -rf gcc-arm-none-eabi-linux && cd -
fi

##  build aos  ##
if [[ ! -d Living_SDK/example/$2 ]] || [[ ! -d Living_SDK/out/$2@$3 ]]; then
	if [[ -d Living_SDK/example ]] && [[ -d Products/$1 ]] && [[ -d Products/$1/$2 ]]; then
		echo "do cp"
		rm -rf Living_SDK/example/$2
		#cp -rf Products/$1/$2 Living_SDK/example/$2
		mv -f Products/$1/$2/$2.mk Products/$1/$2/$2.mk_old
		cd Living_SDK/example
		ln -s ../../Products/$1/$2 .
		cd -
		
		./tools/cmd/linux64/awk '{ gsub("'./make.settings'","example/${APP_FULL}/make.settings"); gsub("'"\?= MAINLAND"'","'"?= $4"'"); gsub("'"\?= ONLINE"'","'"?= $5"'"); gsub("'"CONFIG_DEBUG\ \?=\ 0"'","'"CONFIG_DEBUG ?= $6"'");   print $0 }' Products/$1/$2/$2.mk_old > Living_SDK/${tempapp}/$2.mk

		echo "make aos sdk: $2@$3 CONFIG_SERVER_REGION=$4 CONFIG_SERVER_ENV=$5 CONFIG_DEBUG=$6 $7"
		cd Living_SDK
		aos make clean
		aos make $2@$3 CONFIG_SERVER_REGION=$4 CONFIG_SERVER_ENV=$5 CONFIG_DEBUG=$6 $7
		echo "cp libs and incs..."
		files_cp $1 $2 $3
	else
	    echo "folder Living_SDK/example or Products/$1/$2 is not existed!"
	fi 
else 
	if [ -d Living_SDK/example ]; then
		echo "$2 folder is existed! check $2.mk file."
		
		diff Living_SDK/${tempapp}/$2.mk Living_SDK/${tempapp}/$2.mk_old > Living_SDK/diff.txt

		if [[ -s Living_SDK/diff.txt ]] || [[ ! -f prebuild/lib/board_$3.a ]]; then
			echo "need rebuild all again!"
			mv -f Products/$1/$2/$2.mk Products/$1/$2/$2.mk_old
			./tools/cmd/linux64/awk '{ gsub("'./make.settings'","example/${APP_FULL}/make.settings"); gsub("'"\?= MAINLAND"'","'"?= $4"'"); gsub("'"\?= ONLINE"'","'"?= $5"'"); gsub("'"CONFIG_DEBUG\ \?=\ 0"'","'"CONFIG_DEBUG ?= $6"'");   print $0 }' Products/$1/$2/$2.mk_old > Living_SDK/${tempapp}/$2.mk
			cd Living_SDK
			aos make clean
			aos make $2@$3 CONFIG_SERVER_REGION=$4 CONFIG_SERVER_ENV=$5 CONFIG_DEBUG=$6 $7
			echo "cp libs and incs..."
			files_cp $1 $2 $3
		fi
	fi
fi

echo "start to build app......"
build_bin $1 $2 $3 $4 $5 $6 "$7"




