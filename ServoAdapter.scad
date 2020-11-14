/*

This script will create servo adapters and servo dummies.

** This script is work in progress. It has not been tested yet IRL, and the servo database is minimal, but will grow. **
 
Let's say you are printing a 3D model that was build with a very specific servo in mind, but that servo is no longer available. You can use this script to generate a 3D model that will make a smaller servo fit into the position of the original servo.
 
Also, if you decide to scale a 3D model (let's say you want to print the InMoov robot (www.inmoov.fr), but it's too tall and you scale it to 80%), the servo adapter script will generate adapters that make smaller servos fit your scaled model perfectly.
 
If you set "Small Servo" to "None", the script will generate a dummy servo case that will fit into the original servo mount.

The newest version of this script is available on GitHub: https://github.com/MatthiasWM/ServoAdapterSCAD , merge request welcome.

Still to come:
* generic servo sizes
* more entries in the database
* customize: fatten mounting tabs
* customize: choose mounting bolts in more detail, maybe captive nut)
* customize: compensate printing size

 random links:
	https://servodatabase.com/
	https://www.pololu.com/blog/12/introduction-to-servos 
	https://a.pololu-files.com/picture/0J1829.677.png 
	http://www.theampeer.org/midwest/photos/servo-sizes.jpg 
	https://www.wiltronics.com.au/product/10364/rc-servo-metal-gears-8-8kg-cm-towerpro-mg995/ 
	https://www.t2shop.de/SRT-BH9027-Fullsize-Digital-Servo-Brushless-HV-HIGH-TORQUE-0075sek-/-20kg
	https://www.hoelleinshop.com/Sender-Servos-etc-/Servos/Servo-Savox-SC-1258TG-Digital-12-0kg-cm-Heli-Version.htm?shop=hoellein
  https://www.sparkfun.com/servos

*/
 
// ---- customizable settings ---------------------------------------------

// create a servo adapter of this type
Large_Servo = 1; // [0:None, 1:HS5805MG, 2:DS3218]

// create space for this servo ("None" for dummy)
Small_Servo = 2; // [0:None, 1:HS5805MG, 2:DS3218]

Mount_Small_Servo = 0; // [0:from the top, 1:from the bottom, 2:clam shell]

// draw only the part that is needed to function as an adapter
Draw_Mount = 0; // [0:full servo, 1: top half, 2: small servo height, 3:minimal, 4:minimal plus]

// useful in clam shell mode
Draw_Sides = 0; // [0:both sides, 1:left side, 2:right side]

// 'auto' draws only if no small servo is chosen
Draw_Servo_Wheel = 0; // [0:auto, 1:no, 2:yes, 3:clipped]

/* [Large Servo Settings] */

// Fit adapter into scaled models (%)
Large_Servo_Scale = 100.0;

// create a channel to route the cable away from the adapter
Large_Servo_Cable_Channel = 0; // [0:no, 1:yes]

/* [Small Servo Settings] */

// create a channel to route the cable through the adapter
Small_Servo_Cable_Channel = 1; // [0:no, 1:yes]

// diameter of screw or bolt holding the small servo (mm, 0 for none)
Fastener_Diameter = 2.5;

// length of screw or bolt (mm)
Fastener_Length = 35.0;

// ---- end of customizable settings --------------------------------------

/* [Hidden] */

/* Servo Database:
	The database is an array of datasets of a servo name 
	and a servo case reference.
	*/

/* Servos Datasets:
	Servos are stored as a dataset linking to a case design,
	a mount design, and a wheel design.
	For values or references that are undefined, a reasonable
	value is calculated.
	
	Length is along the x axis, width is along y, height is along z
	*/

/* Servo Case:
	Servo cases are stored using an integer identifying the
	type of case (1=body, mount, wheel), followed by values 
	describing the case, for example 
	[1, body_data, body_offset, mount_data, mount_offset, wheel_data]

/* Servo Body:
	Servo bodies are stored using an integer identifying the
	type of body (1=rectangular), followed by values describing
	the body, for example [1, [length, width, height], [axle_offset_x, y, z]]
	*/
	
