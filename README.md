# Backbone

Backbone is a generic energy network optimization tool written in [GAMS](https://www.gams.com/). It has been designed to be highly adaptable in different dimensions: temporal, spatial, technology representation and market design. The model can represent stochastics with a model predictive control method [1], with short-term forecasts and longer-term statistical uncertainties. Backbone can support multiple different models due to the modifiable temporal structure and varying lengths of the time steps.

[1] Nolde, K., Uhr, M., & Morari, M. (2008). Medium term scheduling of a hydro-thermal system using stochastic model predictive control. Automatica, 1585-1594.

## Getting Started

Make sure that you have [Git](https://git-scm.com/) version control system and a Git interface, such as [TortoiseGit](https://tortoisegit.org/) or [SourceTree](https://www.sourcetreeapp.com/), installed on your computer. You also need to have [GAMS](https://www.gams.com/) installed.

In order to get a copy of the Backbone project, you need to clone it using Git. Copy and paste the URL of the original Backbone repository and select the directory where you want Backbone to be cloned. The URL of the original Backbone repository is https://gitlab.vtt.fi/backbone/backbone. 

You should now have *Backbone.gms*, a few additional files and three subdirectories in the directory where you cloned Backbone. Note that you need to manually create two additional subdirectories in order to get Backbone working. These subdirectories should be named *input* and *output* and they should be created in the same directory where *Backbone.gms* is.

## Model File Structure

Backbone has been designed with a modular structure, making it easier to change even large portions of the model if necessary. The various gms-files of the model are described briefly below, in the order of their execution when running Backbone. 

* Backbone.gms - The heart of the model, containing instructions on how the rest of the files are read and compiled. The following files are currently named with an index corresponding to their turn in the Backbone compilation order.
* 1a_definitions.gms - Contains important definitions regarding the models used, such as possible model features and parameters.
* 1b_sets.gms - Contains the set definitions required by the models.
* 1c_parameters.gms	- Contains the parameter definitions used by the models.
* 1d_results.gms - Contains definitions for the model results.
* 1e_inputs.gms - Contains instructions on how to load input data, as well as forms a lot of helpful sets based on said data, for example in order to facilitate writing the constraints.
* 2a_variables.gms - Contains variable definitions used by the models.
* 2b_equations.gms - Contains the equation definitions for the models.
* *Model Definition Files* - Contains GAMS definitions for different models, essentially lists the equations (constraints) that apply. Current files include *schedule.gms*, *building.gms* and *invest.gms*.
* 3a_periodicInit.gms - Initializes various data and sets for the solve loop.
* 3b_inputsLoop.gms	- Instructions for possible data import inside the solve loop, as well as forecast in-the-loop improvements.
* 3c_periodicLoop.gms - Contains instructions for the forecast-time structure of the desired model.
* 3d_setVariableLimits.gms - Defines the variable boundaries for each solve.
* 3e_solve.gms - Contains the GAMS solve command for using the solver.
* 4a_outputVariant.gms - Contains instructions for storing desired results during the solve loop.
* 4b_outputInvariant.gms - Calculates further results post-solve.
* 4c_outputQuickFile.gms

Most of these files are under *\inc* in the Backbone folder, except for the model definition files being housed under *\defModels*. Other than the abovementioned files, a few key input files are required for Backbone to work. These are assumed to be found under *\input* and are briefly described below.

* inputData.gdx	- Contains most of the input data about the system to be modelled.
* timeAndSamples.inc - Contains definitions for the time, forecast and sample index ranges.
* modelsInit.gms - Contains model parameters for the solve (or a link to a template under *\defModels* to be used). Useful for any additional GAMS scripting.

Backbone folder contains two template files *timeAndSamples_temp.inc* and *modelsInit_temp.gms* to provide examples of the input format. These files can be copied into *\input* and renamed to *timeAndSamples.inc* and *modelsInit.gms*.

## When Simply Using Backbone

When starting to use Backbone, there is no immediate need to understand every single file that makes up the model. The files below list the most important files to understand, if one’s aim is simply to use Backbone for modelling/simulation purposes, without the need to modify the way the model works.

* **1a_definitions.gms**: Lists all the possible model settings, as well as all the different parameters that Backbone understands. Also lists some auxiliary sets that are required for the model structure, but don’t hold any intuitive meaning.
* **1e_inputs.gms**: Imports the input data into Backbone, and thus contains a list of the sets and parameters that need to be included in the “InputData.gdx” input file. Also contains rules for generating all sorts of auxiliary sets based on the input data that are used throughout the model files. Contains a few data integrity checks as well, but these could/should be expanded upon in the future.
* **1b_sets.gms and 1c_parameters.gms**: Understanding of the required dimensions of the input sets and parameters is necessary in order to create working input files. 
* **Model Initialization Files**: E.g. *scheduleInit_temp.gms* that define the rules for the optimization model.

## Authors

* Juha Kiviluoma
* Erkka Rinne
* Topi Rasku
* Niina Helisto

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
