
; Land Management Test Program  V.4
; Nathan Kimball

;LM-Test9: add in more elaborate management plans (make use of the plan-data object)
;LM-Test8: transition to more elaborate land management
;LM-Test7: introduce erosion that loses soil off the edges

;In this profile view, patches are either soil layers or sky.  Soils have a bunch of properties that need thier own variables:
;patches own variable is-soil? set true if patches pcolor != skycolor.  This just to eliminate tests using color, to provide more flexibility with color in the future.
;patches own variable depth, if set, is the number of patches down from the sky.  sky depth is -1; top surface = 0, second layer = 1, etc
;patches own variable erode-direction is initially 0 for all patches. If a a patch has started to erode it is set to
;  either -1 if it moved left or +1 if it moved right. Then, the next time it moves it tries to go in the same direction.
;  This is to eliminate the "jitter" of particales moving randomly until they go down in the erosion algorithm.
;patches own variable zone-num is 1 if pxcor is on left or 2 if on right of center
;patches own variable eroded? is true if the patch of soil has "moved" from its original position. This, in combination with zone-num makes 
;  it possible to turn the color of eroded patches on and off on user command. 
;patches own variable topsoil? is boolean set upon "setup" to define the initial conditions of the top patches (right now depth <= 6) before the effects of erosion.
;  This variable should be useful in defining the soil carbon 
patches-own [ is-soil? depth erode-direction eroded? zone-num topsoil? Carbon Nitrogen Water ]

;Plants, trees, and roots have a state variable that determines several stages of growing, dying, and decaying.  States are:
;  0=lag-phase 1=expodential-phase 2=steady-phase 3=death-phase (sencesence) 4=decay
;  in crop plants, state 3 is harvest, and 4 may be decay if residue is left on field or very short if residue is cleared
;Each state or phase has a duration in days and a rate that affects the size of the plant, so it's in units of 
; (change of size) / day.  The rate may also affect the ycor value so that plants stay aligned with the soil surface as the size changes.

;plant-data is simply a data structure for holding static information about various breeds of plants.  It uses the <turtles-own> variables.  
;  It is always hidden and accessed via a global variable defined in setup.  It provides a way to have named variables instead of everything in a list.
breed [plant-data plant-datum]
plant-data-own [ name annual? in-rows? p-shapes p-colors r-shapes r-colors germinate-period p-initial-size p-durations p-rates r-initial-size r-durations r-rates winters-over? withers? card-temps ]

;plan-data: plan-name=string for name; actions=list of strings of names of actions; actions-days=parallel list to actions that have the day number for the action to occur;
;  action-cost=another parallel list to actions that 
breed [plan-data plan-datum]
plan-data-own [ plan-name actions action-days action-cost num-of-plantings end-states ]

;climate-data is a data structure for holding static information about climate.  It uses the <turtles-own> variables.
;  temperature data is in Celcius and precipation is in millimeters. Both are presented in lists with an entry for each month starting in January.
breed [climate-data climate-datum ]
climate-data-own [ name monthly-temps monthly-precip ]

;every plant is made up of two turtles, one is a plant and the other a root.  They start off together, but may have different endings because plants
;  and roots may end up a fodder or "residue" on fields, and so may decay slowly.
;plants own variables: name=concatination of plant type and day number planted; state=growing state (0 thru 4); rate set rate for that state;
;  day-ct = days since planted; annual? = comes up every year? ; germinate-day = day of year that it is planted; start-x and start-y = initial position
;  p-initial-size = size of NetLogo shape for that plant; p-durations: list of durations for each state; p-rates = list of rates of growth for each state
;  end-state determins what happens to a plant when state=3. 0=normal decay, 1=intensive tillage, 2=conservation tillage, 3=knock down.
breed [plants plant]
plants-own [name state end-state duration rate day-ct annual? in-rows? germinate-day start-x start-y p-initial-size p-durations p-rates p-object is-wintering-over? root-num ]

;root own variables: basically same as plants own variables...
breed [roots root]
roots-own [name state duration rate day-ct annual? germinate-day r-initial-size r-durations r-rates plant-num]

globals [
  amplitude      ;just used for determining the wavyness of the sin wave contour of the landscape
  skycolor       ;a bunch of constants to eliminate magic numbers in the code.  These are set in the setup routine.
  soilcolor
  rainbow-colors
  tree-colors
  root-colors
  wheat-colors
  grass-colors
  wither-colors
  dead-colors
  soil-color-options
  topsoil-color
  soil-carbon-colors
  soil-nitrogen-colors
  soil-water-colors
  color-layers?
  start-run-for-set-interval?
  management-plan-for-year
;;time variables:
  year
  ;start-year   ;presently an interface variable
  month
  months
  month-str
  day
  day-of-year
  max-slope
  germinate-day-lists
;  germinate-day-list-zone-1
;  germinate-day-list-zone-2
  surface-set
  zone1-erode-ct
  zone2-erode-ct
  plants-per-zone      ;for crops, the number of seeds planted at one time in one zone
  zone-plant-count     ;when setting crops that are in rows (not random), it keeps track on planting. 2 x 2 array, one array for each zone, first element total number of plants, second element which one we are on 
  stop-at-year
  last-run-for-setting
  year-duration
  month-duration
  climate-obj
  ave-month-temperature
  ave-month-precip
  default-topsoil-depth
  Plant-Type
  Td            ;tree data
  Wd            ;wheat data
  Wwd           ;winter wheat data
  Sd            ;soy data
  Gd            ;grass data
  zone-plans
  zone1-plan
  zone2-plan
]

to setup
  ca
  set skycolor sky
  set soilcolor brown
  set-terrain
  set rainbow-colors [ 15 25 35 45 55 65 75 85 95 105 115 125 135 ] ;used for checking that the depth algorithm works
  set tree-colors [53 54 55 56 57 62 63 64 65 66 67 73 74 75 76 77] ;forest colors
  set wheat-colors [46 47 48 26 27 28]
  set root-colors [32 33 34 35 36]
  set grass-colors [ 54 55 56 65 65 66 ]
  set wither-colors [7 8 37 38 47 48 ]
  set dead-colors [1 2 3 4 5 6 7 8 9]
  set topsoil-color soilcolor - 2
;  set soil-carbon-colors 
;  set soil-nitrogen-colors
;  set soil-water-colors
  set months ["Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec" ]
  set day 0
  set day-of-year 0
  set month 0  
  set year start-year      ;start-year is set on interface
  set year-duration 360    ;define 360 days per year
  set month-duration 30    ;define 30 days per monty 
  set max-slope 2
  set default-topsoil-depth 5
  set Td tree-data-object  ;holds growth data for trees
  set Wd wheat-data-object ;holds growth data for wheat
  set Wwd winter-wheat-data-object
  set Sd soy-data-object   ;holds growth data for soy
  set Gd grass-data-object ;grass growth data
  set zone1-plan plan-data-object
  set zone2-plan plan-data-object
  set zone-plans list zone1-plan zone2-plan 
  set germinate-day-lists [ [] [] ]
;  set germinate-day-list-zone-1 []
;  set germinate-day-list-zone-2 []
;  set soil-color-options (list "Topsoil" "Erosion"  "Soil Quality" "Nitrogen" "Water")
  set zone1-erode-ct 0
  set zone2-erode-ct 0
  set plants-per-zone 20
  set zone-plant-count [[][]] ;for zones that grow crops (as opposed to forests or grass), this allows crops to be planted in "rows". This contains two, two-element lists. For each zone, first element = total number of crop sprouts, Second element = the number that have been defined in this "pass".
  if climate = "Humid Continental" [set climate-obj temperate-climate-data-object ]
  if climate = "Tropical Rainforest" [ set climate-obj tropical-climate-data-object ]
  if climate = "Semi-Arid" [ set climate-obj semi-arid-climate-data-object ]
  
  ask patches [
    set zone-num ifelse-value (pxcor <= 0) [1][2]
    ifelse ( pycor > terrain-function pxcor ) 
    [
      set pcolor skycolor
      set is-soil? false
      set depth -1
    ]
    [
      set pcolor soilcolor
      set is-soil? true
      set depth 0
    ]
    set erode-direction 0
    set eroded? false
    set topsoil? false
  ]
  set-soil-depth-iterative
  set color-layers? false
  ask patches [if depth >= 0 and depth <= default-topsoil-depth [ set topsoil? true set Water 50] ] ;mark topsoil
  set-soil-color-indicators
  set start-run-for-set-interval? true
  ;set surface-set soil-surface-list
  reset-ticks
end 


to go
  every year-speed * 0.05 
  [
    set-monthly-climate-data
    set-annual-land-management-plan  
    manage-the-land
    grow-all plants 
;    set-soil-depth
;    infiltrate-precipitation ave-month-precip
;    percolation
;    set-soil-color-indicators
    erode ave-month-precip
    set-soil-depth
    infiltrate-precipitation ave-month-precip
    percolation
    set-soil-color-indicators
    ;ifelse show-eroded? [ask patches [ if (eroded?) [set pcolor ifelse-value (zone-num = 1) [magenta][orange]]]][ask patches [if pcolor != skycolor [set pcolor soilcolor]]]
    advance-time
    if not set-and-check-stop-time? [ stop ]  
    tick
  ]
end

;"Topsoil"
;"Erosion"
;"Soil Quality"
;"Nitrogen"
;"Water"

