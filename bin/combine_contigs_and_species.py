#!/usr/bin/env python3

import sys
import csv
from collections import defaultdict
import os

def parse_centrifuge_results(results_file):
    contig_classifications = defaultdict(list)
    with open(results_file, 'r') as f:
        reader = csv.reader(f, delimiter='\t')
        next(reader)  # Skip header
        for row in reader:
            contig_id, seq_id, tax_id, score, query_length = row[0], row[1], row[2], row[3], row[6]
            try:
                score = float(score)
            except ValueError:
                score = 0  # Default to 0 if score can't be converted to float
            contig_classifications[contig_id].append((tax_id, score, query_length))
    return contig_classifications

def parse_centrifuge_report(report_file):
    tax_info = {}
    with open(report_file, 'r') as f:
        reader = csv.reader(f, delimiter='\t')
        next(reader)  # Skip header
        for row in reader:
            name, tax_id, tax_rank, genome_size, num_reads, num_unique_reads, abundance = row
            tax_info[tax_id] = {
                'name': name,
                'rank': tax_rank,
                'genome_size': genome_size,
                'num_reads': num_reads,
                'num_unique_reads': num_unique_reads,
                'abundance': abundance
            }
    return tax_info

def get_best_classification(classifications, tax_info):
    if not classifications:
        return 'Unknown', 'Unknown', 'Unknown', 'Unknown', 'Unknown', 'Unknown'
    
    # Sort by score (highest first) and take the best one
    best_tax_id, best_score, query_length = sorted(classifications, key=lambda x: x[1], reverse=True)[0]
    
    if best_tax_id in tax_info:
        info = tax_info[best_tax_id]
        return info['name'], best_tax_id, info['rank'], info['abundance'], str(best_score), query_length
    else:
        return 'Unknown', best_tax_id, 'Unknown', 'Unknown', str(best_score), query_length

def combine_contigs_and_species(results_file, report_file, output_file):
    contig_classifications = parse_centrifuge_results(results_file)
    tax_info = parse_centrifuge_report(report_file)

    # Extract sample name from the results file name
    sample_name = os.path.basename(results_file).split('_')[0]  # Assumes the sample name is the first part of the filename

    with open(output_file, 'w', newline='') as out:
        writer = csv.writer(out, delimiter='\t', quoting=csv.QUOTE_MINIMAL)
        
        # Write the header
        writer.writerow(['Sample', 'Contig_ID', 'Length', 'Species', 'TaxID', 'TaxRank', 'Abundance', 'Score'])
        
        for contig_id, classifications in contig_classifications.items():
            species, tax_id, tax_rank, abundance, score, length = get_best_classification(classifications, tax_info)
            writer.writerow([sample_name, contig_id, length, species, tax_id, tax_rank, abundance, score])
            
if __name__ == '__main__':
    if len(sys.argv) != 4:
        print("Usage: combine_contigs_and_species.py <centrifuge_results> <centrifuge_report> <output_file>")
        sys.exit(1)
    
    results_file = sys.argv[1]
    report_file = sys.argv[2]
    output_file = sys.argv[3]
    
    combine_contigs_and_species(results_file, report_file, output_file)