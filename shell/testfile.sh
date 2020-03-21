touch x1
truncate --size 10g 10gtruncate
touch pre1;leofs_prealloc pre1 0 10g
touch pun1;leofs_punchhole pun1 0 10g
mkdir -p dir/1/1/1/1/1/1/1/
cp /var/log/messages  dir/1/1/1/1/1/1/1/file1
cat /var/log/messages >> dir/1/1/1/1/1/1/1/file1
cat /var/log/messages >> dir/1/1/1/1/1/1/1/file1
#leofs_snapcmd -r snp   #快照目录算一个
#leofs_snapcmd -c -R   snp ss dir 
ln -s `pwd`/dir/ tdirln #文件夹软连接
rm -rf /datapool/tdirln ;ln -s `pwd`/dir/ /datapool/tdirln #文件夹软连接 出去
ln -s 10gtruncate 10gtruncateln  #文件软连接
ln -s /etc/cron.d   localdir    #本地文件夹软连接
ln -s  /etc/cron.d/sysstat   localfile #本地文件软连接
ln -s `pwd`/dir/1/1/1/1/1/1/1/file1 dir/1/1/1/1/1/1/1/file1-links
ln `pwd`/dir/1/1/1/1/1/1/1/file1 dir/1/1/1/1/1/1/1/file1-link
rm -rf /datapool/file1-link;ln `pwd`/dir/1/1/1/1/1/1/1/file1 /datapool/file1-link  #硬链接出去
ln  10gtruncate 10gtruncateln1
leofs_clonecmd -f pre1 pre1clone
leofs_clonecmd -f pun1 pun1clone
leofs_clonecmd -f 10gtruncate 10gtruncateclone
mknod  bb b 0 6  #创建块文件 -6
mknod  cc c 0 6   #创建字符文件 -6
mkfifo 1.pipe    #创建管道文件 -6
#ln `pwd`/bb bb-ln
#ln `pwd`/xx bb-ln
#ln `pwd`/1.pipe bb-ln
##测试socket文件		-6
#leofs_cfgcmd create-blkdev `pwd` 4 4096 512 10g test xd 2 2
leofs_quotacmd -d `pwd` 40g 1001
