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

import java.util.concurrent.locks.*;


public class Test{

  public static void runMemleak(){
    byte[] buf = new byte[1024 * 1024 * 1024]; // 1GB
  }

  public static void main(String[] args) throws Exception{
    (new Thread(Test::runMemleak)).start();
    Thread parker = new Thread(() -> LockSupport.park());
    parker.start();

    Thread.sleep(1000);

    LockSupport.unpark(parker);
  }

}
