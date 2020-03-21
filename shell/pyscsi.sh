for i in `cat device`
do
python onewr.py $i 1 20G 3333  1 0 0 0 >> w1.log && python onewr.py $i 2 20G 3333 1 0 0 0 >> r1.log &
#Usage:filename optype(1:write, 2:read) filesize(K,M,G,T) blocksize(K,M) thread_num bskip eskip [prefix]
done
