fu! s:setup()
ruby << RUBY
$nyao_ignore_abbrev = false

class NyaoAutoAbbrev
  WORD = /[A-Za-z_]/
  NOTWORD = /[^A-Za-z_]/

  def initialize
    lines = Ev.getline(1, '$')
    @words = []

    #Ev.getline(1, '$').each do |l|
    #  m = l.match /^\s*(class|module|def)\s(self\.)*([A-z_0-9]+)/
    #  @words << m[3] if m && m[3]

    #  # constants
    #  m = l.match /^\s*([A-Z_0-9]+)\s/
    #  @words << m[1] if m && m[1]
    #end
  end

  class CurrentLine
    attr_accessor :col, :line

    def initialize
      @col  = Ev.col('.')
      @line = Ev.getline('.')
    end

    def length
      line.length
    end

    def display
      [
        col,
        line.inspect,
        " " * (col) + "^",
        previous_char.inspect,
        previous_word_ri.inspect,
        previous_word_ri_char.inspect,
        previous_word_li.inspect,
        previous_word_li_char.inspect,
        previous_word.inspect,
        # replace_previous_word("hello world"),
        # " " * (col) + "^",
      ].each do |x|
        TextDebug << x
      end
    end

    def previous_char
      # the insertion point is to the LEFT of the col number.
      # meaning when inserting at the end of the line, the col number
      # refers to a point beyond the current line.
      if col > line.length
        line.chars[-1]
      elsif col == line.length
        line.chars[-2]
      elsif col == 1
        # there is no previous character before col 1, so I guess this should
        # be empty or nil
        ""
        # line[0]
      else
        line[col-2] # one before cursor, adjust one for 0-index
      end
    end

    # more baggage relating just to our purposes, this is the two characters
    # before the trigger character (a space, dot etc) so we can check for an
    # escape sequence
    def previous_two_char
      if col > line.length
        line[-3..-2]
      elsif col == line.length
        line[-4..-3]
      elsif col == 1
        ""
      elsif col == 2
        line[0]
      else
        line[col-4..col-3]
      end || ""
    end

    # in the middle of a word we return nil because we don't want to
    # autocomplete, although that adds some baggage to the meaning of this
    # method beyond its name
    def previous_word_ri
      i = col - 2 # apply index offset and move index LEFT of insert point
      return nil if line[i+1]&.match? WORD

      while i > 0 && line[i].match?(NOTWORD) do
        i -= 1
      end
      i == -1 ? nil : i
    end
    def previous_word_ri_char = previous_word_ri ? line[ previous_word_ri ] : ''

    def previous_word_li
      return nil unless previous_word_ri
      i = previous_word_ri
      while i > 0 && line[i-1].match?(WORD) do
        i -= 1
      end
      i
    end
    def previous_word_li_char = previous_word_li ? line[ previous_word_li ] : ''

    def previous_word
      return "" unless previous_word_ri
      line[previous_word_li..previous_word_ri]
    end

    def replace_previous_word str
      return nil unless previous_word_ri
      old_length = previous_word_ri - previous_word_li
      new_length = str.length
      diff_length = new_length - old_length - 1 # offset index
      line[previous_word_li..previous_word_ri] = str
      @col = @col + diff_length
      Ev.setline('.', line)
      line
    end

    def clear_previous_two_char
      line[col-4..col-3] = ""
      @col = @col - 2
      Ev.setline('.', line.sq)
      line
    end

    def reset_cursor
      # different versions of vim might have different arguments for this
      # function
      Ev.setcursorcharpos(Ev.line('.'), col)
    end

     # <End>		cursor to after last char in the line	     *i_<End>*
     # inoremap <expr> <C-E> col('.')>strlen(getline('.'))<bar><bar>pumvisible()?"\<Lt>C-E>":"\<Lt>End>"
  end

  def run
    TextDebug.clear
    cl = CurrentLine.new
    return if cl.length < 2
    # ignore exactly one "run" statement recieved from TextChangedI
    if $nyao_ignore_abbrev
      $nyao_ignore_abbrev = false
      return
    end

    # when typing \\ after a normally triggering abbrev, remove \\ and proceed
    # as normal
    if cl.previous_two_char == '\\\\'
      cl.clear_previous_two_char
      cl.reset_cursor
      $nyao_ignore_abbrev = true
    else
      lc = cl.previous_char
      return unless ' .()[]'.include? lc

      c = cl.previous_word
      if c && c.length < 4 && !['of', 'it', 'in', 'an', 'and', 'get', 'to', 'for' 'my', 'the', 'end', 'me', 'ok', 'oh'].include?(c)
        # lines = Ev.getline(Ev.line('.')-5, Ev.line('.')+5)

        distance = 5
        above = Ev.getline( Ev.line('.')-distance, Ev.line('.')-1)
        below = Ev.getline( Ev.line('.')+1, Ev.line('.')+distance)
        nearby_words = [ Ev.getline('.') ]
        (0..(distance-1)).each do |i|
          nearby_words << above[distance-i-1]
          nearby_words << below[i]
        end
        # TextDebug << nearby_words.inspect
        # nearby_words = [
        #   Ev.getline( Ev.line('.') ), # current line
        #   Ev.getline( Ev.line('.')-1 ), # line above
        #   Ev.getline( Ev.line('.')+1 ), # line below
        #   Ev.getline( Ev.line('.')-2 ), # etc
        #   Ev.getline( Ev.line('.')+2 ),
        #   Ev.getline( Ev.line('.')-3 ),
        #   Ev.getline( Ev.line('.')+3 ),
        #   Ev.getline( Ev.line('.')-4 ),
        #   Ev.getline( Ev.line('.')+4 ),
        #   Ev.getline( Ev.line('.')-5 ),
        #   Ev.getline( Ev.line('.')+5 ),
        # ]
        nearby_words.compact!
        nearby_words.map!.with_index do |l, i|
          l = i == 0 ? l.split(NOTWORD).reject {|x| x == c } : l.split(NOTWORD)
          l.uniq!
          l.select! {|w| w != ''  }
          l
        end

        # TextDebug << nearby_words.inspect

        return if nearby_words.find {|w| w == c }

        w = case c.length
            when 1
              nearby_words[0].flatten.find {|w| w.downcase.start_with? c }
            when 2
              nearby_words[0..2].flatten.find {|w| w.downcase.start_with? c }
            when 3
              nearby_words[0..-1].flatten.find {|w| w.downcase.start_with? c }
            end

        return unless w

        # cl.display
        cl.replace_previous_word w
        cl.reset_cursor
      end
    end
  end
  def self.backspace
    $nyao_ignore_abbrev = true
    l = Ev.getline
    # bug
    cn = Ev.col('.')
    if cn == l.length # our cursor is past the end of the line
      l[-1] = ''
      Ev.setline('.', l)
    else # our cursor is in the middle of a line
      l[Ev.col('.')-2] = ''
      Ev.setline('.', l)
      Ev.feedkeys "OD"
    end
  end
end

NyaoAutoAbbrev.new
RUBY
endfu

call s:setup()

augroup NyaoAutoAbbrev
    autocmd!
    autocmd InsertEnter * ruby $nyao_abbrev = NyaoAutoAbbrev.new
    autocmd TextChangedI * ruby $nyao_abbrev.run
augroup END

