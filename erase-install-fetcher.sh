latest_release_url=$(curl -s https://api.github.com/repos/grahampugh/erase-install/releases/latest | grep "browser_download_url.*pkg" | cut -d '"' -f 4)
curl -LO $latest_release_url
