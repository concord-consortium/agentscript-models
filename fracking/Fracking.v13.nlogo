turtles-own [moved? moveable? trapped?] ;Boolean set when turtle moves (so that we only move once per tick)
patches-own [ptype pcount] ;ptype is air, land, water, various types of rock; pcount is used for tracking fissure formation patch by patch
globals [
  product ; number of natural gas "turtles" acquired at the well-head
  product-list ;list of turtles acquired by year of acquisition. (Note: there are as many items in the list as the total number of turtles acquired)
  pcount-index ; used to keep track of depth of fissure formation
  fill-fluid ; can be "water" or "propane"
  fill-type ; can be "water-fracking" or "propane-fracking"
  empty-type ; can be "water-empty" or "propane-empty"
  fill-color ; can be "clean-water" or "clean-propane"
  center ;center of screen
  depth
  height ;height of display
  width ; width of display
  v-well-list ;list of vertical well centers and depths driled so far. [v-well-center v-drill-progress v-water-row this-well-full?]
  v-well-center ;location (horizontal coordinate)of vertical well currently being drilled
  v-drill-progress ;used to communicate the depth of a vertical well already in progress to the drill method
  v-water-row ;the row currently being filled
  this-well-full? 
  v-well-list-index ;used to communicate the position on the vertical well list of the vertical well being drilled
  l-well-list ;list of left well centers and depths driled so far. [l-well-center l-drill-progress l-start-point l-water-column]
  l-well-center ;location (vertical coordinate) of left well currently being drilled 
  l-drill-progress ;used to communicate the length of a left well already in progress to the drill method
  l-well-list-index ;used to communicate the position on the left well list of the left well being drilled
  r-well-list ;list of right well centers and depths driled so far. [r-well-center r-drill-progress r-start-point r-water-column]
  r-well-center ;location (vertical coordinate) of right well currently being drilled
  r-drill-progress ;used to communicate the length of a right well already in progress to the drill method
  r-well-list-index ;used to communicate the position on the right well list of the right well being drilled
  v-well-depth ;maximum depth of vertical wells
  h-well-depth ;maximum length of horizontal (left and right) wells
  l-start-point ;used to communicate the starting point of l-wells
  r-start-point ;used to communicate the starting point of r-wells
  well-width ;fixed width of all wells, vertical and horizontal
  explore-range ;range over which we get information from a vertical or horizontal well
  shale-fractability
  rock-fractability
  drilling?
  drilled?
  exploding?
  first-time-exploding?
  exploded?
  first-fill?
  fill-depth
  fracking? 
  first-time-infiltrating?
  infiltrating?
  infiltrated?
  filling?
  filled?
  color-changed?
  pumping-out?
  pumped-out?
  first-pump-out?
  test-color
  here-type
  here-count
  left-type
  left-count
  right-type
  right-count
  up-type
  up-count
  down-type
  down-count
  up-left-type
  up-left-count
  down-left-type
  down-left-count
  up-right-type
  up-right-count
  down-right-type
  down-right-count
  min-count
  base-depth
  oil-depth
  water-depth
  land-depth
  air-depth
  clean-water
  clean-propane
  dirty-water
  color-list
  highest-patch-fracked ;used to speed up emptying process
]

to setup
  clear-all
  set product 0
  set product-list []
  histogram product-list
  set fill-fluid "water"
  ask patches [set pcount 1000]
  set pcount-index 0
  set shale-fractability 42
  set rock-fractability 10
  set height max-pycor - min-pycor
  set width max-pxcor - min-pxcor
  set center ( max-pxcor - min-pxcor ) / 2
  set explore-range 5
  set l-start-point 7
  set highest-patch-fracked 0
  set color-list [95 84 83.8 83.6 83.4 83.2 83 82.8 82.6 82.4 82.2]
  set clean-water first color-list
  set dirty-water last color-list
  set clean-propane 56
  set drilling? false
  set drilled? false
  set exploding? false
  set first-time-exploding? true
  set exploded? false
  set first-time-infiltrating? true
  set infiltrating? false
  set infiltrated? false
  set filling? false
  set filled? false
  set first-fill? true
  set fracking? false
  set fill-depth air-depth
  set color-changed? false
  set pumping-out? false
  set pumped-out? false
  set first-pump-out? true
  set v-well-list [] 
  set v-well-list-index 0
  set l-well-list [] 
  set l-well-list-index 0
  set r-well-list [] 
  set r-well-list-index 0
  set well-width 4
  set base-depth round ( min-pycor + 0.2 * max-pycor )
  set oil-depth round ( min-pycor + 0.4 * max-pycor )
  set water-depth round ( min-pycor + 0.6 * max-pycor )
  set land-depth round ( min-pycor + 0.75 * max-pycor)
  set air-depth round ( min-pycor + 0.8 * max-pycor )
  set v-well-depth round (max-pycor - (max-pycor - min-pycor) * 0.99) 
  set h-well-depth 50
  set v-drill-progress round air-depth ;initial value
  ask patches [ set pcolor white ]
  ask patches [if (pycor > air-depth ) [ set ptype "air"  set pcolor 106] ]
  ask patches [if (pycor > land-depth and pycor <= air-depth) [ set ptype "land" set pcolor 75] ]
  ask patches [if ( (pycor > water-depth + height * sin (1.5 * pxcor - width / 4) / 20) and ( pycor <= land-depth ) ) [ set ptype "water" ] ]
  
  ask patches [if ( (pycor > oil-depth + height * sin (0.9 * pxcor) / 15) and (pycor <= water-depth + height * sin (1.5 * pxcor - width / 4) / 20) ) [ set ptype "rock"] ]
  
  ask patches [if (pycor > base-depth + height * 0.9 * sin ( (1.8 * pxcor) + 45) / 25 + pxcor / 14) and (pycor <= oil-depth + height * sin (0.9 * pxcor) / 15) [ set ptype "shale" ] ]
  ask patches [if (pycor <= base-depth + height * 0.9 * sin ( (1.8 * pxcor) + 45) / 25 + pxcor / 14)  [ set ptype "rock"] ]
  ask patches with [(pycor = min-pycor) or (pycor = max-pycor) or (pxcor = min-pxcor) or (pxcor = max-pxcor)] [set ptype "n/a"]

  create-turtles 1000
  ask turtles [
    setxy ( 2 + random (width - 4)) (2 + random (height - 4))
    while [ not ( [ ptype ] of patch-here = "shale" )] [ setxy ( 2 + random (width - 4)) (2 + random (height - 4)) ]
    set color red
    set heading 180
    set size 4
    set moveable? false
    set trapped? ((random 100) <= 14)
    ht
    ]
  reset-ticks
