#expwalk.jl
#returns a series of unums that are comprehensively tested for satisfying
#the boolean function bf  Uses a binary search method.
function expwalk(bf, ESS, FSS, rlow, rhigh, sign)
  res = Utype[]
  (esize, exponent) = encode_exp(rlow)
  low_exact = Unum{ESS,FSS}(z16, esize, sign, z64, exponent)
  low_ulp = unum_unsafe(low_exact, sign | UNUM_UBIT_MASK)
  (esize, exponent) = encode_exp(rhigh)
  mid_exact = Unum{ESS,FSS}(z16, esize, sign, t64, exponent)
  high_ulp = unum_unsafe(mid_exact, sign | UNUM_UBIT_MASK)

  if rlow == rhigh
    bf(low_exact) && (res = vcat(res, low_exact))
    bf(low_ulp) && (res = vcat(res, low_ulp))
    bf(mid_exact) && (res = vcat(res, mid_exact))
    !isnan(high_ulp) && bf(high_ulp) && (res = vcat(res, high_ulp))
  elseif rlow == rhigh - 1
    pres1 = expwalk(bf, ESS, FSS, rlow, rlow, sign)
    pres2 = expwalk(bf, ESS, FSS, rhigh, rhigh, sign)
    res = [res, pres1, pres2]
  else
    #println("l:", bits(low_ulp, " "))
    #println("h:", bits(high_ulp, " "))
    params = (sign != 0) ? (high_ulp, low_ulp) : (low_ulp, high_ulp)
    bres = bf(Ubound{ESS,FSS}(params...))
    if bres #then we have to try another round.
      mid = (rlow + rhigh) ÷ 2
      pres1 = expwalk(bf, ESS, FSS, rlow, mid, sign)
      pres2 = expwalk(bf, ESS, FSS, mid, rhigh, sign)
      res = [res, pres1, pres2]
    end
  end
  res
end

function subnormalwalk(bf, ESS, FSS, sign)
  res = Utype[]
  low_ulp = Unum{ESS,FSS}(z16, z16, sign | UNUM_UBIT_MASK, z64, z64)
  exact_mid = Unum{ESS,FSS}(z16, z16, sign, t64, z64)
  high_ulp = unum_unsafe(exact_mid, sign | UNUM_UBIT_MASK)
  bf(low_ulp) && (res = vcat(res, low_ulp))
  bf(exact_mid) && (res = vcat(res, exact_mid))
  bf(high_ulp) && (res = vcat(res, high_ulp))
  res
end

function fullwalk(bf, ESS, FSS)
  res = Utype[]
  res = vcat(res, expwalk(bf, ESS, FSS, min_exponent(ESS), max_exponent(ESS), UNUM_SIGN_MASK))
  res = vcat(res, subnormalwalk(bf, ESS, FSS, UNUM_SIGN_MASK))
  bf(zero(Unum{ESS,FSS})) && (res = vcat(res, zero(Unum{ESS,FSS})))
  res = vcat(res, subnormalwalk(bf, ESS, FSS, z16))
  res = vcat(res, expwalk(bf, ESS, FSS, min_exponent(ESS), max_exponent(ESS), z16))
  res
end

export expwalk, subnormalwalk, fullwalk
