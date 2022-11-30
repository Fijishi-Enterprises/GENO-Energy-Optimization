* Define empty sets, parameters and variables (copy pasted from backbone v3.1)

* Check current GAMS version
$ife %system.gamsversion%<240 $abort GAMS distribution 24.0 or later required!

* Set default debugging level
$if not set debug $setglobal debug 0

* Default values for input and output dir as well as input data GDX file and index sheet when importing data from Excel file
* When reading an Excel file, you can opt to read the file only if the Gdxxrw detects changes by using 'checkDate' for
*   input_excel_checkdate. It is off by default, since there has been some problems with it.
$if not set input_dir $setglobal input_dir 'input'
$if not set output_dir $setglobal output_dir 'output'
$if not set input_file_gdx $setglobal input_file_gdx 'inputData.gdx'
$if not set input_excel_index $setglobal input_excel_index 'INDEX'
$if not set input_excel_checkdate $setglobal input_excel_checkdate ''

* Make sure output dir exists
$if not dexist '%output_dir%' $call 'mkdir %output_dir%'

* Activate end of line comments and set comment character to '//'
$oneolcom
$eolcom //
$onempty   // Allow empty data definitions

* Output file streams
Files log /''/, gdx /''/, f_info /'%output_dir%/info.txt'/;

* Include options file to control the solver (if it does not exist, uses defaults)
$ifthen exist '%input_dir%/1_options.gms'
    $$include '%input_dir%/1_options.gms';
$endif

* === Definitions, sets, parameters and input data=============================
$include 'inc/1a_definitions.gms'   // Definitions for possible model settings
* 1a_definitions reads additional parameter definitions from params.inc if exists
$include 'inc/1b_sets.gms'          // Set definitions used by the models
* 1b_sets reads %input_dir%/timeAndSamples.inc and inc/rampSched/sets_rampSched.gms if exists
$include 'inc/1c_parameters.gms'    // Parameter definitions used by the models
$include 'inc/1d_results.gms'       // Parameter definitions for model results
$include 'inc/1e_inputs.gms'        // Load input data
