#!/bin/sh

set -x

list=$(curl --silent "https://api.github.com/repos/fluxcd/flux2/releases/latest" | jq -r '.assets[] | select(.name | test("^.*(flux_).*$")).browser_download_url')
snippet_loc="static/snippet/docs/install"
rel_loc="static/snippet/docs/latestrelease.md"
echo "| Download URL | Platform |" > "$rel_loc"
echo "| ------------ | ------------ |" >> "$rel_loc"

for item in $list; do

  filename=$(basename "$item")
  arch=$(echo "$filename" | grep -oP '(?<=[0-9]_).*(?=.tar.gz|.zip)' )

  ver=$(echo "flux_0.17.0_linux_amd64.tar.gz" | cut -f1,2 -d'_')

  if [ -n "$arch" ] ; then
    echo "| $item | $arch |" >> "$rel_loc"
    
  fi

  case "$arch" in
    # On Mac and Linux tar achive and sha256 sum
    "darwin_amd64" | "linux_amd64" | "darwin_arm64")
       printf "tar -xzof %s\n" "$filename" > "${snippet_loc}/tar${arch}.sh"
       printf "sha256sum %s -c %s_checksums.txt\n" "$filename" "$ver" > "${snippet_loc}/verify${arch}.sh"
       printf "curl -LO %s\n" "$item" > "${snippet_loc}/curl${arch}.sh"
    ;;
    # On windows powershell use expand-archive and
    "windows_amd64")
        printf "Expand-Archive -Path %s -DestinationPath .\n" "$filename" > "${snippet_loc}/zip${arch}.ps1"
        printf "Select-String -Path '%s_checksums.txt' -Pattern ((Get-FileHash %s).Hash)\n" "$ver" "$filename" > "${snippet_loc}/verify${arch}.ps1"
        printf "curl -LO %s\n" "$item" > "${snippet_loc}/curl${arch}.ps1"
    ;;
    "")
    printf "curl -LO %s\n" "$item" > "${snippet_loc}/curlchecksum.sh"
    ;;
    *)
    
    ;; 
  esac

done