to set-soil-color-indicators
  let setcolor 0
  if Soil-Color-Shows = "Topsoil"  [ ask patches [ if (is-soil?) [ ifelse (topsoil?) [set pcolor topsoil-color][set pcolor soilcolor] ] ] ]
  if Soil-Color-Shows = "Erosion"  [ ask patches [ if (is-soil?) [ ifelse (eroded?) [set pcolor ifelse-value (zone-num = 1) [magenta][orange]] 
                                                                                    [ifelse (topsoil? and not eroded?) [set pcolor topsoil-color][ set pcolor soilcolor]]]                                                               
                                                 ]
                                   ]
  if Soil-Color-Shows = "Soil Quality" [ ask patches [ if (topsoil? or eroded?)  [set pcolor indicator-color gray Carbon-Test set setcolor pcolor ] ]] ;including "or eroded?" in the logic, colors eroded subsoil. THis might not be technically correct, but it makes it look better 
  if Soil-Color-Shows = "Nitrogen" [ ask patches [ if (topsoil? or eroded?) [ set pcolor indicator-color green Nitrogen-Test ] ] ] 
  ;if Soil-Color-Shows = "Water" [ ask patches [ if (topsoil? or eroded?)   [ set pcolor indicator-color violet Water ] ] ] 
  if Soil-Color-Shows = "Water" [ ask patches [ if (is-soil? and depth >= 0 and depth <= 6)  [ set pcolor indicator-color violet Water ] ] ] 
;  show (word "indicator: " setcolor)
end

to-report indicator-color [ base-color indicator-value ]
  let dark-color base-color - 2.5
  let light-color base-color + 2
  let width abs(dark-color - light-color)
  let scaled 1 - (indicator-value / 100)
  let offset dark-color + (scaled * width)
  let r round (offset * 2)                 ;make color numbers in increments of 0.5
  report r / 2
end


to set-monthly-climate-data
  ifelse use-slider-climate-values?
  [
    set ave-month-temperature ave-temp-per-month
    set ave-month-precip ave-precip-per-month
  ]
  [
    ask climate-obj 
    [
      set ave-month-temperature item month monthly-temps
      set ave-month-precip  item month monthly-precip
    ]
  ]
end

;sets the "depth" patch variable, sky is -1 during initalization (and in erosion as needed), this function keeps setting 
;top layer 0, 2nd layer 1, etc.
;  this function uses a emergent algorithm, so to set the depth of the whole soil thickness this needs to be run many times. Alternatively,
;  it can just be kept in the "go" loop to maintain the depth settings in the patch variables as they erode. 
to set-soil-depth   ;an algorithm where the patch depth of the soil "trickles down" from the sky by looking at the depth of the patch above
  ask patches with [pycor < max-pycor] [
    if (is-soil?) 
      [ let depth-above [depth] of patch-at 0 1
        
        if (depth-above != depth - 1)
        [
          set depth depth-above + 1
        ]
      ]
  ]
;  ifelse color-layers? and day mod 10 = 0
;  [
;    ask patches [if depth >= 0 [set pcolor 16 + (depth * 10)]]   ;this line sets the pcolors to a rainbow effect to check the algorithm
;  ]
;  [
;    ask patches [if depth >= 0 and not show-eroded? [set pcolor soilcolor]]
;  ]
end

to set-soil-depth-iterative ;sets the "depth" patch variable using an interative, patch counting algorithm. 
                            ;This is more efficient for setting all patches than the above function.
  let i min-pxcor
  
  while [i <= max-pxcor ]
  [
    let found-depth 0
    let j max-pycor
    while [ j >= min-pycor ]
    [
      ask patch i j [
        ifelse not is-soil?
        [
          set depth -1
        ]
        [
          set depth found-depth
          set found-depth found-depth + 1
        ]
        set j j - 1
      ]
    ]
    set i i + 1
  ]
end

to erode [precip] ;erosion is a function of monthly preciptation,and other (global) factors: the slope of the terrain and the vegetation
  
                  ;If a soil patch is exposed to skycolor, we look around it to see if there are other skycolor patches below or below and to one side or the other.    
                  ;  If not, we look at either side at the same pycor to see if it can move.
                  ;  If a patch moves, it "remembers" which direction it moved by setting patch variable erode-direction, -1 to the left, +1 to the right.  Then next time, it will continue to move
                  ;  in that direction, diagonally down if possible or horizontally, unless it can't move further.  If it can't move further, it reverses direction by changing the sign of erode-direction.
                  ;  It will stop moving when there are no skycolor neighobors below it or to either side.
  
                  ;start with "exposed" surface patches, that is, those who touch the skycolor with at least 3 neighbors 
 ;let erosion-set patches with [ (is-soil?) and ((count neighbors with [ not is-soil? ]) >= 3) or (((count neighbors with [ not is-soil? ]) = 1) and ((pxcor = min-pxcor) or (pxcor = max-pxcor)))] 
 ; let sky-neighbor-ct count patches with [ neighbors != is-soil? ]
  let eroders patches with [ (is-soil?) and ((count neighbors with [ not is-soil? ]) >= 4) or (is-soil? and ((count neighbors with [ not is-soil? ]) >= 2) and ((pxcor = min-pxcor) or (pxcor = max-pxcor)))]    
; ; let erosion-set patches with [ is-soil? and (count (neighbors with [ is-soil? ]) >= 1) and (count neighbors with [ not is-soil? ]) >= 3]
;  ;order the surface patches so that the ones with the greatest number of skycolor neigbors are at the front of the list. These are the most "exposed"
;  let surface-list sort-on [ (- count neighbors with [ not is-soil? ] ) ] erosion-set
;  let len length surface-list
;  ;then, only consider the patches in the first 1/4 of the list.  This can easily be increased or decreased.
;  let fraction-len round len / 4
;  ;create a sublist of "erosion candidates"
;  let erosion-candidates sublist surface-list 0 len ; not using fraction-len right now, use the whole list
;  
;  let c length erosion-candidates 
;  
;  let eroders  patch-set n-of c erosion-candidates
  ;show (word "original eroder: " eroders)
  if eroders != nobody
  [
    ask eroders [  
      let rand-x 0                ;is set to the relative x offset from the patch in question
      let tester-list []          ;this keeps a prioritized list of potential places for an erodable patch to move
      ifelse erode-direction = 0  ;logic here could be simplified, but maybe it's clearer as it is
      [                              ;if the patch has never been eroded...
        ifelse (pxcor = min-pxcor)   ;  check left and right boundaries 
        [
          set rand-x 1  ;can only move to the right
          set tester-list (list (patch-at 0 -1) (patch-at rand-x -1) (patch-at rand-x 0))
        ]
        [
          ifelse (pxcor = max-pxcor)
          [
            set rand-x -1  ;can only move to the left
            set tester-list (list (patch-at 0 -1) (patch-at rand-x -1) (patch-at rand-x 0))
          ]
          [
            set rand-x one-of [ -1 1 ]           ;if not on the boundary choose a direction to go randomly
            set tester-list (list (patch-at 0 -1) (patch-at rand-x -1) (patch-at (-1 * rand-x) -1) (patch-at rand-x 0) patch-at (-1 * rand-x) 0) 
          ]
        ]
      ]
      [ ;else if erode-direction has been set to either 1 or -1
        ifelse (pxcor = min-pxcor) 
        [
          set rand-x 1  ;has to move to the right
          set tester-list (list (patch-at 0 -1) (patch-at rand-x -1) (patch-at rand-x 0))
        ]
        [
          ifelse (pxcor = max-pxcor)
          [
            set rand-x -1
            set tester-list (list (patch-at 0 -1) (patch-at rand-x -1) (patch-at rand-x 0))
          ]
          [
            set rand-x erode-direction
            set tester-list (list (patch-at 0 -1) (patch-at rand-x -1) (patch-at (-1 * rand-x) -1) (patch-at rand-x 0) patch-at (-1 * rand-x) 0) 
          ]
        ]
      ]
      ;will test for sky at: patch below, then patch below and beside on either side, then patch on either side
      let i 0
      let num length tester-list
      ;show (word "length tester-list: " num)
      while [i < num]
      [
        let one item i tester-list
        ifelse one != nobody
        [
          ask one
          [
            ifelse ([not is-soil?] of one) ;if we have hit sky
            [
              ;calculate the effect of the plants in the vicinity on erosion:
              let radius 5  ;not actually looking at a circular radius, just a delta, plus and minus
              let lbound ifelse-value ((pxcor - radius) > min-pxcor) [pxcor - radius][min-pxcor]
              let rbound ifelse-value ((pxcor + radius) < max-pxcor) [pxcor + radius][max-pxcor] 
              let close-ones roots with [ xcor >= lbound and xcor <= rbound ]                 ;check for roots in the vicinity
              let close-ones-list sort-on [( - distance myself)] close-ones 
              let num-close count close-ones
              let  vegetation-contribution 0  ;if there are no plants or roots
              if (num-close > 0) 
                [
                  set vegetation-contribution num-close * (mean [size] of close-ones) / (4 * radius) ;factoring in the number of close ones and their size divided by a packing of 1 plant per 2 patches and a presumed average size
                  if vegetation-contribution > 0.99 
                  [
                    set vegetation-contribution 0.99  ;there will always be a 1% chance of erosion
                  ]
                ] 
              ;calculate the effects of the terrain's slope on erosion:
              let local-slope soil-surface-slope ([pxcor] of myself) ([pycor] of myself)
              let slope-contribution abs(local-slope / max-slope)  ;if slope is non-zero, it always will contribute to erosion, so take absolute value
              let erosion-calculated erosion-probability * (precip / 400) * ((0.25 * slope-contribution) + (0.75 * (1 - vegetation-contribution)))
              if show-erosion-data?
                [show (word "veg-cont: " precision vegetation-contribution 3 " ct: " num-close " slope-cont: " precision slope-contribution 3 " erosion-calc " round erosion-calculated )]
              if (random 100 < erosion-calculated) ;(num-close = 0) and
              [
                let save-zone 0             ;create a variable to save the zone number of the patch so it can be assigned to the new position
                let save-topsoil? false     ;similarlly for all patch variables
                let save-is-soil? false
                let save-pcolor 0
                let save-Carbon 0
                let save-Nitrogen 0
                let save-Water 0
                let save-erode-direction 0
                let save-pxcor 0
                ask myself [                ; in this case, myself is the present "eroder" from the erosion candidate set
                  set save-zone zone-num    ;put patch variables in temperary locations
                  set save-pcolor pcolor
                  set save-pxcor pxcor
                  set save-is-soil? is-soil?
                  set save-topsoil? topsoil?
                  set save-Carbon Carbon
                  set save-Nitrogen Nitrogen
                  set save-Water Water
                  set save-erode-direction erode-direction
                  set pcolor skycolor       ;set new-sky-patches (patch-set new-sky-patches myself)
                  set erode-direction 0     ;reset erode-direction because patch is now sky
                  set eroded? false
                  set is-soil? false
                  set topsoil? false
                ]
                ifelse (save-pxcor = min-pxcor and save-erode-direction = -1) or (save-pxcor = max-pxcor and save-erode-direction = 1)
                [
                  ask one [
                    set zone-num 0
                    set topsoil? false
                    set is-soil? false
                    set pcolor skycolor
                    set Carbon 0
                    set Nitrogen 0
                    set Water 0
                    set erode-direction 0
                  ]
                ]
                [
                ask one [
                  set zone-num save-zone
                  set topsoil? save-topsoil?
                  set is-soil? save-is-soil?
                  set pcolor save-pcolor
                  set Carbon save-Carbon
                  set Nitrogen save-Nitrogen
                  set Water save-Water       
                  set rand-x ifelse-value (pxcor < save-pxcor) [-1][1]
;                  if (pxcor = min-pxcor) or (pxcor = max-pxcor)
;                  [
;                    ifelse pxcor = min-pxcor 
;                    [
;                      set rand-x 1
;                    ]
;                    [ 
;                      if pxcor = max-pxcor
;                      [
;                        set rand-x -1
;                      ]        
;                    ]
;                  ]
;                  if [pcolor] of (patch-at rand-x 0) != skycolor    ;if moved soil bumps into other soil, then reverse direction
;                    [set rand-x (-1 * rand-x)] 
                  set erode-direction rand-x ; set direction that the patch moved
                  set eroded? true     
                ]
                ] ;else of if (pxcor = min-pxcor) or (pxcor = max-pxcor)
                ifelse pxcor < 0 [set zone1-erode-ct zone1-erode-ct + 1][set zone2-erode-ct zone2-erode-ct + 1]
              ]
              
              set i 1000                 ;break the while loop
            ]
            [ 
              set i i + 1
            ]
          ]
        ]
        [
          set i 1000
        ]
      ]
    ] ;close "ask eroders"
  ]
