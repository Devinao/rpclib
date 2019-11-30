#!/bin/bash
platform=$1
build_mode=$2
project=$3
para_mode=$4

force_compile=true
compile_dir=""


# 必备功能
# sys
os_env=linux
sys_arch=x64

armv8_android=OFF
armv7_android=OFF
zu3_set=OFF
cv22_chip=OFF
cv22_set=OFF
bfs_accelerate=OFF
shared_libs=ON
cpu_only=ON
compile_test=OFF
use_neon=OFF
use_gsensor_log=OFF
use_minidnn=OFF
avm_set=OFF
m4_set=OFF
aeb_set=OFF
x1d_set=OFF
x1d3_set=OFF
arm_sdk_set=OFF
linux_pc=OFF
para_from_gflags=OFF

# common 仓库切换成对应的版本
if [ $platform = "armv8-android" ]; then
    echo "=====>Armv8-android(M3/M4) Platform<====="
    compile_dir=armv8-android
    os_env=armv8-android
    sys_arch=arm64
    armv8_android=ON

    use_neon=ON
    debug_show_mode=OFF
    debug_save_mode=OFF
    display_result=OFF
    use_minidnn=ON
    shared_libs=OFF
elif [ $platform = "linux" ]; then
    echo "=====>Linux Platform<====="
    compile_dir=linux
    os_env=linux
    sys_arch=x64
    display_result=ON
    debug_save_mode=OFF
    debug_show_mode=OFF
    build_tool=ON
    use_gsensor_log=ON
    linux_pc=ON
elif [ $platform = "armv7-linux" ]; then
    echo "=====>Armv7-linux(X1) Platform <====="
    compile_dir=armv7-linux
    os_env=armv7-linux
    sys_arch=arm
    armv7_android=ON

    fpga_accelerate=ON
    use_neon=ON
    debug_save_mode=OFF
    debug_show_mode=OFF
elif [ $platform = "armv8-linux" ]; then
    echo "=====>armv8-linux(ZU3) Platform <====="
    compile_dir=armv8-linux
    os_env=armv8-linux
    sys_arch=arm64

    fpga_accelerate=ON # to be verified
    os_env=armv8-linux
    use_neon=ON
    zu3_set=ON
    debug_save_mode=OFF
    debug_show_mode=OFF
elif [ $platform = "armv7-android" ]; then
    echo "======> Armv7-android(F1) Platform"
    compile_dir=armv7-android
    os_env=armv7-android
    sys_arch=arm
    armv7_android=ON

    use_ncnn=ON
    use_neon=ON
    debug_show_mode=OFF
    debug_save_mode=OFF
    display_result=OFF
elif [ $platform = "cv22" ]; then
    echo "======> CV22 Platform"
    compile_dir=cv22
    os_env=armv8
    sys_arch=armv8

    use_neon=ON
    debug_show_mode=OFF
    debug_save_mode=OFF
    display_result=OFF
else
    echo "Error : Unsupport Platform :"${platform}
    exit 0
fi

cv22_sys_include_dir=""
gpu_on=OFF

if [ ${platform} = "cv22" ]; then
    cv22_chip=ON
    cv22_sw_sdk_dir=${HOME}/data3/amba/sw-sdk/
    cv22_sys_include_dir=${cv22_sw_sdk_dir}/usr/aarch64-buildroot-linux-gnu/sysroot/usr/include/
    cv22_include_dir=${cv22_sw_sdk_dir}/usr/aarch64-buildroot-linux-gnu/sysroot/usr/local/include/
    cv22_lib_dir=${cv22_sw_sdk_dir}/usr/aarch64-buildroot-linux-gnu/sysroot/usr/local/lib/
elif [ ${platform} = "armv7-linux" ]; then
    bfs_accelerate=ON
elif [ ${platform} = "armv8-android" ]; then
    install_include_dir=${HOME}/data3/lane_repo/dfg_lane_m4/include/
    install_lib_dir=${HOME}/data3/lane_repo/dfg_lane_m4/lib/
elif [ ${platform} = "linux" ]; then
    echo "linux platform ..."
    compile_test=ON
fi

if [ ${project} = "avm" ]; then
    avm_set=ON
    install_include_dir=${HOME}/data3/lane_repo/lane_cv22/include/
    install_lib_dir=${HOME}/data3/lane_repo/lane_cv22/lib/
fi

if [ ${project} = "cv22" ]; then
    cv22_set=ON
    lane_cv22_dir=${HOME}/data3/lane_repo/lane_cv22
    install_include_dir=${lane_cv22_dir}/include/
    install_lib_dir=${lane_cv22_dir}/lib/
fi

if [ ${project} = "c1" ]; then
    cv22_set=ON
    lane_cv22_dir=${HOME}/data3/lane_repo/lane_cv22
    install_include_dir=${lane_cv22_dir}/include/
    install_lib_dir=${lane_cv22_dir}/lib/
fi

if [ ${project} = "m4" ]; then
    m4_set=ON
    shared_libs=OFF
    lane_m4_dir=${HOME}/data3/lane_repo/dfg_lane_m4
    install_include_dir=${lane_m4_dir}/include/
    install_lib_dir=${lane_m4_dir}/lib/
fi

if [ ${project} = "m4c" ]; then
    m4_set=ON
    shared_libs=OFF
    lane_m4_dir=${HOME}/data3/lane_repo/dfg_lane_m4
    install_include_dir=${lane_m4_dir}/include/
    install_lib_dir=${lane_m4_dir}/lib/
