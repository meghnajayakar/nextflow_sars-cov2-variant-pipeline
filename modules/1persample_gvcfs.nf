// modules/1persample_gvcfs.nf

process PERSAMPLE_GVCFS {
    tag "$sample_id"
    container 'broadinstitute/gatk:4.5.0.0'
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
        -ploidy 1 \\
        -ERC GVCF
    """
}