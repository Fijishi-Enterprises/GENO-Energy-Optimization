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

ts_influx(gn(grid, node), f, t) = ts_influx(grid, node, f, t) + ts_influx_building_subtract(grid, node, f, t);

* =============================================================================
* --- Load Model Parameters ---------------------------------------------------
* =============================================================================

// Include desired model definition files here
$include '%input_dir%\%init_file%'

* =============================================================================
* --- Optional Data Manipulation ----------------------------------------------
* =============================================================================



// which nodes follow the superposed states scheme? Add the information here.
// Probably should be included in the input data later.
node_superpos(node) = no;
