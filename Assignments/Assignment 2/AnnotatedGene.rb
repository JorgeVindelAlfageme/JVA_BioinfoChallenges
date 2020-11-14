require 'rest-client'
require 'json'

def fetch(url, headers = {accept: "*/*"}, user = "", pass="") # This function was got from course notes. It allows to retrieve information from web pages.
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

class Annotated_Gene
  
  attr_accessor :name # represents the name of a gene.
  attr_accessor :atcode # represents the code for the Arabidopsis thaliana gene {AaTt[0-5]G[0-9]+}.
  attr_accessor :GO_Annotations # represents the GO ID term from ENSEMBL.
  attr_accessor :GO_Termname_Uniprot # represents the GO terms meaning from ENSEMBL.
  attr_accessor :KEGG # represents the KEGG IDs and meaning from KEGG.
  
  def initialize (params={})
    @name=params.fetch(:name, "Unknown")
    @atcode=params.fetch(:atcode, "Unknown")
    regexp_atcode = Regexp.new(/A[tT][1-5][gG](\d{5})/) # This checks if Arabidopsis gene name has the correct
    # nomenclature. If the regular expression doesn't match the input name, it won't become that gene code.
    if regexp_atcode.match(@atcode).to_s != @atcode
      puts "WARNING: input string doesn't match Arabidopsis thaliana gene pattern."
      @atcode="Unknown"
    end
    @GO_Annotations=params.fetch(:GO_Annotations, []) # represents the GO ID term from Uniprot.
    @GO_Termname_Uniprot=params.fetch(:GO_Termname_Uniprot, []) # represents the GO ID term meaning from UniProt.
    @KEGG=params.fetch(:KEGG, []) # represents the KEGG IDs and meaning from KEGG.
  end
  
  def retrieve_GO_Annotations # In order to get GO terms from a UniProt page, Arabidopsis thaliana gene code was used inserted into a string representing a specific protein page
    # from that domain.
    if @atcode != "Unknown"
      uniprot_url = "https://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=uniprotkb&id="+@atcode+"&style=raw"
      res = fetch(uniprot_url)
      body = res.body
      go_regex=Regexp.new(/GO:[0-9]+/) # This regular expression matches all those GO IDs related a specific A. thaliana gene code from a UniProt page.
      go_annotations = body.scan(go_regex) # scan methods coverts all those matches into a list containing those matches.
      go_regex=Regexp.new(/[0-9]+/) # After that, a regular expression is used so from the latter matches, that have a substring added to the GO IDs string, only the ID is
      # retrieved. This solution is not optimal for this part of the problem. A better solution would have been getting only the ID and the menaing of the terms directly.
      go_terms=[]
      for string in go_annotations # for all those strings with the GO IDs, only the IDs will be got.
        go_annotation = go_regex.match(string).to_s
        go_terms << go_annotation # Those IDs will form part of a list that will contain every GO ID for a single gene.
      end
      @GO_Annotations = go_terms # That list is passed to a Annotated_Gene class variable.
    else
      puts "atcode required." # This part of the code is executed only if a gene from this class doesn't have a registered A. thaliana gene code.
    end
    if @GO_Annotations.length() > 0 # GO terms meaning will be retrieved only if GO IDs were registered. The same approach as for getting the GO IDs is used here.
      go_mean_regex=Regexp.new(/GO:[0-9]+; [A-Z]:.+;/) # A regular expression that will match the GO IDs meaning as part of it is scripted.
      go_meanings = body.scan(go_mean_regex) # All GO IDs and their meanings are matched.
      go_mean_regex=Regexp.new(/ \w:.+/) # A regular expression that will only match the meaning of the GO IDs is scripted.
      go_mean_terms=[]
      for string in go_meanings # for every former match, the second regular expression is used so only the GO IDs meaning are retrieved.
        go_meaning = go_mean_regex.match(string).to_s
        go_mean_terms << go_meaning # They all are registered into a list in an organized way, so they correlate to those GO IDs contained in a previous class variable.
      end
      @GO_Termname_Uniprot = go_mean_terms # That list becomes another class varaible.
    else
      puts "There are no GO annotations associated to gene: #{@atcode}." # This message will pop up if no GO IDs were retreived from a UniProt page assigned to a specific gene.
    end
  end
  
  def retrieve_KEGG_pathways # KEGG pathway retrieval implies json gem usage.
    if @atcode != "Unknown" # This will only be executed if A. thaliana gene code is known.
      kegg_url="http://togows.org/entry/kegg-genes/ath:" + @atcode + "/pathways.json" # KEGG URLs contain the A. thaliana gene code as part of it.
      res=fetch(kegg_url)
      data = JSON.parse(res.body) 
      kegg_pathways = [] # I noticed that this could be redundant, as this variable was conceived as a list of sublists containing all KEGG terms and their meaning. 
      for element in data[0] # data[0] contains the KEGG information as elements from a list. Loop iteration was used to get each element from that list.
        kegg_pathway = []
        kegg_pathway << element[0]
        kegg_pathway << element[1]
        kegg_pathways << kegg_pathway
      end
      @KEGG = kegg_pathways # That list becomes another class variable.
    else
      puts "atcode absent. Kegg pathways couldn't be retrieved."
    end
  end
  
  def gene_info # compiles all GO information and all KEGG information by creating a variable that reunites all GO terms and KEGG terms as strings.
    info = "\t#{@atcode}\n"
    n=0
    if @KEGG != [] # KEGG information will be added only if KEGG pathways were retrieved; anyways, it must be redundant, since if there are no elements in @KEGG, the next loop
      # won't be triggered.
      for element in @KEGG
        info = info + "\t\tKegg ID: #{element[0]}; Kegg meaning: #{element[1]};\n" # compiles KEGG information
      end
    end
    for element in @GO_Annotations
      info = info + "\t\tGO ID: #{@GO_Annotations[n]}; GO meaning: #{@GO_Termname_Uniprot[n][3..@GO_Termname_Uniprot[n].length]}\n" # compiles GO information
      n=n+1
    end
    return info # returns all the information from KEGGpathways and GO terms.
  end
    
end