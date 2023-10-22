#configfile: "config/samples.yaml"
configfile: "config/config.yaml" 

rule all:
	input:
		"results/PreprocessIntervals/preprocessed_intervals.interval_list"

rule PreprocessIntervals:
	output:
		interval_list = "results/PreprocessIntervals/preprocessed_intervals.interval_list"
	params:
		gatk = config["gatk_path"],
    		reference_genome = config["reference_genome"],
    		reference_dict = config["reference_dict"],
    		reference_index = config["reference_index"]
	log:
		"logs/PreprocessIntervals/PreprocessIntervals.txt"
	shell:
		"{params.gatk} PreprocessIntervals \
            	--reference {params.reference_genome} \
            	--padding 250 \
            	--bin-length 1000 \
            	--interval-merging-rule OVERLAPPING_ONLY \
            	--output {output.interval_list}"
