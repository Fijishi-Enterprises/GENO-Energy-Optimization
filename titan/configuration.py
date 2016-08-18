"""
Module for handling Sceleton Titan configuration files.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   22.6.2016
"""

import configparser
import logging
import codecs
from config import SETTINGS


class ConfigurationParser(object):
    """ConfigurationParser class takes care of handling configurations files
    in persistent storage.
    """
    def __init__(self, file_path, defaults=None):
        """Initialize configuration parser.

        Args:
            file_path: Absolute path to the configuration file.
            defaults: A dictionary containing configuration default options.
        """
        self.parser = configparser.ConfigParser()
        self.file_path = file_path
        if defaults:
            self.parser['general'] = defaults
            self.parser['settings'] = SETTINGS

    def __str__(self):
        """Print the current configuration."""
        output = ''
        for section_name in self.parser.sections():
            output += ('[%s]\n' % section_name)
            for name, value in self.parser.items(section_name):
                output += ('    %s = %s\n' % (name, value))
        return output.strip()

    def get(self, section, option):
        """Get configuration option value.

        Args:
            section: Selected configuration section.
            option: Configuration option to get.

        Returns:
            Value of the option as a string or default if the option was
            not found.
        """
        if not self.parser.has_section(section):
            self.parser[section] = {}
        return self.parser.get(section, option)

    def set(self, section, option, value):
        """Set configuration option value.

        Args:
            section: The configuration section to edit.
            option: The configuration option to set.
            value: The option values to be set.
        """
        if not self.parser.has_section(section):
            self.parser[section] = {}
        self.parser.set(section, option, value)

    def load(self, insert_missing=True):
        """ Load a configuration file. By default if 'default'
        section is missing, it is inserted into the configuration.

        Args:
            insert_missing: Add missing sections.

        Returns:
            A boolean value depending on the operation success.
        """
        try:
            self.parser.read(self.file_path, 'utf-8')
        except configparser.MissingSectionHeaderError:
            self.parser.add_section('default')
        except configparser.ParsingError:
            logging.exception('Failed to parse configuration file.')
            return False
        return True

    def save(self):
        """Save configuration into persistent storage, overwriting old file."""
        with codecs.open(self.file_path, 'w', 'utf-8') as output_file:
            self.parser.write(output_file)

    def copy_section(self, source, destination):
        """Copy all option parameters from source section to destination section.

        Args:
            source: Configuration section to copy options from.
            destination: Configuration section to which copy options.
        """
        for option in self.parser.options(source):
            logging.debug('Copy option: %s' % self.get(source, option))
            self.set(destination, option, self.get(source, option))
