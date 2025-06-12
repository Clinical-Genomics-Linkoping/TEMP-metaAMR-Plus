#!/usr/bin/env python3

import pandas as pd
import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description="Postprocess ResFinder raw output (clean)")
    parser.add_argument('--input', required=True, help='Input ResFinder results_table.txt file')
    parser.add_argument('--output', required=True, help='Output summary TSV file')
    args = parser.parse_args()

    # Load raw lines and filter manually
    cleaned_lines = []
    with open(args.input, 'r') as infile:
        for line in infile:
            stripped = line.strip()
            if not stripped:
                continue  # Skip empty lines
            if stripped.lower().startswith('resistance gene'):
                continue  # Skip repeated headers
            if len(stripped.split('\t')) < 6:
                continue  # Likely a category line like "Aminoglycoside"
            cleaned_lines.append(stripped)

    if not cleaned_lines:
        print("[resfinder] No valid rows found.", file=sys.stderr)
        pd.DataFrame(columns=["Contig", "Gene_Symbol", "Identity", "Phenotype", "Accession"]).to_csv(args.output, sep='\t', index=False)
        return

    # Parse into DataFrame
    df = pd.DataFrame([x.split('\t') for x in cleaned_lines])
    df.columns = ["Gene_Symbol", "Identity", "Alignment", "Coverage", "Position_ref", "Contig", "Position_contig", "Phenotype", "Accession"]

    # Keep only the relevant summary columns
    df_out = df[["Contig", "Gene_Symbol", "Identity", "Phenotype", "Accession"]]

    # Save
    df_out.to_csv(args.output, sep='\t', index=False)
    print(f"[resfinder] Clean summary written to {args.output}")

if __name__ == "__main__":
    main()
