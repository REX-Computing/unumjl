macro typenames()
  esc(quote
    uname = options[:longform] ? ((FSS < 6) ? "UnumLarge" : "UnumSmall") : "Unum"
    gname = options[:longform] ? ((FSS < 6) ? "GnumLarge" : "GnumSmall") : "Gnum"
    bname = options[:longform] ? ((FSS < 6) ? "UboundLarge" : "UboundSmall") : "Ubound"
  end)
end
