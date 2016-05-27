"""
Unit tests for titanUI class.

@author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
@date: 7.4.2016
"""

from unittest import TestCase
import sys
import logging as log


class TestTitanUI(TestCase):

    def setUp(self):
        log.basicConfig(stream=sys.stderr, level=log.DEBUG,
                        format='%(asctime)s %(levelname)s: %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S')
        log.info("Setting up")

    def tearDown(self):
        log.info("Tearing down")

    def test_get_selected_setup_base_index(self):
        self.fail()

    def test_get_selected_setup_siblings(self):
        self.fail()
