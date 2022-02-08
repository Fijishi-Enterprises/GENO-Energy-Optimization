# Changelog
All notable changes to this project will be documented in this file.

## unversioned
### Added

### Changed
- decreased default penalty value from 10e9 to 10e4 to improve solver default behavior

### Fixed


## 2.1 - 2022-01-24
### Added
- two new result tables (gnGen, groupReserves) for easier graph drawing and debugging

### Changed
- result table r_gen_gnUnittype renamed to r_gnuTotalGen_unittype. Original was not actively used in master branch.
- updated the order of generation result tables in 4b_outputInvariants
- changed emissions from output result table to print negative numbers signifying emissions bound to manufactured product

### Fixed
- changing sum over gnu_output to gnu in totalVOMcost, genUnittype, and gnuUtilizationRate
- p_gnReserves for one node with more than one independend reserves 
- Aggregated units not working with maintenance breaks
- Summing of reserve results


## 2.0 - 2022-01-05
### Added
- Result parameters for start-up energy consumption and start-up emissions
- Result parameter for realized diffusions
- Result tables for average marginal values (generation, reserves)
- Result tables for annual reserve results (gn, resTransfer)
- Two additional constraints to make transfer constraints tighter
- New set for the m, s, f, t combinations including the previous sample

### Changed
- Replaced commodity set with a parameter usePrice and updated results calculation related to it
- Replaced q_energyMax, q_energyShareMax and q_energyShareMin with q_energyLimit and q_energyShareLimit
- Removing Eps values from r_reserve results table
- Allow solver resource or iteration limit interrupt if the solution is feasible

### Fixed
- Including start-up fuel consumption in q_balance
- Updated start-up cost and start-up emission calculation
- output_dir command line argument was missing quotes in the code and directories with space did not work 
- Sceanario smoothing in certain special cases


## 1.5 - 2021-10-05
### Added
- Additional conditions in the objective function to avoid summing empty sets
- Possibility to model maintenance break with `utAvailalability` limits

### Changed
- Speedups

### Fixed 
- Templates for time and sample sets as well as model definitions files
- N-1 reserve equation did not include last hour of day/solve
- Setting the default update_frequency for reserve types
- Better control of reserve-related assignments


## 1.4 - 2021-06-29
- Time series for transmission availability and losses
- More versatile reading of input files. Translating input Excel to input GDX supported inside Backbone 1e_inputs.gms

## 1.3.3 - 2021-04-14
- Transfer can have additional 'variable' costs (costs per MWh transferred)
- Reserve activation duration and reactivation time included (in state constraints)
- Raise execution error if solver did not finish normally
- Updated the selection of unit efficiency approximation levels
- Additional result outputs

## 1.3.2 - 2021-01-19
- Moving from p_groupPolicy3D to separate p_groupPolicyUnit and p_groupPolicyEmission

## 1.3.1 - 2021-01-19
- Maximum (and minimum) limit to sum of energy inputs/outputs of selected group of units
- Additional result outputs concerning emissions

## 1.3 - 2020-10-21
- Static inertia requirement can be fulfilled by both rotational inertia of machines and certain reserve products
- Dynamic generation portfolios aka pathway modelling aka multi-year simulations with discounted costs enabled
- Parameters p_gnPolicy and p_groupPolicy3D replaced with p_groupPolicyEmission and p_groupPolicyUnit

## 1.2.2 - 2020-06-09
- Clean up, minor bug fixes and more results outputs

## 1.2.1 - 2019-11-26
### Fixed
- Fixed a possible division by zero in the calculation of r_gnuUtilizationRate
- Updated debugSymbols.inc and 1e_scenChanges.gms to match with the current naming of sets and parameters

### Changed
- Changed variable O&M costs from p_unit(unit, 'omCosts') to p_gnu(grid, node, unit, 'vomCosts')

## 1.2 - 2019-11-12

### Added
- Dynamic inertia requirements based on loss of unit and loss of export/import (ROCOF constraints)
- N-1 reserve requirement for transfer links
- A separate parameter to tell whether units can provide offline reserve (non-spinning reserve)
- Maximum share of reserve provision from a group of units
- All input files, including *inputData.gdx*, are optional
- Enabling different combinations of LP and MIP online and invest variables
- Separate availability parameter for output units in the capacity margin constraint
- Parameter `gn_forecasts(*, node, timeseries)` to tell which nodes and timeseries use forecasts

### Changed 
- Reserve requirements are now based on groups (previously node based)
- Changed the v_startup (and v_shutdown) variables into integers to improve the performance online approximations
- Updated tool definitions for Sceleton Titan and Spine Toolbox
- The program will now stop looping in case of execution errors
- Scenario reduction is done based on total available energy
- Maintain original scenario labels after reduction
- Clear time series data from droppped samples after scenario reduction

