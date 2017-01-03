#add promote_rules for integers.  Necessary for triggering automatically solving systems
#of equations

import Base.promote_rule

#do this for small unums
promote_rule{ESS,FSS}(::Type{UnumSmall{ESS,FSS}}, ::Type{Int8})  = UnumSmall{ESS,FSS}
promote_rule{ESS,FSS}(::Type{UnumSmall{ESS,FSS}}, ::Type{Int16}) = UnumSmall{ESS,FSS}
promote_rule{ESS,FSS}(::Type{UnumSmall{ESS,FSS}}, ::Type{Int32}) = UnumSmall{ESS,FSS}
promote_rule{ESS,FSS}(::Type{UnumSmall{ESS,FSS}}, ::Type{Int64}) = UnumSmall{ESS,FSS}

#do this for large unums.
promote_rule{ESS,FSS}(::Type{UnumLarge{ESS,FSS}}, ::Type{Int8})  = UnumLarge{ESS,FSS}
promote_rule{ESS,FSS}(::Type{UnumLarge{ESS,FSS}}, ::Type{Int16}) = UnumLarge{ESS,FSS}
promote_rule{ESS,FSS}(::Type{UnumLarge{ESS,FSS}}, ::Type{Int32}) = UnumLarge{ESS,FSS}
promote_rule{ESS,FSS}(::Type{UnumLarge{ESS,FSS}}, ::Type{Int64}) = UnumLarge{ESS,FSS}
