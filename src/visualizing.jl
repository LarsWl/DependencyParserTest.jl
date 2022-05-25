module Visualizing
  # using Graphs
  # using NetworkLayout
  # using GLMakie
  # using GraphMakie

  using ..Sources
  using ..DependencyTree
  using ..Converting

  function visualize(source::AbstractSource, file_title::String)
    sentences = Converting.convert(source) |> (text -> split(text, r"SENTENCE_END")) .|> strip

    for (index, sentence) in enumerate(sentences)
      filename = "$(file_title)_$(index).pdf"
      draw_sentence_graph(sentence, filename)
    end
  end

  function draw_sentence_graph(sentence, filename::String)
    g = Graphs.SimpleDiGraph()
    add_vertex!(g)
    nodelabel = ["ROOT-0"]
    edgelabel = Vector{String}()
    lines = split(sentence, "\n")

    foreach(lines) do line
      _, _, token = split(line)
      add_vertex!(g)
      push!(nodelabel, token)
    end

    for (index, line) in enumerate(lines)
      dependency_label, head_token, = split(line)
      head_index = findfirst(token -> head_token == token, nodelabel)

      push!(edgelabel, dependency_label)
      add_edge!(g, head_index , index + 1)
    end
    

    GraphMakie.graphplot(
      g,
      nlabels=nodelabel,
      nlabels_distance = 15,
      elabels = edgelabel,
      layout=NetworkLayout.Buchheim(),
      elabels_rotation=0,
      elabels_distance=25
    )
  end
end