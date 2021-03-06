require 'whittle'

module PGN
  # {PGN::Parser} uses the whittle gem to parse pgn files based on their
  # context free grammar.
  #
  class Parser < Whittle::Parser
    rule(:wsp => /\s+/).skip!

    rule("[")
    rule("]")
    rule("(")
    rule(")")

    start(:pgn_database)

    rule(:pgn_database) do |r|
      r[].as { [] }
      r[:pgn_game, :pgn_database].as {|game, database| database << game }
    end

    rule(:pgn_game) do |r|
      r[:tag_section, :movetext_section].as {|tags, moves| {tags: tags, result: moves.pop, moves: moves} }
    end

    rule(:tag_section) do |r|
      r[:tag_pair, :tag_section].as {|pair, section| section.merge(pair) }
      r[:tag_pair]
    end

    rule(:tag_pair) do |r|
      r["[", :tag_name, :tag_value, "]"].as {|_, a, b, _| {a => b} }
    end

    rule(:tag_value) do |r|
      r[:string].as {|value| value[1...-1] }
    end

    rule(:movetext_section) do |r|
      r[:element_sequence, :game_termination].as {|a, b| a.reverse << b }
    end

    rule(:element_sequence) do |r|
      r[:element, :element_sequence].as {|element, sequence| element.nil? ? sequence : sequence << element }
      r[].as { [] }
      #r[:recursive_variation, :element_sequence]
      #r[:recursive_variation]
    end

    rule(:element) do |r|
      r[:move_number_indication].as { nil }
      r[:san_move]
      #r[:numeric_annotation_glyph]
    end

    #rule(:recursive_variation) do |r|
      #r["(", :element_sequence, ")"]
    #end

    rule(
      :string => %r{
        "                          # beginning of string
        (
          [[:print:]&&[^\\"]] |    # printing characters except quote and backslash
          \\\\                |    # escaped backslashes
          \\"                      # escaped quotation marks
        )*                         # zero or more of the above
        "                          # end of string
      }x
    )

    rule(
      :game_termination => %r{
        1-0       |    # white wins
        0-1       |    # black wins
        1\/2-1\/2 |    # draw
        \*             # ?
      }x
    )

    rule(
      :move_number_indication => %r{
        [[:digit:]]+\.*    # one or more digits followed by zero or more periods
      }x
    )

    rule(
      :san_move => %r{
        (
          [O0](-[O0]){1,2}             |    # castling (O-O, O-O-O)
          [a-h][1-8]                   |    # pawn moves (e4, d7)
          [BKNQR][a-h1-8][a-h1-8]?x?[a-h][1-8] |    # major piece moves w/ optional specifier
                                            # and capture
                                            # (Ng8f6, NgF6, N4c3, Raxc1) Support for RHP PGN
          [a-h][1-8]?x[a-h][1-8]            # pawn captures
        )
        (
          =[BNQR]                            # optional promotion (d8=Q)
        )?
        (
          \+                            |    # check (g5+)
          \#                                 # checkmate (Qe7#)
        )?
      }x
    )

    rule(
      :tag_name => %r{
        [A-Za-z0-9_]+    # letters, digits and underscores only
      }x
    )

    rule(
      :numeric_annotation_glyph => %r{
        \$\d+    # dollar sign followed by an integer from 0 to 255
      }x
    )
  end
end
