macro typenames()
  esc(quote
    uname = options[:longform] ? ((FSS < 7) ? "UnumSmall" : "UnumLarge") : "Unum"
    gname = options[:longform] ? ((FSS < 7) ? "GnumSmall" : "GnumLarge") : "Gnum"
    bname = options[:longform] ? ((FSS < 7) ? "UboundSmall" : "UboundLarge") : "Ubound"
  end)
end
