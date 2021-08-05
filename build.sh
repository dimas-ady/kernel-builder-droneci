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
ZIPNAME="Brutal Kernel"
MODEL="Asus Zenfone Max Pro M1"
DEVICE="X00TD"
DEFCONFIG=brutal_defconfig

COMPILER=nusantara-clang

# Compiler Directory
GCC64_DIR=$KERNEL_DIR/gcc64
GCC32_DIR=$KERNEL_DIR/gcc32
CLANG_DIR=$KERNEL_DIR/clang

INCREMENTAL=0

PTTG=1
	if [ $PTTG = 1 ]
	then
		CHATID="-1001328821526"
	fi

DEF_REG=0
SILENCE=0
LOG_DEBUG=1

DISTRO=$(cat /etc/issue)
KBUILD_BUILD_HOST=DroneCI
CI_BRANCH=$(git rev-parse --abbrev-ref HEAD)
token=$TELEGRAM_TOKEN
ProgLink="https://cloud.drone.io/${DRONE_REPO}/${DRONE_BUILD_NUMBER}/1/2"
export KBUILD_BUILD_HOST CI_BRANCH

## Check for CI
if [ -n "$CI" ]
then
	if [ -n "$CIRCLECI" ] 
	then
		export KBUILD_BUILD_VERSION=$CIRCLE_BUILD_NUM
		export KBUILD_BUILD_HOST="Dimas-Ady"
		export CI_BRANCH=$CIRCLE_BRANCH
	fi
	if [ -n "$DRONE" ]
	then
		export KBUILD_BUILD_VERSION=$DRONE_BUILD_NUMBER
		export KBUILD_BUILD_HOST=DroneCI
		export CI_BRANCH=$DRONE_BRANCH
	else
		echo "Not presetting Build Version"
	fi
fi

#Check Kernel Version
KERVER=$(make kernelversion)
COMMIT_HEAD=$(git log --oneline -1)
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")

 clone() {
	# Cloning The Compiler and Toolchain
	if [ $COMPILER == gcc-4.9 ]
	then
		msg "// Cloning GCC 4.9 //"
		
	elif [ $COMPILER == clang ]
	  msg "// Cloning AOSP Clang //"
	  git clone https://github.com/dimas-ady/toolchain -b clang $CLANG_DIR && git clone https://github.com/dimas-ady/toolchain -b gcc-4.9-aarch64 $GCC64_DIR && git clone https://github.com/dimas-ady/toolchain -b gcc-4.9-arm $GCC32_DIR
	
	elif [ $COMPILER == proton-clang ]
	then
	  msg "// Cloning Proton Clang //"
	  git clone --depth=1 https://github.com/kdrag0n/proton-clang $KERNEL_DIR/clang
	  
  elif [ $COMPILER == nusantara-clang ]
  then
    msg "// Cloning Nusantara Devs Clang //"
    git clone --single-branch --depth=1 https://gitlab.com/najahi/clang.git $CLANG_DIR
  fi

	msg "// Cloning Anykernel3 //" 
	git clone https://github.com/dimas-ady/AnyKernel3.git
}

##------------------------------------------------------##

exports() {
	export KBUILD_BUILD_USER="DimasAdy-XZXZ"
	export ARCH=arm64
	export SUBARCH=arm64
   
  if [ $COMPILER == gcc-4.9 ]
  then
    KBUILD_COMPILER_STRING=$("$GCC64_DIR"/bin/aarch64-linux-android-gcc --version | head -n 1)
	  PATH=$GCC64_DIR/bin/:$GCC32_DIR/bin/:/usr/bin:$PATH
	elif [ $COMPILER == clang ]
	then
	  KBUILD_COMPILER_STRING=$("$CLANG_DIR"/bin/clang --version | head -n 1)
	  PATH="$CLANG_DIR/bin:$GCC64_DIR/bin:$GCC32_DIR/bin:${PATH}"
	fi
	elif [ $COMPILER == proton-clang ]
	then
  	KBUILD_COMPILER_STRING=$("$CLANG_DIR"/bin/clang --version | head -n 1)
  	PATH="$CLANG_DIR/bin:$PATH"
  elif [ $COMPILER == nusantara-clang ]
  then
    KBUILD_COMPILER_STRING=$("$CLANG_DIR"/bin/clang --version | head -n 1)
    LD_LIBRARY_PATH="$CLANG_DIR/bin/../lib:$PATH"
    PATH="$CLANG_DIR/bin:${PATH}"
	fi

	export PATH KBUILD_COMPILER_STRING
	export BOT_MSG_URL="https://api.telegram.org/bot$token/sendMessage"
	export BOT_BUILD_URL="https://api.telegram.org/bot$token/sendDocument"
	PROCS=$(nproc --all)
	export PROCS
}

##---------------------------------------------------------##

tg_post_msg() {
	curl -s -X POST "$BOT_MSG_URL" -d chat_id=$CHATID \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"

}

##----------------------------------------------------------------##

