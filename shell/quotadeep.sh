
mkdir -p /datapool/2/2/2/2/2/2/2/2/2/2/2/2/2/2
mkdir -p /datapool/2/1/1/1/1/1/1/1/1/1/1/1/1/1
 for i in `find /datapool/2 -type d`;do leofs_quotacmd -d $i 0 20;if [ $? -ne 0 ];then exit;fi;done
sleep 1
leofs_quotaclt -q /datapool/2/2/2/2/2/2/2/2/2/2/2/2/2/2
leofs_quotaclt -q /datapool/2/1/1/1/1/1/1/1/1/1/1/1/1/1

truncate --size 10m /datapool/2/2/2/2/2/2/2/2/2/2/2/2/2/2/file1111
echo 11111 >> /datapool/2/2/2/2/2/2/2/2/2/2/2/2/2/2/file1111
truncate --size 10m  /datapool/2/1/1/1/1/1/1/1/1/1/1/1/1/1/file222
echo 111 >> /datapool/2/1/1/1/1/1/1/1/1/1/1/1/1/1/file222
#rm -rf /datapool/2/*

leofs_quotaclt -q /datapool/2
rm -rf /datapool/2/*
sleep 2
leofs_quotaclt -q /datapool/2
