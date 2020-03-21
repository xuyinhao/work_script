bsize=(512 4096)
spannum=(1 4 16)
spansize=(32 64 128 256)
for bs in ${bsize[*]}
do
	for spn in ${spannum[*]}
	do
		for sps in ${spansize[*]}
		do
		echo $bs : $spn : $sps
		done
	done
done
