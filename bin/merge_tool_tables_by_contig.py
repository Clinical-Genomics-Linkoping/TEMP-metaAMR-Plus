#!/usr/bin/env python3
import pandas as pd
import argparse
import os

def load_table(path, rename=None):
    if os.path.exists(path):
        df = pd.read_csv(path, sep='\t')
        if rename:
            df.rename(columns=rename, inplace=True)
        return df
    return None

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--sample', required=True)
    parser.add_argument('--output', required=True)
    

    # Tool directories (add more as needed)
    parser.add_argument('--centrifuge_dir', required=False)
    parser.add_argument('--resfinder_dir', required=False)
    parser.add_argument('--amrfinderplus_dir', required=False)
    parser.add_argument('--plasmidfinder_dir', required=False)

    args = parser.parse_args()
    sample = args.sample
    merged_tables = []

    # Tool: Centrifuge
    if args.centrifuge_dir:
        centrifuge_file = os.path.join(args.centrifuge_dir, f"{sample}_contigs_species.tsv")
        centrifuge = load_table(centrifuge_file, rename={"Contig_ID": "Contig"})
        if centrifuge is not None:
            merged_tables.append(centrifuge)

    # Tool: ResFinder
    if args.resfinder_dir:
        resfinder_file = os.path.join(args.resfinder_dir, f"{sample}_resfinder_summary.tsv")
        resfinder = load_table(resfinder_file)
        if resfinder is not None:
            merged_tables.append(resfinder)

    # Tool: AMRFinderPlus 
    if args.amrfinderplus_dir:
        amrfinderplus_file = os.path.join(args.amrfinderplus_dir, f"{sample}_amrfinderplus_summary.tsv")
        amrfinderplus = load_table(amrfinderplus_file)
        if amrfinderplus is not None:
            merged_tables.append(amrfinderplus)        

   
    # Tool: PlasmidFinder  # NEW
    if args.plasmidfinder_dir:
        plasmidfinder_file = os.path.join(args.plasmidfinder_dir, f"{sample}_plasmidfinder.tsv")
        plasmidfinder = load_table(plasmidfinder_file)
        if plasmidfinder is not None:
            merged_tables.append(plasmidfinder)


    if not merged_tables:
        raise RuntimeError("No valid tool tables found to merge.")

    # Merge all tables on 'Contig' column
    merged = merged_tables[0]
    for table in merged_tables[1:]:
        merged = pd.merge(merged, table, on="Contig", how="outer")

    merged.to_csv(args.output, sep='\t', index=False)

if __name__ == "__main__":
    main()
