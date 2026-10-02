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