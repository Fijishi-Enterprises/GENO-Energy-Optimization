
* Automatically add .l to variables in macros
$ondotl

* Macro for sum of squares of relative changes in parameter p in index i from
* time t - prev(t) to time t. Used in probablity calculations.
*$macro squareSum(p, i) \
*    sum(i $(p(i, t - prev(t), s_, 'average') > 0), \
*        power(p(i, t, f, 'average') / p(i, t - prev(t), s_, 'average') - 1, 2))



$ontext
* Macro for calculating the time-average value of time series ts in indices i,
* main index j, in year y during time step t and current hour h.
* Argument stocahstic [yes|no] tells stochasticity, and cur_year the current
* year.
 $macro timeAverage(ts, i, y, h, stochastic, cur_year, t) \
    sum(step_hour(t, h_), \
        ts(h_, &&i, y + (1$(ord(t) > 1 and ord(h_) < ord(h))))$stochastic \
        + ts(h_, &&i, cur_year)$(not stochastic) \
    ) / p_stepLength(f, t)

* Macro for calculating the time-average value of time series ts in indices i,
* main index j in year y during time block b of time step t in sample n
* and considering current hour h.
* Argument stocahstic [yes|no] tells stochasticity, and cur_year the current
* year.
 $macro blockAverage(ts, i, y, f, h, stochastic, cur_year, t) \
    sum(block_hour(f, t, h_), \
        ts(h_, &&i, y + (1$(ord(h_) < ord(h))))$stochastic \
        + ts(h_, &&i, cur_year)$(not stochastic) \
    ) / p_blockLength(t)
$offtext

* Macro for calculating net load error in bus during time step t in scenario n
* and time block b.
* Argument 'direction' {-1, 1} tells if its upward or downwar deviation.
$macro netLoadError(bus, f, direction, t) \
    sMax(step_hour(h, t), \
        (sum(load_in_hub(load, bus), \
            ts_elecLoad(h, load, yr) \
            - p_elecLoad(load, f, t) \
        ) \
        - sum(unit_in_hub(unitVG, bus), \
              sum(unit_REsource(unitVG, REsource), \
                  ts_fluctuation(h, REsource, yr) \
                    * p_data(unitVG, 'max_power') \
                    * p_data(unitVG, 'availability') \
              ) \
              - p_unitVG(unitVG, f, t) \
                  * p_data(unitVG, 'availability') \
          ) \
        - sum(unit_in_hub(unitHydro, bus) \
              $unitVG(unitHydro), \
              ts_inflow(h, unitHydro, yr) / 1 \
              - p_inflowRate(unitHydro, f, t) \
          ) \
        ) * (direction) \
    )

* Macro for calculating amount of stored energy needed to provide reserves of
* res_category during time step t in scenario n and time block b
$macro resEnergy(storage, res_category, f, t) \
    sum(unit_storage(unitElec, storage), \
        sum(&res_category(resDirection), \
            (v_reserve(resDirection, unitElec, t) \
             + v_resConsCapacity(resDirection, unitElec, t)$consuming(unitElec) \
            ) * (p_data(resDirection, 'res_timelim')$(not tertiary(resDirection)) \
                 + p_blockLength(t)$tertiary(resDirection)) \
          ) \
      )

* Macro for calculating total net load over all buses in year and current year
$macro netLoad(year, cur_year, hour) \
    sum(bus, \
        sum(load_in_hub(load, bus), \
            ts_elecLoad(load, hour)$stochastic(load) \
            + ts_elecLoad(load, cur_year, hour)$(not stochastic(load)) \
        ) \
        - ts_import(bus, cur_year, hour) \
        - sum(unit_REsource(unitVG, REsource) \
                $unit_in_hub(unitVG, bus), \
                  (ts_fluctuation(REsource, hour)$stochastic(REsource) \
                   + ts_fluctuation(REsource, cur_year, hour) \
                        $(not stochastic(REsource))) \
                      * p_data(unitVG, 'max_power') \
                      * p_data(unitVG, 'availability') \
          ) \
        - sum(unit_in_hub(unitVG, bus)$unitVG(unitVG), \
              ts_inflow(unitVG, hour)$stochastic(unitVG) \
              + ts_inflow(unitVG, cur_year, hour) \
                    $(not stochastic(unitVG)) \
          ) \
    )
