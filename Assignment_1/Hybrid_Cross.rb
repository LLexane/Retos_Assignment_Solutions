require './SeedStock.rb'
require './SeedStockDatabase.rb'
require './Gene.rb'
class Hybrid_Cross
    attr_accessor :parent1
    attr_accessor :parent2
    attr_accessor :f2_wild 
    attr_accessor :f2_p1
    attr_accessor :f2_p2 
    attr_accessor :f2_p1p2
    @@all_cross = []
  
  def initialize (params = {}) #initialisation of attributes of a Hybrid_Cross object 
    @parent1 = params.fetch(:parent1, 'XXXX')
    @parent2 = params.fetch(:parent2, 'XXXX')
    @f2_wild = params.fetch(:f2_wild, "0")
    @f2_p1 = params.fetch(:f2_p1, "0")
    @f2_p2 = params.fetch(:f2_p2, "0")
    @f2_p1p2 = params.fetch(:f2_p1p2, "0")
    @@all_cross << self
  end

  def Hybrid_Cross.all_cross
    return @@all_cross
  end
  
  def cross? (list_genes,list_seeds) #method allowing to do a Chi-square test on the F2 cross data and to update Gene objects if genes are linked
    #Calcul of the observed total
    sum=@f2_wild.to_i+@f2_p1.to_i+@f2_p2.to_i+@f2_p1p2.to_i
    #Cacul of expected values
    e1=sum*(9.0/16.0)
    e2=sum*(3.0/16.0)
    e3=sum*(1.0/16.0)
    #Calcul of the chi squared
    chi_squared = ((@f2_wild.to_i-e1)**2)/e1 +((@f2_p1.to_i-e2)**2)/e2+((@f2_p2.to_i-e2)**2)/e2+((@f2_p1p2.to_i-e3)**2)/e3
    #the degree of freedom is (number of phenotypes – 1) so here df = 3
    #A value is considered significant if there is less than a 5% probability (p < 0.05). 
    #In our case, with df=3, a value of greater than 7.815 is required for results to be considered statistically significant.
    if chi_squared > 7.815 #genes are linked
      gene1=""
      gene2=""
      id1=""
      id2=""
      list_genes.each do |x| #reads of each Gene objects 
        list_seeds.each do |y| #reads of each SeedStock objects
          #the geneID is the key to link objects Gene and SeedStock and seed_stock ID is the key to link objects SeedStock and Hybrid_Cross
          if x.geneID == y.mutant_Gene_ID and y.seed_Stock == @parent1
            gene1=x.geneName
            id1=x.geneID
          elsif x.geneID == y.mutant_Gene_ID and y.seed_Stock == @parent2
            gene2=x.geneName
            id2=x.geneID
          end
        end
      end
      list_genes.each do |x| #update the attribute gene_link of a Gene objects 
        if x.geneID == id1
          x.gene_link = gene2
        elsif x.geneID == id2
          x.gene_link = gene1       
        end
      end
      puts "Recording: #{gene1} is genetically linked to #{gene2} with chisquare score #{chi_squared}" 
    end
  end

end