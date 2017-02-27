"""
Unit tests for titanUI class.

@author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
@date: 7.4.2016
"""

import unittest
import sys
import logging as log


class TestTitanUI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        log.basicConfig(stream=sys.stderr, level=log.DEBUG,
                        format='%(asctime)s %(levelname)s: %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S')

    def setUp(self):
        log.info("Setting up")

    def tearDown(self):
        log.info("Tearing down")

    @unittest.skip("Not ready")
    def test_get_selected_setup_base_index(self):
        self.fail()

if __name__ == '__main__':
    unittest.main()
