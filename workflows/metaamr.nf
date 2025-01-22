/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { FASTQC                 } from '../modules/nf-core/fastqc/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { PORECHOP_PORECHOP      } from '../modules/nf-core/porechop/main'
include { FILTLONG               } from '../modules/nf-core/filtlong/main'
include { RESFINDER_RUN } from '../modules/nf-core/resfinder/run/main'
include { AMRFINDERPLUS_RUN } from '../modules/nf-core/amrfinderplus/run/main' 
include { AMRFINDERPLUS_UPDATE } from '../modules/nf-core/amrfinderplus/update/main' 
include { ABRICATE_RUN } from '../modules/nf-core/abricate/run/main' 
include { RGI_CARDANNOTATION } from '../modules/nf-core/rgi/cardannotation/main' 
include { RGI_MAIN } from '../modules/nf-core/rgi/main/main' 
include { PLASMIDFINDER } from '../modules/nf-core/plasmidfinder/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_metaamr_pipeline'



// Check input path parameters to see if they exist

def checkPathParamList = [ params.input, 
                           params.hostremoval_index,
                           params.hostremoval_reference,
                         ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters

if (params.input) {
    ch_input = Channel.fromPath(params.input)
                      .splitCsv(header:true, sep:',')
                      .map { row -> 
                          def meta = [id: row.sample, single_end: true]
                          def reads = file(row.fastq_1, checkIfExists: true)
                          return [meta, reads]
                      }
} else {
    error("Input samplesheet not specified")
}

// Debug: Print information about each sample
ch_input.view { meta, reads ->
    "Debug: Processing sample ${meta.id}, single_end: ${meta.single_end}, reads: ${reads}"
}



// Check if databases file is provided and create a channel
ch_databases = params.databases ? Channel.fromPath(params.databases)
    .splitCsv(header:true, sep:',')
    .map { row -> 
        def meta = [:]
        meta.tool = row.tool
        meta.db_name = row.db_name
        meta.db_params = row.db_params
        [ meta, file(row.db_path) ]
    } : Channel.empty()

// Log information about databases
if (params.databases) {
    log.info "Using provided database file: ${params.databases}"
} else {
    log.info "No database file provided. Tools will use default databases or prepare them as needed."
}




if (params.hostremoval_reference) { 
    ch_reference = file(params.hostremoval_reference) 
}
if (params.hostremoval_index) { 
    ch_reference_index = file(params.hostremoval_index) 
} else { 
    ch_reference_index = [] 
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include {READS_HOSTREMOVAL       } from '../subworkflows/local/HOSTREMOVAL'
include {META_ASSEMBLY      } from '../subworkflows/local/ASSEMBLY'
include {POLISH_ASSEMBLY    } from '../subworkflows/local/POLISH_ASSEMBLY'
include { PREPARE_TOOL_DBS } from './prepare_tool_dbs'
include { EXTRACT_RGI_DB } from   '../modules/local/EXTRACT_RGI_DB'
include { HAMRONIZATION } from '../subworkflows/local/HAMRONIZATION'
include { VALIDATE_FASTA } from '../modules/local/validate_fasta'
include { PLASCLASS } from '../modules/local/plasclass'
include { PLASCLASS_POSTPROCESS } from '../modules/local/plasclass_postprocess.nf'
include { PROFILING } from '../subworkflows/local/PROFILING'
include { SUMMARY } from '../subworkflows/local/summary'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow METAAMR {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()
   

    
    // Prepare tool-specific databases
    PREPARE_TOOL_DBS()
    

    PREPARE_TOOL_DBS.out.rgi_db.view { "Debug: RGI DB from PREPARE_TOOL_DBS: $it" }
    def ch_rgi_db_extracted = PREPARE_TOOL_DBS.out.rgi_db.branch {
        compressed: it.toString().endsWith('.tar.gz')
        ready: true
    }
  
    EXTRACT_RGI_DB(ch_rgi_db_extracted.compressed)
    def ch_rgi_db_final = ch_rgi_db_extracted.ready.mix(EXTRACT_RGI_DB.out.rgi_db).first()
    ch_rgi_db_final.view { "Debug: Final RGI DB: $it" }
    //
    // MODULE: Run FastQC
    //
    FASTQC (
        ch_samplesheet
    )
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]})
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())
    
    //
    // MODULE: Run PORECHOPS & FILTLONG
    //
    
    if (!params.skip_trim) {
        PORECHOP_PORECHOP(
            ch_samplesheet
        )
        ch_clipped_reads = PORECHOP_PORECHOP.out.reads
            .map { meta, reads -> 
                def porechopped_reads = reads.findAll { it.name.contains('porechopped') } 
                [ meta + [single_end: true], porechopped_reads ] }
            
        ch_processed_reads = FILTLONG ( ch_clipped_reads.map { meta, reads -> [ meta, [], reads ] } ).reads

        ch_versions = ch_versions.mix(PORECHOP_PORECHOP.out.versions.first())
        ch_versions = ch_versions.mix(FILTLONG.out.versions.first())
        ch_multiqc_files = ch_multiqc_files.mix( PORECHOP_PORECHOP.out.log.map{ it[1] } )
        ch_multiqc_files = ch_multiqc_files.mix( FILTLONG.out.log.map{ it[1] } )
        
    } 
    
    /*
        SUBWORKFLOW: HOST REMOVAL
    */
    if ( params.perform_hostremoval ) {
        ch_hostremoved = READS_HOSTREMOVAL(
            ch_processed_reads, 
            ch_reference,   // Reference channel passed here
            ch_reference_index             // Hostremoval index passed here
        ).reads
        ch_versions = ch_versions.mix(READS_HOSTREMOVAL.out.versions)
    } else {
        ch_hostremoved = ch_processed_reads
    }

    /*
        SUBWORKFLOW: ASSEMBLY
    */
    if ( params.perform_assembly ) {
        ch_assembly = META_ASSEMBLY(ch_hostremoved).ch_assembly   // Use Flye’s metagenomic assembly mode
        ch_versions = ch_versions.mix(META_ASSEMBLY.out.ch_versions)
    } else {
        ch_assembly = ch_hostremoved
    }
    
    /*
        SUBWORKFLOW: POLISH_ASSEMBLY
    */ 

    
    if ( params.perform_polish_assembly ) {
        POLISH_ASSEMBLY(ch_hostremoved, ch_assembly)
        ch_polished_assembly_1 = POLISH_ASSEMBLY.out.polished_assembly_1
        ch_polished_assembly_2 = POLISH_ASSEMBLY.out.polished_assembly_2
    
    // Use the second round by default, or choose based on the parameter
        ch_final_polished_assembly = params.use_second_polish ? 
    ch_polished_assembly_2 : ch_polished_assembly_1
    
        ch_versions = ch_versions.mix(POLISH_ASSEMBLY.out.versions)
    } else {
        ch_final_polished_assembly = ch_assembly
    }
    
    ch_assembly_for_arg = ch_final_polished_assembly.map { it -> it }

    
    if (params.run_resfinder) {
        log.info "Running ResFinder"

    // Prepare input channel for all cases
        ch_resfinder_input = ch_final_polished_assembly
            .map { meta, fasta -> [meta, [], fasta] } // For polished assemblies (no FASTQ)

        ch_resfinder_input
            .combine(PREPARE_TOOL_DBS.out.resfinder_db)
            .map { meta, fastq, fasta, db -> [ meta, fastq, fasta, db ] }
            .view { meta, fastq, fasta, db -> 
                "Debug: ResFinder input - Sample: ${meta.id}, FASTQ: ${fastq}, FASTA: ${fasta}, DB: ${db}"
            }
            .set { ch_resfinder_combined_input }

        RESFINDER_RUN(
            ch_resfinder_combined_input
        )
    
    // Mix versions and outputs into global channels
        ch_versions = ch_versions.mix(RESFINDER_RUN.out.versions.first())
    
        
        RESFINDER_RUN.out.all_outputs.view { meta, files -> 
            "ResFinder outputs for ${meta.id}: ${files.collect { it.getName() }.join(', ')}"
        }
    }
    // Outside the if block, ensure ch_resfinder is a valid channel even if ResFinder wasn't run
    
    if (params.run_abricate) {
      
        log.info "Running Abricate"

        ch_abricate_input = ch_final_polished_assembly
        
        ABRICATE_RUN(
            ch_abricate_input,
            params.arg_abricate_db
        )
    
        ch_versions = ch_versions.mix(ABRICATE_RUN.out.versions)
        ABRICATE_RUN.out.report.view { meta, report -> 
            "Abricate outputs for ${meta.id}: ${report.getName()}"
        }
    }
    
    if (params.run_amrfinderplus) {
        
        log.info "Running AMRFinderPlus"

        ch_amrfinderplus_input = ch_final_polished_assembly
        ch_amrfinderplus_input.combine(PREPARE_TOOL_DBS.out.amrfinderplus_db).view { meta, assembly, db ->
            "Debug: AMRFinderPlus input - Sample: ${meta.id}, Assembly: ${assembly}, DB: ${db}"
        }

        AMRFINDERPLUS_RUN(
            ch_amrfinderplus_input,
            PREPARE_TOOL_DBS.out.amrfinderplus_db,
            
        )

        ch_versions = ch_versions.mix(AMRFINDERPLUS_RUN.out.versions)
        AMRFINDERPLUS_RUN.out.report.view { meta, report -> 
            "AMRFinderPlus outputs for ${meta.id}: ${report.getName()}"
        }
        ch_multiqc_files = ch_multiqc_files.mix(AMRFINDERPLUS_RUN.out.report.collect{it[1]}.ifEmpty([]))
    }


    if (params.run_rgi) {
        
        log.info "Running RGI"

        ch_rgi_input = ch_final_polished_assembly
            .map { meta, assembly -> [ meta, assembly ] }
            .view { meta, assembly -> "Debug: Sample ready for RGI: ${meta.id}" }

        ch_rgi_input
            .combine(ch_rgi_db_final)
            .map { meta, assembly, db -> [ meta, assembly, db ] }  // Ensure correct structure
            .view { meta, assembly, db -> 
                "Debug: Combined input for RGI - Sample: ${meta.id}, Assembly: ${assembly}, DB: ${db}"
            }
            .set { ch_rgi_combined_input }

        RGI_MAIN(
            ch_rgi_combined_input,
            []  // Wildcard input, set to empty if not using
        )

        ch_versions = ch_versions.mix(RGI_MAIN.out.versions)
    
        RGI_MAIN.out.tsv
            .view { meta, tsv -> "RGI outputs for ${meta.id}: ${tsv.getName()}" }
            .ifEmpty { log.warn "No output from RGI_MAIN process" }

        ch_multiqc_files = ch_multiqc_files.mix(
            RGI_MAIN.out.tsv
                .map { meta, tsv -> tsv }
                .collect()
                .ifEmpty([])
        )
    }    
    VALIDATE_FASTA(ch_final_polished_assembly)
    ch_validated_assemblies = VALIDATE_FASTA.out.validated_fasta

    if (params.run_plasmidfinder) {
        
        log.info "Running PlasmidFinder"

   // Combine validated assemblies with PlasmidFinder database
        ch_plasmidfinder_input = VALIDATE_FASTA.out.validated_fasta.combine(PREPARE_TOOL_DBS.out.plasmidfinder_db)

        // Run PlasmidFinder
        PLASMIDFINDER (
            VALIDATE_FASTA.out.validated_fasta,
            PREPARE_TOOL_DBS.out.plasmidfinder_db
        )

        // Collect versions
        ch_versions = ch_versions.mix(PLASMIDFINDER.out.versions)

        // Add PlasmidFinder results to MultiQC if required
        ch_multiqc_files = ch_multiqc_files.mix(
            PLASMIDFINDER.out.tsv.collect { it[1] }.ifEmpty([])
        )
    }
        
    // Run plasclass
   /* if (params.run_plasclass) {
        log.info "Running PlasClass"

        ch_plasclass_input = ch_final_polished_assembly

        ch_plasclass_input.view { meta, assembly ->
            "Debug: PlasClass input - Sample: ${meta.id}, Assembly: ${assembly}"
        }

        PLASCLASS(VALIDATE_FASTA.out.validated_fasta)

        ch_versions = ch_versions.mix(PLASCLASS.out.versions)
        PLASCLASS.out.report.view { meta, report -> 
                "PlasClass outputs for ${meta.id}: ${report.getName()}"
            }
        ch_multiqc_files = ch_multiqc_files.mix(PLASCLASS.out.report.collect{it[1]}.ifEmpty([]))
    


    // Debug MultiQC input files after adding PlasmidFinder results
        ch_multiqc_files.view { "Debug: MultiQC input files after adding PlasmidFinder - $it" }

    }
*/
    // Run PlasClass
    if (params.run_plasclass) {
        
        log.info "Running PlasClass"

    // Step 1: Run PlasClass
        PLASCLASS(VALIDATE_FASTA.out.validated_fasta)

    // Step 2: Post-process PlasClass outputs
        PLASCLASS_POSTPROCESS(PLASCLASS.out.report)

    // Combine versions for tracking
        ch_versions = ch_versions.mix(PLASCLASS.out.versions)
        ch_versions = ch_versions.mix(PLASCLASS_POSTPROCESS.out.versions)

    // Step 3: Collect results for MultiQC (optional)
        ch_multiqc_files = ch_multiqc_files.mix(PLASCLASS_POSTPROCESS.out.classified.collect { it[1] }.ifEmpty([]))
    }
    

        
     // Collect results from AMR tools
    ch_abricate_results = params.run_abricate ? ABRICATE_RUN.out.report : Channel.empty()
    ch_amrfinderplus_results = params.run_amrfinderplus ? AMRFINDERPLUS_RUN.out.report : Channel.empty()
    ch_rgi_results = params.run_rgi ? RGI_MAIN.out.tsv : Channel.empty()


     // Count the number of active AMR tools
    def active_amr_tools = [params.run_abricate, params.run_amrfinderplus, params.run_rgi].count { it }
    // Run HAMRONIZATION only if more than one AMR tool is active and run_hamronization is true
    if (params.run_hamronization && active_amr_tools > 1) {
        HAMRONIZATION (
            ch_abricate_results,
            ch_amrfinderplus_results,
            ch_rgi_results
        )
        ch_versions = ch_versions.mix(HAMRONIZATION.out.versions.ifEmpty([]))
        ch_multiqc_files = ch_multiqc_files.mix(HAMRONIZATION.out.summary.collect{it[1]}.ifEmpty([]))
    } else {
        log.info "Skipping HAMRONIZATION: Either fewer than two AMR tools are active or run_hamronization is set to false."
    }
    
    if (params.run_profiling) {
    ch_profiling_input = ch_final_polished_assembly.map { meta, assembly -> 
        [meta, [assembly]]  // Always pass assembly as a list, set fasta to null
      
    }
    ch_profiling_input.view { "Profiling input: $it" }
    // Ensure databases_ch is created correctly
    databases_ch = Channel.fromPath(params.databases)
        .splitCsv(header: true, sep: ',')
        .map { row ->
            def db_meta = [:]
            db_meta.tool = row.tool
            db_meta.db_name = row.db_name
            db_meta.db_params = row.db_params
            [db_meta, file(row.db_path)]
        }

    // Calling the PROFILING subworkflow correctly
    PROFILING(
        ch_profiling_input,
        databases_ch
    )

    ch_versions = ch_versions.mix(PROFILING.out.versions)
    ch_multiqc_files = ch_multiqc_files.mix(PROFILING.out.raw_profiles.collect { it[1] }.ifEmpty([]))


}
    
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_'  + 'pipeline_software_' +  'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }
    
    
    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    
    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )
    if (params.perform_hostremoval) {
        ch_multiqc_files = ch_multiqc_files.mix(READS_HOSTREMOVAL.out.mqc.collect{it[1]}.ifEmpty([]))
    }

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions.ifEmpty(null)               // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/