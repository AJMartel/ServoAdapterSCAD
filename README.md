# ServoAdapterSCAD

This script will create R/C servo adapters and servo dummies.

** This script is work in progress. It has not been tested yet IRL, and the servo database is minimal, but will grow. **
 
Let's say you are printing a 3D model that was build with a very specific servo in mind, but that servo is no longer available. You can use this script to generate a 3D model that will make a smaller servo fit into the position of the original servo.
 
Also, if you decide to scale a 3D model (let's say you want to print the InMoov robot (www.inmoov.fr), but it's too tall and you scale it to 80%), the servo adapter script will generate adapters that make smaller servos fit your scaled model perfectly.

This works for scaling models up as well. Let's say you printed that awesome robot arm at 150%. This script will create adapters that match the original servo into a servo mount that is 1 1/2 times larger.

If you set "Small Servo" to "None", the script will generate a dummy servo case that will fit into the original servo mount.

The newest version of this script is available on GitHub: https://github.com/MatthiasWM/ServoAdapterSCAD , merge request welcome.

Still to come:
* generic servo sizes
* more entries in the database
* customize: fatten mounting tabs
* customize: choose mounting bolts in more detail, maybe captive nut)
* customize: compensate printing size
