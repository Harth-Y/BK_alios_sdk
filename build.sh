#!/bin/bash

##------default config-----------------------------------------------------------------------------------##

# 设置默认的类型、应用程序名称、电路板、区域、环境、调试级别和参数
default_type="example"
default_app="beken_test"
default_board="bk7231ndevkitc"
default_region=MAINLAND
default_env=ONLINE
default_debug=0
default_args=""

##-------------------------------------------------------------------------------------------------------##

# 如果定义了 ALIOS_COMPILER_PATH 环境变量，则检查编译器路径是否存在，若不存在，则使用指定的路径创建符号链接，并输出使用的编译器路径
if [ $ALIOS_COMPILER_PATH ]; then
	if [! -f Living_SDK/build/compiler/gcc-arm-none-eabi/Linux64/bin/arm-none-eabi-gcc ]; then
		if [ -d Living_SDK/build/compiler ]; then
			mv Living_SDK/build/compiler Living_SDK/build/compiler_bak
		fi
		ln -s $ALIOS_COMPILER_PATH Living_SDK/build/compiler
		echo "Use specified compiler: $ALIOS_COMPILER_PATH"
	fi
fi

# 备份当前 PATH 环境变量，并添加编译器路径到 PATH 变量中
path_tmp=$PATH
export PATH=$path_tmp:$(pwd)/Living_SDK/build/compiler/gcc-arm-none-eabi/Linux64/bin/

# 记录开始时间
start_time=$(date +%s)

# 判断当前操作系统类型
if [ "$(uname)" = "Linux" ]; then
    CUR_OS="Linux"
elif [ "$(uname)" = "Darwin" ]; then
    CUR_OS="OSX"
elif [ "$(uname | grep NT)"!= "" ]; then
    CUR_OS="Windows"
else
    echo "error: unkonw OS"
    exit 1
fi

# 设置应用程序名称，如果未提供，则使用默认值
app=$2
if [ xx"$2" == xx ]; then
        app=$default_app
fi

# 处理清理命令，如果命令行参数是 clean，则删除 Living_SDK/example/$app、out 和 Living_SDK/out 目录，然后退出脚本
if [[ xx"$1" == xxclean ]]; then
	rm -rf Living_SDK/example/$app
	rm -rf out
	rm -rf Living_SDK/out
	#git checkout Living_SDK/example
	exit 0
fi

# 处理帮助命令，如果命令行参数是 help、--help、-h 或 -help，则输出帮助信息并退出脚本
if [[ xx"$1" == xx--help ]] || [[ xx"$1" == xxhelp ]] || [[ xx"$1" == xx-h ]] || [[ xx"$1" == xx-help ]]; then
	echo "./build.sh $default_type $default_app $default_board $default_region $default_env $default_debug $default_args "
	exit 0
fi

# 设置类型，如果命令行参数是 --type，则设置为命令行参数，否则默认为 default_type
type=$1
if [ xx"$1" == xx ]; then
	type=$default_type
fi

# 设置电路板，如果命令行参数是 --board，则设置为命令行参数，否则默认为 default_board
board=$3
if [ xx"$3" == xx ]; then
	board=$default_board
fi

# 设置区域，如果命令行参数是 --region，则设置为命令行参数，否则默认为 default_region
if [[ xx$4 == xx ]]; then
	echo "REGION SET AS MAINLAND"
	REGION=$default_region
else
	REGION=$4
fi

# 设置环境，如果命令行参数是 --env，则设置为命令行参数，否则默认为 default_env
if [[ xx$5 == xx ]]; then
	echo "ENV SET AS ONLINE"
	ENV=$default_env
else
	ENV=$5
fi

# 设置调试级别，如果命令行参数是 --debug，则设置为命令行参数，否则默认为 default_debug
if [[ xx$6 == xx ]]; then
	echo "CONFIG_DEBUG SET AS 0"
	CONFIG_DEBUG=$default_debug
else
	CONFIG_DEBUG=$6
fi

# 设置其他参数，如果命令行参数是 --args，则设置为命令行参数，否则默认为 default_args
if [[ xx$7 == xx ]]; then
	echo "ARGS SET AS NULL"
	ARGS=$default_args
else
	ARGS="$7"
fi

# 更新指定的产品线的代码仓库到最新版本
function update_golden_product()
{
	gp_type=$1
	gp_app=$2
	git submodule update --init --remote Products/$gp_type/$gp_app
	if [ $? -ne 0 ]; then
		echo 'code download or update error!'
		exit 1
	fi
}

# 修改配置文件中的宏定义
modify_config(){
	sed -i '/\(\s*#define\s*\)\<'$2'\>\(\s*\)\([0-9]*\)/\1'$2'\2'$3'/g' $1
}

# 如果应用程序是 beken_test，且电路板是 bk7231ndevkitc，则修改 BEKEN_TEST_BLE_CFG_FILE 文件中的 CONFIG_BEKEN_BLE_4_2 宏定义为 0
if [[ "$app" == "beken_test" ]]; then
	BEKEN_TEST_BLE_CFG_FILE=Products/example/beken_test/beken_test_ble.h
	if [[ "$board" == "bk7231ndevkitc" ]]; then
		modify_config ${BEKEN_TEST_BLE_CFG_FILE} CONFIG_BEKEN_BLE_4_2 0
	# 如果应用程序是 beken_test，且电路板是 bk7231udevkitc，则修改 BEKEN_TEST_BLE_CFG_FILE 文件中的 CONFIG_BEKEN_BLE_4_2 宏定义为 1
	elif [[ "$board" == "bk7231udevkitc" ]]; then
		modify_config ${BEKEN_TEST_BLE_CFG_FILE} CONFIG_BEKEN_BLE_4_2 1
	fi
	# 删除.board 文件
	rm -f.board
	# 将电路板名称写入到.board 文件中
	echo $board >.board
