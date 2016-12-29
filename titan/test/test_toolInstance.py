"""
Unit tests for ToolInstance class.

@author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
@date: 19.12.2016
"""

from unittest import TestCase, mock, skip
import logging as log
import os
import sys
import shutil
from GAMS import GAMSModel
from config import APPLICATION_PATH


class TestToolInstance(TestCase):
    """NOTE: This class is a work in progress and doesn't actually test anything yet."""

    def setUp(self):
        """Make a new ToolInstance to test/work directory according to some tool .json definition file."""
        log.basicConfig(stream=sys.stderr, level=log.DEBUG,
                        format='%(asctime)s %(levelname)s: %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S')
        # log.disable(level=log.ERROR)
        # log.disable(level=log.NOTSET)
        mock_ui = mock.Mock()
        tool_def = os.path.abspath(os.path.join(APPLICATION_PATH, 'test', 'resources', 'test_tool', 'testtool.json'))
        # Load test tool definition (creates a GAMSModel instance)
        self.test_tool = GAMSModel.load(tool_def, mock_ui)
        if not self.test_tool:
            log.debug("Failed to load test tool from tool def file: {0}".format(tool_def))
        # Make a ToolInstance
        cmdline_args = ''
        tool_output_dir = ''
        setup_name = ''
        self.instance = GAMSModel.create_instance(self.test_tool, mock_ui, cmdline_args, tool_output_dir, setup_name)
        log.debug("command: '{0}'".format(self.instance.command))
        log.debug("self.instance.basedir: {0}".format(self.instance.basedir))
        log.debug("GAMSModel main_dir: {0}".format(self.test_tool.main_dir))
        log.debug("GAMSModel main_prgm: {0}".format(self.test_tool.main_prgm))
        log.debug("output_dir: {0}".format(self.instance.tool_output_dir))

    def tearDown(self):
        work_dir = self.instance.basedir
        log.debug("Deleting tool work dir: {0}".format(work_dir))
        if os.path.exists(work_dir):
            shutil.rmtree(work_dir)

    @skip("Not ready")
    def test__checkout(self):
        self.fail()

    @skip("Not ready")
    def test_execute(self):
        self.fail()

    @skip("Not ready")
    def test_tool_finished(self):
        self.fail()

    @skip("Not ready")
    def test_remove(self):
        self.fail()

    @skip("Not ready")
    def test_copy_output(self):
        self.fail()
