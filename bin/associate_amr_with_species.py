#!/usr/bin/env python

import sys

def load_species_info(summary_file):
    species_counts = {}
    total = 0
    with open(summary_file) as f:
        for line in f:
            if line.lower().startswith("taxid"):  # Skip header
                continue
            parts = line.strip().split('\t')
            if len(parts) != 4:
                continue
            taxid, name, count, status = parts
            count = int(count)
            if status == "Present":
                species_counts[name] = count
                total += count
    return species_counts, total

def associate_amr(amr_file, summary_file):
    species_counts, total_reads = load_species_info(summary_file)
    with open(amr_file) as f:
        for line in f:
            if line.startswith('#'):
                print(line.strip() + '\tPredicted Species\tConfidence')
            else:
                if total_reads > 0:
                    entries = [f"{name} ({count / total_reads:.2f})" for name, count in species_counts.items()]
                    print(line.strip() + '\t' + ', '.join(entries))
                else:
                    print(line.strip() + '\tNA\t0.00')

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: associate_amr_with_species.py <amr_file> <species_summary_file>")
        sys.exit(1)
    associate_amr(sys.argv[1], sys.argv[2])