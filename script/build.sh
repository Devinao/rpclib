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
  echo "  aeb (default)"
  echo "  x1d"
  echo "  cv22"
  echo "  x2"
  echo "  m4"
  echo "  avm"
  echo "  aeb-gpu"
  echo "  apa"
  echo "  c1"
  echo "  x1d3"
  echo "  m4c"
  echo "  sansheng"
  echo "  arm-sdk"
  echo "  arm-gpu"
  echo "  ipc"
  echo "  liuqi"
  echo "  x1j"
  echo
  echo "Para:"
  echo "  env (para from env)"
  echo "  gflags (para from gflasg)"
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
    elif [ "_$Para" = "_" ]; then
        Para="$1"
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

if [ "_$Para" = "_" ]; then
    Para=env
fi

. "$(dirname "$0")/build_config.sh" ${Target} ${BuildType} ${Project} ${Para}

build_tmp=build/$compile_dir
if [ ! -d "${build_tmp}" ];then
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

if [ $platform = "armv8-android" ]; then
    #conan install ../../conanfile/m4.txt -s os=Android -s arch=armv8 -s os.api_level=android-21
    cmake --clean_first \
        -DCMAKE_TOOLCHAIN_FILE=`pwd`/../../roadmarking_interface/script/android.toolchain.cmake \
        -DANDROID_NATIVE_API_LEVEL=android-21 \
        -DANDROID_ABI=arm64-v8a \
        ${config[*]} \
        ..
elif [ $platform = "linux" ]; then
    #conan install ../../conanfile/linux.txt -s os=Linux -s arch=x86_64
    cmake --clean_first \
        -DRPCLIB_BUILD_TESTS=ON \
        -DRPCLIB_BUILD_EXAMPLES=ON \
        ../..
elif [ $platform = "armv8-linux" ]; then
    #conan install ../../conanfile/x2.txt -s os=Linux -s arch=armv8 -s compiler.version=7.2
    cmake --clean_first \
        -DCMAKE_SYSTEM_NAME=Linux \
        -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
        -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
        -DZU3=1 \
        ${config[*]} \
        ..
elif [ $platform = "armv7-linux" ]; then
    #conan install ../../conanfile/x1.txt -s os=Linux -s arch=arm_zynq
    cmake --clean_first \
        -DCMAKE_SYSTEM_NAME=Linux \
        -DCMAKE_CXX_COMPILER=/usr/bin/arm-linux-gnueabihf-g++-4.9 \
        -DCMAKE_C_COMPILER=/usr/bin/arm-linux-gnueabihf-gcc-4.9 \
        -DCMAKE_AR=/usr/bin/arm-linux-gnueabihf-gcc-ar-4.9 \
        ${config[*]} \
        ..
elif [ $platform = "cv22" ]; then
    source ${cv22_sw_sdk_dir}/setupenv.sh
    cmake --clean_first \
        ${config[*]} \
        ..
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

