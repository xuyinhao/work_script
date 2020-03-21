mysql -p111111 -e  'source /aiomanager/conf/core.mysql;'

ssh 13.10.12.32 "mysql -e  'source /aiomanager/conf/core.mysql;' "
rm -rf /LeoCluster/conf/*conf* ;cp /LeoCluster/conf/leofs_mond.bak  /LeoCluster/conf/leofs_mond.conf

ssh 13.10.12.32 "rm -rf /LeoCluster/conf/*conf* ;cp /LeoCluster/conf/leofs_mond.bak  /LeoCluster/conf/leofs_mond.conf"

umount /leofs/meta/meta* ;umount /leofs/data/sd*
ssh 13.10.12.32 "umount /leofs/meta/meta* ;umount /leofs/data/sd*"
ssh 13.10.12.30 "umount /leofs/meta/meta* ;umount /leofs/data/sd*"
ssh 13.10.12.31 "umount /leofs/meta/meta* ;umount /leofs/data/sd*"
ssh 13.10.12.29 "umount /leofs/meta/meta* ;umount /leofs/data/sd*"

/aiomanager/shutdown.sh
ssh 13.10.12.32 "/aiomanager/shutdown.sh"
#/aiomanager/startup.sh  && ssh 13.10.12.32 "/aiomanager/startup.sh"
