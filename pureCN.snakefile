configfile: "config/samples.yaml"
configfile: "config/config.yaml" 


rule all:
	input:
		"results/MergeVcfs/subsetnormalpanel.vcf.gz"


rule PreprocessIntervals:
	output:
		interval_list = "results/PreprocessIntervals/{tumor}/{tumor}.preprocessed.interval_list"
	params:
		gatk = config["gatk_path"],
    		reference_genome = config["reference_genome"],
    		reference_dict = config["reference_dict"]
    		reference_index = config["reference_index"]
	log:
		"logs/PreprocessIntervals/{tumor}/PreprocessIntervals.txt"
	shell:
		"""
		{params.gatk} --java-options "-Xmx~{command_mem_mb}m" PreprocessIntervals \
            	--reference {params.reference_genome} \
            	--padding 250 \
            	--bin-length 1000 \
            	--interval-merging-rule OVERLAPPING_ONLY \
            	--output {output.interval_list}"""

rule CollectCounts:
	input:
  		preprocessed_intervals = "results/PreprocessIntervals/{tumor}/{tumor}.preprocessed.interval_list",
		bam = lambda wildcards: config["base_file_name"][wildcards.tumor],
		bam_idx = lambda wildcards: config["base_file_name"][config["index"][wildcards.tumor]]
	output:
		counts_filename_for_collect_read_counts = ""
	params:
		gatk = config["gatk_path"],
    		reference_genome = config["reference_genome"],
    		reference_dict = config["reference_dict"]
    		reference_index = config["reference_index"]
	shell:
		"""
		{params.gatk} --java-options "-Xmx~{command_mem_mb}m" CollectReadCounts \
            	-L {input.preprocessed_intervals} \
            	--input {input.bam} \
            	--read-index {input.bam_idx} \
            	--reference {params.reference_genome} \
            	--interval-merging-rule OVERLAPPING_ONLY \
            	--output {output.counts_filename_for_collect_read_counts}
		"""


rule CollectAllelicCounts:
  File common_sites
      File bam
      File bam_idx
      File ref_fasta
      File ref_fasta_fai
      File ref_fasta_dict


      {params.gatk} --java-options "-Xmx~{command_mem_mb}m" CollectAllelicCounts \
            -L ~{common_sites} \
            --input ~{bam} \
            --read-index ~{bam_idx} \
            --reference ~{ref_fasta} \
            --minimum-base-quality ~{default="20" minimum_base_quality} \
            --output ~{allelic_counts_filename} \
            ~{"--gcs-project-for-requester-pays " + gcs_project_for_requester_pays}


rule DenoiseReadCounts:
  String entity_id
      File read_counts
      File read_count_pon

    {params.gatk} --java-options "-Xmx~{command_mem_mb}m" DenoiseReadCounts \
            --input ~{read_counts} \
            --count-panel-of-normals ~{read_count_pon} \
            ~{"--number-of-eigensamples " + number_of_eigensamples} \
            --standardized-copy-ratios ~{entity_id}.standardizedCR.tsv \
            --denoised-copy-ratios ~{entity_id}.denoisedCR.tsv
  

    
rule ModelSegments:
  String entity_id
      File denoised_copy_ratios
      File allelic_counts
    {params.gatk} --java-options "-Xmx~{command_mem_mb}m" ModelSegments \
            --denoised-copy-ratios ~{denoised_copy_ratios} \
            --allelic-counts ~{allelic_counts} \
            ~{"--normal-allelic-counts " + normal_allelic_counts} \
            --minimum-total-allele-count-case ~{min_total_allele_count_} \
            --minimum-total-allele-count-normal ~{default="30" min_total_allele_count_normal} \
            --genotyping-homozygous-log-ratio-threshold ~{default="-10.0" genotyping_homozygous_log_ratio_threshold} \
            --genotyping-base-error-rate ~{default="0.05" genotyping_base_error_rate} \
            --maximum-number-of-segments-per-chromosome ~{default="1000" max_num_segments_per_chromosome} \
            --kernel-variance-copy-ratio ~{default="0.0" kernel_variance_copy_ratio} \
            --kernel-variance-allele-fraction ~{default="0.025" kernel_variance_allele_fraction} \
            --kernel-scaling-allele-fraction ~{default="1.0" kernel_scaling_allele_fraction} \
            --kernel-approximation-dimension ~{default="100" kernel_approximation_dimension} \
            --window-size ~{sep=" --window-size " window_sizes} \
            --number-of-changepoints-penalty-factor ~{default="1.0" num_changepoints_penalty_factor} \
            --minor-allele-fraction-prior-alpha ~{default="25.0" minor_allele_fraction_prior_alpha} \
            --number-of-samples-copy-ratio ~{default="100" num_samples_copy_ratio} \
            --number-of-burn-in-samples-copy-ratio ~{default="50" num_burn_in_copy_ratio} \
            --number-of-samples-allele-fraction ~{default="100" num_samples_allele_fraction} \
            --number-of-burn-in-samples-allele-fraction ~{default="50" num_burn_in_allele_fraction} \
            --smoothing-credible-interval-threshold-copy-ratio ~{default="2.0" smoothing_threshold_copy_ratio} \
            --smoothing-credible-interval-threshold-allele-fraction ~{default="2.0" smoothing_threshold_allele_fraction} \
            --maximum-number-of-smoothing-iterations ~{default="10" max_num_smoothing_iterations} \
            --number-of-smoothing-iterations-per-fit ~{default="0" num_smoothing_iterations_per_fit} \
            --output ~{output_dir_} \
            --output-prefix ~{entity_id}
    

