fu! s:setup()
ruby << RUBY
$nyao_ignore_abbrev = false

class NyaoAutoAbbrev
  def initialize
    lines = Ev.getline(1, '$')
    @words = []

    Ev.getline(1, '$').each do |l|
      m = l.match /^\s*(class|module|def)\s(self\.)*([A-z_0-9]+)/
      @words << m[3] if m && m[3]

      # constants
      m = l.match /^\s*([A-Z_0-9]+)\s/
      @words << m[1] if m && m[1]
    end
  end

  def run
    # ignore exactly one "run" statement recieved from TextChangedI
    if $nyao_ignore_abbrev
      $nyao_ignore_abbrev = false
      return
    end

    l = Ev.getline('.')

    # when typing \\ after a normally triggering abbrev, remove \\ and proceed
    # as normal
    if l[-3..-2] == '\\\\'
      l[-3..-2] = ''
      $nyao_ignore_abbrev = true
      Ev.setline '.', l.gsub(/"/, '\\"')
      Ev.feedkeys "OC"
    else
      lc = l[-1]
      return unless lc == ' ' || lc == '.' || lc == '(' || lc == '['

      # bug: [^A[ gets included in nearby words
      c = l.split(/[^A-z_]/)&.last
      if c && c.length < 5
        nearby_words = Ev.getline(Ev.line('.')-3, Ev.line('.')+3)
        nearby_words = [
          nearby_words[3], # current line
          nearby_words[2], # line above
          nearby_words[4], # line below
          nearby_words[1], # etc
          nearby_words[5],
          nearby_words[0],
          nearby_words[6],
        ]
        nearby_words.compact!
        nearby_words.map! {|l| l.split(/[^A-z_]/) }
        nearby_words.flatten!
        nearby_words.compact!
        nearby_words.select! {|w| w != '' && (w.length > 1 && w.match?(/[A-Z]/) || w.length > 3) && w != c }
        nearby_words.uniq!

        # TextDebug.clear
        # TextDebug.puts nearby_words.inspect

        w = (nearby_words + @words).find {|w| w.downcase.start_with? c }
        return unless w

        l[-(c.length+1)..-2] = w
        Ev.setline '.', l.gsub(/"/, '\\"')
        Ev.feedkeys ""
      end
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

" this doesn't quite work the way you would want, if you aren't at the end of a line
" we probably just want some easy way to turn it off completely when it gets annoying
ino <silent> <bs> <c-o>:ruby $nyao_ignore_abbrev = true && Ev.setline('.', Ev.getline('.')[0..-2])<cr>

