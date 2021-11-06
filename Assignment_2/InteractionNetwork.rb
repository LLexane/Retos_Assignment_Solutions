require 'rest-client' 
require 'json' 
class InteractionNetwork
    attr_accessor :geneID
    attr_accessor :interactorB
    attr_accessor :interactorC
    attr_accessor :member
    @@network = [] 

    def initialize (params = {}) #initialisation of attributes of a Network object 
      @geneID = params.fetch(:geneID, '') #gene ID from the list
      @interactorB = params.fetch(:interactorB, []) #contain genes ID that interact with the geneID
      @interactorC = params.fetch(:interactorC, []) #contain genes ID that interact with genes from the list interactorB
      @member = params.fetch(:member, false) #parameter allowing to determine if a gene from interactorB, but not contained in the initial gene list, allow to find a gene (interactorC) contained in the initial gene list
      @@network << self 
    end 

    # each InteractionNetwork object is conserved in the list network where each case represent a network. A network is : a gene from 
    # the initial list, genes in interactions with this initial gene (only those contained in the initial gene list or implicated 
    # in an interaction C) and all genes interacted with these genes but only those contained in the initial gene list.
    def InteractionNetwork.network 
        return @@network 
    end

    def getProtein(gene) #method allowing to find and return the protein associated with a gene
        prot=''
        address = "http://togows.dbcls.jp/entry/uniprot/#{gene}/dr.json"
        res = RestClient::Request.execute( method: :get, url: address)
        data = JSON.parse(res.body)
        data.each do |d|
            if d["PRO"]
                prot=d["PRO"][0][0].split(":",2)[1]
            else
                prot=d["SMR"][0][0]
            end
        end
        return prot
    end

    def findInteractionC (gene) #method allowing to find all interactions with a gene, put each gene ID in the list interactorC and see if they belong to the initial gene list 
        address = "http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/interactor/#{gene}?format=tab25"
        res = RestClient::Request.execute( method: :get, url: address)
        if res
            if !res.body.chomp.empty? #look if the page is not empty. I use only one database so if the page is empty I considered that my gene doesn't interact.
                protein=getProtein(gene)
                res.body.each_line do |line|
                    line.split("\t",15)[0..1].each do |x|
                        bd,prot=x.split(":",2)
                        if prot != protein #select only the protein prot from the other gene to find this other gene ID which interact with my gene via protein
                            if bd == "uniprotkb" #going to try to retrieve the AGI of this other gene
                                address2="http://togows.org/entry/ncbi-protein/#{prot}/features.json"
                                response = RestClient::Request.execute( method: :get, url: address2)
                                data = JSON.parse(response.body)
                                if data[0].any? #look if the page is not empty of information
                                    if data[0][1]["locus_tag"]
                                        agi=data[0][1]["locus_tag"][0].upcase 
                                    elsif agi=data[0][1]["gene"]
                                        agi=data[0][1]["gene"][0].upcase
                                    end
                                else
                                    address3="http://togows.org/entry/ebi-uniprot/#{prot}/dr.json"
                                    resp = RestClient::Request.execute( method: :get, url: address3)
                                    datos = JSON.parse(resp.body)
                                    if datos[0]["EnsemblPlants"]
                                        agi=datos[0]["EnsemblPlants"][0][2].upcase
                                        matc = Regexp.new(/[A][T](\d)[G](\d\d\d\d\d\.)/) #wrong regular expression in this case
                                        if matc.match(agi) #look if the AGI have the wrong regular expression
                                            agi=datos[0]["EnsemblPlants"][0][2].split(".",2)[0].upcase
                                        end
                                    else
                                        address4="https://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=uniprotkb&format=fasta&id=#{prot}&style=raw"
                                        re = RestClient::Request.execute( method: :get, url: address4)
                                        tab=re.body.upcase.split(" ") #construction of a tabular because the format isn't json
                                        matc = Regexp.new(/[A][T](\d)[G]/) #right regular expression in this case
                                        tab.each do |x|
                                            if matc.match(x)
                                                agi=x
                                            end
                                        end
                                    end    
                                end
                                #now the AGI of the other gene is found so we are going to look if we can add it in the network of the @geneID
                                @@network.each do |n|
                                    if n.geneID == agi && agi != @geneID && @interactorB.include?(agi)==false #look if the AGI is contained in the initial gene list but not equal to the first gene and to the AGI list of interactorB genes of this network 
                                        @interactorC|=[agi] #add this AGI in the interactorC list
                                        @member=true #true = gene from interactorB allow to find a gene (interactorC) contained in the initial gene list
                                    end
                                end
                            elsif bd == "ensemblgenomes"
                                @@network.each do |n|
                                    if n.geneID == agi && prot.upcase != @geneID && @interactorB.include?(agi)==false
                                        @interactorC|=[prot.upcase] 
                                        @member=true 
                                    end  
                                end
                            end
                        end 
                    end 
                end
            end
        else
            puts "the Web call failed - see STDERR for details..."
        end
    end

    def findInteraction (gene) #method allowing to find all interactions with a gene, put each gene ID in the list interactorB and see if they belong to the initial gene list or if allow to find a gene (interactorC) contained in the initial gene list
        #here just one database is selected to find all the interactions but many empty page are result. It could be good to search in many other databases.
        address = "http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/interactor/#{gene}?format=tab25"
        res = RestClient::Request.execute( method: :get, url: address)
        if res
            if !res.body.chomp.empty?
                protein=getProtein(gene)
                res.body.each_line do |line|
                    line.split("\t",15)[0..1].each do |x|
                        bd,prot=x.split(":",2)
                        if prot != protein
                            if bd == "uniprotkb"
                                address2="http://togows.org/entry/ncbi-protein/#{prot}/features.json"
                                response = RestClient::Request.execute( method: :get, url: address2)
                                data = JSON.parse(response.body)
                                if data[0].any?
                                    if data[0][1]["locus_tag"]
                                        agi=data[0][1]["locus_tag"][0].upcase 
                                    elsif agi=data[0][1]["gene"]
                                        agi=data[0][1]["gene"][0].upcase
                                    end
                                else
                                    address3="http://togows.org/entry/ebi-uniprot/#{prot}/dr.json"
                                    resp = RestClient::Request.execute( method: :get, url: address3)
                                    datos = JSON.parse(resp.body)
                                    matc = Regexp.new(/[A][T](\d)[G](\d\d\d\d\d\.)/)
                                    if datos[0]["EnsemblPlants"]
                                        agi=datos[0]["EnsemblPlants"][0][2].upcase
                                        if matc.match(agi)
                                            agi=datos[0]["EnsemblPlants"][0][2].split(".",2)[0].upcase
                                        end
                                    else
                                        address4="https://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=uniprotkb&format=fasta&id=#{prot}&style=raw"
                                        re = RestClient::Request.execute( method: :get, url: address4)
                                        tab=re.body.upcase.split(" ")
                                        matc = Regexp.new(/[A][T](\d)[G]/)
                                        tab.each do |x|
                                            if matc.match(x)
                                                agi=x
                                            end
                                        end
                                    end    
                                end
                                #now the AGI of the other gene is found so we are going to look if we can add it in the network of the @geneID
                                if agi != @geneID && @interactorB.include?(agi)==false #look if the AGI is not equal to the first gene (@geneID) and to other interactorB genes of this network 
                                    @interactorB|=[agi] #add this AGI in the interactorB list
                                end
                            elsif bd == "ensemblgenomes"
                                if agi != @geneID && @interactorB.include?(agi)==false
                                    @interactorB|=[prot.upcase]
                                end
                            end
                        end
                    end 
                end
            end
        else
            puts "the Web call failed - see STDERR for details..."
        end
        @interactorB.each do |g|
            @member=false
            findInteractionC(g) #find interactin with each gene of the list @interactorB. It correspond to an other deep.
            @@network.each do |n|
                if n.geneID != g && @member==false #if it doesn't find any interaction between the gene g and any gene of the initial gene list, 
                    #then the @member stay equals to false and if this gene g of interaction B is not in the initial gene list then we can delete it
                    @interactorB=@interactorB - [g]
                end
            end   
        end
    end

    def keggPathway (gene) #method allowing to find and return the KEGG ID and Pathway Name of a gene 
        kegg={}
        address="http://rest.kegg.jp/link/pathway/ath:#{gene}"
        res = RestClient::Request.execute( method: :get, url: address)
        if !res.body.chomp.empty? #look if the page is not empty
            res.body.each_line do |line|
                path,keggID=line.chomp.split("\t",2)[1].split(":",2) #find the keggID
                addressP="http://togows.org/entry/kegg-pathway/#{keggID}/pathways.json" #look for the Pathway Name using the keggID
                res = RestClient::Request.execute( method: :get, url: addressP)
                data = JSON.parse(res.body)
                kegg.merge!(data[0]) #stock each keggID and pathway name in the hash kegg
            end
        end
        return kegg
    end 


    def go_term (gene) #method allowing to find and return the GO term from the biological_process part of a gene 
        go={}
        addressG = "http://togows.dbcls.jp/entry/uniprot/#{gene}/dr.json"
        response = RestClient::Request.execute( method: :get, url: addressG)  
        data = JSON.parse(response.body)
        data.each do |d|
            d["GO"].each do |a|
                if a[1].split(":",2)[0]=="P"
                    go[a[0]]=a[1] #each GO:ID and GO term name are stocked in the hash go 
                end
            end
        end
        return go
    end

    def report() #method allowing to create a report of which members of the gene list interact with one another, with the KEGG/GO functional annotations of those interacting members.
        puts "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
        if @interactorB.empty? #if there is no member in the interactor B list then there is no gene in the interactor C list so our initial gene interacts with no gene from the initial list.
            puts "The gene #{@geneID} interacts with no gene from the list."
        else
            network = @interactorB + @interactorC #final network of the @geneID
            puts "Gene #{@geneID}"
            puts "\t KEGG Pathway : #{keggPathway(@geneID)}\n"
            puts "\t\t    GO : #{go_term(@geneID)}"
            puts "Interact with :"
            puts
            network.each do |z| #for each member of the network present in the initial list, the KEGG and GO are searched with there methods and puts.
                @@network.each do |n|
                    if n.geneID == z
                        puts " - #{z}\tKEGG Pathway : #{keggPathway(z)}\n"
                        puts "\t\t\t GO : #{go_term(z)}"
                    end
                end
            end
        end
    end
end