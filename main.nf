#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { CALL_VARIANTS } from './modules/1persample_gvcfs.nf'

params.samplesheet = null
params.reference   = null
params.outdir      = 'results'

workflow {

    if (!params.samplesheet) error "Please provide --samplesheet"
    if (!params.reference)   error "Please provide --reference"

    // reference trio: fasta + .fai + .dict, all sitting next to each other
    reference_ch = channel.fromPath(params.reference)
        .map { fasta -> tuple(fasta, file("${fasta}.fai"), file(fasta.toString().replaceAll(/\.fasta$/, '.dict'))) }
        .first()

    // sample_id, cram, crai
    samples_ch = channel.fromPath(params.samplesheet)
        .splitCsv(header: true)
        .map { row -> tuple(row.sample_id, file(row.cram), file(row.crai)) }

    CALL_VARIANTS(samples_ch, reference_ch)

    CALL_VARIANTS.out.gvcf.view()
}