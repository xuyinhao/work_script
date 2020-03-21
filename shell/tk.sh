tk="truncate --size"
size=4
while [ 1 ]
do
$tk ${size}k file1 
let size=$size+4
sleep 0.1
done
