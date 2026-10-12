// modules/5variant_annotation.nf

process VARIANT_ANNOTATION {
    container 'ensemblorg/ensembl-vep:release_116.3'   
    publishDir "${params.outdir}/variant_annotation", mode: 'copy'

    input:
    tuple path(vcf), path(vcf_tbi)
    tuple path(gff), path(gff_tbi)
    tuple path(fasta), path(fai), path(dict)

    output:
    tuple path("var_annotation.vcf.gz"), path("var_annotation.vcf.gz.tbi"), emit: variant_annotation

    script:
    """
    vep \\
        -i ${vcf} \\
        -o var_annotation.vcf \\
        --vcf \\
        --force_overwrite \\
        --gff ${gff} \\
        --fasta ${fasta} \\
        --symbol \\
        --canonical \\
        --biotype \\

    bgzip var_annotation.vcf
    tabix -p vcf var_annotation.vcf.gz
    """
}