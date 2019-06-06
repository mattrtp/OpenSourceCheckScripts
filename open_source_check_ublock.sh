# Define variables
mozilla_store_url=https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/
github_ublock=https://github.com/gorhill/uBlock.git
github_uassets=https://github.com/uBlockOrigin/uAssets.git

# Get latest version of uBlock
wget -O store_page.html $mozilla_store_url
addon_download_url_unescaped=$(cat store_page.html  | grep -o 'https:[^"]*xpi')
addon_download_url=$(echo -e $addon_download_url_unescaped)
rm store_page.html 

wget -O addon.xpi $addon_download_url

# Unzip the contents into the directory xpi/
mv addon.xpi ublock.zip
mkdir xpi
unzip ublock.zip -d xpi

sudo apt install jq -y

# Clone equivalent version from GitHub
version=$(jq -r '.version' xpi/manifest.json)
git clone --branch $version $github_ublock
git clone $github_uassets

# Build the Firefox distribution
cd uBlock/
./tools/make-firefox.sh

# Take a diff of the build and the download
# (Excluding assets as these update and are not tied to a specific version)
cd ..
diff_result=$(diff -r --exclude=assets uBlock/dist/build/uBlock0.firefox/ xpi/)

# Check if the only result of the diff is the Mozilla signing files
if [ "$diff_result" == "Only in xpi/: META-INF" ]
then
	echo Pass
else
	echo Fail
fi

# Remove all files added and dependencies
rm -r xpi
rm ublock.zip
sudo apt remove jq -y
rm -r uBlock
rm -r uAssets