end

to infiltrate-precipitation [ precip ]  ;precip = monthly precip
  if (day mod 10 = 0) ; there are 3 storms per month on the 1st, 10th, and 20th of the month
  [
   ; set surface-set patches with [is-soil? and (count neighbors with [not is-soil?] >= 1)]
    set surface-set patches with [depth = 0]
    let c count surface-set
    let factor 0.5
    let water-amount (precip / (3 * c))  ;three rain storms per month water
    
    ask surface-set 
    [
      let s soil-surface-slope pxcor pycor
      let runoff water-amount * factor * (abs(s) / max-slope)
      ;show (word "slope: " s)
      let infiltrate water-amount - runoff
      ;set pcolor red
      set Water Water + infiltrate
    ]
  ]
end



to percolation ;acccount for water moving due to gravity and matric forces (capillary)
  ask patches with [is-soil? and depth < default-topsoil-depth]
  [
;    if water > 65 
;    [
      let water-available water * .17
        set water water - water-available
        if pycor > min-pycor
        [
          ask patch-at 0 -1 [set water water + water-available ]
        ]
;    ]
  ]
end


to evaporate [ temperature ]
  
end


;to-report surface-patches
;  let elegible-patches patches with [pycor > min-pycor and pycor < max-pycor]  
;  report elegible-patches with [[pcolor] of patch-at 0 1 = skycolor and [pcolor] of patch-at 0 -1 != skycolor]
;end

;;data from: http://www.weatherbase.com/weather/weather.php3?s=502031&cityname=Ames--Iowa-State-University-Iowa-United-States-of-America&units=metric
;;Temperate Temperature Climate data is average monthly temperature data for Ames, Iowa
;[ -7.1  -4.8  1.9  9.6  15.8  20.9  23.6  22.3  17.8  11.4  2.8  -4.2 ]
;;Temperate Rainfall Climate data is average montly rainfally for Ames, Iowa in mm
;[ 22  26  43  73  108  115  89  93  95  58  36  27 ]

to-report temperate-climate-data-object
  let cli no-turtles
  create-climate-data 1
  [
    set hidden? true
    set name "Temperate Climate"
    set monthly-temps [ -7.1  -4.8  1.9  9.6  15.8  20.9  23.6  22.3  17.8  11.4  2.8  -4.2 ]
    set monthly-precip [ 22  26  43  73  108  115  89  93  95  58  36  27 ]
    set cli self
  ]
  report cli
end

;;data from: http://www.weatherbase.com/weather/weather.php3?s=44228&cityname=Santarem-Paraiba-Brazil&units=metric
;;Tropical Temmpeature Climate data-average montly temperature data from Santarem, Brazil in C
;[27  27  27  27  27  27  27  28  28  28  28  28 ]
;;Tropical Rainfall Climate data for Santarem, Brazil in mm
;[ 200  290  380  360  280  120  80  40  30  30  70  100 ]

to-report tropical-climate-data-object
  let cli no-turtles
  create-climate-data 1
  [
    set hidden? true
    set name "Tropical Climate"
    set monthly-temps [ 27  27  27  27  27  27  27  28  28  28  28  28]
    set monthly-precip [ 200  290  380  360  280  120  80  40  30  30  70  100 ]
    set cli self
  ]
  report cli
end

;;data from: http://www.weatherbase.com/weather/weather.php3?s=590710&cityname=Bhatinda-Punjab-India&units=metric
;;Semi-Arid climate: monthly average temperature, Punjab: Bhatinda, India or now offically spelled Bathinda
;; see for more info: http://en.wikipedia.org/wiki/Bathinda
;[12.6  15.3  20.4  27.2  31.4  34.1  31.6  30.4  29  25.2  18.9  14]
;;rainfall:
;[11.4  13.2  23.5  8.8  14.8  34.1  133.1  120.2  47  7.8  7.7  6.8]

to-report semi-arid-climate-data-object
  let cli no-turtles
  create-climate-data 1
  [
    set hidden? true
    set name "Semi-Arid Climate"
    set monthly-temps [12.6  15.3  20.4  27.2  31.4  34.1  31.6  30.4  29  25.2  18.9  14]
    set monthly-precip [11.4  13.2  23.5  8.8  14.8  34.1  133.1  120.2  47  7.8  7.7  6.8]
    set cli self
  ]
  report cli
end

to-report tree-data-object ;creates a hidden turtle of breed plant-data that holds the growth data 
  let t no-turtles
  create-plant-data 1      ;  for a tree in its turtle variables. This turtle is assinged to global varible Td (tree data).
  [
    set hidden? true
    set name "tree"
    set annual? false      ;if annual? = true total duration of plant life will be under year-duration (360 days), and will come up every year
    set in-rows? false
    set p-shapes [ "tree" "tree pine" ] 
    set p-colors [53 54 55 56 57 62 63 64 65 66 67 73 74 75 76 77]
    set r-shapes [ "plant 2" ]
    set r-colors [32 33 34 35 36]
    set germinate-period [ 90 240 ]   ; day numbers that tree can germinate between, if any day of the year list will be [0 360]
    set p-initial-size 4
    set p-durations  [ 21 720 1440 400 360 ] 
    set p-rates [ 0.0015 0.002 0.0003 -0.004 -0.002 ] 
    set r-initial-size 3
    set r-durations p-durations
    set r-rates [ 0.0015 0.0015 0.0003 -0.004 -0.002 ]
    set winters-over? true
    set withers? false
    set card-temps [ 5 15 35 ]
    set t self
  ]
  report t
end       

to-report tree-data-randomizer [ tree-data ]
  let tdr no-turtles
  create-plant-data 1 
  [
    set hidden? true
    set name "randomized tree"
    set germinate-period [germinate-period] of tree-data
    set annual? [annual?] of tree-data
    set p-initial-size [p-initial-size] of tree-data
    let T1 round random-normal 3 2
    let T2 round random-normal 100 50
    let T3 round random-normal 200 100
    let T4 round random-normal 80 40
    let T5 round random-normal 50 25
    set p-durations (list T1 T2 T3 T4 T5 ) ;list of randomized deltas to be applied to tree-data
    set p-rates [p-rates] of tree-data
    set r-initial-size [r-initial-size] of tree-data
    set r-durations p-durations
    set r-rates [r-rates] of tree-data
    set tdr self
  ]
  report tdr
end

