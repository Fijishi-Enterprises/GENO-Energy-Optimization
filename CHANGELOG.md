# Changelog
All notable changes to this project will be documented in this file.

## [Unreleased]

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



[Unreleased]: https://gitlab.vtt.fi/backbone/backbone/compare/v1.0.5...dev
[1.0.5]: https://gitlab.vtt.fi/backbone/backbone/compare/v1.0.4...v1.0.5
[1.0.4]: https://gitlab.vtt.fi/backbone/backbone/compare/v1.0.3...v1.0.4
[1.0.3]: https://gitlab.vtt.fi/backbone/backbone/compare/v1.0.2...v1.0.3
[1.0.2]: https://gitlab.vtt.fi/backbone/backbone/compare/v1.0...v1.0.2