end


to go
  drill
  explode
  fill
  frack
  change-color
  pump-out
  move-turtles
  tick ;update display
end

to drill
  if mouse-down? [
  ifelse (mouse-on-land?) [drill-vertical]
  [drill-left 
   drill-right
  ]
;  print "              ****************************"
;  type "mouse in l-well? " type mouse-in-l-well? type ", mouse in r-well? " print mouse-in-r-well? 
;  type "l-well nearby? " type l-well-nearby? type ", r-well-nearby? " print r-well-nearby?
;  type "mouse-xcor = " type mouse-xcor type ", mouse-ycor = " print mouse-ycor
;  type "l-well-list = " type l-well-list type ", r-well-list = " print r-well-list
  ]
end

to drill-vertical
    ifelse (mouse-in-v-well?) [ ;continue drilling at old location
      set v-well-center item 0 item v-well-list-index v-well-list
      set v-drill-progress item 1 item v-well-list-index v-well-list
;      print"" type "in drill-vertical continuing old well. v-well-center = " print v-well-center
;      type "v-drill-progress = " print v-drill-progress
      v-drill-here
    ] 
    [
      if (not v-well-nearby?) [ ;start a new well
      set v-well-center round mouse-xcor ;set new well center
      set v-drill-progress air-depth ;set drill progress at the top
      set v-water-row air-depth ;new v-well is empty
      set this-well-full? false
      set v-well-list fput ( list (v-well-center) (v-drill-progress) (v-water-row) (this-well-full?)) v-well-list ;put the new well on the front of the list
      set v-well-list-index 0 ;and set the pointer to the beginning of the list so that v-drill-here won't screw things up
;      type "in drill-vertical starting new well. v-well-center = " print v-well-center
      v-set-colors   
      v-drill-here
    ]
  ]
end

to drill-left ;we only get here if we're not clicking on the land
  ifelse (mouse-in-v-well?) [ ;start an l-well or continue one
;    print "mouse in v-well"
    ifelse (mouse-in-l-well?) [ ;there's one already started. Continue it.
;      print "continuing l-well" 
      l-drill-here
    ]
    [ ;if we're in a v-well but there's no l-well started yet, start one
      set l-well-center round mouse-ycor ;start one
      set l-drill-progress well-width / 2
      set l-start-point v-well-center
      let l-water-column l-start-point ;new l-well is empty
      set l-well-list fput (list (l-well-center) (l-drill-progress) (l-start-point) ) l-well-list ;put it on the list
      set l-well-list-index 0 ;point to the new well
      l-drill-here
    ]
  ]
  [ ;if mouse click not in v-well
  if (mouse-in-l-well?) [ ;if already in left well continue drilling this well
  set l-start-point item 2 item l-well-list-index l-well-list ;the l-start-point of left well
  set l-drill-progress item 1 item l-well-list-index l-well-list
  set l-well-center item 0 item l-well-list-index l-well-list
  l-drill-here
  ]
  ]  
end
  
to drill-right ;we only get here if we're not clicking on the land
  ifelse (mouse-in-v-well?) [ ;start an r-well or continue one
;    print "mouse in v-well"
    ifelse (mouse-in-r-well?) [ ;there's one already started. Continue it.
;      print "continuing r-well" 
      r-drill-here
    ] ;if we're in a v-well but there's no l-well started yet, start one
    [
      set r-well-center round mouse-ycor ;start one
      set r-drill-progress well-width / 2
      set r-start-point v-well-center
      let r-water-column r-start-point ;new r-well is empty
;      type "R-WELL-LIST BEFORE ADDITION OF NEW WELL = " print r-well-list
      set r-well-list fput (list (r-well-center) (r-drill-progress) (r-start-point) ) r-well-list ;put it on the list
;      type "R-WELL-LIST AFTER ADDITION OF NEW WELL = " print r-well-list
      set r-well-list-index 0 ;point to the new well
      r-drill-here
    ] 
  ]
  [ ;if mouse click not in v-well
  if (mouse-in-r-well?) [ ;if already in right well continue drilling this well
  set r-start-point item 2 item r-well-list-index r-well-list ;the l-start-point of left well
  set r-drill-progress item 1 item r-well-list-index r-well-list
  set r-well-center item 0 item r-well-list-index r-well-list
  r-drill-here
  ]
 ]  
end

to v-drill-here
    v-set-colors   
    set v-drill-progress (v-drill-progress - 1)
;    type "in v-drill-here v-well-list = " print v-well-list
; put the decremented drill-progress into the right place in v-well-list
    let current-well-list item v-well-list-index v-well-list ;get the list of the well being drilled
    set current-well-list replace-item 1 current-well-list v-drill-progress ;replace its v-drill-progress with the decremented one
    set v-well-list replace-item v-well-list-index v-well-list current-well-list ;and put it back in the right place in v-well-list