to-report wheat-data-object ;creates a hidden turtle of breed plant-data that holds the growth data 
  let obj no-turtles
  create-plant-data 1      ;  for wheat in its turtle variables. This turtle is assinged to global varible Wd.
  [
    set hidden? true
    set name "wheat"
    set annual? true
    set in-rows? true
    set p-shapes [ "plant wheat" "plant wheat right" ] ;plant shapes
    set p-colors [46 47 48 26 27 28]
    set r-shapes [ "plant 3" ]                         ;root shape
    set r-colors [32 33 34 35 36]
    set p-initial-size 2
    set germinate-period [90 95]
    set p-durations  [ 35 70 35 35 30 ]                 ;more realistic for trees: (list 60 3600 3600 360 720) 
    set p-rates (list 0.005 0.02 0.0001 -0.04 -0.02)     ;
    set r-initial-size 2
    set r-durations p-durations
    set r-rates (list 0.005 0.02 0.0001 -0.04 -0.02)
    set winters-over? true 
    set withers? true
    set card-temps [ 5 20 30 ]    
    set obj self
  ]
  report obj
end    

to-report wheat-data-randomizer [ wheat-data ]
  let wdr no-turtles
  create-plant-data 1 
  [
    set hidden? true
    set name "randomized wheat"
    set germinate-period [germinate-period] of wheat-data
    set annual? [annual?] of wheat-data
    set p-initial-size [p-initial-size] of wheat-data
    let T1 round random-normal 3 2
    let T2 round random-normal 10 5
    let T3 round random-normal 10 5
    let T4 round random-normal 2 1
    let T5 round random-normal 2 1
    set p-durations (list T1 T2 T3 T4 T5 ) ;list of randomized deltas to be applied to tree-data
    set p-rates [p-rates] of wheat-data
    set r-initial-size [r-initial-size] of wheat-data
    set r-durations p-durations
    set r-rates [r-rates] of wheat-data
    set wdr self
  ]
  report wdr
end

to-report winter-wheat-data-object
  let wwdo no-turtles
  create-plant-data 1
  [
    set hidden? true
    set name "winter wheat"
    set annual? true
    set in-rows? true
    set p-shapes [ "plant wheat" "plant wheat right" ] ;plant shapes
    set p-colors [46 47 48 26 27 28]
    set r-shapes [ "plant 3" ]                         ;root shape
    set r-colors [32 33 34 35 36]
    set p-initial-size 2
    set germinate-period [270 275]
    set p-durations  [ 35 120 35 35 30 ]                 ;more realistic for trees: (list 60 3600 3600 360 720) 
    set p-rates (list 0.005 0.01 0.0001 -0.04 -0.02)     ;
    set r-initial-size 2
    set r-durations p-durations
    set r-rates (list 0.005 0.015 0.00005 -0.04 -0.02)
    set winters-over? true 
    set withers? true
    set card-temps [ 5 20 30 ]    
    set wwdo self
  ]
  report wwdo
end

to-report winter-wheat-data-randomizer [ winter-wheat-data ]
  let wwdr no-turtles
  create-plant-data 1 
  [
    set hidden? true
    set name "randomized winter wheat"
    set germinate-period [germinate-period] of winter-wheat-data
    set annual? [annual?] of winter-wheat-data
    set p-initial-size [p-initial-size] of winter-wheat-data
    let T1 round random-normal 3 2
    let T2 round random-normal 10 5
    let T3 0 ;round random-normal 10 5
    let T4 round random-normal 1 1
    let T5 round random-normal 3 2
    set p-durations (list T1 T2 T3 T4 T5 ) ;list of randomized deltas to be applied to winter-wheat-data
    set p-rates [p-rates] of winter-wheat-data
    set r-initial-size [r-initial-size] of winter-wheat-data
    set r-durations p-durations
    set r-rates [r-rates] of winter-wheat-data
    set wwdr self
  ]
  report wwdr
end

to-report soy-data-object ;creates a hidden turtle of breed plant-data that holds the growth data 
  let obj no-turtles
  create-plant-data 1      ;  for wheat in its turtle variables. This turtle is assinged to global varible Wd.
  [
    set hidden? true
    set name "soy"
    set annual? true
    set in-rows? true
    set p-shapes ["plant soy" ]
    set p-colors [ 54 55 56 65 65 66 ]
    set r-shapes ["plant 3" ]
    set r-colors [32 33 34 35 36]
    set p-initial-size 2
    set germinate-period [89 90]
    set p-durations  [ 35 70 35 35 30 ]                 ;more realistic for trees: (list 60 3600 3600 360 720) 
    set p-rates (list 0.005 0.02 0.0001 -0.04 -0.02)     ;
    set r-initial-size 2
    set r-durations p-durations
    set r-rates (list 0.005 0.01 0.0001 -0.04 -0.02)
    set winters-over? false
    set withers? true
    set card-temps [ 5 20 35 ]    
    set obj self
  ]
  report obj
end 

to-report soy-data-randomizer [ soy-data ]
  let sdr no-turtles
  create-plant-data 1 
  [
    set hidden? true
    set name "randomized soy"
    set germinate-period [germinate-period] of soy-data
    set annual? [annual?] of soy-data
    set p-initial-size [p-initial-size] of soy-data
    let T1 0 ;round random-normal 3 2
    let T2 0  ;round random-normal 10 5
    let T3 0 ;round random-normal 10 5
    let T4 round random-normal 1 1
    let T5 round random-normal 2 1
    set p-durations (list T1 T2 T3 T4 T5 ) ;list of randomized deltas to be applied to tree-data
    set p-rates [p-rates] of soy-data
    set r-initial-size [r-initial-size] of soy-data
    set r-durations p-durations
    set r-rates [r-rates] of soy-data
    set sdr self
  ]
  report sdr
end


to-report grass-data-object ;creates a hidden turtle of breed plant-data that holds the growth data 
  let obj no-turtles
  create-plant-data 1      ;  for wheat in its turtle variables. This turtle is assinged to global varible Wd.
  [
    set hidden? true
    set name "grass"
    set annual? false
    set in-rows? false
    set p-shapes [ "plant timothy" ]
    set p-colors [ 54 55 56 65 65 66 ]
    set r-shapes ["plant 2" ]
    set r-colors [32 33 34 35 36]
    set p-initial-size 2
    set germinate-period [75 300]
    set p-durations  [ 10 21 90 14 7 ]                 
    set p-rates (list 0.005 0.01 0.00002 -0.04 -0.02)   
    set r-initial-size 2
    set r-durations p-durations
    set r-rates (list 0.005 0.01 0.00002 -0.04 -0.02)
    set winters-over? true
    set withers? true
    set card-temps [ 5 15 40 ]    
    set obj self
  ]
  report obj
end 

to-report grass-data-randomizer [ grass-data ]
  let gdr no-turtles
  create-plant-data 1 
  [
    set hidden? true
    set name "randomized grass"
    set germinate-period [germinate-period] of grass-data
    set annual? [annual?] of grass-data
    set p-initial-size [p-initial-size] of grass-data
    let T1 round random-normal 3 2
    let T2 round random-normal 5 3
    let T3 round random-normal 5 3
    let T4 round random-normal 2 1
    let T5 round random-normal 2 1
    set p-durations (list T1 T2 T3 T4 T5 ) ;list of randomized deltas to be applied to tree-data
    set p-rates [p-rates] of grass-data
    set r-initial-size [r-initial-size] of grass-data
    set r-durations p-durations
    set r-rates [r-rates] of grass-data
    set gdr self
  ]
  report gdr
end

to-report plan-data-object
  let pdo no-turtles
  create-plan-data 1 
  [ 
    set end-states [ 0 ]  ;will be a list of length num-of-plantings
    set pdo self
  ]
  report pdo
end


;this creates a list of soil patches that are at the boundary of the sky and soil
to-report soil-surface-list                          ;this function is SLOW so it can only be called when it is REALLY needed.
  let soil-patches (patches with [pcolor != skycolor])
  let surface-list [ ]
  let i min-pxcor
  while [i <= max-pxcor ]
  [
    if any? soil-patches with [pxcor = i]
    [
      let m (soil-patches with [pxcor = i]) with-max [pycor]
      set surface-list lput m surface-list
      set i i + 1
    ]
  ]
  report surface-list
end


to-report soil-surface-average-y [ x ]   ;report the pycor value corresponding to the x value; it uses a local average hight of the soil surrounding the x value
  let delta 3
  let lbound ifelse-value ((x - delta) < min-pxcor) [ min-pxcor ][x - delta]
  let rbound ifelse-value ((x + delta) > max-pxcor) [ max-pxcor ][x + delta]
  set surface-set patches with [ (pcolor != skycolor) and (count (neighbors with [pcolor != skycolor]) >= 1) and (count neighbors with [ pcolor = skycolor]) >= 3 and (pxcor >= lbound) and (pxcor <= rbound)] 
  if (surface-set = no-patches or any? surface-set with [ pycor = max-pycor ] )
    [ 
      show "hit the top"
      report max-pycor
    ]
  ;show (word "x val: " x)
  report sum [pycor] of surface-set / count surface-set
  
end


