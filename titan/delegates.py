"""
Custom PyQt delegate classes.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   14.2.2017
"""

import os
import logging
from PyQt5.QtCore import Qt, QRect, QSize
from PyQt5.Qt import QStyleOptionViewItem, QIcon, QStyle, QTextDocument, QPixmap
from PyQt5.QtWidgets import QItemDelegate, QStyledItemDelegate
from config import UI_RESOURCES


class SimpleSetupStyledItemDelegate(QStyledItemDelegate):
    """This delegate simply makes the decoration appear on the right side of DisplayRole."""

    def paint(self, painter, options, index):
        """Overwritten paint method.

        Args:
            painter (QPainter): painter
            options (QStyleOptionViewItem): options
            index (QModelIndex): index
        """
        options.decorationPosition = QStyleOptionViewItem.Right
        # options.decorationAlignment = Qt.AlignRight
        super().paint(painter, options, index)


class SetupStyledItemDelegate(QStyledItemDelegate):

    def __init__(self, parent=None):
        super().__init__(parent)
        self.icon_widths = 0
        self.decoration_width = 25

    def paint(self, painter, options, index):
        """Reimplemented paint method.

        Args:
            painter (QPainter): painter
            options (QStyleOptionViewItem): options
            index (QModelIndex): index
        """
        style = self.parent().style()
        icon_list = self.get_flag_icon(index.internalPointer())
        main_rect = options.rect  # The allotted rectangle to fill (size given by sizeHint)
        box_width = 20
        box_height = 18  # row height: 22, so this leaves a little breathing room
        # Note about flag icon size: Original flag icon .png images are 75x70 pixels. Requested size of the icon
        # is box_width x box_height.
        first_box = QRect()  # Rectangle for first box icon (Extra 10 pixels space for 1st and 2nd box padding)
        first_box.setX(main_rect.x() + main_rect.width() - 2*box_width-10)
        first_box.setY(main_rect.y())
        # Added 5 pixels empty space after first icon
        first_box.setWidth(box_width+5)
        first_box.setHeight(main_rect.height())
        sec_box = QRect()  # Rectangle for the second box icon (Extra 5 pixels space for end padding)
        sec_box.setX(main_rect.x() + main_rect.width() - box_width-5)
        sec_box.setY(main_rect.y())
        # Added 5 pixels empty space after second icon
        sec_box.setWidth(box_width+5)
        sec_box.setHeight(main_rect.height())
        # Update item width for sizeHint
        self.icon_widths = first_box.width() + sec_box.width()
        item_state = QIcon.On
        # Switch icon mode if item is selected and has focus
        if options.state & QStyle.State_Selected and options.state & QStyle.State_HasFocus:
            item_mode = QIcon.Selected
            # Paint DisplayRole. Enables mouse hover and select background effects.
            # If item is selected, DisplayRole is painted before the icons. This
            # prevents the icons of appearing too dark.
            super().paint(painter, options, index)
            # Add icons to column (Spinning wheel decoration is shown by the model)
            style.drawItemPixmap(painter, first_box, Qt.AlignLeft | Qt.AlignVCenter,
                                 icon_list[0].pixmap(QSize(first_box.width(), box_height), item_mode, item_state))
            style.drawItemPixmap(painter, sec_box, Qt.AlignLeft | Qt.AlignVCenter,
                                 icon_list[1].pixmap(QSize(sec_box.width(), box_height), item_mode, item_state))
        elif options.state & QStyle.State_Selected:
            # When item is selected but does not have focus
            item_mode = QIcon.Normal
            super().paint(painter, options, index)
            # Add icons to column (Spinning wheel decoration is shown by the model)
            style.drawItemPixmap(painter, first_box, Qt.AlignLeft | Qt.AlignVCenter,
                                 icon_list[0].pixmap(QSize(first_box.width(), box_height), item_mode, item_state))
            style.drawItemPixmap(painter, sec_box, Qt.AlignLeft | Qt.AlignVCenter,
                                 icon_list[1].pixmap(QSize(sec_box.width(), box_height), item_mode, item_state))
        else:
            item_mode = QIcon.Normal
            # Add icons to column (Spinning wheel decoration is shown by the model)
            style.drawItemPixmap(painter, first_box, Qt.AlignLeft | Qt.AlignVCenter,
                                 icon_list[0].pixmap(QSize(first_box.width(), box_height), item_mode, item_state))
            style.drawItemPixmap(painter, sec_box, Qt.AlignLeft | Qt.AlignVCenter,
                                 icon_list[1].pixmap(QSize(sec_box.width(), box_height), item_mode, item_state))
            # If item is not selected, DisplayRole is painted after the icons.
            # This makes the mouse hover effect show over icons.
            # if not item_mode == QIcon.Selected and not item_mode == QIcon.Disabled:
            super().paint(painter, options, index)

        # This makes basically the same thing without super
        # style.drawControl(QStyle.CE_ItemViewItem, options, painter, options.widget)
        # style.drawItemText(painter, text_rect, Qt.AlignLeft | Qt.AlignVCenter,
        #                    QApplication.palette(), True, index.internalPointer().name)
        # style.drawItemPixmap(painter, first_box, Qt.AlignLeft | Qt.AlignVCenter,
        #                      icon_list[0].pixmap(QSize(first_box.width(), box_height)))
        # style.drawItemPixmap(painter, sec_box, Qt.AlignLeft | Qt.AlignVCenter,
        #                      icon_list[1].pixmap(QSize(sec_box.width(), box_height)))

    def sizeHint(self, options, index):
        """Reimplemented sizeHint method. Needed in order to
        make view header handle double-clicking work.

        Args:
            options (QStyleOptionViewItem): Style options
            index (QModelIndex): Index
        """
        if index.column() == 0:  # Not actually needed because the delegate is set only for the first column
            text = index.model().data(index, Qt.DisplayRole)
            document = QTextDocument(text)
            document.setDefaultFont(options.font)
            text_width = document.idealWidth()
            w = text_width + self.icon_widths
            if index.internalPointer().running:
                w += self.decoration_width
            return QSize(w, 22)
        else:
            super().sizeHint(options, index)

    # noinspection PyMethodMayBeStatic
    def get_flag_icon(self, setup):
        """Returns Setup icons according to set flags.
        Note: Icons are loaded from a resource file embedded into the application.

        Args:
            setup (Setup): Setup for which the icons are being painted
        """
        icon1 = QIcon()
        icon2 = QIcon()
        if setup.is_ready and setup.failed:
            icon1.addPixmap(QPixmap(":/flags/check_mark.png"))
            icon2.addPixmap(QPixmap(":/flags/fail_box.png"))
        elif not setup.is_ready and setup.failed:
            icon1.addPixmap(QPixmap(":/flags/empty_box.png"))
            icon2.addPixmap(QPixmap(":/flags/fail_box.png"))
        elif setup.is_ready and not setup.failed:
            icon1.addPixmap(QPixmap(":/flags/check_mark.png"))
            icon2.addPixmap(QPixmap(":/flags/empty_box.png"))
        else:
            icon1.addPixmap(QPixmap(":/flags/empty_box.png"))
            icon2.addPixmap(QPixmap(":/flags/empty_box.png"))
        return [icon1, icon2]


