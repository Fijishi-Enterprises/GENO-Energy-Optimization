"""
Unit tests for SetupModel class.

@author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
@date: 7.4.2016
"""

import unittest
from unittest import mock
import sys
import logging as log
from PyQt5.Qt import QModelIndex
from setup import Setup
from models import SetupModel
from project import SceletonProject


class TestSetupModel(unittest.TestCase):
    def setUp(self):
        log.basicConfig(stream=sys.stderr, level=log.DEBUG,
                        format='%(asctime)s %(levelname)s: %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S')
        log.info("Setting up")
        self._project = SceletonProject('Unittest Project', 'a project for unit tests')
        self._root = Setup('root', 'root node for Setups,', self._project)
        self.test_model = self.make_test_model()

    def tearDown(self):
        log.info("Tearing down")
        self.test_model = None
        # TODO: Remove Setup input directories (and maybe the whole unittest_project directory)

    @mock.patch('models.AnimatedSpinningWheelIcon')
    def make_test_model(self, anim_icon):
        """Mock spinning wheel icon class."""
        SetupModel.animated_icon = anim_icon
        test_model = SetupModel(self._root)
        return test_model

    def test_get_siblings(self):
        """Test if get_siblings returns indices a, b, c if given index a."""
        log.info("Testing get_siblings()")
        self.create_setups_1()
        expected_output = list()
        expected_output.append(self.a_ind)
        expected_output.append(self.b_ind)
        expected_output.append(self.c_ind)
        actual_output = list()
        index = self.a_ind
        actual_output = self.test_model.get_siblings(index)
        # for ind in actual_output:
        #     log.debug("%s" % self.test_model.get_setup(ind).name)
        self.assertEqual(expected_output, actual_output)

    @unittest.skip("Not ready")
    def test_get_next_setup(self):
        self.fail()

    def test_breadth_first_setups_1(self):
        """get_next_setup is called the first time when Base Setup has already finished.
        Expected output should start from the first child of Base.
        """
        breadth_first = True
        # Create Setups 1
        self.create_setups_1()
        # Create expected output
        exp_output = self.expected_output_for_setups_1(breadth_first=breadth_first)
        # List for actual output
        act_output = list()
        # Get first Setup
        ret = self.test_model.get_next_setup(breadth_first=True)
        # Get next Setup until None is returned
        while ret is not None:
            # Set Setup ready
            self.test_model.get_setup(ret).is_ready = True
            act_output.append(ret.internalPointer().name)
            ret = self.test_model.get_next_setup(breadth_first=breadth_first)
        self.assertEqual(act_output, exp_output)

    def test_breadth_first_setups_2(self):
        """get_next_setup is called the first time when Base Setup has already finished.
        Expected output should start from the first child of Base.
        """
        breadth_first = True
        # Create Setups 2
        self.create_setups_2()
        # Create expected output
        exp_output = self.expected_output_for_setups_2(breadth_first=breadth_first)
        # List for actual output
        act_output = list()
        # Get first Setup
        ret = self.test_model.get_next_setup(breadth_first=breadth_first)
        # Get next Setup until None is returned
        while ret is not None:
            # Set Setup ready
            self.test_model.get_setup(ret).is_ready = True
            act_output.append(ret.internalPointer().name)
            ret = self.test_model.get_next_setup(breadth_first=breadth_first)
        self.assertEqual(act_output, exp_output)

    def test_breadth_first_setups_3(self):
        """get_next_setup is called the first time when Base Setup has already finished.
        Expected output should start from the first child of Base.
        """
        breadth_first = True
        # Create Setups 3
        self.create_setups_3()
        # Create expected output
        exp_output = self.expected_output_for_setups_3()
        # List for actual output
        act_output = list()
        # Get first Setup
        ret = self.test_model.get_next_setup(breadth_first=breadth_first)
        # Get next Setup until None is returned
        while ret is not None:
            # Set Setup ready
            self.test_model.get_setup(ret).is_ready = True
            act_output.append(ret.internalPointer().name)
            ret = self.test_model.get_next_setup(breadth_first=breadth_first)
        self.assertEqual(act_output, exp_output)

    def test_breadth_first_setups_4(self):
        """get_next_setup is called the first time when Base Setup has already finished.
        Expected output should start from the first child of Base.
        """
        breadth_first = True
        # Create Setups 4
        self.create_setups_4()
        # Create expected output
        exp_output = self.expected_output_for_setups_4()
        # List for actual output
        act_output = list()
        # Get first Setup
        ret = self.test_model.get_next_setup(breadth_first=breadth_first)
        # Get next Setup until None is returned
        while ret is not None:
            # Set Setup ready
            self.test_model.get_setup(ret).is_ready = True
            act_output.append(ret.internalPointer().name)
            ret = self.test_model.get_next_setup(breadth_first=breadth_first)
        self.assertEqual(act_output, exp_output)

    def test_breadth_first_setups_5(self):
        """get_next_setup is called the first time when Base Setup has already finished.
        Expected output should start from the first child of Base.
        """
        breadth_first = True
        # Create Setups 5
        self.create_setups_5()
        # Create expected output
        exp_output = self.expected_output_for_setups_5(breadth_first=breadth_first)
        # List for actual output
        act_output = list()
        # Get first Setup
        ret = self.test_model.get_next_setup(breadth_first=breadth_first)
        # Get next Setup until None is returned
        while ret is not None:
            # Set Setup ready
            self.test_model.get_setup(ret).is_ready = True
            act_output.append(ret.internalPointer().name)
            ret = self.test_model.get_next_setup(breadth_first=breadth_first)
        self.assertEqual(act_output, exp_output)

    def test_depth_first_setups_1(self):
        """get_next_setup is called the first time when Base Setup has already finished.
        Expected output should start from the first child of Base.
        """
        breadth_first = False
        # Create Setups 1
        self.create_setups_1()
        # Create expected output
        exp_output = self.expected_output_for_setups_1(breadth_first=breadth_first)
        # List for actual output
        act_output = list()
        # Get first Setup
        ret = self.test_model.get_next_setup(breadth_first=breadth_first)
        # Get next Setup until None is returned
        while ret is not None:
            # Set Setup ready
            self.test_model.get_setup(ret).is_ready = True
            act_output.append(ret.internalPointer().name)
            ret = self.test_model.get_next_setup(breadth_first=breadth_first)
        self.assertEqual(act_output, exp_output)

    def test_depth_first_setups_2(self):
        """get_next_setup is called the first time when Base Setup has already finished.
        Expected output should start from the first child of Base.
        """
        breadth_first = False
        # Create Setups 2
        self.create_setups_2()
        # Create expected output
        exp_output = self.expected_output_for_setups_2(breadth_first=breadth_first)
        # List for actual output
        act_output = list()
        # Get first Setup
        ret = self.test_model.get_next_setup(breadth_first=breadth_first)
        # Get next Setup until None is returned
        while ret is not None:
            # Set Setup ready
            self.test_model.get_setup(ret).is_ready = True
            act_output.append(ret.internalPointer().name)
            ret = self.test_model.get_next_setup(breadth_first=breadth_first)
        self.assertEqual(act_output, exp_output)

    def test_depth_first_setups_3(self):
        """get_next_setup is called the first time when Base Setup has already finished.
        Expected output should start from the first child of Base.
        """
        breadth_first = False
        # Create Setups 3
        self.create_setups_3()
        # Create expected output
        exp_output = self.expected_output_for_setups_3()
        # List for actual output
        act_output = list()
        # Get first Setup
        ret = self.test_model.get_next_setup(breadth_first=breadth_first)
        # Get next Setup until None is returned
        while ret is not None:
            # Set Setup ready
            self.test_model.get_setup(ret).is_ready = True
            act_output.append(ret.internalPointer().name)
            ret = self.test_model.get_next_setup(breadth_first=breadth_first)
        self.assertEqual(act_output, exp_output)

    def test_depth_first_setups_4(self):
        """get_next_setup is called the first time when Base Setup has already finished.
        Expected output should start from the first child of Base.
        """
        breadth_first = False
        # Create Setups 4
        self.create_setups_4()
        # Create expected output
        exp_output = self.expected_output_for_setups_4()
        # List for actual output
        act_output = list()
        # Get first Setup
        ret = self.test_model.get_next_setup(breadth_first=breadth_first)
        # Get next Setup until None is returned
        while ret is not None:
            # Set Setup ready
            self.test_model.get_setup(ret).is_ready = True
            act_output.append(ret.internalPointer().name)
            ret = self.test_model.get_next_setup(breadth_first=breadth_first)
        self.assertEqual(act_output, exp_output)

    def test_depth_first_setups_5(self):
        """get_next_setup is called the first time when Base Setup has already finished.
        Expected output should start from the first child of Base.
        """
        breadth_first = False
        # Create Setups 5
        self.create_setups_5()
        # Create expected output
        exp_output = self.expected_output_for_setups_5(breadth_first=breadth_first)
        # List for actual output
        act_output = list()
        # Get first Setup
        ret = self.test_model.get_next_setup(breadth_first=breadth_first)
        # Get next Setup until None is returned
        while ret is not None:
            # Set Setup ready
            self.test_model.get_setup(ret).is_ready = True
            act_output.append(ret.internalPointer().name)
            ret = self.test_model.get_next_setup(breadth_first=breadth_first)
        self.assertEqual(act_output, exp_output)

    @unittest.skip("Not ready")
    def test_get_next_generation(self):
        self.fail()

    def create_setups_1(self):
        """Creates Setups:
        base
            a
                d
            b
            c
                e
        """
        log.disable(level=log.ERROR)
        # TODO: Mock create_dir method so that directories are not actually created
        #  Add Base
        self.test_model.insert_setup('base', 'Base Setup', self._project, 0)
        self.base_ind = self.test_model.index(0, 0, QModelIndex())
        # Add A
        self.test_model.insert_setup('A', 'A setup', self._project, 0, self.base_ind)
        self.a_ind = self.test_model.index(0, 0, self.base_ind)
        # Add B
        self.test_model.insert_setup('B', 'B setup', self._project, 1, self.base_ind)
        self.b_ind = self.test_model.index(1, 0, self.base_ind)
        # Add C
        self.test_model.insert_setup('C', 'C setup', self._project, 2, self.base_ind)
        self.c_ind = self.test_model.index(2, 0, self.base_ind)
        # Add D as child of A
        self.test_model.insert_setup('D', 'D setup', self._project, 0, self.a_ind)
        self.d_ind = self.test_model.index(0, 0, self.a_ind)
        # Add E as child of C
        self.test_model.insert_setup('E', 'E setup', self._project, 0, self.c_ind)
        self.e_ind = self.test_model.index(0, 0, self.c_ind)
        # Set Base as base index
        self.test_model.set_base(self.base_ind)
        log.disable(level=log.NOTSET)
        log.debug("Setups 1:\n{}".format(self._root.log()))

    def expected_output_for_setups_1(self, breadth_first=True):
        """Returns expected output for setups_1 according to given algorithm.
        Expected output for breadth_first
        a, b, c, d, e
        Expected output for depth_first
        a, d, b, c, e
        """
        out = list()
        if breadth_first:
            out.append(self.a_ind.internalPointer().name)
            out.append(self.b_ind.internalPointer().name)
            out.append(self.c_ind.internalPointer().name)
            out.append(self.d_ind.internalPointer().name)
            out.append(self.e_ind.internalPointer().name)
        else:
            out.append(self.a_ind.internalPointer().name)
            out.append(self.d_ind.internalPointer().name)
            out.append(self.b_ind.internalPointer().name)
            out.append(self.c_ind.internalPointer().name)
            out.append(self.e_ind.internalPointer().name)
        return out

    def create_setups_2(self):
        """Creates Setups:
        base
            a
                e
                    g
            b
                f
            c
            d
        """
        log.disable(level=log.ERROR)
        # TODO: Mock create_dir method so that directories are not actually created
        #  Add Base
        self.test_model.insert_setup('base', 'Base Setup', self._project, 0)
        self.base_ind = self.test_model.index(0, 0, QModelIndex())
        # Add A
        self.test_model.insert_setup('A', 'A setup', self._project, 0, self.base_ind)
        self.a_ind = self.test_model.index(0, 0, self.base_ind)
        # Add B
        self.test_model.insert_setup('B', 'B setup', self._project, 1, self.base_ind)
        self.b_ind = self.test_model.index(1, 0, self.base_ind)
        # Add C
        self.test_model.insert_setup('C', 'C setup', self._project, 2, self.base_ind)
        self.c_ind = self.test_model.index(2, 0, self.base_ind)
        # Add D
        self.test_model.insert_setup('D', 'D setup', self._project, 3, self.base_ind)
        self.d_ind = self.test_model.index(3, 0, self.base_ind)
        # Add E as child of A
        self.test_model.insert_setup('E', 'E setup', self._project, 0, self.a_ind)
        self.e_ind = self.test_model.index(0, 0, self.a_ind)
        # Add F as child of B
        self.test_model.insert_setup('F', 'F setup', self._project, 0, self.b_ind)
        self.f_ind = self.test_model.index(0, 0, self.b_ind)
        # Add G as child of E
        self.test_model.insert_setup('G', 'G setup', self._project, 0, self.e_ind)
        self.g_ind = self.test_model.index(0, 0, self.e_ind)

        # Set Base as base index
        self.test_model.set_base(self.base_ind)
        log.disable(level=log.NOTSET)
        log.debug("Setups 2:\n{}".format(self._root.log()))

    def expected_output_for_setups_2(self, breadth_first=True):
        """Returns expected output for setups_1 according to given algorithm.
        Expected output for breadth_first
        a, b, c, d, e, f, g
        Expected output for depth_first
        a, e, g, b, f, c, d
        """
        out = list()
        if breadth_first:
            out.append(self.a_ind.internalPointer().name)
            out.append(self.b_ind.internalPointer().name)
            out.append(self.c_ind.internalPointer().name)
            out.append(self.d_ind.internalPointer().name)
            out.append(self.e_ind.internalPointer().name)
            out.append(self.f_ind.internalPointer().name)
            out.append(self.g_ind.internalPointer().name)
        else:
            out.append(self.a_ind.internalPointer().name)
            out.append(self.e_ind.internalPointer().name)
            out.append(self.g_ind.internalPointer().name)
            out.append(self.b_ind.internalPointer().name)
            out.append(self.f_ind.internalPointer().name)
            out.append(self.c_ind.internalPointer().name)
            out.append(self.d_ind.internalPointer().name)
        return out

    def create_setups_3(self):
        """Creates Setups:
        base
            a
            b
            c
            d
                e
                    f
        """
        log.disable(level=log.ERROR)
        # TODO: Mock create_dir method so that directories are not actually created
        #  Add Base
        self.test_model.insert_setup('base', 'Base Setup', self._project, 0)
        self.base_ind = self.test_model.index(0, 0, QModelIndex())
        # Add A
        self.test_model.insert_setup('A', 'A setup', self._project, 0, self.base_ind)
        self.a_ind = self.test_model.index(0, 0, self.base_ind)
        # Add B
        self.test_model.insert_setup('B', 'B setup', self._project, 1, self.base_ind)
        self.b_ind = self.test_model.index(1, 0, self.base_ind)
        # Add C
        self.test_model.insert_setup('C', 'C setup', self._project, 2, self.base_ind)
        self.c_ind = self.test_model.index(2, 0, self.base_ind)
        # Add D
        self.test_model.insert_setup('D', 'D setup', self._project, 3, self.base_ind)
        self.d_ind = self.test_model.index(3, 0, self.base_ind)
        # Add E as child of D
        self.test_model.insert_setup('E', 'E setup', self._project, 0, self.d_ind)
        self.e_ind = self.test_model.index(0, 0, self.d_ind)
        # Add F as child of E
        self.test_model.insert_setup('F', 'F setup', self._project, 0, self.e_ind)
        self.f_ind = self.test_model.index(0, 0, self.e_ind)
        # Set Base as base index
        self.test_model.set_base(self.base_ind)
        log.disable(level=log.NOTSET)
        log.debug("Setups 3:\n{}".format(self._root.log()))

    def expected_output_for_setups_3(self):
        """Returns expected output for setups_1 according to given algorithm.
        Expected output for breadth_first
        a, b, c, d, e, f
        Expected output for depth_first (the same)
        a, b, c, d, e, f
        """
        out = list()
        out.append(self.a_ind.internalPointer().name)
        out.append(self.b_ind.internalPointer().name)
        out.append(self.c_ind.internalPointer().name)
        out.append(self.d_ind.internalPointer().name)
        out.append(self.e_ind.internalPointer().name)
        out.append(self.f_ind.internalPointer().name)
        return out

    def create_setups_4(self):
        """Creates Setups:
        base
            a
            b
            c
        """
        log.disable(level=log.ERROR)
        # TODO: Mock create_dir method so that directories are not actually created
        #  Add Base
        self.test_model.insert_setup('base', 'Base Setup', self._project, 0)
        self.base_ind = self.test_model.index(0, 0, QModelIndex())
        # Add A
        self.test_model.insert_setup('A', 'A setup', self._project, 0, self.base_ind)
        self.a_ind = self.test_model.index(0, 0, self.base_ind)
        # Add B
        self.test_model.insert_setup('B', 'B setup', self._project, 1, self.base_ind)
        self.b_ind = self.test_model.index(1, 0, self.base_ind)
        # Add C
        self.test_model.insert_setup('C', 'C setup', self._project, 2, self.base_ind)
        self.c_ind = self.test_model.index(2, 0, self.base_ind)
        # Set Base as base index
        self.test_model.set_base(self.base_ind)
        log.disable(level=log.NOTSET)
        log.debug("Setups 4:\n{}".format(self._root.log()))

    def expected_output_for_setups_4(self):
        """Returns expected output for setups_1 according to given algorithm.
        Expected output for breadth_first
        a, b, c
        Expected output for depth_first (the same)
        a, b, c
        """
        out = list()
        out.append(self.a_ind.internalPointer().name)
        out.append(self.b_ind.internalPointer().name)
        out.append(self.c_ind.internalPointer().name)
        return out

    def create_setups_5(self):
        """Creates Setups:
        base
            a
            b
                e
                    f
                        h
                    g
            c
            d
        """
        log.disable(level=log.ERROR)
        # TODO: Mock create_dir method so that directories are not actually created
        #  Add Base
        self.test_model.insert_setup('base', 'Base Setup', self._project, 0)
        self.base_ind = self.test_model.index(0, 0, QModelIndex())
        # Add A
        self.test_model.insert_setup('A', 'A setup', self._project, 0, self.base_ind)
        self.a_ind = self.test_model.index(0, 0, self.base_ind)
        # Add B
        self.test_model.insert_setup('B', 'B setup', self._project, 1, self.base_ind)
        self.b_ind = self.test_model.index(1, 0, self.base_ind)
        # Add C
        self.test_model.insert_setup('C', 'C setup', self._project, 2, self.base_ind)
        self.c_ind = self.test_model.index(2, 0, self.base_ind)
        # Add D
        self.test_model.insert_setup('D', 'D setup', self._project, 3, self.base_ind)
        self.d_ind = self.test_model.index(3, 0, self.base_ind)
        # Add E as child of B
        self.test_model.insert_setup('E', 'E setup', self._project, 0, self.b_ind)
        self.e_ind = self.test_model.index(0, 0, self.b_ind)
        # Add F as child of E
        self.test_model.insert_setup('F', 'F setup', self._project, 0, self.e_ind)
        self.f_ind = self.test_model.index(0, 0, self.e_ind)
        # Add G as child of E
        self.test_model.insert_setup('G', 'G setup', self._project, 1, self.e_ind)
        self.g_ind = self.test_model.index(1, 0, self.e_ind)
        # Add H as child of F
        self.test_model.insert_setup('H', 'H setup', self._project, 0, self.f_ind)
        self.h_ind = self.test_model.index(0, 0, self.f_ind)

        # Set Base as base index
        self.test_model.set_base(self.base_ind)
        log.disable(level=log.NOTSET)
        log.debug("Setups 5:\n{}".format(self._root.log()))

    def expected_output_for_setups_5(self, breadth_first=True):
        """Returns expected output for setups_5 according to given algorithm.
        Expected output for breadth_first
        a, b, c, d, e, f, g, h
        Expected output for depth_first
        a, b, e, f, h, g, c, d
        """
        out = list()
        if breadth_first:
            out.append(self.a_ind.internalPointer().name)
            out.append(self.b_ind.internalPointer().name)
            out.append(self.c_ind.internalPointer().name)
            out.append(self.d_ind.internalPointer().name)
            out.append(self.e_ind.internalPointer().name)
            out.append(self.f_ind.internalPointer().name)
            out.append(self.g_ind.internalPointer().name)
            out.append(self.h_ind.internalPointer().name)
        else:
            out.append(self.a_ind.internalPointer().name)
            out.append(self.b_ind.internalPointer().name)
            out.append(self.e_ind.internalPointer().name)
            out.append(self.f_ind.internalPointer().name)
            out.append(self.h_ind.internalPointer().name)
            out.append(self.g_ind.internalPointer().name)
            out.append(self.c_ind.internalPointer().name)
            out.append(self.d_ind.internalPointer().name)
        return out

if __name__ == '__main__':
    unittest.main()
