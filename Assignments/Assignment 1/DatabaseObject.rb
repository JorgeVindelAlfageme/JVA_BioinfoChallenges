class SeedStockDatabase
  attr_accessor :name
  attr_accessor :content
  
  def initialize (params={})
    @name=params.fetch(:name, "Unknown")
    @content=params.fetch(:content, [])
  end
  
  def load_from_file(path)
    seed_stock_data = IO.readlines(path)
    datum=Regexp.new(/\d+\/\d+\/\d+|\w+/)
    # Note that last regular expression is not the same as:
    # datum=Regexp.new(/\w+|\d+\/\d+\/\d+/)
    # The former searches for dates in first place, while the latter would end splitting dates into three different data.
    new_tsv_array=[]
    for line in seed_stock_data
      # I found scan method as extremely useful. I knew about this method on: 
      # https://stackoverflow.com/questions/80357/how-to-match-all-occurrences-of-a-regex
      new_tsv_array << line.scan(datum)
    end
    @content=new_tsv_array
  end
  
  def get_seed_stock(id)
    header = ""
    for string in @content[0]
      if @content[0].find_index(string) != @content[0].length-1
        header = header + string + "\t"
      else
        header = header + string
      end
    end
    data_line = "" # It'll be the output line
    for line in @content
      for datum in line # searches for id in database content
        if datum == id
          for datum in line # after it's been found, data_line variable will register the entire line
            if line.find_index(datum) != line.length-1
              data_line = data_line + datum + "\t"
            else
              data_line = data_line + datum
            end
          end
        end
      end
    end
    puts "\nInformation about " + id + " from #{@name} database:"
    puts "\n"+header
    puts data_line
  end
  
  def planting(planted_seed_grams)
    
    puts "\nInitializing seed planting..."
    puts ""
    date_index=@content[0].find_index("Last_Planted")
    grams_index=@content[0].find_index("Grams_Remaining") # This implies knowing about what kind of tsv file you are
    # manipulating, its header and the kind of value the given column name contains.

    date_today=Time.now.strftime("%d/%m/%Y") # retrieved from:
    # https://stackoverflow.com/questions/7415982/how-do-i-get-the-current-date-time-in-dd-mm-yyyy-hhmm-format
    m=1 # It's the line index in tsv file coverted into an array of multiple arrays.
    
    for line in @content
      if line != @content[0] # allows to operate in every tsv row except the header.
        for string in line # for every datum in the table.
          if line.find_index(string) == date_index
            @content[m][date_index] = date_today # changes values so dates become today's date.
          end
          if line.find_index(string) == grams_index # checks if values are in the stock grams column. 
            new_value = string.to_i - planted_seed_grams # converts string numbers into integer values and operates.
            if new_value <= 0
              new_value = 0 # asures no negative values are included in the new file.
              puts "WARNING: we have run out of seed stock #{@content[m][@content[0].find_index("Seed_Stock")]}"
            end
            @content[m][grams_index] = new_value.to_s # is the only way I found to sustitute one value by another one
            # in this code context (string = new_value.to_s is not valid).
          end
        end
      m=m+1
      end
    end
    puts "\nPlanting succeded."
  end
  
  def write_database(new_path)
    puts "\nInitializing file writting..."
    new_stock_file="" # will contain seed stock file updated information.
    for line in @content
      for string in line
        if line.find_index(string) != line.length-1
          new_stock_file = new_stock_file + string + "\t" # will be adding each datum to new_stock_file variable.
        else
          new_stock_file = new_stock_file + string + "\n" # if last line datum from the table is going to be added to 
          # new_stock_file variable, it'll be with a carriage return symbol at the end instead of a tab character.
        end
      end
    end
    puts "\nNew file content:"
    puts new_stock_file
    File.write(new_path, new_stock_file) # creates new stock file with new_stock_file variable content.
    puts "\nFile writting succeded."
  end
  
end