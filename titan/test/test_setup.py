"""
Unit tests for Setup class [Needs updating).

@author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
@date: 26.2.2016
"""

from unittest import TestCase, SkipTest, mock, skip
import os
import sys
import shutil
import logging as log
from tool import Setup
import tool
import ui_main
from GAMS import GAMSModel
from config import APPLICATION_PATH, PROJECT_DIR, CONFIGURATION_FILE, GENERAL_OPTIONS
from helpers import copy_files, create_dir, create_output_dir_timestamp
from project import SceletonProject
from models import SetupModel
from models import ToolModel
from configuration import ConfigurationParser


class TestSetup(TestCase):
    # TODO: Mock create_dir so that directories are not actually created
    # TODO: Fix or move execution tests

    # add_msg_signal = mock.Mock()  # Example of a mock signal

    def setUp(self):
        """Make a Setup Model with 3 Setups (base -> dummy_a, dummy_b)."""
        log.basicConfig(stream=sys.stderr, level=log.DEBUG,
                        format='%(asctime)s %(levelname)s: %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S')
        log.disable(level=log.ERROR)
        self._project = SceletonProject('Unittest Project', '')
        # Make SetupModel
        self._root = Setup('root', 'root node for Setups,', self._project)
        self._setup_model = SetupModel(self._root)
        # Add a few Setups into SetupModel
        self._setup_model.insert_setup('Base', 'Base Setup for unit tests', self._project, 0)
        base_index = self._setup_model.find_index('Base')
        self._setup_model.insert_setup('Dummy A', 'Setup A with parent Base', self._project, 0, base_index)
        self._setup_model.insert_setup('Dummy B', 'Setup B with parent Base', self._project, 0, base_index)
        self._tool_model = None  # Initialize ToolModel only if test needs it
        log.disable(level=log.NOTSET)

    def tearDown(self):
        """Delete files and reset models."""
        # log.info("Tearing down")
        # TODO: Remove Setup input directories (and maybe the whole unittest_project directory)
        log.disable(level=log.ERROR)
        base_f = os.path.join(self._project.project_dir, 'input', 'base')
        base_output_f = os.path.join(self._project.project_dir, 'output', 'base')
        dummy_a_f = os.path.join(self._project.project_dir, 'input', 'dummy_a')
        dummy_b_f = os.path.join(self._project.project_dir, 'input', 'dummy_b')
        # DELETE INPUT FILES
        delete = True
        if delete:
            if os.path.exists(base_f):
                self.delete_files(base_f)
            if os.path.exists(dummy_a_f):
                self.delete_files(dummy_a_f)
            if os.path.exists(dummy_b_f):
                self.delete_files(dummy_b_f)
        # DELETE TIMESTAMPED OUTPUT FOLDERS OF SETUP BASE
        base_output_folders = os.listdir(base_output_f)
        # log.debug("base output folders:{0}".format(base_output_folders))
        for folder in base_output_folders:
            folder_path = os.path.join(base_output_f, folder)
            if os.path.isdir(folder_path):
                log.debug("Deleting folder: {0}".format(folder_path))
                shutil.rmtree(folder_path)
        log.disable(level=log.NOTSET)
        # Clear project, setup model, tool model, and root setup
        self._project = None
        self._root = None
        self._setup_model = None
        if self._tool_model:
            self._tool_model = None

    @mock.patch('ui_main.TitanUI')
    def init_tool_model(self, mock_ui):
        """Create Tool model and initialize configuration file."""
        config = ConfigurationParser(CONFIGURATION_FILE, defaults=GENERAL_OPTIONS)
        config.load()
        # Tool model
        self._tool_model = ToolModel()
        tool_defs = config.get('general', 'tools').split('\n')
        gui = mock_ui()
        # log.debug("Asserting mock GUI")
        assert mock_ui is ui_main.TitanUI
        assert gui is ui_main.TitanUI()
        for tool_def in tool_defs:
            if tool_def == '':
                continue
            # Load tool definition
            t = GAMSModel.load(tool_def, gui)
            if not t:
                log.error("Failed to load Tool from path '{0}'".format(tool_def))
                continue
            # Add tool definition file path to tool instance variable
            t.set_def_path(tool_def)
            # Insert tool into model
            # log.debug("Inserting Tool {0} to ToolModel".format(t.name))
            self._tool_model.insertRow(t)

    def test_attach_tool(self):
        """Test adding tool to Setup Base."""
        log.info("Testing attach_tool()")
        # Fill ToolModel
        self.init_tool_model()
        # Get Setup
        base_index = self._setup_model.find_index('Base')
        base = base_index.internalPointer()
        # Get the first tool in ToolModel from index 1 (0:No Tool)
        t = self._tool_model.tool(1)
        # log.debug("Attaching Tool '{0}' to Setup '{1}'".format(t.name, base.name))
        retval = base.attach_tool(t)
        self.assertTrue(retval)

    def test_find_input_file(self):
        """Test finding individual files from Setups with no Tool."""
        log.info("Testing find_input_file()")
        # Prepare test data
        self.prepare_test_data()
        # Get test Setup
        s = self._setup_model.find_index('Dummy A').internalPointer()
        # Make folder refs
        base_f = os.path.join(self._project.project_dir, 'input', 'base')
        dummy_a_f = os.path.join(self._project.project_dir, 'input', 'dummy_a')
        # dummy_b_f = os.path.join(self._project.project_dir, 'input', 'dummy_b')
        # TEST 1. Find a file in Setups's own input folder (Dummy A)
        path = s.find_input_file('dummy3.gdx')
        self.assertEqual(path, os.path.join(dummy_a_f, 'dummy3.gdx'))
        # TEST 2. Find a file in Setups's parents input folder (Base)
        path = s.find_input_file('dummy1.gdx')
        self.assertEqual(path, os.path.join(base_f, 'dummy1.gdx'))
        # TEST 3. Find a file in Setups's siblings input folder. (Dummy B) Must return None.
        path = s.find_input_file('dummy4.gdx')
        self.assertEqual(path, None)
        # TEST 4. Try to find a file that does not exist. Must return None.
        path = s.find_input_file('dummy4.gdx')
        self.assertEqual(path, None)
        # TEST 5. Find a file from parent's output(=input) folder. No tools.
        path = s.find_input_file('dummy1.gdx')
        self.assertEqual(path, os.path.join(base_f, 'dummy1.gdx'))

    def test_find_input_files(self):
        """Test finding files with wildcards."""
        log.info("Testing find_input_files()")
        # Prepare test data
        self.prepare_test_data()
        # Get test Setup
        s = self._setup_model.find_index('Dummy A').internalPointer()
        # Make folder refs
        base_f = os.path.join(self._project.project_dir, 'input', 'base')
        dummy_a_f = os.path.join(self._project.project_dir, 'input', 'dummy_a')

        # TEST 1: Find *.gdx files
        found_files = s.find_input_files('*.gdx')
        # log.debug("found_files:\n{0}".format(found_files))
        ref = list()
        ref.append(os.path.join(dummy_a_f, 'data.gdx'))
        ref.append(os.path.join(dummy_a_f, 'dummy3.gdx'))
        ref.append(os.path.join(base_f, 'dummy1.gdx'))
        ref.append(os.path.join(base_f, 'dummy2.gdx'))
        self.assertEqual(found_files, ref)

    def test_find_input_files_from_setups_with_tools(self):
        """Test that find_input_files works with wildcards with Setups with a tool.
        This means that find_input_files should look for files matching the pattern from
        the most recent timestamped output folder."""
        log.info("Testing find_input_files with Setups with tools()")
        # Prepare test data
        self.prepare_test_data()
        # Fill ToolModel
        self.init_tool_model()
        # Get tool from ToolModel
        t_magic_invest = self._tool_model.find_tool('Magic Investments')
        if not t_magic_invest:
            self.skipTest("Cannot make test without Magic Investments tool")
        # Get tool from ToolModel
        t_magic_operation = self._tool_model.find_tool('Magic Operation')
        if not t_magic_operation:
            self.skipTest("Cannot make test without Magic Operation tool")
        # Get base Setup
        s_base = self._setup_model.find_index('Base').internalPointer()
        # Get Dummy A
        s_dummy_a = self._setup_model.find_index('Dummy A').internalPointer()
        # Attach Tool Magic Investments to Setup Base
        s_base.attach_tool(t_magic_invest)
        # Attach Tool Magic Operation to Setup Dummy A
        s_dummy_a.attach_tool(t_magic_operation)
        # Make folder refs
        base_f = os.path.join(self._project.project_dir, 'input', 'base')
        base_output_f = os.path.join(self._project.project_dir, 'output', 'base')
        dummy_a_f = os.path.join(self._project.project_dir, 'input', 'dummy_a')

        # TEST 1: Find all *.gdx files for Base with Tool
        log.debug("TEST 1")
        base_files = s_base.find_input_files('*.gdx')
        # log.debug("Base *.gdx files:\n{0}".format(base_files))
        ref_base = list()
        ref_base.append(os.path.join(base_f, 'data.gdx'))
        ref_base.append(os.path.join(base_f, 'dummy1.gdx'))
        ref_base.append(os.path.join(base_f, 'dummy2.gdx'))
        self.assertEqual(base_files, ref_base)

        # TEST 2: Find all *.gdx files for Dummy A with Tool
        # Simulate that Base Setup Magic Investments finished by copying Magic Investments
        # output files to a new timestamped folder
        base_result_path = create_dir(os.path.abspath(os.path.join(
            s_base.output_dir, s_base.short_name + create_output_dir_timestamp())))
        # Copy investments.gdx from \test\resources to a timestamped base Setup output folder
        src_file_path = os.path.abspath(os.path.join(
            APPLICATION_PATH, 'test', 'resources', 'test_output_for_magic_invest'))
        base_count = copy_files(src_file_path, base_result_path)
        log.debug("TEST 2")
        # Find input files for Dummy A with Tool
        dummy_files = s_dummy_a.find_input_files('*.gdx')
        # log.debug("Dummy A *.gdx files:\n{0}".format(dummy_files))
        ref_dummy = list()
        ref_dummy.append(os.path.join(dummy_a_f, 'data.gdx'))
        ref_dummy.append(os.path.join(dummy_a_f, 'dummy3.gdx'))
        ref_dummy.append(os.path.join(base_result_path, 'investments.gdx'))
        ref_dummy.append(os.path.join(base_result_path, 'report.gdx'))
        self.assertEqual(dummy_files, ref_dummy)

        # TEST 3: Find all *.inc for Dummy A and Base with Tools
        log.debug("TEST 3")
        dummy_inc_files = s_dummy_a.find_input_files('*.inc')
        # log.debug("Dummy A *.inc files:\n{0}".format(dummy_inc_files))
        ref_dummy_inc = list()
        ref_dummy_inc.append(os.path.join(dummy_a_f, 'change1.inc'))
        self.assertEqual(dummy_inc_files, ref_dummy_inc)

        # TEST 4: Find *.gdx files for Dummy A when Base has no results dirs
        # Delete Output folders
        log.debug("TEST 4")
        base_output_folders = os.listdir(base_output_f)
        # log.debug("base output folders:{0}".format(base_output_folders))
        for folder in base_output_folders:
            folder_path = os.path.join(base_output_f, folder)
            if os.path.isdir(folder_path):
                log.debug("Deleting folder: {0}".format(folder_path))
                shutil.rmtree(folder_path)
        dummy_gdx_files4 = s_dummy_a.find_input_files('*.gdx')
        # log.debug("Dummy A *.gdx files:\n{0}".format(dummy_gdx_files4))
        ref_dummy4 = list()
        ref_dummy4.append(os.path.join(dummy_a_f, 'data.gdx'))
        ref_dummy4.append(os.path.join(dummy_a_f, 'dummy3.gdx'))
        self.assertEqual(dummy_gdx_files4, ref_dummy4)

        # TEST 5: Find all *.inc for Dummy A with Tool and Base with no Tool
        # Detach tool from Base
        log.debug("TEST 5")
        s_base.detach_tool()
        dummy_inc_files2 = s_dummy_a.find_input_files('*.inc')
        # log.debug("Dummy A *.inc files:\n{0}".format(dummy_inc_files2))
        ref_dummy_inc2 = list()
        ref_dummy_inc2.append(os.path.join(dummy_a_f, 'change1.inc'))
        ref_dummy_inc2.append(os.path.join(base_f, 'choice.inc'))
        self.assertEqual(dummy_inc_files2, ref_dummy_inc2)

    @mock.patch('ui_main.TitanUI')
    def test_copy_input(self, mock_ui):
        log.info("Testing copy_input()")
        log.disable(level=log.ERROR)
        # Prepare test data
        self.prepare_test_data()
        # Fill ToolModel
        self.init_tool_model()
        # Get tool from ToolModel
        t_magic_invest = self._tool_model.find_tool('Magic Investments')
        if not t_magic_invest:
            self.skipTest("Cannot make test without Magic Investments tool")
        # Get tool from ToolModel
        t_magic_operation = self._tool_model.find_tool('Magic Operation')
        if not t_magic_operation:
            self.skipTest("Cannot make test without Magic Operation tool")
        # Get base Setup
        s_base = self._setup_model.find_index('Base').internalPointer()
        # Get Dummy A
        s_dummy_a = self._setup_model.find_index('Dummy A').internalPointer()
        # Attach Tool Magic Investments to Setup Base
        s_base.attach_tool(t_magic_invest)
        # Attach Tool Magic Operation to Setup Dummy A
        s_dummy_a.attach_tool(t_magic_operation)

        # Mock GUI
        gui = mock_ui()
        assert mock_ui is ui_main.TitanUI
        assert gui is ui_main.TitanUI()

        # Make a Magic Investments tool instance
        try:
            magic_invest_instance = t_magic_invest.create_instance(gui, s_base.cmdline_args,
                                                                   s_base.output_dir, s_base.short_name)
        except OSError:
            self.fail("Creating instance of Magic Investments failed")
        log.disable(level=log.NOTSET)
        # TEST 1
        # Copy input of Magic Investments to tool instance input folder
        retval = s_base.copy_input(t_magic_invest, gui, magic_invest_instance)
        self.assertTrue(retval)

        # TEST 2
        # Simulate that Magic Investments finished by copying Magic Investments output files to a timestamped folder
        base_result_path = create_dir(os.path.abspath(os.path.join(
            s_base.output_dir, s_base.short_name + create_output_dir_timestamp())))
        # Copy investments.gdx from \test\resources to a timestamped base Setup output folder
        src_file_path = os.path.abspath(os.path.join(
            APPLICATION_PATH, 'test', 'resources', 'test_output_for_magic_invest'))
        base_count = copy_files(src_file_path, base_result_path)
        # Magic Operation should now find investments.gdx from the latest \output\base\base-???\ folder
        # Make a Magic Operation tool instance
        log.disable(level=log.ERROR)
        try:
            magic_operation_instance = t_magic_operation.create_instance(gui, s_dummy_a.cmdline_args,
                                                                         s_dummy_a.output_dir,
                                                                         s_dummy_a.short_name)
        except OSError:
            self.fail("Creating instance of Magic Operation failed")
        log.disable(level=log.NOTSET)
        # Copy input of Magic Operation to tool instance input folder
        retval = s_dummy_a.copy_input(t_magic_operation, gui, magic_operation_instance)
        self.assertTrue(retval)

        # # Add model into Setup. Creates model input directories.
        # self.child_dummy_a.attach_tool(self.tool)
        # # Add input formats to model
        # self.tool.add_input_format(GDX_DATA_FMT)
        # self.tool.add_input_format(GAMS_INC_FILE)
        # # Copy dummy test files to setup model folders
        # self.prepare_test_data()
        # # DO THE ACTUAL TEST
        # self.child_dummy_a.pop_model()
        # gdx_count = 1
        # inc_count = 1
        # for fmt in self.child_dummy_a.running_model.input_formats:
        #     # get_input_files gives the names of the input files in a list
        #     filenames = self.child_dummy_a.get_input_files(self.child_dummy_a.running_model, fmt)
        #     count = 0
        #     for file in filenames:
        #         # log.info(".%s file #%d: %s" % (fmt.extension, count, file))
        #         count += 1
        #     if fmt.extension == 'gdx':
        #         gdx_count = count
        #     elif fmt.extension == 'inc':
        #         inc_count = count
        # log.debug("GDX count:%d INC_count:%d" % (gdx_count, inc_count))
        # # Simply check that 4 gdx files and 2 inc files were found
        # self.assertEqual(gdx_count, 4)
        # self.assertEqual(inc_count, 2)
        # # # This is how you can check variables if a test fails
        # # try:
        # #     self.assertTrue(False)
        # # except AssertionError as e:
        # #     print("Assertion error caught")
        # #     # Do something with variables
        # #     raise e

    @mock.patch('ui_main.TitanUI', autospec=True)
    def test_execute_base_setup(self, mock_ui):
        """Execute Base Setup with no Tool."""
        log.debug("Testing execute()")
        gui = mock_ui()
        assert mock_ui is ui_main.TitanUI
        assert gui is ui_main.TitanUI()
        base = self._setup_model.find_index('Base').internalPointer()
        base.execute(gui)
        self.assertTrue(base.is_ready)

    @skip("Method 'collect_input_files' does not exist")
    def test_collect_input_files(self):
        # TODO: Test here that changes in child Setup input files have an effect (change1.inc)
        pass
        # log.info("Testing collect_input_files()")
        # # Delete files from test model input folders except .gitignore
        # self.delete_files(self.tool.input_dir)
        # # Add model into Setup. Creates model input directories.
        # self.child_dummy_a.attach_tool(self.tool)
        # # Add input formats to model
        # self.tool.add_input_format(GDX_DATA_FMT)
        # self.tool.add_input_format(GAMS_INC_FILE)
        # # Copy dummy test files to setup model folders
        # self.prepare_test_data()
        # self.child_dummy_a.pop_model()
        # # DO THE ACTUAL TEST
        # self.child_dummy_a.collect_input_files()
        # # Check that created changes.inc is the same as reference changes.inc
        # changes_path = os.path.abspath(os.path.join(self.tool.input_dir, 'changes.inc'))
        # changes_ref_path = os.path.abspath(os.path.join(APPLICATION_PATH, 'test', 'resources',
        #                                                 'test_input', 'changes_reference.inc'))
        # # Check that both have the same number of lines
        # with open(changes_path, 'r') as changes:
        #     n_changes = sum(1 for line in changes)
        # with open(changes_ref_path, 'r') as ref:
        #     n_ref = sum(1 for line in ref)
        # self.assertEqual(n_changes, n_ref, "Number of lines in changes.inc and reference file does not match")
        # # Check files line by line
        # mismatch_found = False
        # n = 0
        # with open(changes_path, 'r') as changes:
        #     with open(changes_ref_path, 'r') as ref:
        #         for line in changes:
        #             n += 1
        #             ref_line = ref.readline()
        #             if line == ref_line:
        #                 # log.debug("\nLine #%d:>\n%smatches line:>\n%s" % (n, line, ref_line))
        #                 pass
        #             else:
        #                 log.debug("\nMismatch on Line #%d:>\n%sand line:>\n%s" % (n, line, ref_line))
        #                 mismatch_found = True
        # self.assertFalse(mismatch_found, "There was a mismatch in changes.inc and reference file")

    @skip("Obsolete")
    def test_execute_and_model_finished(self):
        """Executes a setup tree with base setup (no model) and one setup (gams model)
        with base parent. Skips start_process() and goes straight to model_finished().
        """
        log.info("Testing execute() and model_finished()")
        # Add input formats to model
        self.tool.add_input_format(GDX_DATA_FMT)
        self.tool.add_input_format(GAMS_INC_FILE)
        self.tool.add_output_format(GDX_DATA_FMT)
        # Create data parameters
        g = Dimension('g', 'generators')
        param = Dimension('param', 'parameters')
        data = DataParameter('data', 'generation data', '?', [g, param])
        # Add input data parameters to model
        self.tool.add_input(data)
        log.disable(level=log.ERROR)
        # Add model into Setup. Creates model input & output directories.
        self.child_dummy_a.attach_tool(self.tool, 'MIP=CPLEX')
        log.disable(level=log.NOTSET)
        # Copy dummy test files to setup model folders
        self.prepare_test_data()
        # DO THE ACTUAL TEST
        log.debug("STARTING EXECUTE")

        # effects = [self.side_effect_a, Exception("No more side effects left")]
        effects = [self.child_dummy_a.model_finished, Exception("No more effects left")]

        def side_effect(*args, **kwargs):
            effect = effects.pop(0)
            if isinstance(effect, Exception):
                raise effect
            gams_ret_val = 0
            log.debug("Calling %s(%d) for '%s'" % (effect.__name__, gams_ret_val, effect.__self__.name))
            effect(gams_ret_val)  # Calls popped method with argument
            # effect(*args, **kwargs)  # Calls the method

        # THIS WORKS!!!!!
        with mock.patch('tool.qsubprocess.QSubProcess.start_process',
                        side_effect=side_effect) as mock_start_process:
            self.child_dummy_a.execute()
            # log.debug("Mock calls: %s" % mock_start_process.mock_calls)
            assert mock_start_process is tool.qsubprocess.QSubProcess.start_process
        log.debug("EXECUTE FINISHED")
        # Assert that Base and Setup is_ready is True
        self.assertTrue(self.base_setup.is_ready)
        self.assertTrue(self.child_dummy_a.is_ready)

    @skip("Obsolete")
    def test_execute_with_multiple_models_in_setup(self):
        """Testing execute with base setup (no model) and child setup (2 GAMS models)."""
        log.info("Testing execute() with multiple models in a setup")
        # Add input formats to model
        self.tool.add_input_format(GDX_DATA_FMT)
        self.tool.add_input_format(GAMS_INC_FILE)
        self.tool.add_output_format(GDX_DATA_FMT)
        # Create data parameters
        g = Dimension('g', 'generators')
        param = Dimension('param', 'parameters')
        data = DataParameter('data', 'generation data', '?', [g, param])
        # Add input data parameters to model
        self.tool.add_input(data)
        log.disable(level=log.ERROR)
        # Add two models into Setup child_dummy_a. Creates model input & output directories.
        self.child_dummy_a.attach_tool(self.tool, 'MIP=CPLEX')
        self.child_dummy_a.attach_tool(self.tool_two)
        log.disable(level=log.NOTSET)
        effects = [self.child_dummy_a.model_finished, self.child_dummy_a.model_finished, Exception("No effects left")]

        def side_effect(*args, **kwargs):
            effect = effects.pop(0)
            if isinstance(effect, Exception):
                raise effect
            gams_ret_val = 0
            log.debug("Calling %s(%d) for '%s'" % (effect.__name__, gams_ret_val, effect.__self__.name))
            effect(gams_ret_val)  # Calls popped method with argument

        with mock.patch('tool.qsubprocess.QSubProcess.start_process', side_effect=side_effect) as mock_start_process:
            self.child_dummy_a.execute()
            assert mock_start_process is tool.qsubprocess.QSubProcess.start_process
        self.assertTrue(self.base_setup.is_ready)
        self.assertTrue(self.child_dummy_a.is_ready)

    @skip("Obsolete")
    def test_execute_with_three_setups_and_two_models(self):
        """Test execute with three setups: base -> setup_dummy_a -> setup_dummy_b.
        setup_dummy_a and setup_dummy_b have a GAMS model."""
        log.debug("Testing execute() with three setups and two models")
        log.disable(level=log.ERROR)
        self.child_dummy_a.attach_tool(self.tool, 'MIP=CPLEX')
        self.child_dummy_b = Setup('Setup Dummy B', 'Setup with parent A', self.project, self.child_dummy_a)
        self.child_dummy_b.attach_tool(self.tool_two)
        log.disable(level=log.NOTSET)
        effects = [self.child_dummy_a.model_finished, self.child_dummy_b.model_finished, Exception("No effects left")]

        def side_effect(*args, **kwargs):
            effect = effects.pop(0)
            if isinstance(effect, Exception):
                raise effect
            gams_ret_val = 0
            log.debug("Calling %s(%d) for '%s'" % (effect.__name__, gams_ret_val, effect.__self__.name))
            effect(gams_ret_val)  # Calls popped method with argument

        with mock.patch('tool.qsubprocess.QSubProcess.start_process', side_effect=side_effect) as mock_start_process:
            self.child_dummy_b.execute()
            assert mock_start_process is tool.qsubprocess.QSubProcess.start_process
        self.assertTrue(self.base_setup.is_ready)
        self.assertTrue(self.child_dummy_a.is_ready)
        self.assertTrue(self.child_dummy_b.is_ready)  # TODO: Fails because of bug in execute()

    @skip("Obsolete")
    def test_execute_with_three_setups_and_one_model(self):
        """Test execute with three setups: base -> setup_dummy_a -> setup_dummy_b.
        setup_dummy_b has a GAMS model."""
        log.debug("Testing execute() with three setups and one model")
        self.child_dummy_b = Setup('Setup Dummy B', 'Setup with parent A', self.project, self.child_dummy_a)
        log.disable(level=log.ERROR)
        self.child_dummy_b.attach_tool(self.tool_two)
        log.disable(level=log.NOTSET)
        effects = [self.child_dummy_b.model_finished, Exception("No effects left")]

        def side_effect(*args, **kwargs):
            effect = effects.pop(0)
            if isinstance(effect, Exception):
                raise effect
            gams_ret_val = 0
            log.debug("Calling %s(%d) for '%s'" % (effect.__name__, gams_ret_val, effect.__self__.name))
            effect(gams_ret_val)  # Calls popped method with argument
        with mock.patch('tool.qsubprocess.QSubProcess.start_process',
                        side_effect=side_effect) as mock_start_process:
            self.child_dummy_b.execute()
            assert mock_start_process is tool.qsubprocess.QSubProcess.start_process
        self.assertTrue(self.base_setup.is_ready)
        self.assertTrue(self.child_dummy_a.is_ready)
        self.assertTrue(self.child_dummy_b.is_ready)

    @skip("Obsolete")
    def test_execute_with_three_setups(self):
        """Test execute with three setups: base -> setup_dummy_a -> setup_dummy_b."""
        log.debug("Testing execute() with three setups")
        self.child_dummy_b = Setup('Setup Dummy B', 'Setup with parent A', self.project, self.child_dummy_a)
        self.child_dummy_b.execute()
        # with mock.patch('model.qsubprocess.QSubProcess.start_process',
        #                 side_effect=self.side_effect) as mock_start_process:
        #     self.child_dummy_b.execute()
        #     assert mock_start_process is model.qsubprocess.QSubProcess.start_process
        self.assertTrue(self.base_setup.is_ready)
        self.assertTrue(self.child_dummy_a.is_ready)
        self.assertTrue(self.child_dummy_b.is_ready)

    def prepare_test_data(self):
        """Helper function to copy test input data from \test\resources\test_input
        into appropriate test folders. NOTE: Call this function after attach_tool has
        been called."""
        log.info("Copying test files")
        # Create path strings for easier reference
        # Path to test input
        src_f = os.path.abspath(os.path.join(APPLICATION_PATH, 'test', 'resources', 'test_input'))
        # Path to base setup input (src)
        src_base_f = os.path.join(src_f, 'base')
        # Path to Dummy A setup input (src)
        src_dummy_a_f = os.path.join(src_f, 'dummy_a')
        # Path to Dummy B setup input (src)
        src_dummy_b_f = os.path.join(src_f, 'dummy_b')

        if not self._project:
            raise SkipTest("Test skipped. No project found")
        dst_base_f = os.path.join(self._project.project_dir, 'input', 'base')
        dst_dummy_a_f = os.path.join(self._project.project_dir, 'input', 'dummy_a')
        dst_dummy_b_f = os.path.join(self._project.project_dir, 'input', 'dummy_b')

        # Check that source test input folders exist
        if not os.path.exists(src_base_f):
            raise SkipTest("Test skipped. Base (src) input folder missing <{0}>\n".format(src_base_f))
        if not os.path.exists(src_dummy_a_f):
            raise SkipTest("Test skipped. Child (src) input folder missing <{0}>\n".format(src_dummy_a_f))
        if not os.path.exists(src_dummy_b_f):
            raise SkipTest("Test skipped. Child (src) input folder missing <{0}>\n".format(src_dummy_b_f))
        # Check that destination project input folders exist (created by SceletonProject())
        if not os.path.exists(dst_base_f):
            raise SkipTest("Test skipped. Base (dst) input folder not found <{0}>\n".format(dst_base_f))
        if not os.path.exists(dst_dummy_a_f):
            raise SkipTest("Test skipped. Child (dst) input folder not found <{0}>\n".format(dst_dummy_a_f))
        if not os.path.exists(dst_dummy_b_f):
            raise SkipTest("Test skipped. Child (dst) input folder not found <{0}>\n".format(dst_dummy_b_f))
        # Copy files from test input folders to appropriate test setup folders
        base_count = copy_files(src_base_f, dst_base_f)
        dummy_a_count = copy_files(src_dummy_a_f, dst_dummy_a_f)
        dummy_b_count = copy_files(src_dummy_b_f, dst_dummy_b_f)
        # log.debug("copied {0} files to folder: {1}".format(base_count, dst_base_f))
        # log.debug("copied {0} files to folder: {1}".format(dummy_a_count, dst_dummy_a_f))
        # log.debug("copied {0} files to folder: {1}".format(dummy_b_count, dst_dummy_b_f))

    def delete_files(self, dir_path):
        """Helper function to delete all files from folder dir_path excluding .gitignore."""
        file_list = os.listdir(dir_path)
        for file in file_list:
            if file == '.gitignore':
                log.debug("Skipping file .gitignore")
                continue
            file_path = os.path.abspath(os.path.join(dir_path, file))
            if os.path.isfile(file_path):
                log.debug("Deleting file:%s" % file_path)
                try:
                    os.remove(file_path)
                except OSError:
                    log.debug("Failed to delete file:%s" % file_path)

    @mock.patch('model.qsubprocess.QProcess', autospec=True)
    def _test_mocking(self, mock_qprocess_class):
        """Test mocking a QProcess class.
        NOTE: Remove preceding underscore '_' from method name to run test.

        Args:
            mock_qprocess_class: mocked QProcess class
        """
        log.debug("Testing QProcess mocking")
        tool.qsubprocess.QProcess()
        # log.debug("model.qsubprocess.Qprocess class dir:%s" % dir(model.qsubprocess.QProcess))
        # log.debug("MockQProcessClass class dir:%s" % dir(mock_qprocess_class))
        assert mock_qprocess_class is tool.qsubprocess.QProcess
        assert mock_qprocess_class.called

    @mock.patch('ui_main.TitanUI', autospec=True)
    def _test_ui_button_with_mocking(self, mock_ui):
        """Test TitanUI class mocking. Does not actually do anything because test_button()
        is mock method.
        NOTE: Remove preceding underscore '_' from method name to run test.
        """
        log.debug("Testing TitanUI test_button() with mocking")
        gui = mock_ui()
        gui.test_button()
        # log.debug("After call to gui.test_button()")
        # log.debug("ui_main.TitanUI() dir:%s" % dir(ui_main.TitanUI))
        # log.debug("mock_ui() dir:%s" % dir(mock_ui))
        assert ui_main.TitanUI is mock_ui

    def _test_ui_button(self):
        """Test TitanUI class mocking. This one calls test_button() as it
        is supposed to.
        NOTE: Remove preceding underscore '_' from method name to run test.
        """
        log.debug("Testing TitanUI test_button()")
        # noinspection PyCallByClass,PyTypeChecker
        ui_main.TitanUI.test_button(mock.Mock())  # This works
        # log.debug("After call to gui.test_button()")
        self.assertTrue(True)

    # noinspection PyArgumentList
    def side_effect_base(self, *args, **kwargs):
        """Side effect for mock start_process method. Instead of running
        start_process() jumps straight to model_finished() with the
        wanted GAMS return code.

        Args:
            args[0] (str): 'command' argument given to start_process method
        """
        # TODO: side_effect has a problem. It should call model_finished with
        # TODO: the current running model in self.running_model
        # TODO: Maybe add a return value that gives the current running setup
        log.debug("Called base_setup.start_process() with command arg: %s" % args[0])
        ret = 0
        self.base_setup.model_finished(ret)

    # noinspection PyArgumentList
    def side_effect_a(self, *args, **kwargs):
        """Side effect for mock start_process method when
        child_a.start_process() is called.

        Args:
            args[0] (str): 'command' argument given to start_process method
        """
        log.debug("Called child_dummy_a.start_process() with command arg: %s" % args[0])
        ret = 0
        self.child_dummy_a.model_finished(ret)

    # noinspection PyArgumentList
    def side_effect_b(self, *args, **kwargs):
        """Side effect for mock start_process method when
        child_dummy_b.start_process() is called.

        Args:
            args[0] (str): 'command' argument given to start_process method
        """
        log.debug("Called child_dummy_b.start_process() with command arg: %s" % args[0])
        ret = 0
        self.child_dummy_b.model_finished(ret)  # Should not be child_dummy_a every time.
