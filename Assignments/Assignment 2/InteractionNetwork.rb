require 'rest-client'

def fetch(url, headers = {accept: "*/*"}, user = "", pass="") # is the way we access to web pages content and a piece of code extracted from the course.
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

class Interaction_Network
  
  attr_accessor :file # contains the list of genes from a file enumerating them.
  attr_accessor :raw_Interaction_Networks # it was supposed that this variable would contain all gene interactions from a single gene as a sublist.
  attr_accessor :Interaction_Networks # it was supposed that this variable would contain the refine interaction network considering only the genes in @file.
  
  def initialize (params={})
    
    @file=params.fetch(:file, "")
    @raw_Interaction_Networks=params.fetch(:raw_Interaction_Networks, [])
    @Interaction_Networks=params.fetch(:Interaction_Networks, [])
    
  end
  
  def read_file(file_name) # reads a file and extracts the information as a string. After that, Arabidopis thaliana genes are got through the scan method using a
    # regular expression representing any of those genes.
    file = ""
    File.open(file_name, "r") do |f|
      f.each_line do |line|
        file = file + line
      end
    end
    list_of_codes=file.scan(/[Aa][Tt][1-5][Gg][0-9]{5}/)
    @file = list_of_codes
  end
  
  def format_file(original_substring, new_substring) # This function was created in order to make sure that all the genes from a file adopt the pertinent loci nomenclature
    # on UniProt. It wasn't used in the end.
    file = []
    for code in @file
      file << code.gsub(original_substring, new_substring)
      #Found on: https://www.techotopia.com/index.php/Ruby_String_Replacement,_Substitution_and_Insertion
    end
    @file = file
  end
  
end

# The next piece of code represents the try I scripted so I could retrive the interaction networks, but it doesn't work in the correct way. Anyway, it can be executed and
# it will get the binary interactions from a list of genes for each gene. The chunk of code is extremely tedious to check out. It isn't appropiately commented, so I'll explain
# here what it does in general terms: from a list of genes which nomenclature has been formated after this regular expression: At[1-5]g[0-9]{5}, it obtains what binary
# interactions are established between a gene protein and other proteins. UniProt was used for this approach. UniProt has multiple protein names for the same protein, so
# what's important to be checked out is the IntAct protein name. That's the code used to identify other proteins that interact with it, and with that information, their gene
# names can be found. n variable was used in a while loop so recursivity could be applied, and a following filtering method was created so protein names couldn't appear multiple
# times in the same protein list. Nevertheless, recursivity loop doesn't work, so this piece of code is only useful in order to retrieve binary interactions. Also, it takes
# so long to be run for every gene in the given file. That's why it ended toogled. I didn't notice what was indicated at the end of the assignment page, so I thought that this
# was the only approach I could try instead of using BAR (University of Toronto). If I retried this assignment, I would explore that solution.

#interaction_network=[]
#list_of_gene_names = ["At3g15030"]

#for gene_name in list_of_gene_names
#  list_of_proteins=[]
#  res = fetch("https://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=uniprotkb&id=" + gene_name + "&style=raw")
#  body = res.body
#  uniprot_regex=Regexp.new(/IntAct;.+;/)
#  # The regular expression was obtained from: https://www.uniprot.org/help/accession_numbers
#  protein_id = uniprot_regex.match(body).to_s
#  uniprot_regex=Regexp.new(/[OPQ][0-9][A-Z0-9]{3}[0-9]|[A-NR-Z][0-9]([A-Z][A-Z0-9]{2}[0-9]){1,2}/)
#  protein_id = uniprot_regex.match(protein_id).to_s
#  list_of_proteins << protein_id
#  n = 0
#  o = 0
#  while n < 1
#    list_of_proteins_length=list_of_proteins.length()
#    while o < list_of_proteins_length
#      res = fetch("https://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=uniprotkb&id=" + list_of_proteins[o] + "&style=raw")
#      body = res.body
#      interaction_proteins_regex=Regexp.new(/CC.+:/)
#      list_of_interaction_proteins=body.scan(interaction_proteins_regex)
#      interaction_proteins_regex=Regexp.new(/; [OPQ][0-9][A-Z0-9]{3}[0-9]|[A-NR-Z][0-9]([A-Z][A-Z0-9]{2}[0-9]){1,2}/)
#      for str in list_of_interaction_proteins
#        interaction_protein=interaction_proteins_regex.match(str).to_s
#        if interaction_protein != ""
#          interaction_protein = interaction_protein[2..interaction_protein.length+1]
#          list_of_proteins << interaction_protein
#        end
#        o = o + 1
#      end
#    end
#    new_list_of_proteins=[]
#    for element in list_of_proteins
#      if new_list_of_proteins.include? element
#      else
#        new_list_of_proteins << element
#      end
#    end
#    list_of_proteins=[]
#    for element in new_list_of_proteins
#      list_of_proteins << element
#    end
#    n = n + 1
#  end
#  new_list_of_genes=[]
#  for element in list_of_proteins
#    res = fetch("https://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=uniprotkb&id="+element+"&style=raw")
#    body = res.body
#    gene_name_regex=Regexp.new(/OrderedLocusNames=[Aa][Tt][1-5][Gg][0-9]{5}/)
#    gene_name=gene_name_regex.match(body).to_s
#    gene_name_regex=Regexp.new(/[Aa][Tt][1-5][Gg][0-9]{5}/)
#    gene_name=gene_name_regex.match(body).to_s
#    if gene_name != ""
#      new_list_of_genes << gene_name
#    end
#  end
#  interaction_network << new_list_of_genes
#end