/* Servo Mount:
	Servo mounts are stored using an integer identifier
	(1=rectangular, four holes, 2=two holes), followed by values
	describing the mount, for example
	[1, [length, width, height], hole_dist_x, hole_dist_y, hole_dia]
	[2, [length, width, height], hole_dist_x, hole_dia]
	*/
	
/* Servo Wheel:
	Servo wheels are stored using an integer identifier
	(1=round wheel), followed by values describing the wheel, 
	for example [1, diameter, height]
	*/

// ---- servo class list --------------------------------------------------
kClassStandard = 5;
kClassLarge = 5;

// ---- wheel database ----------------------------------------------------
// wheel type 0, no wheel: [0]
wheel_none = [ 0 ];
//	wheel type 1, disk: [1, diameter, height]
//		diameter of disk in mm
//		height of disk in mm
wheel_standard = [ 1, 24.0, 3.0 ];
wheel_large = [ 1, 36.0, 4.0 ];

// default sizes of wheels for every servo class
wheel_db = [ undef, undef, undef, undef, wheel_standard, wheel_large ];

// ---- mount database ----------------------------------------------------
//	mount type 1, two tabs, 4 holes: [1, [length, width, height], hole_dist_x, hole_dist_y, hole_dia]
//		length, width, and heigt of mounting surface in mm
//		hole_dist_x, hole_dist_y: distance of hole to each other in mm
//		hole_dia: diameter of mounting hole in mm
mount_480_100 = [ 1, [56.4, 20.0, 3.0], 48.0, 10.0, 4.0 ];
mount_750_180 = [ 1, [83.0, 30.0, 3.0], 75.0, 18.0, 6.0 ];

// ---- body database -----------------------------------------------------
//	body type 1, chamfered box: [1, [length, width, height]]
//		length, width, and heigt of body without mounts or wheel in mm
body_405_200_410 = [ 1, [ 40.5, 20.0, 41.0]  ];
body_660_300_676 = [ 1, [ 66.0, 30.0, 57.6]  ];

// ---- servo database ----------------------------------------------------
//	servo type 1, body, mount wheel: [1, class, body, [body_offset_vec], mount, mount_offset, wheel]
//		class: one of the kClass* constants that best matches the body
//		body: reference to an entry in the body database
//		body_offset: vector with 3 elements, x is the offset from the left side of the body to the center of the wheel (usually half the case width)
//		             y is the offset of the center of the body to the center of the wheel, usually 0
//		             z is the offset from the top of the wheel to the bottom of the body
//		mount: reference to an entry in the mount database
//		mount_offset: the distance from the top of the wheel to the bottom of the mounting tabs
//		wheel: reference to an entry in the wheel database
servo_hitec_hs5805mg = [ 1, kClassStandard, body_660_300_676, [14.8, 0.0, 70.0], mount_750_180, 27.6, wheel_large ];
servo_ds_ds3218 = [ 1, kClassLarge, body_405_200_410, [10.0, 0.0, 45.0], mount_480_100, 17.0, wheel_standard ];

// ---- servo lookup table ------------------------------------------------
servo_db = [
  [ "none" ],
	[ "Hitec HS-5805MG", servo_hitec_hs5805mg ],
	[ "DigitalServo DS3218", servo_ds_ds3218 ],
];

/*
https://servodatabase.com/servos/all

  Nano        w< 7.5, L<18.5
	Sub-Micro   w<11.5, L<24
	Micro       w<13,   L<29
	Mini        w<17,   L<32.5
	Standard    W<20,   L<38
	Large       W>20    L>38
*/

// --- draw routines have an optional style parameter
kStyleDraw 	= 0;	// draw an object, so it fits into existing spaces (when in doubt, draw less)
kStyleCut 	= 1;	// draw a space, so an object fits into it (when in doubt, draw more)
kStyleMount = 2;	// draw parts that may be needed to mount the smaller servo, but may not be part of the bigger servo

d1 = 0.0001; // small distance to make booleans work better
d2 = 2*d1;

module cbox(size, chamfer)
{
	c = chamfer;
	dx = size[0]/2;
	dy = size[1]/2;
	dz = size[2]/2;
	
