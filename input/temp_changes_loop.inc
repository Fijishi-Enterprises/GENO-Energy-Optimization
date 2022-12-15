
// This is a template of a additional file that is read once per loop
// allowing specific adjustement in models that run over several loops, 
// e.g. schedule model that has 365 loops in a year if run with 24h jumps.



* These rows fix storage value at a hour 't008760' to a given value.
* More examples can be found from 3d_setVariableLimits.gms.
* NOTE: example uses hard coded storage names that must match the data, otherwise model crashes.
* NOTE: when the model runs schedule run and uses aggregated time steps, 't008760' does not always exist.
*       The sum inside if condition ${ } converts an user given hour to a aggregated time step.
* NOTE: 3b_periodicLoop clears v_state. Otherwise the fixed state would remain in wrong hours in furhter loops.
* grid = 'hydro'
* node = 'country_hydro'
* t_ = 't008760'


v_state.fx('hydro', 'country_hydro', sft(s, f, t)) $ { tt_aggregate(t, 't008760') }
     = 2e6 ;

* NOTE: Adding this constaint to P2Xdemo model resulted to an error "LP status(5): optimal with unscaled infeasibilities".
*       This can be fixed by adding "scaind = -1" to cplex.opt. See Error fixing page in wiki.