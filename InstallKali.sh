#!/data/data/com.termux/files/usr/bin/bash

echo
echo -e "\e[93mThis script will install Kali Linux in Termux."
echo

folder="kali-fs"
tarball="kali-rootfs.tar.xz"

if [ -d "$folder" ]; then
    echo -e "\e[32m[*] \e[34mRootFS is already downloaded, skipping download..."
else
    echo -e "\e[32m[*] \e[34mDetecting CPU architecture..."
    case $(dpkg --print-architecture) in
        aarch64) archurl="arm64" ;;
        arm) archurl="armhf" ;;
        amd64) archurl="amd64" ;;
        x86_64) archurl="amd64" ;;
        i*86) archurl="i386" ;;
        x86) archurl="i386" ;;
        *) echo; echo -e "\e[91mDetected unsupported CPU architecture!"; echo; exit 1 ;;
    esac

    echo -e "\e[32m[*] \e[34mDownloading RootFS (~70Mb) for ${archurl}..."
    wget "https://raw.githubusercontent.com/EXALAB/AnLinux-Resources/master/Rootfs/Kali/${archurl}/kali-rootfs-${archurl}.tar.xz" -O $tarball -q

    cur=$(pwd)
    mkdir -p "$folder"
    cd "$folder"
    echo -e "\e[32m[*] \e[34mDecompressing RootFS..."
    proot --link2symlink tar -xf ${cur}/${tarball} || (echo -e "\e[91mFailed to decompress RootFS!"; echo; exit 1)
    cd "$cur"
fi

mkdir -p kali-binds
bin="start-kali.sh"

echo -e "\e[32m[*] \e[34mCreating startup script..."
cat > $bin <<- EOM
#!/data/data/com.termux/files/usr/bin/bash

cd \$(dirname \$0)
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $folder"
if [ -n "\$(ls -A kali-binds)" ]; then
    for f in kali-binds/* ;do
      . \$f
    done
fi
command+=" -b /dev"
command+=" -b /proc"
command+=" -b kali-fs/tmp:/dev/shm"
command+=" -b /sdcard"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"
com="\$@"
if [ -z "\$1" ];then
    exec \$command
else
    \$command -c "\$com"
fi
EOM

echo -e "\e[32m[*] \e[34mConfiguring Shebang..."
termux-fix-shebang $bin
echo -e "\e[32m[*] \e[34mSetting execution permissions..."
chmod +x $bin
echo -e "\e[32m[*] \e[34mRemoving RootFS image..."
rm -rf $tarball

echo
echo -e "\e[32mKali Linux was successfully installed!\e[39m"
echo -e "\e[32mYou can now launch it by executing ./${bin} command.\e[39m"
