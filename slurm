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
  --perform_trim \
  --perform_hostremoval \
  --hostremoval_reference /mnt/reference/Reference_Genomes/ucsc_hg38/hg38.fa \
  --perform_assembly \
  --perform_polish_assembly \
  --run_resfinder \
  --download_resfinder_db \
  --run_rgi \
  --download_rgi_db \
  --run_amrfinderplus \
  --download_amrfinderplus_db \
  --run_abricate \
  --run_plasmidfinder \
  --download_plasmidfinder_db \
  --run_plasclass \
  --run_hamronization \
  --run_profiling \
  --run_centrifuge 
   -run_centrifuge \
   --amr_summary_mode "top" --top_species 5
   --amr_summary_mode targeted" --target_species "Klebsiella pneumoniae,Escherichia coli"
  
           

echo "========== Job ended at $(date) =========="


************
# Run the pipeline
nextflow run main.nf \
  -profile docker \
  --input samplesheet.csv \
  --databases database.csv \
  --outdir results_full_run \
  --perform_trim \
  --perform_hostremoval \
  --hostremoval_reference /mnt/reference/Reference_Genomes/ucsc_hg38/hg38.fa \
  --perform_assembly \
  --perform_polish_assembly \
  --run_resfinder \
  --download_resfinder_db \
  --run_rgi \
  --download_rgi_db \
  --run_amrfinderplus \
  --download_amrfinderplus_db \
  --run_abricate \
  --run_plasmidfinder \
  --download_plasmidfinder_db \
  --run_plasclass \
  --run_hamronization \
  --run_profiling \
  --run_centrifuge \
  -resume
  
 