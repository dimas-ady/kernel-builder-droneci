#! /bin/bash

 # Script For Building Android arm64 Kernel
 #
 # Copyright (c) 2018-2020 Panchajanya1999 <rsk52959@gmail.com>
 #
 # Licensed under the Apache License, Version 2.0 (the "License");
 # you may not use this file except in compliance with the License.
 # You may obtain a copy of the License at
 #
 #      http://www.apache.org/licenses/LICENSE-2.0
 #
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 # limitations under the License.
 #

msg() {
    echo -e "\e[1;32m$*\e[0m"
}

err() {
    echo -e "\e[1;41m$*\e[0m"
    exit 1
}

KERNEL_DIR="$(pwd)"
ZIPNAME="Droopy with KALLSYMS"
MODEL="Asus Zenfone Max Pro M1"
DEVICE="X00TD"
DEFCONFIG=X00T_defconfig
COMPILER=clang

# Brutal Kernel Only !!!
BRUTAL_KERNEL=N
COMPILE_ALL=N
OC=N
STABLE=N
  if [ $STABLE == Y ]
  then
    BUILD_TYPE=Stable
  else
    BUILD_TYPE=Test
  fi
USE_EAS=N
NLV=N
  
# Compiler Directory
GCC64_DIR=$KERNEL_DIR/gcc64
GCC32_DIR=$KERNEL_DIR/gcc32
CLANG_DIR=$KERNEL_DIR/clang

PTTG=1
	if [ $PTTG == 1 ]
	then
		CHATID="-1001328821526"
		PRIVATE_CHATID="661131869"
	fi
LOG_DEBUG=0

DISTRO=$(cat /etc/issue)
KBUILD_BUILD_HOST=DroneCI
CI_BRANCH=$(git rev-parse --abbrev-ref HEAD)
token=$TELEGRAM_TOKEN
export KBUILD_BUILD_HOST CI_BRANCH

## Check for CI
if [ -n "$CI" ]
then
	if [ -n "$CIRCLECI" ] 
	then
	if [ $STABLE != Y ]
	then
		export KBUILD_BUILD_VERSION=$CIRCLE_BUILD_NUM
		export KBUILD_BUILD_HOST=CircleCI
	else
	  export KBUILD_BUILD_HOST=XZXZ
	fi
	  PROG_LINK=$CIRCLE_BUILD_URL
		export CI_BRANCH=$CIRCLE_BRANCH
	fi
	if [ -n "$DRONE" ]
	then
	  if [ $STABLE != Y ]
	  then
		export KBUILD_BUILD_VERSION=$DRONE_BUILD_NUMBER
		export KBUILD_BUILD_HOST=DroneCI
		else
		  export KBUILD_BUILD_HOST=dimasady
		fi
		PROG_LINK="https://cloud.drone.io/${DRONE_REPO}/${DRONE_BUILD_NUMBER}/1/2"
		export CI_BRANCH=$DRONE_BRANCH
	else
		echo "Not presetting Build Version"
	fi
fi
export PROG_LINK

