'''
Copyright (C) 2018 Nippon Telegraph and Telephone Corporation

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
'''

import sys, os
sys.path.append(os.pardir + "/../")

import common


class SleepHandler(gdb.Breakpoint):
    def __init__(self):
        super(SleepHandler, self).__init__("JVM_Sleep")

    def stop(self):
        self.enabled = False
        os.kill(gdb.selected_inferior().pid, 12)  # Send USR2 for collecting log
        return False


common.initialize("TTrapSender::sendTrap", common.return_true, "OnClassUnload", common.return_true, True)
SleepHandler()