	polyhedron(
		points = [
			[-dx+c, -dy, -dz+c], // 0: front bottom left
			[-dx, -dy+c, -dz+c],
			[-dx+c, -dy+c, -dz],
			[-dx+c, dy, -dz+c], // 3: back bottom left
			[-dx, dy-c, -dz+c],
			[-dx+c, dy-c, -dz],
			[dx-c, dy, -dz+c], // 6: back bottom right
			[dx, dy-c, -dz+c],
			[dx-c, dy-c, -dz],
			[dx-c, -dy, -dz+c], // 9: front bottom right
			[dx, -dy+c, -dz+c],
			[dx-c, -dy+c, -dz],
			[-dx+c, -dy, dz-c], // 12: front top left
			[-dx, -dy+c, dz-c],
			[-dx+c, -dy+c, dz],
			[-dx+c, dy, dz-c], // 15: back top left
			[-dx, dy-c, dz-c],
			[-dx+c, dy-c, dz],
			[dx-c, dy, dz-c], // 18: back top right
			[dx, dy-c, dz-c],
			[dx-c, dy-c, dz],
			[dx-c, -dy, dz-c], // 21: front top right
			[dx, -dy+c, dz-c],
			[dx-c, -dy+c, dz],
		],
		faces = [
			// front
			[0, 12, 21, 9], // front
			[0, 2, 1], // front bottom left
			[0, 1, 13, 12], // front left
			[12, 13, 14], // front top left
			[12, 14, 23, 21], // front top
			[21, 23, 22], // front top right
			[9, 21, 22, 10], // front right
			[9, 10, 11], // front bottom right
			[0, 9, 11, 2], // front bottom
			// back
			[3, 6, 18, 15], // back
			[3, 4, 5], // back bottom left
			[3, 15, 16, 4], // back left
			[15, 17, 16], // back top left
			[15, 18, 20, 17], // back top
			[18, 19, 20], // back top right
			[6, 7, 19, 18], // back right
			[6, 8, 7], // back bottom right
			[3, 5, 8, 6], // back bottom
			// outer ring
			[1, 4, 16, 13], // left
			[13, 16, 17, 14], // left top
			[14, 17, 20, 23], // top
			[19, 22, 23, 20], // top right
			[7, 10, 22, 19], // right
			[7, 8, 11, 10], // bottom right
			[2, 11, 8, 5], // bottom
			[1, 2, 5, 4], // bottom left
		]
	);	
}

module fbox(size, chamfer)
{
	c = chamfer;
	dx = size[0]/2;
	dy = size[1]/2;
	dz = size[2]/2;
	
	polyhedron(
		points = [
			[-dx+c, -dy, -dz], // 0: front left
			[-dx, -dy+c, -dz],
			[-dx+c, -dy, dz],
			[-dx, -dy+c, dz],
			[-dx+c, dy, -dz], // 4: back left
			[-dx, dy-c, -dz],
			[-dx+c, dy, dz],
			[-dx, dy-c, dz],
			[dx-c, dy, -dz], // 8: back right
			[dx, dy-c, -dz],
			[dx-c, dy, dz],
			[dx, dy-c, dz],
			[dx-c, -dy, -dz], // 12: front right
			[dx, -dy+c, -dz],
			[dx-c, -dy, dz],
			[dx, -dy+c, dz],
		],
		faces = [
			[2, 3, 7, 6, 10, 11, 15, 14], // top
			[1, 5, 7, 3], // left
			[4, 6, 7, 5], // left back
			[4, 8, 10, 6], // back
			[8, 9, 11, 10], // back right
			[9, 13, 15, 11], // right
			[12, 14, 15, 13], // front right
			[0, 2, 14, 12], // front
			[0, 1, 3, 2], // front left
			[0, 12, 13, 9, 8, 4, 5, 1], // bottom
		]
	);	
}




