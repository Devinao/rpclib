#!/bin/bash
Program=${0##*/}

show_usage() {
  echo "Usage: $Program [Options] <target> [build_type]"
  echo
  echo "Options:"
  echo "  -h, --help             Show help message and exit"
  echo
  echo "Target:"
  echo "  linux (default)"
  echo "  armv8-android"
  echo "  armv7-linux"
  echo "  armv8-linux"
  echo "  armv7-android"
  echo "  cv22"
  echo
  echo "Build type:"
  echo "  release (default)"
  echo "  debug"
  echo
  echo "Project:"
  echo "  apa"
  echo "  c1"
  echo
  echo "Shared libs:"
  echo "  shared "
  echo "  static "
  echo
}

if [ $# -eq 0 ];then
    show_usage
    exit 1
fi

while [[ $# -gt 0 ]]
do
  case "$1" in
    -h|--help)
      show_usage
      exit
      ;;
    -*)
      echo "Error: unknown option: $1"
      exit 1
      ;;
  *)
    if [ "_$Target" = "_" ]; then
      Target="$1"
      shift
    elif [ "_$BuildType" = "_" ]; then
      case "${1,,}" in
        release)
          BuildType=Release
          ;;
        debug)
          BuildType=Debug
          ;;
        *)
          echo "Error: invalid build type"
          exit 1
          ;;
      esac
      shift
    elif [ "_$Project" = "_" ]; then
        Project="$1"
        shift
    elif [ "_$Shared" = "_" ]; then
        Shared="$1"
        shift
    else
      echo "Error: too many positional arguments"
      exit 1
    fi
    ;;
  esac
done

if [ "_$Target" = "_" ]; then
    LibMode=linux
fi

if [ "_$BuildType" = "_" ]; then
    BuildType=Release
fi

if [ "_$Project" = "_" ]; then
    Project=x1
fi

if [ "_$Shared" = "_" ]; then
    Shared=shared
fi

compile_dir=""

if [ $Target = "armv8-android" ]; then
    echo "=====>Armv8-android(M3/M4) Platform<====="
    compile_dir=armv8-android
    os_env=armv8-android
    sys_arch=arm64
    armv8_android=ON
    use_neon=ON
elif [ $Target = "linux" ]; then
    echo "=====>Linux Platform<====="
    compile_dir=linux
    os_env=linux
    sys_arch=x64
    linux_pc=ON
elif [ $Target = "armv7-linux" ]; then
    echo "=====>Armv7-linux(X1) Platform <====="
    compile_dir=armv7-linux
    os_env=armv7-linux
    sys_arch=arm
    armv7_android=ON

    fpga_accelerate=ON
    use_neon=ON
elif [ $Target = "armv8-linux" ]; then
    echo "=====>armv8-linux(ZU3) Platform <====="
    compile_dir=armv8-linux
    os_env=armv8-linux
    sys_arch=arm64

    fpga_accelerate=ON # to be verified
    os_env=armv8-linux
    use_neon=ON
    zu3_set=ON
elif [ $Target = "armv7-android" ]; then
    echo "======> Armv7-android(F1) Platform"
    compile_dir=armv7-android
    os_env=armv7-android
    sys_arch=arm
    armv7_android=ON

    use_ncnn=ON
    use_neon=ON
elif [ $Target = "cv22" ]; then
    echo "======> CV22 Platform"
    compile_dir=cv22
    os_env=armv8
    sys_arch=armv8

    use_neon=ON
else
    echo "Error : Unsupport Platform :"${platform}
    exit 0
fi

build_tmp=build/$compile_dir
if [ ! -d "${build_tmp}" ];then
    echo ${build_tmp}
    mkdir -p ${build_tmp}
fi
# run compile command
#echo "=====>"${config[*]}
pushd ${build_tmp}
force_compile=true
if $force_compile; then
    echo `pwd`
    /bin/rm * -rf
    echo "force compile"
fi

if [ $Shared = "shared" ]; then
    shared_libs=ON
else
    shared_libs=OFF
fi

if [ $Target = "armv8-android" ]; then
    #conan install ../../conanfile/m4.txt -s os=Android -s arch=armv8 -s os.api_level=android-21
    cmake --clean_first \
        -DCMAKE_TOOLCHAIN_FILE=`pwd`/../../roadmarking_interface/script/android.toolchain.cmake \
        -DANDROID_NATIVE_API_LEVEL=android-21 \
        -DANDROID_ABI=arm64-v8a \
        ..
elif [ $Target = "linux" ]; then
    conan install ../../conanfile/linux.txt -s os=Linux -s arch=x86_64
    install_dir=${HOME}/data3/conan_devin/rpclib/binaries/linux/
    cmake --clean_first \
        "-DCMAKE_INSTALL_PREFIX=${install_dir}" \
        "-DBUILD_SHARED_LIBS=${shared_libs}" \
        -DRPCLIB_BUILD_TESTS=ON \
        -DRPCLIB_BUILD_EXAMPLES=ON \
        ../..
elif [ $Target = "armv8-linux" ]; then
    #conan install ../../conanfile/x2.txt -s os=Linux -s arch=armv8 -s compiler.version=7.2
    cmake --clean_first \
        -DCMAKE_SYSTEM_NAME=Linux \
        -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
        -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
        -DZU3=1 \
        ..
elif [ $Target = "armv7-linux" ]; then
    #conan install ../../conanfile/x1.txt -s os=Linux -s arch=arm_zynq
    cmake --clean_first \
        -DCMAKE_SYSTEM_NAME=Linux \
        -DCMAKE_CXX_COMPILER=/usr/bin/arm-linux-gnueabihf-g++-4.9 \
        -DCMAKE_C_COMPILER=/usr/bin/arm-linux-gnueabihf-gcc-4.9 \
        -DCMAKE_AR=/usr/bin/arm-linux-gnueabihf-gcc-ar-4.9 \
        ..
elif [ $Target = "cv22" ]; then
    conan install ../../conanfile/cv22.txt -s os=Linux -s arch=armv7hf
    if [ $Project = "apa" ]; then
        cv22_sw_sdk_dir=${HOME}/data3/amba/a1ba-sw-sdk/
    else
        cv22_sw_sdk_dir=${HOME}/data3/amba/hdmi-sw-sdk/
    fi
    cv22_sys_include_dir=${cv22_sw_sdk_dir}/usr/aarch64-buildroot-linux-gnu/sysroot/usr/include/
    cv22_include_dir=${cv22_sw_sdk_dir}/usr/aarch64-buildroot-linux-gnu/sysroot/usr/local/include/
    cv22_lib_dir=${cv22_sw_sdk_dir}/usr/aarch64-buildroot-linux-gnu/sysroot/usr/local/lib/
    install_dir=${HOME}/data3/conan_devin/rpclib/binaries/cv22/
    source ${cv22_sw_sdk_dir}/setupenv.sh
    cmake --clean_first \
        "-DCV22_SYS_INCLUDE_DIR=${cv22_sys_include_dir}" \
        "-DCV22_INCLUDE_DIR=${cv22_include_dir}" \
        "-DCV22_LIB_DIR=${cv22_lib_dir}" \
        "-DBUILD_SHARED_LIBS=${shared_libs}" \
        "-DCMAKE_INSTALL_PREFIX=${install_dir}" \
        -DWITH_CV22_CHIP=ON \
        -DRPCLIB_BUILD_TESTS=ON \
        -DRPCLIB_BUILD_EXAMPLES=ON \
        ../..
fi

if [ 0 -ne $? ]; then
    echo "Error : compile failed ......"
    exit 1
fi
make clean
make -j4
make install
popd
exit 0

