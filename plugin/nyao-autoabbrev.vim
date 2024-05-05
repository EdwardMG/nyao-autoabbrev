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

      # c = l.split(/[ .(\[]/).last
      c = l.split(/[^A-z_]/).last
      if c && c.length < 5
        nearby_words = Ev
          .getline(Ev.line('.')-3, Ev.line('.')+3)
          .map {|l| l.split(/[^A-z_]/) }
          .flatten
          .select {|w| w != '' && w.length > 1 && w != c }
          .uniq

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

ino <silent> <bs> <c-o>:ruby $nyao_ignore_abbrev = true && Ev.setline('.', Ev.getline('.')[0..-2])<cr>