;    type "in v-drill-here after change v-well-list = " print v-well-list 
end

to l-drill-here
    l-set-colors
    set l-drill-progress (l-drill-progress + 1) 
;    type "in l-drill-here, l-well-list = " print l-well-list
; put the incremented drill-progress into the right place in l-well-list
    let current-well-list item l-well-list-index l-well-list ;get the list of the well being drilled
    set current-well-list replace-item 1 current-well-list l-drill-progress ;replace its v-drill-progress with the incremented one
    set l-well-list replace-item l-well-list-index l-well-list current-well-list ;and put it back in the right place in v-well-list
;    type "in l-drill-here after change l-well-list = " print l-well-list
end

to r-drill-here
    r-set-colors
    set r-drill-progress (r-drill-progress + 1) 
;    type "in r-drill-here, r-well-list = " print r-well-list
; put the incremented drill-progress into the right place in l-well-list
    let current-well-list item r-well-list-index r-well-list ;get the list of the well being drilled
    set current-well-list replace-item 1 current-well-list r-drill-progress ;replace its v-drill-progress with the incremented one
    set r-well-list replace-item r-well-list-index r-well-list current-well-list ;and put it back in the right place in v-well-list
;    type "in r-drill-here after change l-well-list = " print r-well-list
end

    
to v-set-colors
  ask patches [ 
    if ((pycor > v-drill-progress) and (pycor < air-depth)) [
    if ((pxcor < v-well-center + well-width / 2) and (pxcor > v-well-center - well-width / 2 ))  [ set pcolor grey set ptype "pipe" set pcount 0]
    if ((pxcor = v-well-center + well-width / 2 ) or (pxcor = v-well-center - well-width / 2 )) [ set pcolor grey - 2 set ptype "border" set pcount 0]
    if (( pxcor < ( v-well-center - well-width / 2 ) and pxcor >= ( v-well-center - well-width / 2 - explore-range )) or 
        ( pxcor > ( v-well-center + well-width / 2 ) and pxcor <= ( v-well-center + well-width / 2 + explore-range ))) [
          if (ptype = "water") [ set pcolor blue ]
          if (ptype = "rock") [ set pcolor brown ]
          if (ptype = "shale") [ set pcolor yellow ]
       ]
    ]
 ] 
 end
    
to l-set-colors
 ; type "in l-set-colors, l-well-center = " type l-well-center type ", l-drill-progress = " type l-drill-progress 
 ; type ", l-start-point = " type l-start-point type ", l-well-list = " print l-well-list
    let well-bottom ( l-well-center -  well-width / 2 )
    let well-top (l-well-center + well-width / 2 )
    let right-end round ( l-start-point - well-width / 2 )
    let left-end round ( l-start-point - l-drill-progress )
  ask patches [
    if not ( pcolor = red ) [ 
    if (pxcor >= left-end and pxcor <= right-end ) [ ;if you're within the horizontal range of the l-well
    if (pycor >= well-bottom and pycor <= well-top)  [ set pcolor grey set ptype "pipe" set pcount 0]
;    if (pycor = well-bottom or pycor = well-top) [ set pcolor grey - 2 set ptype "border"]
    if (( pycor < well-bottom and pycor >= well-bottom - explore-range ) or 
       ( pycor > well-top and pycor <= well-top + explore-range )) [
          if (ptype = "water") [ set pcolor blue ]
          if (ptype = "rock") [ set pcolor brown ]
          if (ptype = "shale") [ set pcolor yellow ]
       ]
     ]
    ]
  ]
  if ( ( round l-drill-progress >= 20 ) and ( round l-drill-progress mod 20 = 0 ) ) [
    ask patches with [ ( pycor >= well-top and pycor <= well-top + explore-range ) or ( pycor >= well-bottom - explore-range and pycor <= well-bottom ) 
      and pxcor = left-end ] [ set pcolor red set ptype "exploding"]
  ]
 end

to r-set-colors
    let well-bottom ( r-well-center -  well-width / 2 )
    let well-top (r-well-center + well-width / 2 )
    let right-end round ( r-start-point + r-drill-progress ) 
    let left-end round ( r-start-point + well-width / 2 )
  ask patches [
    if not (pcolor = red) [
    if (pxcor <= right-end and pxcor >= left-end) [ 
    if (pycor >= well-bottom and pycor <= well-top)  [ set pcolor grey set ptype "pipe" set pcount 0]
;    if (pycor = well-bottom or pycor = well-top) [ set pcolor grey - 2 set ptype "border"]
    if ( pycor < well-bottom and pycor > well-bottom - explore-range ) or 
       ( pycor > well-top and pycor < well-top + explore-range ) [
          if (ptype = "water") [ set pcolor blue ]
          if (ptype = "rock") [ set pcolor brown ]
          if (ptype = "shale") [ set pcolor yellow ]
     ]
    ]
  ]
 ] 
  if ( ( round r-drill-progress >= 20 ) and ( round r-drill-progress mod 20 = 0 ) ) [
;    print count patches with [ptype = "border"]
;    type "well-top = " type well-top type ", explore-range = " type explore-range type ", well-bottom = " type well-bottom type ", right-end = " print right-end
    ask patches with [ (( pycor >= well-top and pycor <= well-top + explore-range) or ( pycor >= well-bottom - explore-range and pycor <= well-bottom ) )
      and pxcor = right-end ] [ set pcolor red set ptype "exploding"]
]        
end

to-report mouse-on-land?
   report ( mouse-ycor < air-depth) and (mouse-ycor > land-depth)
end

