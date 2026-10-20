# Nextflow variant calling and annotation pipeline

A modular Nextflow (DSL2) pipeline for germline variant calling and annotation, inspired by the WGS analysis stage of my MSc dissertation at King's College London (Using iPSC variation to define HIV-1 regulatory networks). Developed as a personal project to practise workflow engineering and pipeline development.

## Overview

```
CRAM --> HaplotypeCaller (per sample, gVCF) --> CombineGVCFs --> GenotypeGVCFs
     --> VariantFiltration --> Ensembl VEP annotation
```

| Step | Module | Tool |
|------|--------|------|
| 1 | `modules/1persample_gvcfs.nf` | GATK HaplotypeCaller (`-ERC GVCF`) |
| 2 | `modules/2combine_gvcfs.nf` | GATK CombineGVCFs |
| 3 | `modules/3joint_genotyping.nf` | GATK GenotypeGVCFs |
| 4 | `modules/4variant_filtration.nf` | GATK VariantFiltration (hard filters) |
| 5 | `modules/5variant_annotation.nf` | Ensembl VEP (GFF-based annotation) |

Each process runs in a container (GATK 4.5.0.0; Ensembl VEP release 115).

## Requirements

- Nextflow (>= 23.04.0)
- Docker (or adapt the config for Singularity)
- CRAM input, **version 3.0**. The GATK version used here is not compatible with CRAM 3.1, so create CRAMs with `samtools sort -O cram,version=3.0`.
- For generating test data: `samtools`, `bwa`, `wgsim`, `tabix`/`bgzip`, `python3`

## Quick start

Activate the environment:

```bash
micromamba env create -f environment.yml --yes
micromamba activate testdata
```

Generate the synthetic test dataset, then run:

```bash
bash make_testdata.sh        
nextflow run main.nf -profile synthetic -resume
```

Or run on the SARS-CoV-2 reference:

```bash
nextflow run main.nf -profile sarscov2 -resume
```

Results are written to `results/<profile>/`.

## Input

Provide a samplesheet CSV with absolute paths to CRAM and index files:

```csv
sample_id,cram,crai
sample1,/path/to/sample1.cram,/path/to/sample1.cram.crai
sample2,/path/to/sample2.cram,/path/to/sample2.cram.crai
```

Even for the simulated datasets, reads generated with `wgsim` (FASTQ) were aligned with `bwa mem`, with one read group per sample, and written as CRAM v3.0 to match the input expected by a typical WGS workflow.

Parameters:

| Parameter | Description |
|-----------|-------------|
| `--samplesheet` | CSV of samples (above) |
| `--reference` | Reference FASTA; `.fai` and `.dict` must sit alongside (`ref.fasta`, `ref.fasta.fai`, `ref.dict`) |
| `--gff` | bgzipped, tabix-indexed GFF3 for VEP (`.tbi` alongside) |
| `--outdir` | Output directory |

Note: the reference filename must end in `.fasta`, because the `.dict` path is derived from it.

## Profiles

- `synthetic`: simulated reads on a random 100 kb reference with a tiled fake GFF
- `sarscov2`: simulated reads (wgsim) on the SARS-CoV-2 reference (NC_045512.2) with its NCBI annotation, restructured for VEP

Both datasets use simulated reads, not real sequencing data. For haploid SARS-CoV-2, HaplotypeCaller is run with `-ploidy 1`.

## Results and validation

The pipeline was tested end to end on simulated reads (wgsim) aligned to the SARS-CoV-2 reference NC_045512.2. It called 16 variants, annotated with Ensembl VEP.

- **Genotypes:** haploid calls (`GT=1`, `AF=1.00`), as expected for a clonal viral sample. Most variants passed the hard filters; low-quality sites were flagged (e.g. `QD2`).
- **Coding consequences:**

| Position | Change | Gene | Consequence |
|----------|--------|------|-------------|
| 21965 | T>C | S (Spike) | Missense (F/L), moderate |
| 26466 | G>A | E (Envelope) | Synonymous (L), low |
| 27137 | A>T | M (Membrane) | Missense (K/N), moderate |
| 27319 | T>C | ORF6 | Synonymous (L), low |
| 27609 | A>C | ORF7a | Missense (K/N), moderate |
| 29337 | A>C | N (Nucleocapsid) | Missense (K/T), moderate |

- **Non-coding:** the remaining variants were annotated as intergenic (e.g. positions 991, 2154, 5182) or upstream/downstream of genes.

Because the reads are simulated, these results demonstrate that the workflow runs correctly and produces sensible annotation. They are not a biological finding.

## Scope and limitations

- Annotation uses a custom GFF and FASTA rather than the full VEP cache, so SIFT, PolyPhen and population frequency (gnomAD) fields are not available.
- The NCBI viral GFF has a gene to CDS structure, without the transcript/exon layer VEP expects. It was restructured with a small Python script that adds an mRNA and exon for each gene before sorting, bgzipping and indexing. UTRs are omitted, and ORF1ab's two frameshift CDS segments are represented as two exons of one transcript, which is a simplification.
- The data are simulated, so the repo demonstrates the workflow, not a scientific result.

## Relationship to the dissertation

The original analysis (GATK, VEP with gnomAD and cCRE tracks, DESeq2, pathway enrichment, motif analysis, AlphaMissense/AlphaGenome) was run with scripts on an HPC cluster; those scripts are in [meghnajayakar/HIV-1_iPSC_Project](https://github.com/meghnajayakar/HIV-1_iPSC_Project). This repo covers only the variant calling and annotation stages as a Nextflow workflow.

## Development environment

The repository includes a `.devcontainer` configuration and a `setup.sh` script. Opening it in GitHub Codespaces or VS Code Remote - Containers provisions the environment (Nextflow and the testing tools) automatically.

## Future work

- Consequence and population-frequency filtering
- A GFF normalisation step, so NCBI-style annotations work without manual restructuring
- Singularity/HPC profile
- `nf-test` tests
- Containerised R/Python stages (DESeq2, enrichment)

## References 
- SARS-CoV-2 reference NC_045512.2 genome FASTA file: https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NC_045512.2&rettype=fasta&retmode=text
- SARS-CoV-2 reference NC_045512.2 genome GFF3 file: https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NC_045512.2&rettype=gff3&retmode=text

## Author

Meghna B. Jayakar | https://github.com/meghnajayakar