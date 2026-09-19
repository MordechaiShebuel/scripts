# 1. Install build dependencies
#
# Debian
sudo apt update
sudo apt install -y build-essential libncurses-dev bison flex libssl-dev libelf-dev dwarves git

# Void
sudo xbps-install -S base-devel ncurses-devel bison flex openssl-devel elfutils-devel git

# 2. Clone the latest Cachy kernel (based on latest stable)
cd ~/src  # or wherever you keep sources
git clone https://github.com/sirlucjan/kernel-patches.git cachy-patches
cd cachy-patches
git log --oneline | head -20  # See latest patch set

# 3. Get the latest mainline kernel
cd ..
git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
cd linux
git fetch --tags
# Get the latest stable tag (e.g., v6.11.x)
LATEST_TAG=$(git tag -l 'v6.*' --sort=-version:refname | head -1)
git checkout $LATEST_TAG
echo "Building: $LATEST_TAG"

# 4. Apply Cachy patches
# Check cachy-patches repo for matching version
cd ../cachy-patches
ls -la | grep "6-1"  # or whatever version you're on
# Apply the appropriate patch series
cd ../linux
patch -p1 < ../cachy-patches/6.1-cachy/0001-*.patch  # Example
# (Cachy provides a full series; apply in order or use their build script)
