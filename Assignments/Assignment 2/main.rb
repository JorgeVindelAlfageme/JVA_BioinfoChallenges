require 'rest-client'

def fetch(url, headers = {accept: "*/*"}, user = "", pass="") # is the way we access to webpages content and a piece of code extracted from the course notes.
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

require 'json'
require './AnnotatedGene.rb'
require './InteractionNetwork.rb'

puts "Building gene interaction networks. Please, wait."
file_name="ArabidopsisSubNetwork_GeneList.txt"
all_genes=Interaction_Network.new # a new interaction network for all of the genes in a file is created.
all_genes.read_file(file_name) # this object from the interaction network class reads the file containing the A. thaliana gene codes.
all_genes.format_file("T", "t") # those gene codes are formated after the way they appear in the Utoronto database.
l=2 # sets the levels of depth or iterations through a interaction network, so non-binary interactions between genes can be established.
all_genes.interaction_networks(l) # The interaction network is created.

puts "Done."
puts "Getting GO and KEGG annotations for each gene. Please, wait (with 2 levels of depth, this takes about 10 minutes)."

text = "" # This varaible will contain all the results from this analysis. It could have been more efficient to overwrite the same creted file over and over again with the
# method append.
text = text + file_name + " genes interaction networks\n\n"

k=1 # represents the number ot the interaction networks starting from a sigle gene from the read file.

for sublist in all_genes.Interaction_Networks # for each interaction network
  text = text + "Interaction network number " + k.to_s + " (with #{l.to_s} levels of depth)" + ":\n"
  text = text + "List of genes participating in this network: " + sublist.to_s + "\n"
  for gene in sublist # for each gene in that network
    new_gene=Annotated_Gene.new(:atcode => gene) # creates new object from a gene code from the A. thaliana gene codes files. 
    new_gene.retrieve_GO_Annotations # for that gene, GO IDs and their meaning are retrieved
    new_gene.retrieve_KEGG_pathways # for that gene, KEGG pathways are retrieved.
    text = text + new_gene.gene_info # they are all compiled through gene_info method
  end
  k=k+1
end

File.write("results.txt", text)

puts "Done."

puts "After the results that I have got, what I can say is that the genes that are found in the A. thaliana gene codes file aren't interacting with each other in their mayority, even if 2 levels of depth are considered through the interaction networks."