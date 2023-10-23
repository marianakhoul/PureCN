configfile: "config/samples.yaml"
configfile: "config/config.yaml" 

rule all:
	input:
		"results/PreprocessIntervals/preprocessed_intervals.interval_list",
		expand("results/CollectReadCounts/{tumor}/{tumor}.counts.hdf5",tumor=config["normals"]),
		expand("results/CollectAllelicCounts/{tumor}/{tumor}.allelicCounts.tsv",tumor=config["normals"]),
		expand("results/CreateReadCountPanelOfNormals/{tumor}/{tumor}.pon.hdf5",tumor=config["normals"]),
		expand("results/DenoiseReadCounts/{tumor}/{tumor}.standardizedCR.tsv",tumor=config["normals"]),
		expand("results/DenoiseReadCounts/{tumor}/{tumor}.denoisedCR.tsv",tumor=config["normals"]),
		expand("results/ModelSegments/{tumor}/",tumor=config["normals"])

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
		bam_idx = lambda wildcards: config["base_file_name"][config["normals"][wildcards.tumor]]
	output:
		collect_read_counts = "results/CollectReadCounts/{tumor}/{tumor}.counts.hdf5"
	params:
		gatk = config["gatk_path"],
    		reference_genome = config["reference_genome"],
    		reference_dict = config["reference_dict"],
    		reference_index = config["reference_index"]
	log:
		"logs/CollectReadCounts/{tumor}/CollectReadCounts.txt"
	shell:
		"""
		{params.gatk} CollectReadCounts \
            	-L {input.preprocessed_intervals} \
            	--input {input.bam} \
            	--read-index {input.bam_idx} \
            	--reference {params.reference_genome} \
            	--interval-merging-rule OVERLAPPING_ONLY \
            	--output {output.collect_read_counts}
		"""


rule CollectAllelicCounts:
	input:
		bam_file = lambda wildcards: config["base_file_name"][wildcards.tumor],
		bam_idx = lambda wildcards: config["base_file_name"][config["normals"][wildcards.tumor]]
	output:
		allelic_counts = "results/CollectAllelicCounts/{tumor}/{tumor}.allelicCounts.tsv"
	params:
		gatk = config["gatk_path"],
    		reference_genome = config["reference_genome"],
    		reference_dict = config["reference_dict"],
    		reference_index = config["reference_index"],
		common_sites = config["common_sites"]
	log:
		"logs/CollectAllelicCounts/{tumor}/CollectAllelicCounts.txt"
	shell:
		"""
	   	{params.gatk} CollectAllelicCounts \
           	 -L {params.common_sites} \
            	--input {input.bam_file} \
            	--read-index {input.bam_idx} \
            	--reference {params.reference_genome} \
            	--minimum-base-quality 20 \
            	--output {output.allelic_counts}
		"""

rule CreateReadCountPanelOfNormals:
	input:
		read_counts = "results/CollectReadCounts/{tumor}/{tumor}.counts.hdf5"
	output:
		read_counts_pon = "results/CreateReadCountPanelOfNormals/{tumor}/{tumor}.pon.hdf5"
	params:
		gatk = config["gatk_path"]
	log:
	shell:
		"""
		{params.gatk} CreateReadCountPanelOfNormals \
		-I {input.read_counts} \
		-O {output.read_counts_pon}
		"""

rule DenoiseReadCounts:
	input:
		read_counts = "results/CollectReadCounts/{tumor}/{tumor}.counts.hdf5",
		read_count_pon = "results/CreateReadCountPanelOfNormals/{tumor}/{tumor}.pon.hdf5"
	output:
		standardizedCR = "results/DenoiseReadCounts/{tumor}/{tumor}.standardizedCR.tsv",
		denoisedCR = "results/DenoiseReadCounts/{tumor}/{tumor}.denoisedCR.tsv"
	params:
		gatk = config["gatk_path"]
	log:
		"logs/DenoiseReadCounts/{tumor}/DenoiseReadCounts.txt"
	shell:
		"""
		{params.gatk} DenoiseReadCounts \
		--input {input.read_counts} \
		--count-panel-of-normals {input.read_count_pon} \
		--standardized-copy-ratios {output.standardizedCR} \
		--denoised-copy-ratios {output.denoisedCR}
		"""

rule ModelSegments:
	input:
		denoised_copy_ratios = "results/DenoiseReadCounts/{tumor}/{tumor}.denoisedCR.tsv",
		allelic_counts = "results/CollectAllelicCounts/{tumor}/{tumor}.allelicCounts.tsv"
	output:
		output_dir = "results/ModelSegments/{tumor}/"
	params:
		gatk = config["gatk_path"]
	log:
		"logs/ModelSegments/{tumor}/ModelSegments.txt"
	shell:
		"""{params.gatk} ModelSegments \
		--denoised-copy-ratios {input.denoised_copy_ratios} \
		--allelic-counts {input.allelic_counts} \
		--minimum-total-allele-count-normal 30 \
		--genotyping-homozygous-log-ratio-threshold -10.0 \
		--genotyping-base-error-rate 0.05 \
		--maximum-number-of-segments-per-chromosome 1000 \
		--kernel-variance-copy-ratio 0.0 \
		--kernel-variance-allele-fraction 0.025 \
		--kernel-scaling-allele-fraction 1.0 \
		--kernel-approximation-dimension 100 \
		--number-of-changepoints-penalty-factor 1.0 \
		--minor-allele-fraction-prior-alpha 25.0 \
		--number-of-samples-copy-ratio 100 \
		--number-of-burn-in-samples-copy-ratio 50 \
		--number-of-samples-allele-fraction 100 \
		--number-of-burn-in-samples-allele-fraction 50 \
		--smoothing-credible-interval-threshold-copy-ratio 2.0 \
		--smoothing-credible-interval-threshold-allele-fraction 2.0 \
		--maximum-number-of-smoothing-iterations 10 \
		--number-of-smoothing-iterations-per-fit 0 \
		--output {output.output_dir} \
		--output-prefix {wildcards.tumor}"""
    

