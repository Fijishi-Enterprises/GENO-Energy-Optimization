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
* --- Sets to define time, forecasts and samples ------------------------------
* =============================================================================

    s "Samples from historical periods" / s000 * s999 /
    f "Forecasts for the short term" / f00 * f99,
                                       scen 'long-term scenarios',
                                     /
    t "Model time steps" / t000000 * t017568 /
    scenario "Long-term scenarios" / scen00 /
    z "periods for superpositioning of states (candidate periods)" /z000 * z100/