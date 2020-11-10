require 'rest-client'
require 'json'

def fetch(url, headers = {accept: "*/*"}, user = "", pass="")
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
  
  attr_accessor :name # represents the name.
  attr_accessor :atcode # represents the code for the Arabidopsis thaliana gene {AaTt[0-5]G[0-9]+}.
  attr_accessor :ProteinID # represents the Uniprot ID code /[OPQ][0-9][A-Z0-9]{3}[0-9]|[A-NR-Z][0-9]([A-Z][A-Z0-9]{2}[0-9]){1,2}/.
  attr_accessor :GO_Annotations # represents the GO ID term from Uniprot.
  attr_accessor :GO_Termname_Uniprot # represents the GO ID term meaning from UniProt
  attr_accessor :KEGG # represents the KEGG IDs and meaning from KEGG.
  
  def initialize (params={})
    @name=params.fetch(:name, "Unknown")
    @atcode=params.fetch(:atcode, "Unknown")
    regexp_atcode = Regexp.new(/A[tT][1-5][gG](\d{5})/) # This checks if Arabidopsis gene name has the correct
    # nomenclature. If the regular expression doesn't match the input name, it won't become that gene name.
    if regexp_atcode.match(@atcode).to_s != @atcode
      puts "WARNING: input string doesn't match Arabidopsis thaliana gene pattern."
      @atcode="Unknown"
    end
    @ProteinID=params.fetch(:ProteinID, "Unknown") # represents the Uniprot ID code /[OPQ][0-9][A-Z0-9]{3}[0-9]|[A-NR-Z][0-9]([A-Z][A-Z0-9]{2}[0-9]){1,2}/.
    @GO_Annotations=params.fetch(:GO_Annotations, []) # represents the GO ID term from Uniprot.
    @GO_Termname_Uniprot=params.fetch(:GO_Termname_Uniprot, []) # represents the GO ID term meaning from UniProt
    @KEGG=params.fetch(:KEGG, []) # represents the KEGG IDs and meaning from KEGG.
  end
  
  def retreive_ProteinID # uses the AT code in order to retrieve the protein ID code from ENSEMBL.
    if @atcode != "Unknown"
      ensembl_url = "http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id="+@atcode # ENSEMBL URL gene-specific main structure.
      res = fetch(ensembl_url)
      body = res.body # contains all the data from the given page
      uniprot_regex=Regexp.new(/db_xref="Uniprot\/SWISSPROT:[OPQ][0-9][A-Z0-9]{3}[0-9]|[A-NR-Z][0-9]([A-Z][A-Z0-9]{2}[0-9]){1,2}"/)
      # The regular expression was obtained from: https://www.uniprot.org/help/accession_numbers; it'll match what will be converted into a string with the protein ID.
      protein_id = uniprot_regex.match(body).to_s
      uniprot_regex=Regexp.new(/[OPQ][0-9][A-Z0-9]{3}[0-9]|[A-NR-Z][0-9]([A-Z][A-Z0-9]{2}[0-9]){1,2}/)
      protein_id = uniprot_regex.match(protein_id).to_s # another macth method is used so protein ID is completely separated from the rest of the string.
      @ProteinID = protein_id
    else
      puts "atcode absent. The Protein_ID couldn't be retrieved."
    end
  end
  
  def retrieve_GO_Annotations # In order to get GO terms from a UniProt page, protein ID was used inserted into a string representng a specific protein page from that domain.
    # This could have implied that some genes don't have associated any GO terms in the output text file. UniProt URLs accept AT code as part of them, and redirect to a page where
    # GO terms can be found. Nevertheless, some protein IDs don't redirect to pages where those GO terms are found.
    if @ProteinID != "Unknown"
      uniprot_url = "https://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=uniprotkb&id="+@ProteinID+"&style=raw"
      res = fetch(uniprot_url)
      body = res.body
      go_regex=Regexp.new(/GO:[0-9]+/) # the same filetering method through regular expression has been applied here so GO terms could be retrieved.
      go_annotations = body.scan(go_regex)
      go_regex=Regexp.new(/[0-9]+/)
      go_terms=[]
      for string in go_annotations
        go_annotation = go_regex.match(string).to_s
        go_terms << go_annotation
      end
      @GO_Annotations = go_terms
    else
      puts "ProteinID required."
    end
  end
  
  def retrieve_GO_meaning # gets GO ID meaning. The same kind of code as that from previous methods can be found here.
    if @GO_Annotations.length() > 0 # GO terms meaning will be retrieve only if GO IDs were registered.
      uniprot_url = "https://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=uniprotkb&id="+@ProteinID+"&style=raw"
      res = fetch(uniprot_url)
      body = res.body
      go_mean_regex=Regexp.new(/GO:[0-9]+; [A-Z]:.+;/)
      go_meanings = body.scan(go_mean_regex)
      go_mean_regex=Regexp.new(/ \w:.+/)
      go_mean_terms=[]
      for string in go_meanings
        go_meaning = go_mean_regex.match(string).to_s
        go_mean_terms << go_meaning
      end
      @GO_Termname_Uniprot = go_mean_terms
    else
      puts "There are no GO annotations associated to gene: #{@atcode}." 
    end
  end
  
  def retrieve_KEGG_pathways # KEGG pathway retrieval implies json gem usage.
    if @atcode != "Unknown"
      kegg_url="http://togows.org/entry/kegg-genes/ath:" + @atcode + "/pathways.json" # KEGG URLs contain gene AT code.
      res=fetch(kegg_url)
      data = JSON.parse(res.body) 
      kegg_pathways = [] # I noticed that this could be redundant, as this variable was conceived as a list of sublists containing all KEGG terms and their meaning. 
      for element in data[0] # data[0] contains the KEGG information as elements from a list. Loop iteration was used to get each element from that list.
        kegg_pathway = []
        kegg_pathway << element[0]
        kegg_pathway << element[1]
        kegg_pathways << kegg_pathway
      end
      @KEGG = kegg_pathways
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