to-report mouse-in-v-well?
  if ( not empty? v-well-list ) [
  set v-well-list-index 0
  while [ v-well-list-index < length v-well-list ] 
    [
      set v-well-center item 0 item v-well-list-index v-well-list
      set v-drill-progress item 1 item v-well-list-index v-well-list
;      type "mouse-ycor = " type mouse-ycor type ", v-drill-progress = " print v-drill-progress
      if ( ( abs ( mouse-xcor - v-well-center ) < well-width ) and ( mouse-ycor >= min ( list v-drill-progress land-depth ) ) ) [
 ;       type "in mouse-in-v-well? reporting true, v-well-center = "
;        type v-well-center type ", mouse-xcor = " type mouse-xcor type ", v-well-list-index = " print v-well-list-index
        report true 
      ]
      set v-well-list-index v-well-list-index + 1
    ]
  ]
    report false
end

to-report mouse-in-l-well? 
  ifelse ( empty? l-well-list ) [ report false ] [
  set l-well-list-index 0
  while [ l-well-list-index < length l-well-list ] 
  [
   set l-well-center item 0 item l-well-list-index l-well-list
   set l-drill-progress item 1 item l-well-list-index l-well-list
   set l-start-point item 2 item l-well-list-index l-well-list
   let well-left-end l-start-point - l-drill-progress - well-width / 2
   let well-right-end l-start-point + well-width / 2
;   type "well-left-end = " type well-left-end type ", well-right-end = " type well-right-end type ", mouse-xcor = " print mouse-xcor 
;   type "l-well-list = " type l-well-list type", mouse-ycor = " print mouse-ycor
   if ( ( abs ( mouse-ycor - l-well-center ) <= well-width ) and ( mouse-xcor <= well-right-end ) and ( mouse-xcor > well-left-end ) ) [
;    type "mouse-in-l-well? reporting true. l-well-center = " print l-well-center
    report true 
    ]
   set l-well-list-index l-well-list-index + 1
  ]
;     type "mouse-in-l-well? reporting false. l-well-center = " print l-well-center
   report false
  ]
end

to-report mouse-in-r-well? 
;  type "in mouse-in-r-well? r-well-list = " print r-well-list
  ifelse ( empty? r-well-list ) [ report false ] [
  set r-well-list-index 0
  while [ r-well-list-index < length r-well-list ] 
  [
   set r-well-center item 0 item r-well-list-index r-well-list
   set r-drill-progress item 1 item r-well-list-index r-well-list
   set r-start-point item 2 item r-well-list-index r-well-list
   let well-right-end r-start-point + r-drill-progress
   let well-left-end r-start-point - well-width  / 2
   if ( ( abs ( mouse-ycor - r-well-center ) < well-width ) and ( mouse-xcor <= well-right-end ) and ( mouse-xcor > well-left-end ) ) [
    report true 
    ]
   set r-well-list-index r-well-list-index + 1
  ]
;     type "mouse-in-r-well? reporting false. r-well-center = " print r-well-center
   report false
  ]
end
  



to-report v-well-nearby?
  set v-well-list-index 0
  while [ v-well-list-index < length v-well-list ] 
  [
   set v-well-center item 0 item v-well-list-index v-well-list
   set v-drill-progress item 1 item v-well-list-index v-well-list
   if ( abs ( mouse-xcor - v-well-center ) < 3 * explore-range ) [
    report true 
    ]

   set v-well-list-index v-well-list-index + 1
  ]
;  print "in v-well-nearby? reporting false v-well-center = " print v-well-center
    report false
end
  
to-report l-well-nearby?
  set l-well-list-index 0
  while [ l-well-list-index < length l-well-list ] 
  [
   set l-well-center item 0 item l-well-list-index l-well-list
   set l-drill-progress item 1 item l-well-list-index l-well-list
   if ( abs ( mouse-ycor - l-well-center ) < 3 * explore-range ) [
;     print "l-well-nearby? reporting true"
    report true 
    ]
   set l-well-list-index l-well-list-index + 1
  ]
;       print "l-well-nearby? reporting false"
    report false
end

to-report r-well-nearby?
  set r-well-list-index 0
  while [ r-well-list-index < length r-well-list ] 
  [
   set r-well-center item 0 item r-well-list-index r-well-list
   set r-drill-progress item 1 item r-well-list-index r-well-list
   if ( abs ( mouse-ycor - r-well-center ) < 3 * explore-range ) [
;     type "r-well-nearby? reporting true"
    report true 
    ]
   set r-well-list-index r-well-list-index + 1
  ]
;       print "r-well-nearby? reporting false"
    report false
end



to set-off-explosions
  ifelse (exploding?) [ set exploding? false ] [ set exploding? true set exploded? false]
end

to explode
  if  exploding? [
      if first-time-exploding? [set pcount-index 0 set first-time-exploding? false]
  set pcount-index pcount-index + 1
  while [ count patches with [ptype = "exploding"] > 0 ] [
  ask patches with [ptype = "exploding"] [
     ask patches at-points [ [-1 0] [1 0] [0 1] [0 -1] ]
      [ if ((ptype = "shale" or (ptype = "border")) and (random-float 100 < shale-fractability ))
          [ set pcolor red  set ptype "exploding" set pcount pcount-index] 
      ]
     ask patches at-points [ [-1 0] [1 0] [0 1] [0 -1] ]
      [ if ((ptype = "rock") and (random-float 100 < rock-fractability ))
          [ set pcolor red set ptype "exploding" set pcount pcount-index] 
      ]
      set ptype "open"
      set pcolor black
   ]
   tick
  ]
  if count patches with [ptype = "exploding"] = 0 [
  set exploding? false
  set exploded? true
  ]
]
end