module draw_wheel_for_servo_type_1(servo, style=kStyleDraw)
{
	wheel = servo[6];
	type = wheel[0];
	if (type==undef || type==0) { // wheel: none
	} else if (type==1) { // wheel: disk
		diameter = wheel[1];
		height = wheel[2];
		axle_diameter = diameter/2;
		axle_height = diameter/2;
		// draw the assembly
		union() {
			difference() {
				// draw the wheel
				translate([0.0, 0.0, -height])
					cylinder(d=diameter, h=height);
				// draw holes into the wheel
				translate([0.0, 0.0, -height-d1]) union() {
					for (r=[diameter/12*5, diameter/12*4, diameter/12*3]) {
						translate([ r, 0.0, 0.0]) cylinder(r=1, h=height+d2);
						translate([-r, 0.0, 0.0]) cylinder(r=1, h=height+d2);
						translate([0.0,  r, 0.0]) cylinder(r=1, h=height+d2);
						translate([0.0, -r, 0.0]) cylinder(r=1, h=height+d2);
					}
				}
				// draw a cone into the center of the wheel
				translate([0.0, 0.0, -height+d1])
					cylinder(r1=0, r2=diameter/8, h=height);
			}
			// draw the axle
			translate([0.0, 0.0, -axle_height])
				cylinder(d=axle_diameter, h=axle_height-height+d1);
		}
	} else {
		echo("Unknown servo wheel type: ", type);
	}
}


module clip_wheel_for_servo_type_1(servo, style=kStyleDraw)
{
	body = servo[2];
	offset = servo[3];
	type = body[0];
	size = body[1];
	if (type==1) { // body: chamfered box
//		translate([size[0]/2-offset[0], offset[1], size[2]/2-offset[2]])
//			cbox(body[1], 1.0);
		intersection() {
			translate([0, offset[1], 0])
				cube([1000, size[1], 1000], center=true);
			draw_wheel_for_servo_type_1(servo, style);
		}
	}
}


module draw_body_for_servo_type_1(servo, style=kStyleDraw)
{
	body = servo[2];
	offset = servo[3];
	mount_offset = servo[5];
	type = body[0];
	size = body[1];
	cbox_chamfer = style==kStyleDraw ? 1.0 : 0.1;
	if (type==1) { // body: chamfered box
		difference() {
			translate([size[0]/2-offset[0], offset[1], size[2]/2-offset[2]])
				cbox(body[1], cbox_chamfer);
			if (style==kStyleDraw && Large_Servo_Cable_Channel==1) {
				// half pipe going down the left side fitting the R/C cable
				translate([-offset[0], offset[1], -100-mount_offset])
				//translate([-offset[0], offset[1], -mount_offset-100])
					cylinder(h=200, r=2.5, $fn=6, center=true);
			}
		}
	} else {
		echo("Unknown servo body type: ", type);
	}
}


