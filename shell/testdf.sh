mkdir -p p1/p2/p3/p4/p5/p6/p7/p8/p9
leofs_quotacmd -d p1 10g 200
if [ $? -ne 0 ];then exit;fi
leofs_quotacmd -d p1/p2 20g 150
if [ $? -ne 0 ];then exit;fi
leofs_quotacmd -d p1/p2/p3/ 15g 100
leofs_quotacmd -d p1/p2/p3/p4/p5  0g 100
leofs_quotacmd -d p1/p2/p3/p4/p5/p6  10g 0
leofs_quotacmd -d p1/p2/p3/p4/p5/p6/p7  5g 180
leofs_quotacmd -d p1/p2/p3/p4/p5/p6/p7/p8  30g 100
sleep 2
truncate --size 1g p1/1g
truncate --size 1g p1/p2/1g
truncate --size 1g p1//p2/p3/1g
truncate --size 1g p1/p2/p3/p4/1g
truncate --size 1g p1/p2/p3/p4/p5/1g
truncate --size 1g p1//p2/p3/p4/p5/p6/1g
truncate --size 1g p1//p2/p3/p4/p5/p6/p7/1g
truncate --size 1g p1//p2/p3/p4/p5/p6/p7/p8/1g
truncate --size 1g p1//p2/p3/p4/p5/p6/p7/p8/p9/1g

echo p1
df -h p1|grep 10G
df -i p1|grep 200
echo p1/p2
df -h p1/p2|grep 10G
df -i p1/p2|grep 200
echo p1/p2/p3
df -h p1/p2/p3/ |grep 10G
df -i p1/p2/p3/ |grep 200
echo p1/p2/p3/p4
df -h p1/p2/p3/p4|grep 10G
df -i p1/p2/p3/p4|grep 200
echo p1/p2/p3/p4/p5
df -h p1/p2/p3/p4/p5|grep 10G 
df -i p1/p2/p3/p4/p5|grep 200
echo p1/p2/p3/p4/p5/p6
df -h p1/p2/p3/p4/p5/p6|grep 10G
df -i p1/p2/p3/p4/p5/p6|grep 200
echo p1/p2/p3/p4/p5/p6/p7
df -h p1/p2/p3/p4/p5/p6/p7 |grep 5.0G
df -i p1/p2/p3/p4/p5/p6/p7 |grep 180
echo p1/p2/p3/p4/p5/p6/p7/p8
df -h p1/p2/p3/p4/p5/p6/p7/p8|grep 5.0G
df -i p1/p2/p3/p4/p5/p6/p7/p8|grep 180

