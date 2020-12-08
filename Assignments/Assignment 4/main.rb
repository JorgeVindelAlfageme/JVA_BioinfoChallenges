# Before starting, I created a directory called "Databases" and use blast+ to build the databases files so alignments
# can be performed. I used the next command lines at the terminal:

# mkdir Databases
# makeblastdb -in S_pombe_pep.fa -dbtype prot -out ./Databases/S_pombe_pep # argument "prot" has been used since S_pombe_pep.fa contains peptidic sequences.
# makeblastdb -in ARA_genes.fa -dbtype nucl -out ./Databases/ARA_genes # argument "nucl" has been used since ARA_genes.fa contains nucleotidic sequences.

require "bio"

puts "Program running. This program takes about 4 hours and 20 minutes to generate a file containing the orthologs, considering the two given fasta files."

aThalianaFactory = Bio::Blast.local("tblastn", "./Databases/ARA_genes") # if a nucleotide and peptidic sequences are
# going to be aligned, when creating the nucleotide sequence factory, "tblastn" argument has to be used.
sPombeFasta = Bio::FastaFormat.open("./S_pombe_pep.fa") # retrieves the information from the peptidic sequences fasta
# file, so entries and their sequences can be iterated.
evalue = 10e-10 # The e-value was the only BLAST parameter to be scripted. The rest of the parameters correspond to their
# predetermined value. E-values have to be chosen considering the length of the queried sequence, the size of the
# database, and the given alignment p-value. When searching for ortholog genes, it's important to determine what kind
# of e-value, or p-value, will indicate orthology was found. The e-value was decided based on what is indicated at:
# https://www.biostars.org/p/116338/

list_tblastn=[] # will contain the pairs of gene names which sequences aligned.
only_at=[] # will only contain the A. thaliana gene names which sequences aligned with the S. pombe peptidic sequences.

for entry in sPombeFasta
  sublist=[] # will contain the pair of gene names which sequence aligned. It gets empty after each iteration.
  a=0 # This counter will be used so only the gene name from the best match from an alignment is retrieved.
  sp_id = entry.entry_id # S. pombe gene name from the fasta file is retrieved.
  report = aThalianaFactory.query(">#{sp_id}\n#{entry.seq}") # Gene sequence and name is used for a query.
  for instance in report
    if instance.evalue <= evalue and a==0 # Only if the alignment match meet the requirements, its information will be
      # retrieved.
      at = instance.target_def.split(" | ")[0] # Every accession line can be splitted this way, so the gene name occupies
      # the first position of the array that consitutes the splitted line. This had to be done since not all A. thaliana
      # gene names match the next regular expression: /[Aa][Tt][1-5][Gg][0-9]{5}\.[0-9]/
      only_at << at # The A. thaliana gene name which sequence matched the S. pombe sequence and met the requisites is
      # stored at this variable.
      sublist << at # Now the same gene name is stored in the sublist...
      sublist << sp_id # as well as the S. pombe gene name...
      list_tblastn << sublist # The sublist will be introduced into the list which will have all the paired gene names.
      # The order in which gene names are introduced is relevant, since in the next part of the code, orthologs will be
      # considered only if one element of the main list corresponds to the result of the reciprocal alignment.
      a = a+1
    end
  end
end

sPombeFactory = Bio::Blast.local("blastx", "./Databases/S_pombe_pep") # if a nucleotide and peptidic sequences are
# going to be aligned, when creating the peptidic sequence factory, "blastx" argument has to be used.
aThalianaFasta = Bio::FastaFormat.open("./ARA_genes.fa") # retrieves the information from the nucleotide sequences fasta
# file, so entries and their sequences can be iterated.

str = "List of orthologs discovered by a 'reciprocal best BLAST':\n\n" # This string will constitute the content
# of the output file.

for entry in aThalianaFasta
  sublist=[] # will contain the pair of gene names which sequence aligned. It gets empty after each iteration.
  a=0 # This counter will be used so only the gene name from the best match from an alignment is retrieved.
  at_id = entry.entry_id # A. thaliana gene name from the fasta file is retrieved.
  if only_at.include?(at_id) # The next part of the code will only be considered if the gene name is already in the list
    # containig the A. thaliana gene names from the first alignment process, so the code runs faster.
    sublist << at_id # First, the A. thaliana gene name is introduced in the variable "sublist"
    report = sPombeFactory.query(">#{at_id}\n#{entry.seq}") # executes the reciprocal query.
    for instance in report
      if instance.evalue <= evalue and a==0 # If blast query requisites are met...
        sp_id = instance.target_def.split("|")[0] # The S. pombe gene name will be retrieved from the entry with the
        # matched sequence. In this case, the way accession lines are splitted is different than the last time, since
        # the terms in this case are just joined by "|", and not by " | ".
        sublist << sp_id # The S. pombe gene name is introduced in the variable "sublist".
        a=a+1
      end
    end
    if list_tblastn.include?(sublist) # If the variable "sublist" is already included in the list "list_tblastn", then
      # it's a reciprocal hit.
      str = str + sublist[0] + "\t\t" + sublist[1] + "\n" # The gene names of this reciprocal hit are stored in a string.
    end
  end
end

File.write("orthologs.txt", str) # The string "str" content is recorded into a txt file.

# Bonus:
# After getting the reciprocal best hits and the gene names:
# - A phylogenetic analysis could be performed, so it can confirm if both gene have the same origin.
# - Both gene sequences could be analyzed, so if they share multiple common domains and they have the same function,
# the most probable thing is that they both have the same function, and orthologs are known to share the same function.