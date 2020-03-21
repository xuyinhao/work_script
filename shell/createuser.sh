for i in $(seq 1 9000)
do
groupadd -g 91000$i tg.91000${i}_g
useradd -u 91000$i tu.91000${i}_u 
done