class SetupItemDelegate(QItemDelegate):

    def paint(self, painter, options, index):
        """Overwritten paint method.

        Args:
            painter (QPainter): painter
            options (QStyleOptionViewItem): options
            index (QModelIndex): index
        """
        # super().paint(painter, options, index)
        setup_model = index.model()
        text = setup_model.data(index, Qt.DisplayRole)
        run_icon = setup_model.data(index, Qt.DecorationRole)
        flags_icon = self.get_flag_icon(index.internalPointer())

        main_rect = options.rect  # The allotted rectangle to fill
        run_rect_width = 25
        flags_rect_width = 40
        row_height = 18  # options.rect.height() : 20
        # Note about flag icon size: Original flag icon .png images are 180x81 pixels. It looks like Qt
        # scales the size down by a factor of 4.5 so the actual size of the icon is 40x18 pixels.

        rect1 = QRect()  # Rectangle for running icon
        rect1.setX(main_rect.x())
        rect1.setY(main_rect.y())
        rect1.setWidth(run_rect_width)
        rect1.setHeight(main_rect.height())

        rect_running = QRect()  # Rectangle to display Setup name when Setup is running
        rect_running.setX(main_rect.x() + run_rect_width)
        rect_running.setY(main_rect.y())
        rect_running.setWidth(main_rect.width() - run_rect_width - flags_rect_width)
        rect_running.setHeight(main_rect.height())

        rect_not_running = QRect()  # Rectangle to display Setup name when Setup is not running
        rect_not_running.setX(main_rect.x())
        rect_not_running.setY(main_rect.y())
        rect_not_running.setWidth(main_rect.width() - flags_rect_width)
        rect_not_running.setHeight(main_rect.height())

        rect3 = QRect()  # Rectangle for flags icon
        rect3.setX(main_rect.x() + main_rect.width() - flags_rect_width)
        rect3.setY(main_rect.y())
        rect3.setWidth(flags_rect_width)
        rect3.setHeight(main_rect.height())

        QItemDelegate.drawBackground(self, painter, options, index)
        if run_icon:
            QItemDelegate.drawDecoration(self, painter, options, rect1,
                                         run_icon.pixmap(QSize(run_rect_width, row_height)))
            QItemDelegate.drawDisplay(self, painter, options, rect_running, text)
            QItemDelegate.drawDecoration(self, painter, options, rect3,
                                         flags_icon.pixmap(QSize(flags_rect_width, row_height)))
        else:
            QItemDelegate.drawDisplay(self, painter, options, rect_not_running, text)
            QItemDelegate.drawDecoration(self, painter, options, rect3,
                                         flags_icon.pixmap(QSize(flags_rect_width, row_height)))

        if options.state & QStyle.State_MouseOver:
            logging.debug("{} selected".format(index.internalPointer().name))
            QItemDelegate.drawFocus(self, painter, options, options.rect)
        # options.decorationPosition = QStyleOptionViewItem.Right
        # super().paint(painter, options, index)

    # noinspection PyMethodMayBeStatic
    def get_flag_icon(self, setup):
        if setup.is_ready and setup.failed:
            return QIcon(os.path.join(UI_RESOURCES, 'check_mark_fail.png'))
        elif not setup.is_ready and setup.failed:
            return QIcon(os.path.join(UI_RESOURCES, 'no_check_mark_fail.png'))
        elif setup.is_ready and not setup.failed:
            return QIcon(os.path.join(UI_RESOURCES, 'check_mark_no_fail.png'))
        else:
            return QIcon(os.path.join(UI_RESOURCES, 'two_empty_boxes.png'))