to-report soil-surface-slope [ x y ]
  let horiz-delta 3
  let vert-delta 5
  let y-lbound 0
  let y-rbound 0
  let lbound ifelse-value ((x - horiz-delta) < min-pxcor)[min-pxcor][x - horiz-delta]
  let rbound ifelse-value ((x + horiz-delta) > max-pxcor)[max-pxcor][x + horiz-delta]
  let bbound ifelse-value ((y - vert-delta)  < min-pycor)[min-pycor][y - vert-delta]
  let tbound ifelse-value ((y + vert-delta)  > max-pycor)[max-pycor][y + vert-delta]
  
  let l-list []    ;create a list of vertical patches "horiz-delta" to the left of x, and "vert-delta" above and below x
  let i bbound
  while [i <= tbound]
    [
      set l-list lput (patch lbound i) l-list
      set i i + 1
    ]
  let r-list []    ;create a list of vertical patches "horiz-delta" to the right of x, and "vert-delta" above and below x
  set i bbound
  while [i <= tbound]
    [
      set r-list lput (patch rbound i) r-list
      set i i + 1
    ]
  ;show (word "x: " x " y: "  y " l: " lbound " r: " rbound " b: " bbound " t: " tbound)
  
  let l-set (patch-set l-list) 
  let l-set-soil l-set with [pcolor != skycolor]   ;from the lists create agentsets of soil only patches
  ;show (word "l-set: " l-set)
  ;show (word "l-set-soil: " l-set-soil)
  ifelse any? l-set-soil
    [ set y-lbound [pycor] of (max-one-of l-set-soil [pycor]) ]   ;find the highest soil patch
    [ set y-lbound y - (vert-delta + 1) ]                         ;if all the patches are skycolor, then just assume that the next patch below is a soil patch (this defines max-slope)
  let r-set (patch-set r-list) 
  let r-set-soil r-set with [pcolor != skycolor]
  ifelse any? r-set-soil
    [set y-rbound [pycor] of (max-one-of r-set-soil[pycor]) ]
    [set y-rbound y - (vert-delta + 1)]
  let delta-y (y-rbound - y-lbound)
  let delta-x (rbound - lbound)
  let slope delta-y / delta-x              ;calculate slope (line between the two top patches that are "horiz-delta" away from x)
  ;show (word "y-lbound: " y-lbound " y-rbound: " y-rbound " delta-y: " delta-y " delta-x: " delta-x " slope: " slope)
  report ( slope )
end

to-report soil-surface-slope2 [ x y ] ;this version uses all patch sets and no iteration--it turns out to be MUCH slower than the first version
  let horiz-delta 3
  let vert-delta 5
  let y-lbound 0
  let y-rbound 0
  let lbound ifelse-value ((x - horiz-delta) < min-pxcor)[min-pxcor][x - horiz-delta]
  let rbound ifelse-value ((x + horiz-delta) > max-pxcor)[max-pxcor][x + horiz-delta]
  let bbound ifelse-value ((y - vert-delta)  < min-pycor)[min-pycor][y - vert-delta]
  let tbound ifelse-value ((y + vert-delta)  > max-pycor)[max-pycor][y + vert-delta]
 
  let l-set patches with [is-soil? and pxcor = lbound and pycor >= bbound and pycor <= tbound]
  let r-set patches with [is-soil? and pxcor = rbound and pycor >= bbound and pycor <= tbound]
  
  let l-soil-top l-set with-max [pycor]
  let r-soil-top r-set with-max [pycor]

  ifelse any? l-soil-top
    [ set y-lbound [pycor] of max-one-of l-soil-top [pycor] ]   ;find the highest soil patch
    [ set y-lbound y - (vert-delta + 1) ]    ;if all the patches are skycolor, then just assume that the next patch below is a soil patch (this defines max-slope)
 
  ifelse any? r-soil-top
    [ set y-rbound [pycor] of max-one-of r-soil-top [pycor] ]
    [ set y-rbound y - (vert-delta + 1)]
  let delta-y (y-rbound - y-lbound)
  let delta-x (rbound - lbound)
  let slope delta-y / delta-x              ;calculate slope (line between the two top patches that are "horiz-delta" away from x)
  ;show (word "y-lbound: " y-lbound " y-rbound: " y-rbound " delta-y: " delta-y " delta-x: " delta-x " slope: " slope)
  report ( slope )
end

to advance-time   ;we assume a year of 360 days, and all months of 30 days; this procedure increments one day and calculates month and year
  set day day + 1  
  let raw-year day / year-duration
  set day-of-year day mod year-duration
  ;show (word "remainder " day-of-year)
  set year int (raw-year) + start-year
  set month int (day-of-year / month-duration)
  let day-of-month (day-of-year mod month-duration) + 1
  set month-str (word item month months " " day-of-month)  
end

to-report set-and-check-stop-time?      ;report true if it's time to stop...this manages the logic for running for a set interval of time.
  ;let day-of-year day mod year-duration
  ifelse start-run-for-set-interval?      ;if starting up for the first time...
    [
      set-stop-year
      set start-run-for-set-interval? false
      report true
    ]
    [
      ifelse (stop-at-year != 0) and ( year >= stop-at-year)  ;otherwise test to see if we are done
      [
        set start-run-for-set-interval? true
        ;set day day - 1  ;go back a day
        report false
      ]
      [
        if (run-for != last-run-for-setting)                 ;check if the "run-for" setting has changed
        [
          set-stop-year
        ]
        report true
      ]
    ] 
end

to set-stop-year
  set last-run-for-setting run-for
  let run-year-options [ "1 year" "2 years" "4 years" "6 years" "8 years" "10 years" "20 years" "Forever" ]
  let indx position last-run-for-setting run-year-options
  ifelse indx = (length run-year-options) - 1           ; if "Forever"
    [ 
      set stop-at-year 0 
      ;show "don't stop"
    ]
    [ 
      set stop-at-year year + (item indx [ 1 2 4 6 8 10 20 ]) ;add the "run for" years to the start year (or the present running year)
      ;show (word "stop at: " stop-at-year)
    ]
end


to-report random-xcor-in-zone [ z ]  
  if z = 0  [report round random-between min-pxcor 0]
  if z = 1  [report round random-between 0 max-pxcor]
  report 1000       ;error condition will throw failure
end

to-report next-xcor-in-zone [ z ]
  ifelse (z = 0) or (z = 1)
  [
    let zone-width max-pxcor
    ;show (word "zone-plant-count: " zone-plant-count)
    let which-zone item (z) zone-plant-count  ;seperate out the right list
    let tot-num  item 0 which-zone
    let num item 1 which-zone
    let start-at ifelse-value (z = 0) [min-pxcor][0]
    let delta zone-width / tot-num
    let xpos start-at + (delta / 2) + (delta * num)
    set num num + 1
    if num = plants-per-zone ;this compensates for the second planting of crops that are at the end of the list
    [
      set num 0
    ]
    set which-zone list tot-num num
    set zone-plant-count replace-item (z) zone-plant-count which-zone
    report xpos
  ]
  [
    report 1000   ;error condition will throw failure
    show "error in next-xcor-in-zone !!!!!!!!!!!!!!!!!!!!!"
  ]
  
end


to-report add-durations [ list1 list2 ] 
  let l []
  (foreach list1 list2
    [set l lput (?1 + ?2) l ]  )
  ;(show word "l: " l)
  report l
end


to make-a-seed [ d zone seed-data randomizer-obj ] ;d = germinate day; zone = number (1 or 2); data object for seed-type; randomize function for seed-type 
  let x 0
  let y 0
  let skip-this-seed? false
  let plant-who 0
  let root-who 0
  
  ;let local-seed-data randomizer seed-data
  create-plants 1 [ 
    set germinate-day d
    set name word ([name] of seed-data) germinate-day      
    set shape one-of [p-shapes] of seed-data 
    set state 0
    set-plant-state-vars state randomizer-obj
    set color one-of [p-colors] of seed-data
    set heading 0              ;growing upward
    set size [p-initial-size] of randomizer-obj
    set p-durations add-durations ([p-durations] of seed-data) ([p-durations] of randomizer-obj)
    set p-rates [p-rates] of randomizer-obj
    set p-object seed-data
    set is-wintering-over? false
    ;show (word "size: " size)
    ifelse [ in-rows? ] of seed-data
      [ set x next-xcor-in-zone zone ]
      [ set x random-xcor-in-zone zone ]
    set y soil-surface-average-y x 
    let adjusted-up-y y + 2                       ;checking that the plant is not over the top of the window
    ifelse (y + 2 <= max-pycor)
      [
        setxy x adjusted-up-y
        set start-x x
        set start-y ycor
      ]
      [
        set skip-this-seed? true                   ;if seed is out of bounds, we just skip it.
        die
      ]
    let adjusted-down-y y - 1                    ;this is checking that the root is not off the bottom of the window
    if (adjusted-down-y < min-pycor)
      [
        set skip-this-seed? true
        die
      ]
    set plant-who who       ;save the who number of the plant so it can be saved by the root
    setxy x (y + 2)
  ]
  if not skip-this-seed?
    [
      create-roots 1 [
        set germinate-day d
        set name word "Root" germinate-day
        set shape one-of [r-shapes] of seed-data      ;"plant 3"
        set state 0
        set-root-state-vars state randomizer-obj
        set color one-of [r-colors] of seed-data
        set heading 180             ;growing downward
        set size [r-initial-size] of randomizer-obj
        set r-durations add-durations ([r-durations] of seed-data) ([r-durations] of randomizer-obj)
        set r-rates [r-rates] of randomizer-obj
        setxy x y - 1
        set root-who who
        set plant-num plant-who    ;save the who number of the root so it can be saved by the plant
      ]
    ask plant plant-who [set root-num root-who]  ;point the plant to the root and vise-versa so they can find each other easily
    ]
  
end

to set-plant-state-vars [ state-num data-object ]        ;;turtle procedure
  set duration [item state-num p-durations] of data-object
  set rate [item state-num p-rates] of data-object
  set day-ct 0        
end

