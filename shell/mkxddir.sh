for i in "2"
do
mkdir txd221;mkdir txd224;mkdir txd2216;mkdir txd2264;mkdir txd22256;mkdir txd221024;
for j in txd221 txd224 txd2216 txd2264 txd22256 txd221024
do
	leofslayout3 -c $j xd 2 2
done
mkdir txd221;leofs_xd_grpsize_cmd -c txd221 1m
mkdir txd224;leofs_xd_grpsize_cmd -c txd224 4m
mkdir txd2216;leofs_xd_grpsize_cmd -c txd2216 16m
mkdir txd2264;leofs_xd_grpsize_cmd -c txd2264 64m
mkdir txd22256;leofs_xd_grpsize_cmd -c txd22256 256m 
mkdir txd221024;leofs_xd_grpsize_cmd -c txd221024 1024m
done

for i in "4"
do
mkdir txd424;mkdir txd4216;mkdir txd4264;mkdir txd42256;mkdir txd421024;
for j in txd424 txd4216 txd4264 txd42256 txd421024
do
        leofslayout3 -c $j xd 4 2
done
mkdir txd424;leofs_xd_grpsize_cmd -c txd424 4m
mkdir txd4216;leofs_xd_grpsize_cmd -c txd4216 16m
mkdir txd4264;leofs_xd_grpsize_cmd -c txd4264 64m
mkdir txd42256;leofs_xd_grpsize_cmd -c txd42256 256m
mkdir txd421024;leofs_xd_grpsize_cmd -c txd421024 1024m
done

for i in "8"
do
mkdir txd824;mkdir txd8216;mkdir txd8264;mkdir txd82256;mkdir txd821024;mkdir txd824096;
for j in txd824 txd8216 txd8264 txd82256 txd821024 txd824096
do
        leofslayout3 -c $j xd 8 2
done

mkdir txd824 ;leofs_xd_grpsize_cmd -c txd824 4m
mkdir txd8216;leofs_xd_grpsize_cmd -c txd8216 16m
mkdir txd8264;leofs_xd_grpsize_cmd -c txd8264 64m
mkdir txd82256;leofs_xd_grpsize_cmd -c txd82256 256m
mkdir txd821024;leofs_xd_grpsize_cmd -c txd821024 1024m
mkdir txd824096;leofs_xd_grpsize_cmd -c txd824096 4096m
done

for i in "16"
do

mkdir txd16216;mkdir txd16264;mkdir txd162256;mkdir txd1621024;mkdir txd1624096;
for j in txd16216 txd16264 txd162256 txd1621024 txd1624096
do
        leofslayout3 -c $j xd 16 2
done

mkdir txd16216;leofs_xd_grpsize_cmd -c txd16216 16m
mkdir txd16264;leofs_xd_grpsize_cmd -c txd16264 64m
mkdir txd162256;leofs_xd_grpsize_cmd -c txd162256 256m
mkdir txd1621024;leofs_xd_grpsize_cmd -c txd1621024 1024m
mkdir txd1624096;leofs_xd_grpsize_cmd -c txd1624096 4096m
done

