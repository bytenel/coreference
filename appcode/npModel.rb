require 'java'
require 'rules.rb'

include Java
require '../stanford-ner-2012-07-09/stanford-ner.jar'
java_import 'edu.stanford.nlp.ie.crf.CRFClassifier'

# poro for handling info... i like strongly typed for this stuff
class NpModel
  #ref is a reference to another NpModel...
  attr_accessor :id,:startIdx,:endIdx,:sentIdx,:phrase,:sent,
		:ref,:included,:coref,:position,:pronounType,
	       	:article,:appositive,:plurality,:properName,
	       	:semanticClass,:gender,:animacy,:headNoun
  
  classifierRoute = "../stanford-ner-2012-07-09/classifiers/english.all.3class.distsim.crf.ser.gz"
  @@classifier = CRFClassifier.getClassifierNoExceptions(classifierRoute)

  #sent model, 
  #probably should pass in the parse tree from the orig np sent parse
  #to make certain identifications easier
  def initialize(id, startIdx, endIdx, phrase, sent)
    @id = id
    @startIdx = startIdx
    @endIdx = endIdx
    @phrase = phrase
    @sent = sent #this is the sentence of the np right?
    identifyPlurality
    identifySemanticClass
    identifyAppositive
  end

  def to_s 
    "#{phrase}"
  end
 
  def identifyPlurality
    words = @phrase.split(/\s+/)

    idx = words.length
    wordLength = words[idx-1].length
    if words[idx-1][wordLength-1] == 's'
      @plurality = true
    else
      @plurality = false
    end
  end

  #prob will need to be refactored later
  #returns true if matched an article, false if no article
  def identifyArticle
    a_regex = /\s+a\s+/
    an_regex = /\s+an\s+/
    the_regex = /\s+the\s+/
    
    if(a_regex.match(@phrase))
	@article = "a" 
	return true	
    elsif(an_regex.match(@phrase))
	@article = "an" 
	return true	
    elsif(the_regex.match(@phrase))
	@article = "the" 
	return true	
    else
	@article = "NONE"
    end

    false
  end 

  #using appositive definition from clustering algorithm 
  def identifyAppositive
    #if np is surrounded by commas

    if @startIdx > 0
      if @sent.sent[@startIdx-1] == ","
        @appositive = true
      end
    elsif phrase.chars.to_a[0] == ","
      @appositive = true
    else
      @appositive = false
    end
    
    return
    
    tempStatus = false
    sentence = @sent 
    phrase = @phrase

    #hey man, I don't think we need to do all this
    regex = /,[\s]#{phrase},/
      
    if(regex.match(sentence) != nil)
      #contains an article
      if(identifyArticle)
        #and is immediately preceded by another noun phrase
	      #penn output has commas like (, ,) ie. (ADVP (RB Man)) (, ,) etc.
	      treebank_arr = treebank_parse.split('(, ,)')
	      regex_builder = ""
	      phrase.split(' ').each do |word|

        if(regex_builder.length > 0)
          regex_builder << ".*"
        end
        regex_builder << word	    
      end

	    nRegex = /#{regex_builder}/
	    treebank_arr.each do |parse|
	    if(nRegex.match(parse) != nil)
		    idx = treebank_arr.index(parse) - 1
		  
        if(idx >= 0)
          npRegex = /\(NP/
		    
          if(npRegex.match(treebank_arr[idx]))
            #then it is marked as an appositive
			     tempStatus = true
		      end	      
        end
      end
    end
  end
end
  @appositive = tempStatus
  tempStatus
end

  #checks if all words have capitol starting
  #and/or semantic class == 'PERSON'
  def identifyProperName
    words = @phrase.split(' ')

    #this maybe should change to not check semanticClass
    #depends on how the NER system is going to be accurate or not
    #...we'll see
    tempStatus = true unless(@semanticClass != "PERSON") 
    capRegex = /^[A-Z]/
    
    words.each do |word|
	if(capRegex.match(word) != nil)
	    tempStatus = true
	end	    
    end

    @properName = tempStatus
    
    tempStatus
  end

  #going the stanford ner route as that seems simplest to import
  #returns true if identified, false if unknown
  def identifySemanticClass
    #just going to do NER on the phrase for now, prob could change this to doing it on the whole sentence at some point and see if accuracy changes 
     classifiedPhrase = @@classifier.classifyToString(@phrase) 
     classHash = {}
     #build the hash
     classifiedPhrase.split(' ').each do |word|
	  k,v = word.split('/')
	  unless classHash[v] == nil
	      classHash[v] += 1
	  else
	      classHash[v] = 1
	  end
     end	 

     theoreticalNER = classHash.max_by { |k,v| v }
     unless theoreticalNER[0] == 'O'
	 @semanticClass = theoreticalNER[0]
     else
	 @semanticClass = 'UNKNOWN'
	 return false
     end
     
     true
  end

  #TODO identify the gender of the phrase (or should it be the head noun? could
  #	prob try both).
  def identifyGender

  end

  #TODO identify if the noun phrase is animate or not
  def identifyAnimacy

  end

  #for the purposes of the clustering algorithm, the last word in the np is considered the head noun
  def identifyHeadNoun
     words = @phrase.split(' ')
     @headNoun = words[words.length-1]

     true
  end

  def findBestMatch(allSentences)
    #candidates are all the words that come before current 


  end
end
