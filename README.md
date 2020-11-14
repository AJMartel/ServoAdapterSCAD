# Customizable Servo Adapter

This script will create R/C servo adapters and servo dummies.

### This script is work in progress. It has not been tested yet IRL, and the servo database is minimal, but will grow
 
Let's say you are printing a 3D model that was build with a very specific servo in mind, but that servo is no longer available. You can use this script to generate a 3D model that will make a smaller servo fit into the position of the original servo.
 
Also, if you decide to scale a 3D model (let's say you want to print the InMoov robot (www.inmoov.fr), but it's too tall and you scale it to 80%), the servo adapter script will generate adapters that make smaller servos fit your scaled model perfectly.

This works for scaling models up as well. Let's say you printed that awesome robot arm at 150%. This script will create adapters that match the original servo into a servo mount that is 1 1/2 times larger.

If you set "Small Servo" to "None", the script will generate a dummy servo case that will fit into the original servo mount.

The newest version of this script is available on GitHub: https://github.com/MatthiasWM/ServoAdapterSCAD , merge request welcome.

# Parameters

You can modify the following parameters to get the exact servo adapter for your needs.

## General Settings

### Large Servo

Select the model of the originally intended servo for your thing. If your servo is not in the 
database, try the generic servo for your servo size class. If that doesn't work, download the 
script form GitHub ( https://github.com/MatthiasWM/ServoAdapterSCAD ) and add your servo type 
to the database.

### Small Servo

Select the servo model that you want to use instead of Large Servo. To make the adapter work
well, this is usually a much smaller servo than the original model. This script will make sure
that the servo disk of the replacement servo is at the same position as the original. If no
small servo is selected, the script will generate a non-working servo of the original version.

### Mount Small Servo

* from the top: the small servo will be mounted in the adapter from the top. Cables should have
  enough space to exit at the original position. This is the most common choice.
* from the bottom: the servo will be mounted from the bottom of the adapter. This is rather 
  uncommon, but works well if the new servo is much smaller than the original.
* clam shell: the new servo is mounted inbetween two halves of the adapter. This may work 
  well if the top-mount adapter is not togh enough for the job. Use Draw Sides to build and 
  print both halves.

### Draw Adapter

It's usually no neccessary to print the entire case of the original servo.

* full servo: create the entire original servo
* top half: create the adapter starting from the large mounting bracket and up
* small servo height: make the adapter enclose no more than the small servo  
* minimal: just generate the part between original and new mounting bracket
* minimal plus: like minimal, but add 10mm at the bottom

### Draw Sides

Useful for inspections or in clam shell mode. This outputs only the left or right side of the adapter.

### Draw Servo Wheel

Useful for dummy servos. This builds a servo wheel for the original servo. A clipped wheel will 
be functional, but easier to print.

## Large Servo Settings

### Large Servo Scale

This parameter will scale the original servo, but leave the new servo as is. It's great to fit smaller
servos into models that have been scaled down, or even the original servo into models that have been
scaled up.

### Large Servo Adjust

This parameter expands or contracts the servo case and mount without changing the location of 
mounting points or the servo wheel. This is useful to compensate for inaccuracies in the 
3d-print, or just to make the adapter fit tightly into the model.

### Large Servo Cable Channel

Setting this to 'yes' adds a small channel to the right side of the servo for routing the servo 
control cable. But it also makes the adapter weaker, so this should be 'no' unless needed.

## Small Servo Settings

### Small Servo Adjust

This parameter expands or contracts the servo cutout without changing the location of 
mounting points or the servo wheel. This is useful to compensate for inaccuracies in the 
3d-print, or just to make the smalle servo fit tightly into the adapter.

### Small Servo Cable Channel

Add channels to the small servo cutout that will make it easier to route the servo control
cable away from the adapter into the original cable position.

### Fastener Diameter

This a the diameter of the screw or bolt hole for the small servo in the adapter. If this
is set to 0, no holes are created.

### Fastener Length

The length of the screw or bolt hole in milimeters.


## Still to come

* generic servo sizes
* more entries in the database
* customize: fatten mounting tabs
* customize: choose mounting bolts in more detail, maybe captive nut)
