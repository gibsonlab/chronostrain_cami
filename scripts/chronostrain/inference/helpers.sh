num_fastq_reads() {
  fq_gz_file=$1
  num_lines=$(pigz -dc "$fq_gz_file" | wc -l | awk '{print $1}')
	num_reads=$((${num_lines} / 4))
	echo "${num_reads}"
}
export num_fastq_reads
