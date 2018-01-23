/*
 * Copyright (C) 2018 Nippon Telegraph and Telephone Corporation
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import java.nio.file.*;
import com.sun.tools.attach.*;
import sun.tools.attach.*;


public class Test implements Runnable{

  public void run(){
    try{
      /* Wait 10 sec until GDB reaches breakpoint of DumpRequest */
      Thread.sleep(10000);
    }
    catch(Exception e){
      e.printStackTrace();
    }

    System.gc();
  }

  public static void main(String[] args) throws Exception{
    (new Thread(new Test())).start();

    Path selfProc = Paths.get("/proc/self");
    String pid = Files.readSymbolicLink(selfProc).toString();
    HotSpotVirtualMachine selfVM =
                              (HotSpotVirtualMachine)VirtualMachine.attach(pid);
    try{
      selfVM.localDataDump();
    }
    finally{
      selfVM.detach();
    }

  }
}