to fill-with-water
  set fill-fluid "water"
  ifelse ( filling? = true )
  [ set filling? false ]
  [ set filling? true
    set first-fill? true
    set filled? false]
end

to fill-with-propane
  set fill-fluid "propane"
  ifelse ( filling? = true )
  [ set filling? false ]
  [ set filling? true
    set first-fill? true
    set filled? false]
end

to fill
  if ( filling? ) [
  fill-and-frack
  set pumped-out? false
  ]  
end

to fill-and-frack
  if not filled? [
  ifelse first-fill? [set first-fill? false set fill-depth air-depth] [
    if (fill-fluid = "water") [set fill-color clean-water set fill-type "water-fracking"]
    if (fill-fluid = "propane") [set fill-color clean-propane set fill-type "propane-fracking"]
  set pcount-index pcount-index + 1
  ask patches with [ptype = "pipe"] [ set pcolor fill-color set ptype fill-type]
  ask patches with [( ptype = fill-type)] 
     [ask patches at-points [ [-1 0] [1 0] [-1 1] [0 1] [1 1] [0 -1] [1 -1] [-1 -1]] ;adjacent patches fill with water
     [if (ptype = "open") [set ptype fill-type set pcolor fill-color set pcount pcount-index]
     ]
  ]
  if (count patches with [ptype = "pipe"] + count patches with [ptype = "open"] ) = 0 [set filling? false set filled? true set color-changed? false]
  ]  
]
end 
  

to change-color
  if (filled? and not color-changed?) [
    let index 0
    while [ index <= ( length color-list - 2 )] [
      ask patches with [ptype = "water-fracking"] [
         set pcolor ( item (index + 1) color-list )
        ] 
      display
      wait 0.1
      set index index + 1
     ]
    set color-changed? true set fracking? true
  ]
end

to frack
  if fracking? [
  while [ count patches with [ptype = "water-fracking"] > 0 ] [
  ask patches with [ptype = "water-fracking"] [
     ask patches at-points [ [-1 0] [1 0] [0 1] [0 -1] ]
      [ if ((ptype = "shale") and (random-float 100 < shale-fractability * 1.05))
          [ set pcolor dirty-water  set ptype "water-fracking" set pcount pcount-index] 
      ]
      set ptype "water-fracked"
   ]
   set pcount-index pcount-index + 1
   tick
 ;  let number-fracked  count patches with [ptype = "fracked"]
 ;  let number-fracking  count patches with [ptype = "fracking"]
 ;  type "pcount-index = " type pcount-index type ", number fracked = " type number-fracked type ", number fracking = " print number-fracking
  ]
  while [ count patches with [ptype = "propane-fracking"] > 0 ] [
  ask patches with [ptype = "propane-fracking"] [
     ask patches at-points [ [-1 0] [1 0] [0 1] [0 -1] ]
      [ if ((ptype = "shale") and (random-float 100 < shale-fractability * 1.1))
          [ set pcolor clean-propane  set ptype "propane-fracking" set pcount pcount-index] 
      ]
      set ptype "propane-fracked"
   ]
   set pcount-index pcount-index + 1
   tick
 ;  let number-fracked  count patches with [ptype = "fracked"]
 ;  let number-fracking  count patches with [ptype = "fracking"]
 ;  type "pcount-index = " type pcount-index type ", number fracked = " type number-fracked type ", number fracking = " print number-fracking
  ]
  if (count patches with [ptype = "water-fracking" or ptype = "propane-fracking"] = 0 ) [set fracking? false] 
]
end

to pump-out-water
  set pumping-out? true set first-pump-out? true
end

to pump-out
  if pumping-out? [ if first-pump-out? [set first-pump-out? false] 
  if (not (pumped-out?) ) [
    let volume-of-dirty-water count patches with [pcolor = dirty-water]
    let bottom min-pycor
    let top air-depth
    let index 0
    while [(bottom + index) <= top] [
      ask patches with [(pycor >= bottom) and (pycor <= bottom + index) and (ptype = "water-fracked")]
        [set ptype "water-empty" set pcolor grey]
      ask patches with [(pycor >= bottom) and (pycor <= bottom + index) and (ptype = "propane-fracked")]
        [set ptype "propane-empty" set pcolor grey]
        set index index + 1
        tick
      ]
    create-cap
    set pumping-out? false
    set pumped-out? true
    set filled? false
  ]
 ]
end

to create-cap
  ask patches with [(pycor = air-depth - 1) and (ptype = "empty")] [
    ask patch-at 0 1 [set pcolor black] 
    ask patch-at 0 2 [set pcolor black] 
    ask patch-at 0 3 [set pcolor black] 
    ask patch-at 0 4 [set pcolor black] 
    ask patch-at -3 5 [set pcolor black] 
    ask patch-at -2 5 [set pcolor black] 
    ask patch-at -1 5 [set pcolor black] 
    ask patch-at 0 5 [set pcolor black] 
    ask patch-at 1 5 [set pcolor black] 
    ask patch-at 2 5 [set pcolor black]
    ask patch-at 3 5 [set pcolor black] 
    ask patch-at -3 6 [set pcolor black] 
    ask patch-at -2 6 [set pcolor black] 
    ask patch-at -1 6 [set pcolor black] 
    ask patch-at 0 6 [set pcolor black] 
    ask patch-at 1 6 [set pcolor black] 
    ask patch-at 2 6 [set pcolor black]
    ask patch-at 3 6 [set pcolor black] 
    
  ]
end

