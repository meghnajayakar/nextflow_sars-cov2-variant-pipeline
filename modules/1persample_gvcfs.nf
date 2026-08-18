// modules/call_variants.nf

process CALL_VARIANTS {
    tag "$sample_id"
    publishDir "${params.outdir}/gvcf", mode: 'copy'

    input:
    tuple val(sample_id), path(cram), path(crai)
    tuple path(fasta), path(fai), path(dict)

    output:
    tuple val(sample_id), path("${sample_id}.g.vcf.gz"), path("${sample_id}.g.vcf.gz.tbi"), emit: gvcf

    script:
    """
    gatk HaplotypeCaller \\
        -R ${fasta} \\
        -I ${cram} \\
        -O ${sample_id}.g.vcf.gz \\
        -ERC GVCF
    """
}