require 'rest-client'
require 'bio'


def lineGFF3 (bioSeq) #function allowing to create each line with the right format for a GFF3 format and put them in a table
    tab=[]
    bioSeq.features.each do |feature|
      featuretype = feature.feature
      next unless featuretype == "repeatExon"
      locations = Bio::Locations.new(feature.position)
      loc=locations.span #put the start and the end position of the cttctt sequence (in the entire gene) in a table 
      qual = feature.assoc
      tab +=["#{qual['chr']}\tEnsembl\tcttctt_exon\t#{loc[0]}\t#{loc[1]}\t.\t#{qual['strand']}\t.\t#{qual['ID']}"]
    end
    return tab
end

def lineGFF3_fullChr (bioSeq) #function allowing to create each line with the right format and with the position correponding to full chromosomes for a GFF3 format and put them in a table
    tab=[]
    bioSeq.features.each do |feature|
        featuretype = feature.feature
        start,eNd=bioSeq.primary_accession.split(":")[3..4] #take the first and the last position of the gene in the full chromosome corresponding
        next unless featuretype == "repeatExon"
        locations = Bio::Locations.new(feature.position)
        loc=locations.span
        qual = feature.assoc
        seqStart = start.to_i+loc[0]-1 #start position of cttctt sequence in the full chromosome
        seqEnd = start.to_i+loc[1]-1 #end position of cttctt sequence in the full chromosome
        tab +=["#{qual['chr']}\tEnsembl\texon\t#{seqStart}\t#{seqEnd}\t.\t#{qual['strand']}\t.\t#{qual['ID']}"]
    end
    return tab
end

def findRepeatSeq (gene) #function allowing to take the coordinates of every CTTCTT sequence of each exon of the gene and create a new Sequence Feature 
    found=false
    gene=gene.upcase
    address = "http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{gene}"
    response=RestClient.get(address)
    record = response.body

    File.open("#{gene}.embl", 'w') do |myfile|
    myfile.puts record
    end

    datafile = Bio::FlatFile.auto("#{gene}.embl")
    entry =  datafile.next_entry   # this is a way to get just one entry from the FlatFile
    bioseq = entry.to_biosequence
    chromosome = entry.accession.split(":")[2] #take the number of the chromosome corresponding to location of the gene
    bioseq.features.each do |feature|
        assoc=feature.assoc
        next unless feature.feature == "exon"
        note=assoc["note"]
        exp = Regexp.new("exon_id=#{gene}")
        if note.match(exp) #select only the exons localized in the gene
            search = Bio::Sequence::NA.new("CTTCTT")
            re = Regexp.new(search.to_re) #create regular expression for the cttctt sequence
            location = Bio::Locations.new(feature.position) #create a Bio::Locations object to make it easier to manipulate the coordinates
            exon = entry.seq.splice(feature.position) #retrieve the etire sequence of the exon
            exon.scan(re) do |m| #check if the exon match with one or more cttctt sequences
                found = true
                s=Regexp.last_match.begin(0)
                e=Regexp.last_match.begin(0)+5
                location.each do |loc|
                    if loc.strand == -1
                        strand= "-" #retrieve the negative strand
                        start = loc.to-e #retrieve the start position in all the gene of the cttctt sequence
                        eNd = loc.to-s #retrieve the end position in all the gene of the cttctt sequence
                        start1=start-3 #retrieve the start position in all the gene of the cttctt sequence which overlap the previous one
                        eNd1=eNd-3 #retrieve the end position in all the gene of the cttctt sequence which overlap the previous one
                    else
                        strand="+" #retrieve the positive strand
                        #retrieve the position but for the positive strand
                        start = loc.from+s
                        eNd = loc.from+e
                        start1=start+3
                        eNd1=eNd+3
                    end
                    f1 = Bio::Feature.new('repeatExon',"#{start}..#{eNd}") #create the new Sequence Feature
                    f1.append(Bio::Feature::Qualifier.new('repeat_motif', 'CTTCTT'))
                    f1.append(Bio::Feature::Qualifier.new('strand', "#{strand}"))
                    f1.append(Bio::Feature::Qualifier.new('ID',assoc['note']))
                    f1.append(Bio::Feature::Qualifier.new('chr',"chr#{chromosome}"))
                    bioseq.features << f1 #add the new Sequence Feature

                    exon1=exon.splice("#{s+1}..#{e+4}") #retrive the cttctt sequence + 3 nucleotides 
                    if exon1.match(/#{re}+(?=ctt)/) #check if before the cttctt sequence, the 3 nucleotides correspond to "ctt"
                        f2 = Bio::Feature.new('repeatExon',"#{start1}..#{eNd1}") #create the new Sequence Feature
                        f2.append(Bio::Feature::Qualifier.new('repeat_motif', 'CTTCTT'))
                        f2.append(Bio::Feature::Qualifier.new('strand', "#{strand}"))
                        f2.append(Bio::Feature::Qualifier.new('ID',assoc['note']))
                        f2.append(Bio::Feature::Qualifier.new('chr',"chr#{chromosome}"))
                        bioseq.features << f2 #add the new Sequence Feature
                    end
                end
            end
        end   
    end
    if found == false
        puts "The gene #{gene} don't have exons with the CTTCTT repeat." #write this report if the gene don't have exon with the cttctt sequence
    end
    return bioseq
end


record_1 = Bio::GFF::GFF3.new()
record_2 = Bio::GFF::GFF3.new()
File.foreach( 'ArabidopsisSubNetwork_GeneList.txt' ) do |gene|
    bioseq = findRepeatSeq(gene.chomp.upcase)
    lineGFF3(bioseq).each do |line1|
        record_1.parse(line1) #retrieve the content of gff file with position corresponding to the gene scale
    end
    lineGFF3_fullChr(bioseq).each do |line2|
        record_2.parse(line2) #retrieve the content of the gff file with position corresponding to the chromosome scale
    end
end

# Create new gff files 
File.open("gffonGene.gff", "w") do |gff1|
    gff1<<record_1
end
File.open("gffonfullChr.gff", "w") do |gff2|
    gff2<<record_2
end