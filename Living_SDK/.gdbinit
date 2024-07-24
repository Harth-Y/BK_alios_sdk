#GDB_PATH="/home/ming.liu/ci/workspace/sdk3.0_Verify/smartliving-1.6.0-bk7231u-master/Living_SDK/build/compiler/gcc-arm-none-eabi/Linux64/bin/arm-none-eabi-gdb"
set remotetimeout 20
shell killall openocd
shell /home/ming.liu/ci/workspace/sdk3.0_Verify/smartliving-1.6.0-bk7231u-master/Living_SDK/build/cmd/linux64/dash -c "trap \"\" 2;"/home/ming.liu/ci/workspace/sdk3.0_Verify/smartliving-1.6.0-bk7231u-master/Living_SDK/build/OpenOCD/Linux64/bin/openocd" -f .//build/OpenOCD/Linux64/interface/jlink.cfg -f .//build/OpenOCD/Linux64/bk7231u/bk7231u.cfg -f .//build/OpenOCD/Linux64/bk7231u/bk7231u_gdb_jtag.cfg -l out/openocd.log &"
