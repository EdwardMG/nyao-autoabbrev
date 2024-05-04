fu! s:setup()
ruby << RUBY
$nyao_ignore_abbrev = false

class NyaoAutoAbbrev
  def initialize
    @words = Ev.getline(1, '$').map {|l| l.split(/[^A-z_]/) }.flatten.select {|w| w != '' && w.length > 4 }
  end

  def run
    # ignore exactly one "run" statement recieved from TextChangedI
    if $nyao_ignore_abbrev
      $nyao_ignore_abbrev = false
      return
    end

    l = Ev.getline('.')

    # when typing ,, after a normally triggering abbrev, remove ,, and proceed
    # as normal
    if l[-3..-2] == ',,'
      l[-3..-2] = ''
      $nyao_ignore_abbrev = true
      Ev.setline '.', l.gsub(/"/, '\\"')
      Ev.feedkeys "OC"
    else
      lc = l[-1]
      return unless lc == ' ' || lc == '.' || lc == '(' || lc == '['

      c = l.split(/[ .(\[]/).last
      if c && c.length < 5
        w = @words.find {|w| w.downcase.start_with? c }
        return unless w

        l[-(c.length+1)..-2] = w
        Ev.setline '.', l.gsub(/"/, '\\"')
        Ev.feedkeys ""
      end
    end
  end
end
RUBY
endfu

call s:setup()

augroup NyaoAutoAbbrev
    autocmd!
    autocmd InsertEnter * ruby $nyao_abbrev = NyaoAutoAbbrev.new
    autocmd TextChangedI * ruby $nyao_abbrev.run
augroup END
