#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { PERSAMPLE_GVCFS } from './modules/1persample_gvcfs.nf'

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

    PERSAMPLE_GVCFS(samples_ch, reference_ch)

    PERSAMPLE_GVCFS.out.gvcf.view()
}