#Check Kernel Version
KERVER=$(make kernelversion)
COMMIT_HEAD=$(git log --oneline -1)
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")

 clone() {
	if [ $COMPILER == gcc-4.9 ]
	then
		msg "// Cloning AOSP GCC 4.9 //"
		git clone --depth=1 https://github.com/dimas-ady/toolchain -b gcc-4.9-aarch64 $GCC64_DIR
		git clone --depth=1 https://github.com/dimas-ady/toolchain -b gcc-4.9-arm $GCC32_DIR
		
	elif [ $COMPILER == clang ]
	then
	  msg "// Cloning AOSP Clang //"
	  git clone --depth=1 https://github.com/dimas-ady/toolchain -b clang $CLANG_DIR
	  git clone --depth=1 https://github.com/dimas-ady/toolchain -b gcc-4.9-aarch64 $GCC64_DIR 
	  git clone --depth=1 https://github.com/dimas-ady/toolchain -b gcc-4.9-arm $GCC32_DIR
	
	elif [ $COMPILER == proton-clang ]
	then
	  msg "// Cloning Proton Clang //"
	  git clone --depth=1 https://github.com/kdrag0n/proton-clang $CLANG_DIR
	  
  elif [ $COMPILER == nusantara-clang ]
  then
    msg "// Cloning Nusantara Devs Clang //"
    git clone --single-branch --depth=1 https://gitlab.com/najahi/clang.git $CLANG_DIR
  elif [ $COMPILER == dragon-tc ]
  then
    msg "// Cloning Dragon TC //"
    git clone --depth=1 https://github.com/NusantaraDevs/DragonTC $CLANG_DIR
    git clone https://github.com/theradcolor/aarch64-linux-gnu -b stable-gcc --depth=1 $GCC64_DIR
    git clone https://github.com/theradcolor/arm-linux-gnueabi -b stable-gcc --depth=1 $GCC32_DIR
  elif [ $COMPILER == gcc-10 ]
  then
    msg "// Cloning GCC 10.2.0 //"
    git clone https://github.com/theradcolor/aarch64-linux-gnu -b stable-gcc --depth=1 $GCC64_DIR
    git clone https://github.com/theradcolor/arm-linux-gnueabi -b stable-gcc --depth=1 $GCC32_DIR
  fi

	msg "// Cloning Anykernel3 //" 
	git clone https://github.com/dimas-ady/AnyKernel3.git -b perf
}

exports() {
	export KBUILD_BUILD_USER="DimsAdy"
	export ARCH=arm64 && export SUBARCH=arm64
   
  if [ $COMPILER == gcc-4.9 ]
  then
    KBUILD_COMPILER_STRING=$("$GCC64_DIR"/bin/aarch64-linux-android-gcc --version | head -n 1)
	  PATH=$GCC64_DIR/bin/:$GCC32_DIR/bin/:/usr/bin:$PATH
	elif [ $COMPILER == clang ]
	then
	  KBUILD_COMPILER_STRING=$("$CLANG_DIR"/bin/clang --version | head -n 1)
	  PATH="$CLANG_DIR/bin:$GCC64_DIR/bin:$GCC32_DIR/bin:${PATH}"
	  export LD=ld.lld
		export LD_LIBRARY_PATH="$CLANG_DIR/lib64:$LD_LIBRARY_PATH"
	elif [ $COMPILER == proton-clang ]
	then
  	KBUILD_COMPILER_STRING=$("$CLANG_DIR"/bin/clang --version | head -n 1)
  	PATH="$CLANG_DIR/bin:$PATH"
  elif [ $COMPILER == nusantara-clang ]
  then
    KBUILD_COMPILER_STRING=$("$CLANG_DIR"/bin/clang --version | head -n 1)
    LD_LIBRARY_PATH="$CLANG_DIR/bin/../lib:$PATH"
    PATH="$CLANG_DIR/bin:${PATH}"
  elif [ $COMPILER == dragon-tc ]
  then
    KBUILD_COMPILER_STRING=$("$CLANG_DIR"/bin/clang --version | head -n 1)
    PATH=$CLANG_DIR/bin:$GCC64_DIR/bin:$GCC32_DIR/bin:/usr/bin:${PATH}
	elif [ $COMPILER == gcc-10 ]
	then
	  KBUILD_COMPILER_STRING=$("$GCC64_DIR"/bin/aarch64-linux-gnu-gcc --version | head -n 1)
	  PATH=$GCC64_DIR/bin/:$GCC32_DIR/bin/:/usr/bin:$PATH
	fi

	export PATH KBUILD_COMPILER_STRING
	export BOT_MSG_URL="https://api.telegram.org/bot$token/sendMessage"
	export BOT_BUILD_URL="https://api.telegram.org/bot$token/sendDocument"
	PROCS=$(nproc --all)
	export PROCS
}

tg_post_msg() {
	curl -s -X POST "$BOT_MSG_URL" -d chat_id=$CHATID \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"
}

tg_post_build() {
	MD5CHECK=$(md5sum "$1" | cut -d' ' -f1)

	curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
	-F chat_id="$3"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$2 | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"  
}

tg_post_file() {
	curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
	-F chat_id="$CHATID"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$2"  
}

