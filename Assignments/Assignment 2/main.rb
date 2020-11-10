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

require 'json'
require './AnnotatedGene.rb'
require './InteractionNetwork.rb'

all_genes=Interaction_Network.new # An object that will contain all genes from given file is created.
all_genes.read_file("ArabidopsisSubNetwork_GeneList.txt") # Method read_file is used on previous object so it will contain all the genes from a file that's been read.
  
list_of_genes=[] # List that will contain all Annotated_Gene objects.

for atcode in all_genes.file # All Annotated_Gene objects will be created using ftheir Arabidopsis thaliana gene codes.
  gene = Annotated_Gene.new(:atcode => atcode)
  list_of_genes << gene
end

text = "" # will contain the output file content

for gene in list_of_genes # for each Annotated_Gene
  gene.retreive_ProteinID # its protein ID from ENSEMBL will be retrieved
  gene.retrieve_GO_Annotations # Their associated GO ID from UniProt will be retrieved
  gene.retrieve_GO_meaning # Each GO ID meaning from UniProt will be retrieved
  gene.retrieve_KEGG_pathways # Their associated KEGG ID and KEGG ID menaning from KEGG will be retrieved
  text = text + gene.gene_info # GO information and KEGG information will compiled into the variable text
end

File.write("KEGGandGO.txt", text) # This file only has some of the genes with their associated GO terms and KEGG pathways. Annotated_Gene functioning could explain why some
# GO terms aren't retrieved and written down as file content. See Annonated_Gene.rb for more information.