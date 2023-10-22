



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
    

