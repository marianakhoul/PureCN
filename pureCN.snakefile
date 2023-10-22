configfile: "config/samples.yaml"
configfile: "config/config.yaml" 

rule all:
	input:
		"results/PreprocessIntervals/preprocessed_intervals.interval_list",
		expand("results/PreprocessIntervals/preprocessed_intervals.interval_list",tumor=config["normals"]),
		expand("results/CollectAllelicCounts/{tumor}/{tumor}.counts.hdf5",tumor=config["normals"])

rule PreprocessIntervals:
	output:
		interval_list = "results/PreprocessIntervals/preprocessed_intervals.interval_list"
	params:
		gatk = config["gatk_path"],
    		reference_genome = config["reference_genome"],
    		reference_dict = config["reference_dict"],
    		reference_index = config["reference_index"],
		intervals = config["intervals"]
	log:
		"logs/PreprocessIntervals/PreprocessIntervals.txt"
	shell:
		"{params.gatk} PreprocessIntervals \
            	--reference {params.reference_genome} \
		--intervals {params.intervals} \
            	--padding 250 \
            	--bin-length 1000 \
            	--interval-merging-rule OVERLAPPING_ONLY \
            	--output {output.interval_list}"

rule CollectCounts:
	input:
  		preprocessed_intervals = "results/PreprocessIntervals/preprocessed_intervals.interval_list",
		bam = lambda wildcards: config["base_file_name"][wildcards.tumor],
		bam_idx = lambda wildcards: config["base_file_name"][config["index"][wildcards.tumor]]
	output:
		collect_read_counts = "results/CollectAllelicCounts/{tumor}/{tumor}.counts.hdf5"
	params:
		gatk = config["gatk_path"],
    		reference_genome = config["reference_genome"],
    		reference_dict = config["reference_dict"],
    		reference_index = config["reference_index"]
	shell:
		"""
		{params.gatk} CollectReadCounts \
            	-L {input.preprocessed_intervals} \
            	--input {input.bam} \
            	--read-index {input.bam_idx} \
            	--reference {params.reference_genome} \
            	--interval-merging-rule OVERLAPPING_ONLY \
            	--output {output.collect_read_counts} #counts_filename_for_collect_read_counts = basename(counts_filename, ".gz")
		"""


rule CollectAllelicCounts:
      	input:
		bam = lambda wildcards: config["base_file_name"][wildcards.tumor],
		bam_idx = lambda wildcards: config["base_file_name"][config["index"][wildcards.tumor]]
	output:
		allelic_counts = "results/CollectAllelicCounts/{tumor}/{tumor}.allelicCounts.tsv"
	params:
		gatk = config["gatk_path"],
    		reference_genome = config["reference_genome"],
    		reference_dict = config["reference_dict"],
    		reference_index = config["reference_index"],
		common_sites = config["common_sites"]
	shell:
		"""
	   	{params.gatk} CollectAllelicCounts \
           	 -L {params.common_sites} \
            	--input {input.bam} \
            	--read-index {input.bam_idx} \
            	--reference {params.reference_genome} \
            	--minimum-base-quality 20 \
            	--output {output.allelic_counts}
		"""
      	   
