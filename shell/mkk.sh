while [ 1 ]
do
for i in sdah  sdai sdaj sdak sdal sdam sdan sdao 
do
DEV=/dev/$i
parted -s  $DEV mklabel gpt
parted -s $DEV mkpart primary ext4 4096s 100%
done

for i in sdah  sdai sdaj sdak sdal sdam sdan sdao
do
mkfs.ext4 /dev/${i}1
done

for i in sdah  sdai sdaj sdak sdal sdam sdan sdao
do
mkdir -p /mnt/${i}1
mount /dev/${i}1 /mnt/${i}1
touch /mnt/${i}1/file
if [ "$?" != "0" ];then echo error;exit;fi
done
umount /mnt/sd*
umount /mnt/sd*
umount /mnt/sd*
sleep 5
done