to move-turtles
  if (pumped-out?) [
   if product = 0 [ reset-ticks ]
   ask turtles [
     set moved? false ;they haven't moved on this tick
     set here-type [ ptype ] of patch-at 0 0
     set here-count [pcount] of patch-at 0 0
     
     set down-type [ ptype ] of patch-at 0 -1
     set up-type [ ptype ] of patch-at 0 1
     set left-type [ ptype ] of patch-at -1 0
     set right-type [ ptype ] of patch-at 1 0
     
     set up-right-type [ ptype ] of patch-at 1 1
     set down-right-type [ ptype ] of patch-at 1 -1
     set up-left-type [ ptype ] of patch-at -1 1
     set down-left-type [ ptype ] of patch-at -1 -1
     
     if (here-type = "water-empty" or here-type = "propane-empty") [
        show-turtle
           set down-count [pcount] of patch-at 0 -1
           set up-count [pcount] of patch-at 0 1
           set left-count [pcount] of patch-at -1 0
           set right-count [pcount] of patch-at 1 0
           
           set up-left-count [pcount] of patch-at 1 -1
           set up-right-count [pcount] of patch-at 1 1
           set down-left-count [pcount] of patch-at -1 -1
           set down-right-count [pcount] of patch-at 1 -1
           
           set min-count min (list down-count up-count left-count right-count up-left-count up-right-count down-left-count down-right-count )
           set moveable? (here-count > min-count)
           
         if (random 1000 < 3) [
           hatch 1 [
           setxy ( 2 + random (width - 4)) (2 + random (height - 4))
           while [ not (( [ ptype ] of patch-here = "water-empty" ) or ( [ ptype ] of patch-here = "propane-empty" ))] [ 
           setxy ( 2 + random (width - 4)) (2 + random (height - 4)) ]  
           ] 
         ]
           
        ifelse turtle-in-v-well? [ move-up ]
        [ifelse turtle-in-l-well? [move-right]
        [ifelse turtle-in-r-well? [move-left]
        [ 
        ifelse here-count > 0 [move-upstream] [random-move]
        ]]]
       if ycor >= air-depth - 1 [
         set product product + 1
         set product-list lput (round ticks / 100 ) product-list
         histogram product-list
         die
      ]
    ]
   ]
 ]
   tick
end
  
to move-upstream
  if (here-type = "water-empty" and not trapped?) or (here-type = "propane-empty") [ 
   ifelse (down-count < here-count) and (down-type = "water-empty" or down-type = "propane-empty") [move-down]
   [ifelse (up-count < here-count) and (up-type = "water-empty" or up-type = "propane-empty") [move-up]
   [ifelse (left-count < here-count) and (left-type = "water-empty" or left-type = "propane-empty") [move-left]
   [ifelse (right-count < here-count) and (right-type = "water-empty" or right-type = "propane-empty") [move-right] 
   
   [ifelse (down-right-count < here-count) and (down-right-type = "water-empty" or down-right-type = "propane-empty") [move-down-right]
   [ifelse (up-right-count < here-count) and (up-right-type = "water-empty" or up-right-type = "propane-empty") [move-up-right]
   [ifelse (down-left-count < here-count) and (down-left-type = "water-empty" or down-left-type = "propane-empty") [move-down-left]
   [ifelse (up-left-count < here-count) and (up-left-type = "water-empty" or up-left-type = "propane-empty") [move-up-left] 
   [random-move]]]]]]]]
  ]
end

to random-move 
  set color red        
  let random-index random 8
  if random-index = 0 [move-left] 
  if random-index = 1 [move-right]
  if random-index = 2 [move-up]
  if random-index = 3 [move-down]
  if random-index = 4 [move-down-left]
  if random-index = 5 [move-down-right]
  if random-index = 6 [move-up-right]
  if random-index = 7 [move-up-left]

end
  
  to-report turtle-in-v-well? ;called by an individual turtle
  if ( not empty? v-well-list ) [
  set v-well-list-index 0
  while [ v-well-list-index < length v-well-list ] 
    [
      set v-well-center item 0 item v-well-list-index v-well-list
      set v-drill-progress item 1 item v-well-list-index v-well-list
      let my-xcor [pxcor] of patch-here
      let my-ycor [pycor] of patch-here
      let well-left-side (v-well-center - well-width / 2) + 1
      let well-right-side (v-well-center + well-width / 2) - 1
      if ( my-xcor >= well-left-side and my-xcor <= well-right-side  and ( my-ycor >= min ( list v-drill-progress land-depth ) ) ) [
        report true 
      ]
      set v-well-list-index v-well-list-index + 1
    ]
  ]
    report false
end
  
  to-report turtle-in-l-well?
  ifelse ( empty? l-well-list ) [ report false ] [
  set l-well-list-index 0
  while [ l-well-list-index < length l-well-list ] 
  [
   set l-well-center item 0 item l-well-list-index l-well-list
   set l-drill-progress item 1 item l-well-list-index l-well-list
   set l-start-point item 2 item l-well-list-index l-well-list
   let well-left-end l-start-point - l-drill-progress - well-width / 2
   let well-right-end l-start-point - 1 + well-width / 2
      let my-xcor [pxcor] of patch-here
      let my-ycor [pycor] of patch-here
   if ( ( abs ( my-ycor - l-well-center ) <= ( well-width / 2 ) - 1 ) and ( my-xcor <= well-right-end ) and ( my-xcor >= well-left-end ) ) [
    report true 
    ]
   set l-well-list-index l-well-list-index + 1
  ]
   report false
  ]
    
  end
  
  to-report turtle-in-r-well? 
  ifelse ( empty? r-well-list ) [ report false ] [
  set r-well-list-index 0
  while [ r-well-list-index < length r-well-list ] 
  [
   set r-well-center item 0 item r-well-list-index r-well-list
   set r-drill-progress item 1 item r-well-list-index r-well-list
   set r-start-point item 2 item r-well-list-index r-well-list
   let well-right-end r-start-point + r-drill-progress
   let well-left-end r-start-point + 1 - well-width  / 2
      let my-xcor [pxcor] of patch-here
      let my-ycor [pycor] of patch-here
   if ( ( abs ( my-ycor - r-well-center ) <= ( well-width / 2) - 1) and ( my-xcor <= well-right-end ) and ( my-xcor >= well-left-end ) ) [
    report true 
    ]
   set r-well-list-index r-well-list-index + 1
  ]
   report false
  ]
    
  end

