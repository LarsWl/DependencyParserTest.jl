module Converting
  using ..Sources

  function convert(source::ConlluSource)
    parsed_sentences = []

    parse_sentence = (sentence_lines) -> begin
      words = filter(word -> (length(word) > 1) && !(occursin(r"^(# |(\d+\-\d+)|(\d+\.\d+))", word)), sentence_lines) .|> 
        (word -> split(word, r"\t")) |>
        (words -> map(word -> [word[1], word[2], word[7], word[8]], words))

      words = map(words) do word
        dependent_word_number = word[1]
        dependent_word = word[2]
        dependent_word_label = string(dependent_word, "-", dependent_word_number)

        head_word_number = word[3]
        if head_word_number == "0"
          head_word = "ROOT"
        else
          head_word = words[findfirst(hword -> hword[1] == word[3], words)][2]
        end
        head_word_label = string(head_word, "-", head_word_number)

        dependency = word[4]

        return join([dependency, head_word_label, dependent_word_label], " ")
      end

      push!(parsed_sentences, join(words, "\n"))
    end

    open(source.filename) do file
      sentence_lines = []
    
      while !eof(file)
        line = readline(file)
    
        if !occursin(r"^\s*$", line)
          push!(sentence_lines, line)
        else
          parse_sentence(sentence_lines)
          sentence_lines = []
        end
      end
    end

    join(parsed_sentences, "\nSENTENCE_END\n")
  end

  function convert(source::SpacySource)
    sentences = open(f -> read(f, String), source.filename) |> (text -> split(text, r"SENTENCE END")) .|> strip
    deleteat!(sentences, length(sentences))
    
    sentences = map(sentences) do sentence
      map(enumerate(split(sentence, "\n"))) do (index, word)
        word = split(word)
        dependent_word = replace(word[1], r"TOKEN:" => "") |> strip
        dependency = replace(word[2], r"DEP:" => "") |> strip |> lowercase
        head_word = replace(word[3], r"HEAD:" => "") |> strip
  
        dependent_word = replace(dependent_word, r"-\d+" => "-$(index)")
  
  
        head_word_index = findfirst(word -> 
        ((replace(split(word)[1], r"TOKEN:" => "") 
            |> strip) == head_word), split(sentence, "\n"))
        if startswith(head_word, "ROOT")
          head_word_index = 0
        end
  
        head_word = replace(head_word, r"-\d+" => "-$(head_word_index)")
  
        return join([dependency, head_word, dependent_word], " ")
      end |> (sentence -> join(deleteat!(sentence, length(sentence)), "\n"))
    end |> (sentences -> join(sentences, "\nSENTENCE_END\n"))
  
    return sentences
  end

  function convert(source::StanzaSource)
    sentences = open(f -> read(f, String), source.filename) |> (text -> split(text, r"SENTENCE END")) .|> strip
    deleteat!(sentences, length(sentences))
    
    sentences = map(sentences) do sentence
      map(enumerate(split(sentence, "\n"))) do (index, word)
        word = split(word)
        dependent_word = replace(word[1], r"TOKEN:" => "") |> strip
        dependency = replace(word[2], r"DEP:" => "") |> strip |> lowercase
        head_word = replace(word[3], r"HEAD:" => "") |> strip
  
        dependent_word = replace(dependent_word, r"-\d+" => "-$(index)")
  
  
        head_word_index = findfirst(word -> 
        ((replace(split(word)[1], r"TOKEN:" => "") 
            |> strip) == head_word), split(sentence, "\n"))
        if startswith(head_word, "ROOT")
          head_word_index = 0
        end
  
        head_word = replace(head_word, r"-\d+" => "-$(head_word_index)")
  
        return join([dependency, head_word, dependent_word], " ")
      end |> (sentence -> join(sentence, "\n"))
    end |> (sentences -> join(sentences, "\nSENTENCE_END\n"))
  
    return sentences
  end

  function convert(source::CoreNLPSource)
    lines = readlines(source.filename) |> lines -> map(line -> match(r"^(.*)\((.*), (.*)\)", line), lines)
    
    new_lines = []

    foreach(lines) do line
      if line === nothing
        push!(new_lines, "SENTENCE_END")
      else
        push!(new_lines, join(line, " "))
      end
    end
    deleteat!(new_lines, length(new_lines))
    join(new_lines, "\n")
  end

  function extract_sentences_from_conllu(filename)
    sentence_lines = []

    open(filename) do file
      while !eof(file)
        line = readline(file)
    
        if occursin(r"# text = ", line)
          push!(sentence_lines, replace(line, r"# text = " => ""))
        end
      end
    end

    join(sentence_lines, "\n")
  end
end