fi

if [ ${project} = "m5-gpu" ]; then
    m4_set=ON
    gpu_on=ON
    shared_libs=OFF
    lane_m4_dir=${HOME}/data3/lane_repo/dfg_lane_m4
    install_include_dir=${lane_m4_dir}/include/
    install_lib_dir=${lane_m4_dir}/lib/
fi

if [ ${project} = "sansheng" ]; then
    m4_set=ON
    shared_libs=OFF
    lane_m4_dir=${HOME}/data3/lane_repo/dfg_lane_m4
    install_include_dir=${lane_m4_dir}/include/
    install_lib_dir=${lane_m4_dir}/lib/
fi


if [ ${project} = "arm-gpu" ]; then
    m4_set=ON
    gpu_on=ON
    shared_libs=OFF
    lane_m4_dir=${HOME}/data3/lane_repo/dfg_lane_m4
    install_include_dir=${lane_m4_dir}/include/
    install_lib_dir=${lane_m4_dir}/lib/
fi

if [ ${project} = "aeb" ]; then
    aeb_set=ON
    aeb_dir=${HOME}/data3/lane_repo/dfg_lane
    install_include_dir=${aeb_dir}/include/
    install_lib_dir=${aeb_dir}/lib/
fi

if [ ${project} = "x1d3" ]; then
    x1d3_set=ON
    aeb_dir=${HOME}/data3/lane_repo/dfg_lane
    install_include_dir=${aeb_dir}/include/
    install_lib_dir=${aeb_dir}/lib/
fi

if [ ${project} = "x1d" ]; then
    x1d_set=ON
    x1d_dir=${HOME}/data3/lane_repo/dfg_lane_x1d
    install_include_dir=${x1d_dir}/include/
    install_lib_dir=${x1d_dir}/lib/
fi

if [ ${project} = "arm-sdk" ]; then
    arm_sdk_set=ON
    prj_dir=${HOME}/data3/lane_repo/dfg_lane_m4
    install_include_dir=${prj_dir}/include/
    install_lib_dir=${prj_dir}/lib
fi

if [ ${project} = "ipc" ]; then
    prj_dir=${HOME}/data3/lane_repo/dfg_lane
    install_include_dir=${prj_dir}/include/
    install_lib_dir=${prj_dir}/lib
fi


if [ ${project} = "liuqi" ]; then
    prj_dir=${HOME}/data3/lane_repo/dfg_lane
    install_include_dir=${prj_dir}/include/
    install_lib_dir=${prj_dir}/lib
fi

if [ ${project} = "x1j" ]; then
    prj_dir=${HOME}/data3/lane_repo/dfg_lane
    install_include_dir=${prj_dir}/include/
    install_lib_dir=${prj_dir}/lib
fi


if [ ${project} = "aeb-gpu" ]; then
    gpu_on=ON
    aeb_dir=${HOME}/data3/lane_repo/dfg_lane
    install_include_dir=${aeb_dir}/include/
    install_lib_dir=${aeb_dir}/lib/
fi

if [ ${project} = "apa" ]; then
    apa_dir=${HOME}/data3/apa_repo/dfg_apa
    install_include_dir=${apa_dir}/include/
    install_lib_dir=${apa_dir}/lib
fi

if [ ${para_mode} = "gflags" ]; then
    para_from_gflags=ON
fi

config=(
"-DCMAKE_INSTALL_PREFIX=${install_prefix}"
"-DOS_ENV=${os_env}"
"-DSYS_ARCH=${sys_arch}"
"-DCMAKE_BUILD_TYPE=${build_mode}"
"-DWITH_FPGA_ACCELERATE=${fpga_accelerate}"
"-DWITH_NEON=${use_neon}"
"-DWITH_CPU_ONLY=${cpu_only}"
"-DWITH_TEST=${compile_test}"
"-DWITH_ZU3=${zu3_set}"
"-DWITH_CV22_CHIP=${cv22_chip}"
"-DANDROID_ARMV7=${armv7_android}"
"-DANDROID_ARMV8=${armv8_android}"
"-DCV22_INCLUDE_DIR=${cv22_include_dir}"
"-DCV22_LIB_DIR=${cv22_lib_dir}"
"-DINSTALL_INCLUDE_DIR=${install_include_dir}"
"-DINSTALL_LIB_DIR=${install_lib_dir}"
"-DBUILD_SHARED_LIBS=${shared_libs}"
"-DCV22_SYS_INCLUDE_DIR=${cv22_sys_include_dir}"
"-DWITH_BFS_ACCELERATE=${bfs_accelerate}"
"-DWITH_GSENSOR_LOG=${use_gsensor_log}"
"-DWITH_MINIDNN=${use_minidnn}"
"-DWITH_CV22=${cv22_set}"
"-DWITH_AVM=${avm_set}"
"-DWITH_M4=${m4_set}"
"-DWITH_AEB=${aeb_set}"
"-DWITH_X1D3=${x1d3_set}"
"-DWITH_X1D=${x1d_set}"
"-DWITH_LINUX_PC=${linux_pc}"
"-DWITH_GFLAGS_PARA=${para_from_gflags}"
"-DWITH_GPU=${gpu_on}"
"-DWITH_ARM_SDK=${arm_sdk_set}"
 )

