process SUMMARY_REPORT {
    tag "${meta.id}"
    label 'process_medium'

    input:
    tuple val(meta), path(abricate), path(amrfinder), path(resfinder), path(rgi), path(plasmidfinder), path(plasclass), path(kaiju), path(centrifuge)

    output:
    path "${meta.id}_summary_report.tsv", emit: summary_report
    path "versions.yml", emit: versions

    script:
    """
    echo -e "SampleID\tAMR_Genes\tPlasmid_Finder\tPlasClass\tKaiju\tCentrifuge" > ${meta.id}_summary_report.tsv

    # Sample ID
    echo -n "${meta.id}\t" >> ${meta.id}_summary_report.tsv

    # Deduplicated AMR Genes
    if [ -f "${abricate}" ] || [ -f "${amrfinder}" ] || [ -f "${resfinder}" ] || [ -f "${rgi}" ]; then
        (
            [ -f "${abricate}" ] && awk '{if (NR > 1) print \$6}' ${abricate}
            [ -f "${amrfinder}" ] && awk '{if (NR > 1) print \$6}' ${amrfinder}
            [ -f "${resfinder}" ] && awk '{if (NR > 1) print \$1}' ${resfinder}
            [ -f "${rgi}" ] && jq -r '.["AMR_genes"][] | .gene_name' ${rgi}
        ) | sort | uniq | tr '\\n' ',' | sed 's/,\$//' >> ${meta.id}_summary_report.tsv
    else
        echo -n "No AMR Detected" >> ${meta.id}_summary_report.tsv
    fi
    echo -n "\t" >> ${meta.id}_summary_report.tsv

    # Plasmid Finder Results
    if [ -f "${plasmidfinder}" ]; then
        awk '{if (NR > 1) print \$2}' ${plasmidfinder} | sort | uniq | tr '\\n' ',' | sed 's/,\$//' >> ${meta.id}_summary_report.tsv
    else
        echo -n "No Plasmid Detected" >> ${meta.id}_summary_report.tsv
    fi
    echo -n "\t" >> ${meta.id}_summary_report.tsv

    # PlasClass Results
    if [ -f "${plasclass}" ]; then
        awk '{print \$1}' ${plasclass} | sort | uniq | tr '\\n' ',' | sed 's/,\$//' >> ${meta.id}_summary_report.tsv
    else
        echo -n "No PlasClass Detected" >> ${meta.id}_summary_report.tsv
    fi
    echo -n "\t" >> ${meta.id}_summary_report.tsv

    # Kaiju Results
    if [ -f "${kaiju}" ]; then
        awk '{print \$2}' ${kaiju} | sort | uniq | tr '\\n' ',' | sed 's/,\$//' >> ${meta.id}_summary_report.tsv
    else
        echo -n "No Kaiju Detected" >> ${meta.id}_summary_report.tsv
    fi
    echo -n "\t" >> ${meta.id}_summary_report.tsv

    # Centrifuge Results
    if [ -f "${centrifuge}" ]; then
        awk '{if (NR > 1) print \$2}' ${centrifuge} | sort | uniq | tr '\\n' ',' | sed 's/,\$//' >> ${meta.id}_summary_report.tsv
    else
        echo -n "No Centrifuge Detected" >> ${meta.id}_summary_report.tsv
    fi
    echo "" >> ${meta.id}_summary_report.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        summary_report_script: "version 1.0"
    END_VERSIONS
    """
}