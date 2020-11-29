require 'rest-client' # allows retrieving a webpage content
require 'bio' # imports bio-ruby
require 'enumerator' # allows getting the position of a match from a string. Retrieved from https://stackoverflow.com/questions/5241653/ruby-regex-match-and-get-positions-of

def fetch(url, headers = {accept: "*/*"}, user = "", pass="") # got from course notes. It consists of a secure form of getting webpage content.
  response = RestClient::Request.execute({
    method: :get,
    url: url.to_s,
    user: user,
    password: pass,
    headers: headers})
  return response
  
  rescue RestClient::ExceptionWithResponse => e
    $stderr.puts e.inspect
    response = false
    return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
  rescue RestClient::Exception => e
    $stderr.puts e.inspect
    response = false
    return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
  rescue Exception => e
    $stderr.puts e.inspect
    response = false
    return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
end

target="CTTCTT" # string representing the nucleotide match we are searching for in the given gene sequences.
search = Bio::Sequence::NA.new(target) # transforms the latter string target into a bio-ruby object
re_search= /(?=(#{search.to_s}))/ # transforms the former target DNA sequence into a regular expression, so later it can be used as a variable along with the method match.
gff="##gff-version 3\n" # This variable will contain all the information that the gff3 file without expressing the chromosome coordinates will have.
ft = "" # This variable represents the content of an optional file, which will have the information from all the created features for each entry with the position of the nucleotide
# repeat.
fasta1 = "" # will have all the fasta gene sequences (including the introns).
genes_with_no_repeat = "List of genes that do not have a CTTCTT repeat:\n" # will contain the name of all those genes for which the CTTCTT repeat wasn't found in their sequence.
gff2 = "##gff-version 3\n" # represents the gff3 file with the chromosome coordinates.

file = "" # Empty variable for having the ArabidopsisSubNetwork_GeneList.txt information.
File.open("ArabidopsisSubNetwork_GeneList.txt", "r") do |f| # will record each line from ArabidopsisSubNetwork_GeneList.txt into the empty variable "file".
  f.each_line do |line|
    file = file + line
  end
end
at_list=file.scan(/[Aa][Tt][1-5][Gg][0-9]{5}/) # transforms all the gene names from ArabidopsisSubNetwork_GeneList.txt into a list of gene names.

puts "This program takes a couple of minutes to create five different files:\n- ARA_DNA.fasta contains the sequence of all the 167 genes from the file ArabidopsisSubNetwork_GeneList.txt in fasta format (introns are included).\n- gff_genes_id.gff3 contains information about the CTTCTT repeats found in the genes sequences using the fasta gene sequence coordinates.\n- gff_chr_id.gff3 contains the same information as the previous file but in this file chromosome coordinates are given instead.\n- repeat_features.txt contains all the repeat features created.\n- genes_with_no_repeat.txt is a list of the genes that have no CTTCTT repeat in their sequence."

for at in at_list
  web="http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id="+at # specific ENSEMBL gene URL
  res=fetch(web) # fetches ENSEMBL gene URL content
  if res
    gff_list=[] # This empty list will contain every kind of report line included into the first gff3 file once and for each gene. It was created so the gff3 file doesn't repeat some
    # lines since iterations over exons can create the same information line multiple times in the file due to alternative splicing.
    gff2_list=[] # This empty list has the same purpose as the latter, but it refers to the information for the second gff3 file.
    raw_positions=[] # This varaible will contain all the positions for all the exons for a single gene.
    is_there_match=false # If this variable stays with this value for the rest of the analysis for a single gene, the gene will be included in the file that will have all those
    # genes that don't contain the CTTCTT repeat in their sequence, at least according to this script. It is possible that I left multiple exons without being analyzed, and that's
    # because coordinates are not given in the same numerical format for each exon feature. This will be discussed in more detail below (see line 75).
    body=res.body # body of the webpage.
    entry = Bio::EMBL.new(body) # defines the content from the ENSEMBL webpage as a bio-ruby object.
    fasta1 = fasta1 + ">#{at}\n#{entry.naseq}\n" # The first line of a fasta entry is included into the fasta report string.
    bioseq = entry.to_biosequence  # this is how you convert a database entry to a Bio::Sequence
    len=entry.naseq.length # entry sequence length is registered. Entry sequence length is useful when calculating some position coordinates. The coordinates calculation would have
    # been less troublesome if I had followed another approach when elaborating this script. Reverse complement coordinates could have been retrieved by using the target sequence
    # "aagaag", but I'll use the reverse complement of the entire entry sequence instead, which is computationally more time-expensive.
    chr_number=entry.accession.match(/:(\d+):\d+:\d+:\d+/)[1].to_s # Chromosome number is not retrieved from the gene name, but from the accession entry code.
    chr_coordinates=entry.accession.match(/:\d+:(\d+:\d+):\d+/)[1].to_s # Chromosome coordinates are retrieved from the accession entry code.
    chr_coordinates=chr_coordinates.scan(/\d+/) # first coordinates that appear on the Bio::EMBL object
    l=0 # The optional file with the information with the created features will include a paragraph which will separate each gene features from the other thanks to this variable.
    # It is part of a conditional so after it is greater than 1, that part of the code won't be executed again, so it is only run once for every gene.
    for feature in entry.features # every feature in the entry
      if (/exon_id=/).match(feature.assoc["note"]).to_s=="exon_id=" # If a feature has a note that says "exon_id", it'll be consider an entry sequence exon.
        raw_position=(feature.position).match(/\d+\.\.\d+/).to_s # Position is retrieved from this feature. Here, I'm not considering if this position is located in the reverse
        # complement strand, and that's because the position will be used to get both the original sequence and its complementary.
        parts=raw_position.scan(/\d+/) # Position numbers are retrieved. This was scripted since there are exon features that have positions that contain numbers that don't match
        # numbers ranged from 1 to the entry sequence length, or ranging between the chromosome coordinates. This means they are notated using another scale. They could relatively
        # be indicating exons, but those weren't considered with this program due to problems associated with translating that scale into another.
        if raw_positions.include?(raw_position) or parts[1].to_i > entry.naseq.length # The fisrt part of the conditional, if exon positions are repeated, they will not be included
          # multiple times as part of all the positions that will be analyzed as part of the entry sequence. This part could be useless or redundant considering following code lines
          # The second part of the conditional filters positions considering the numerical value: if those numbers are greater than the entry sequence length, those positions
          # won't be considered in the analyses.
        else
          raw_positions << raw_position
        end
      end
    end
    for pos in raw_positions
      exon_pos_forward=[] # accumulates exon indices which will be used for calculating the sequences or chromosomes start coordinates for the CTTCTT repeat in the forward strand.
      exon_pos_reverse=[] # accumulates exon indices which will be used for calculating the sequences or chromosomes start coordinates for the CTTCTT repeat in the reverse strand.
      exon=entry.naseq.splice("#{pos}") # Position from positions list is transformed into the forward exon strand.
      complement_exon=exon.reverse_complement # Position from positions list is transformed into the reverse exon strand.
      exons_start_and_end=pos.scan(/\d+/) # Each value from the position variable is separated into two different numbers.
      pos_of_targets = exon.to_s.enum_for(:scan, re_search).map { Regexp.last_match.begin(0) } # Using 'enumerator' gem, CTTCTT repeat start coordinates are calculated in the
      # forward exon strand. Note that this code line allows retrieving overlapping substrings (CTTCTT target can be overlapped).
      if pos_of_targets.length()!=0 # This piece of code won't be executed if there are no coordinates calculated through the last code line.
        for number in pos_of_targets
          start=number+exons_start_and_end[0].to_i # Coordinates are calculated in terms of the entry sequence scale, ranging from 1 to entry sequence length in the forward exon
          # strand.
          exon_pos_forward << start
        end
      end
      pos_of_targets = complement_exon.to_s.enum_for(:scan, re_search).map { Regexp.last_match.begin(0) } # Using 'enumerator' gem, CTTCTT repeat start coordinates are calculated in
      # the reverse exon strand. 
      if pos_of_targets.length()!=0 # This piece of code won't be executed if there are no coordinates calculated through the last code line.
        for number in pos_of_targets
          start=len-exons_start_and_end[1].to_i+number+1 # Coordinates are calculated in terms of the entry sequence scale, ranging from 1 to entry sequence length in the reverse
          # exon strand.
          exon_pos_reverse << start
        end
      end
      if exon_pos_forward.length()!=0 or exon_pos_reverse.length()!=0 and l<1 # Only if some CTTCTT repeat has matched some part of the given exon, a new entry in the optional repeat
        # features file will be included and only once, since this conditional is implemented in a loop for every position of each exon.
        ft=ft+"Accession code: #{entry.accession}\nGene ID: #{at}\n\n"
        l=l+1
      end
      if exon_pos_forward.length()!=0 # If some CTTCTT repeat has been found in the forward exon strand, this code will be executed.
        for number in exon_pos_forward # For every CTTCTT start coordinate in an exon
          if gff_list.include?("#{at}\t.\texpressed_sequence_match\t#{number}\t#{(number.to_i+search.length-1).to_s}\t.\t+\t.\tName=#{search.to_s}\n") # Since alternative splicing
            # could generate exons with the same sequence parts, this conditional implies that only unique information will form part of the written files, and it won't appear
            # repeated.
          else
            gff_list << "#{at}\t.\texpressed_sequence_match\t#{number}\t#{(number.to_i+search.length-1).to_s}\t.\t+\t.\tName=#{search.to_s}\n"
            # If the information is included in this list, it won't appear repeated in the written files; "end of the repeat" = "start of the repeat" + "length of it" - 1
            gff=gff+"#{at}\t.\texpressed_sequence_match\t#{number}\t#{(number.to_i+search.length-1).to_s}\t.\t+\t.\tName=#{search.to_s}\n"
            # The first gff3 file information is updated
            f1 = Bio::Feature.new('myrepeat', "#{number}..#{(number.to_i+search.length-1).to_s}") # A CTTCTT feature is created. Features will be created and but they won't be read
            # so the gff3 files can be created through these features, which could imply a different approach from the specified for this assignment.
            f1.append(Bio::Feature::Qualifier.new('repeat_motif', target)) # Feature characteristics are included.
            f1.append(Bio::Feature::Qualifier.new('strand', '+'))
            bioseq.features << f1
            ft=ft+"FEATURE: #{f1.feature.to_s}; @POSITION = #{f1.position.to_s}\nAssociations = #{f1.assoc.to_s}\n" # The feature is written in the optional features file.
          end
          if gff2_list.include?("Chr#{chr_number}\t.\texpressed_sequence_match\t#{(number.to_i+chr_coordinates[0].to_i-1).to_s}\t#{(number.to_i+search.length-1+chr_coordinates[0].to_i-1).to_s}\t.\t+\t.\tName=#{search.to_s}\n")
          else
            gff2_list << "Chr#{chr_number}\t.\texpressed_sequence_match\t#{(number.to_i+chr_coordinates[0].to_i-1).to_s}\t#{(number.to_i+search.length-1+chr_coordinates[0].to_i-1).to_s}\t.\t+\t.\tName=#{search.to_s}\n"
            # Features are included in the gff3 file representing chromosome coordiantes.
            gff2=gff2+"Chr#{chr_number}\t.\texpressed_sequence_match\t#{(number.to_i+chr_coordinates[0].to_i-1).to_s}\t#{(number.to_i+search.length-1+chr_coordinates[0].to_i-1).to_s}\t.\t+\t.\tName=#{search.to_s}\n"
          end
        end
        is_there_match=true # If any match was detected, this variable won't make the given gene name be included in the list that doesn't have the CTTCTT repeat.
      end
      if exon_pos_reverse.length()!=0
        for number in exon_pos_reverse
          if gff_list.include?("#{at}\t.\texpressed_sequence_match\t#{((entry.naseq.length)-(number.to_i+search.length-1)+1).to_s}\t#{((entry.naseq.length)-(number.to_i+search.length-1)+search.length).to_s}\t.\t-\t.\tName=#{search.to_s}\n")
            # Here, positions for reverse strand are calculated. As it is indicated before, it would have been easier to calculate if "aagaag" repeat had been used. Since the
            # entry sequence reverse strand is what is being used, a more complex mathematical conversion is used so coordinates adequate the ENSEMBL position format. This script
            # has been written considering those rules [positions are given in terms of the forward strand always, and gff3 files consider those positions even when indicating they
            # are located in the reverse strand (-)].
            # The same approach is repeated here; "start position in the reverse strand in terms of the entry sequence coordinates" = "Entry sequence length" - "End of the CTTCTT match in the reverse exon strand" + 1
          else
            gff_list << "#{at}\t.\texpressed_sequence_match\t#{((entry.naseq.length)-(number.to_i+search.length-1)+1).to_s}\t#{((entry.naseq.length)-(number.to_i+search.length-1)+search.length).to_s}\t.\t-\t.\tName=#{search.to_s}\n"
            # The same approach is applied here. Mathematical conversion explained before is used here. If chromosome coordinates have to be calculated, chromosome start coordinate
            # will be summed in each case.
            gff=gff+"#{at}\t.\texpressed_sequence_match\t#{((entry.naseq.length)-(number.to_i+search.length-1)+1).to_s}\t#{((entry.naseq.length)-(number.to_i+search.length-1)+search.length).to_s}\t.\t-\t.\tName=#{search.to_s}\n"
            f2 = Bio::Feature.new("myrepeat","complement(#{((entry.naseq.length)-(number.to_i+search.length-1)+1).to_s}..#{((entry.naseq.length)-(number.to_i+search.length-1)+search.length).to_s})")
            f2.append(Bio::Feature::Qualifier.new('repeat_motif', target))
            f2.append(Bio::Feature::Qualifier.new('strand', '-'))
            bioseq.features << f2
            ft=ft+"FEATURE: #{f2.feature.to_s}; @POSITION = #{f2.position.to_s}\nAssociations = #{f2.assoc.to_s}\n"
          end
          if gff2_list.include?("Chr#{chr_number}\t.\texpressed_sequence_match\t#{((entry.naseq.length)-(number.to_i+search.length-1)+1+(+chr_coordinates[0].to_i-1)).to_s}\t#{((entry.naseq.length)-(number.to_i+search.length-1)+search.length+(+chr_coordinates[0].to_i-1)).to_s}\t.\t-\t.\tName=#{search.to_s}\n")
          else
            gff2_list << "Chr#{chr_number}\t.\texpressed_sequence_match\t#{((entry.naseq.length)-(number.to_i+search.length-1)+1+(+chr_coordinates[0].to_i-1)).to_s}\t#{((entry.naseq.length)-(number.to_i+search.length-1)+search.length+(+chr_coordinates[0].to_i-1)).to_s}\t.\t-\t.\tName=#{search.to_s}\n"
            gff2=gff2+"Chr#{chr_number}\t.\texpressed_sequence_match\t#{((entry.naseq.length)-(number.to_i+search.length-1)+1+(+chr_coordinates[0].to_i-1)).to_s}\t#{((entry.naseq.length)-(number.to_i+search.length-1)+search.length+(+chr_coordinates[0].to_i-1)).to_s}\t.\t-\t.\tName=#{search.to_s}\n"
          end
        end
        is_there_match=true
      end
    end
    if is_there_match==true # This conditional will control if a gene name is included in the list of genes that don't have the CTTCTT repeat.
      ft=ft+"\n"
    else
      genes_with_no_repeat=genes_with_no_repeat+"#{at}\n"
    end
  end
end

File.write("ARA_DNA.fasta", fasta1) # All files are written.
File.write("gff_genes_id.gff3", gff)
File.write("gff_chr_id.gff3", gff2)
File.write("repeat_features.txt", ft)
File.write("gene_with_no_repeat.txt", genes_with_no_repeat)

puts "All files where created."