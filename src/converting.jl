module Converting
  using ..Sources

  function convert(source::ConlluSource)
    sentences = open(f -> read(f, String), source.filename) |> (text -> split(text, r"# sent_id.+\n"))

    sentences = map(sentences) do sentence
      words = split(sentence, "\n") |> 
          (words -> filter(word -> (length(word) > 1) && 
          !(occursin(r"(text = )|(\d+-\d+)", word)), words)) .|> 
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

      return join(words, "\n")
    end
    deleteat!(sentences, 1)

    join(sentences, "\nSENTENCE_END\n")
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

  function convert(source::CoreNLPSource)
    lines = readlines(source.filename) .|> 
      (sentence -> (replace(sentence, r"[()]" => " ") |>
      (sentence -> replace(sentence, r"," => ""))))
    
    new_lines = []

    foreach(lines) do line
      words = split(line)

      if length(words) != 3
        push!(new_lines, "SENTENCE_END")
      else
        push!(new_lines, join(words, " "))
      end
    end
    deleteat!(new_lines, length(new_lines))
    join(new_lines, "\n")
  end
end
