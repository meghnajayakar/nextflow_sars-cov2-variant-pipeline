// modules/4variant_filtration.nf

process VARIANT_FILTRATION {
    // tag "$sample_id"
    container 'broadinstitute/gatk:4.5.0.0'
    publishDir "${params.outdir}/variant_filtration", mode: 'copy'

    input:
    tuple path(combined_raw_vcf), path(combined_raw_vcf_tbi)

    output:
    tuple path("combined.exp_filtration.vcf.gz"), path("combined.exp_filtration.vcf.gz.tbi"), emit: variant_filtration

    script:
    """
    gatk VariantFiltration \\
        -V ${combined_raw_vcf} \\
            --filter-expression "QD < 2.0" --filter-name QD2 \
            --filter-expression "FS > 60.0" --filter-name FS60 \
            --filter-expression "MQ < 40.0" --filter-name MQ40 \
            --filter-expression "QUAL < 30.0" --filter-name QUAL30 \
        -O combined.exp_filtration.vcf.gz 
    """
}
