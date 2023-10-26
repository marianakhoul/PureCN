configfile: "config/samples_purecn.yaml"
configfile: "config/config.yaml" 

rule all:
	input:
		expand("results/PureCN/{tumor}/",tumor=config["normals"])

rule PureCN:
	input:
		segFile = "results/ModelSegments/{tumor}/{tumor}.modelFinal.seg"
	output:
		output_dir = directory("results/PureCN/{tumor}/")
	log:
		"logs/PureCN/{tumor}/PureCN.txt"
	params:
		purecn_intervals = config["purecn_intervals"],
		purecn_script = config["purecn_script"]
		genome = config["genome"],
		maxCopyNumber = config["maxCopyNumber"],
		minPurity = config["minPurity"],
		maxPurity = config["maxPurity"],
		funSegmentation = config["funSegmentation"],
		maxSegments = config["maxSegments"]

	shell:
		"""
		Rscript {params.purecn_script} \
			--out {output.output_dir} \
			--sampleid {wildcards.tumor} \
			--seg-file {input.segFile} \
			--vcf "${vcf}" \
			--intervals {params.purecn_intervals} \
			--genome {params.genome} \
			--max-purity {params.maxPurity} \
			--min-purity {params.minPurity} \
			--max-copy-number {params.maxCopyNumber} \
			--fun-segmentation {params.funSegmentation} \
			--max-segments {params.maxSegments} \
			--post-optimize --model-homozygous --min-total-counts 20

		Rscript -e "write.table(read.csv('{wildcards.tumor}.csv'),'table.txt',sep='\n',row.names=F,col.names=F,quote=F)"
		Rscript depmap_omics/WGS_pipeline/PureCN_pipeline/call_wgd_and_cin.R "${sampleID}_loh.csv" "${sampleID}.csv"
		"""



