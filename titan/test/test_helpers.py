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
from helpers import create_dir, copy_files


class TestHelpers(TestCase):

    @classmethod
    def setUpClass(cls):
        log.basicConfig(stream=sys.stderr, level=log.DEBUG,
                        format='%(asctime)s %(levelname)s: %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S')

    def tearDown(self):
        if os.path.exists(os.path.abspath(os.path.join('C:\\', 'data', 'temp', 'test'))):
            shutil.rmtree(os.path.abspath(os.path.join('C:\\', 'data', 'temp', 'test')))
        if os.path.exists(os.path.abspath(os.path.join('C:\\', 'data', 'temp', 'test2'))):
            shutil.rmtree(os.path.abspath(os.path.join('C:\\', 'data', 'temp', 'test2')))

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

    def test_copy_files(self):
        """Test copying files with includes and excludes."""
        src_path = os.path.abspath(os.path.join('C:\\', 'data', 'temp', 'test'))
        dst_path = os.path.abspath(os.path.join('C:\\', 'data', 'temp', 'test2'))
        create_dir(src_path)
        create_dir(dst_path)
        # Make two files into folder
        with open(os.path.join(src_path, 'a.txt'), 'w') as out:
            out.write('buugi' + '\n')
        with open(os.path.join(src_path, 'b.txt'), 'w') as out:
            out.write('buugi' + '\n')
        with open(os.path.join(src_path, 'c.log'), 'w') as out:
            out.write('buugi' + '\n')

        for i in range(8):
            with self.subTest(i=i):
                self.delete_files(dst_path)
                if i == 0:
                    expected_n = 3
                    n = copy_files(src_path, dst_path)
                    self.assertEqual(n, expected_n)
                elif i == 1:
                    includes = ['*']
                    excludes = ['']
                    expected_n = 3
                    n = copy_files(src_path, dst_path, includes, excludes)
                    self.assertEqual(n, expected_n)
                elif i == 2:
                    includes = ['']
                    excludes = ['*']
                    expected_n = 0
                    n = copy_files(src_path, dst_path, includes, excludes)
                    self.assertEqual(n, expected_n)
                elif i == 3:
                    includes = ['*.txt']
                    excludes = ['*.log']
                    expected_n = 2
                    n = copy_files(src_path, dst_path, includes, excludes)
                    self.assertEqual(n, expected_n)
                elif i == 4:
                    includes = ['*.log']
                    excludes = ['']
                    expected_n = 1
                    n = copy_files(src_path, dst_path, includes, excludes)
                    self.assertEqual(n, expected_n)
                elif i == 5:
                    includes = ['*.log', 'a.*']
                    excludes = ['']
                    expected_n = 2
                    n = copy_files(src_path, dst_path, includes, excludes)
                    self.assertEqual(n, expected_n)
                elif i == 6:
                    includes = ['*.*']
                    excludes = ['?.txt']
                    expected_n = 1
                    n = copy_files(src_path, dst_path, includes, excludes)
                    self.assertEqual(n, expected_n)
                elif i == 7:
                    includes = ['*.*']
                    excludes = ['?.txt', '*.log']
                    expected_n = 0
                    n = copy_files(src_path, dst_path, includes, excludes)
                    self.assertEqual(n, expected_n)
                else:
                    self.fail("No subTest defined for iteration {0}".format(i))

    def delete_files(self, path):
        files = os.listdir(path)
        for file in files:
            file_path = os.path.join(path, file)
            if os.path.isfile(file_path):
                os.remove(file_path)
                log.debug("Deleted file: {0}".format(file_path))
