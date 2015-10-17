#unum-options.jl

#the unum library comes with a set of options that can be set after calling
#import("unum.jl").  Here is where those options are declared and set to their
#defaults.

#there might be a better way to do this, e.g. with macros.

unum_options = ["development", "kernel", "arm", "lzcnt"]

function set_options(o::String)
  if o in unum_options

  end
end
