fu! s:setup()
ruby << RUBY

class NyaoAutoAbbrev
  def initialize
    @words = Ev.getline(1, '$').map {|l| l.split(/[^A-z_]/) }.flatten.select {|w| w != '' && w.length > 4 }
  end

  def run
    l = Ev.getline('.')
    lc = l[-1]
    return unless lc == ' ' || lc == '.' || lc == '(' || lc == '['

    c = l.split(/[ .(\[]/).last
    if c && c.length == 2
      w = @words.find {|w| w.downcase.start_with? c }
      return unless w

      l[-3..-2] = w
      Ev.setline '.', l
      Ev.feedkeys ""
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

