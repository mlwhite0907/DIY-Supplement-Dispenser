// Visual approval model V01. Six removable wedges per tier, two tiers.
// Geometry represents exterior and component envelopes, NOT working mechanisms.
// Units mm; export selectors are listed in scripts/build.py.
$fn=96;
part="assembly";
stations=6;
tiers=2;
tier_gap=158;
removed=false;
exploded=false;
outer=150;
inner=37;
body_h=118;
angle=360/stations-2.2;
black=[.075,.082,.095];
silver=[.76,.72,.63];
window_color=[.43,.51,.52];
labels=["PROTEIN","CREATINE","COLLAGEN","GREENS","ELECTROLYTES","RECOVERY"];
function pt(r,a)=[r*sin(a),-r*cos(a)];
module sector2(ro,ri,a){polygon(concat([for(t=[-a/2:a/64:a/2])pt(ro,t)],[for(t=[a/2:-a/64:-a/2])pt(ri,t)]));}
module profile(inset=0){offset(delta=-inset)offset(r=2)offset(delta=-2)sector2(outer,inner,angle);}
module wedge(h,inset=0){linear_extrude(h)profile(inset);}
module roundbox(size,r){linear_extrude(size[2])offset(r=r)offset(delta=-r)square([size[0],size[1]],center=true);}
module body(){
    difference(){
        wedge(body_h);
        translate([0,0,3])wedge(body_h,3);
        // Window cut through metallic skin. Continuous liner visible behind it.
        translate([0,-130,74])rotate([90,0,0])roundbox([52,54,35],3);
        // Wheel recess. Sized for envelope only, not a shaft/bearing/seal interface.
        translate([0,-120,24])rotate([90,0,0])roundbox([72,27,45],7);
    }
}
module liner(){
    difference(){wedge(body_h-3,3.6);translate([0,0,2.4])wedge(body_h,6);}
}
module lid(){
    union(){
        hull(){wedge(1,-.7);translate([0,0,7])wedge(1,1.5);}
        translate([0,0,-4])difference(){wedge(4,3.4);translate([0,0,-.1])wedge(4.2,5.5);}
        // Front release tab and shallow raised thumb pad match the reference silhouette.
        translate([0,-137,6])roundbox([26,19,3],5);
        translate([0,-108,8])roundbox([40,36,1.5],10);
    }
}
module wheel(){
    difference(){
        union(){cylinder(d=60,h=18);for(a=[0:30:330])rotate(a)translate([28.5,0,1])cylinder(d=5,h=16,$fn=24);}
        translate([0,0,-1])cylinder(d=6.4,h=20);
    }
}
module foot(){wedge(6,-.4);}
module label_text(txt){translate([0,-150.2,42])rotate([90,0,0])linear_extrude(.45)text(txt,size=4.2,halign="center",font="Liberation Sans:style=Bold");}
module cartridge(index=0){
    color(silver)body();
    color(window_color)translate([0,0,2])liner();
    color(black)translate([0,0,body_h+(exploded?35:0)])lid();
    color(black)translate([0,-132-(exploded?35:0),15])wheel();
    color(black)translate([0,0,-6])foot();
    color([.16,.17,.18])label_text(labels[index%6]);
}
module tray_sector(){
    difference(){
        linear_extrude(7)sector2(155,25,360/stations-.25);
        for(a=[-12,12])translate(concat(pt(34,a),[-1]))cylinder(d=4.4,h=9);
    }
}
module hub(){difference(){cylinder(d=85,h=7);translate([0,0,-1])cylinder(d=25.8,h=9);}}
module support(){difference(){cylinder(d=25,h=tier_gap);translate([0,0,-1])cylinder(d=8.4,h=tier_gap+2);}}
module handle(){
    // Rounded arch is an appearance envelope; not load rated.
    translate([0,0,6])rotate([90,0,0])linear_extrude(12,center=true)difference(){
        intersection(){scale([1,.55])circle(r=51);translate([-55,0])square([110,40]);}
        scale([1,.52])circle(r=40);
    }
    cylinder(d=116,h=6);
}
module tier(){
    color(black)hub();
    for(i=[0:stations-1])rotate(i*360/stations){
        color(black)tray_sector();
        translate([0,(removed && i==0)?-100:0,13+((removed && i==0)?8:0)])cartridge(i);
    }
    color(black)translate([0,0,139])cylinder(d=77,h=6);
}
module base_sector(){linear_extrude(14)sector2(157,25,89.8);}
module base(){color(black){for(i=[0:3])rotate(i*90)base_sector();cylinder(d=85,h=14);}}
module assembly(levels=tiers){
    base();
    for(k=[0:levels-1]){
        color(black)translate([0,0,14+k*tier_gap])support();
        translate([0,0,14+k*tier_gap])tier();
    }
    color(silver)translate([0,0,14+(levels-1)*tier_gap+150])handle();
}
module separated(){
    translate([-190,0,0]){base();translate([0,0,14])tier();color(silver)translate([0,0,164])handle();}
    translate([190,0,0]){base();translate([0,0,14])tier();color(silver)translate([0,0,164])handle();}
}
if(part=="assembly")assembly();
else if(part=="single")assembly(1);
else if(part=="separated")separated();
else if(part=="cartridge")cartridge();
else if(part=="body")body();
else if(part=="liner")liner();
else if(part=="lid")lid();
else if(part=="wheel")wheel();
else if(part=="foot")foot();
else if(part=="tray_sector")tray_sector();
else if(part=="hub")hub();
else if(part=="base_sector")base_sector();
else if(part=="handle")handle();
else assert(false,str("Unknown part ",part));