to set-root-state-vars [ state-num data-object ]         ;;turtle procedure
  set duration [item state-num r-durations] of data-object
  set rate [item state-num r-rates] of data-object
  set day-ct 0  
end 

;management plan options:
; "Bare Soil"
; "Forest"
; "Grass"
; "Wheat"
; "Soy"
; "Soy-Winter Wheat"

;Tillage options
; "Intensive"
; "Conservation"



to set-annual-land-management-plan   
  ;show (word "hit set-annual-land-management-plan day-of-year: " day-of-year)
  if (day-of-year = 0)     ;execute only once per year on Jan 1
  [
    let crop ""
    set germinate-day-lists [ [] [] ]
    set zone-plant-count [ ]
    set management-plan-for-year list Zone-1-Management-Plan Zone-2-Management-Plan       ;management plan will only change on Jan 1.
    let z 0
    while [ z < 2 ]                         ;iterate over the two zones
    [
      let temp-zone-plant-count [ ]
      set crop item z management-plan-for-year
      ;show (word "zone=" z " crop=" crop " day=" day-of-year )
      if crop = "Bare Soil" 
      [
        set temp-zone-plant-count [0 0]
      ]   
      if crop = "Forest" 
      [
        let g-day-list []
        let i 0
        set temp-zone-plant-count [15 0]
;        let plan item z zone-plans
;        ask plan 
;        [
;          set num-of-plantings 1
;          set end-state 0
;        ]
;        set zone-plans replace-item z zone-plans plan
        while [i < 15]
        [
          set g-day-list lput (round random-between (first [germinate-period] of Td) (last [germinate-period] of Td)) g-day-list
          set i i + 1
        ]
        set germinate-day-lists replace-item z germinate-day-lists g-day-list
      ]
      if crop = "Grass"
      [
        let g-day-list []
        let i 0
        set temp-zone-plant-count [40 0]
;        ask Gd [set end-state 0]
        while [i < 40]
        [
          set g-day-list lput (round random-between (first [germinate-period] of Gd) (last [germinate-period] of Gd)) g-day-list        
          set i i + 1
        ]
        set germinate-day-lists replace-item z germinate-day-lists g-day-list    
      ]
      if crop = "Wheat"
      [
        let g-day-list  []
        set temp-zone-plant-count (list plants-per-zone 0)
        let planting-day first [germinate-period] of Wd   ;(round random-between (first [germinate-period] of Wd) (last [germinate-period] of Wd))
        let i 0
        while [i < plants-per-zone]
        [
          set g-day-list lput (round random-between (first [germinate-period] of Wd) (last [germinate-period] of Wd)) g-day-list
          set i i + 1
        ]
        set g-day-list sort g-day-list
        set germinate-day-lists replace-item z germinate-day-lists g-day-list
        
      ]
      if crop = "Soy"
      [
        let g-day-list  []
        set temp-zone-plant-count (list plants-per-zone 0)        
        let planting-day first [germinate-period] of Sd    ;(round random-between (first [germinate-period] of Sd) (last [germinate-period] of Sd))
        let i 0
        while [i < plants-per-zone]
        [
          set g-day-list lput planting-day g-day-list
          set i i + 1
        ]
        set g-day-list sort g-day-list
        set germinate-day-lists replace-item z germinate-day-lists g-day-list
      ]
      if crop = "Soy-Winter Wheat"
      [
        let g-day-list  []
        set temp-zone-plant-count (list plants-per-zone 0)
        let planting-day first [germinate-period] of Sd    ;(round random-between (first [germinate-period] of Sd) (last [germinate-period] of Sd))
        let i 0
        while [i < plants-per-zone]
        [
          set g-day-list lput planting-day g-day-list
          set i i + 1
        ]                                 ;DON'T reset i to zero, this second while loop handles the winter wheat
        set planting-day first [germinate-period] of Wwd
        while [i < plants-per-zone * 2]   ;we are tacking the winter wheat onto the end of this list, this is not a robust solution, but expedient
        [
          set g-day-list lput planting-day g-day-list
          set i i + 1
        ]
        set g-day-list sort g-day-list
        set germinate-day-lists replace-item z germinate-day-lists g-day-list     
      ]
    ifelse z = 0
      [ set zone-plant-count fput temp-zone-plant-count zone-plant-count ]
      [ set zone-plant-count lput temp-zone-plant-count zone-plant-count ]
    set z z + 1
    ]


    
    ;show (word "germinate-day-lists=" germinate-day-lists)
    output-print (word year ": zone 1-" item 0 management-plan-for-year " zone 2-"item 1 management-plan-for-year)
  ]
end

to manage-the-land
  ;show "hit manage-the-land"
  ;let day-of-year (day mod year-duration)
  let z 0
  while [ z < 2 ]
  [
  let crop item z management-plan-for-year
  ;show (word "zone=" z " crop=" crop " day=" day-of-year)
  let g-day-list item z germinate-day-lists
  if crop = "Bare Soil" []       ;do nothing
  if crop = "Forest" 
    [
      ;show (word "day number: " day-of-year)
      if (member? day-of-year g-day-list)
      [
        foreach g-day-list [if ? = day-of-year [make-a-seed day-of-year (z) Td (tree-data-randomizer Td) ]]
      ]
    ]
  if crop = "Wheat"
    [
      ;show (word "day number: " day-of-year)
      if (member? day-of-year g-day-list)
      [
        foreach g-day-list [if ? = day-of-year [ make-a-seed day-of-year (z) Wd (wheat-data-randomizer Wd)] ]
      ]           
    ]
    if crop = "Grass"
    [
      if (member? day-of-year g-day-list)
      [
        foreach g-day-list [if ? = day-of-year [ make-a-seed day-of-year (z) Gd (tree-data-randomizer Gd) ]]
      ]     
    ]
    if crop = "Soy"
    [
      if (member? day-of-year g-day-list)
      [
        ;show (word "zone 1: " germinate-day-list-zone-1)
        foreach g-day-list [if ? = day-of-year [ make-a-seed day-of-year (z) Sd (soy-data-randomizer Sd) ]]
      ]    
    ]
    if crop = "Soy-Winter Wheat"
    [
      if (member? day-of-year g-day-list)
      [
        let i 0
        while [i < plants-per-zone * 2]
        [ 
          if (item i g-day-list) = day-of-year
          [
            ifelse i < plants-per-zone
            [
               make-a-seed day-of-year (z) Sd (soy-data-randomizer Sd)                 
            ]
            [
               make-a-seed day-of-year (z) Wwd (winter-wheat-data-randomizer Wwd)
            ]
          ] 
          set i i + 1
        ]
      ]
    ]
    set z z + 1
  ] ;end while
end


to-report temperature-rate-factor [ plant-data-object ] ;;the return value modifies the growth rate depending on temperature
  let min-t item 0 [ card-temps ] of plant-data-object
  let opt-t item 1 [ card-temps ] of plant-data-object
  let max-t item 2 [ card-temps ] of plant-data-object
  if ave-month-temperature <= min-t [ report 0 ]                       ;too cold, no growth
  if ave-month-temperature > min-t and ave-month-temperature <= opt-t  ;growth in proportion to difference of min growth temp and optimal temp
   [
    let plant-span opt-t - min-t
    let present-span opt-t - ave-month-temperature
    report (1 - (present-span / plant-span))
   ]
   if ave-month-temperature > opt-t and ave-month-temperature <= max-t  ;in optimal zone
   [
     report 1
   ]
   if ave-month-temperature > max-t and ave-month-temperature <= max-t + 5  ;for hotter than max-t, assume a 5 degree range of withering before it dies
   [
     let present-span ave-month-temperature - max-t
     report (present-span / 5)
   ]
   report 0  ;if hotter than max cardinal temperature + 5 degrees, no growth, it may die
end

to-report topsoil-rate-factor [ x-val ]
  set x-val round x-val        ;if you don't round the x-val, no patches are found!  NetLogo can be stupid!!
  let topsoil-depth count patches with [ (pxcor = x-val) and topsoil? and (depth <= default-topsoil-depth) ]
  ;show (word "soil x-val: " x-val " topsoil-depth: " topsoil-depth)
  ifelse topsoil-depth = 0
    [
      set topsoil-depth 0.25
    ]
    [
      if topsoil-depth > default-topsoil-depth 
      [
        set topsoil-depth default-topsoil-depth 
      ]
    ]
  report topsoil-depth / default-topsoil-depth
end


