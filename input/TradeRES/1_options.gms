Options

// Solution gap: the first one reached will end iteration
optca = 0       // Absolute gap between the found solution and the best possible solution
optcr = 0.005  // Relative gap between the found solution and the best possible solution

// Solver options
Solvelink = %Solvelink.ChainScript%

threads = -1          // How many cores the solver can use: 0 = all cores; negative values = all cores - n
solprint = On          // Don't print a lot of stuff into .lst?
ResLim = 18000
;

