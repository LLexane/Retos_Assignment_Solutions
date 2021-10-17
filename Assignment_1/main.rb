require 'csv'
require './SeedStock.rb'
require './SeedStockDatabase.rb'
require './Gene.rb'
require './Hybrid_Cross.rb'

####### First task #######
all_seeds = SeedStock.all_seeds   #create the class variable of SeedStock
data=SeedStockDatabase.new(:list_seeds => all_seeds)  #create the SeedStockDatabase object with class variable contening all SeedStock objects
data.load_from_file("seed_stock_data.tsv")

all_seeds.each do |i| 
  i.plant(7)  #apply the plant method to each SeedStock object
end

data.write_database ("new_seed_stock_data.tsv")  #uptade the stock by creating a new one 

####### Second task #######
all_genes = Gene.all_genes  #create the class variable of Gene
gene=CSV.read("gene_information.tsv", col_sep: "\t", :headers => true)
gene.each do |g|
  Gene.new(:geneID =>g[0],:geneName =>g[1], :mutant =>g[2]) #Creating all Gene objects
end

all_cross = Hybrid_Cross.all_cross  #create the class variable of Hybrid_cross
hybrid=CSV.read("cross_data.tsv", col_sep: "\t", :headers => true)
hybrid.each do |x|
  Hybrid_Cross.new(:parent1 =>x[0],:parent2 =>x[1], :f2_wild =>x[2], :f2_p1 =>x[3], :f2_p2 =>x[4], :f2_p1p2=>x[5]) #Create all Hybrid_cross objects
end
all_cross.each do |j|
  j.cross?(all_genes, all_seeds) #apply the cross? method to each Hybrid_Cross object with the list of all Gene objects and the list of all SeedStock objects
end

Gene.final_report #call the class method allowing put a final report message with each link genes