up_log() {
  log=$(cat error.log)
  tg_post_msg "<b>Log :</b>%0A<code>$log</code>"
}

build_kernel() {
  #SU Add
  git remote add mysu https://github.com/dimas-ady/kernel_asus_sdm660
  git fetch mysu
  git cherry-pick b175639^..1b51943
  
  # String
  if [ $OC == Y ]
  then
    CLOCK="Overclock"
  else
    CLOCK="Stock"
  fi
  if [ $NLV == Y ]
  then
    VB_TYPE=NLV
  else
    VB_TYPE=LV
  fi
  if [ $USE_EAS == Y ]
  then
    KERNEL_TYPE=EAS
  else
    KERNEL_TYPE=HMP
  fi
  
  if [ $COMPILE_ALL == Y ]
  then 
    msg "// Reset Kernel Repo //"
    git reset --hard origin
  fi
	msg "// Cleaning Sources //"
	make clean && make mrproper && rm -rf out

	if [ $PTTG == 1 ]
 	then
 	  #if [ $COMPILE_ALL == Y ]
 	  #
      KKT="$KERNEL_TYPE $CLOCK $VB_TYPE"
		#else
		 # KKT="All"
	#	fi
		tg_post_msg "<b>Docker OS : </b><code>$DISTRO</code>%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=Asia/Jakarta date)</code>%0A<b>Device : </b><code>$MODEL [$DEVICE]</code>%0A<b>Kernel Type : </b><code>$KKT</code>%0A<b>Build Type : </b><code>$BUILD_TYPE</code>%0A<b>Pipeline Host : </b><code>$KBUILD_BUILD_HOST</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0a<b>Branch : </b><code>$CI_BRANCH</code>%0A<b>Top Commit : </b><a href='$DRONE_COMMIT_LINK'><code>$COMMIT_HEAD</code></a>%0A<b>Compiler Progress Link : </b><a href='$PROG_LINK'>Click Here</a>"
	fi
  
  if [ $BRUTAL_KERNEL == Y ]
  then
  
    if [ $NLV == Y ]
    then
      git cherry-pick 75a909ca1376505ff3355d089f096a283d874da0
    fi
    
    if [ $OC == Y ]
    then
      git cherry-pick 65702d6878e04d560eace2e88713ffe438ba929e
    fi
    
    LOCAL_NAME_0=$(sed -n -e '/CONFIG_LOCALVERSION/ s/.*\= *//p' arch/arm64/configs/brutal_defconfig)
    LOCAL_NAME_1=$(echo "$LOCAL_NAME_0" | tr -d '"')
    LOCAL_NAME_2="$LOCAL_NAME_1-$KERNEL_TYPE-$CLOCK-$VB_TYPE"
    sed -i '/CONFIG_LOCALVERSION/d' arch/arm64/configs/brutal_defconfig
    echo "CONFIG_LOCALVERSION="\"${LOCAL_NAME_2}\" >> arch/arm64/configs/brutal_defconfig
    git add .
    git commit -m "defconfig: Set type to local version"
    
    KERNEL_NAME=${LOCAL_NAME_1:1}
    export KERNEL_NAME
    make O=out brutal_defconfig
  else
	  make O=out $DEFCONFIG
	fi

	BUILD_START=$(date +"%s")
	
	if [ $COMPILER == clang ]
	then
	  make -j"$PROCS" O=out \
	                CC=clang \
	                CLANG_TRIPLE=aarch64-linux-gnu- \
	                CROSS_COMPILE=aarch64-linux-android- \
	                CROSS_COMPILE_ARM32=arm-linux-androideabi- \
	                AR=llvm-ar \
	                NM=llvm-nm \
	                OBJCOPY=llvm-objcopy \
	                OBJDUMP=llvm-objdump \
	                STRIP=llvm-strip 2>&1 | tee error.log
	
	elif [ $COMPILER == proton-clang ]
	then
	make -j"$PROCS" O=out \
	                CC=clang \
	                CROSS_COMPILE=aarch64-linux-gnu- \
	                CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
	                AR=llvm-ar \
	                NM=llvm-nm \
	                OBJCOPY=llvm-objcopy \
	                OBJDUMP=llvm-objdump \
	                STRIP=llvm-strip 2>&1 | tee error.log
	
	elif [ $COMPILER == nusantara-clang ]
	then
	  make -j"$PROCS" O=out \
		              CC=clang \
		              CLANG_TRIPLE=aarch64-linux-gnu- \
		              CROSS_COMPILE=aarch64-linux-gnu- \
		              CROSS_COMPILE_ARM32=arm-linux-gnueabi- 2>&1 | tee error.log
		              
	elif [ $COMPILER ==  gcc-10 ]
	then
  	make -j"$PROCS" O=out \
  	                CROSS_COMPILE=aarch64-linux-gnu- \ 
  	                CROSS_COMPILE_ARM32=arm-linux-gnueabi- 2>&1 | tee error.log
	  
	elif [ $COMPILER == dragon-tc ]
	then
	  make -j"$PROCS" O=out \
	                CC=clang \
	                CROSS_COMPILE=aarch64-linux-gnu- \
	                CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
	                AR=llvm-ar \
	                NM=llvm-nm \
	                OBJCOPY=llvm-objcopy \
	                OBJDUMP=llvm-objdump \
	                STRIP=llvm-strip 2>&1 | tee error.log
	                
	elif [ $COMPILER == gcc-4.9 ]
  then
  	make -j"$PROCS" O=out \
  	              CROSS_COMPILE=aarch64-linux-android- \
  	              CROSS_COMPILE_ARM32=arm-linux-androideabi- 2>&1 | tee error.log
  fi

	BUILD_END=$(date +"%s")
	DIFF=$((BUILD_END - BUILD_START))

		if [ -f "$KERNEL_DIR"/out/arch/arm64/boot/Image.gz-dtb ] 
	 then
	   msg "// Kernel successfully compiled //"
	   gen_zip
		else
	  	if [ $PTTG == 1 ]
 		  then
		  	tg_post_msg "<b>❌ Build failed to compile after $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds</b>"
				up_log
	  	fi
		fi
	
}

