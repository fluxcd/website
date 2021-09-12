#!/usr/bin/bash

list=($(curl --silent "https://api.github.com/repos/fluxcd/flux2/releases/latest" | jq -r '.assets[] | select(.name | test("^.*(flux_).*$")).browser_download_url'))

echo "| Download URL | Platform |" > static/snippet/docs/latestrelease.md
echo "| ------------ | ------------ |" >> static/snippet/docs/latestrelease.md
validatelinux=""
validateosxintel=""
validateosxarm=""
validatechecksum=""
validatechecksumwin=""
validatewin=""
for i in "${list[@]}"; do
    filename=$(echo $i | grep -o -P '(\w+)(\.\w+)+(?!.*(\w+)(\.\w+)+)')
    if [[ $i != *checksums* ]]; then
      arch=$(echo $i | grep -o -P '(?<=[0-9]_).*(?=.tar.gz)')$(echo $i | grep -o -P '(?<=[0-9]_).*(?=.zip)')
      printf "| $i | $arch |\n" >> static/snippet/docs/latestrelease.md
      if [[ $i == *linux_amd64* ]]; then
        printf "\`\`\`bash\ncurl -LO \"$i\"\n\`\`\`\n" > static/snippet/docs/install/curllinux.md
        printf "\`\`\`bash\ntar -xzof $filename\n\`\`\`\n" > static/snippet/docs/install/extractlinux.md
        validatelinux=$(printf "\`\`\`bash\nsha256sum $filename -c ")
      elif [[ $i == *darwin_amd64* ]]; then
        printf "\`\`\`bash\ncurl -LO \"$i\"\n\`\`\`\n" > static/snippet/docs/install/curlosxintel.md
        printf "\`\`\`bash\ntar -xzof $filename\n\`\`\`\n" > static/snippet/docs/install/extractosxintel.md
        validateosxintel=$(printf "\`\`\`bash\nsha256sum $filename -c ")
      elif [[ $i == *darwin_arm64* ]]; then
        printf "\`\`\`bash\ncurl -LO \"$i\"\n\`\`\`\n" > static/snippet/docs/install/curlosxarm.md
        printf "\`\`\`bash\ntar -xzof $filename\n\`\`\`\n" > static/snippet/docs/install/extractosxarm.md
        validateosxarm=$(printf "\`\`\`bash\nsha256sum $filename -c ")
      elif [[ $i == *windows_amd64* ]]; then
        printf "\`\`\`bash\ncurl -LO \"$i\"\n\`\`\`\n" > static/snippet/docs/install/curlwindowsamd.md
        validatewinfile=$(printf "$filename")
        printf "\`\`\`powershell\nExpand-Archive -Path $filename -DestinationPath .\n\`\`\`\n" > static/snippet/docs/install/extractwinamd.md
      fi
    else
      printf "\`\`\`bash\ncurl -LO \"$i\"\n\`\`\`\n" > static/snippet/docs/install/downloadchecksum.md
      
      validatechecksum=$(printf "$filename --ignore-missing\n\`\`\`\n")
      validatechecksumfilewin=$(printf "$filename")
    fi
done

printf "$validatelinux$validatechecksum" > static/snippet/docs/install/verifychecksumlinux.md
printf "$validateosxintel$validatechecksum" > static/snippet/docs/install/verifychecksumosxintel.md
printf "$validateosxarm$validatechecksum" > static/snippet/docs/install/verifychecksumosxarm.md
printf "\`\`\`powershell\nSelect-String -Path $validatechecksumfilewin -Pattern ((Get-FileHash '$validatewinfile').Hash)\n\`\`\`\n" > static/snippet/docs/install/verifychecksumwin.md
