if [ $# != 1 ];then echo "需要输入一个参数作为目录";exit;fi
dir=$1/w
minidir=$dir/12k
minilog=$dir/mini.log
mkdir -p $minidir
java -jar /datapool/create.jar $minidir dir 5 file 80 12000 3333 5 3 0 0 >> $minilog && \
java -jar /datapool/check.jar $minidir dir 5 file 80 12000 3333 5 3 0 0 >> $minilog &

log=$dir/file.log
python /datapool/filewr.py $dir/w 1 $((1024*1024*1024*4))  104857 2 0 0 >> $log && \
python /datapool/filewr.py $dir/w 2 $((1024*1024*1024*4))  104857 2 0 0 >> $log &
#python /datapool/filewr.py $dir/w 1 $((1024*1024*1024*2045))  104857 1 0 0 >> $log && \
#python /datapool/filewr.py $dir/w 2 $((1024*1024*1024*2045))  104857 1 0 0 >> $log &


#sh /datapool/iozone_w.sh $dir &
#sh /datapool/echo.sh $dir &
#sh /datapool/java_null_w.sh $dir &
