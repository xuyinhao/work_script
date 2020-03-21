for i in j k l m n o p q
do
mkdir -p /mnt/$i
mount /dev/sd${i}1 /mnt/$i
done
