"""
Custom PyQt delegate classes.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   14.2.2017
"""

from PyQt5.QtCore import Qt, QRect, QSize
from PyQt5.Qt import QStyleOptionViewItem, QIcon, QStyle, QPixmap, QFontMetrics, QApplication
from PyQt5.QtWidgets import QStyledItemDelegate


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
    """Class to overwrite painting of Setup name column."""
    def __init__(self, parent=None):
        """Delegate constructor."""
        super().__init__(parent)
        self.decoration_width = 25  # Animated icon width
        self.box_width = 20  # Flag icon width
        self.box_height = 18  # Flag icon height
        # Note about flag icon size: Original flag icon .png images are 75x70 pixels.
        # Requested size of the icon is self.box_width x self.box_height.
        self.box_w_padding = 5  # Flag icon width padding
        self.box_h_padding = 4  # Row height padding to leave a little breathing room
        self.padding = 3  # Padding for decoration and text
        self.box_widths = 2*self.box_width + 2*self.box_w_padding  # Flag icons + padding

    # noinspection PyArgumentList, PyUnresolvedReferences
    def paint(self, painter, options, index):
        """Reimplemented paint method. Reimplement also displayText if
        super().paint() is called.

        Paints item with the following contents:
        padding + decoration + padding + text + box + box_padding + box + box_padding

        Args:
            painter (QPainter): painter
            options (QStyleOptionViewItem): options
            index (QModelIndex): index
        """
        style = self.parent().style()
        palette = QApplication.palette()
        font = QApplication.font()
        deco = index.model().data(index, Qt.DecorationRole)
        text = index.internalPointer().name
        icon_list = self.get_flag_icon(index.internalPointer())
        main_rect = options.rect  # The allotted rectangle to fill (size given by sizeHint)
        deco_width = 0
        if deco:
            deco_width = self.decoration_width
        # Rectangle for decoration (spinning wheel animation)
        deco_box = QRect()
        deco_box.setX(main_rect.x() + self.padding)
        deco_box.setY(main_rect.y())
        deco_box.setWidth(deco_width)
        deco_box.setHeight(main_rect.height())
        # Rectangle where text is drawn
        text_box = QRect()
        text_box.setX(main_rect.x() + deco_box.width() + self.padding)
        text_box.setY(main_rect.y())
        text_box.setWidth(main_rect.width() - self.box_widths - deco_box.width() - self.padding)
        text_box.setHeight(main_rect.height())
        # Rectangle where ready flag is drawn
        first_box = QRect()  # Rectangle for first box icon (Extra 10 pixels space for 1st and 2nd box padding)
        first_box.setX(main_rect.x() + main_rect.width() - 2*self.box_width - 2*self.box_w_padding)
        first_box.setY(main_rect.y())
        first_box.setWidth(self.box_width+self.box_w_padding)
        first_box.setHeight(main_rect.height())
        # Rectangle where failed flag is drawn
        sec_box = QRect()  # Rectangle for the second box icon (Extra 5 pixels space for end padding)
        sec_box.setX(main_rect.x() + main_rect.width() - self.box_width-self.box_w_padding)
        sec_box.setY(main_rect.y())
        sec_box.setWidth(self.box_width+self.box_w_padding)
        sec_box.setHeight(main_rect.height())
        # Compact text when allotted space is too short for the whole text
        metrics = QFontMetrics(font)
        elided_text = metrics.elidedText(text, Qt.ElideRight, text_box.width())
        # Set mode and state for flag icons
        item_state = QIcon.On
        item_mode = QIcon.Normal
        if options.state & QStyle.State_Selected and options.state & QStyle.State_HasFocus:
            item_mode = QIcon.Selected
        # Draw item contents
        style.drawControl(QStyle.CE_ItemViewItem, options, painter, options.widget)
        # Draw decoration when Setup is running and if item has enough space
        if deco and main_rect.width() > self.box_widths + self.decoration_width:
            style.drawItemPixmap(painter, deco_box, Qt.AlignLeft | Qt.AlignVCenter,
                                 deco.pixmap(QSize(deco_box.width(), self.box_height), item_mode, item_state))
        style.drawItemText(painter, text_box, Qt.AlignLeft | Qt.AlignVCenter,
                           palette, True, elided_text)
        style.drawItemPixmap(painter, first_box, Qt.AlignLeft | Qt.AlignVCenter,
                             icon_list[0].pixmap(QSize(first_box.width(), self.box_height), item_mode, item_state))
        style.drawItemPixmap(painter, sec_box, Qt.AlignLeft | Qt.AlignVCenter,
                             icon_list[1].pixmap(QSize(sec_box.width(), self.box_height), item_mode, item_state))

    def sizeHint(self, options, index):
        """Reimplemented sizeHint method. Needed in order to
        make view column resizing work.

        Args:
            options (QStyleOptionViewItem): Style options
            index (QModelIndex): Index
        """
        if index.column() == 0:  # Not actually needed because the delegate is set only for the first column
            super_size = super().sizeHint(options, index)
            w = super_size.width() + self.box_widths + 2*self.padding
            h = self.box_height + self.box_h_padding
            return QSize(w, h)
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