module draw_mount_for_servo_type_1(servo, style=kStyleDraw)
{
	body = servo[2];
	size = body[1];
	offset = servo[3];
	mount = servo[4];
	mount_offset = servo[5];
	type = mount[0];
	fbox_chamfer = style==kStyleDraw ? size[1]/8 : 0.1;
	if (type==1) { // mount: 2 tabs with two holes each
		// 	[1, [length, width, height], hole_dist_x, hole_dist_y, hole_dia]
		mount_size 	= mount[1];
		hole_dist_x = mount[2]/2;
		hole_dist_y = mount[3]/2;
		hole_dia 		= mount[4];
		// draw the entire mount
		difference() {
			// draw the tabs
			union() {
				translate([size[0]/2-offset[0], offset[1], mount_size[2]/2-mount_offset])
					fbox(mount_size, fbox_chamfer);
				// in 'cut' style, draw space for reinforcement triangle
				if (style==kStyleCut) 
					translate([size[0]/2-offset[0], offset[1], mount_size[2]/2-mount_offset+mount_size[1]/8])
						cube([mount_size[0], mount_size[2], mount_size[1]/4], center=true);				
			}
			// subtract the mounting holes
			// don't draw holes on the small servo if we use clam shell mounting, so we can slide the servo in from the side
			if (style==kStyleDraw || Mount_Small_Servo!=2) {
				// TODO: subtract holes for mounting screws on the small servo
				translate([size[0]/2-offset[0], offset[1], -mount_offset-d1]) {
					hm = mount_size[2]+d2;
					translate([ hole_dist_x,  hole_dist_y, 0.0]) cylinder($fn=16, h=hm, d=hole_dia);
					translate([-hole_dist_x,  hole_dist_y, 0.0]) cylinder($fn=16, h=hm, d=hole_dia);
					if (hole_dist_y>0) {
						translate([ hole_dist_x, -hole_dist_y, 0.0]) cylinder($fn=16, h=hm, d=hole_dia);
						translate([-hole_dist_x, -hole_dist_y, 0.0]) cylinder($fn=16, h=hm, d=hole_dia);
					}
				} 
			}
		}
		// make room for the servo to slide in from the top or bottom
		if (style==kStyleCut) {
			// ---- create space so that the servo can be inserted from above or below
			if (Mount_Small_Servo==0) { // mount from the top (the most common way
				// extend the mount all the way to the top, so we can slide the servo in
				translate([size[0]/2-offset[0], offset[1], mount_size[2]-mount_offset/2])
					fbox([mount_size[0], mount_size[1], mount_offset], fbox_chamfer);
				// create holes for the fasteners
				if (Fastener_Diameter>0) {
					hf = Fastener_Length;
					df = Fastener_Diameter;
					translate([size[0]/2-offset[0], offset[1], -mount_offset+mount[1][2]+d1-hf]) {
						translate([ hole_dist_x,  hole_dist_y, 0.0]) cylinder($fn=16, h=hf, d=df);
						translate([-hole_dist_x,  hole_dist_y, 0.0]) cylinder($fn=16, h=hf, d=df);
						if (hole_dist_y>0) {
							translate([ hole_dist_x, -hole_dist_y, 0.0]) cylinder($fn=16, h=hf, d=df);
							translate([-hole_dist_x, -hole_dist_y, 0.0]) cylinder($fn=16, h=hf, d=df);
						}
					}
				}				
			} else if (Mount_Small_Servo==1) { // mount from the bottom
				// extend the mount all the way to the bottom, so we can slide the servo in
				translate([size[0]/2-offset[0], offset[1], -mount_offset-100])
					fbox([mount_size[0], mount_size[1], 200], fbox_chamfer);
				if (Fastener_Diameter>0) {
					hf = Fastener_Length;
					df = Fastener_Diameter;
					translate([size[0]/2-offset[0], offset[1], -mount_offset-d1]) {
						translate([ hole_dist_x,  hole_dist_y, 0.0]) cylinder($fn=16, h=hf, d=df);
						translate([-hole_dist_x,  hole_dist_y, 0.0]) cylinder($fn=16, h=hf, d=df);
						if (hole_dist_y>0) {
							translate([ hole_dist_x, -hole_dist_y, 0.0]) cylinder($fn=16, h=hf, d=df);
							translate([-hole_dist_x, -hole_dist_y, 0.0]) cylinder($fn=16, h=hf, d=df);
						}
					}
				}
			}
			// ---- cable channel (TODO: shouldn't this be in the 'body' module?
			if (Small_Servo_Cable_Channel==1) {
				// half pipe going down the left side fitting the R/C cable
				translate([-offset[0], offset[1], -mount_offset-100])
					cylinder(h=200, r=2.5, $fn=6, center=true);
				// square pipe going down the side fitting the R/C plug
				translate([-offset[0]+2, offset[1], -mount_offset-100])
					cube([4, 10, 200], center=true);
				// square pipe going out the left side fitting the R/C plug
				translate([-offset[0]-50, offset[1], -offset[2]+7])
					cube([100, 10, 10], center=true);
			}
		}
	} else {
		echo("Unknown servo mount type: ", type);
	}
}