tg_post_build() {
	#Post MD5Checksum alongwith for easeness
	msg "Checking MD5sum..."
	MD5CHECK=$(md5sum "$1" | cut -d' ' -f1)

	#Show the Checksum alongwith caption
	curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
	-F chat_id="$CHATID"  \
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
  make > build.log 2>&1
  log=$(cat build.log)
  tg_post_msg "<b>Log :</b>%0A<code>$log</code>"
}

##----------------------------------------------------------##

build_kernel() {
	if [ $INCREMENTAL = 0 ]
	then
		msg "// Cleaning Sources //"
		make clean && make mrproper && rm -rf out
	fi

	if [ "$PTTG" = 1 ]
 	then
		tg_post_msg "<b>Docker OS: </b><code>$DISTRO</code>%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=Asia/Jakarta date)</code>%0A<b>Device : </b><code>$MODEL [$DEVICE]</code>%0A<b>Pipeline Host : </b><code>$KBUILD_BUILD_HOST</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0a<b>Branch : </b><code>$CI_BRANCH</code>%0A<b>Top Commit : </b><a href='$DRONE_COMMIT_LINK'><code>$COMMIT_HEAD</code></a>%0A<b>Compiler Progress Link : </b><code>$ProgLink</code>"
	fi

	make O=out $DEFCONFIG
	if [ $DEF_REG = 1 ]
	then
		cp .config arch/arm64/configs/$DEFCONFIG
		git add arch/arm64/configs/$DEFCONFIG
		git commit -m "$DEFCONFIG: Regenerate

						This is an auto-generated commit"
	fi

	BUILD_START=$(date +"%s")
	
	if [ $SILENCE = "1" ]
	then
		MAKE+=( -s )
	fi
	
	if [ $COMPILER == proton-clang ]
	then
		make -j"$PROCS" O=out \
		              CC=clang \
		              CROSS_COMPILE=aarch64-linux-android- \
		              CROSS_COMPILE_ARM32=arm-linux-androideabi-
	elif [ $COMPILER == clang ]
	  make -j"$PROCS" O=out \
	                CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
	                CROSS_COMPILE=aarch64-linux-android- \
	                CROSS_COMPILE_ARM32=arm-linux-androideabi-
	then
	elif [ $COMPILER == nusantara-clang ]
	then
	  make -j"$PROCS" O=out \
		              CC=clang \
		              CLANG_TRIPLE=aarch64-linux-gnu- \
		              CROSS_COMPILE=aarch64-linux-gnu- \
		              CROSS_COMPILE_ARM32=arm-linux-gnueabi-
	fi
  
  if [ $COMPILER == gcc-4.9 ]
  then
	  msg "// Started Compilation //"
  	export CROSS_COMPILE_ARM32=$GCC32_DIR/bin/arm-linux-androideabi-
  	make -j"$PROCS" O=out CROSS_COMPILE=aarch64-linux-android-
  fi

		BUILD_END=$(date +"%s")
		DIFF=$((BUILD_END - BUILD_START))

		if [ -f "$KERNEL_DIR"/out/arch/arm64/boot/Image.gz-dtb ] 
	    then
	    	msg "// Kernel successfully compiled //"
	    	if [ $BUILD_DTBO = 1 ]
			then
				msg "// Building DTBO //"
				tg_post_msg "<code>Building DTBO..</code>"
				python2 "$KERNEL_DIR/scripts/ufdt/libufdt/utils/src/mkdtboimg.py" \
					create "$KERNEL_DIR/out/arch/arm64/boot/dtbo.img" --page_size=4096 "$KERNEL_DIR/out/arch/arm64/boot/dts/qcom/sm6150-idp-overlay.dtbo"
			fi
				gen_zip
		else
			if [ "$PTTG" = 1 ]
 			then
				tg_post_msg "<b>❌ Build failed to compile after $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds</b>" "$CHATID"
				#make > build.log 2>&1
				#tg_post_file "build.log" "build.log"
				up_log
			fi
		fi
	
}

gen_zip() {
	msg "// Zipping into a flashable zip //"
	mv "$KERNEL_DIR"/out/arch/arm64/boot/Image.gz-dtb AnyKernel3/Image.gz-dtb
	if [ $BUILD_DTBO = 1 ]
	then
		mv "$KERNEL_DIR"/out/arch/arm64/boot/dtbo.img AnyKernel3/dtbo.img
	fi
	cd AnyKernel3 || exit
	zip -r9 "$ZIPNAME-$DEVICE-$DATE" * -x .git README.md

	## Prepare a final zip variable
	ZIP_FINAL="$ZIPNAME-$DEVICE-$DATE.zip"
	if [ "$PTTG" = 1 ]
 	then
 	  msg "Sending to Telegram..."
		tg_post_build "$ZIP_FINAL" "✅ Build took : $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)"
		if [ $LOG_DEBUG == 1 ]
		then
		  up_log
		fi
		msg "Kernel succesfully sended to Telegram Channel"
	fi
	cd ..
}

clone
exports
build_kernel