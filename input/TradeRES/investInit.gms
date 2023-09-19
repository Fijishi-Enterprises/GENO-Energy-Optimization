$ontext
This file is part of Backbone.

Backbone is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Backbone is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with Backbone.  If not, see <http://www.gnu.org/licenses/>.
$offtext

* =============================================================================
* --- Model Definition - Invest -----------------------------------------------
* =============================================================================
sGroup(s, 'VRE_limit') = yes;
if (mType('invest'),
    m('invest') = yes; // Definition, that the model exists by its name

* --- Define Key Execution Parameters in Time Indeces -------------------------

    // Define simulation start and end time indeces
    mSettings('invest', 't_start') = 1;  // First time step to be solved, 1 corresponds to t000001 (t000000 will then be used for initial status of dynamic variables)
    mSettings('invest', 't_end') = 8760; // Last time step to be included in the solve (may solve and output more time steps in case t_jump does not match)

    // Define simulation horizon and moving horizon optimization "speed"
    mSettings('invest', 't_horizon') = 8760;   // How many active time steps the solve contains (aggregation of time steps does not impact this, unless the aggregation does not match)
    mSettings('invest', 't_jump') = 8760;      // How many time steps the model rolls forward between each solve

* =============================================================================
* --- Model Time Structure ----------------------------------------------------
* =============================================================================

* --- Define Samples ----------------------------------------------------------

    // Number of samples used by the model
    mSettings('invest', 'samples') = 5;

    // Clear Initial and Central samples
    ms_initial('invest', s) = no;
    ms_initial('invest', 's000') = yes;
    ms_initial('invest', 's001') = yes;
    ms_initial('invest', 's002') = yes;
    ms_initial('invest', 's003') = yes;
    ms_initial('invest', 's004') = yes;
*    ms_initial('invest', 's005') = yes;
*    ms_initial('invest', 's006') = yes;
*    ms_initial('invest', 's007') = yes;   
    ms_central('invest', s) = no;

    // Define time span of samples
    // For selecting the samples, see, for example, https://doi.org/10.1016/j.energy.2020.118585.
    // currently used: k-medoids-emthod by https://github.com/FZJ-IEK3-VSA/tsam
    // The duration of the samples can be, for example, 1 day or 1 week (24 h or 168 h).
    // The samples can have different durations.
    msStart('invest', 's000') = 1009;
    msEnd('invest', 's000') = msStart('invest', 's000') + 168;
    msStart('invest', 's001') = 2521;
    msEnd('invest', 's001') = msStart('invest', 's001') + 168;
    msStart('invest', 's002') = 3865;
    msEnd('invest', 's002') = msStart('invest', 's002') + 168;
    msStart('invest', 's003') = 5713;
    msEnd('invest', 's003') = msStart('invest', 's003') + 168;
    msStart('invest', 's004') = 7729;
    msEnd('invest', 's004') = msStart('invest', 's004') + 168;

    // Define the probability of samples
    // Probabilities are 1 in deterministic model runs.
    // It is also possible to include, for example, 3 samples from a cold year with a probability of 1/10
    // and 3 samples from a normal year year with a probability of 9/10.
    p_msProbability('invest', s) = 0;
    p_msProbability('invest', 's000') = 1;
    p_msProbability('invest', 's001') = 1;
    p_msProbability('invest', 's002') = 1;
    p_msProbability('invest', 's003') = 1;
    p_msProbability('invest', 's004') = 1;
*    p_msProbability('invest', 's005') = 1;
*    p_msProbability('invest', 's006') = 1;
//    p_msProbability('invest', 's007') = 1; 
    // Define the weight of samples
    // Weights describe how many times the samples are repeated in order to get the (typically) annual results.
    // For example, 3 samples with equal weights and with a duration of 1 week should be repeated 17.38 times in order
    // to cover the 52.14 weeks of the year.
    // Weights are used for scaling energy production and consumption results and for estimating node state evolution.
    p_msWeight('invest', s) = 0;
    p_msWeight('invest', 's000') = 11.14;
    p_msWeight('invest', 's001') = 9;
    p_msWeight('invest', 's002') = 6;
    p_msWeight('invest', 's003') = 16;
    p_msWeight('invest', 's004') = 10;
 //   p_msWeight('invest', 's007') = 1;  
    // Define the weight of samples in the calculation of fixed costs
    // The sum of p_msAnnuityWeight should be 1 over the samples belonging to the same year.
    // The p_msAnnuityWeight parameter is used for describing which samples belong to the same year so that the model
    // is able to calculate investment costs and fixed operation and maintenance costs once per year.
    p_msAnnuityWeight('invest', s) = 0;
    p_msAnnuityWeight('invest', 's000') = 1/5;
    p_msAnnuityWeight('invest', 's001') = 1/5;
    p_msAnnuityWeight('invest', 's002') = 1/5;
    p_msAnnuityWeight('invest', 's003') = 1/5;
    p_msAnnuityWeight('invest', 's004') = 1/5;
*    p_msAnnuityWeight('invest', 's005') = 168/8760;
*    p_msAnnuityWeight('invest', 's006') = (8760-2*168)/5/8760;
 //   p_msAnnuityWeight('invest', 's007') = /8760;

* --- Define Time Step Intervals ----------------------------------------------

    // Define the duration of a single time-step in hours
    mSettings('invest', 'stepLengthInHours') = 1;

    // Define the time step intervals in time-steps
    mInterval('invest', 'stepsPerInterval', 'c000') = 1;
    mInterval('invest', 'lastStepInIntervalBlock', 'c000') = 8760;

* --- z-structure for superpositioned nodes ----------------------------------

    // number of candidate periods in model
    // please provide this data
    mSettings('invest', 'candidate_periods') = 0;

    // add the candidate periods to model
    // no need to touch this part
    mz('invest', z) = no;
    loop(z$(ord(z) <= mSettings('invest', 'candidate_periods') ),
       mz('invest', z) = yes;
    );

    // Mapping between typical periods (=samples) and the candidate periods (z).
    // Assumption is that candidate periods start from z000 and form a continuous
    // sequence.
    // please provide this data
    zs(z,s) = no;

* =============================================================================
* --- Model Forecast Structure ------------------------------------------------
* =============================================================================

    // Define the number of forecasts used by the model
    mSettings('invest', 'forecasts') = 0;

    // Define which nodes and timeseries use forecasts
    //Option clear = gn_forecasts;  // By default includes everything, so clear first
    //gn_forecasts('wind', 'XXX', 'ts_cf') = yes;

    // Define forecast properties and features
    mSettings('invest', 't_forecastStart') = 0;                // At which time step the first forecast is available ( 1 = t000001 )
    mSettings('invest', 't_forecastLengthUnchanging') = 0;     // Length of forecasts in time steps - this does not decrease when the solve moves forward (requires forecast data that is longer than the horizon at first)
    mSettings('invest', 't_forecastLengthDecreasesFrom') = 0;  // Length of forecasts in time steps - this decreases when the solve moves forward until the new forecast data is read (then extends back to full length)
    mSettings('invest', 't_forecastJump') = 0;                 // How many time steps before new forecast is available

    // Define Realized and Central forecasts
    mf_realization('invest', f) = no;
    mf_realization('invest', 'f00') = yes;
    mf_central('invest', f) = no;
    mf_central('invest', 'f00') = yes;

    // Define forecast probabilities (weights)
    p_mfProbability('invest', f) = 0;
    p_mfProbability(mf_realization('invest', f)) = 1;

    // Define active model features
    active('invest', 'storageValue') = yes;

* =============================================================================
* --- Model Features ----------------------------------------------------------
* =============================================================================

* --- Define Reserve Properties -----------------------------------------------

    // Lenght of reserve horizon
    mSettingsReservesInUse('invest', resType, up_down) = no;
    //mSettingsReservesInUse('invest', 'primary', 'up') = no;

* --- Define Unit Approximations ----------------------------------------------

    // Define the last time step for each unit aggregation and efficiency level (3a_periodicInit.gms ensures that there is a effLevel until t_horizon)
    mSettingsEff('invest', 'level1') = inf;

    // Define the horizon when start-up and shutdown trajectories are considered
    mSettings('invest', 't_trajectoryHorizon') = 0;

* --- Define output settings for results --------------------------------------

    // Define the length of the initialization period. Results outputting starts after the period. Uses ord(t) > t_start + t_initializationPeriod in the code.
    mSettings('invest', 't_initializationPeriod') = 0;  // r_state and r_online are stored also for the last step in the initialization period, i.e. ord(t) = t_start + t_initializationPeriod

* --- Define the use of additional constraints for units with incremental heat rates

    // How to use q_conversionIncHR_help1 and q_conversionIncHR_help2
    mSettings('invest', 'incHRAdditionalConstraints') = 0;
    // 0 = use the constraints but only for units with non-convex fuel use
    // 1 = use the constraints for all units represented using incremental heat rates

* --- Control the solver ------------------------------------------------------

    // Control the use of advanced basis
    mSettings('invest', 'loadPoint') = 0;  // 0 = no basis, 1 = latest solve, 2 = all solves, 3 = first solve
    mSettings('invest', 'savePoint') = 0;  // 0 = no basis, 1 = latest solve, 2 = all solves, 3 = first solve

); // END if(mType)


