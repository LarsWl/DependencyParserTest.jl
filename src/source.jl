module Sources
  export AbstractSource, 
    CoreNLPSource,
    SpacySource,
    StanzaSource,
    ConlluSource

  abstract type AbstractSource; end

  struct CoreNLPSource <: AbstractSource
    filename::String
  end

  struct SpacySource <: AbstractSource
    filename::String
  end

  struct StanzaSource <: AbstractSource
    filename::String
  end

  struct ConlluSource <: AbstractSource
    filename::String
  end
end