apt-get install xz-utils
if [ -n "$DRONE" ]
then
  usermame=$DRONE_REPO_OWNER
elif [ -n "$CIRCLECI" ]
then
  username=$CIRCLE_USERNAME
fi

KERNEL_REPO=https://github.com/aslenofarid/kernel_asus_sdm660/commits/lineage-17.1
BRANCH=lineage-17.1

git config --global user.name $GITHUB_USERNAME
git config --global user.email $GITHUB_EMAIL
git clone --recursive $KERNEL_REPO -b $BRANCH kernel
cd kernel
git remote add dms https://github.com/dimas-ady/kernel_asus_sdm660
git fetch dms
curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -
git cherry-pick b175639^..1b51943
bash ../build.sh
