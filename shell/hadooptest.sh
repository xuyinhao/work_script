lgfs="/opt/loongoop-1.0.0/bin/hadoop fs"
for i in $(seq 2156 100000)
do
$lgfs  -touchz /r1/file${i}
$lgfs  -chown  ${i}:${i}   /r1/file${i}
$lgfs  -ls -R /r1/ |grep file >> /datapool/file.log
done
