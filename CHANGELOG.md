# Changelog
All notable changes to this project will be documented in this file.

## [Unreleased]
### Added
- New model setting `dataLength` to set the length of time series data before it is
  recycled. Warn if this is not defined and automatically calculated from data.
- Command line arguments '--input_dir=<path>' and '--ouput_dir=<path' to set
  input and output directories, respectively.

### Changed
- Automatic calculation of parameter `dt_circular` takes into account time steps 
  only from `t000001` onwards.

### Fixed
- Calculation of parameter `df_central`
- Readability of some displayed messages 


## 1.0 - 2018-09-12
### Changed
- Major updates to data structures etc.

[Unreleased]: https://gitlab.vtt.fi/backbone/backbone/compare/v1.0...dev
