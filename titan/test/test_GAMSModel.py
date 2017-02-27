"""
Unit tests for GAMSModel class.

@author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
@date: 28.2.2016
"""

import unittest
from unittest import mock
import os
import sys
import shutil
import logging as log
import GAMS
from tool import Tool, ToolInstance
from config import APPLICATION_PATH, CONFIGURATION_FILE, GAMS_EXECUTABLE
import setup
from project import SceletonProject
from models import SetupModel
from configuration import ConfigurationParser


# noinspection PyUnusedLocal
class TestGAMSModel(unittest.TestCase):
    """Unit tests for GAMSModel class."""
    @classmethod
    def setUpClass(cls):
        log.basicConfig(stream=sys.stderr, level=log.DEBUG,
                        format='%(asctime)s %(levelname)s: %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S')

    def setUp(self):
        # Create GAMSModel by loading a test definition file
        self.instance = None
        self.tool_def = os.path.abspath(os.path.join(APPLICATION_PATH,
                                                     'test', 'resources',
                                                     'test_tool', 'testtool.json'))
        self.project = SceletonProject('Unittest Project', 'a project for unit tests')
        self._root = setup.Setup('root', 'root node for Setups,', self.project)
        self.setup_model = self.make_test_model()
        self.config = ConfigurationParser(CONFIGURATION_FILE)
        self.config.load()

    def tearDown(self):
        self.setup_model = None
        if self.instance:
            work_dir = self.instance.basedir
            # log.debug("Deleting tool work dir: {0}".format(work_dir))
            if os.path.exists(work_dir):
                shutil.rmtree(work_dir)

    @mock.patch('models.AnimatedSpinningWheelIcon')
    def make_test_model(self, anim_icon):
        """Mock spinning wheel icon class."""
        SetupModel.animated_icon = anim_icon
        test_model = SetupModel(self._root)
        return test_model

    def test_create_instance(self):
        """Test that GAMSModel class create_instance() method returns a ToolInstance class instance."""
        mock_ui = mock.Mock()
        log.disable(level=log.ERROR)  # Disable logging
        gams_model = GAMS.GAMSModel.load(self.tool_def, mock_ui)
        # GAMSModel.create_instance() returns a ToolInstance
        self.instance = GAMS.GAMSModel.create_instance(gams_model, ui=mock_ui,
                                                       setup_cmdline_args='', tool_output_dir='',
                                                       setup_name='')
        log.disable(level=log.NOTSET)  # Enable logging
        self.assertIsInstance(self.instance, ToolInstance)

    def test_load(self):
        """Test that load returns a GAMSModel class instance, which also a Tool class instance."""
        mock_ui = mock.Mock()
        # Load test tool definition and create a GAMSModel instance
        tool = GAMS.GAMSModel.load(self.tool_def, mock_ui)
        self.assertIsInstance(tool, GAMS.GAMSModel)
        self.assertIsInstance(tool, Tool)

    def make_cmd_base(self, gams_model):
        """Returns the command part that is the same for all test cases."""
        gams_path = self.config.get('general', 'gams_path')
        logoption_value = self.config.get('settings', 'logoption')
        cerr_value = self.config.get('settings', 'cerr')
        gams_exe_path = GAMS_EXECUTABLE
        if not gams_path == '':
            gams_exe_path = os.path.join(gams_path, GAMS_EXECUTABLE)
        cmd_base = "{0} \"".format(gams_exe_path) \
                   + gams_model.main_prgm + "\" Curdir=\"" \
                   + self.instance.basedir \
                   + "\\\" logoption={0} cerr={1}".format(logoption_value, cerr_value)
        return cmd_base

    @mock.patch('setup.create_dir')  # This mocks create_dir() from helpers. Yeah!!!
    def test_command1(self, mock_create_dir):
        """Test command line args: 1 Tool arg & 2 Setup args.
        Test that command like this is created:
        gams "magic.gms" Curdir="C:\data\GIT\TITAN\work\magic_invest__jgmy8yqi\" logoption=3 cerr=1 --INVEST=yes A=100 B=100
        """
        mock_ui = mock.Mock()
        log.disable(level=log.ERROR)  # Disable logging
        # Create GAMSModel Tool
        gams_model = GAMS.GAMSModel.load(self.tool_def, mock_ui)
        # Create Setup
        self.setup_model.insert_setup("a", "", self.project, 0)
        test_setup = self.setup_model.find_index("a").internalPointer()
        # Attach GAMSModel Tool to Setup
        test_setup.attach_tool(gams_model, cmdline_args='A=100 B=100')
        # Create instance just like when executing a Setup (returns ToolInstance)
        self.instance = GAMS.GAMSModel.create_instance(gams_model, ui=mock_ui,
                                                       setup_cmdline_args=test_setup.cmdline_args, tool_output_dir='',
                                                       setup_name="root")
        log.disable(level=log.NOTSET)  # Enable logging
        log.debug("[test_command1] command: '{0}'".format(self.instance.command))
        # log.debug("create_dir call_count: {0}".format(mock_create_dir.call_count))
        command_base = self.make_cmd_base(gams_model)
        correct_cmd = command_base + " --INVEST=yes A=100 B=100"
        self.assertEqual(correct_cmd, self.instance.command)

    @mock.patch('setup.create_dir')  # This mocks create_dir() from helpers package
    def test_command2(self, mock_create_dir):
        """Test command line args: 1 Tool arg.
        Test that command like this is created:
        gams "magic.gms" Curdir="C:\data\GIT\TITAN\work\magic_invest__jgmy8yqi\" logoption=3 cerr=1 --INVEST=yes
        """
        mock_ui = mock.Mock()
        log.disable(level=log.ERROR)  # Disable logging
        # Create GAMSModel Tool
        gams_model = GAMS.GAMSModel.load(self.tool_def, mock_ui)
        # Create Setup
        self.setup_model.insert_setup("a", "", self.project, 0)
        test_setup = self.setup_model.find_index("a").internalPointer()
        # Attach GAMSModel Tool to Setup
        test_setup.attach_tool(gams_model, cmdline_args='')
        # Create instance just like when executing a Setup (returns ToolInstance)
        self.instance = GAMS.GAMSModel.create_instance(gams_model, ui=mock_ui,
                                                       setup_cmdline_args=test_setup.cmdline_args, tool_output_dir='',
                                                       setup_name="root")
        log.disable(level=log.NOTSET)  # Enable logging
        log.debug("[test_command2] command: '{0}'".format(self.instance.command))
        command_base = self.make_cmd_base(gams_model)
        correct_cmd = command_base + " --INVEST=yes"
        self.assertEqual(correct_cmd, self.instance.command)

    @mock.patch('setup.create_dir')  # This mocks create_dir() from helpers package
    def test_command3(self, mock_create_dir):
        """Test command line args: 1 Tool arg & 1 Setup arg.
        Test that command like this is created:
        gams "magic.gms" Curdir="C:\data\GIT\TITAN\work\magic_operation__6yxz_ryl\" logoption=3 cerr=1 --INVEST=yes A=100
        """
        mock_ui = mock.Mock()
        log.disable(level=log.ERROR)  # Disable logging
        # Create GAMSModel Tool
        gams_model = GAMS.GAMSModel.load(self.tool_def, mock_ui)
        # Create Setup
        self.setup_model.insert_setup("a", "", self.project, 0)
        test_setup = self.setup_model.find_index("a").internalPointer()
        # Attach GAMSModel Tool to Setup
        test_setup.attach_tool(gams_model, cmdline_args='A=100')
        # Create instance just like when executing a Setup (returns ToolInstance)
        self.instance = GAMS.GAMSModel.create_instance(gams_model, ui=mock_ui,
                                                       setup_cmdline_args=test_setup.cmdline_args, tool_output_dir='',
                                                       setup_name="root")
        log.disable(level=log.NOTSET)  # Enable logging
        log.debug("[test_command3] command: '{0}'".format(self.instance.command))
        command_base = self.make_cmd_base(gams_model)
        correct_cmd = command_base + " --INVEST=yes A=100"
        self.assertEqual(correct_cmd, self.instance.command)

    @mock.patch('setup.create_dir')  # This mocks create_dir() from helpers package
    def test_command4(self, mock_create_dir):
        """Test command line args: Tool arg is None & 1 Setup arg
        Test that command like this is created:
        gams "magic.gms" Curdir="C:\data\GIT\TITAN\work\magic_operation__6yxz_ryl\" logoption=3 cerr=1 A=100
        """
        mock_ui = mock.Mock()
        log.disable(level=log.ERROR)  # Disable logging
        # Create GAMSModel Tool
        gams_model = GAMS.GAMSModel.load(self.tool_def, mock_ui)
        # Force Tool cmdline_arg to be None
        gams_model.cmdline_args = None
        # Create Setup
        self.setup_model.insert_setup("a", "", self.project, 0)
        test_setup = self.setup_model.find_index("a").internalPointer()
        # Attach GAMSModel Tool to Setup
        test_setup.attach_tool(gams_model, cmdline_args='A=100')
        # Create instance just like when executing a Setup (returns ToolInstance)
        self.instance = GAMS.GAMSModel.create_instance(gams_model, ui=mock_ui,
                                                       setup_cmdline_args=test_setup.cmdline_args, tool_output_dir='',
                                                       setup_name="root")
        log.disable(level=log.NOTSET)  # Enable logging
        log.debug("[test_command4] command: '{0}'".format(self.instance.command))
        command_base = self.make_cmd_base(gams_model)
        correct_cmd = command_base + " A=100"
        self.assertEqual(correct_cmd, self.instance.command)

    @mock.patch('setup.create_dir')  # This mocks create_dir() from helpers package
    def test_command5(self, mock_create_dir):
        """Test command line args: Tool arg is '' & 1 Setup arg
        Test that command like this is created:
        gams "magic.gms" Curdir="C:\data\GIT\TITAN\work\magic_operation__6yxz_ryl\" logoption=3 cerr=1 A=100
        """
        mock_ui = mock.Mock()
        log.disable(level=log.ERROR)  # Disable logging
        # Create GAMSModel Tool
        gams_model = GAMS.GAMSModel.load(self.tool_def, mock_ui)
        # Force Tool cmdline_arg to be ''
        gams_model.cmdline_args = ''
        # Create Setup
        self.setup_model.insert_setup("a", "", self.project, 0)
        test_setup = self.setup_model.find_index("a").internalPointer()
        # Attach GAMSModel Tool to Setup
        test_setup.attach_tool(gams_model, cmdline_args='A=100')
        # Create instance just like when executing a Setup (returns ToolInstance)
        self.instance = GAMS.GAMSModel.create_instance(gams_model, ui=mock_ui,
                                                       setup_cmdline_args=test_setup.cmdline_args, tool_output_dir='',
                                                       setup_name="root")
        log.disable(level=log.NOTSET)  # Enable logging
        log.debug("[test_command5] command: '{0}'".format(self.instance.command))
        command_base = self.make_cmd_base(gams_model)
        correct_cmd = command_base + " A=100"
        self.assertEqual(correct_cmd, self.instance.command)

    @mock.patch('setup.create_dir')  # This mocks create_dir() from helpers package
    def test_command6(self, mock_create_dir):
        """Test command line args: 1 Tool arg & Setup arg is None
        Test that command like this is created:
        gams "magic.gms" Curdir="C:\data\GIT\TITAN\work\magic_operation__6yxz_ryl\" logoption=3 cerr=1 --INVEST=yes
        """
        mock_ui = mock.Mock()
        log.disable(level=log.ERROR)  # Disable logging
        # Create GAMSModel Tool
        gams_model = GAMS.GAMSModel.load(self.tool_def, mock_ui)
        # Create Setup
        self.setup_model.insert_setup("a", "", self.project, 0)
        test_setup = self.setup_model.find_index("a").internalPointer()
        # Attach GAMSModel Tool to Setup
        test_setup.attach_tool(gams_model, cmdline_args=None)
        # Create instance just like when executing a Setup (returns ToolInstance)
        self.instance = GAMS.GAMSModel.create_instance(gams_model, ui=mock_ui,
                                                       setup_cmdline_args=test_setup.cmdline_args, tool_output_dir='',
                                                       setup_name="root")
        log.disable(level=log.NOTSET)  # Enable logging
        log.debug("[test_command6] command: '{0}'".format(self.instance.command))
        command_base = self.make_cmd_base(gams_model)
        correct_cmd = command_base + " --INVEST=yes"
        self.assertEqual(correct_cmd, self.instance.command)

    @mock.patch('setup.create_dir')  # This mocks create_dir() from helpers package
    def test_command7(self, mock_create_dir):
        """Test command line args: 1 Tool arg & Setup arg is ''
        Test that command like this is created:
        gams "magic.gms" Curdir="C:\data\GIT\TITAN\work\magic_operation__6yxz_ryl\" logoption=3 cerr=1 --INVEST=yes
        """
        mock_ui = mock.Mock()
        log.disable(level=log.ERROR)  # Disable logging
        # Create GAMSModel Tool
        gams_model = GAMS.GAMSModel.load(self.tool_def, mock_ui)
        # Create Setup
        self.setup_model.insert_setup("a", "", self.project, 0)
        test_setup = self.setup_model.find_index("a").internalPointer()
        # Attach GAMSModel Tool to Setup
        test_setup.attach_tool(gams_model, cmdline_args='')
        # Create instance just like when executing a Setup (returns ToolInstance)
        self.instance = GAMS.GAMSModel.create_instance(gams_model, ui=mock_ui,
                                                       setup_cmdline_args=test_setup.cmdline_args, tool_output_dir='',
                                                       setup_name="root")
        log.disable(level=log.NOTSET)  # Enable logging
        log.debug("[test_command7] command: '{0}'".format(self.instance.command))
        command_base = self.make_cmd_base(gams_model)
        correct_cmd = command_base + " --INVEST=yes"
        self.assertEqual(correct_cmd, self.instance.command)

    @mock.patch('setup.create_dir')  # This mocks create_dir() from helpers package
    def test_command8(self, mock_create_dir):
        """Test command line args: 2 Tool args
        Test that command like this is created:
        gams "magic.gms" Curdir="C:\data\GIT\TITAN\work\magic_operation__6yxz_ryl\" logoption=3 cerr=1 --INVEST=yes A=100
        """
        mock_ui = mock.Mock()
        log.disable(level=log.ERROR)  # Disable logging
        # Create GAMSModel Tool
        gams_model = GAMS.GAMSModel.load(self.tool_def, mock_ui)
        # Overwrite Tool cmdline_args
        gams_model.cmdline_args = "--INVEST=yes A=100"
        # Create Setup
        self.setup_model.insert_setup("a", "", self.project, 0)
        test_setup = self.setup_model.find_index("a").internalPointer()
        # Attach GAMSModel Tool to Setup
        test_setup.attach_tool(gams_model, cmdline_args='')
        # Create instance just like when executing a Setup (returns ToolInstance)
        self.instance = GAMS.GAMSModel.create_instance(gams_model, ui=mock_ui,
                                                       setup_cmdline_args=test_setup.cmdline_args, tool_output_dir='',
                                                       setup_name="root")
        log.disable(level=log.NOTSET)  # Enable logging
        log.debug("[test_command8] command: '{0}'".format(self.instance.command))
        command_base = self.make_cmd_base(gams_model)
        correct_cmd = command_base + " --INVEST=yes A=100"
        self.assertEqual(correct_cmd, self.instance.command)

    @mock.patch('setup.create_dir')  # This mocks create_dir() from helpers package
    def test_command9(self, mock_create_dir):
        """Test command line args: 2 Setup args
        Test that command like this is created:
        gams "magic.gms" Curdir="C:\data\GIT\TITAN\work\magic_operation__6yxz_ryl\" logoption=3 cerr=1 A=100 B=100
        """
        mock_ui = mock.Mock()
        log.disable(level=log.ERROR)  # Disable logging
        # Create GAMSModel Tool
        gams_model = GAMS.GAMSModel.load(self.tool_def, mock_ui)
        # Overwrite Tool cmdline_args
        gams_model.cmdline_args = None
        # Create Setup
        self.setup_model.insert_setup("a", "", self.project, 0)
        test_setup = self.setup_model.find_index("a").internalPointer()
        # Attach GAMSModel Tool to Setup
        test_setup.attach_tool(gams_model, cmdline_args='A=100 B=100')
        # Create instance just like when executing a Setup (returns ToolInstance)
        self.instance = GAMS.GAMSModel.create_instance(gams_model, ui=mock_ui,
                                                       setup_cmdline_args=test_setup.cmdline_args, tool_output_dir='',
                                                       setup_name="root")
        log.disable(level=log.NOTSET)  # Enable logging
        log.debug("[test_command9] command: '{0}'".format(self.instance.command))
        command_base = self.make_cmd_base(gams_model)
        correct_cmd = command_base + " A=100 B=100"
        self.assertEqual(correct_cmd, self.instance.command)

    @mock.patch('setup.create_dir')  # This mocks create_dir() from helpers package
    def test_command10(self, mock_create_dir):
        """Test command line args: Tool args is '', Setup args is None
        Test that command like this is created:
        gams "magic.gms" Curdir="C:\data\GIT\TITAN\work\magic_operation__6yxz_ryl\" logoption=3 cerr=1
        """
        mock_ui = mock.Mock()
        log.disable(level=log.ERROR)  # Disable logging
        # Create GAMSModel Tool
        gams_model = GAMS.GAMSModel.load(self.tool_def, mock_ui)
        # Overwrite Tool cmdline_args
        gams_model.cmdline_args = ''
        # Create Setup
        self.setup_model.insert_setup("a", "", self.project, 0)
        test_setup = self.setup_model.find_index("a").internalPointer()
        # Attach GAMSModel Tool to Setup
        test_setup.attach_tool(gams_model, cmdline_args=None)
        # Create instance just like when executing a Setup (returns ToolInstance)
        self.instance = GAMS.GAMSModel.create_instance(gams_model, ui=mock_ui,
                                                       setup_cmdline_args=test_setup.cmdline_args, tool_output_dir='',
                                                       setup_name="root")
        log.disable(level=log.NOTSET)  # Enable logging
        log.debug("[test_command10] command: '{0}'".format(self.instance.command))
        command_base = self.make_cmd_base(gams_model)
        correct_cmd = command_base
        self.assertEqual(correct_cmd, self.instance.command)

if __name__ == '__main__':
    unittest.main()
