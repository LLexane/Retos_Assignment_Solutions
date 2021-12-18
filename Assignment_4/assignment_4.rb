require 'bio'
require 'stringio'

#In the terminal I firstly created two databases containing respectively each proteomes :
#I created two new folders "Databases_pep" and "Databases_TAIR10" in home/osboxes/Documents directory, and copy respectively pep.fa and TAIR10 into these locations. I executed this command to create a BLAST database:
#      $  makeblastdb -in pep.fa -dbtype 'prot' -out DATABASE_pep
#      $  makeblastdb -in TAIR10.fa -dbtype 'nucl' -out DATABASE_TAIR10


def sequences (file) #this function allows to retrive each sequence of a file in a table
    string=''
    tab = []
    nb=0
    exp = Regexp.new(">")
    File.open(file, 'r') do |file|
        file.each do |line|
            if line.match(exp)
                if nb!=0
                    tab+= [string]
                end
                string=line
                nb=1
            else
                string+=line.chomp #to remove each \n in the sequence
            end
        end
        tab+= [string]
    end
    return tab
end

factory_pep = Bio::Blast.local('blastx', 'Databases_pep/DATABASE_pep')
factory_TAIR10 = Bio::Blast.local('tblastn', 'Databases_TAIR10/DATABASE_TAIR10')
#explations of blastx and tblastn in the .pdf Explanation.

pep_seqs= sequences('pep.fa')
tair10_seqs= sequences('TAIR10.fa')

orthologs=[]
pep_seqs.each do |s|
    dic_evaluesp={} #dictionnary which will contains evalues of each blast results to then select the minimum one (the better one)
    find = StringIO.new(s) #input sequence
    ff = Bio::FlatFile.auto(find)
    ff.each do |entryp| #Bio::FastaFormat
        report = factory_TAIR10.query(entryp) # this is a Bio::Blast::Report
        # Iterates over each hit
        report.each do |hit|
            next unless hit.evalue < 10e-2 #Selection of this parameter to considered two protein as homologs (found online), explanation in the .pdf Explanation.
            target=hit.target_def.split('|')[0].strip #retrieve the identifier of the protein corresponding of the database 
            dic_evaluesp[target]=hit.evalue #retrive the identifier and the evalue of every homologs did with the sequence s against the database
        end
        if !dic_evaluesp.empty?() #in this part, I'm going to check if the best homolog of this sequence, if there is one, is reciprocal
            id_pep=entryp.entry_id
            id_homolog =dic_evaluesp.select{|k,v| v == dic_evaluesp.values.min}.keys[0] #retrieve the identifier corresponding with the minimum evalue = the best homolog
            tair10_seqs.each do |st|
                dic_evaluest={}
                find2 = StringIO.new(st) #input sequence
                ff2 = Bio::FlatFile.auto(find2)
                ff2.each do |entryt| #Bio::FastaFormat
                    if entryt.entry_id==id_homolog #I just want to look the best homolog of the sequence s and check if it's reciprocal
                        #when I found the sequence corresponding to this best homolog, I can realise the blast against the pep database
                        report = factory_pep.query(entryt) # this is a Bio::Blast::Report
                        # Iterates over each hit
                        report.each do |hitt|
                            next unless hitt.evalue < 10e-2
                            target=hitt.target_def.split('|')[0].strip
                            dic_evaluest[target]=hitt.evalue  
                        end
                        if !dic_evaluesp.empty?()
                            id_t=entryt.entry_id
                            id_homolog2=dic_evaluest.select{|k,v| v == dic_evaluest.values.min}.keys[0] #retrieve the identifier corresponding with the minimum evalue = the best homolog
                            if id_homolog2==id_pep && id_t==id_homolog #check if it's reciprocal = orthologs
                                puts
                                puts "###################################################################################"
                                puts
                                puts "#{id_pep} and #{id_t} are orthologs : "
                                puts "Sens 1 : #{id_pep} -> #{id_homolog} with a evalue = #{dic_evaluesp.select{|k,v| v == dic_evaluesp.values.min}.values[0]}"
                                puts "Sens 2 : #{id_t} -> #{id_homolog2} with a evalue = #{dic_evaluest.select{|k,v| v == dic_evaluest.values.min}.values[0]}"
                                orthologs+= ["#{id_pep} and #{id_t} are orthologs" ]
                            end
                        end
                    end
                end
            end
        end
    end
end

#create a report with all orthologs
File.open("orthologs_report.txt", "w") do |f|
    orthologs.each do |orth|
        f.write(orth) 
    end
end 