module draw_servo(servo, style=kStyleDraw)
{
	type = servo[0];
	if (type==1) { // ---- R/C servo: case, mount, wheel
		
		// read elements in or possibly incomplete database entry
		class 				= servo[1];
		body 					= servo[2];
		body_offset 	= servo[3];
		mount 				= servo[4];
		mount_offset	= servo[5];
		wheel 				= (servo[6]==undef) ? wheel_db[class] : servo[6];
		
		// create a new servo definition based on the entries we found or added
		new_servo = [1, class, body, body_offset, mount, mount_offset, wheel];
		
		// now draw all parts of our servo
		draw_body_for_servo_type_1(new_servo, style);
		draw_mount_for_servo_type_1(new_servo, style);
		
		if (Draw_Servo_Wheel==0) {
			if (Small_Servo==0) {
				draw_wheel_for_servo_type_1(new_servo, style);
			}
		}
		if (Draw_Servo_Wheel==1) {
			// don't draw it
		} else if (Draw_Servo_Wheel==2) {
			// draw the entire wheel
			draw_wheel_for_servo_type_1(new_servo, style); 
		} else if (Draw_Servo_Wheel==3) {
			// clip the wheel to the body in Y, so it can 3D-print more easily
			clip_wheel_for_servo_type_1(new_servo, style); 
		}
		
	} else {
		
		echo("Unknown servo case type: ", type);
		
	}
}


module draw_scene()
{
	if (Large_Servo!=0 && Small_Servo==0) {
		scale(Large_Servo_Scale/100.0)
			draw_servo(servo_db[Large_Servo][1], style=kStyleDraw);
	} else if (Large_Servo!=0 && Small_Servo!=0) {
		difference() {
			scale(Large_Servo_Scale/100.0)
				draw_servo(servo_db[Large_Servo][1], style=kStyleDraw);
			draw_servo(servo_db[Small_Servo][1], style=kStyleCut);
		}
	} else if (Large_Servo==0 && Small_Servo!=0) {
		color("Salmon")
			draw_servo(servo_db[Small_Servo][1], style=kStyleCut);
	} else if (Large_Servo==0 && Small_Servo==0) {
		rotate([90, 0, 0]) text("empty");
	}
}


/**
 * Draw a shape that is subtracted from the entire scene.
 *
 * Y-Clipping allows for printing the adapter in halves and using them
 * as a clam shell to hold the smaller servo in place.
 * 
 * Draw_Sides = 0; // [0:both sides, 1:left side, 2:right side]
 */
module clip_y() 
{
	// clip both sides, the left side, or the right side
	if (Draw_Sides==1) {
			translate([0, -100, -98])
				cube(200, center=true);
	} else if (Draw_Sides==2) {
			translate([0, 100, -98])
				cube(200, center=true);
	}
}


/**
 * Draw a shape that is subtracted from the entire scene.
 *
 * Z-Clipping reduces the model to the minimal shape that is needed
 * for a servo adapter.
 *
 * Draw_Mount = 0; // [0:full servo, 1: top half, 2: small servo height, 3:minimal, 4:minimal plus]
 * 
 * TODO: this module does not take the type of servo elements into account.
 *       It might make sense to write functions that find these secific measurements.
 */
module clip_z()
{
	scl = Large_Servo_Scale/100.0;
	l_servo = servo_db[Large_Servo][1];
	s_servo = servo_db[Small_Servo][1];
	// ---- draw the top clipping box
	// draw a large cube that clips everything above the top of
	// the small servo mount
	if (s_servo!=undef && (Draw_Mount==3 || Draw_Mount==4)) {
		s_servo_top = -s_servo[5]+s_servo[4][1][2];
		echo(s_servo, s_servo_top);
		translate([0, 0, 100+s_servo_top])
			cube(200, center=true);
	}
	// draw a large cube that clips the lower half of the mount
	if (l_servo!=undef && (Draw_Mount==1 || Draw_Mount==3 || Draw_Mount==4)) {
		// clip belom the large servo mount
		l_servo_bot = -l_servo[5]*scl - ((Draw_Mount==4) ? 10 : 0);
		translate([0, 0, l_servo_bot-100])
			cube(200, center=true);
	} else if (s_servo!=undef && Draw_Mount==2) {
		// clip belom the small servo case
		s_servo_bot = -s_servo[3][2];
		translate([0, 0, s_servo_bot-100])
			cube(200, center=true);
	}
}


/**
 * Draw the entire assembly
 */
module run() 
{	
	// TODO: create the actual servo dataset here by filling in undef values
	difference() {
		draw_scene();
		clip_y();
		clip_z();
	}
}


run();