gen_zip() {
	msg "// Zipping into a flashable zip //"
	mv "$KERNEL_DIR"/out/arch/arm64/boot/Image.gz-dtb AnyKernel3/Image.gz-dtb
	cd AnyKernel3 || exit
	
	if [ $BRUTAL_KERNEL == Y ]
	then
	  if [ $STABLE != Y ]
	  then
      ZIP_FINAL="$KERNEL_NAME-$KERNEL_TYPE-$CLOCK-$VB_TYPE-$DEVICE-$DATE"
    else
      ZIP_FINAL="$KERNEL_NAME-$KERNEL_TYPE-$CLOCK-$VB_TYPE-$DEVICE"
    fi
	else
	  ZIP_FINAL="$ZIPNAME-$KERNEL_TYPE-$DEVICE-$DATE"
	fi
	zip -r9 "$ZIP_FINAL" * -x .git README.md

	if [ $PTTG == 1 ]
 	then
 	  msg "Sending to Telegram..."
 	  if [ $STABLE != Y ]
 	  then
		  tg_post_build "$ZIP_FINAL.zip" "✅ Build took : $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)" $CHATID
		else
      tg_post_build "$ZIP_FINAL.zip" "✅ Build took : $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)" $PRIVATE_CHATID		
    fi
		
		if [ $LOG_DEBUG == 1 ]
		then
		  up_log
		fi
		msg "Kernel succesfully sended to Telegram Channel"
	else
	  curl -T $ZIP_FINAL.zip https://oshi.at
	fi
	rm -rf $ZIP_FINAL.zip
	rm -rf Image.gz-dtb
	cd ..
}

clone
exports

if [ $COMPILE_ALL != Y ]
then
  build_kernel
else
  OC=N
  NLV=N
  cd ~/kernel
  build_kernel
  OC=Y
  cd ~/kernel
  build_kernel
  NLV=Y
  cd ~/kernel
  build_kernel
  OC=N
  cd ~/kernel
  build_kernel
fi
