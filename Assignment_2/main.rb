require './InteractionNetwork.rb'  

network = InteractionNetwork.network  #create the class variable
File.foreach( 'ArabidopsisSubNetwork_GeneList.txt' ) do |line| #create each InteractionNetwork object with each geneID from the initial list
    InteractionNetwork.new(:geneID =>line.chomp.upcase )
end

network.each do |j|
    j.findInteraction(j.geneID) #find all interactions of differents deeps (2) creating the network
    j.report() #make a report to print the network with KEGG and GO annotations for each genes of the network
end
