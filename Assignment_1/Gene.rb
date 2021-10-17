class Gene 

    attr_accessor :geneID 
    attr_accessor :geneName  
    attr_accessor :mutant
    attr_accessor :gene_link
    @@all_genes = [] 
  
    def initialize (params = {}) #initialisation of attributes of a Gene object 
      geneID = params.fetch(:geneID)
      matchh = Regexp.new(/A[Tt]\d[Gg]\d\d\d\d\d/)
      if matchh.match(geneID) #test if the format of the Gene Identifier of a Gene Object is correct
         @geneID = geneID
      else
        abort "The format of the identifier isn't correct, please retry " #the programme stop running and give an error message 
      end
    
      @geneName = params.fetch(:geneName, 'unknown')
      @mutant = params.fetch(:mutant, 'unknown')
      @gene_link = params.fetch(:gene_link, '')
      @@all_genes << self
    end
    
    def Gene.all_genes
      return @@all_genes
    end

    def Gene.final_report #class method allowing put a final report message with each link genes
        puts "\n\n"
        puts "Final Report: \n\n"
        @@all_genes.each do |x|
          if x.gene_link != ''
            puts "#{x.geneName} is linked to #{x.gene_link}"
          end
        end
      end
end