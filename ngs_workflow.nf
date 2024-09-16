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

process downloadGenomes {
	storeDir params.storeDir
	output:
		path "genomes.fasta"
	"""
	wget https://gitlab.com/dabrowskiw/cq-examples/-/raw/master/data/hepatitis_combined.fasta?inline=false -O genomes.fasta
	"""
}

process combineFasta {
	input:
		path file
	output:
		path "${params.accession}_combined.fasta"
	"""
	cat *.fasta > ${params.accession}_combined.fasta
	"""
}

process mafft {
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
	download_channel = downloadAccession(Channel.from(params.accession)) 
	download_genome_channel = downloadGenomes()
	combining_channel = download_channel.concat(download_genome_channel).collect()
	making_Fasta = combineFasta(combining_channel)
	alignment_channel = mafft(making_Fasta)
	trimal_channel = trimAL(alignment_channel)
}