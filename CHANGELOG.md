# Changelog
All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- All input files, including *inputData.gdx*, are optional
- Enabling different combinations of LP and MIP online and invest variables
- Separate availability parameter for output units in the capacity margin constraint
- Parameter `gn_forecasts(*, node, timeseries)` to tell which nodes and timeseries use forecasts
- Dynamic inertia requirements based on loss of unit and loss of export/import (ROCOF constraints)
- N-1 reserve requirement for transfer links
- A separate parameter to tell whether units can provide offline reserve
- Maximum share of reserve provision from a group of units

### Changed 
- Updated tool definitions for Sceleton Titan and Spine Toolbox
- The program will now stop looping in case of execution errors.
- Scenario reduction is done based on total available energy
- Maintain original scenario labels after reduction
- Reserve requirements are now based on groups (previously node based)
- Clear time series data from droppped samples after scenario reduction

### Fixed
- Removed hard-coded `elec grids` from *setVariableLimits* and *rampSched files*
- Time series smooting not working at all (#100)
- Fix a number of compilation warnings
- Limiting the provision of online reserve based on the online variable
- Sample probability bug from scenario reduction (probability of single scneario
  above one)

## [1.1] - 2019-04-17
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


## [1.0.6] - 2019-03-27
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


## [1.0.5] - 2019-02-14
### Fixed
- Probabilities were not updated after using scenario reduction

### Added
- Enable long-term samples that extend several years by using planning horizon 
  which is longer than one scenario (e.g. 3 years). Note: Cannot use all data for 
  samples as last years need to be reserved for the planning horizon.


## [1.0.4] - 2019-02-11
### Fixed
- Severe bug in setting node state level limits

### Changed
- Suppress ouput from SCENRED2


## [1.0.3] - 2019-02-05
### Fixed
- Only selects forecasts with positive probability for the solve


## [1.0.2] - 2019-02-04
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



[Unreleased]: https://gitlab.vtt.fi/backbone/backbone/compare/v1.1...dev
[1.1]: https://gitlab.vtt.fi/backbone/backbone/compare/v1.0.6...v1.1
[1.0.6]: https://gitlab.vtt.fi/backbone/backbone/compare/v1.0.5...v1.0.6
[1.0.5]: https://gitlab.vtt.fi/backbone/backbone/compare/v1.0.4...v1.0.5
[1.0.4]: https://gitlab.vtt.fi/backbone/backbone/compare/v1.0.3...v1.0.4
[1.0.3]: https://gitlab.vtt.fi/backbone/backbone/compare/v1.0.2...v1.0.3
[1.0.2]: https://gitlab.vtt.fi/backbone/backbone/compare/v1.0...v1.0.2
