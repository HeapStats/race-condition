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


public class Test{

  public static void runGC(){
    try{
      Thread.sleep(10000);
    }
    catch(Exception e){
      e.printStackTrace();
    }

    System.gc();
  }

  public static void main(String[] args) throws Exception{
    (new Thread(Test::runGC)).start();

    // OOM for sending SNMP trap
    byte[] oom = new byte[1024 * 1024 * 1024];
  }
}
