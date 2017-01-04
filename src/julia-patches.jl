#patches onto julia that should probably be committed upstream.

#from ./linalg/generic.jl
function Base.istriu{F <: Utype}(A::AbstractMatrix{F})
    m, n = size(A)
    for j = 1:min(n,m-1), i = j+1:m
        if A[i,j] != zero(F)
            return false
        end
    end
    return true
end

function Base.istril{F <: Utype}(A::AbstractMatrix{F})
    m, n = size(A)
    for j = 2:n, i = 1:min(j-1,m)
        if A[i,j] != zero(F)
            return false
        end
    end
    return true
end

import Base.LinAlg.BlasInt
import Base.LinAlg.LU

#from ./linalg/lu.jl
function Base.LinAlg.generic_lufact!{T <: Utype,Pivot}(A::StridedMatrix{T}, ::Type{Val{Pivot}} = Val{true})
    m, n = size(A)
    minmn = min(m,n)
    info = 0
    ipiv = Array{BlasInt}(minmn)
    @inbounds begin
        for k = 1:minmn
            # find index max
            kp = k
            if Pivot
                amax = real(zero(T))
                for i = k:m
                    absi = abs(A[i,k])
                    if absi > amax
                        kp = i
                        amax = absi
                    end
                end
            end
            ipiv[k] = kp
            if A[kp,k] != zero(T)
                if k != kp
                    # Interchange
                    for i = 1:n
                        tmp = A[k,i]
                        A[k,i] = A[kp,i]
                        A[kp,i] = tmp
                    end
                end
                # Scale first column
                Akkinv = inv(A[k,k])
                for i = k+1:m
                    A[i,k] *= Akkinv
                end
            elseif info == 0
                info = k
            end
            # Update the rest
            for j = k+1:n
                for i = k+1:m
                    A[i,j] -= A[i,k]*A[k,j]
                end
            end
        end
    end
    LU{T,typeof(A)}(A, ipiv, convert(BlasInt, info))
end