fi

#  更新 golden_product 产品线的代码仓库到最新版本
if [[ "${type}-${app}" == "Smart_outlet-smart_outlet_meter" ]] || [[ "${type}-${app}" == "Smart_lighting-smart_led_strip" ]] || [[ "${type}-${app}" == "Smart_lighting-smart_led_bulb" ]]; then
	echo 'golden sample product--------------------'
	update_golden_product $type $app
fi

# 如果指定的应用程序目录存在，但没有找到对应的 makefile 文件，则删除原有的应用程序目录
if [[ -d Products/$type/$app ]] && [[! -f prebuild/lib/board_$board.a ]]; then
	rm -rf Living_SDK/example/$app
	# git checkout Living_SDK/example
fi

# 打印当前的路径、操作系统类型、产品类型、应用程序名称、电路板、区域、环境、调试级别和参数
echo "----------------------------------------------------------------------------------------------------"
echo "PATH=$PATH"
echo "OS: ${CUR_OS}"
echo "Product type=$type app_name=$app board=$board REGION=$REGION ENV=$ENV CONFIG_DEBUG=$CONFIG_DEBUG ARGS=$ARGS"
echo "----------------------------------------------------------------------------------------------------"

# 如果指定的应用程序目录存在，但没有找到对应的 makefile 文件，则拷贝 Smart_outlet 产品线的 makefile 文件到当前应用程序目录，并替换其中的应用程序名
if [[ -d Products/$type/$app ]] && [[! -f Products/$type/$app/makefile ]]; then
	./tools/cmd/linux64/awk '{ gsub("'"smart_outlet"'","'"$app"'");  print $0 }' Products/Smart_outlet/smart_outlet/makefile > Products/$type/$app/makefile
fi

# build_end 函数：打印编译耗时并恢复 PATH 环境变量
function build_end()
{
	# 记录结束时间
	end_time=$(date +%s)
	# 计算编译消耗时间
	cost_time=$[ $end_time-$start_time ]
	# 输出编译耗时信息
	echo "build time is $(($cost_time/60))min $(($cost_time%60))s"
	# 恢复 PATH 环境变量
	export PATH=$path_tmp
}

# build_sdk 函数：构建 SDK，包括清理环境、设置编译参数、编译代码，最后检查编译结果
function build_sdk()
{
	# 创建 out 目录，为每个应用程序-电路板组合创建单独的目录，并清理其中的内容
	mkdir -p out;mkdir -p out/$app@${board}
	rm -rf out/$app@${board}/*

	# 检查 Products/$type/$app 目录是否存在，并且 Living_SDK/example/$app 是否存在，若存在，则进行下一步
	if [[ -d Products/$type/$app ]] && [[! -f Products/$type/$app/makefile ]]; then
		# 备份当前目录，进入 Living_SDK 目录
		cd Living_SDK
		# 清理之前的编译结果
		aos make clean

		# 显示编译命令信息，然后执行编译
		echo -e "aos make $app@${board} CONFIG_SERVER_REGION=${REGION} CONFIG_SERVER_ENV=${ENV} CONFIG_DEBUG=${CONFIG_DEBUG} $ARGS"
		aos make $app@${board} CONFIG_SERVER_REGION=${REGION} CONFIG_SERVER_ENV=${ENV} CONFIG_DEBUG="${CONFIG_DEBUG}" "$ARGS"

		# 返回原目录
		cd -

		# 检查 Living_SDK/out/$app@${board}/binary 目录下是否存在 $app@${board}.bin 文件，若存在，则表明编译成功，拷贝文件到 out 目录并结束脚本
		if [[ -f Living_SDK/out/$app@${board}/binary/$app@${board}.bin ]]; then
			cp -rfa Living_SDK/out/$app@${board}/binary/* out/$app@${board}
			# 调用 build_end 函数，打印编译耗时信息
			build_end
			exit 0
		else
			# 编译失败信息提醒
			echo "build failed!"
			exit 1
		fi
	fi
}

# 开始构建过程
# 如果 out 目录或者 Living_SDK/example 目录不存在，则创建它们
# 如果 Products/$type/$app 目录或者 Living_SDK/example/$app 目录不存在，则打印错误信息并退出脚本
mkdir -p out;mkdir -p out/$app@${board}
rm -rf out/$app@${board}/*

if [[! -d Products/$type ]] || [[! -d Products/$type/$app ]]; then
	echo "path of Products/$type or Products/$type/$app don't exist!"
	if [[! -d Living_SDK/example/$app ]]; then
		echo "path of Living_SDK/example  don't exist!"
		exit 1
	else
		# 进入 Living_SDK 目录，清理编译环境
		cd Living_SDK
		# 清理之前的编译结果
		aos make clean
fi



