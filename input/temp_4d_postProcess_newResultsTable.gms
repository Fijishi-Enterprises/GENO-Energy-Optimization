
* 4d_postProcess.gms is read after calculating the default results and 
* it is the last place to adjust anything before writing the result file.
* This is a template file giving examples how this can be used to expand the result file

* Declaring a new result table: sum of unit VOM costs
Parameter
	r_uTotalVOMCost(unit) "Sum of unit VOM costs"
;


* Calculating the values for the new result table.
* See further examples from 4b_outputInvariant.gms
r_uTotalVOMCost(unit)
    = sum(ft_realizedNoReset(f,startp(t)),
    	sum(gnu(grid, node, unit), 
        	+ r_gnuVOMCost(grid, node, unit, f, t)
            	* sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s) * p_s_discountFactor(s))
            ) // END sum(gnu)
        ); // END sum(ft_realizedNoReset)