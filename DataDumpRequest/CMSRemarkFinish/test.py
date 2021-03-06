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


class BreakAtDataDump(gdb.Breakpoint):
    def __init__(self):
        super(BreakAtDataDump, self).__init__("data_dump")

    def stop(self):
        gdb.execute("set var ReduceSignalUsage=true")
        gdb.write("set true to ReduceSignalUsage\n")


class BreakAtShouldPostDataDump(gdb.Breakpoint):
    def __init__(self):
        super(BreakAtShouldPostDataDump, self).__init__("JvmtiExport::should_post_data_dump")

    def stop(self):
        gdb.execute("set var ReduceSignalUsage=false")
        gdb.write("set false to ReduceSignalUsage\n")


def Cond_GarbageCollectionFinish():
    frame = gdb.newest_frame()
    while frame is not None:
        if(frame.name().find("VM_CMS_Final_Remark::doit") != -1):
            return True
        frame = frame.older();
    return False


common.initialize("OnDataDumpRequestForSnapShot", common.return_true, "JvmtiExport::post_garbage_collection_finish", Cond_GarbageCollectionFinish, True)
BreakAtDataDump()
BreakAtShouldPostDataDump()
