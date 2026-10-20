import re
rows = []
for line in open("original_ncbi.gff3"):
    if line.startswith("#") or not line.strip():
        continue
    f = line.rstrip("\n").split("\t")
    rows.append(f)

out = ["##gff-version 3"]
for f in rows:
    if f[2] != "gene":
        continue
    gid = re.search(r"ID=([^;]+)", f[8]).group(1)
    name = re.search(r"Name=([^;]+)", f[8])
    name = name.group(1) if name else gid
    tid = "tx-" + gid
    out.append("\t".join(f[:8] + [f"ID={gid};Name={name};biotype=protein_coding"]))
    out.append("\t".join(f[:2] + ["mRNA"] + f[3:8] + [f"ID={tid};Parent={gid};Name={name};biotype=protein_coding"]))
    # exon spanning all CDS segments of this gene
    cds = [c for c in rows if c[2] == "CDS" and f"Parent={gid}" in c[8]]
    for i, c in enumerate(sorted(cds, key=lambda x: int(x[3])), 1):
        out.append("\t".join(c[:2] + ["exon"] + c[3:7] + ["."] + [f"ID=ex-{gid}-{i};Parent={tid}"]))
        out.append("\t".join(c[:7] + [c[7]] + [f"ID=cds-{gid}-{i};Parent={tid}"]))
open("sars_fixed.gff3", "w").write("\n".join(out) + "\n")