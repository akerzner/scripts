#!/bin/bash

 echo "Alex's experimental install script"

 echo "Don't use this."
 exit 1
 
 
 pre="[MPI_INSTALL]"

 echo -n "$pre Which machine is this? [0=boss, 1=worker1, 2=worker2, 3=worker3] "
 hostopt0="mario"
 ipopt0="192.168.1.29"
 hostopt1="luigi"
 ipopt1="192.168.1.30"
 hostopt2="toad"
 ipopt2="192.168.1.31"
 hostopt3="peach"
 ipopt3="192.168.1.32"

 read machine_id
 case $machine_id in
   0)
     newhost="$hostopt0"
     newipaddr="$ipopt0"
     ;;
   1)
     newhost="$hostopt1"
     newipaddr="$ipopt1"
     ;;
   2)
     newhost="$hostopt2"
     newipaddr="$ipopt2"
     ;;
   3)
     newhost="$hostopt3"
     newipaddr="$ipopt3"
     ;;
   *)
     echo "$pre Invalid option '$machine_id', exiting."
     exit 1
     ;;
 esac


 echo "$pre Configuration: host=$newhost, ipaddr=$newipaddr"




 echo "$pre Installing python-mpi4py"
 sudo apt-get install python-mpi4py -y

 echo "$pre Installing python-numpy"
 sudo apt-get install python-numpy -y
 echo "$pre Installing python-pandas"
 sudo apt-get install python-pandas -y

 echo "$pre Changing host to '$newhost'"

 echo "$pre modifying /etc/hosts"
 sed -i "s/\(127.0.1.1\s*\)raspberrypi/\1$newhost/" /etc/hosts

 if [ $machine_id -eq 0 ]
 then
   echo "$pre Adding additional machines for boss..."
   sudo echo "\n$ipopt1 $hostopt1" >> /etc/hosts
   sudo echo "$ipopt2 $hostopt2" >> /etc/hosts
   sudo echo "$ipopt3 $hostopt3" >> /etc/hosts
 fi

 echo "$pre modifying /etc/hostname"
 echo "$newhost" | sudo tee /etc/hostname

 echo "$pre setting hostname with hostname command"
 sudo hostname "$newhost"

 echo "$pre Backing up /etc/network/interfaces to /etc/network/interfaces.bak"
 sudo cp /etc/network/interfaces /etc/network/interfaces.bak



 echo "$pre Modifying /etc/network/interfaces"
 sudo sed -i "s/\(iface eth0 inet\) manual/auto eth0\n\1 static\naddress $newipaddr \nnetmask 255.255.255.0\nnetwork 192.168.1.0\nbroadcast 192.168.1.255\ngateway 192.168.1.254/" /etc/network/interfaces

 echo "$pre Checking if ~/.ssh exists"
 if [ ! -d "/home/pi/.ssh" ]
 then
   echo "$pre Directory does not exist. Creating..."
   sudo install -d -m 700 /home/pi/.ssh
   sudo chown pi:pi /home/pi/.ssh
 fi

 echo "$pre Verifying that ~/.ssh/authorized_keys exists"
 touch /home/pi/.ssh/authorized_keys

 if [ $machine_id -eq 0 ]
 then
   echo "$pre Generating keys for boss..."
   cd /home/pi/.ssh
   ssh-keygen -t rsa -C "$hostopt0" -f "/home/pi/.ssh/id-rsa" -N ''
 
   echo "$pre Copying key to workers..."
   cd /home/pi
   echo "$pre USER INPUT REQUIRED"
   cat /home/pi/.ssh/id_rsa_pub | ssh pi@"$ipopt1" 'cat >> /home/pi/.ssh/authorized_keys'
   cat /home/pi/.ssh/id_rsa_pub | ssh pi@"$ipopt2" 'cat >> /home/pi/.ssh/authorized_keys'
   cat /home/pi/.ssh/id_rsa_pub | ssh pi@"$ipopt3" 'cat >> /home/pi/.ssh/authorized_keys'


   echo "$pre Creating ~/mpi4py directory..."
   mkdir /home/pi/mpi4py

   echo "$pre Creating machinefile at ~/mpi4py/workers..."
   echo "$ipopt0\n$ipopt1\n$ipopt2\n$ipopt3" > /home/pi/mpi4py/workers

   echo "$pre Creating beginner's script..."
   echo 'from mpi4py import MPI\nimport sys\nsize = MPI.COMM_WORLD.Get_size()\nrank = MPI.COMM_WORLD.Get_rank()\nname = MPI.Get_processor_name()\nsys.stdout.write("Hello world! I am process %d of %d on %s.\n" % (rank,size,name))' >> helloworld.py
   sudo chmod a+rwx helloworld.py
   sudo chown pi:pi helloworld.py

   echo "$pre ...done creating python script."


   echo "$pre Preparing $hostopt1..."
   ssh pi@"$ipopt1" "cd ~; mkdir mpi4py"
   scp /home/pi/mpi4py/helloworld.py pi@"$ipopt1":/home/pi/mpi4py

   echo "$pre Preparing $hostopt2..."
   ssh pi@"$ipopt2" "cd ~; mkdir mpi4py"
   scp /home/pi/mpi4py/helloworld.py pi@"$ipopt2":/home/pi/mpi4py

   echo "$pre Preparing $hostopt3..."
   ssh pi@"$ipopt3" "cd ~; mkdir mpi4py"
   scp /home/pi/mpi4py/helloworld.py pi@"$ipopt3":/home/pi/mpi4py

   echo "$pre Okay, it should be done!"
 fi

 echo "$pre Rebooting now..."
 sudo reboot now

~

