apt-get install xz-utils
if [ -n "$DRONE" ]
then
  usermame=$DRONE_REPO_OWNER
elif [ -n "$CIRCLECI" ]
then
  username=$CIRCLE_USERNAME
fi

KERNEL_REPO=https://$GITHUB_USERNAME:$GITHUB_TOKEN@github.com/dimas-ady/kernel_asus_sdm660.git
BRANCH=lineage-17.1

git config --global user.name $GITHUB_USERNAME
git config --global user.email $GITHUB_EMAIL
git clone $KERNEL_REPO -b $BRANCH kernel
cd kernel
bash ../build.sh