to grow-all [ plant-breed ]
  
  if any? plant-breed
  [
    ;let day-of-year day mod year-duration
    let delta 0   ;increment of how much it grows per day, (size * rate)

    
    ask plant-breed [ 
      
      let local-root-num root-num             ;contains the root breed number of the root corresponding to the plant in question  
      let plant-will-die? false        
      
      let plants-state state       ;because both plants and roots are in "ask" simultaneously, we will work with local variables and assign the changeed <turtles-own> variables at the end.
      let plants-size size
      let plants-rate rate
      let plants-color color
      let plants-ycor ycor
      let plants-xcor xcor
      let plants-new-ycor 0
      let plants-heading heading
      let plants-start-x start-x
      let plants-start-y start-y
      let plants-duration duration
      let plants-day-ct day-ct
      let plants-is-wintering-over? is-wintering-over?
      let local-p-data [p-object] of self
      let local-p-durations p-durations 
      let local-p-rates p-rates
      let plants-withers? [ withers? ] of local-p-data      
      let local-card-temps [card-temps] of local-p-data
      let local-min-temp item 0 local-card-temps
      let local-optimal-temp item 1 local-card-temps
      let local-max-temp item 2 local-card-temps
      set plant-will-die? false
      
      let roots-state 0
      let roots-size 0
      let roots-rate 0
      let roots-ycor 0
      let roots-new-ycor 0
      let roots-duration 0
      let local-r-rates 0
      let local-r-duration 0 
      
      ask root local-root-num                           ;we have to work on both the plant and its root at the same time.
      [  
        ;set plant-will-die? false  
        set roots-state [state] of self ;self in this case is the root
        set roots-size [size] of self
        set roots-rate [rate] of self
        set roots-ycor [ycor] of self
        
        set roots-duration [duration] of self
        set local-r-rates [r-rates] of self
        set local-r-duration [r-durations] of self
        
        
        if (plants-state >= 0 and plants-state <= 3)
        [
          let growth-rate-for-state item plants-state local-p-rates
          ;modify standard plant growth rate depending on temperature and depth of topsoil
          let t topsoil-rate-factor plants-xcor
          ;show (word "topsoil-rate-factor: " t)
          let plants-adjusted-rate growth-rate-for-state * t * (temperature-rate-factor local-p-data)
          ;set plants-rate topsoil-rate-factor plants-rate plants-xcor                             ;modify plants-rate depending on depth of topsoil
          ;show (word "plant rate: " plants-rate)
          set delta plants-size * plants-adjusted-rate
          set plants-new-ycor plants-ycor + delta * 0.5
          if (plants-new-ycor > min-pycor) and (plants-new-ycor < max-pycor) 
            [ 
              set plants-ycor plants-new-ycor 
            ] 
          set plants-size plants-size + delta
          ;now grow the root
          set growth-rate-for-state item plants-state local-r-rates
          let roots-adjusted-rate growth-rate-for-state * t * (temperature-rate-factor local-p-data)
          set delta roots-size * roots-adjusted-rate
          set roots-new-ycor roots-ycor - delta * 0.5
          if (roots-new-ycor > min-pycor) and (roots-new-ycor < max-pycor) 
            [ 
              set roots-ycor roots-new-ycor 
            ]
          set roots-size roots-size + delta                    
          set plants-day-ct plants-day-ct + 1
          if ( plants-day-ct >= plants-duration )
          [ 
            set plants-state plants-state + 1
            set roots-state plants-state
            set plants-duration item plants-state local-p-durations
            set plants-day-ct 0 
            
            ;show (word "state is " state)
            if (plants-state = 3)
            [
              set plants-color one-of dead-colors
              set plants-heading one-of [90 270]
              set plants-xcor plants-start-x       ;if plant dies it needs to return to its original position when it falls over
              set plants-ycor plants-start-y
              ;setxy start-x start-y 
            ]
          ]
        ]
        if (plants-state = 4) 
        [
          set plants-day-ct plants-day-ct + 1
          if ( plants-day-ct >= plants-duration )
          [ 
            set plant-will-die? true
          ]
        ]
        
        ifelse [ winters-over? ] of local-p-data
          [
            ifelse ave-month-temperature < local-min-temp 
            [
              if not plants-is-wintering-over? 
              [
                set plants-is-wintering-over?  true
                if plants-withers? 
                [
                  set plants-color one-of wither-colors
                ] 
              ]
            ]
            [
              if plants-is-wintering-over? 
              [
                set plants-is-wintering-over?  false
                if plants-withers?
                [
                  set plants-color one-of [p-colors] of local-p-data
                ]
              ]
            ]
          ]
          [
          ]         
        
        ;set all local root variables:
        ;set color plants-color
        set state plants-state
        set size roots-size
        set rate roots-rate
        set ycor roots-ycor
        set duration plants-duration    
        set day-ct plants-day-ct 
      ] ;end ask root
      
      ifelse plant-will-die?     
      [
        ask root local-root-num [ die ]
        die                              ;this is NetLogo's "die" that removes the plant from the screen. The plant has already be "dead" for some time.
      ]
      [
        set state plants-state 
        set size plants-size 
        set rate plants-rate
        set color plants-color
        set ycor plants-ycor
        set xcor plants-xcor
        ;      set plants-new-ycor 0
        set heading plants-heading
        set is-wintering-over? plants-is-wintering-over? 
        set duration plants-duration
        set day-ct plants-day-ct    
      ]
    ] ;end ask plant
  ; if plant-will-die? [ ask root local-root-num [ die ] ]
  ] ;end if any?
end




to set-terrain
  if terrain = "Nearly Flat" [set amplitude -0.00001]
  if terrain = "Plain"       [set amplitude  -4]
  if terrain = "Rolling"     [set amplitude -10]
  if terrain = "Hilly"       [set amplitude -20]
end

to-report terrain-function [ x ]
  ifelse ( terrain = "Terraced" )
  [
    if x >= min-pxcor and x < min-pxcor + round (max-pxcor / 5) [report min-pycor + (world-height * 0.2)]
    if x >= min-pxcor + round (max-pxcor / 5) and x < min-pxcor + round (max-pxcor * 2 / 5) [report  min-pycor + (world-height * 0.3)]
    if x >= min-pxcor + round (max-pxcor * 2 / 5) and x < min-pxcor + round (max-pxcor * 3 / 5) [report  min-pycor +  (world-height * 0.4)]
    if x >= min-pxcor + round (max-pxcor * 3 / 5) and x < min-pxcor + round (max-pxcor * 4 / 5) [report  min-pycor +  (world-height * 0.5)]
    if x >= min-pxcor + round (max-pxcor * 4 / 5) and x < min-pxcor + round (max-pxcor) [report  min-pycor +  (world-height * 0.6)]
    report -25 * sin( pxcor - 20 ) - 1
  ]
  [
    ifelse terrain = "Slope Test"
    [
      let surface 0
      ifelse x >= min-pxcor and x < 0 
      [
        set surface (zone-1-slope * x) + elevation
      ]
      [
        set surface (zone-2-slope * x) + elevation 
      ]
      if surface <= min-pycor [ set surface min-pycor ]
      report surface
    ]
    [
      report amplitude * sin( pxcor - 10 ) 
    ]
  ]
end

to-report monthly-climate-rainfall
  report item month [monthly-precip] of climate-obj
end

to-report monthly-climate-temperature
  report item month [monthly-temps] of climate-obj
end

to-report max-set-monthly-rainfall
  report [max monthly-precip] of climate-obj
end

to-report max-possible-monthly-rainfall        ;this looks through each climate data object and extracts the highest monthly rainfall in mm.  As each new climate is added to the model, it needs to be updated.
 let temper-obj temperate-climate-data-object 
 let trop-obj tropical-climate-data-object
 let semi-arid-obj semi-arid-climate-data-object
 let max-precip-list []
 foreach (list temper-obj trop-obj semi-arid-obj )  [ ask ? [set max-precip-list lput max monthly-precip max-precip-list]]
 report max max-precip-list
end

to-report random-between [a b] ; returns a random number between a and b (inclusive) with four decimals, i.e. 3.3092
  if a > b [let c b set b a set a c ] ; make a the smaller of the two
  report a + .0001 * random (1 + 10000 * (b - a)) 
end
@#$#@#$#@
GRAPHICS-WINDOW
98
73
855
347
124
40
3.0
1
10
1
1
1
0
0
0
1
-124
124
-40
40
0
0
1
ticks
30.0

BUTTON
16
73
80
106
NIL
Setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
164
24
221
69
Year
year
0
1
11

MONITOR
225
24
282
69
Month
month-str
17
1
11

BUTTON
16
117
79
150
Run
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

SLIDER
681
28
853
61
year-speed
year-speed
0.1
5
0.1
0.1
1
NIL
HORIZONTAL

INPUTBOX
98
10
160
70
Start-Year
2014
1
0
Number

CHOOSER
619
354
815
399
Zone-2-Management-Plan
Zone-2-Management-Plan
"Bare Soil" "Forest" "Grass" "Wheat" "Soy" "Soy-Winter Wheat"
2

CHOOSER
2
300
94
345
Terrain
Terrain
"Nearly Flat" "Plain" "Rolling" "Hilly" "Terraced" "Slope Test"
5

CHOOSER
7
512
200
557
Climate
Climate
"Humid Continental" "Tropical Rainforest" "Semi-Arid"
0

TEXTBOX
288
325
340
345
Zone 1 
11
9.9
1

TEXTBOX
617
326
673
345
Zone 2
11
9.9
1

MONITOR
286
24
350
69
Temp (C)
round ave-month-temperature
17
1
11

MONITOR
354
24
422
69
Precip (mm)
round ave-month-precip
17
1
11

CHOOSER
3
161
95
206
Run-for
Run-for
"1 year" "2 years" "4 years" "6 years" "8 years" "10 years" "20 years" "Forever"
7

SLIDER
552
28
674
61
erosion-probability
erosion-probability
0
100
32
1
1
NIL
HORIZONTAL

PLOT
125
353
378
503
Erosion Rates
Time
Monthly Erosion
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Zone 1" 1.0 0 -5825686 true "" "if day != 0 and day mod 30 = 0\n[plot zone1-erode-ct\n set zone1-erode-ct 0]"
"Zone 2" 1.0 0 -955883 true "" "if day != 0 and day mod 30 = 0\n[plot zone2-erode-ct\n set zone2-erode-ct 0]"

SLIDER
3
385
108
418
Zone-1-slope
Zone-1-slope
-0.5
0.5
0.4
0.1
1
NIL
HORIZONTAL

SLIDER
4
422
109
455
Zone-2-slope
Zone-2-slope
-0.5
0.5
-0.4
0.1
1
NIL
HORIZONTAL