to move-sideways
  ifelse ( random 2 = 0 )
  [move-left move-right]
  [move-right move-left]
end

to move-left
  if left-type = "water-empty" or left-type = "propane-empty" [
   move-to patch-at -1 0
   set moved? true ]
end

to move-right
  if right-type = "water-empty" or right-type = "propane-empty" [
   move-to patch-at 1 0
   set moved? true ]
end

to move-up
  if up-type = "water-empty" or up-type = "propane-empty" [
   move-to patch-at 0 1
   set moved? true]
end

to move-down
  if down-type = "water-empty" or down-type = "propane-empty" [
   move-to patch-at 0 -1
   set moved? true]
end

to move-up-left
  if up-left-type = "water-empty" or up-left-type = "propane-empty" [
   move-to patch-at -1 1
   set moved? true]
end

to move-up-right
  if up-right-type = "water-empty" or up-right-type = "propane-empty" [
   move-to patch-at 1 1
   set moved? true]
end

to move-down-left
  if down-left-type = "water-empty" or down-left-type = "propane-empty" [
   move-to patch-at -1 -1
   set moved? true]
end

to move-down-right
  if down-right-type = "water-empty" or down-right-type = "propane-empty" [
   move-to patch-at 1 -1
   set moved? true]
end
    


; ---------------------- Procedures used for debugging -------------------------


to cheat ; used to see all the rock formations without doing any drilling
  ask patches [
              if (ptype = "water") [ set pcolor blue ]
              if (ptype = "rock") [ set pcolor brown ]
              if (ptype = "shale") [ set pcolor yellow ]
    ]
end

to try-move
  get-variables
  print-variables
   ifelse down-count < here-count [try-move-down]
   [ifelse up-count < here-count [try-move-up]
   [ifelse left-count < here-count [try-move-left]
   [ifelse right-count < here-count [try-move-right] 
   
   [ifelse up-left-count < here-count [try-move-up-left]
   [ifelse up-right-count < here-count [try-move-up-right]
   [ifelse down-left-count < here-count [try-move-down-left]
   [ifelse down-right-count < here-count [try-move-down-right]
   [random-move]]]]]]]]
end

to try-move-left
  type "trying to move left, moved? = " print moved?
  if ( not moved? ) [
     if ( left-type = "empty" ) [ ;if you can move left,
        move-to patch-at -1 0 ;do it.
        print "moved left"
        set moved? true
     ]
  ]
end

to try-move-down-left
  print "trying to move down left"
  if ( not moved? ) [
     if ( down-left-type = "empty" ) [ ;if you can move left and down,
        move-to patch-at -1 -1 ;do it.
        print "moved down left"
        set moved? true
     ]
  ]
end

to try-move-up-left
  print "trying to move up left"
  if ( not moved? ) [
     if (up-left-type = "empty" ) [ ;if you can move left and up,
        move-to patch-at -1 1 ;do it.
        print "moved up left"
        set moved? true
     ]
  ]
end

to try-move-right
  
  print "trying to move right"
  if ( not moved? ) [
     if ( right-type = "empty" ) [ ;if you can move right,
        move-to patch-at 1 0 ;do it.
        print "moved right"
        set moved? true
     ]
  ]
end

to try-move-down-right
  print "trying to move down right"
  if ( not moved? ) [
     if ( down-right-type = "empty" ) [ ;if you can move right and down
        move-to patch-at 1 -1 ;do it.
        print "moved down right"
        set moved? true
     ]
  ]
end

to try-move-up-right
  print "trying to move up right"
  if ( not moved? ) [
     if ( up-right-type = "empty" ) [ ;if you can move left and down,
        move-to patch-at 1 1 ;do it.
        print "moved up right"
        set moved? true
     ]
  ]
end

to try-move-up
  print "trying to move up"
  if ( not moved? ) [ ;if you can move up,
     if up-type = "empty"
     [ move-to patch-at 0 1 ;do it.
        print "moved upo"
     set moved? true ]
]
end

to try-move-down
  print "trying to move down"
  if ( not moved? ) [
     if ( down-type = "empty" ) ;if you can move down,
     [ move-to patch-at 0 -1 ;do it.
        print "moved down"
     set moved? true ]
]
end
  
to look-around
  ask turtles with [mouse-on-turtle?] [
    get-variables
    print-variables
  ]
  end
   
   to get-variables
     set here-type [ ptype ] of patch-at 0 0
     
     set down-type [ ptype ] of patch-at 0 -1
     set up-type [ ptype ] of patch-at 0 1
     set left-type [ ptype ] of patch-at -1 0
     set right-type [ ptype ] of patch-at 1 0
     
     set up-right-type [ ptype ] of patch-at 1 1
     set down-right-type [ ptype ] of patch-at 1 -1
     set up-left-type [ ptype ] of patch-at -1 1
     set down-left-type [ ptype ] of patch-at -1 -1
     
     set here-count [pcount] of patch-at 0 0
     
     set down-count [pcount] of patch-at 0 -1
     set up-count [pcount] of patch-at 0 1
     set left-count [pcount] of patch-at -1 0
     set right-count [pcount] of patch-at 1 0
     
     set up-left-count [pcount] of patch-at 1 -1
     set up-right-count [pcount] of patch-at 1 1
     set down-left-count [pcount] of patch-at -1 -1
     set down-right-count [pcount] of patch-at 1 -1
     
    
           set min-count min (list down-count up-count left-count right-count up-left-count up-right-count down-left-count down-right-count )
           set moveable? (here-count > min-count)
   end
   
   to print-variables
           
     type "turtle ID = " type who type ", moved? = " print moved?
     
     type up-left-type type " - " type up-left-count type "     " type up-type type " - " type up-count type "     " type up-right-type type " - " print up-right-count
     type left-type type " - " type left-count type "     " type here-type type " - " type here-count type "     " type right-type type " - " print right-count
     type down-left-type type " - " type down-left-count type "     " type down-type type " - " type down-count type "     " type down-right-type type " - " print down-right-count

  
