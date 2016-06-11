#options.jl  - sets up the options dictionary and methods to easily set options
#from within command line or using a unums.jl preprocessing block.
doc"""
  *Unums.options* is the associative dictionary of options for this module.
  options can be acessed or set using the associated symbols.

  * :devmode => true          sets developer mode protections on.
  * :usegnum => false         sets it so that operands return gnums
  * :env_ESS => 4             sets the default environment esizesize
  * :env_FSS => 6             sets the default environment fsizesize
  * :longform => false        outputs unum types as their long form

  NB: usegnum will eventually be set to a default "true"

  *overriding using ~/.unums.jl*

  You can specify a julia script in ~/.unums.jl which will be executed before running any unums script.  While
  this can be used for anything, you can override options using the following code:

    RexAssembly.options[*:option*] = *value*

  *overriding using command line arguments*

  RexAssembly automatically parses the command line arguments to see if the options should be set, this
  takes precedence over internal defaults and contents of ~/.unums.jl.  For example:

    >script.jl devmode=false

    >julia unumscript.jl devmode=false

  both would disable developer mode checks.
"""
const options = Dict{Symbol, Any}(
  :devmode => true,
  :usegnum => false,
  :env_ESS => 4,
  :env_FSS => 6,
  :longform => false)

#attempt to load defaults from a .unums.jl file
@linux_only isfile("$(homedir)/.unums.jl") && include("$(homedir)/.unums.jl")
@osx_only   isfile("$(homedir)/.unums.jl") && include("$(homedir)/.unums.jl")

function argparse(s)
  (s == "true") && return true
  (s == "false") && return false
  isnumber(s) && return parse(s)
end

for arg in ARGS
  arglist = split(arg,"=")
  if length(arglist) == 1
    options[symbol(arglist[1])] = true
  else
    options[symbol(arglist[1])] = argparse(arglist[2])
  end
end

################################################################################
## include code for options.

include("./environment.jl")
include("./devsafety.jl")
include("./usegnum.jl")
