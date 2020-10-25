class HybridCrossDatabase
  attr_accessor :name
  attr_accessor :content
  
  def initialize (params={})
    @name=params.fetch(:name, "Unknown")
    @content=params.fetch(:content, [])
  end
  
  def load_from_file(path) # cross_data.tsv data will be scattered into lists as it happened with seed_stock_data.tsv
    # data.
    cross_hybrid_data = IO.readlines(path)
    datum=Regexp.new(/\w+/) # This is a very specific regular expression that is only useful in this context, so data
    # from cross_data.tsv can be manipulated.
    new_tsv_array=[]
    for line in cross_hybrid_data
      new_tsv_array << line.scan(datum)
    end
    @content=new_tsv_array
  end
  
  def chi_calculator
    all_observed=[] # will contain observed values for each fenotypical trait so chi square formula can be applied.
    all_chi=[] # This list will ave all chi square values for each trait, so they can be summed.
    for line in @content # cross_data.tsv content has to have been created. 
      for datum in line
        if datum.to_i != 0 # string data converted into integer become zeros. This code line is risky to use, as it is
          # a particularity we can only take advantage of in this situation with these data.
         all_observed << datum.to_i # integer data from cross_data.tsv are collected.
         if line.find_index(datum) == line.length-1 # just when the last line datum has been introduced into 
           # all_observed list, the sum of all observed values for a pair of traits is calculated.
           sum = 0
           for number in all_observed
             sum = sum + number # This sum is needed to calculate the traits expected values.
           end
           expected1=0.75*0.75*sum # The pair of traits expected values were scripted. Again, this program will only be
           # useful in a very particular situation. 
           expected2=0.75*0.25*sum
           expected3=0.25*0.75*sum
           expected4=0.25*0.25*sum
           all_expected=[expected1, expected2, expected3, expected4] # All expected values are introduced in a list.
           chi=0
           for observed in all_observed # each chi square value is obtained just apllying its formula to the data in
             # the observed values and expected values lists.
             expected = all_expected[all_observed.find_index(observed)]
             chi = chi + (((observed - expected)**2)/expected) # For each pair of traits, each chi square value is the
             # result of the sum of muliple square values.
           end
           all_chi << chi # All definitive chi square values are disposed in another list.
         end
        end
      end
      all_observed = []
    end
    return all_chi
  end
  
end