end
  
  to-report mouse-on-turtle?
    ifelse ( (abs (xcor - mouse-xcor) + abs (ycor - mouse-ycor)) < 2 ) [report true] [report false]
  end  
@#$#@#$#@
GRAPHICS-WINDOW
220
25
1032
502
-1
-1
2.0
1
10
1
1
1
0
0
0
1
0
400
0
222
1
1
1
ticks
30.0

BUTTON
42
42
112
75
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
117
42
184
75
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
8
216
90
249
fill with water
fill-with-water
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
36
266
213
299
pump out fracking fluid
pump-out-water
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
46
173
188
206
set off explosions
set-off-explosions
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
105
218
210
251
fill with propane
fill-with-propane
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
9
325
209
475
Gas production
year
production
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "set-plot-pen-mode 1"

@#$#@#$#@
## WHAT IS IT?

This model shows how an oil spill can percolate down through permeable soil.  It was inspired by a similar model meant to be done by hand on paper (see "Forest Fires, Oil Spills, and Fractal Geometry", Mathematics Teacher, Nov. 1998, p. 684-5).

## HOW IT WORKS

The soil is modeled as a checkerboard of hard particles (gray squares) and semi-permeable spaces in between these hard particles (brown squares).  (You may need to zoom in to see the individual squares.)

Oil cannot enter the solid gray squares, but it may pass through the brown squares.

Some soils are more porous ("holey") than other soils.  In this model the porosity value of the soil determines the probability that the oil will be able to enter any given brown soil square.

The model represents an oil spill as a finite number of oil "particles", or simply oil drops.

The oil spill starts at the top of the view, and percolates downward.

The leading edge of the oil spill is represented by red squares, and every square that oil has passed through (or "saturated") is shown as black.

The oil drops sink downward through the soil by moving diagonally to the right or left, slipping between the hard gray particles.

## HOW TO USE IT

Push the SETUP button to place the soil and start the oil spill (shown as red) at the top of the view.

Press the GO button to run the model.

The POROSITY slider controls the percent chance that oil will be able to enter each brown square, as it works its way downward.

The model can be run as long as you like; if the spill reaches the bottom of the view, the bottom row of squares is moved to the top, and the model continues to run from where it left off, starting at the top of the view.
(Think of this as a camera panning downward, as necessary, to show the deeper percolation.)

The two plots show how large the leading edge of the spill is (red) and how much soil has been saturated (black).

## THINGS TO NOTICE

Try different settings for the porosity.  What do you notice about the pattern of affected soil?  Can you find a setting where the oil just keeps sinking, and a setting where it just stops?

If percolation stops at a certain porosity, it's still possible that it would percolate further at that porosity given a wider view.

Note the plot of the size of the leading edge of oil.  Does the value settle down roughly to a constant?  How does this value depend on the porosity?

## EXTENDING THE MODEL

Give the soil different porosity at different depths.  How does it affect the flow?  In a real situation, if you took soil samples, Could you reliably predict how deep an oil spill would go or be likely to go?

Currently, the model is set so that the user has no control over how much oil will spill.  Try adding a feature that will allow the user to specify precisely, when s/he presses SETUP, the amount of oil that will spill on that go.  For instance, a slider may be useful here, but you'd have to modify the code to accommodate this new slider.  Such control over the to-be-spilled amount of oil gives the user a basis to predict how deep the oil will eventually percolate (i.e. how many empty spaces it will fill up).  But then again, the depth of the spill is related to the soil's porosity.  Can you predict the depth of the spill before you press GO?

## NETLOGO FEATURES

This is a good example of a cellular automaton, because it uses only patches.  It also uses a simple random-number generator to give a probability, which in turn determines the average large-scale behavior.

This is also a simple example of how plots can be used to reveal, graphically, the average behavior of a model as it unfolds.

In the pen-and-paper activity the soil was represented by rectangles arranged in a brickwork pattern, where each rectangular cell had two neighboring rectangular cells below it.  Since NetLogo's patches are always squares in an aligned grid, our replica of the model uses a checkerboard pattern instead.  Can you see how the two models would have the same behavior, despite having different ways of visualizing them?

## RELATED MODELS

"Fire" is a similar model.  In both cases, there is a rather sharp cutoff between halting and spreading forever.

This model qualifies as a "stochastic" or "probabilistic" one-dimension cellular automaton.  For more information, see the "CA Stochastic" model.


## HOW TO CITE

If you mention this model in a publication, we ask that you include these citations for the model itself and for the NetLogo software:  
- Wilensky, U. (1998).  NetLogo Percolation model.  http://ccl.northwestern.edu/netlogo/models/Percolation.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.  
- Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.  

## COPYRIGHT AND LICENSE

Copyright 1998 Uri Wilensky.

![CC BY-NC-SA 3.0](http://i.creativecommons.org/l/by-nc-sa/3.0/88x31.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2001.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.1
@#$#@#$#@
setup
repeat world-height - 1 [ go ]
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
