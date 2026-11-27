// EARLY MECHANISM STUDY, not integrated with the appearance model. Front dial axis differs.
// V01 mechanical development model. Millimeters. See README for untested limits.
// Export a single part with -D 'part="hopper"'. No print or load rating implied.
$fn=72;
part="assembly";
stations=6;
tiers=2;
pitch=360/stations;
cartridge_angle=pitch-3;
R=132;
outer_r=174;
inner_r=96;
tier_pitch=180;
rotor_angle=90; // 0 fill, 90 park, 180 release. Always verify mass on a scale.
explode=0;
show_powder=false;
dark=[0.08,0.09,0.10];
satin=[0.77,0.73,0.63];
clear=[0.58,0.73,0.75,0.50];
function polar(r,a)=[r*sin(a),-r*cos(a)];
module annulus(ro,ri,h){difference(){cylinder(r=ro,h=h);translate([0,0,-.1])cylinder(r=ri,h=h+.2);}}
module sector2(ro,ri,a){polygon(concat([for(t=[-a/2:a/48:a/2])polar(ro,t)],[for(t=[a/2:-a/48:-a/2])polar(ri,t)]));}
module wedge(h,inset=0){translate([0,R,0])linear_extrude(h)offset(delta=-inset)sector2(outer_r,inner_r,cartridge_angle);}
module ycyl(d,h){rotate([90,0,0])cylinder(d=d,h=h,center=true);}
module dshaft(d,h,flat){intersection(){ycyl(d,h);translate([-d,-h,-d])cube([d+flat,2*h,2*d]);}}
module screw_y(x,z,d=3.4,h=100){translate([x,0,z])ycyl(d,h);}
module hopper_volume(){
    // Loft from 22 x 26 throat to wedge. Thin slices avoid degenerate hulls.
    hull(){translate([-11,-13,0])cube([22,26,.2]);translate([0,0,44])wedge(.2,3);}
    translate([0,0,44])wedge(65,3);
}
module hopper(){
    difference(){
        union(){
            hull(){translate([-14,-16,0])cube([28,32,.2]);translate([0,0,44])wedge(.2);}
            translate([0,0,44])wedge(65);
            // Cassette flange, four M3 through holes; matching captive nuts below.
            translate([-24,-22,0])cube([48,44,5]);
        }
        translate([0,0,-.1])hopper_volume();
        for(x=[-19,19],y=[-17,17])translate([x,y,-1])cylinder(d=3.4,h=8);
    }
}
module sleeve(){
    // Cosmetic outer skin; clear hopper behind window is a continuous powder wall.
    difference(){
        translate([0,0,43])wedge(67,-1.8);
        translate([0,0,42.9])wedge(68,-.5);
        translate([-13,-60,66])cube([26,35,34]);
    }
}
module lid(){
    union(){
        wedge(4,-2.5);
        translate([0,0,-6])difference(){wedge(6,3.4);translate([0,0,-.1])wedge(6.2,5.5);}
    }
}
module housing(){
    difference(){
        union(){
            translate([-26,-26,0])cube([52,52,50]);
            translate([-23,-38,0])cube([46,76,4]); // rear hook and front latch feet
        }
        // Front-open bore. Back wall retains rear journal. Front cap is separate.
        translate([0,-2,25])ycyl(42.7,48.8); // y -26.4 .. 22.4
        translate([0,25,25])ycyl(10.6,8);
        translate([-12,-14,-1])cube([24,28,10]);
        translate([-12,-14,40])cube([24,28,11]);
        for(x=[-22,22],z=[8,42])translate([x,-21,z])ycyl(2.6,11); // pilot, self-tap prototype
        for(x=[-19,19],y=[-17,17]){
            translate([x,y,42])cylinder(d=3.4,h=9);
            translate([x,y,42])cylinder(d=6.4,h=3,$fn=6); // nut traps accessed from bore
        }
    }
}
module rotor(){
    difference(){
        union(){translate([0,0,25])ycyl(42,44);
            translate([0,-30.5,25])dshaft(10,17,3.5);
            translate([0,24.5,25])ycyl(10,5);
        }
        translate([-10,-12,29])cube([20,24,25]); // one blind metering pocket
    }
}
module cap(){
    difference(){
        translate([-26,-30,0])cube([52,3.6,50]);
        translate([0,-28,25])ycyl(10.6,6);
        for(x=[-22,22],z=[8,42])screw_y(x,z);
        // Four indexing dimples for spring-ball plunger in the dial.
        for(a=[0:90:270])translate([15*sin(a),-30.5,25+15*cos(a)])sphere(d=3.2,$fn=24);
    }
}
module dial(){
    difference(){
        union(){
            translate([0,-36,25])ycyl(38,11);
            for(a=[0:30:330])translate([18*sin(a),-36,25+18*cos(a)])ycyl(3.5,10);
        }
        translate([0,-36,25])dshaft(10.4,13,3.7);
        translate([0,-36,40])ycyl(4.2,14); // M4 spring-ball plunger, verify purchased length
        // radial M3 set-screw hole, tap after print
        translate([-1,-36,25])rotate([0,90,0])cylinder(d=2.6,h=23);
    }
}
module dust_cap(){
    difference(){translate([-15,-17,-4])cube([30,34,7]);translate([-12.4,-14.4,-1.5])cube([24.8,28.8,5]);}
}
module cradle(){
    difference(){
        union(){
            translate([-26,-43,0])cube([52,86,5]);
            // Rear retaining hooks, 0.5 vertical gap above foot when seated.
            for(x=[-22,16])translate([x,35,5])cube([6,7,11]);
            for(x=[-22,16])translate([x,32,9.5])cube([6,10,4]);
            // Front flexible thumb latch; pushed outward to lift cartridge.
            translate([-7,-43,3])cube([14,1.6,18]);
            translate([-7,-43,9.5])cube([14,7,3]);
            // lateral locating pads
            for(x=[-28,26])translate([x,-23,0])cube([2,46,9]);
        }
        for(y=[-24,24])translate([0,y,-1])cylinder(d=4.4,h=7);
    }
}
module station_plate(){
    difference(){
        linear_extrude(6)sector2(184,32,pitch-.4);
        for(a=[-pitch*.23,pitch*.23])translate(concat(polar(39,a),[-1]))cylinder(d=4.4,h=8);
        for(y=[-24,24])translate([0,-R+y,-1])cylinder(d=4.4,h=8);
        // Blind nut seats underneath keep cradle fasteners out of rotation path.
        for(y=[-24,24])translate([0,-R+y,-.1])cylinder(d=7.8,h=3.4,$fn=6);
    }
}
module hub(){
    difference(){
        union(){cylinder(r=44,h=6);cylinder(d=34,h=32);}
        translate([0,0,-1])cylinder(d=24.7,h=34);
        for(i=[0:stations-1],a=[-pitch*.23,pitch*.23])translate(concat(polar(39,i*pitch+a),[-1]))cylinder(d=4.4,h=8);
    }
}
module washer(){annulus(20,12.5,1.5);}
module column(){
    difference(){
        union(){cylinder(d=24,h=tier_pitch);translate([0,0,tier_pitch])cylinder(d=18,h=24);}
        translate([0,0,-.1])cylinder(d=18.6,h=24.5);
        translate([0,0,12])ycyl(5.4,30);
        translate([0,0,tier_pitch+12])ycyl(5.4,30);
        translate([0,0,23])cylinder(d=8,h=tier_pitch-22);
    }
}
module top_stop(){
    difference(){
        union(){cylinder(d=46,h=5);cylinder(d=26,h=26);}
        translate([0,0,-.1])cylinder(d=18.6,h=27);
        translate([0,0,12])ycyl(5.4,50);
    }
}
module base_hub(){
    difference(){
        union(){cylinder(d=94,h=16);cylinder(d=18,h=40);}
        translate([0,0,28])ycyl(5.4,100);
        for(a=[0:30:330])translate(concat(polar(39,a),[-1]))cylinder(d=4.4,h=18);
    }
}
module base_sector(){
    difference(){
        linear_extrude(16)sector2(190,32,59.7);
        // three mounting holes on common 30 degree grid, sector centers at 0,60...300
        for(a=[-30,0,30])translate(concat(polar(39,a),[-1]))cylinder(d=4.4,h=18);
        // recess for adhesive rubber foot, not a structural glue connection
        translate(concat(polar(156,0),[-.1]))cylinder(d=22,h=2.1);
    }
}
module crown_segment(){
    // Decorative rotating roof, held by radial struts on top collar.
    difference(){
        union(){linear_extrude(4)sector2(179,26,pitch-.4);translate([0,0,-4])linear_extrude(4)sector2(179,172,pitch-.4);}
        for(a=[-pitch*.23,pitch*.23])translate(concat(polar(39,a),[-1]))cylinder(d=4.4,h=6);
    }
}
module collar(){
    difference(){
        cylinder(d=88,h=6);
        translate([0,0,-1])cylinder(d=24.7,h=8);
        for(i=[0:stations-1],a=[-pitch*.23,pitch*.23])translate(concat(polar(39,i*pitch+a),[-1]))cylinder(d=4.4,h=8);
    }
}
module post(){difference(){cylinder(d=9,h=149);translate([0,0,-1])cylinder(d=4.4,h=151);}}
module cartridge(){
    color(dark) housing();
    color([.43,.46,.45])translate([0,0,25])rotate([0,rotor_angle,0])translate([0,0,-25])rotor();
    color(dark)translate([0,-explode*.7,0])cap();
    color(dark)translate([0,-explode,0])translate([0,0,25])rotate([0,rotor_angle,0])translate([0,0,-25])dial();
    color(clear)translate([0,0,50+explode])hopper();
    color(satin)translate([0,0,50+explode])sleeve();
    color(dark)translate([0,0,159+explode*2])lid();
}
module tier(){
    color(dark)translate([0,0,-6])hub();
    color(dark)for(i=[0:stations-1])rotate(i*pitch){
        station_plate();
        translate([0,-R,6])cradle();
    }
    for(i=[0:stations-1])rotate(i*pitch)translate([0,-R,11])cartridge();
    // Crown is lifted 3 mm clear of cartridge lids. Remove cartridge radially after tilting.
    color(dark)translate([0,0,173])collar();
    color(dark)for(i=[0:stations-1])rotate(i*pitch)translate([0,0,179])crown_segment();
}
module assembly(){
    color(dark){base_hub();for(a=[0:60:300])rotate(a)base_sector();}
    for(k=[0:tiers-1]){
        color([.34,.36,.36])translate([0,0,16+k*tier_pitch])column();
        color([.65,.65,.65])translate([0,0,16+k*tier_pitch])washer();
        translate([0,0,23.5+k*tier_pitch])tier();
    }
    color(dark)translate([0,0,16+tiers*tier_pitch])top_stop();
}
if(part=="assembly")assembly();
else if(part=="tier")tier();
else if(part=="cartridge")cartridge();
else if(part=="hopper")hopper();
else if(part=="sleeve")sleeve();
else if(part=="lid")lid();
else if(part=="housing")housing();
else if(part=="rotor")rotor();
else if(part=="cap")cap();
else if(part=="dial")dial();
else if(part=="dust_cap")dust_cap();
else if(part=="cradle")cradle();
else if(part=="station_plate")station_plate();
else if(part=="hub")hub();
else if(part=="washer")washer();
else if(part=="column")column();
else if(part=="top_stop")top_stop();
else if(part=="base_hub")base_hub();
else if(part=="base_sector")base_sector();
else if(part=="crown_segment")crown_segment();
else if(part=="collar")collar();
else if(part=="post")post();
else if(part=="hopper_volume")hopper_volume();
else assert(false,str("Unknown part: ",part));
