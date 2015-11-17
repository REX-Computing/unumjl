#kernel.jl

#creates the unum kernels.
const register_width = 40
const register_count = 4
const registers = [zeros(UInt64, register_width) for idx=1:register_count]
