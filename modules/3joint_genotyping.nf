// modules/3joint_genotyping.nf

process JOINT_GENOTYPING {
    container 'broadinstitute/gatk:4.5.0.0'
    publishDir "${params.outdir}/joint_genotyping", mode: 'copy'

    input:
    tuple path(fasta), path(fai), path(dict)
    tuple path(combined_gvcf), path(combined_gvcf_tbi)

    output:
    tuple path("combined.raw.vcf.gz"), path("combined.raw.vcf.gz.tbi"), emit: joint_genotyping

    script:
    """
    gatk GenotypeGVCFs \
        -R ${fasta} \
        -V ${combined_gvcf} \
        --include-non-variant-sites true \
        -O combined.raw.vcf.gz
    """
}