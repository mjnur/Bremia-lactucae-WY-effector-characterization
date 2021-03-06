#!/bin/bash

#usage: ./runPONDR.sh <input proteins fasta file> <your desired output path>
#input proteins must be single line fasta format! (see 0Commands.sh to convert)

#loop through $input_proteins, get each gene (without fasta header)
#send each gene to PONDR, append results to $output_results
#
#PONDR only runs 1 AA seq at a time,
#    PONDR doesn't allow any  special chars (*) or fasta headers
usage(){
	echo "Usage: bash run_pondr.sh <input fasta file> <output text file>"
	exit 1
}

[[ $# -ne 2 ]] && usage


input_proteins="$1"
output_results="$2"

awk '!/^>/ { printf "%s", $0; n = "\n" } /^>/ { print n $0;n = "" } END { printf "%s", n }' $input_proteins > ${input_proteins}_formatted
sed -iE 's/*//g' ${input_proteins}_formatted

num_proteins=$(grep -c ">" $input_proteins)


rm -f -- $output_results 

for (( gene=1; gene <= num_proteins; ((gene++)) ))
do
    echo -e "processing gene: $gene of $num_proteins"

    #gene n will be at file_pos 2n (fasta file is a single line fasta file format)
    gene_file_pos=$(( 2 * $gene ))

    #put gene in temp file
    sed -n -e ${gene_file_pos}p ${input_proteins}_formatted > tempGene

    #run PONDR, get raw results in tempResults
    java -jar VSL2.jar -s:tempGene > tempResults

    #remove unnecessary headers in PONDR results and delete last line
    sed -n -iE '/------/,$p' tempResults && sed -iE '$d' tempResults

    #append to user output file, for easy processing in R (comment char = '-')
    cat tempResults >> $output_results

done

rm tempGene*
rm tempResults*
rm ${input_proteins}_formattedE
