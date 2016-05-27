"""
Unit tests for Setup class.

@author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
@date: 26.2.2016
"""

from unittest import TestCase, SkipTest, mock
import os
import sys
import shutil
import logging as log
from tool import Setup, Dimension, DataParameter
import tool
import ui_main
from GAMS import GAMSModel, GDX_DATA_FMT, GAMS_INC_FILE
from config import APPLICATION_PATH, PROJECT_DIR
from tools import copy_files, create_dir
from project import SceletonProject


class TestSetup(TestCase):
    # TODO: Create Setups into SetupModel
    # TODO: Move test input files into appropriate folder
    # TODO: Mock create_dir so that directories are not actually created
    # TODO: Fix or move execution tests

    # add_msg_signal = mock.Mock()  # If a mock signal is needed

    def setUp(self):
        log.basicConfig(stream=sys.stderr, level=log.DEBUG,
                        format='%(asctime)s %(levelname)s: %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S')
        # log.info("Setting up")
        log.disable(level=log.ERROR)
        self.project = SceletonProject('Unit Test Project', ' ')
        self.magic_model_file = os.path.join(APPLICATION_PATH, 'test', 'resources', 'test_model', 'magic.gms')
        self.magic_model_path = os.path.split(self.magic_model_file)[0]
        self.base_setup = Setup('Test base', 'Base Setup for testing', self.project)
        self.child_dummy_a = Setup('Setup Dummy A', 'Setup with parent Base', self.project, self.base_setup)
        self.child_dummy_b = None  # Placeholder for a third setup
        self.tool = GAMSModel('Test GAMS Magic Tool', 'Tool for testing.', self.magic_model_path,
                               self.magic_model_file, 'input', 'output')
        self.tool_two = GAMSModel('Another Test GAMS Magic Tool', 'Second model for testing.',
                                   self.magic_model_path, self.magic_model_file, 'input', 'output')
        log.disable(level=log.NOTSET)

    def tearDown(self):
        # log.info("Tearing down")
        if os.path.exists(os.path.abspath(os.path.join('C:\\', 'data', 'temp', 'test'))):
            shutil.rmtree(os.path.abspath(os.path.join('C:\\', 'data', 'temp', 'test')))
        if os.path.exists(self.base_setup.input_dir):
            # log.info("Removing directory: %s" % self.base_setup.input_dir)
            shutil.rmtree(self.base_setup.input_dir)
        if os.path.exists(self.base_setup.output_dir):
            # log.info("Removing directory: %s" % self.base_setup.output_dir)
            shutil.rmtree(self.base_setup.output_dir)
        # Remove folders created while making setup child_dummy_a
        if os.path.exists(os.path.join(self.child_dummy_a.input_dir, self.tool.short_name)):
            # log.info("Removing directory: %s" % os.path.join(self.child_dummy_a.input_dir, self.tool.short_name))
            shutil.rmtree(os.path.join(self.child_dummy_a.input_dir, self.tool.short_name))
        if os.path.exists(os.path.join(self.child_dummy_a.output_dir, self.tool.short_name)):
            # log.info("Removing directory: %s" % os.path.join(self.child_dummy_a.output_dir, self.tool.short_name))
            shutil.rmtree(os.path.join(self.child_dummy_a.output_dir, self.tool.short_name))
        if os.path.exists(self.child_dummy_a.input_dir):
            # log.info("Removing directory: %s" % self.child_dummy_a.input_dir)
            shutil.rmtree(self.child_dummy_a.input_dir)
        if os.path.exists(self.child_dummy_a.output_dir):
            # log.info("Removing directory: %s" % self.child_dummy_a.output_dir)
            shutil.rmtree(self.child_dummy_a.output_dir)
        # Remove folders created while making setup child_dummy_b
        if self.child_dummy_b:  # Remove only if child_dummy_b available
            if os.path.exists(os.path.join(self.child_dummy_b.input_dir, self.tool.short_name)):
                shutil.rmtree(os.path.join(self.child_dummy_b.input_dir, self.tool.short_name))
            if os.path.exists(os.path.join(self.child_dummy_b.output_dir, self.tool.short_name)):
                shutil.rmtree(os.path.join(self.child_dummy_b.output_dir, self.tool.short_name))
            if os.path.exists(self.child_dummy_b.input_dir):
                shutil.rmtree(self.child_dummy_b.input_dir)
            if os.path.exists(self.child_dummy_b.output_dir):
                shutil.rmtree(self.child_dummy_b.output_dir)

    def test_create_dir(self):
        # Test create_dir() function in tools.py
        log.info("Testing create_dir()")
        basepath = os.path.abspath(os.path.join('C:\\', 'data', 'temp'))
        folder = 'test'
        create_dir(basepath, folder)
        self.assertTrue(os.path.exists(os.path.join(basepath, folder)))

    def test_create_dir_without_second_argument(self):
        log.info("Testing create_dir_without_second_argument()")
        basepath = os.path.abspath(os.path.join('C:\\', 'data', 'temp', 'test'))
        create_dir(basepath)
        self.assertTrue(os.path.exists(basepath))

    def test_create_dir_with_pardir(self):
        """ Note: makedirs() will become confused if the path
            elements to create include pardir (eg. ”..” on UNIX systems)
            (from Python Docs).
        """
        log.info("Testing create_dir_with_pardir()")
        basepath = os.path.abspath(os.path.join('C:\\', 'data', os.path.pardir, 'data', 'temp', 'test'))
        folder = os.path.join(os.path.pardir, 'test')
        dir_path = create_dir(base_path=basepath, folder=folder)
        self.assertTrue(os.path.exists(dir_path))

    def test_add_tool(self):
        log.info("Testing add_tool()")
        # Test adding tool to Setup
        retval = self.child_dummy_a.add_tool(self.tool)
        self.assertTrue(retval)

    def test_collect_input_files(self):
        log.info("Testing collect_input_files()")
        # Delete files from test model input folders except .gitignore
        self.delete_files(self.tool.input_dir)
        # Add model into Setup. Creates model input directories.
        self.child_dummy_a.add_tool(self.tool)
        # Add input formats to model
        self.tool.add_input_format(GDX_DATA_FMT)
        self.tool.add_input_format(GAMS_INC_FILE)
        # Copy dummy test files to setup model folders
        self.prepare_test_data()
        self.child_dummy_a.pop_model()
        # DO THE ACTUAL TEST
        self.child_dummy_a.collect_input_files()
        # Check that created changes.inc is the same as reference changes.inc
        changes_path = os.path.abspath(os.path.join(self.tool.input_dir, 'changes.inc'))
        changes_ref_path = os.path.abspath(os.path.join(APPLICATION_PATH, 'test', 'resources',
                                                        'test_input', 'changes_reference.inc'))
        # Check that both have the same number of lines
        with open(changes_path, 'r') as changes:
            n_changes = sum(1 for line in changes)
        with open(changes_ref_path, 'r') as ref:
            n_ref = sum(1 for line in ref)
        self.assertEqual(n_changes, n_ref, "Number of lines in changes.inc and reference file does not match")
        # Check files line by line
        mismatch_found = False
        n = 0
        with open(changes_path, 'r') as changes:
            with open(changes_ref_path, 'r') as ref:
                for line in changes:
                    n += 1
                    ref_line = ref.readline()
                    if line == ref_line:
                        # log.debug("\nLine #%d:>\n%smatches line:>\n%s" % (n, line, ref_line))
                        pass
                    else:
                        log.debug("\nMismatch on Line #%d:>\n%sand line:>\n%s" % (n, line, ref_line))
                        mismatch_found = True
        self.assertFalse(mismatch_found, "There was a mismatch in changes.inc and reference file")

    def test_get_input_files(self):
        log.info("Testing get_input_files()")
        # Add model into Setup. Creates model input directories.
        self.child_dummy_a.add_tool(self.tool)
        # Add input formats to model
        self.tool.add_input_format(GDX_DATA_FMT)
        self.tool.add_input_format(GAMS_INC_FILE)
        # Copy dummy test files to setup model folders
        self.prepare_test_data()
        # DO THE ACTUAL TEST
        self.child_dummy_a.pop_model()
        gdx_count = 1
        inc_count = 1
        for fmt in self.child_dummy_a.running_model.input_formats:
            # get_input_files gives the names of the input files in a list
            filenames = self.child_dummy_a.get_input_files(self.child_dummy_a.running_model, fmt)
            count = 0
            for file in filenames:
                # log.info(".%s file #%d: %s" % (fmt.extension, count, file))
                count += 1
            if fmt.extension == 'gdx':
                gdx_count = count
            elif fmt.extension == 'inc':
                inc_count = count
        log.debug("GDX count:%d INC_count:%d" % (gdx_count, inc_count))
        # Simply check that 4 gdx files and 2 inc files were found
        self.assertEqual(gdx_count, 4)
        self.assertEqual(inc_count, 2)
        # # This is how you can check variables if a test fails
        # try:
        #     self.assertTrue(False)
        # except AssertionError as e:
        #     print("Assertion error caught")
        #     # Do something with variables
        #     raise e

    def test_save(self):
        """Tests only that .json files are saved to \input\ folder."""
        log.info("Testing save()")
        self.base_setup.save()
        self.child_dummy_a.save()
        base_json_filename = self.base_setup.short_name + '.json'
        child_json_filename = self.child_dummy_a.short_name + '.json'
        json_save_path = os.path.abspath(os.path.join(PROJECT_DIR, 'input'))
        base_json_path = os.path.join(json_save_path, base_json_filename)
        child_json_path = os.path.join(json_save_path, child_json_filename)
        self.assertTrue(os.path.exists(base_json_path))
        self.assertTrue(os.path.exists(child_json_path))
        self.delete_files(json_save_path)

    def test_pop_model(self):
        log.info("Testing pop_model()")
        self.child_dummy_a.add_tool(self.tool)
        # Pop next model into model.running_model
        self.child_dummy_a.pop_model()
        retval = False
        if self.child_dummy_a.running_model.__class__.__name__ == 'GAMSModel':
            retval = True
        self.assertTrue(retval)

    def test_pop_model_from_empty_dict(self):
        log.info("Testing pop_model_from_empty_dict()")
        # Pop a model from an empty dictionary
        self.assertRaises(KeyError, self.child_dummy_a.models.popitem)

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
        self.child_dummy_a.add_tool(self.tool, 'MIP=CPLEX')
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
        self.child_dummy_a.add_tool(self.tool, 'MIP=CPLEX')
        self.child_dummy_a.add_tool(self.tool_two)
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

    def test_execute_with_base_setup(self):
        """Test execute with just base setup (no model)."""
        log.debug("Testing execute() with base setup")
        self.base_setup.execute()
        # with mock.patch('model.qsubprocess.QSubProcess.start_process',
        #                 side_effect=self.side_effect_base) as mock_start_process:
        #     self.base_setup.execute()
        #     assert mock_start_process is model.qsubprocess.QSubProcess.start_process
        self.assertTrue(self.base_setup.is_ready)

    def test_execute_with_three_setups_and_two_models(self):
        """Test execute with three setups: base -> setup_dummy_a -> setup_dummy_b.
        setup_dummy_a and setup_dummy_b have a GAMS model."""
        log.debug("Testing execute() with three setups and two models")
        log.disable(level=log.ERROR)
        self.child_dummy_a.add_tool(self.tool, 'MIP=CPLEX')
        self.child_dummy_b = Setup('Setup Dummy B', 'Setup with parent A', self.project, self.child_dummy_a)
        self.child_dummy_b.add_tool(self.tool_two)
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

    def test_execute_with_three_setups_and_one_model(self):
        """Test execute with three setups: base -> setup_dummy_a -> setup_dummy_b.
        setup_dummy_b has a GAMS model."""
        log.debug("Testing execute() with three setups and one model")
        self.child_dummy_b = Setup('Setup Dummy B', 'Setup with parent A', self.project, self.child_dummy_a)
        log.disable(level=log.ERROR)
        self.child_dummy_b.add_tool(self.tool_two)
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
        into appropriate test folders. NOTE: Call this function after add_tool has
        been called."""
        log.info("Copying test files")
        # Create path strings for easier reference
        # Path to test input
        input_f = os.path.abspath(os.path.join(APPLICATION_PATH, 'test', 'resources', 'test_input'))
        # Path to base setup input for model magic (src)
        base_input_f = os.path.join(input_f, 'base', self.tool.short_name)
        # Path to child setup input for model magic (src)
        child_input_f = os.path.join(input_f, 'child', self.tool.short_name)
        # Path to base setup input for model magic (dst). This must be made manually.
        base_model_f = os.path.join(self.base_setup.input_dir, self.tool.short_name)
        # Path to child setup input for model magic (dst)
        child_model_f = os.path.join(self.child_dummy_a.input_dir, self.tool.short_name)
        # TODO: Make input folder for model in base setup as well, when a model is added to setup.
        # This is not done at the moment when a model is added to Setup
        create_dir(base_model_f)
        # Check that source test input folders exist
        if not os.path.exists(base_input_f):
            raise SkipTest("Test skipped. Base (src) input folder missing <{0}>\n".format(base_input_f))
        if not os.path.exists(child_input_f):
            raise SkipTest("Test skipped. Child (src) input folder missing <{0}>\n".format(child_input_f))
        # Check that destination test input folders exist (Created by add_tool())
        if not os.path.exists(base_model_f):
            raise SkipTest("Test skipped. Base (dst) input folder not found <{0}>\n".format(base_model_f))
        if not os.path.exists(child_model_f):
            raise SkipTest("Test skipped. Child (dst) input folder not found <{0}>\n".format(child_model_f))
        # Copy files from test input folders to appropriate test setup folders
        base_count = copy_files(base_input_f, base_model_f)
        child_count = copy_files(child_input_f, child_model_f)
        log.debug("copied {0} files to folder: {1}".format(base_count, base_model_f))
        log.debug("copied {0} files to folder: {1}".format(child_count, child_model_f))

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
