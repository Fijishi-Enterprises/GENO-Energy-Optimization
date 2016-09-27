"""
Unit tests for helper functions in helpers.py file.

@author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
@date: 26.9.2016
"""

from unittest import TestCase
import sys
import os
import shutil
import logging as log
from helpers import create_dir


class TestTitanUI(TestCase):

    def setUp(self):
        log.basicConfig(stream=sys.stderr, level=log.DEBUG,
                        format='%(asctime)s %(levelname)s: %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S')
        log.info("Setting up")

    def tearDown(self):
        log.info("Tearing down")
        if os.path.exists(os.path.abspath(os.path.join('C:\\', 'data', 'temp', 'test'))):
            shutil.rmtree(os.path.abspath(os.path.join('C:\\', 'data', 'temp', 'test')))

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
