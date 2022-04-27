module Benchmark
  using MD5
  using BenchmarkTools
  using ..Sources
  using ..Converting
  
  function test_accuracy(gold_data_source::AbstractSource, test_data_source::AbstractSource)
    gold_data_sentences = extract_sentences(gold_data_source)
    test_data_sentences = extract_sentences(test_data_source)

    total_labels = 0
    correct_labels = 0
    correct_vertices = 0

    for gold_data_sentence_pair in gold_data_sentences
      gold_sentence = gold_data_sentence_pair.second

      if !haskey(test_data_sentences, gold_data_sentence_pair.first)
        continue;
      end

      parsed_gold_sentence = split(gold_sentence, "\n")
      parsed_test_sentence = 
        split(test_data_sentences[gold_data_sentence_pair.first], "\n")

      for (index, gold_word_data) in enumerate(parsed_gold_sentence)
        total_labels += 1

        parsed_gold_word_data = split(gold_word_data)
        parsed_test_word_data = split(parsed_test_sentence[index])

        if (parsed_gold_word_data[2] == parsed_test_word_data[2])
          correct_vertices += 1

          if lowercase(parsed_gold_word_data[1]) == lowercase(parsed_test_word_data[1])
            correct_labels += 1
          end
        end
      end
    end
    
    uas = correct_vertices / total_labels
    las = correct_labels / total_labels

    println("UAS - $(uas)")
    println("LAS - $(las)")

    [uas, las]
  end

  function extract_sentences(source)
    sentences = Converting.convert(source) |> (text -> split(text, r"SENTENCE_END")) .|> strip
    sentences_dict = Dict()

    foreach(sentences) do sentence
      sentences_dict[sentence_id(sentence)] = sentence
    end

    sentences_dict
  end

  function sentence_id(sentence)
    split(sentence, "\n") |> 
    (words -> map(word -> split(word)[3], words)) |>
    join |>
    MD5.md5 |>
    join
  end

  function time_measure_stanza()
    #Stanza
    b = @benchmarkable stanza_call() samples=10 seconds=260
    run(b)
  end

  function stanza_call()
      run(`python3 ../stanza_parser/run_depparse_test.py`)
  end

  function time_measure_spacy(input_file, model_path)
    #Spacy
    spacy = pyimport("spacy")
    nlp = spacy.load(model_path)
    text = open(f -> read(f, String), input_file)
    b = @benchmarkable nlp_call($nlp, $text) samples=10 seconds=260
    run(b)
  end
      
  function nlp_call(nlp, text)
      nlp(text)
  end

  function time_measure_coreNLP()
    # CoreNLP
    b = @benchmarkable corenlp_call() samples=10 seconds=260
    run(b)
  end
    
  function corenlp_call()
    cd("/Users/admin/education/materials/stanford-corenlp-4.4.0")
    run(`java -cp "*" edu.stanford.nlp.parser.nndep.DependencyParser -model edu/stanford/nlp/models/parser/nndep/english_UD.gz -textFile ../test_texts/test_text.txt -outFile corenlp_parsed_result.txt`)
  end
end