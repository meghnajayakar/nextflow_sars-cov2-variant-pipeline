#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { PERSAMPLE_GVCFS } from './modules/1persample_gvcfs.nf'
include { COMBINE_GVCFS } from "./modules/2combine_gvcfs.nf"
include { JOINT_GENOTYPING } from "./modules/3joint_genotyping.nf"
include { VARIANT_FILTRATION} from "./modules/4variant_filtration.nf"

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

    gvcfs_ch = PERSAMPLE_GVCFS.out.gvcf.map{sample_id, gvcf, tbi -> gvcf}.collect()
    indices_ch = PERSAMPLE_GVCFS.out.gvcf.map{sample_id, gvcf, tbi -> tbi}.collect()

    COMBINE_GVCFS(reference_ch, gvcfs_ch, indices_ch)

    JOINT_GENOTYPING(reference_ch, COMBINE_GVCFS.out.combined_gvcf)

    VARIANT_FILTRATION(JOINT_GENOTYPING.out.joint_genotyping)



}