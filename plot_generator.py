
# NOTES
# Tested with python 3.11 and GAMS45.
# Add gams transfer to conda with following instructions: https://www.gams.com/latest/docs/API_PY_GETTING_STARTED.html
# Install pandas and matplotlib to the environment. Os and sys are part of the python.

print('Importing libraries...')
import pandas as pd
import gams.transfer as gt
import os
import matplotlib.pyplot as plt
import sys
from matplotlib.backends.backend_pdf import PdfPages


######
### USER INTERFACE

# insert the path to your results GDX file
# relative pointer to default backbone results.gdx
path_to_result_gdx = os.path.normpath('./output/results.gdx')

# choose the name of the output directory
# relative pointer to default backbone output folder
path_to_output_dir = os.path.normpath('./output/')


# choose whether you want to automatically plot everything or pick the symbols yourself
    # 'automatic': the script finds and plots every available time series (may take several minutes depending on model)
    # 'manual_bb3': manual choice with results in Backbone 3.x format
    # 'manual_bb2': like 'manual_bb3' but for results in Backbone 2.x format
manual_or_automatic = 'automatic' # insert either 'automatic', 'manual_bb3' or 'manual_bb2'

# AUTOMATIC CHOICE: if you chose 'automatic', you are done and can ignore the rest of the file.
    # The script will print result tables from each result table that has t or gnu in the name

# MANUAL CHOICE: edit the lists below
    # Edit either manual_bb3_symbols or manual_bb2_symbols depending on the format of your results.

# choose symbols in Backbone 3.x format (comment out the ones you do not need)
# only time series are accepted (there needs to be a 't' and 'value' column)
manual_bb3_symbols = [
    'r_state_gnft',
    'r_spill_gnft',
    'r_transfer_gnnft',
    'r_balance_marginalValue_gnft',
    'r_transferValue_gnnft',
    'r_curtailments_gnft',
    'r_gen_gnuft',
    'r_gen_gnft',
    'r_genByFuel_gnft',
    'r_genByUnittype_gnft',
    'r_gen_unitStartupConsumption_nu',
    'r_online_uft',
    'r_startup_uft',
    'r_shutdown_uft',
    'r_emission_operationEmissions_gnuft',
    'r_emission_startupEmissions_nuft',
    'r_qGen_gnft',
    'r_cost_unitVOMCost_gnuft',
    'r_cost_unitFuelEmissionCost_gnuft',
    'r_cost_unitStartupCost_uft',
    'r_cost_realizedOperatingCost_gnft'
]

# choose Backbone 2.x format symbols (comment out the ones you do not need)
# only time series are accepted (there needs to be a 't' and 'value' column)
manual_bb2_symbols = [
    'r_state',
    'r_spill',
    'r_transfer',
    'r_transferRightward',
    'r_transferLeftward',
    'r_balanceMarginal',
    'r_gnnTransferValue',
    'r_gnCurtailments',
    'r_gen',
    'r_gnGen',
    'r_genFuel',
    'r_genUnittype',
    'r_gnConsumption',
    'r_nuStartupConsumption',
    'r_online',
    'r_startup',
    'r_shutdown',
    'r_emissions',
    'r_emissionsStartup',
    'r_qGen',
    'r_gnuVOMCost',
    'r_uFuelEmissionCost',
    'r_uStartupCost',
    'r_gnRealizedOperatingCost'
]

### END OF USER INTERFACE
######



# Function to add zero-valued rows to a time series dataframe, if missing from gdx
def add_zero_rows(df:pd.DataFrame, first_hour, last_hour):
    df_new = df.copy()

    # replace 't' values of type 't123456' with corresponding integers
    df_new['t'] = df['t'].str.replace('t','').astype(int)
    
    zero_data = {}
    
    # a list of the hours that are missing (due to having zero value), example: {1,2,3,4} - {2,4} equals {1,3}
    missing_hours = list((set(range(first_hour, last_hour + 1)) - set(df_new['t'])))
    # add the missing_hours data to the zero_data_input dictionary
    zero_data.update({'t':missing_hours, 'value':0})
    # create dataframe with missing zero-valued hours
    zero_data_df = pd.DataFrame(zero_data)
    
    # concatenate original df with zero_data and sort by 't'
    df_new = pd.concat([df_new,zero_data_df]).sort_values(by='t').reset_index(drop=True)
    df_new = df_new.reset_index(drop=True)
    
    return df_new

# Function to create a plot and save it to a PDF
def single_plot_to_pdf(df:pd.DataFrame, symbol_name:str, title_name:str, pdf_file):
    fig, ax = plt.subplots()
    ax.plot(df['t'], df['value'])
    ax.set(xlabel='Time (h)', ylabel=symbol_name,
        title=title_name)
    ax.grid()
    pdf_file.savefig(fig, bbox_inches='tight')
    plt.close()

