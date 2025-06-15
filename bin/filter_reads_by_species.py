#!/usr/bin/env python3

import sys
from collections import defaultdict

def get_species_taxids(report_file, species_list):
    name_to_taxid = {}
    taxid_to_name = {}
    with open(report_file) as f:
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) < 3:
                continue
            name = parts[0].strip()
            taxid = parts[1].strip()
            rank = parts[2].strip().lower()
            if rank == 'species':
                name_lower = name.lower()
                name_to_taxid[name_lower] = taxid
                taxid_to_name[taxid] = name

    selected_taxids = []
    for s in species_list:
        key = s.strip().lower()
        if key in name_to_taxid:
            selected_taxids.append(name_to_taxid[key])
        else:
            print(f"WARNING: Species '{s}' not found in report.", file=sys.stderr)

    return selected_taxids, taxid_to_name

def extract_reads(results_file, taxid_list, taxid_to_name, output_file, summary_file):
    species_read_counts = defaultdict(int)

    if not taxid_list:
        # Write dummy empty output and summary
        print("No matching taxIDs found — creating empty output.", file=sys.stderr)
        with open(output_file, 'w') as out:
            pass
        with open(summary_file, 'w') as summary:
            summary.write("TaxID\tSpecies\tCount\tStatus\n")
            summary.write("NA\tNA\t0\tAbsent\n")
        return

    with open(results_file) as infile, open(output_file, 'w') as out:
        for line in infile:
            parts = line.strip().split('\t')
            if len(parts) < 3:
                continue
            read_id = parts[0]
            taxid = parts[2]
            if taxid in taxid_list:
                out.write(f"{read_id}\t{taxid}\n")
                species_read_counts[taxid] += 1

    with open(summary_file, 'w') as summary:
        summary.write("TaxID\tSpecies\tCount\tStatus\n")
        for taxid in taxid_list:
            name = taxid_to_name.get(taxid, "Unknown")
            count = species_read_counts.get(taxid, 0)
            status = "Present" if count > 0 else "Absent"
            summary.write(f"{taxid}\t{name}\t{count}\t{status}\n")

if __name__ == "__main__":
    if len(sys.argv) != 6:
        print("Usage:", file=sys.stderr)
        print("  python filter_reads_by_species.py <report.txt> <results.txt> <output_reads.txt> <summary.txt> 'Species1,Species2,...'", file=sys.stderr)
        sys.exit(1)

    report_file = sys.argv[1]
    results_file = sys.argv[2]
    output_file = sys.argv[3]
    summary_file = sys.argv[4]
    species_input = sys.argv[5]
    species_list = [s.strip() for s in species_input.split(',') if s.strip()]

    print("Processing with parameters:", file=sys.stderr)
    print(f"Report file: {report_file}", file=sys.stderr)
    print(f"Results file: {results_file}", file=sys.stderr)
    print(f"Output reads file: {output_file}", file=sys.stderr)
    print(f"Summary file: {summary_file}", file=sys.stderr)
    print(f"Species list: {species_input}", file=sys.stderr)

    selected_taxids, taxid_to_name = get_species_taxids(report_file, species_list)
    extract_reads(results_file, selected_taxids, taxid_to_name, output_file, summary_file)