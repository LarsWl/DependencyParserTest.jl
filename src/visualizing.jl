module Visualizing
  using Graphs
  using Cairo
  using Compose
  using GraphPlot

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

      push!(edgelabel, dependency_label)
      add_edge!(g, findfirst(token -> head_token == token, nodelabel), index + 1)
    end

    layout=(args...)->spring_layout(args...; C=9)

    plot = gplot(
      g, 
      nodelabel=nodelabel, 
      edgelabel=edgelabel, 
      nodelabeldist=1.7, 
      linetype="curve",
      layout=layout,
      arrowlengthfrac=0.05,
      arrowangleoffset= π/18
    )

    draw(PDF(filename, 30cm, 30cm), plot)
  end
end