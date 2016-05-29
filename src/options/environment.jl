#environment.jl - gets the esizesize and fsizesize variables.
################################################################################

doc"""
`Unums.environment` outputs the current environment as the appropriate Unum type
"""
function environment()
  Unum{options[:env_ESS], options[:env_FSS]}
end

doc"""
  `Unums.setenvironment` sets the current environment as the appropriate Unum type
"""
function setenvironment(ESS, FSS)
  options[:env_ESS] = ESS
  options[:env_FSS] = FSS
end
