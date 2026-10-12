#!/usr/bin/env bash
set -euo pipefail

OUT=testdata
mkdir -p "$OUT"
cd "$OUT"
D=$(pwd)

# --- fake 100 kb reference ---
python3 - <<'PYEOF'
import random
random.seed(1)
seq = ''.join(random.choice('ACGT') for _ in range(100000))
with open('ref.fasta', 'w') as f:
    f.write('>chrTest\n')
    for i in range(0, len(seq), 60):
        f.write(seq[i:i+60] + '\n')
PYEOF

samtools faidx ref.fasta               # ref.fasta.fai
samtools dict ref.fasta -o ref.dict    # ref.dict
bwa index ref.fasta

python3 - <<'PYEOF'
# Tile chrTest with single-exon protein-coding "genes".
# Each gene length is divisible by 3 so the CDS is in frame.
genes = [(1, 300)]                      # one short gene at the very start
start = 5001
while start + 3000 <= 100000:           # a 3 kb gene every 5 kb
    genes.append((start, start + 2999))
    start += 5000

rows = ["##gff-version 3"]
for i, (s, e) in enumerate(genes, 1):
    attrs_gene = f"ID=gene{i};Name=TESTG{i};biotype=protein_coding"
    rows += [
        f"chrTest\ttest\tgene\t{s}\t{e}\t.\t+\t.\t{attrs_gene}",
        f"chrTest\ttest\tmRNA\t{s}\t{e}\t.\t+\t.\tID=tx{i};Parent=gene{i};biotype=protein_coding",
        f"chrTest\ttest\texon\t{s}\t{e}\t.\t+\t.\tID=ex{i};Parent=tx{i}",
        f"chrTest\ttest\tCDS\t{s}\t{e}\t.\t+\t0\tID=cds{i};Parent=tx{i}",
    ]
with open("genes.gff3", "w") as f:
    f.write("\n".join(rows) + "\n")
PYEOF

# VEP needs the GFF sorted, bgzipped and tabix-indexed
(grep "^#" genes.gff3; grep -v "^#" genes.gff3 | sort -k1,1 -k4,4n) | bgzip > genes.gff3.gz
tabix -p gff genes.gff3.gz

# --- two simulated samples (~30x coverage) ---
for pair in sampleA:11 sampleB:22; do
  s=${pair%%:*}
  seed=${pair##*:}

  wgsim -N 10000 -1 150 -2 150 -r 0.005 -S "$seed" ref.fasta "${s}_1.fq" "${s}_2.fq" > /dev/null

#   bwa mem -R "@RG\tID:${s}\tSM:${s}\tPL:ILLUMINA" ref.fasta "${s}_1.fq" "${s}_2.fq" \
#     | samtools sort -O cram --reference ref.fasta -o "${s}.cram" -

# version mismatch between CRAM 3.1 and GATK, hence requesting version 3.0 for compatibility 

bwa mem -R "@RG\tID:${s}\tSM:${s}\tPL:ILLUMINA" ref.fasta "${s}_1.fq" "${s}_2.fq" \
  | samtools sort -O cram,version=3.0 --reference ref.fasta -o "${s}.cram" -

  samtools index "${s}.cram"           # ${s}.cram.crai
  rm "${s}_1.fq" "${s}_2.fq"
done

# --- samplesheet (absolute paths) ---
cat > samples.csv <<CSVEOF
sample_id,cram,crai
sampleA,${D}/sampleA.cram,${D}/sampleA.cram.crai
sampleB,${D}/sampleB.cram,${D}/sampleB.cram.crai
CSVEOF

echo "Done. Files in $D:"
ls -1