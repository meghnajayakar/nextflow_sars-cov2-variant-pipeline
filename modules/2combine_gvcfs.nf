// modules/2combine_gvcfs.nf

process COMBINE_GVCFS {
    // tag "$sample_id"
    container 'broadinstitute/gatk:4.5.0.0'
    publishDir "${params.outdir}/combined_gvcf", mode: 'copy'

    input:
    tuple path(fasta), path(fai), path(dict)
    path gvcfs
    path gvcf_indices

    output:
    tuple path("combined.g.vcf.gz"), path("combined.g.vcf.gz.tbi"), emit: combined_gvcf

    script:
    def variant_args = gvcfs.collect { gvcf -> "--variant ${gvcf}" }.join(' ')

    """
    gatk CombineGVCFs \\
        -R ${fasta} \\
        ${variant_args} \\
        -O combined.g.vcf.gz \\
    """
}