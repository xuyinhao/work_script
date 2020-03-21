if [[ "$1" = "" ]];then echo "dir1 ";exit ; fi
for i in 1m 2m 4m 8m 16m 32m 64m 128m 256m 512m 1024m 2048m 4096m 8192m
do
leofs_xd_grpsize_cmd -c -R $1 $i
done
