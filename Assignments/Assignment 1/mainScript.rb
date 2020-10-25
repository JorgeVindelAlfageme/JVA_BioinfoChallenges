require "/home/osboxes/BioinformaticsCourseGit/JVA_BioinfoChallenges/Assignments/Assignment 1/GeneObject.rb"
require "/home/osboxes/BioinformaticsCourseGit/JVA_BioinfoChallenges/Assignments/Assignment 1/CrossObject.rb"
require "/home/osboxes/BioinformaticsCourseGit/JVA_BioinfoChallenges/Assignments/Assignment 1/DatabaseObject.rb"

path=ARGV[0]
path2=ARGV[1]
path3=ARGV[2]
path4=ARGV[3]

seed_stock=SeedStockDatabase.new(:name => "SeedStock1")

seed_stock.load_from_file(path2) # Notice that first path isn't
# variable "path", but it's path2... This will continue to
# happen all along the script.

seed_stock.get_seed_stock("A348")

seed_stock.planting(7)

seed_stock.write_database(path4)

hybrid_cross=HybridCrossDatabase.new(:name => "Hybrid cross 1") # A new database variable is created for cross_data.tsv
#content.

hybrid_cross.load_from_file(path3) # cross_data.tsv is read from a path.

chi_list=hybrid_cross.chi_calculator # chi square values are obtained from the data.

significative_chi_indexes=[] # this list will contain only the indexes from cross_data.tsv lines which data generated
# significative chi square values.
for chi in chi_list
  if chi > 3.84 # if chi square value is greater than 3.84, p-value is lesser than 0.05, which in statistics is related
# with statistival significance.
    significative_chi_indexes << chi_list.find_index(chi) + 1 # It's necessary to add one so those indexes really
    # represent the line significative chi square values were extracted from, since the database header hasn't a
    # associated chi square value.
  end
end

seed_stock_code=Regexp.new(/[a-zA-Z][0-9]+/) # Associated seed stock codes from significative chi square values are
# introduced in a list.
seed_stock_codes=[]

for index in significative_chi_indexes 
  for datum in hybrid_cross.content[index]
    if seed_stock_code.match(datum) != nil # macth() method generates nil values when applied.
      seed_stock_codes << datum
    end
  end
end

regexp_atgene = Regexp.new(/A[tT][1-5][gG](\d{5})/) # Seed stock codes are necessry so Arabidopsis gene codes can be
# retrieved. They can be found from the seed_stock_data.tsv data.
gene_atcodes=[]
for code in seed_stock_codes
  for line in seed_stock.content
    for datum in line
      if code == datum
        for datum in line
          if regexp_atgene.match(datum) != nil
            gene_atcodes << regexp_atgene.match(datum).to_s
          end
        end
      end
    end
  end
end

gene_information = IO.readlines(path) # Now the last file in order to find and equivalence between the seed stock codes
# and the gene names is read. Multiple regular expressions are used so the genes names can finally be obtained.

gene_names=[]
for code in gene_atcodes
  gene_atcode=Regexp.new(code)
  for string in gene_information
    if gene_atcode.match(string) != nil
      gene_name=Regexp.new(/\t(\w+)\t/)
      if gene_name.match(string) != nil
        gene_names << gene_name.match(string).to_s
      end
    end
  end
end

gene_abbreviation=Regexp.new(/\w+/)
gene_abbreviations=[]

for datum in gene_names
  if gene_abbreviation.match(datum) != nil
    gene_abbreviations << gene_abbreviation.match(datum).to_s
  end
end

genes=[] # A list with all the infomration about the gene names is created. It will only contain those genes that are
# linked, since all the previous information referred to those genes which implied a significative chi square value.
n=0
for string in seed_stock_codes
  gene=Gene.new(:name => gene_abbreviations[n],
                :atcode => gene_atcodes[n],
                :seedcode => seed_stock_codes[n])
  genes << gene
  n=n+1
end

puts ""
for index in significative_chi_indexes
  for gene in genes
    if genes.find_index(gene)%2 == 0 # Since linked genes will be ordered by pairs, modulus operator can be used
    # so using only one gene name both of them will be output.
      puts "Report: #{gene.name} is genetically linked to #{genes[genes.find_index(gene)+1].name} with chi square score #{chi_list[index-1]}."
    end
  end
end

puts "\nFinal report:"
puts ""
for gene in genes
  if genes.find_index(gene)%2 == 0 # Since linked genes will be ordered by pairs, each gene of the pair will refer to
    # the other. This can be achieved through modulus operator and index calling.
    puts "#{gene.name} is linked to #{genes[genes.find_index(gene)+1].name}"
  else
    puts "#{gene.name} is linked to #{genes[genes.find_index(gene)-1].name}"
  end
end

puts ""