

rule DenoiseReadCounts:
  entity_id = CollectCountsTumor.entity_id, # String base_filename = basename(bam, ".bam") entity_id = base_filename
            read_counts = CollectCountsTumor.counts, #counts = counts_filename #String counts_filename = "~{base_filename}.~{counts_filename_extension}"
#
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
            --output ~{output_dir_} \
            --output-prefix ~{entity_id}
    

