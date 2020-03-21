tk="truncate --size"
#size=4
while [ 1 ]
do
nos=`ls -l file1 |awk '{print $5}'`
let size=$nos/1024+8
$tk ${size}k file1
#$size+=4
sleep 0.1
done
