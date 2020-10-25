class Gene
  attr_accessor :name # represents the name retrieved from gene_information.tsv.
  attr_accessor :atcode # represents the Arabidopsis gene name retrieved from seed_stock_data.tsv.
  attr_accessor :seedcode # represents the seed stock name from cross_data.tsv.
  def initialize (params={})
    @name=params.fetch(:name, "Unknown")
    @atcode=params.fetch(:atcode, "Unknown")
    regexp_atcode = Regexp.new(/A[tT][1-5][gG](\d{5})/) # This checks if Arabidopsis gene name has the correct
    # nomenclature. If the regular expression doesn't match the input name, it won't become that gene name.
    if regexp_atcode.match(@atcode).to_s != @atcode
      puts "WARNING: input string doesn't match Arabidopsis thaliana gene pattern."
      @atcode="Unknown"
    end
    @seedcode=params.fetch(:seedcode, "Unknown")
  end
end