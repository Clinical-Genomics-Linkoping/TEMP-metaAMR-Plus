#!/bin/bash
#SBATCH --job-name=metaamr
#SBATCH --output=metaamr_%j.out
#SBATCH --error=metaamr_%j.err
#SBATCH --time=14:00:00               
#SBATCH --cpus-per-task=1                              
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=leila.nasirzadeh@liu.se

echo "========== Job ended at $(date) =========="

module load nextflow-24.04.4  
          


# Run the pipeline
nextflow run main.nf \
  -profile docker \
  --input samplesheet.csv \
  --databases database.csv \
  --outdir results_full_run \
  --perform_assembly \
  --perform_polish_assembly \
  --run_resfinder \
  --download_resfinder_db \
 
   
echo "========== Job ended at $(date) =========="