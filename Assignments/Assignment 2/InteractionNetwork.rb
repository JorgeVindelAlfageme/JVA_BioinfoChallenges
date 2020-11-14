require 'rest-client'

def fetch(url, headers = {accept: "*/*"}, user = "", pass="") # Function the requires rest-client ruby gem in order to work that allows to retrieve information from web pages.
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

class Interaction_Network # This class was created so it could compile the information from a file containing only A. thaliana gene codes.
  
  attr_accessor :file # This variable will have all the gene codes as a list of strings.
  attr_accessor :Interaction_Networks # This variable will be a list of sublist. Each sublist will have genes that interact with a specific gene from the @file variable. Those
  # interacting genes will have to forma part ot the @file variable too in order to become a sublist that constitutes an interaction network.
  
  def initialize (params={})
    
    @file=params.fetch(:file, "")
    @Interaction_Networks=params.fetch(:Interaction_Networks, [])
    
  end
  
  def read_file(file_name) # reads file and retrieves all A. thaliana gene codes from it.
    file = ""
    File.open(file_name, "r") do |f|
      f.each_line do |line|
        file = file + line
      end
    end
    list_of_codes=file.scan(/[Aa][Tt][1-5][Gg][0-9]{5}/) # scan method is necessary so gene codes are organized into a list.
    @file = list_of_codes # That list becomes the @file variable.
  end
  
  def format_file(original_substring, new_substring) # This function was defined so genes from the original txt file could match those gene names from the Utoronto web page, where
    # gene interactions are registered.
    file = []
    for code in @file
      file << code.gsub(original_substring, new_substring) # transforms an string with an specific substring into another through that substring modification.
      #Found on: https://www.techotopia.com/index.php/Ruby_String_Replacement,_Substitution_and_Insertion
    end
    @file = file
  end
  
  def interaction_networks(m) # This function creates a gene interaction network from a given gene and a set of genes. It compares retrieved genes from Utoronto domain and
    # if they match to those in the variable that constains all the genes from a file, then they become part of the interaction network.
    for gene in @file
      genes_once=[] # this will contain the genes that form the interaction network.
      genes_once << gene # inserts the given gene into the list, so at leat it will have one gene.
      n=0 # n represents a counter that will permit to establish the number of iterations is wanted in a interaction network so non-binary interactions can be discovered.
      o=0 # this variable will represent the index of a gene in the list that constitutes the interaction network. Thanks to it, no redundant webpage searches will be done.
      while n < m # this determines the number of iterations for each gene to discover non-binaty interactions. m can be set to different values (it is called levels of depth of
        # the interaction network in the main script).
        length_genes_once=genes_once.length() # For each iteration through the levels of depth of the interaction network, this value registers the length of the list containing the
        # genes in the interaction network. Thanks to this, for each iteraction, all genes from a level of depth are evaluated.
        while o < length_genes_once
          web="http://bar.utoronto.ca:9090/psicquic/webservices/current/search/query/" + genes_once[o] + "?format=tab25" # the variable o is needed so each gene is retrieved
          # for its index in the genes interaction network list. In these pages, there are gene codes for all the gene that interact with the given gene named in the URL.
          res=fetch(web)
          if res
            body=res.body
            at=Regexp.new(/[Aa][Tt][1-5][Gg][0-9]+/) # All thos genes are retrieved using the scan methos and a regular expression.
            ats=body.scan(at)
            for at in ats # for all those genes retrieved
              if genes_once.include? at # if they are already included in the list of the interaction network, they will be rejected.
              else
                if @file.include? at # if not, and if they are found int the varaible @file, they become part of the interaction network
                  genes_once << at
                end
              end
            end
            o = o + 1 # lastly, the variable o increments its value so next gene in the list can be evaluated.
          else
            o = o + 1 # The same happens if a given gene hasn't a Utoronto webpage.
          end
        end
        n = n + 1
      end
      @Interaction_Networks << genes_once # after ending with all the iterations through the depth levels of the interaction network, it is added to a list that will contain all
      # those interaction networks.
    end
  end
  
end