### Fixed
- Removed hard-coded `elec grids` from *setVariableLimits* and *rampSched files*
- Cyclic bounds between different samples was not working correctly (#97)
- Time series smoothing not working at all (#100)
- Fix a number of compilation warnings
- Limiting the provision of online reserve based on the online variable
- Sample probability bug from scenario reduction (probability of single scenario above one)


## 1.1.5 - 2020-11-28
### Fixed
- Long-term scenario data when using only one scenario
- Bug with scenario smooting which caused wrong values on later than first solve


## 1.1.4 - 2019-11-02
### Fixed
- Sample probability bug from scenario reduction


## 1.1.3 - 2019-10-24
### Changed 
- Scenario reduction is done based on total available energy


## 1.1.2 - 2019-10-23
### Changed 
- Maintain original scenario labels after reduction


## 1.1 - 2019-04-17
### Added
- New model setting 't_perfectForesight' tells the number of time steps (from 
  the beginning of current solve) for which realized data is used instead of 
  forecasts. This value cannot exceed current forecast length, however. Setting 
  the value lower than 't_jump' has no effect.
- Automated the calculation of sample start and end times if using long-term 
  scenarios. Also setting number of scenarios to one, instructs the model to use
  central forecast for the long-term.
- Speedup for model dimension calculation (set `msft` etc.)
- Support long time intervals in the first block
- Possibility to limit `v_online` to zero according to time series
- Output for reserve transfer results
- Reserve provision limits with investments
- Constrain the set of units to which ramp equations are applied
- Piecewise linear heat rate curves
- Checks for reserves
- Allow to set certain value for `v_gen` at 't000000'

### Changed
- Removed some old command line arguments
- Removed obsolete 'emissionIntensity' fuel parameter

### Fixed
- Unit ramps during start-up and shutdown
- Refreshing forecast data in *inputsLoop*
- Aggregated groups that were not in use were included in the model
- `mst_end` not found for the last sample
- Start-up not working for units without start costs or start fuel consumption
- *periodicInit* will fail with multiple model definitions
- Reserves should not be allowed to be locked when the interval is greater than 
  smallest interval in use
- Start-up phase and aggregated time steps do not work together
- In SOS2 unit cannot exceed the generation of `p_ut_runUp`
- Startup cost calculation
- Efficiency presentations
- `p_uNonoperational` not fully correct


## 1.0.6 - 2019-03-27
### Fixed
- Major bug in state variable reserve equations
- Scenario smoothing alogirithm

### Changed
- Speedup for timeseries calculations

### Added 
- New model setting `mSettings(mType, 'onlyExistingForecasts') = 0|1` to control 
  the reading of forecasts. Set to 1 to only read forecast data that exists in 
  the file. Note that zeros need to be saved as Eps when using this.
- Proper stochastic programming for the long-term scenarios period. Possible also
  to create a stochastic tree from the original data.
- Clickable link to *sr.log* in the process window in case of SCENRED2 error
- New diagnostic parameter for timeseries scenarios `d_ts_scenarios`


## 1.0.5 - 2019-02-14
### Fixed
- Probabilities were not updated after using scenario reduction

### Added
- Enable long-term samples that extend several years by using planning horizon 
  which is longer than one scenario (e.g. 3 years). Note: Cannot use all data for 
  samples as last years need to be reserved for the planning horizon.


## 1.0.4 - 2019-02-11
### Fixed
- Severe bug in setting node state level limits

### Changed
- Suppress ouput from SCENRED2


## 1.0.3 - 2019-02-05
### Fixed
- Only selects forecasts with positive probability for the solve


## 1.0.2 - 2019-02-04
### Added
- New model setting `dataLength` to set the length of time series data before it is
  recycled. Warn if this is not defined and automatically calculated from data.
- Command line arguments '--input_dir=<path>' and '--ouput_dir=<path' to set
  input and output directories, respectively.
- Added sample dimension to most variables and equations (excl. investments). 
  Samples can now be used as long-term scenario alternatives (for e.g. hydro scehduling)
- Number of parallel samples can be reduced using SCENRED2. Activate with active('scenRed')
  and set parameters in modelsInit.

### Changed
- Automatic calculation of parameter `dt_circular` takes into account time steps 
  only from `t000001` onwards.
- Debug mode yes/no changed to debug levels 0, 1 or 2. With higher level produces
  more information. Default is 0, when no extra files are written (not even *debug.gdx*).
  Set debug level with command line parameter `--debug=LEVEL`.

### Fixed
- Calculation of parameter `df_central`
- Readability of some displayed messages 


## 1.0 - 2018-09-12
### Changed
- Major updates to data structures etc.