SLIDER
4
459
109
492
Elevation
Elevation
-25
25
17
1
1
NIL
HORIZONTAL

TEXTBOX
8
353
65
383
Slope Test Variables:
11
0.0
1

SLIDER
7
561
200
594
ave-precip-per-month
ave-precip-per-month
0
500
343
1
1
mm
HORIZONTAL

SWITCH
204
519
382
552
use-slider-climate-values?
use-slider-climate-values?
1
1
-1000

SWITCH
388
626
553
659
show-erosion-data?
show-erosion-data?
1
1
-1000

SLIDER
205
561
382
594
ave-temp-per-month
ave-temp-per-month
-10
50
17
1
1
C
HORIZONTAL

CHOOSER
386
353
577
398
Zone-1-Management-Plan
Zone-1-Management-Plan
"Bare Soil" "Forest" "Grass" "Wheat" "Soy" "Soy-Winter Wheat"
1

OUTPUT
386
452
816
616
12

CHOOSER
386
403
479
448
Zone-1-Tillage
Zone-1-Tillage
"Intensive" "Conservation"
1

CHOOSER
619
403
716
448
Zone-2-Tillage
Zone-2-Tillage
"Intensive" "Conservation"
1

CHOOSER
2
224
95
269
Soil-Color-Shows
Soil-Color-Shows
"Topsoil" "Erosion" "Soil Quality" "Nitrogen" "Water"
0

SLIDER
10
603
182
636
Carbon-Test
Carbon-Test
0
100
62
1
1
NIL
HORIZONTAL

SLIDER
10
647
182
680
Nitrogen-Test
Nitrogen-Test
0
100
44
1
1
NIL
HORIZONTAL

SLIDER
201
627
373
660
Water-Test
Water-Test
0
100
55
1
1
NIL
HORIZONTAL

MONITOR
13
19
96
64
topsoil count
count patches with [topsoil?]
0
1
11

CHOOSER
485
403
577
448
Zone-1-Fertilize
Zone-1-Fertilize
"None" "Light" "Medium" "Heavy"
0

CHOOSER
720
403
817
448
Zone-2-Fertilize
Zone-2-Fertilize
"None" "Light" "Medium" "Heavy"
0

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

flower budding
false
0
Polygon -7500403 true true 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Polygon -7500403 true true 189 233 219 188 249 173 279 188 234 218
Polygon -7500403 true true 180 255 150 210 105 210 75 240 135 240
Polygon -7500403 true true 180 150 180 120 165 97 135 84 128 121 147 148 165 165
Polygon -7500403 true true 170 155 131 163 175 167 196 136

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

plant 2
true
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 225 45 195 90 255 135 285
Polygon -7500403 true true 165 255 210 225 255 195 210 255 165 285
Polygon -7500403 true true 135 180 90 150 45 120 90 180 135 210
Polygon -7500403 true true 165 180 165 210 210 180 255 120 210 150
Polygon -7500403 true true 165 105 210 75 225 60 210 90 165 135
Polygon -7500403 true true 135 90 135 45 150 15 165 45 165 90
Polygon -7500403 true true 135 105 90 75 75 60 90 90 135 135

plant 3
true
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 165 255 180 225 210 165 195 240 165 285
Polygon -7500403 true true 135 180 135 210 105 165 90 90 105 135
Polygon -7500403 true true 165 105 180 75 180 45 195 75 165 135
Polygon -7500403 true true 135 90 135 45 150 15 165 45 165 90
Polygon -7500403 true true 135 105 120 75 120 45 105 75 135 135
Polygon -7500403 true true 165 180 165 210 195 165 210 90 195 135
Polygon -7500403 true true 135 255 120 225 90 165 105 240 135 285

plant medium
false
0
Rectangle -7500403 true true 135 165 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 165 120 120 150 90 180 120 165 165

plant small
false
0
Rectangle -7500403 true true 135 240 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 240 120 195 150 165 180 195 165 240

plant soy
true
0
Rectangle -7500403 true true 141 90 156 300
Polygon -7500403 true true 144 260 99 215 54 200 102 233 144 290
Polygon -7500403 true true 144 188 144 218 119 188 62 149 100 162
Polygon -7500403 true true 145 121 145 151 113 110 71 75 96 85
Polygon -7500403 true true 156 90 136 58 103 34 119 55 141 91
Polygon -7500403 true true 142 89 162 55 195 33 179 54 157 90
Polygon -7500403 true true 96 84 89 74 74 69 60 72 50 81 41 97 50 98 65 97 75 101 84 96 88 90 95 86
Polygon -7500403 true true 123 121 117 129 107 132 95 135 84 130 79 123 75 115 78 110 92 109 100 111 114 113 120 119
Polygon -7500403 true true 121 255 115 263 105 266 93 269 82 264 77 257 73 249 76 244 90 243 98 245 112 247 118 253
Polygon -7500403 true true 80 154 73 144 58 139 44 142 34 151 25 167 34 168 49 167 59 171 68 166 72 160 79 156
Polygon -7500403 true true 75 211 68 201 53 196 39 199 29 208 20 224 29 225 44 224 54 228 63 223 67 217 74 213
Polygon -7500403 true true 115 185 109 193 99 196 87 199 76 194 71 187 67 179 70 174 84 173 92 175 106 177 112 183
Polygon -7500403 true true 120 47 114 39 104 36 92 33 81 38 76 45 72 53 75 58 89 59 97 57 111 55 117 49
Polygon -7500403 true true 174 47 180 39 190 36 202 33 213 38 218 45 222 53 219 58 205 59 197 57 183 55 177 49
Polygon -7500403 true true 155 121 155 151 187 110 229 75 204 85
Polygon -7500403 true true 204 84 211 74 226 69 240 72 250 81 259 97 250 98 235 97 225 101 216 96 212 90 205 86
Polygon -7500403 true true 177 121 183 129 193 132 205 135 216 130 221 123 225 115 222 110 208 109 200 111 186 113 180 119
Polygon -7500403 true true 156 188 156 218 181 188 238 149 200 162
Polygon -7500403 true true 220 154 227 144 242 139 256 142 266 151 275 167 266 168 251 167 241 171 232 166 228 160 221 156
Polygon -7500403 true true 185 185 191 193 201 196 213 199 224 194 229 187 233 179 230 174 216 173 208 175 194 177 188 183
Polygon -7500403 true true 156 260 201 215 246 200 198 233 156 290
Polygon -7500403 true true 225 211 232 201 247 196 261 199 271 208 280 224 271 225 256 224 246 228 237 223 233 217 226 213
Polygon -7500403 true true 179 255 185 263 195 266 207 269 218 264 223 257 227 249 224 244 210 243 202 245 188 247 182 253

plant timothy
true
0
Polygon -7500403 true true 223 127 212 159 195 207 186 241 180 301 171 301 181 228 190 194 214 127
Polygon -7500403 true true 211 132 218 109 237 83 250 65 260 75 239 117 224 137
Polygon -7500403 true true 130 102 138 134 151 195 152 240 151 300 161 301 162 239 160 194 151 150
Polygon -7500403 true true 146 126 136 100 119 71 105 54 97 63 125 122 136 135
Polygon -7500403 true true 172 99 165 134 173 194 169 242 161 302 169 302 180 242 182 192 174 146
Polygon -7500403 true true 174 124 176 98 169 57 158 58 160 100 161 119 164 130
Polygon -7500403 true true 44 65 59 92 62 86
Polygon -7500403 true true 271 46 256 73 253 67
Polygon -7500403 true true 162 23 161 58 166 57
Polygon -7500403 true true 92 141 109 169 129 216 138 250 144 310 153 310 143 237 134 203 103 141
Polygon -7500403 true true 109 145 99 122 80 96 63 80 55 91 78 130 93 150
Polygon -7500403 true true 273 59 258 86 261 80
Polygon -7500403 true true 83 35 98 62 101 56

plant wheat
true
0
Polygon -7500403 true true 75 120 105 165 120 210 135 240 135 300 150 300 150 240 135 195 105 135
Polygon -7500403 true true 105 135 105 105 90 75 60 45 68 106 87 133 105 150
Polygon -7500403 true true 120 75 135 135 150 195 150 240 150 300 165 300 165 240 165 195 150 150
Polygon -7500403 true true 135 120 135 90 120 60 90 30 98 91 117 118 135 135
Polygon -7500403 true true 165 75 180 135 180 195 180 240 165 300 180 300 195 240 195 195 195 150
Polygon -7500403 true true 180 135 180 105 165 75 135 45 143 106 162 133 180 150

plant wheat right
true
0
Polygon -7500403 true true 225 105 195 165 180 210 165 240 165 300 150 300 150 240 165 195 195 135
Polygon -7500403 true true 195 135 195 105 210 75 240 45 232 106 210 135 195 150
Polygon -7500403 true true 180 75 165 135 150 195 150 240 150 300 135 300 135 240 135 195 150 150
Polygon -7500403 true true 165 120 165 90 180 60 210 30 202 91 183 118 165 135
Polygon -7500403 true true 135 75 120 135 120 195 120 240 135 300 120 300 105 240 105 195 105 150
Polygon -7500403 true true 120 135 120 105 135 75 165 45 157 106 138 133 120 150

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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
true
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

tree pine
true
0
Rectangle -6459832 true false 120 225 180 300
Polygon -7500403 true true 150 240 240 270 150 135 60 270
Polygon -7500403 true true 150 75 75 210 150 195 225 210
Polygon -7500403 true true 150 7 90 157 150 142 210 157 150 7

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