* Defining sets and parameters related to extreme periods
* 0, 14, 17, 21, 43, 30, 44
* 0, 1, 2, 3, 5, 4, 6
gnss_bound(grid, node, s, s_) = no;
loop(gn(grid,node)${sameas(grid, 'hydro') or sameas(grid, 'pumped') or sameas(grid, 'H2')},
    gnss_bound(grid,node,'s000','s001') = yes;
    gnss_bound(grid,node,'s001','s002') = yes;
    gnss_bound(grid,node,'s002','s003') = yes;
    gnss_bound(grid,node,'s003','s004') = yes;
    gnss_bound(grid,node,'s004','s000') = yes;
*    gnss_bound(grid,node,'s005','s006') = yes;
*    gnss_bound(grid,node,'s006','s000') = yes;
*    gnss_bound(grid,node,'s006','s007') = yes;
*    gnss_bound(grid,node,'s007','s000') = yes;
);
loop(s$ms_initial('invest', s),
    gnss_bound(gn('battery',node),s,s) = yes;
*        gnss_bound(gn('ev',node),s,s) = yes;
);
sGroup('s000','VRE_limit') = yes;
sGroup('s001','VRE_limit') = yes;
sGroup('s002','VRE_limit') = yes;
sGroup('s003','VRE_limit') = yes;
sGroup('s004','VRE_limit') = yes;
*sGroup('s005','VRE_limit') = yes;
*sGroup('s006','VRE_limit') = yes;
*sGroup('s007','VRE_limit') = yes;

p_s_discountFactor('s000') = 1;
p_s_discountFactor('s001') = 1;
p_s_discountFactor('s002') = 1;
p_s_discountFactor('s003') = 1;
p_s_discountFactor('s004') = 1;
*p_s_discountFactor('s005') = 1;
*p_s_discountFactor('s006') = 1;
