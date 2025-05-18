#!/usr/bin/env python3

import argparse
import pandas as pd
import glob
from pathlib import Path

TOOL_COLUMNS = {
    "rgi": {
        "file_ext": "_rgi.txt",
        "columns": ["Contig", "Best_Hit_ARO", "Drug Class", "Resistance Mechanism", "AMR Gene Family"],
    },
    "abricate": {
        "file_ext": "_abricate.tsv",
        "columns": ["SEQUENCE", "GENE", "%IDENTITY", "PRODUCT", "RESISTANCE"],
    },
    "resfinder": {
        "file_ext": "-ResFinder_results_tab.txt",
        "columns": ["Resistance gene", "Identity", "Contig", "Phenotype"],
    },
    "amrfinder": {
        "file_ext": "_amrfinder.tsv",
        "columns": ["Contig id", "Gene symbol", "Class", "Subclass"],
    },
    "plasmidfinder": {
        "file_ext": "_plasmidfinder.tsv",
        "columns": ["Contig", "Plasmid Identity"],
    },
    "plasclass": {
        "file_ext": ".plasclass_classified.txt",
        "columns": ["Contig_ID", "Classification"],
    },
    "centrifuge": {
        "file_ext": "_contigs_species.tsv",
        "columns": ["Contig_ID", "Species"],
    }
}

def load_tool_table(sample, tool, input_dir):
    spec = TOOL_COLUMNS[tool]
    tool_files = glob.glob(f"{input_dir}/*{spec['file_ext']}")
    
    if not tool_files:
        print(f"Warning: No file found for {tool} in {input_dir}")
        return pd.DataFrame(columns=["Contig"])
    
    tool_file = tool_files[0]
    df = pd.read_csv(tool_file, sep="\t", comment="#", dtype=str)
    
    # Ensure all expected columns are present
    for col in spec['columns']:
        if col not in df.columns:
            print(f"Warning: Expected column '{col}' not found in {tool} file")
            df[col] = "N/A"
    
    df = df.rename(columns={col: f"{tool}-{col}" for col in spec["columns"]})
    contig_col = f"{tool}-{spec['columns'][0]}"
    df = df.set_index(contig_col)
    return df

def main():
    parser = argparse.ArgumentParser(description="Merge per-tool results by contig for metaAMR analysis.")
    parser.add_argument("--sample", required=True, help="Sample name")
    parser.add_argument("--tools", required=True, help="Comma-separated list of tools")
    parser.add_argument("--input-dir", required=True, help="Directory containing input files")
    parser.add_argument("--output", required=True, help="Output file path")
    args = parser.parse_args()

    tools = [t.strip() for t in args.tools.split(",")]
    summary = pd.DataFrame()
    
    for tool in tools:
        if tool not in TOOL_COLUMNS:
            print(f"Warning: Unknown tool '{tool}'. Skipping.")
            continue
        df = load_tool_table(args.sample, tool, args.input_dir)
        summary = summary.join(df, how="outer")

    summary.index.name = "Contig"
    summary = summary.reset_index()
    
    # Add sample column
    summary.insert(0, "Sample", args.sample)
    
    summary.to_csv(args.output, sep="\t", index=False)
    print(f"Summary saved to {args.output}")

if __name__ == "__main__":
    main()
