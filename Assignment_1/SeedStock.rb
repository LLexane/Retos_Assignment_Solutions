class SeedStock
    attr_accessor :seed_Stock 
    attr_accessor :mutant_Gene_ID 
    attr_accessor :last_Planted
    attr_accessor :storage
    attr_accessor :grams
    @@all_seeds = [] 
    
    def initialize (params = {}) #initialisation of attributes of a SeedStock object 
      @seed_Stock = params.fetch(:seed_Stock, 'unknown')
      @mutant_Gene_ID = params.fetch(:mutant_Gene_ID, 'unknown')
      @last_Planted = params.fetch(:last_Planted, 'unknown')
      @storage = params.fetch(:storage, 'unknown')
      @grams = params.fetch(:grams, "0")
      @@all_seeds << self
    end
    
    def SeedStock.all_seeds
      return @@all_seeds
    end
    
    def plant (nbrGrams)  #method allowing to plant a number of grams by a soustraction and to inform if the result is zero or negative
      new_quantity = @grams.to_i-nbrGrams
        if new_quantity <= 0
          new_quantity = 0
          puts "WARNING: we have run out of Seed Stock #{@seed_Stock} "
        end
      @grams=new_quantity.to_s  #the new quantity is updated in the SeedStock object
    end
end