# creates a directory for the output pdfs, if needed
# also confirms that the user wants to continue if the output directory contains files that would be overwritten
def check_chosen_output(symbols:list):
    if not os.path.exists(path_to_output_dir):
        os.mkdir(path_to_output_dir)
    else:
        to_be_overwritten = set(os.listdir(path_to_output_dir)).intersection(set([s + '.pdf' for s in symbols]))
        if len(to_be_overwritten) > 0:
            print(f'\nWARNING: running the script will overwrite the following files in the {path_to_output_dir}\ directory:\n')
            for file_name in to_be_overwritten:
                print(file_name)
            user_answer = input('\nDo you want to continue (write "yes" to proceed)?\n')
            if user_answer not in ['y', 'yes']:
                sys.exit('\nScript aborted.')


# Function to create plots for selected data
def create_all_plots(all_results:gt.Container(), chosen_data:list):
    
    for symbol in chosen_data:
        print(f'Creating plot pdf for {symbol}...')
        df = all_results.data[symbol].records
        
        # dataframe consisting of the unique combinations of values in columns excluding ['t', 'value']
        combinations = df.loc[:, ~df.columns.isin(['t', 'value'])].drop_duplicates().reset_index(drop=True)
        headers = combinations.columns
        pdf_name = f'{path_to_output_dir}\\{symbol}.pdf'

        if len(headers) > 0: # i.e. if there are other columns than 't' and 'value'
            # PdfPages allows for adding multiple plots to a single pdf file
            pp = PdfPages(pdf_name)
            for row in combinations.itertuples():
                # filter the dataframe with unique value combinations from the other columns
                query_input = ''
                plot_title = ''
                for index in range(0, len(headers)):
                    if index < len(headers) - 1:
                        query_input += f'{headers[index]} == "{row[index + 1]}" and '
                        plot_title += f'{headers[index]}={row[index + 1]}, '
                    else:
                        query_input += f'{headers[index]} == "{row[index + 1]}"'
                        plot_title += f'{headers[index]}={row[index + 1]}'
                # query input ready, now query the df and create plot for current combination
                ready_df = add_zero_rows(df.query(query_input), t_start, t_end)
                single_plot_to_pdf(ready_df, symbol, plot_title, pp)
            pp.close()
        # in case some data only have the 't' and 'value' columns
        else:
            ready_df = add_zero_rows(df, t_start, t_end)
            plt.plot(ready_df['t'], ready_df['value'], title=symbol)
            plt.savefig(pdf_name)
            plt.close()

    print('All done.')


if manual_or_automatic not in ['automatic', 'manual_bb3', 'manual_bb2']:
    print('No plots created. Please set the manual_or_automatic variable as either "automatic", "manual_bb3" or "manual_bb2".')
    sys.exit('\nScript aborted.')

# check output directory and load results.gdx

if manual_or_automatic in ['manual_bb3', 'manual_bb2']:
    check_chosen_output(manual_or_automatic)

print('\nLoading gdx data...')
result_gdx = gt.Container(path_to_result_gdx)

if manual_or_automatic == 'automatic':
    # get suitable symbol names from result_gdx
    all_symbols_with_t_and_gnu = []
    for symbol in result_gdx.data.keys():
        df = result_gdx.data[symbol].records
        if df is not None and 't' in df.columns and any(item in ['grid', 'node', 'unit'] for item in df.columns) and len(df) > 1:
            all_symbols_with_t_and_gnu += [symbol]
    check_chosen_output(all_symbols_with_t_and_gnu)


# picking t_start and t_end from mSettings info result table
# named r_info_mSettings in BB3.x and mSettings in BB2.x
try:
    t_start = result_gdx.data['r_info_mSettings'].records.copy().query('mSetting=="t_start"')['value'].values[0].astype(int)
    t_end = result_gdx.data['r_info_mSettings'].records.copy().query('mSetting=="t_end"')['value'].values[0].astype(int)
except:
    print()
    
try:
    t_start = result_gdx.data['mSettings'].records.copy().query('mSetting=="t_start"')['value'].values[0].astype(int)
    t_end = result_gdx.data['mSettings'].records.copy().query('mSetting=="t_end"')['value'].values[0].astype(int)
except:
    print()

# print automatic or selected list of result symbols to pdf
if manual_or_automatic == 'automatic':
    create_all_plots(result_gdx, all_symbols_with_t_and_gnu)
elif manual_or_automatic == 'manual_bb3':
    create_all_plots(result_gdx, manual_bb3_symbols)
elif manual_or_automatic == 'manual_bb2':
    create_all_plots(result_gdx, manual_bb2_symbols)
