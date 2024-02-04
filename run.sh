apt-get install xz-utils
if [ -n "$DRONE" ]
then
  usermame=$DRONE_REPO_OWNER
elif [ -n "$CIRCLECI" ]
then
  username=$CIRCLE_USERNAME
fi

KERNEL_REPO=https://github.com/ajaivasudeve/kernel_asus_sdm660.git
BRANCH=asus

git config --global user.name $GITHUB_USERNAME
git config --global user.email $GITHUB_EMAIL
git clone --recursive $KERNEL_REPO -b $BRANCH kernel
cd kernel
bash ../build.sh
