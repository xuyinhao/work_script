fstype=ext4
retdisk=`lsblk |grep disk|grep -v " 8:"|grep -v "leo"|awk '{print $1}'`
#retdisk="sdah sdai"
time4sleep=1
function umountall() {
for i in $(seq 1 50)
do
umount /mnt_scsi > /dev/null 2>&1
done
}

function checkok() {
if [ "$1" != "0" ] && [ "$1" != "32" ];then
echo has some errors : $2 $3
exit 1
fi 
}
#devpath mountpath
function mount_pre() {
mount $1 $2 > /dev/null 2>&1
checkok $? "mount $1"
sleep $time4sleep
ret=`df |grep $1 |grep $2`
if [ "$ret" == "" ];then echo "mount has error";exit;fi
cp /etc/udev/hwdb.bin $2/hwdb.bin
checkok $? "$1"
mkdir -p $2/testdir1/1/1/1/1/1/
checkok $? "$1"
echo "111111" > $2/testdir1/1/1/1/1/1/file1
checkok $? "$1"
echo "222222" > $2/testdir1/1/1/1/1/1/file1
checkok $? "$1"
ln -s $2/testdir1/1/1/1/1/1/file1 $2/lnsfile1
checkok $? "$1"
ln $2/testdir1/1/1/1/1/1/file1 $2/lnfile1
checkok $? "$1"
mknod $2/bb b 0 6 
checkok $? "$1"
mknod $2/cc c 0 6
checkok $? "$1"
mkfifo $2/1.pipe
checkok $? "$1"
touch $2/touchfile;rm -rf $2/touchfile
checkok $? "$1"
cat /var/log/messages >> $2/10Tfile;truncate --size 10T $2/10Tfile;
checkok $? "$1"
sleep $time4sleep
}
#devpath  mountpath
function mount_check(){
mount $1 $2 > /dev/null 2>&1
sleep $time4sleep
ret=`df |grep $1 |grep $2`
if [ "$ret" == "" ];then echo "mount has error";exit;fi
md5=`md5sum $2/hwdb.bin|awk '{print $1}'`
md5local=`md5sum /etc/udev/hwdb.bin|awk '{print $1}'`
if [ "$md5" != "$md5local" ];then echo "hwdb.bin check error :$1";exit;fi
if [ ! -d $2/testdir1/1/1/1/1/1/ ];then echo "test check dir error: $1";exit;fi
if [ "`cat $2/testdir1/1/1/1/1/1/file1`" != "222222" ];then echo "check 222222 error : $1";exit;fi
if [ "`md5sum $2/lnfile1|awk '{print $1}'`" != "`md5sum $2/lnsfile1|awk '{print $1}'`" ];then echo "check ln lns error : $1";exit;fi
if [ "`file $2/bb|grep "block special"`" == "" ];then echo "check block error: $1";exit;fi
if [ "`file $2/cc|grep "character special"`" == "" ];then echo "check character  error: $1";exit;fi
if [ "`stat $2/10Tfile|grep "10995116277760"`" == "" ];then echo "check 10Tfile  error : $1";exit;fi 
sleep $time4sleep
}

function mk1() {
num=0
for i in $retdisk
do
let num+=1
echo  fdisk  /dev/${i}
fdisk /dev/${i} >> /tmp/log.fdisk  <<EOF
n
p
1

+100G

n
p
2


ww

EOF
sleep $time4sleep
#mkfs.${fstype} /dev/${i}
done
echo all disk num : $num
for i in $retdisk
do
echo mkfs  ${i}
mkfs.${fstype} /dev/${i}1  >> /tmp/log.mk1 2>&1 &
mkfs.${fstype} /dev/${i}2  >> /tmp/log.mk2 2>&1 &
done
wait
sleep $time4sleep
}

mkdir -p /mnt_scsi
function mount1() {
for i in $retdisk
do
echo mount and write data  ${i}
mount_pre /dev/${i}1 /mnt_scsi
sleep $time4sleep
umount  /mnt_scsi
mount_pre /dev/${i}2 /mnt_scsi
sleep $time4sleep
umount  /mnt_scsi
done
wait
echo mount and write end $i
umountall
sleep $time4sleep
for i in $retdisk
do
echo mount and check $i
mount_check /dev/${i}1 /mnt_scsi
sleep $time4sleep
umount  /mnt_scsi
mount_check /dev/${i}2 /mnt_scsi
sleep $time4sleep
umount  /mnt_scsi
done
wait
echo mount and check end $i
}
umountall
mk1
mount1
umountall
