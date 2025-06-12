#!/usr/bin/env python3

import pandas as pd
import argparse
import sys

def main():
    parser = argparse.ArgumentParser(description="Postprocess Abricate output from HAMRonization")
    parser.add_argument('--input', required=True, help='Input harmonized Abricate TSV file')
    parser.add_argument('--output', required=True, help='Output summary TSV file')
    args = parser.parse_args()

    try:
        df = pd.read_csv(args.input, sep='\t', comment="#", dtype=str)
        df.columns = (
            df.columns
            .str.strip()
            .str.replace(r"\s+", " ", regex=True)
            .str.replace(u"\xa0", " ")
        )
    except Exception as e:
        print(f"[abricate] ERROR reading {args.input}: {e}", file=sys.stderr)
        df = pd.DataFrame(columns=[
            "Contig", "Gene_Symbol", "Gene_Name",
            "Database", "Resistance_Mechanism", "Sequence_Identity"
        ])

    expected_cols = {
        "Contig": "input_sequence_id",
        "Gene_Symbol": "gene_symbol",
        "Gene_Name": "gene_name",
        "Database": "reference_database_name",
        "Resistance_Mechanism": "resistance_mechanism",
        "Sequence_Identity": "sequence_identity",
    }

    missing = [v for v in expected_cols.values() if v not in df.columns]
    if missing:
        print(f"[abricate] WARNING: Missing columns {missing}", file=sys.stderr)
        df_out = pd.DataFrame(columns=expected_cols.keys())
    else:
        df_out = df[list(expected_cols.values())].rename(columns={v: k for k, v in expected_cols.items()})

    df_out.to_csv(args.output, sep='\t', index=False)
    print(f"[abricate] Wrote summary to {args.output}")

if __name__ == "__main__":
    main()