nextflow.enable.dsl = 2

params.accession="M21012"
params.out = "${launchDir}/output"
params.storeDir="${launchDir}/cache"

process downloadAccession {
	storeDir params.storeDir
	input:
		val accession
	output:
		path "${params.accession}.fasta"
	"""
	wget "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=${params.accession}&rettype=fasta&retmode=text" -O ${params.accession}.fasta
	"""
}

process downloadCombined {
	storeDir params.storeDir
	output:
		path "${params.accession}_combined.fasta"
	"""
	wget https://gitlab.com/dabrowskiw/cq-examples/-/raw/master/data/hepatitis_combined.fasta?inline=false -O ${params.accession}_combined.fasta
	"""
}

process combineFasta {
	publishDir params.out, mode: "copy", overwrite: true
	input:
		path "*.fasta"
	output:
		path "${params.accession}_final.fasta"
	"""
	cat *.fasta > ${params.accession}_final.fasta
	"""
}

process mafft {
	publishDir params.out, mode: "copy", overwrite: true
	container "https://depot.galaxyproject.org/singularity/mafft%3A7.525--h031d066_1"
	input:
		path infile
	output:
		path "${params.accession}_alignment.fasta"
	"""
	mafft-linsi $infile >  ${params.accession}_alignment.fasta
	"""
}

process trimAL {
	publishDir params.out, mode: "copy", overwrite: true
	container "https://depot.galaxyproject.org/singularity/trimal%3A1.5.0--h4ac6f70_1"
	input:
		path infile
	output:
		path "${infile}*"
	"""
	trimal -in $infile -out ${infile}.trimmed.fasta -htmlout ${infile}_report.html -automated1 
	"""
}



workflow {
	//downloadAccession(Channel.from(params.accession)) | downloadCombined | combineFasta
	download_channel = downloadAccession(Channel.from(params.accession)) 
	download_combined = downloadCombined()
	combining_channel = download_channel.combine(download_combined)
	making_Fasta = combineFasta(combining_channel)
	alignment_channel = mafft(making_Fasta)
	trimal_channel = trimAL(alignment_channel)
}