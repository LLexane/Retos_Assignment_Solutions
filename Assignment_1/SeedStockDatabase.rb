require 'csv'
require './SeedStock.rb'
class SeedStockDatabase
    attr_accessor :list_seeds
    
    def initialize (params = {}) #initialisation of attribute of a SeedStockDatabase object 
      @list_seeds = params.fetch(:list_seeds, [])
    end
  
    def load_from_file(myfile) #method allowing to reed a csv file and to create SeedStock objects with each line of the file
      seed=CSV.read(myfile, col_sep: "\t", :headers => true)
      seed.each do |x|
        SeedStock.new(:seed_Stock =>x[0],:mutant_Gene_ID =>x[1], :last_Planted =>x[2], :storage =>x[3], :grams =>x[4])
      end
    end
    
    def get_seed_stock (iD)     #method allowing to individual SeedStock objects based on their ID
      response=""
      @list_seeds.each do |s|   #read the database of seeds. Each line is a SeedStock object
        if s.seed_Stock == iD   #check if the iD seed_Stock is the same as the input iD
          response = s          #the individual SeedStock objects is assigned to the variable response
        end
      end
      if response == ""
        response="This ID don't correspond to this database"
      end
      return response
    end
    
    def write_database (newfile)    #method allowing to create a new csv file and puts into it a header line and each attribute of each SeedStock object of the database
      CSV.open(newfile, "w") do |csv|
        csv << ["Seed_Stock\tMutant_Gene_ID\tLast_Planted\tStorage\tGrams_Remaining"]
        @list_seeds.each do |s|
          csv << ["#{s.seed_Stock}\t#{s.mutant_Gene_ID}\t#{s.last_Planted}\t#{s.storage}\t#{s.grams} \n"]
        end
      end
    end
    
end
  