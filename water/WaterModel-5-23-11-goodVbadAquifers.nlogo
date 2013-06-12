; Groundwater v.5.2
; April, 2011
; Developed by: Bob Tinker
; Design assistance: Nathan Kimball, Dan Damelin
; The HAS project, Amy Pallent, PI

; Improvements:
; Disk save and restore remains as a convenience to developers
; Pumps and surface added
; Refactored to be cleaner
; Full checkmark implementation
; Information on-screen every step of the way

; The overall logic features a few NL buttons, three of which put up soft buttons that support 16 functions.
; The soft buttons are polled regularly in the main execution loop and when one is pressed, control is passed to its handler.
; The handler is executed once per button click on mouse-up. All handlers have names that begin with "hadle-" followed by a name. 
; The names of the buttons are defined in the first statement of "define-icons". 
; In that statement, the button names have spaces, such as "pause model". This is the form that the user sees as a roll-over
; The shape of the button is its name, but with hyphens for spaces, such as "pause-model". 
; The command executed must be fully hyphenated, such as "handle-pause-model" 
; Some handlers instantly do some action, whereas others require additional user interaction. 
; These latter put up a checkmark called "check when done" In the code, this check is made with "show-checkmark" and polled with "checkmark-clicked?" 
; Each soft button has a "kind" that defines the group of icons to which it belongs. 
; The buttons are defined in startup and thereafter shown or hidden according to which kind is to be shown. 

globals [
  pressed-icon-color
  default-icon-color
  icon-zone              ; list of lower right x,y coordinates of the last icon to the right--used to make the icon area out-of-bounds for editing.
  icon-size
  run?                   ; tells whether the main model should be running
  help-message           ; stores the help message that is shown when the help button is pressed 
  view-name              ; the name of the current view
  handle-size            ; the size of the handles (2)
  water-amount
  year
  quarter
  dot-size
  n-Handles              ; the number of handles in a group
  n-groups               ; a unique group number
  view                   ; a list of all the data needed to reproduce a scene: the name, number of groups, handles, and droplets. 
  views                  ; stores multiple views on disc
  selected-color         ; used to share the color of the swatch that a user selects
  rock-colors
  surface-colors
  sky-color
  mark-color
  max-spray-v            ; max component in the spray water
  grav                   ; the effective value of gravity
  max-allowed            ; the maximum allowed water droplets
  user-done?             ; set when the user clicks a checkmark
  first-time?            ; used to initialize model
  ds
  w-ave
  w-ave1
  mark-rain?
  watching?
  watched-turtle-number  ;set the number of the turtle being watched so that die-check can call reset-perspective if the turtle is bein watched
  mark-count
  month-rain-ct
  month-pump-ct
  month-ET-ct
  new-quarter?
  well-water-dissappears?
  Year-duration
  Rain-pattern
  Prob-rain
  evap-prob
]

breed [dots dot]             ; water drops
breed [well-waters well-water] ; water drops that rise 
breed [spray-waters spray-water] ; water sprayed upward 
breed [evaps evap]           ; evaporating drops
breed [points point]         ; the dots drawn between handles
breed [handles handle]       ; black squares in the drawings
breed [icons icon]           ; used for soft buttons.   an icon is active if not hidden?; inactive if hidden?
                             ;   it is pressed if its color is pressed-icon-color. 
                             ;   it is not pressed if its color is default-icon-color
                             ;   its shape is its name, but with spaces converted to hyphens
breed [swatches swatch]      ; used for picking colors
breed [squares square]       ; used for picking files
breed [messages message]     ; used for messages
breed [roll-overs roll-over] ; like messages, but used for the roll-overs
breed [fillers filler]       ; turtles that draw the background based on the colors of dots they enounter heading downward, to their death
breed [pumps pump]

icons-own [kind name]       ; kind may be used to turn on or off sub-classes of icons.  
                            ; the name is the name of the icos without hyphens so it is easier to read--used for the roll-over
handles-own [group point-color]   ; all the handles and points that define a layer are in one group
points-own [group]
squares-own [index]
spray-waters-own [vx vy]
pumps-own [end?]            ; there are two kinds of pump turtles bottom ends (end? = true) and well-heads (end? = false)

to startup  ; called by the reset button and also run when NL is loaded (the reset button is just for testing)
  clear-all
  set n-handles 31                  ; the number of handles in a group, evenly spaced horizontally
  set n-groups 0                    ; start with no groups
  set handle-size 2                   ; the size of the handles
  set rock-colors [0 115 125 45 15]  ; five rock colors: black, violet, magenta, yellow, red
  set surface-colors [31 34 37 29 26]
  set max-allowed 4000              ; the target maximum number of water droplets of all kinds

  set dot-size 1.8                  ; size of raindrops and evaporating water
  set sky-color 88
  
  set icon-size max-pycor / 4       ; size of the icons
  set default-icon-color 57         ;  light green
  set pressed-icon-color 63         ;  dark green
  set max-spray-v 2.5 / patch-size  ; maximum speed of spray
  set grav .015                     ; force of gravity on spray
  set ds 2                          ; ds is the default distance of water movement
  set mark-rain? false
  set mark-count 5
  set mark-color orange
  set watching? false
  set year 0
  set quarter 0
  set month-rain-ct 0
  set month-pump-ct 0
  set month-ET-ct 0
  set new-quarter? false
  set views [ ["Aquifers Example" 4
 [[-66 11.5 15 2] [-124 27.5 0 1] [-58 5.17 15 2] [-8 17.83 45 4] [-25 19.17 45 4] [-83 40 15 2]
 [116 40 115 3] [-83 40 115 3] [25 -20.5 0 1] [58 19.83 45 4] [-25 -8.83 115 3] [-41 -25.17 0 1]
 [-124 40 115 3] [83 40 115 3] [0 -10.83 0 1] [-50 -5.17 115 3] [50 -21.17 0 1] [-116 27.5 0 1] [-25
 -18.5 0 1] [-66 -2.5 0 1] [0 6.5 15 2] [-41 0.83 15 2] [124 40 45 4] [116 40 15 2] [41 1.17 15 2]
 [8 40 115 3] [-99 40 45 4] [50 3.83 15 2] [16 4.83 15 2] [116 40 45 4] [91 35.5 0 1] [-91 40 15 2]
 [-8 6.5 15 2] [-99 26.17 0 1] [-17 -7.83 115 3] [8 17.5 45 4] [124 40 15 2] [33 40 115 3] [-33
 -7.17 115 3] [-91 40 45 4] [83 33.83 0 1] [124 40 115 3] [8 6.17 15 2] [99 34.5 0 1] [25 3.17 15 2]
 [74 40 115 3] [58 0.83 0 1] [16 -15.5 0 1] [83 40 15 2] [91 40 115 3] [107 40 45 4] [0 -10.17 115
 3] [-66 21.17 45 4] [-58 -20.17 0 1] [107 35.17 0 1] [-41 -6.17 115 3] [58 4.5 15 2] [-91 40 115 3]
 [50 40 115 3] [8 -12.5 0 1] [-124 40 15 2] [-33 2.5 15 2] [91 40 15 2] [-107 40 15 2] [66 25.83 45
 4] [74 40 15 2] [124 37.17 0 1] [-74 22.83 45 4] [-99 40 15 2] [-116 40 15 2] [25 19.83 45 4] [58
 40 115 3] [116 36.17 0 1] [-83 40 0 1] [-74 22.17 15 2] [-17 18.83 45 4] [33 1.83 15 2] [41 21.83
 45 4] [-58 -5.17 115 3] [-41 25.5 45 4] [-33 21.5 45 4] [99 40 115 3] [66 40 15 2] [16 17.5 45 4]
 [16 40 115 3] [74 31.17 0 1] [74 40 45 4] [-116 40 115 3] [-107 40 115 3] [-50 25.17 45 4] [-91
 24.5 0 1] [-107 40 45 4] [99 40 15 2] [-74 21.17 0 1] [-58 21.17 45 4] [-17 -13.83 0 1] [83 40 45
 4] [50 19.17 45 4] [66 25.17 0 1] [66 40 115 3] [-66 -1.17 115 3] [-74 40 115 3] [41 -23.5 0 1]
 [-107 26.83 0 1] [41 40 115 3] [-50 3.83 15 2] [99 40 45 4] [91 40 45 4] [107 40 15 2] [-8 -10.83 0
 1] [-116 40 45 4] [0 18.17 45 4] [33 22.17 45 4] [-124 40 45 4] [-50 -23.17 0 1] [-99 40 115 3] [33
 -21.83 0 1] [25 40 115 3] [-33 -24.17 0 1] [-25 4.5 15 2] [-83 40 45 4] [107 40 115 3] [-17 5.5 15
 2] [-8 -7.5 115 3]] [[24.7 -20.9] [-32.6 -7.2] [-64.8 -3.2] [15.8 -15.3] [36.7 -14.4] [-24.5 -18.1]
 [18.4 -12.4] [-53.5 -21.5] [23.9 -17.7] [46 12.6] [29.4 7.2] [23 -15.8] [-55.2 9.4] [-21.5 -3.7]
 [-30.1 -17.8] [-2.4 8.8] [-41.1 -17.1] [-60 -14.4] [54.4 15.6] [60.4 16.6] [-49.4 -14.4] [35.6
 -14.5] [55.1 -15.1] [36.7 -22] [57.1 5.5] [-74.1 18.3] [-55.9 21.3] [32.8 -18.3] [19.7 -15.3]
 [-64.1 17.9] [-31.5 -19.6] [20.7 8.6] [30.4 -22.4] [13.4 -14.5] [-47.9 -11.8] [-36.8 -19.4] [-30.6
 -23.3] [-39.1 -22.6] [-51.2 -19.5] [24.2 -17.4] [24.1 -20.2] [109 36] [-39.7 -18.7] [-53.8 -20.2]
 [-47.8 -13.2] [41.4 -14.7] [112.5 36.1] [-13.5 7] [-49.4 -19] [34.6 -21] [-67.1 21.6] [46.9 -22.3]
 [-39.8 -13.8] [-45.6 -23.7] [-51.8 -16.8] [50.3 -15.6] [29.1 -21.1] [-61.2 -14.8] [26.1 -20.5]
 [-34.6 -20.7] [-31.1 -23.9] [-56.2 -18.1] [-50.4 6.8] [-9.3 6.7] [33.3 8.5] [55.7 10.6] [-7.9 14.2]
 [26 -20.2] [46.1 -19.2] [50.2 -18.9] [-58.4 -11.4] [22.8 3.5] [-28.9 -16.8] [-57.5 -12.4] [-56.3
 -7.7] [52 20] [-29.3 -7.5] [-29.1 -22.1] [-53.6 10.5] [12.3 -14.5] [35.1 -3.2] [-38.9 -17.4] [25.1
 -15.4] [-13.2 -7.7] [-48.8 -23.5] [30.1 -20.5] [-7.2 3.2] [-36.8 -12.2] [-64.7 14.8] [37.4 -19.5]
 [52.4 15.6] [20.5 -1.9] [-62.6 22.6] [-53 -19] [-56.1 -13.7] [-53.8 -17.9] [-58 22.8] [30.1 -20.5]
 [44.1 8.6] [15.3 10.4] [-53.5 -9.5] [18.2 -16.8] [-61.9 -4.3] [-36.8 -19.6] [32.4 -21] [54.2 -13]
 [26.4 -19.7] [-24.9 -13.6] [-67.1 19.1] [24.6 -16.1] [-40.8 -15.2] [-22.8 -8.6] [-66.4 22.8] [-31.9
 -15.7] [-43.2 -25.1] [-54.3 -20.6] [-43.4 -19.9] [13.4 16.1] [92 36] [1.3 -5.5] [30.8 -21.6] [21.3
 -9.8] [-60.8 -17.1] [-12.8 -5.4] [-49.7 -19.3] [23.3 -16.9] [24.3 -16] [-41.1 -19.4] [-60.4 10.1]
 [44.6 -15.7] [18.3 -14.4] [36.7 -21.9] [-45.6 -24.1] [30 -20.8] [-67 20.9] [31.1 -19] [37.7 -22.8]
 [41.3 -15.4] [39.7 -20.3] [-56.9 -16.9] [-10.8 17.5] [-14.7 -10.3] [-53.1 -16.2] [-33.8 -14.2] [2.4
 -2.4] [-59.7 -8.9] [-40.8 -16.2] [8.3 17.1] [113 -40] [22.4 -18.5] [-43.2 -16.8] [-59 -16.5] [-18.7
 -7.8] [50.9 13.8] [-53.6 11.2] [13.6 -15.3] [20.1 -17.6] [-53.6 -21.8] [-49 -22.4] [11 -14.5]
 [-53.5 10.3] [-46.4 -12.5] [-19.9 -16] [48.3 9.8] [36.9 -18.9] [-34 -21.3] [-24.6 -20.6] [20.1
 -17.5] [30.1 -21.9] [-50.2 -17.6] [-54.5 -13.8] [-59.3 -19.2] [-54.5 -12.8] [-32.5 -18.8] [-48.6
 -22.3] [25.9 -18.6] [-28.4 -20.4] [-56 -4.4] [-41.8 -16.4] [-29.5 -22.9] [16.6 5.8] [-25.7 -14]
 [-56.7 -19.9] [-42.8 -12.2] [-54.5 -16.1] [37.6 -17.6] [-28.4 -18.6] [-22.5 -13.7] [-54.2 -11.2]
 [-62.9 11] [0.7 14.2] [24.1 -19.8] [35.1 -21.7] [21.4 -16.4] [-26.9 -12.2] [30.4 -21.2] [20.9 -18]
 [-20.1 -13.6] [-57 -17.7] [49.7 -20.3] [-60.8 9.2] [102 -40] [53.1 18.8] [16.8 -16.7] [-54.6 -17.1]
 [18 -16.5] [-23.8 -17.5] [-14.4 18.8] [20 -18.8] [37 -16.6] [-28.7 -20.7] [-69 6.3] [-59.1 17.3]
 [51.9 -19.1] [-60.4 20.2] [49.5 18.1] [-16.9 7.1] [-33.8 -12.1] [-78 23.7] [-20.6 -12.8] [-27
 -14.9] [-30.9 -21] [-34.9 -24.8] [113 37] [-23 -1.2] [-37.1 -21.8] [20.3 -17.8] [30.6 3] [-46.1
 -18.6] [21.4 -14.9] [-55.4 -19] [-70 23] [19.2 -17.8] [-7.8 -9.5] [23.9 -12.6] [0.7 13] [-46.3
 -10.8] [33.4 -21.6] [5.4 -11.8] [46.9 4.5] [51.7 -18.4] [56 21] [-5.7 10.6] [-50.7 -15.7] [-48.6
 -14.5] [5.7 10.1] [51.8 -18.1] [49.6 -21.5] [-62.8 -1.9] [-24.8 -19.2] [31.8 -17.5] [-57.7 16.6]
 [-62.9 -5.8] [-60.4 -5.6] [48.2 -16] [34.9 -17.3] [50.5 -18] [51.8 -15.4] [55 20.9] [40.8 8.2]
 [-63.8 -4.5] [-62.5 21.9] [-39.7 -17] [18 -12.6] [-23.6 6.6] [-30.9 -15.2] [-30.9 -15.3] [25.8
 -20.1] [51.6 -19.8] [35.6 -18.8] [-65.4 15.4] [-37.6 -17] [33.8 -19] [-61.9 -12.3] [-54.4 1.3]
 [-40.3 -21.8] [19.2 -17.2] [-56.2 -14.7] [48.3 19.3] [-83.3 24.8] [-45.3 -11.8] [21.8 -15.3] [-23.9
 -16.2] [-51.5 -10.8] [41.5 -19.5] [-64.5 18.3] [38.5 11.8] [-48.5 -16.7] [55.8 15.7] [-59 -2.3]
 [50.5 -17.7] [-44.8 -14.2] [11.3 3.4] [-73.2 14.4] [-15 -9.1] [39.1 -17.7] [-51.6 -12.2] [-72.7
 15.3] [8.8 5.2] [-65.6 14.1] [43 -18.1] [23.5 -15.2] [-30.8 -10.8] [-54 -5.6] [-42.8 -14.2] [-55.9
 -4.8] [-52.5 15] [-32.5 -14.2] [-74 24] [8.9 8.5] [-51.7 -15.9] [-32.5 -18.1] [53.6 12.4] [12.7
 16.8] [24.8 -14.1] [-9.5 12.8] [-0.7 13.9] [54.6 13] [-63.7 20] [-51.3 -22.3] [7.9 -3.8] [19.8
 -18.2] [-34.3 -6.4] [29.5 -17.6] [-32.8 -23.5] [22.8 -13.6] [50.6 -2.1] [-25.4 -12.8] [-9.6 -7.9]
 [-58.8 3.3] [8.5 -12.7] [-32.8 -23] [49.8 -17.7] [-57.8 -15.5] [15.1 -12.8] [45 -22.7] [46.8 -16.1]
 [30.9 -18.3] [-34.3 -16.9] [34 -21] [42.4 -22.8] [-2.1 13.2] [-34.4 -23.7] [-39 -21.2] [-29.3 -23]
 [49.6 -18.7] [28.5 -16.7] [-9 19.7] [17.2 -16] [-27.6 -17.8] [-19.4 -14.3] [42.7 -19.7] [-28.4
 -15.9] [-9.8 14.7] [-36.2 -19.7] [-41.8 -25.1] [-54.8 -9.8] [27.8 -16.3] [31.9 -20.3] [47.6 -19.7]
 [-9.4 10] [-33.2 -17.5] [-60.4 -14.5] [57.2 15.7] [52.2 -18.7] [35.3 -19.8] [10.2 -14.1] [-43.1
 -16.1] [-33.3 -23.7] [41.9 -24] [58.2 14.1] [-68.7 2.4] [50.8 -18.2] [-8 7.8] [24.1 -19.8] [-61.7
 -15.2] [30.2 -18.8] [-54.5 -15.4] [-58.5 10.6] [-45 -15.1] [-51.2 -11.5] [-55.3 -5.1] [52.1 -17.6]
 [-36.7 -17.1] [-58.4 -12.5] [8.6 11.6] [47.7 -7.7] [-41.5 -20.2] [26.8 -20.7] [-65 23] [39.5 -20.7]
 [32.9 -16.5] [-46.5 -22.1] [-34.5 -23.9] [48.5 -20.6] [-61.5 18.5] [-50.8 -13.7] [-81 24] [20.3
 -18] [51.3 9.4] [14.4 -14] [17.6 -16.7] [-49.8 -13.5] [-68.5 5.4] [-35.8 -12.2] [43.8 -17.3] [22.4
 -16.4] [31.3 -20] [-4 -8.8] [41.6 -22.7] [24 -14.5] [-28.2 -13.7] [44.8 -16.5] [36.7 -21.4] [-60.1
 -10.9] [-39.9 -19.6] [-44.8 -16.5] [41.7 -15.7] [48.9 -16.1] [42.8 -16.1] [-37.3 -21.5] [-74.2
 18.4] [50.4 -18.1] [18.2 -6.9] [-54.7 -16] [17.7 -15.6] [32.2 -20.7] [-20.5 -14.5] [35 -18.2]
 [-47.3 -21.4] [-44 -22.5] [25.1 -17.9] [51.7 12.8] [48.2 -16.6] [-31.5 -16.4] [-31.2 -20.1] [-53.2
 -13.3] [52.9 -18.1] [18.3 -16.6] [-47.4 -15.9] [-39.3 -14] [39.9 -23] [-58.5 -17.2] [-54.7 -17.6]
 [40.1 -15.8] [-49.4 -10.4] [31.7 -21.2] [-58.1 -14.1] [39.6 -13.6] [-41.6 -13.2] [-48.5 -18.8]
 [-35.9 -18.5] [-24.2 -11.1] [36.5 -18.2] [27.1 -17.8] [49 6.5] [-47.4 -22] [48.7 -21.8] [50.1 -15]
 [-69.2 7.6] [-32.6 -14.7] [-24.7 -14.8] [28.6 -13.7] [-60.7 -6.3] [-26.9 -13.2] [-60.5 20.8] [-34.8
 -17.2] [45.9 -16.3] [46.7 17.4] [-43.3 -19.1] [45.9 15.7] [34.2 -18.3] [-34.2 -16.1] [-53.2 -17.6]
 [-32.4 -13.6] [53.6 16.6] [18.1 -18.3] [-21.4 -17.3] [16.1 -14.7] [51.9 -18] [-2.3 10.9] [44.5
 -17.8] [29.3 -15.6] [41.2 -13.7] [40.1 -14.8] [35.7 -18.2] [-61.4 -1.8] [-65.8 9.8] [32.3 -14.7]
 [-37.6 -15.8] [-36.9 -15.1] [-57.9 -21.4] [-29.2 -17.6] [-33.5 -13.2] [-45.8 -17.5] [-66 21.9]
 [-58.7 -15.2] [-74 18.1] [13.7 6.5] [-17.6 -8.5] [-42.8 -13.2] [45.5 -17.9] [-38.4 -23.2] [21.9
 -19.4] [-48.1 -14.2] [4.5 -4.7] [42.3 -15] [35.8 -14.4] [-38.6 -20] [-48.4 -22.5] [-58.6 -5.3]
 [-57.5 7.9] [-14.2 10.9] [27.1 -0.3] [-8.3 -2.4] [35.6 -20.3] [52.3 -19.8] [56.3 9] [48.9 -18.6]
 [-34.6 -19.5] [15.1 -14.6] [-70.6 14.6] [-22.4 5.6] [-44.5 -22.4] [44.2 17.3] [41.5 -20.5] [-10
 18.7] [46 -20.9] [-26.2 -20.2] [38.2 -21.6] [37.9 -20.1] [52 -20.7] [-71.6 12] [42.1 -18] [-47.3
 -18] [-42.8 -18.3] [-37.8 -20.2] [48.5 -3.5] [-22.4 -16.5] [-34 -23.3] [-29 -16.5] [18.1 -17.2]
 [-46 -23.2] [34.9 -14.4] [-50.4 -23.3] [-42.5 -10.8] [49.2 -17.8] [1.7 -8.7] [-59.5 11.6] [-30.8
 -13.2] [46.5 -20.5] [41.9 -21.9] [-43.8 -12.5] [-39.7 -23.5] [50.4 -17.7] [-48.1 -25] [39 -15.7]
 [1.2 16.1] [54.9 13.4] [-25.5 -16.9] [-51.3 -18.8] [-38.9 -13.7] [52.9 -15.5] [-47 -12.8] [-49.7
 -11.3] [15 -13.5] [59.8 3.6] [34 -16.7] [42.7 -22.3] [39.5 -19.9] [36.6 -16.2] [-58.9 -16] [57.6
 8.7] [50.8 18.6] [3.7 -5.1] [-57.5 -19.2] [47.2 -18.8] [61.5 10.5] [-43.8 -22.4] [-70.7 20.6] [-56
 22.8] [-49.8 -12.5] [-46.8 -11.5] [-49.8 -14.7] [-55.3 19.3] [-20.8 9.2] [-50.5 -21.1] [-40.7
 -21.1] [-32.6 -12.4] [-11 14.7] [-53.3 -23.2] [30.4 -20.7] [45.5 -13.9] [27.6 -21.4] [-52.8 -12.2]
 [0.5 9.3] [32 -18.7] [30.2 -22.1] [-37.1 -14.1] [-43 -22.9] [57.5 11.8] [41.2 -22] [24 11] [58.5 1]
 [-34.7 -15.6] [27.7 -18] [35.2 -16.3] [-68.4 20] [34.1 -19.8] [27 -15.2] [22.5 -18.6] [-38.9 -24.7]
 [-61.1 22.2] [16.5 -15.7] [-61 -4.2] [-44.1 -23.9] [-58.8 15.5] [25.8 -19.6] [43.9 -23.9] [-78.6
 23.2] [59.4 13.5] [40.9 -18.4] [59.6 1.4] [-8.8 -9.6] [-5.2 -5] [39.6 -13] [48.8 -15.2] [-50.9
 -22.4] [-42.1 -13.1] [48 -18.5] [65 26] [-47.8 -15.6] [25.7 -14.9] [1.3 -11.1] [-70.1 9.4] [16.7
 -12.5] [-21.8 -13.8] [-71.4 8] [-46.3 -19.1] [-74.8 21] [-40.7 -14.8] [50 -19.5] [51.9 -17.5]
 [-24.2 -9] [23.6 -18.7] [33.6 -21.8] [23.2 -19] [29 -14.6] [44.3 -15.5] [34.1 -16] [48.2 -17.9]
 [56.4 14.6] [-31.1 -22.3] [38 -22] [43.1 -21.4] [-61 20.9] [-58.9 -14.3] [-1.4 2.2] [-40.8 -23.9]
 [-44.5 -11.5] [-67 16.2] [-27.4 -20.8] [-24.6 7.7] [-62.4 -13.9] [31.8 -16.2] [45.6 -19.8] [-36.2
 -13.2] [50.3 16] [27.5 -17.2] [-63.7 8.1] [55.6 17.3] [-60.4 -10.3] [47.1 -17.1] [-55.3 -4.2] [40.1
 -18.1] [22.2 -17.9] [13.4 9.9] [-33.5 -13.8] [19.6 -13.9] [-74.5 25.2] [49.8 -18] [-42.4 -19.5]
 [52.1 5.4] [11.4 -14.8] [53.4 -15.9] [-49.5 -18.4] [-68.1 9.7] [33.6 -21.8] [-41 -12.7] [-45.6
 -16.1] [-21.4 -13.8] [42.6 8.5] [49.9 -17.5] [-34.5 7.2] [36.7 -22.8] [-31.6 6.8] [-68 23] [-80
 22.9] [42.5 -19] [-35.8 -22.8] [-56.4 -20.7] [21.3 -16.8] [-52 -6.8] [-29.6 -14.5] [-60.9 -4.3]
 [-28.8 -17.5] [-59.1 21.6] [-64.5 19.2] [58.2 20] [-70.4 17.1] [30.4 -21.2] [-69 3.1] [-23.4 -8.4]
 [-60.1 -14.3] [-60 -11.8] [45 -21.8] [52.8 7.7] [-50.5 -14.6] [-38.6 -12.8] [53.3 -18.2] [-33.5
 -16] [34.8 -19.3] [49.9 -17.7] [38.5 -21.3] [-28.3 -21.6] [-54 24] [19.8 -17.2] [24.6 -17.3] [51.1
 -15.3] [-3.7 -5.6] [34.9 -14.6] [33.3 -19.1] [30 -17.4] [-46.6 -23.8] [40.7 -17.4] [-67.1 -1.2]
 [-45.2 -20.6] [32.9 -20.8] [-47.4 -19.8] [17.4 8.5] [-30.8 -12.2] [-28.5 -14.2] [35.7 -16.7] [-59.8
 23.4] [-50.6 -22.5] [-38 -24] [-66 16.2] [39.4 -22.2] [2.2 -2.8] [51.5 -18.2] [52.6 13.8] [-20.9
 -15.7] [-45.2 -14.9] [19 -16.5] [-46.8 -24] [61.6 12.4] [30.1 -20.5] [-34.8 -22.9] [-48.3 -17.1]
 [-33.5 -16.2] [-36.3 -20.9] [-42.5 -12.2] [15.5 -15.5] [-28.7 -20.9] [43.7 -20.7] [-29.2 -19.6]
 [-56 -12] [28.5 -18.7] [29.3 -12.8] [-16.9 -8.4] [-7 18.6] [-37.7 -11.8] [-77 23] [-36 -16.8]
 [-24.8 -18.4] [16.2 8.5] [-65 -2.8] [33.4 -22] [-13.4 -8.4] [20.2 -18.5] [-42.2 -25.3] [-36.5
 -24.9] [-59.9 -12.6] [-6.8 -11] [-36.3 -18] [7.7 7] [-38.5 -22.5] [-74.7 22.8] [-20.7 2.7] [37.8
 -19.1] [43.3 1.9] [45 -14.8] [31.2 -10.8] [-43.8 -24.1] [43.5 -14.8] [32.1 -20.7] [34.5 -14] [18.6
 -14.5] [52 -18.9] [57.5 2.9] [-59.3 -7.5] [39.8 -23.1] [-63.4 -3.9] [29.1 -18] [16.5 -14.5] [37
 -22.3] [60 12.2] [-54.5 -20.3] [21.1 -20.1] [-22.6 -15.8] [-34.7 -12.3] [-62.1 -1.4] [25.8 -16.2]
 [28.2 -18.7] [-33.5 -11.2] [22.9 -17.6] [13.8 7.4] [-31.4 -17.9] [41.8 -16.8] [51.5 -18.1] [-37.5
 -25.2] [-8 -7.5] [26.9 -14.4] [-55.5 -5.9] [32.7 -15.3] [6.7 1.2] [-52.5 -11.1] [-32.9 -22.7] [46
 11.8] [-52.6 -22.2] [-40.6 -18.4] [-70.8 8.1] [44.5 -19.9] [-63.5 20.4] [-38.1 -13.8] [-45.2 -10.8]
 [44 -22.4] [-23.3 -17.7] [-51.1 -9.8] [-43.3 -21.2] [52.4 -17.2] [-31.7 -17.4] [43 -14.8] [-56.3
 -13.4] [-54.1 -21.8] [-75.4 22.2] [52.5 -15.8] [-33 -22.3] [-48.3 -17.5] [-62.3 17.9] [-48.7 -11.7]
 [56.7 -5.2] [8.8 2.7] [-26.6 -14.2] [-42.2 -15.2] [49.9 -17.7] [50.5 -21.7] [48.6 -19.6] [85 35]
 [-51.5 -13.2] [0.2 -9.8] [33.1 -16] [-5 8.2] [-60.9 23.6] [-35.3 -26] [-34 -20.3] [40.5 -23.2]
 [-57.9 -20.9] [40.1 -22.6] [-28.3 -16] [18.8 -15.1] [12.6 -14.1] [-58.1 -18.1] [26.5 -16.7] [27.2
 -18.7] [-13.7 8.8] [-9.7 18] [40.9 -15.9] [57 7.4] [-65.8 20.2] [-61.8 -14.7] [-57.6 -5.7] [50.3
 -18.3] [45.2 -20.1] [45.7 13.8] [39 -22] [12.6 10.9] [-74.5 20.1] [-21.9 -17.5] [-33.4 -12.6] [42.1
 -20.8] [-55.5 -11.2] [5.2 -11.9] [-54.6 -22.1] [36.3 -20.8] [-66.3 2.6] [35.8 -22.6] [19.7 8.6] [99
 37] [15 10.6] [7 9.8] [24.2 -20] [49.3 3.4] [-50.9 -17.3] [0.7 -11] [-14.3 12.7] [-61.3 15.9] [16.5
 -14.3] [-27.3 -17.3] [24.4 -20.4] [23.3 -15.5] [63.3 12.7] [-45.8 -13.6] [40 -22] [34 -14.9] [27.8
 6.5] [22.8 -20.1] [25.8 -20.1] [38.9 12.8] [-40.5 -10.8] [-63.1 21] [26.5 -14.1] [-56.8 -19.8] [-2
 -9.9] [-54.6 17.5] [41.2 -20.4] [-43.7 -24.8] [-61.5 -12.6] [-30.3 -11.7] [-52.5 -13.9] [29 -20]
 [37.9 -16.2] [20.8 -19.1] [51.1 -17.2] [20.4 -17.3] [-63.4 4.2] [28.2 -19.6] [-19.1 -14.6] [44.2
 -23] [49.1 -16.8] [35.1 -22] [-63 23.8] [36.1 -15.7] [-32.5 -22] [45.5 -22.3] [47.7 -21] [-1.7
 -8.9] [-20.1 -15.9] [-52.5 -16.7] [-32.9 -24.1] [-32.6 -23.7] [47.3 -20.6] [54.1 -13.7] [23.7
 -20.5] [-56 -5.1] [44.8 6.9] [-35.9 -14.1] [40.7 -21.3] [29.8 -15.9] [-39.8 -23.2] [-64.4 10.8] [-1
 -10.1] [29.9 -20.5] [20.3 -18.4] [13.5 -6.9] [-56.5 13.6] [17.4 -14.8] [59.2 5.8] [-39.6 -24.8]
 [-43 -23.9] [-38.7 -16.1] [-72.6 12.8] [26.1 -16.7] [-49.9 -20.1] [-53.3 -12.3] [32.1 -17.6] [-43.6
 -15] [-57.5 12.5] [-53 -19.7] [-40.7 -22.6] [-39 -14.7] [58.5 10.9] [11 -13.9] [41.7 -14.4] [28.2
 -14.4] [19.2 -18.6] [62.6 16.1] [-57 -20.6] [-40.2 -17.8] [-13.4 12.6] [43.6 -18.4] [-3.7 -2.6]
 [-52.5 -14.2] [18.3 -16.5] [51.9 -16.6] [46.9 -18] [-53.9 -19] [38.5 -20.8] [-65.2 14] [-34.7
 -21.9] [-30.7 -18.6] [50 -11.7] [-11 12.4] [-27.6 -12.6] [-52.5 -17.8] [-30.5 4] [-34.8 -14.1]
 [-27.7 -21] [-26.3 -16.9] [53 16.7] [-32.6 -19.3] [-71.7 12.4] [50.3 12.8] [35.6 -21.7] [-49.1
 -23.8] [57 1.7] [60.9 12.1] [-5.3 12.2] [44.6 -22.7] [42.5 -18.5] [7.5 9.2] [-54.8 6.6] [51.7 9.9]
 [15.3 13.6] [30.9 -15.3] [-58.3 18.5] [-29.9 -16.6] [-36.1 -16.5] [-4 11.8] [-32.5 -15.2] [38.4
 -15.2] [-57.5 -20.1] [62.2 8.3] [-44.1 -19.8] [-62.6 18.6] [-46.8 -11.5] [42.8 -22.8] [-59.1 16.5]
 [-46.8 -16.8] [42.3 -22.8] [17.7 -15.4] [-61.3 12.1] [16.3 -15.9] [-2.5 3.4] [44.3 -18.9] [-38.5
 -18.2] [36.9 -14.8] [12.3 -14.2] [-49.8 -15.5] [-71.3 14.2] [45.2 -21.3] [4.4 12.2] [-39.2 -23.5]
 [-58 -19] [-54.5 -13.4] [43.4 10.5] [-71.1 8.4] [-56.7 12.4] [47 -22.8] [-57.5 14] [38.9 -23]
 [-41.8 -14.2] [-23.9 -19.3] [43.5 -16.8] [-45.1 -12.9] [-24 -14.7] [-64.6 -1.7] [-35 -24.8] [-48.5
 -20.5] [24.8 -19.2] [50.1 -18.5] [35.1 9.4] [24.1 10.1] [-41.5 -23.6] [18.3 -16.8] [-3.4 7.8] [-55
 -14.1] [-22.5 8.4] [5.2 9.4] [-60 24] [-48.8 -20.5] [-57.5 -14.8] [48.5 15] [-36.2 -14.6] [49.9
 -19.2] [38.9 -16.7] [39 -18.8] [-28 -16.7] [-49 -15.2] [-58.8 -20.2] [-26.9 -18.7] [-40.6 -25.4]
 [10.2 3.6] [0.6 13.5] [-32.2 -13.1] [29.2 10] [24.9 -20.4] [15.3 4.7] [-41.5 -14.7] [-38.6 -13.8]
 [-43.7 4.2] [22.3 -16.9] [-55.9 -15.5] [31.8 -21.8] [-42.1 -17.1] [52 -17.6] [-28.9 -12.1] [49.9
 -17.1] [-59.4 20.6] [25.3 -22.8] [29.5 -15.5] [-72.9 16.5] [-63.1 17.5] [-12.4 -4.8] [-52 -22.7]
 [-59 23] [-56.9 -14.4] [33.2 -20.3] [17.7 -15.8] [23.8 7.2] [-54.2 -14.8] [-12.3 18.6] [22.3 -13.9]
 [21 -19] [20.2 -17.8] [-83 24] [-38.7 -17.5] [-42.8 -21.9] [31.8 -20.9] [-62 22] [-39.4 -19.3]
 [-40.5 -16.2] [-26.6 -18.9] [16.3 -3.6] [-61.3 18.1] [19 -13] [-35.7 -21.6] [-17.3 8.2] [21.2
 -14.2] [-39.5 -21.8] [49.7 11.6] [47.7 -21.9] [98 36] [33.4 0.4] [-20.4 -8.5] [15.4 -15.6] [21.8
 -17.6] [30.7 -16.5] [-46 -18] [-54.4 -11.9] [-6.7 2.5] [-47.6 -10.5] [-65.3 -2.4] [-45.2 -26] [9.8
 -3.4] [-24.5 -17.2] [24.5 -19.9] [-47.5 -18.5] [35.5 -22.5] [-41.2 -10.8] [0.1 11.3] [-58.5 -17.9]
 [49.9 9.8] [-45.5 -21] [53.3 10.1] [-16.4 11.6] [-27.5 -9.7] [48.7 6.5] [39.9 -17.1] [-58.5 -16.8]
 [-53.4 -8.4] [51.8 -17.9] [49.6 -18.7] [-55.5 18.1] [51.8 -16.8] [-58.8 -5] [-21.5 -15.2] [46.5
 -15.3] [-39.5 -15.1] [46.2 -16.6] [-13.1 11] [-6.3 -11] [-51.4 -10.9] [-36.6 -24.3] [45.5 -14.6]
 [-56.4 -5.5] [-49.6 -23] [-52.9 -21.6] [-57.7 21.7] [16.9 4.2] [-34.7 -19.8] [25.5 -17.9] [-42.3
 -23.4] [12.4 -13.6] [-10.3 13.2] [-47.2 -14.2] [-42.6 -16.7] [-36.6 -24.6] [-27.3 -19.7] [-36.7
 -16] [-45.2 -16.2] [16.5 10.1] [45.1 -18.6] [32.6 -13.6] [-62.2 -9.8] [-4.8 -11.1] [57.5 10.1]
 [51.2 6.6] [39.2 -14.6] [18.9 -19.1] [2.9 -8.3] [30.8 -20.6] [-2.7 -10.3] [28 -15] [38.5 -16.9]
 [-12.4 -10.7] [41.9 -22.6] [-10.2 10.4] [27 -15.6] [49.9 -19.7] [-31.8 -14.2] [24.4 -22] [40.4
 -18.6] [-74.7 15.3] [8.2 -12.7] [52.4 -17.9] [-57.9 -13.6] [21.9 3.4] [31.3 -17.5] [30.2 -13.7]
 [27.5 -19.9] [51.1 -15.9] [50.1 6.4] [-52.7 -14.8] [20.5 -15.7] [114 -40] [25.7 -20.8] [-42.5 -25]
 [-48.7 -12.7] [-54.7 -21.2] [-10.7 12.9] [52.7 13.9]] [] []] 
  ["Example Layers" 5 [[-50 -9.17 15 2] [33 17.5 45 5] [-58 10.5 45 5] [8 -9.17 15 2] [33 -14.5 0 1]
 [-116 7.17 15 2] [-17 -27.17 0 1] [-99 0.17 0 4] [-25 40 115 3] [50 18.5 45 5] [116 13.17 115 3]
 [-99 -16.5 0 1] [107 40 0 4] [-124 17.83 45 5] [91 40 0 4] [50 3.5 115 3] [-74 14.83 45 5] [25 40 0
 4] [33 -11.83 15 2] [16 11.17 45 5] [99 40 0 4] [58 3.83 115 3] [99 40 15 2] [91 -12.5 0 1] [50 40
 15 2] [124 15.83 115 3] [8 8.17 45 5] [66 -19.17 0 1] [-91 -3.83 15 2] [33 40 0 4] [116 40 15 2]
 [66 15.17 45 5] [-107 4.83 0 4] [41 -14.5 0 1] [-8 40 115 3] [83 12.17 45 5] [83 -3.17 115 3] [116
 -5.5 0 1] [116 25.17 45 5] [-124 12.83 0 4] [-50 9.17 45 5] [83 40 15 2] [-66 12.5 45 5] [-33 40
 115 3] [-33 -10.83 15 2] [74 40 0 4] [-17 -1.83 45 5] [99 -0.83 115 3] [83 -17.17 0 1] [-58 -7.5 15
 2] [41 40 0 4] [8 -17.83 0 1] [107 16.17 45 5] [-116 40 115 3] [16 40 0 4] [-41 40 0 4] [-41 40 115
 3] [0 -21.83 0 1] [124 40 15 2] [25 -14.5 0 1] [16 -9.17 15 2] [-107 40 115 3] [41 -12.83 15 2] [16
 -6.5 115 3] [-33 40 0 4] [-66 -2.5 15 2] [58 -19.17 0 1] [124 -5.17 0 1] [-17 40 115 3] [-124 -6.17
 0 1] [25 -10.5 15 2] [-124 40 115 3] [41 1.17 115 3] [50 40 0 4] [-99 -3.83 15 2] [-66 -23.83 0 1]
 [-74 -19.17 0 1] [-107 16.17 45 5] [-83 15.83 45 5] [74 -19.17 0 1] [66 3.17 115 3] [8 40 0 4] [16
 -14.83 0 1] [25 14.5 45 5] [-107 -14.83 0 1] [-8 -24.5 0 1] [-8 -10.17 15 2] [124 27.5 45 5] [-25
 -29.83 0 1] [-91 14.83 45 5] [50 -18.5 0 1] [-83 40 115 3] [-91 2.5 0 4] [74 -0.5 115 3] [-66 40 0
 4] [-83 -0.17 15 2] [41 18.17 45 5] [-17 -10.5 15 2] [74 40 15 2] [-99 40 115 3] [107 0.83 115 3]
 [-74 2.5 0 4] [-83 4.5 0 4] [-116 16.5 45 5] [66 40 0 4] [-116 11.5 0 4] [-33 -29.83 0 1] [-58 40 0
 4] [-74 1.83 15 2] [-8 -0.5 45 5] [-116 -11.83 0 1] [116 40 0 4] [-50 40 115 3] [0 3.17 45 5] [-25
 40 0 4] [-83 -17.83 0 1] [-58 -26.5 0 1] [-25 -1.83 45 5] [-41 -29.17 0 1] [91 -2.17 115 3] [66 40
 15 2] [-74 40 115 3] [-99 15.17 45 5] [-41 6.83 45 5] [-66 40 115 3] [0 40 0 4] [25 -4.17 115 3]
 [-91 -16.83 0 1] [83 40 0 4] [124 40 0 4] [107 40 15 2] [-91 40 115 3] [-58 40 115 3] [-107 -0.83
 15 2] [91 13.17 45 5] [-33 0.17 45 5] [58 40 15 2] [8 -7.17 115 3] [99 -8.83 0 1] [107 -7.5 0 1]
 [99 13.5 45 5] [74 12.5 45 5] [58 17.83 45 5] [-50 -27.5 0 1] [-25 -11.17 15 2] [58 40 0 4] [0 40
 115 3] [-50 40 0 4] [91 40 15 2] [-41 -9.83 15 2] [-124 7.83 15 2] [-8 40 0 4] [0 -9.17 15 2] [33
 -0.83 115 3] [-17 40 0 4]] [] [] []]] 
  set well-water-dissappears? false
  set Year-duration 730
  set Rain-pattern [10 0 0 0]
  set Prob-rain 0.33
  set evap-prob 0
  
  define-icons                      ; creates the edit and run icons--defines their shape and location.

;  carefully [                    ; read in stored views from the file called 'views'
;    file-open "views"
;    set views file-read 
;    file-close ]
;    [ show "File problems" ] 
      
  set n-groups 1                    ; start with a 'zero group' which creates the sky
  create-handles 1 [                ; group zero has only two handles across the top, used for drawing the sky        
    set point-color sky-color              ; point-color is an internal variable that tells what color this handle governs
    set color sky-color
    set group 0                     ; each handle is assigned to a group. 
    setxy min-pxcor max-pycor
    st]    
  create-handles 1 [                                 
    set point-color sky-color            
    set color sky-color
    set group 0                     
    setxy max-pxcor max-pycor
    st]            
  fill-between 0
  fill-down
  
;    carefully [                    ; read in stored views from the file called 'views'
;    file-open "views"
;    set views file-read 
;    file-close ]
;    [ show "File problems" ] 
  
  draw-view 1    

  create-messages 1 [setxy min-pxcor + 63 * 4 / patch-size max-pycor - 2 set label-color black 
     set label "To use this software, press the ON/OFF button once"]
  set run? false      ; do not start with the model running
  set first-time? true
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;; Main Loop and Button Handlers  ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; the following are the names of the buttons (and the procedures that they call)[and the kind of associated soft buttons]
; ON/OFF (run-groundwater)
; Run (run-simulation) [run]
; Make (make) [make]
; Remove (remove) [remove]
; Save (save-views)
; Pick (pick-model)
; Help (help)


to run-groundwater  ; This is the main program loop--repeatedly called by the ON/OFF forever button
                                               ; this routine advances the model one time step and takes care of soft buttons. 
  every .04 [
    process-icon-presses             ; check the soft keys every .04 sec--executes handler of any key pressed
    set water-amount count dots + count evaps + count well-waters + count spray-waters ]

  if run? [                                    ; all following code advances the model one time-step only if "run?" is true
    set year year + 1 / year-duration          ; uses slider set by authors
    let temp-quarter  ceiling (4 * (year mod 1))
    if temp-quarter != quarter
      [ ;set new-quarter? true
        ;let quarter-ticks year-duration / 4
       ; set-current-plot "Water by Quarter"
        ;set-current-plot-pen "Rain"
        ;plotxy (year - 0.25) month-rain-ct
        ;plotxy year month-rain-ct
        ;set-current-plot-pen "Pump"
        ;plotxy (year - 0.25) month-pump-ct
        ;plotxy (year) month-pump-ct
        ;set-current-plot-pen "ET"
        ;plotxy (year - 0.25) month-ET-ct
        ;plotxy year month-ET-ct
        set month-rain-ct 0
        set month-pump-ct 0
        set month-ET-ct 0
      ]
    set quarter temp-quarter     ; computes the season (quarter)
    
    ;set-current-plot "Water in Ground"
    ;plotxy year count dots with [member? pcolor rock-colors]
       
    ask dots [
    ; first check for evaporation
    ; evaporation from rock or water happens with evap-prob probability; from soil with less, depending on the soil resistance
    ; evaporation can happen only if a dot has empty sky above it, it is on land or soil or it has water below it. 
   
    ; evaporate if (the dot is on land or there is a drop below) and the patch above is unoccupied
      set heading 0                                             ; Later code will move the evap turtle upward. 
      if (([pcolor] of patch-ahead 1) = sky-color) and          ; if the patch above is sky and...
          (not any? dots-on patch-ahead 1) [                    ;    the patch above is empty
            ifelse member? pcolor rock-colors [evaporate]       ; evaporate if the current dot is land  
              [ifelse member? pcolor surface-colors             ; if not on land, it is in the surface?
                [if random resistance pcolor = 0 [evaporate]]   ; evaporate with a probability that depends on the soil resistance      
                [if any? dots-on patch-ahead -1 [evaporate]]]]  ; evaporate if over water (water is on the patch below and the patch ahead is sky-colored)
      
      ; now move the blue dots 
      if pycor > min-pycor + 1 [                                ; trap the turtles on the bottom by skipping the following moves
        ifelse member? pcolor surface-colors                    ; if the current dot is in the surface layer
       
          ; you reach here if the dot is in the surface. Now move it, giving preference for motion within the surface
          [if random resistance pcolor = 0  [                   ; the probability of moving depends on the resistance of the soil   
            set heading 90 * random 4                           ; pick a direction at random  
            if not-any-dots-on-patches-ahead? ds [                ; if the patch ahead is unoccupied
               let ct-ahead unoccupied-patch ds
               let cnum-ahead [pcolor] of patch-ahead ct-ahead         ; get the color of the patch ahead
               ifelse (cnum-ahead = sky-color) and              ; NK change to re-establish surface runoff: if the patch ahead is sky... 
                   (heading != 180)                              ;   and the water dot is not moving down
                 [ jump  ct-ahead ]                                       ; let the dot drip into sky to become surface runoff
                 [ifelse member? cnum-ahead surface-colors      ; if the patch ahead is in the surface....
                   [fd 1]                                       ; .... move there  
                   ; if the patch ahead is not sky or surface, it must be rock. go there using its probablity.  
                   [if (random round ((resistance [pcolor] of patch-ahead 1) / (resistance pcolor))) = 0 [fd 1]]]]]]       
              
              ; repeat a second time if the first patch ahead was occupied. This doubles the speed of dot motion in the surface 
;              [set heading heading + 180                         ; look in the opposite direction for a place to move
 ;               if not any? dots-on patch-ahead  1 [             ; if the patch in this new direction is not occupied
;                  let cnum-ahead [pcolor] of patch-ahead 1       ; get the color of that patch
 ;                 if cnum-ahead != sky-color  [                  ; if the patch ahead is NOT sky       
 ;                   ifelse member? cnum-ahead surface-colors     ; if it is also surface...........
 ;                     [fd 1]                                     ;    move there   
 ;                     [if (random resistance [pcolor] of patch-ahead 1) = 0 [fd 1]]]]]]  ; enter the rock layer using its probablity
                     
         ; you get here is the dot is NOT in the surface layer (and not on the bottom), so it can be rain or in the rock
          [set heading 180                              ; take care of water not in the surface layer
           ifelse any? dots-on patch-ahead 1    
             ; you get here if there are dots on the patch ahead, so the dot cannot move forward
             [ ifelse random 2 = 0  [ set heading 90 ] [ set heading 270 ]  ; if you cannot go forward, check to one side
              if not-any-dots-on-patches-ahead? ds [
                let ct-ahead unoccupied-patch ds
                let cnum [pcolor] of patch-ahead ct-ahead                      ; get the color of the patch ahead
                ifelse cnum = sky-color [jump ct-ahead]   ; if the patch ahead is sky go there, 
                  [if random resistance cnum = 0 [jump ct-ahead ]]]]  ; otherwise go there with a probibility related to the color of that patch
             ; you get here if there are no dots on the patch ahead; the heading is 180. 
             [ifelse  ([pcolor] of patch-ahead 1) = sky-color        ; if the patch ahead is unoccupied and sky colored, go there 
               ; you get here if the patch ahead is unoccupied and blue
               [fd 1]  
               ; you get here if the patch ahead is land and unoccupied            
               [ifelse random 2 = 0               ; if the patch ahead is unoccupied land, first check for blue on one side
               ; pick left or right to check 
                 [ set heading 90 ] [ set heading 270 ]]
               ; even though the patch below is unoccupied, before moving there, see whether the one you are facing is unoccupied sky
               let cnum [pcolor] of patch-ahead 1
               ifelse (cnum = sky-color )         ; took out: (not any? dots-on patch-ahead 1) and 
                 ; even if occupied sky-color, go there, then bubble to surface (NK). 
                 [fd 1 while [ ([pcolor] of patch-here = sky-color) and (count dots-here > 1)] [set ycor ycor + 1]]  
                 [if random resistance cnum = 0 [   ; but if no unoccupied blue, go down with 1/resistance probiblity 
                   set heading 90 + random 181 ; slip left or right a bit
                   fd 1 ]]]]]]                      ; end of "ask dots"                   

   ; adjust rain by season
   let prob .1 * prob-rain * item floor (4 * (year mod 1)) rain-pattern   ;combines author inputs to determine the rainfall this season
   if prob > 0 [                              ; make it rain
     repeat 2 [
       if random round (1 / prob ) = 0 [     ;
        create-dots 1 [
          setxy random-pxcor max-pycor
          set color blue 
;          ifelse mark-rain? [set color mark-color set mark-count mark-count - 1]
;                            [set color blue ]
;          if mark-count <= 0 [set mark-rain? false set mark-count 5]
          set size dot-size
          set shape "circle 2"
          if mark-rain?
            [set mark-rain? false
             set watching? true
             set color mark-color
             set watched-turtle-number who 
             watch-me]
          set month-rain-ct month-rain-ct + 1
       ] ]]]
       
   ; remove some dots if over the max-allowed
    if water-amount > max-allowed [                ; remove water at random from bedrock only (NK change) ;formally from land or lakes
      if any? dots with [pcolor = 0] [                            ; pick a dot at random   
        ask one-of dots with [pcolor = 0] [die-check]]                       ; bedrock = black or 0 
;        ifelse pcolor = sky-color                 ; if it is in the sky...
;          [if ((count dots-at -1 0) + (count dots-at 1 0)) > 1  [die-check] ] ;if surrounded left and right by dots it is probably in a lake, so kill it
;          [if member? pcolor rock-colors [die-check]
            ];]                                              ; if in land, die

    ask pumps with [end? = true ] [                ; for each pump end, convert nearby drops into rising drops 
      let pumpwater dots with [distance myself < 3 ]
      set month-pump-ct month-pump-ct + count pumpwater
      ask pumpwater [ 
        set breed well-waters                      ; convert nearby dots to pump-water, which rises until it encounters a pumphouse
        set shape "circle 2"                       ; green dot in center
        set xcor [xcor] of myself                  ; move the pump-water to the well center
        
        ]]
   ask pumps with  [ end? = false ] [              ; for each pumphouse,  
     ask well-waters with [distance myself < 2 ] 
     [ifelse well-water-dissappears?               ;decide if water will dissappear or be sprayed
     [die-check]                                         ; dissappear
     [ set breed spray-waters                      ; convert well-water into spray water
       set shape "circle 2" set color blue  
       set heading random-between 40 60   
       if (random 2) = 0 [set heading (0 - heading)]                        ; 
       set vx dx * random-between (max-spray-v / 2) max-spray-v
       set vy dy * random-between (max-spray-v / 2) max-spray-v

       set ycor [ycor] of myself + 2]]             ; raise it up over the pumphouse
   ]
    ask well-waters [
      set ycor ycor + .2 ]                          ; rise slowly up the well pipe
  
    ask spray-waters [                             ; move the spray
      set vx .96 * vx                              ; add some friction
      set vy .96 * vy - grav                       ; and gravity
      set xcor xcor + vx
      set ycor ycor + vy
      if pcolor != sky-color [                            ; if spray is not over air, convert to regular water. 
        set breed dots 
        set color blue
        set shape "circle 2"]
      evaporate ]

                                       ; move the evaporated water upward
      if random 3 = 0 [
        let dying-evaps evaps with [ycor + 1 > max-pycor]
        let cnt count dying-evaps
        set month-ET-ct month-ET-ct + cnt
        ask dying-evaps [die-check]
        ask evaps [ 
        set heading ((random 90) - 45)
           fd 1]]
    
    ;this plots the water in the valley
     let n-water count dots with [(pcolor = sky-color) and (ycor < 15) and ((count dots-at -1 -1) + (count dots-at 0 -1) + (count dots-at 1 -1)) >= 2]
     set w-ave n-water
     set w-ave1 .98 * w-ave1 + .02 * w-ave
     ;set-current-plot "Water in Stream"
     ;plotxy year w-ave1 
  
    tick-advance .2]
end

to evaporate 
  if evap-prob = 0 [stop]                            ; avoid the divide-by-zero problem
  if random ((100 / evap-prob) - 1) = 0 [            ; with probability evap-prob (one chance out of 100/evap-prob)
     set breed evaps                                 ; change the dot to an evap
     if color = blue
       [set color 67]
     set shape "circle 2"
     set size dot-size]       
end 

to run-simulation  [ set-state ] ; called once by the run button-- turns on the simulation.
  ask messages [die]        ; kills off the initial message about pressing the on/off button
  set help-message "Press the green arrow to run the model, the orange bars to pause it, and the red icon to restart it."
  ask icons [ifelse kind = "run" [st][ht]]             ; show the 'run' kind
  set run? set-state        ; turn off the simulation
end

to make  ; called by the Make button (used to be "edit" button)
   ask messages [die]        ; kills off the initial message about pressing the on/off button
   set run? false                             ; stop advancing the model
   set help-message "The icons in the upper left allow you to add features to the model"
   ask icons [ifelse kind = "make" [st][ht]]
end

to remove-items  ; called by the Remove button
   set run? false
   set help-message "The icons in the upper left allow you to remove parts to the model"
   ask icons [ifelse kind = "remove" [st][ht]]
end

to save-views        ; called once by the save button. allows the variable "views" to be saved
  ask icons [ht]     ; "views" is a list--each item in this list is a view. 
                     ; a view is a list of all the information needed to reproduce a model, starting with its name. 
  if not user-yes-or-no? (word "Use " view-name " for this view?")
    [set view-name user-input "Please give this view a name"]
  set help-message "You can save your model just by giving it a name"
  
  set view view-data      ; creates a list that completely describes the handles and raindrops of the current view

  ; if view-name is a new name, the new view is appended to views
  ; if the view-name is the same as one used before, the new one repaces the old one
  ; need to get the names
  let names names-of-views                             ; "names-of-views" returns a list of all the current views
  ifelse member? view-name names                       ; is view-name in the list of names? 
    [ let i position view-name names                   ; find the position (i) of view-name in the list of names  
      set views replace-item i views view ]            ; replace the i-th view with the current one
    [ set views lput view views ]  
  carefully [file-delete "views" ][]                   ; delete any old file, if exists
  file-open "views"                                    ; save this new value for views 
  file-write views
  file-close
end

to pick-model                      ; called once by the 'pick' button: lists available models and allows the user to pick one
  let current-view view-data       ; save the current view temporarily. NB: view-data is a reporter 
  clear-view
  let view-titles lput "Cancel pick" names-of-views ; create option list consisting of the names of views plus "Cancel"
  let v pick-view view-titles      ; v is the index of the one selected -1 indicates none selected
  ifelse v < 0  [clear-view make ]  ; this is the "new model" condition--clears and puts up the "make" soft buttons
    [ifelse v + 1 >= length view-titles ; this is the "Return" condition
      [draw-one-view current-view]
      [draw-view v ]]                         ; if a view is selected, draw it, 
  ;clear-plot
  set year 0
  set quarter 0
  run-simulation false                             ; equivalent to pressing the 'run' button
end

to help              ; called once by the 'help' button. 
  user-message help-message  ; Help-messaage is set throughout the code before responding to user input. 
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; pressed icon handlers ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; the following are called ONCE when the user releases a soft key. 
; if any of these require additional user interactions, then they must start with 'show-checkmark', end with restoring the appropriate soft-menu
; and use check-checkmark whenever the code waits for user input. After using check-checkmark, test for user-done? and abort if true. 

; 1. To reset-model
to handle-reset-model   ;called by the "reset model" soft key 
    set help-message "The model has been reset to its initial condition. You can now run it by clicking on the green arrowhead"
    ask dots [die-check]
    ask evaps [die-check]
    ask well-waters [die-check]
    reset-ticks
    set run? false
    set year 0
    set quarter 0
    clear-all-plots
end

; 2. To pause-model
to handle-pause-model   ;called by the "pause model" soft key
  set run? false
  set help-message "The model is now paused. Click on the green arrowhead to resume or the red button to restart it."
end

; 3. To run-model       ; called by the "run model" soft key
to handle-run-model
  set run? true
  set help-message "The model is now running. Note where the water drops go as time goes by."
end

; 4. To click-when-done 
;to handle-click-when-done              ; control should NEVER get here, but this is included just in case
;   ask icons [ifelse kind = saved-kind [st][ht]]       ; shows the last-used kind of softkey.  
;end
  
; 5. To make-layer  
to handle-make-layer                     ; called by the "make layer" soft key
  show-checkmark                         ; puts up a checkmark and records the current kind of soft buttons 
  set help-message "You can pick one of the colors to determine how easily water flows in the layer you are about to make"
    
  ; first, pick a color
  let labels ["select a permeability" "no flow" " easy flow"] 
  pick-swatch rock-colors labels  ; draws swatches, waits for the user to select one, and puts the selected color into swatch-color
  if (user-done? or selected-color = "none") [  ; if the user selects no swatch or clicks the checkmark, exit    
    ask swatches [die] 
    ask icons [ifelse kind = "make" [st][ht]]
    stop]

  ; next draw a layer with the selected color, 'selected-color'
  create-messages 1 [
    setxy .2 * max-pxcor max-pycor - 5
    set label-color black
    set label "Now sketch the top of the new layer."]
  set help-message "You can now draw a new layer"
  new-layer                            ; sketch in the new layer
  ask messages [die]    
  ask icons [ifelse kind = "make" [st][ht]]    ; turn on the edit icons
end

; 6. To handle-edit-layer
to handle-edit-layer ; called by the edit layer soft key
  show-checkmark                         ; puts up a checkmark and records the current kind of soft buttons 
  create-messages 1 [
    setxy .2 * max-pxcor max-pycor - 5
    set label-color black
    set label "Click on a square dot in a layer you want to edit"]
  edit-layer
  ask messages [die]
  ask icons [ifelse kind = "make" [st][ht]]    ; turn on the edit icons
end

; 7. To add-soil
to handle-add-soil    ; handle the add-soil soft key
  show-checkmark
  set help-message "Pick one of the surface types colors by clicking. Then you can paint this on the top of your rock layers"
  let colors surface-colors             ; defined in startup
  let labels ["select the surface type" "rich humus" "clay"] 
  pick-swatch colors labels  ; draws swatches and puts the selected color into swatch-color
  if (user-done? or selected-color = "none") [
    ask swatches [die] 
    ask icons [ifelse kind = "make" [st][ht]]
    stop]
  set help-message "You have selected a surface type, now leave this soil near the top of your rock layers by clicking and dragging"
  if not user-done? [draw-surface selected-color]
  ask icons [ifelse kind = "make" [st][ht]]    ; turn on the edit icons
end

; 8. To add-water
to handle-add-water                                        ; handle the add-water soft key    
  show-checkmark
  set help-message "Use the mouse to add ground water."
  while [not user-done?] [                                 ; repeat until the user checks the checkmark
    if mouse-down? and inside-area? [                      ; if the mouse is down and inside the work area
      let x mouse-xcor
      let y mouse-ycor 
      let y1 y - 2
      while [y1 <= y + 2] [                                   ; draw dots two above and below the cursor
        if y1 > min-pycor and y1 < max-pycor [
          if (not any? dots-on patch x y1) and 
            ([pcolor] of patch x y1) != sky-color [                  ; if the patch is unoccupied and not sky
              create-dots 1 [                                 ; create a dot
                setxy x y1
                set color blue
                set size dot-size
                set shape "circle 2"]]]
      set y1 y1 + 1 ]]
    check-checkmark ]                                       ; check the checkmark
  ask icons [ifelse kind = "make" [st][ht]]                 ; when done, turn on the edit icons
end 

; 9. To set-climate
to handle-set-climate                  ; handle the set-climate soft key. INCOMPLETE
  set help-message "Pick one of the colors to select the level of climate in your model"
  let colors [63 64 65 66 67 68 58 48 47] 
  let labels ["select the climate" "rain forest" "desert"] 
  pick-swatch colors labels  ; draws swatches and puts the selected color into c
  ; code needed here--do something with "selected-color"
  ask swatches [die]
  ask icons [ifelse kind = "make" [st][ht]]    ; turn on the edit icons
end

; 10. To add-well  
to handle-add-well       ; handles the "add well" soft key
  set help-message "Click on the inlet where the water enters the well, deep below the surface."
  create-messages 1 [
    setxy .2 * max-pxcor max-pycor - 5
    set label-color black
    set label "Click where you want the pump inlet"]
  
  show-checkmark  
  let pump-x 0  let pump-y 0 let y 0
  let above? true           ; set true if the user clicks above the surface
  while [above?] [
    while [not (mouse-down? and mouse-inside?)] [
      wait .04                   ; wait for the user to click
      check-checkmark 
      if user-done? [            ; if clicked over the checkmark, abort
        ask messages [die]
        ask icons [ifelse kind = "make" [st][ht]]
        stop]]  
  ; record the x location, work down from the top to find the surface and place the pumphouse there. Then drill down to the y-value
    set pump-x mouse-xcor
    set pump-y mouse-ycor
    set y max-pycor
    while [[pcolor] of patch pump-x y  = sky-color ][
      set y y - 1 ]
    set y y + 1
    ifelse y < pump-y 
      [ set above? true
        set help-message "Click below the surface, where you want the lower end of the pump." 
        ask messages [die]
        create-messages 1 [
          setxy .2 * max-pxcor max-pycor - 5
          set label-color red
          set label "Click below the surface, where water enters the well below ground."]]
      [ set above? false ]
  ]    ; loops back if the user selected a place above the surface
  let pump-who 0
  create-pumps 1 [
    set pump-who who
    setxy pump-x y 
    set size 5 
    set color white
    set end? false
    set shape "pumphouse"]
  create-fillers 1 [
    setxy pump-x y 
    hide-turtle
    pen-down 
    set color white ]
  ask fillers [
    while [ycor > pump-y ] [
      set ycor ycor - .002 ]]       ; slowly drill well
  ask fillers [die]                 ; leave the turtle track to show the well
  create-pumps 1 [                  ; this is where the water flows into the well
    setxy pump-x pump-y
    ht
    set end? true ]
  ask messages [die]
  ask icons [ifelse kind = "make" [st][ht]]    ; turn on the edit icons
end

; 11. To add-pipes     INCOMPLETE
to handle-add-pipes
end

; 12. To remove-layer
to handle-remove-layer   ; handle the remove-layer soft key                                         
  create-messages 1 [
    setxy .2 * max-pxcor max-pycor - 5
    set label-color black
    set label "Remove a layer by clicking on its upper surface."]
  set help-message "Click near a black square to remove it"
  remove-layer
  ask icons [ifelse kind = "remove" [st][ht]]    ; turn on the edit icons
end

; 13. To remove-soil     
to handle-remove-soil     ; handles remove-soil soft key
  ask patches [
    if member? pcolor surface-colors [
      set pcolor sky-color]]
end      

; 14. To remove-well
to handle-remove-well      ; handles the "remove well" soft key
  clear-drawing
  ask pumps [die]
  ask well-waters [die]
end

; 15. To remove-pipes        INCOMPLETE
to handle-remove-pipes
end

; 16. To clear-screen     
to handle-clear-screen         ; handle 'clear screen' soft key
  if "Yes, clear the screen and eliminate this model" = user-one-of 
    "Clear the screen and loose the current model?  "  
       ["Yes, clear the screen and eliminate this model" "No, do not clear the screen. Do nothing."] [
         clear-view 
         if length views > 0 [                               ; get the index of this view in views
           let i position view-name names-of-views
;           set view-name 0                             ; use the name of this view as the current name
           if i != length views [                            ; unless the view being eliminated is the last one in views
             let v last views                                ; move the last view into the position of the one to be eliminated
             set views replace-item i views v ]              ; overwrite the eliminated view with the last one
           set views but-last views ]                        ; remove the last view
         run-simulation false ]        ; acts as though the run button was pressed--shows icons and waits]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;  Sketching routines  ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; the turtles called "handles" completely define a view--handy for saving and restoring. Just fill-between for each group and fill-down
to new-layer  
;  show-checkmark       
     ; first, create a new group of handles from which the geologic layers are constructed 
  ask dots [die-check]     
  set n-groups n-groups + 1                      ; add a new group of handles  
  ask handles [ht]                               ; hide all current handles
  display                                        ; the number of handles in the sketch (N-1 intervals)
  let du (max-pxcor - ( .1 + min-pxcor)) / (n-handles - 1)        ; separation of handles (the .1 is needed to give the user access to the right-most dot)
  let u min-pxcor
  while [u <= max-pxcor ] [
     create-handles 1 [                          ; create the handles, give them u-values but hide them and put them at v=0         
       set point-color selected-color              ; point-color is an internal variable that tells what color this black handle governs
       set color black
       set size handle-size
       set shape "square" 
       setxy round u max-pycor 
       set group n-groups                        ; assign each to a unique group number 
       ht]                                       ; assign each handle to one of the nTics horizontal positions
     set u u + du ]
   edit-group n-groups                           ; support the user interaction with this group.    
end

to edit-layer                 ; figures out which layer the user wants to edit (the one nearest at the first click)
   ask dots [die-check]         ; and then supports the editing of that layer using edit-group n
   if n-groups = 0 [stop]
   set help-message "Click on a black dot at the top of a layer that you want to edit. Then drag the dots up or down." 
   let g closest-group     ; edit the group of handles indicated by the one closest to the next mouse-down event
   ask messages [die]
   if user-done? [stop]
   create-messages 1 [
     setxy .2 * max-pxcor max-pycor - 5
     set label-color black
     set label "Now sketch where you want the top of the layer to be."]
   edit-group g
end

to-report closest-group
   ask handles with [ycor < max-pycor ] [st]         ; show all turtles except any lurking at the top
   display
   while [not (inside-area? and mouse-down?)] [           ; wait until the user clicks in the view after pressing the edit button
      wait .04
      check-checkmark]                                ; but look for user checking the checkmark
   if user-done? [stop]
   let g 0
   if inside-area? [                                  ; do the following when the user first clicks inside the view
     let x mouse-xcor
     let y mouse-ycor
     let dist 1e20                                     ; this will become the distance to the closest handle
     let nearest 0
     ask handles [                                     ; check with all the handles, regardless of group
       ht                                              ; hide the handles 
       let d distancexy x y                            ; get the distance to the mouse
       if  d < dist [                                  ; if this handle is closer to the mouse than any so far
         set nearest who                               ; save its who and distance
         set dist d ]]
     set g [group] of handle nearest]                  ; at this point nearest holds the who of the closest handle
   report g                                            ; the group number of this nearest handle is reported 
end

to edit-group [n]                                       ; supports the user interactions with group n of handles  
  ask handles with [group = n and pycor < max-pycor][st]  ; show the group being edited
  let du (max-pxcor - ( .1 + min-pxcor)) / (n-handles - 1)
  while [not user-done?][                                     ; do  the following until the the mouse leaves the view
    check-checkmark
    if (mouse-down? and inside-area? ) [                    ; collect data while the mouse is down
      let u mouse-xcor
      let v mouse-ycor
      ask handles with [group = n and 
         abs( u - xcor ) < du / 2]  [                   ; find a handle with u-value nearest the cursor 
            set ycor v                                  ; move the selected handle to the cursor position and show it
            st ]
      fill-between n                                    ; fill small dots between the handles. Fills all points in this group--wasteful, but time is not a factor.
      fill-down                                         ; fills the background down to the bottom or the next-lower set of points for all groups
      display ]       
    ]                                                   ; loop back to "while" until the OK button is clicked 
  ask handles [ht]                                      ; hide all the handles when the user leaves the view
end

to fill-between [n]                                    ; fills small dots between handles of group n
  let cnum [point-color] of one-of handles with [group = n]  ; get the color of the layer coded by these handles
  let du 1                                             ; make small dots for each patch--du here is the distance between patches
  let coords [ ]                                       ; this will be the list of u-v coordinates of the visible big dots
  ask handles with [group = n and not hidden?][        ; convert the handles of group n to a list of u-v coordinates
      let pair list xcor ycor
      set coords fput pair coords  ]                   ; add the u-v pair to the the list coords 
  if length coords < 2 [stop]                          ; exit this fill routine if there are fewer than two handles
  set coords order-list coords                         ; put the u-v pairs in order of increasing u
  let i 0
  ask points with [group = n ][die]                    ; remove any points previously shown, leaving only handles
  while [i < ((length coords) - 1)][                   ; draw a line from each dot to the next starting with dot 0 (to dot 1) up to N-2 (to dot N-1)
    let pair1 item i coords
    let pair2 item (i + 1) coords
    let u0 first pair1
    let v0 last pair1
    let u1 first pair2
    let v1 last pair2
    let u u0 
    while [u <= u1] [                                    ; fill in the region between point i and i+1
      let v v0 + (u - u0)*(v1 - v0)/(u1 - u0)           ; a linear interpolation between the points
      create-points 1 [                                   ; create a small dot
         setxy u v
         set color cnum 
         set size 1
         set shape "circle" 
         set group n
      ]
      set u u + du
    ]
    set i i + 1
  ]
end

to fill-down   ; fills patches down from points drawn between handles using their color, stopping when another point is encountered, or the bottom. 
;  clear-patches
  ask patches [set pcolor sky-color]
  ask points [
    set pcolor color                               ; set the color of the starting patch where the point lives
    hatch-fillers 1 [                              ; create a temporary filler turtle whose job is to run down to the next point and die, 
      set ycor round ycor                          ; painting the patches it encounters with its color, inhereted from the point it started at
      set heading 180  ; aim down
      while [(not any? points-on patch-ahead 1) 
        and ( ycor > min-pycor )] [
          fd 1
          set pcolor color ]
        die ]
    ]
;  ask points [die]
end
  
to-report order-list [i-list]   ; takes a list of sub-lists and returns a list with the same sub-lists 
  ; but in order of ascending values of the first element in each sublist 
;  if length i-list = 0 [stop]
  let o-list [ ]  ; this will be the output list
  let temp-token [ ]  ; this holds the sublist as it is being passed from the input list to the output one
  let n length i-list ; this is the number of sub-lists
  while [ n > 1 ][ ; repeat the following as long as there are two or more sub-lists...
    let index-of-smallest 0  ; find the sublist with the smallest first element, add the sub-list to the end of temp-list
                             ;         and remove it from i-list
    let x0-of-smallest first first i-list  ; x0 is the first element in each sub-list in i-list
    let j 1   ; this will be the index into token-list of the token being tested
    while [j < n] [
      let x0-next first item j i-list
      if  x0-next < x0-of-smallest [
        set index-of-smallest j
        set x0-of-smallest x0-next ]
      set j j + 1 ]
    set temp-token item index-of-smallest i-list      ; at this point, index-of-smallest contains the index of the token with the smallest x0
    set o-list lput temp-token o-list  ; tack the new token on the end
    set i-list remove-item index-of-smallest i-list   ; take this out of i-list
    set n n - 1 ]
  report lput first i-list o-list         ; this is tricky--after all the tests, one sub-list remains in i-list,
end

to remove-layer    
  ask dots [die-check]  
  let removed-group closest-group                    ; get the number of the group to be removed--the first clicked by the user
  ask handles with [group = removed-group ]          ; kill off the corresponding handles
    [die]    
  ask handles with [group = n-groups ]               ; move the last group into the vacated group number
    [set group removed-group ]
  set n-groups n-groups - 1                          ; 
  ask points [die]                                   ; kill off all the points
  restore-geology                                    ; redraws the entire screen from the handles
  make                                                ; returns the 'make' icons
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;  save and restore views ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; the file "views" contains a single variable also called 'views' 
; all data needed for 20 views are stored in the variable 'views'
; views is a list of 20 items. Each item contains all the information needed to reconstruct one view
; each item of views is a view
; each view is a list of two itmes
; the first item of view is the number of groups of handles in that view
; the second item of view is a list of handle descriptors
; each handle descriptor is a list consisting of four items.
; the items in a handle descriptor are xcor, ycor, point-color, and group



to-report view-data
  ; the current format for the data in the view consists of five items
  ; item 0 is the view name
  ; item 1 is the number of groups of handles
  ; item 2 is a list of handles each consisting of a list: [x, y, color, group number]
  ; item 3 is a list of water drops each consisting of a list [x, y]
  ; item 4 is a list of patches at the top of any surfaces [x, y, color]
  ; item 5 is a list of well turtles: [x, y, end?]  
  
  
    ; first package all the handles into the list 'h-data'
  let h-data [ ]
  ask handles [
    let x precision xcor 2    ; reduces unnecessary precision
    let y precision ycor 2    ; useful if the list is saved as text. 
    set h-data lput (list x y point-color group ) h-data ] ; save all handles into view

  ; now package all the x,y coordinates of the rain dots, if any
  let dot-data [ ]    ; this will hold a list of rain dots
  ask dots [
    let x precision xcor 1   
    let y precision ycor 1   
    set dot-data lput list x y dot-data ]
  
  ;now package all the surface data. save the coordinates and color of all surface paches next to the sky. 
  let patch-data []
  ask patches [
    if (member? pcolor surface-colors) and       ; if this patch is a surface and...
       ([pcolor] of (patch-at 0 1) = sky-color)[            ;  the patch above is sky
       set patch-data fput (list pxcor pycor pcolor) patch-data] ] ; add the triplet x, y, color to the patch-data list 
  
  ; finally, package up any pump data, marked by the top and bottom of each. 
  let pump-data [ ]
  ask pumps [
    set pump-data fput (list (round pxcor) (round pycor) end?) pump-data]  ; add triplet x, y, and end? to the pump data. 
    
  ; now create the view by combining into one list the view-name, the number of groups.....
  report (list view-name n-groups h-data dot-data patch-data pump-data)      ;   and the handle, dot, surface, and pump data
  ; this returns the current view as [view-name n-groups [handles][dots][surface-patches][pumps]]
  ; later, if there is a call for it, I could add all water
end

to-report names-of-views
  let names [ ]
  let i 0
  repeat length views [
    set names lput (first item i views) names          ; place the names of all current views into "names" in the order that they occur
    set i i + 1 ]
  report names
end

to clear-view 
  clear-turtles                                      ; clear everything
  clear-patches
  clear-drawing
  set n-groups 0
  ask patches [ set pcolor sky-color ]                      ; sky color
  define-icons                                       ; needed because they were just wiped out with all the turtles!!
end

to draw-view [n]                                      ; reads the view n from views (a global)
  if not empty? views [                               ; skip this if views is empty
    set view item n views
    if empty? view [stop]
    clear-view
    draw-one-view view ]    
end   
    
to draw-one-view [v-list]   
  
  set view-name first v-list                         ; the name of the view is the first item in the v-list
  set n-groups item 1 v-list                         ; the next item saved is the number of groups of handles in this view
  if n-groups = 1 [
    clear-view
    stop]  
                                                       ; this is possible if a blank page was saved
    ; draw the rocks
    let h-list item 2 v-list                           ; locate  the list of handles
    while [not empty? h-list][                         ; take the first list in h-list, this describes one handle
      let h first h-list
      set h-list but-first h-list                      ; remove this handle from the list in h-list
      create-handles 1 [
        setxy first h item 1 h                         ; assign the first to items to the x-y position of the handle
        set point-color item 2 h                       ; give it the right point-color (its actual color is black)
        set group item 3 h                             ; this is the group to which this handle belongs
        set color black
        set shape "square" 
        set size handle-size
        ht]]                                           ; hide the handle
    restore-geology                                    ; redraw the sub-surface from the handles. 
    
    ; draw the water dots
    let d-list item 3 v-list                           ; the list of dot locations
    while [not empty? d-list][
      let d first d-list                               ; the [x y] for the first dot
      set d-list bf d-list                             ; knock off the first x-y pair
      create-dots 1 [                                  ; create the dot and place it
        setxy first d last d
        set color blue
        set shape "circle 2"
        set size dot-size ]] 

  ; draw the surfaces
  if length v-list > 3 [                     ; useful in upgrading from earlier versions that didn't store this information (can be removed later)
    let s-list item 4 v-list                         ; the list of the top surface patches   
    while [not empty? s-list ][
      let s first s-list
      let x first s let y item 1 s
      let cnum item 2 s
      repeat 4 [                                    ; fill in the patch at x, y and those below it. 
        ask patch x y [if pcolor = sky-color [set pcolor cnum]]
        set y y - 1 ]
      set s-list bf s-list]]                         ; chop off the completed section of surface        

  ; draw the pumps
  if length v-list > 5 [
    let p-list item 5 v-list                         ; the list of pumps  
    while [not empty? p-list ][
      let p first p-list
      let x first p let y item 1 p 
      create-pumps 1 [
        setxy x y 
        set color white
        set shape "pumphouse"
        set heading 0
        set size 5
        set end? item 2 p
        if (end?)  [ht] ]                            ; if this is the lower end of the pump...
      set p-list bf p-list ]
    ; now draw in the pump line
    ask pumps with [end?][                           ; repeat for all the well inlets
      let y0 ycor                                    ; save the y-coordinate of the end
      ask pumps with [not end? and abs (xcor - [xcor] of myself) < .1 ][   ; find the pumphouse just above
        let y1 ycor                                  ; save the pumphouse y-cor         
        set color white
        setxy xcor y0
        pd fd y1 - y0 ]]]                             ; have the pumphouse draw upward the distance between the inlet and pumphouse
end

to restore-geology                                   ; uses the handles to create the scene
  if n-groups = 0 [clear-view stop]
  let i 1
  while [i <= n-groups] [
    ask handles with [pycor < max-pycor ][st]
    fill-between i 
    set i i + 1]                                     ; adds points between the handles
  fill-down                                          ; fills the patches down from the points
  ask handles [ht]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;   soft UI support   ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to process-icon-presses                   ; this is called repeatedly from the main loop. 
  ; until an icon is pressed, this handels the roll-overs
  ; once an icon is pressed, this procedure delays until the user releases the soft key and then calls the selected handler 
  let val "none"                          ; val will contain the name of the most recently pressed icon
  let radius .55 * icon-size              ; half-hight of the icons
  let x 0 let y 0 let t ""                ; local variables needed to extract values from icons and pass them to the roll-over code
  ask icons [                             ; icons are the soft buttons only
    if not hidden? and                    ; if this is hidden, some other code has disabled this icon
        abs (xcor - mouse-xcor) <= radius and    ; if the mouse is near this visible icon......
        abs (ycor - mouse-ycor) <= radius [
        ifelse mouse-down?                ; if the mouse is down, the user has pressed this icon.....
          [set val shape                  ; val is the shape of the icon currently pressed (this is the icon's name, but with hyphens)
          set color pressed-icon-color ]  ; turn the pressed icon background darker to provide user feedback that the press is noticed   
          [set x xcor set y ycor          ; if the mouse is not down but over an icon, note coordinates for roll-over
          set t name  ]]]                 ; the name of the icon--a non-blank t initiates a roll-over in the code below
  
                                          ; show roll-overs
  ask roll-overs [die]                    ; kill off any old roll-overs
  if t != "" [                            ; code for roll-overs (if there is a name...)
    create-roll-overs 1 [
      set size 0                          ; don't show the turtles (but don't hide them, or the label won't show.
      setxy (x + (2.8 * length t) / patch-size)  y - 24 / patch-size
      set label-color black
      set label t ]]
  
  ; now take care of the pressed key, which has the hyphenated name "val"
  if val != "none" [                               ; "none" indicates that the user has NOT pressed a soft key, so skip to the end      
    while [mouse-down?] [ wait .04 ]               ; if a key was pressed, wait until the user releases the soft button
      ask icons [set color default-icon-color]     ; reset the icon color
    run word "handle-" val]                        ; execute the key's handler (always shape with "handle-" prefixed)
end

to define-icons
  let icon-list [                  
    ["run" "reset model" "pause model" "run model"]
    ["check" "click when done"]
    ["make" "make layer" "edit layer" "add soil" "add water" "set climate" "add well" "add pipes"]
    ["remove" "remove layer" "remove soil" "remove well" "remove pipes" "clear screen"]
  ] 
    ; The syntax here is that icon-list is a list of soft key buttons. Each button has a kind, that is the first item in each button list.
    ; The subsequent items are the names for each type in order that they appear. There must be a turtle for each shape but the turtle shapes must be single words.
    ; The software replaces spaces in the names with hyphens to make executable code--these hyphenated versions are also used for the names of the shapes. 
    ; When the button is pressed, it passes control to a procedure of that name. 
    ; The name (with spaces) used to generate the text used as the roll-over. 
    ; Thus the name and roll-over "pause model" is converted into "pause-model" which is the shape as well as the executable code. 
    ; In this example, there must be a shape and a procedure named "pause-model" 

  let icon-separation 1.2 * icon-size
  let y max-pycor - .6 * icon-size  ; vertical center of icons
  let x-start min-pxcor + icon-size * 4 / patch-size 
  let icon-x x-start                   ; used to determine the right-most edge of the longest group of icons
  while [length icon-list > 0 ][       ; repeat for each group of icons in the icon-list
    let icon-group first icon-list     ; icon-group contains all the information for a group of icons of one kind that are displayed together. 
    let icon-kind first icon-group     ; icon-kind is the kind of icon, the name of the group
    set icon-group bf icon-group       ; knock off the kind, leaving a list of icon shapes
    let x x-start                      ; this is the x-location of the first icon in the icon-group
    while [length icon-group > 0 ][
      if x > icon-x [set icon-x x]     ; keep track of the center of the right-most icon in all groups
      create-icons 1 [ ht
        set name first icon-group      ; the first item in icon-group now, is the name of the next icon to be defined
        set kind icon-kind             ; picked up from the first item in each list
        setxy x y
        let start-thing name                 ; start-thing will be transferred to end-thing letter by letter, 
        let end-thing ""                     ; ...but changing any spaces into hyphens
        while [length start-thing > 0][          ; go through the letters in the current name
          let letter first start-thing
          if letter = " " [set letter "-"]       ; if this letter is a space, change it into a dash
          set end-thing word end-thing letter    ; tack letter onto the end of end-thing
          set start-thing bf start-thing ]       ; knock off the first letter of start-thing
        set shape end-thing                      ; now end-thing should be the same as the name but with hyphens, later to be used to call a procedue using "run shape"
        ]                                        ; code now contains the code executed 
      set icon-group bf icon-group               ; knock off the first item in the icon-group to get ready to repeat defining icons
      set x x + icon-separation]
    set icon-list bf icon-list]                  ; repeat for the next set of icons
  set icon-zone list (icon-x + .5 * icon-separation) (y - .5 * icon-separation)  ; this is the right-most of the longest set of icons. Used to exclude user clicks. 
  ; in a better world, icon-zone would depend on the number of icons in a menu.
  ask icons [                                    ; all icons will have the following properties
    set size icon-size
    set color default-icon-color   
    set heading 0 ht]
end

to-report inside-area?   ; reports true if mouse is inside the view but not in the edit button area
  report mouse-inside? and (not ((mouse-xcor < first icon-zone ) and (mouse-ycor > last icon-zone))) 
end
  
to pick-swatch [swatch-colors labels]  ; creates a spectrum of swatches using the list passed
  ; each item in the swatch-colors list is a color number of one swatch in order from left to right
  ; this returns the color number that the user selects and then turns off the swatches
  ; if the user clicks outside the spectrum, the color returned is "none"
  ; "labels" is a list of three labels for the instructions, left and right ends of the spectrum
  ask swatches [die]               ; needed???
  let s-size .7 * icon-size 
  let x-start .5 * min-pycor  ; start swatches to the left of center of the screen
  let x x-start
  let y max-pycor - 3 
  let color-list swatch-colors
  create-swatches 1 [                  ; create the instructions
    set label first labels
    let xc x-start + (.5 * length label) + (.55 * s-size * length color-list)
    setxy xc y - .8 * s-size 
    set label-color black
    st ]
  set labels but-first labels
  create-swatches 1 [                  ; create the first label
    set label first labels
    setxy x y
    set label-color black
    st ]
  set x x + .5 * s-size + .3 * length first labels
  while [not empty? color-list ][       ; create the swatch spectrum
    create-swatches 1 [setxy x y set color first color-list
    set x x + s-size * .9
    set color-list bf color-list 
    set size s-size
    st set heading 0 
    set shape "square 3"]]
  create-swatches 1 [                  ; create the last label
    set label last labels
    setxy (x + 1.2 * length last labels) y  set label-color black
    st ]
  
  ; at this point, the swatches are visible, and the software waits for the user to pick one
  set selected-color"none"
  let radius s-size / 2 
  while [not mouse-down? ][ 
    wait .04                  ; wait for a mouse click 
    check-checkmark          ; or for the user to abort
    if user-done? [stop]]        ; 'user-done?' is set by 'check-checkmark'@@@@@@@@@@@@@@@@@@@@@@@@
  if inside-area?            ; the user needs to stay inside the view
     [ask swatches [          ; you get here if the mouse is down inside the view
        if abs (xcor - mouse-xcor) <= radius and
           abs (ycor - mouse-ycor) <= radius [      ; this is the swatch nearest the mouse
             set selected-color color ]
        ]]
  while [mouse-down?] [wait .04]         ; idle until mouse-up occurs
  ask swatches [die]
end

to-report pick-view [view-titles]    ; waits for the user to pick a view or wander outside the view-screen
  ; reports the index of the selected view or -1 if none
  ; list the possible views that a user can select
  ask messages [die] ask squares [die] 
  create-messages 1 [setxy min-pxcor + 172 / patch-size max-pycor - 8 / patch-size set label-color black 
    set label "Pick a view by clicking on a square:"]
  let x min-pxcor + 160 / patch-size
  let y max-pycor - 24 / patch-size
  let i 0
  while [length view-titles > 0 ][
    if y < min-pycor + 5 [       ; bump over to a new column before hitting the bottom
      set y max-pycor - 6
      set x x + 320 / patch-size  ]
    show-view-titles i x y first view-titles
    set y y - 5
    set view-titles but-first view-titles 
    set i i + 1]   
  
  ; at this point, the list of views is visible and waiting.
  let r -1
  let selected? false 
  while [mouse-down? ][ wait .04 ]  ; wait for the user to get off the button that resulted in switching to this proceedure    
  while [not mouse-inside? ][ wait .04 ]    ; wait for the user to move into the viw                                                                                                                                                                             ]        ; wait for the user to release the button that resulted in calling this routine
  while [not selected? ] [         ; wait for the user to pick an item
    if not mouse-inside? [         ; the user needs to stay inside the view
      set selected? true ]
    if mouse-down? [
      ask squares [
        let d distancexy mouse-xcor mouse-ycor    ; the user has to be near the checkbox
        ifelse d < 3 [             ; this is the icon nearest to the user 
          set selected? true  
          set r index ]
        [ set selected? true ]      ; if not near any icon, pop out 
        ]]]

  ; now clean up and exit
  ask messages [die]   
  ask squares [die]   
  report r
end
  
to show-view-titles [i x y mess]           ; creates a message preceded by a checkbox that is located at x,y
  create-messages 1 [setxy (x - 12 / patch-size)  y
    set label-color black 
    set label mess]
  create-squares 1 [setxy x y set shape "checkbox" 
    set size 4 set heading 0 
    set color default-icon-color 
    set index i]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;  Drawing support   ;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report resistance [cnum]    ; 1/resistance is the prob of going down, it is like a resistance to flow

  ; rock colors
  if cnum = 15  [report 20]    ; red 15
  if cnum = 45  [report 80]   ; yellow is 45
  if cnum = 125 [report 180]   ; magenta is 125  
  if cnum = 115 [report 260]   ; violet is 115
  if cnum = 0   [report 10000] ; black is 0 
  
  ; surface colors
  if cnum = 26  [report 2]     ; orange is 26
  if cnum = 29  [report 4]     ; washed out orange is 29
  if cnum = 37  [report 8]     ; light brown is 37
  if cnum = 34  [report 16]    ; darker brown is 37
  if cnum = 31  [report 32]    ; very dark brown almost black is 31 
  
  ; currently unused
;  if cnum = 9.9 [report 2 ]    ; white is 9.9 (a bog?)
;  if cnum = 85  [report 5 ]    ; cyan is 85 (a wetland?)
;  if cnum = 35  [report 7 ]    ; brown is 35 (agricultural?)
;  if cnum = 55  [report 8 ]    ; green is 55 (a forest?)
;  if cnum = 75  [report 10]    ; turquoise is 75 (soapstone?)
;  if cnum = 65  [report 15]    ; lime is 65
;  if cnum = 25  [report 30]    ; orange is 25
;  if cnum = 135 [report 70]    ; pink is 135
;  if cnum = 5   [report 2000]  ; gray is 5

  report 1                     ; the sky or anything else is 100% probable
end

to draw-surface [cnum] ; user paints the surface with dirt of color cnum  
  create-messages 1 [setxy 0 max-pycor - 2 set label-color black 
     set label "Drag the mouse slowly over the land"]
  create-messages 1 [setxy 0 max-pycor - 6 set label-color black 
     set label "Then, click the checkmark when you are done with this surface"]
  while [not mouse-down?][
    wait .04 ; wait for the user to click
    check-checkmark  
    if user-done? [
      ask messages [die]
      stop]]
  ; Only four or fewer pixels can be dropped onto top of rocks. 
  ; The surface must be one of the colors in surface-colors and not a rock color

  while [not user-done?][                  ; repeat until the checkmark is pressed 
    check-checkmark
    if mouse-down? and inside-area? [                  ; draw only if the mouse is pressed
     ; locate surface, find the first sky-colored patch at mouse-xcor. 
     let x round mouse-xcor
     let y round mouse-ycor
     let y1 y
     let color-list fput sky-color surface-colors   ; list of non-earth colors--sky plus the surface colors

     let delta-x -2        ; get ready to repeat for five x-values
     while [delta-x < 3] [   ; repeat for three values of x
       let x1 x + delta-x
       ifelse member? ([pcolor] of patch x1 y)  color-list   ; if x,y is in sky or surface 
         [while [member? ([pcolor] of patch x1 y) color-list ] [         ; walk down to find earth
              set y y - 1 ]
            set y y + 1 ]                                ; when x,y with non-sky is found add one to y to point above the earth
         [while [not member? ([pcolor] of patch x1 y ) color-list ] [        ; if x,y was not in sky or surface, walk up until found
            set y y + 1 ]]     
       ; here y is the first non-earth colored patch above the surface
       ask patches [                                             ; check every patch
         if abs ((pxcor) - x1) <= .5 and                         ; if this patch is at x,y or three up
             (pycor >= y ) and ((pycor <= (y + 3)) and           ; .....or reaches the mouse
               pycor <= y1) [ 
           set pcolor cnum ]]                                    ; set its color to cnum and........     
       set delta-x delta-x + 1 ]]                                ;    repeat for nearby x values and until the user leaves the view
    ] 
  ask messages [die]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; support utilities ;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to show-checkmark  ; substitutes the checkmark for the current kind of soft keys
;  set saved-kind [kind] of one-of icons with [hidden? = false]  ; save the kind any one of the icons that are currently visible     
  ask icons [ifelse kind = "check" [st][ht]] ; shows checkmark; hides but saves the kind of soft key that called the checkmark
  set user-done? false
end

to check-checkmark     ; sets "user-done?" true if the user is clicking on the checkmark. Also restores prior soft menu.
  ; if pressed, this removes the checkmark and restores the previous soft menu (if show-checkmark was used to put up the checkmark)
  set user-done? false
  let roll? false
  let x 0 let y 0
  ask icons with [name = "click when done"][
    set x xcor  set y ycor                ; extract the center of the icon--used for the rollover
    let rad .55 * icon-size
    if abs (mouse-xcor - xcor ) < rad and abs (mouse-ycor - ycor ) < rad [
      ifelse mouse-down? 
        [set user-done? true 
         set color pressed-icon-color
         while [mouse-down?][wait .04]             ; wait for the user to release the checkmark.  
         set color default-icon-color] 
;         ask icons [ifelse kind = saved-kind [st][ht]]]       ; shows the last-used kind of softkey.  
        [set roll? true]]]                    ; roll is true if the mouse is over the checkmark but not clicked. 
  if roll? [
    ask roll-overs [die]                    ; kill off any old roll-overs
    create-roll-overs 1 [
      set size 0                          ; don't show the turtles (but don't hide them, or the label won't show.
      setxy (x + 42 / patch-size)  (y - 24 / patch-size)
      set label-color black
      set label "Click when done" ]]
end

to-report random-between [a b] ; returns a random number between a and b (inclusive) with four decimals, i.e. 3.3092
  if a > b [let c b set b a set a c ] ; make a the smaller of the two
  report a + .0001 * random (1 + 10000 * (b - a)) 
end

; reports true/false if there is a patch ahead that is unoccupied the is less than or equal to the parameter 
to-report not-any-dots-on-patches-ahead? [ num-of-patches ]
  let i 1
  while [i <= num-of-patches] [ 
   if (not any? dots-on patch-ahead  i) [report true]   ;jumps out of loop
   set i i + 1
  ]
  report false
end

; reports which patch ahead is unoccupied
to-report unoccupied-patch [ num-of-patches ]
    let i 1
    while [i <= num-of-patches] [
      if (not any? dots-on patch-ahead  i) [report i]
      set i i + 1
    ]
    report 0  
end

to die-check
   if who = watched-turtle-number 
     [set watching? false
      set watched-turtle-number -1
     ]
   die
end

@#$#@#$#@
GRAPHICS-WINDOW
71
14
828
288
124
40
3.0
1
10
1
1
1
0
1
1
1
-124
124
-40
40
0
0
0
years

BUTTON
7
15
70
48
ON/OFF
run-groundwater
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
7
53
70
86
Run
Run-simulation true
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
6
255
69
288
Reset
Startup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
7
91
70
124
Make
Make
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
7
125
70
158
Remove
remove-items   ; cannot use 'remove'....
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
7
166
70
199
Pick
pick-model
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

@#$#@#$#@
WHAT IS IT?
-----------
This section could give a general understanding of what the model is trying to show or explain.


HOW IT WORKS
------------
This section could explain what rules the agents use to create the overall behavior of the model.


HOW TO USE IT
-------------
This section could explain how to use the model, including a description of each of the items in the interface tab.


THINGS TO NOTICE
----------------
This section could give some ideas of things for the user to notice while running the model.


THINGS TO TRY
-------------
This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.


EXTENDING THE MODEL
-------------------
This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.


NETLOGO FEATURES
----------------
This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.


RELATED MODELS
--------------
This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.


CREDITS AND REFERENCES
----------------------
This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

add-pipes
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -1 true false -15 60 300 120 300 105 -15 45 -15 0
Polygon -1 true false 0 195 300 180 300 165 0 180
Polygon -1 true false 135 255 255 75 240 75 150 210 120 255
Line -16777216 false 0 0 0 300
Line -16777216 false 300 0 0 0
Line -16777216 false 300 0 300 300
Line -16777216 false 300 300 0 300

add-soil
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -14835848 false false 90 150 90 270 120 270 180 195
Polygon -14835848 true false 210 210 300 120 75 120 90 150
Circle -16777216 true false 195 180 90
Polygon -6459832 true false 240 225 0 120 0 105 270 225 270 240
Polygon -6459832 true false 120 120 150 105 210 90 240 105 270 120 255 120
Line -16777216 false 0 0 0 300
Line -16777216 false 300 0 0 0
Line -16777216 false 300 0 300 300
Line -16777216 false 300 300 0 300

add-water
false
0
Rectangle -7500403 true true 0 0 300 300
Circle -13345367 true false 73 133 152
Polygon -13345367 true false 219 181 205 152 185 120 174 95 163 64 156 37 149 7 147 166
Polygon -13345367 true false 79 182 95 152 115 120 126 95 137 64 144 37 150 6 154 165
Line -16777216 false 0 0 0 300
Line -16777216 false 300 0 300 300
Line -16777216 false 0 300 300 300
Line -16777216 false 0 0 300 0

add-well
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -1 true false 105 90 195 90 195 30 150 0 105 30
Line -1 false 150 90 150 285
Line -16777216 false 0 0 300 0
Line -16777216 false 300 0 300 300
Line -16777216 false 0 0 0 300
Line -16777216 false 0 300 300 300

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

big x
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -2674135 true false 270 75 225 30 30 225 75 270
Polygon -2674135 true false 30 75 75 30 270 225 225 270

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

checkbox
false
0
Rectangle -16777216 true false 30 30 270 60
Rectangle -16777216 true false 30 240 270 270
Rectangle -16777216 true false 30 60 60 240
Rectangle -16777216 true false 240 60 270 240
Rectangle -7500403 true true 60 60 240 240

checkmark
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -10899396 true false 75 165 120 240 165 180 285 60 225 15 120 180 60 105 15 120
Rectangle -16777216 false false 0 0 300 300

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -14835848 true false 89 89 122

clear-screen
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -2674135 true false 270 75 225 30 30 225 75 270
Polygon -2674135 true false 30 75 75 30 270 225 225 270
Rectangle -16777216 false false 0 0 300 300

click-when-done
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -10899396 true false 75 165 120 240 165 180 285 60 225 15 120 180 60 105 15 120
Rectangle -16777216 false false 0 0 300 300

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

drop
false
0
Circle -7500403 true true 73 133 152
Polygon -7500403 true true 219 181 205 152 185 120 174 95 163 64 156 37 149 7 147 166
Polygon -7500403 true true 79 182 95 152 115 120 126 95 137 64 144 37 150 6 154 165

droplet
false
0
Rectangle -7500403 true true 0 0 300 300
Circle -11221820 true false 73 133 152
Polygon -11221820 true false 219 181 205 152 185 120 174 95 163 64 156 37 149 7 147 166
Polygon -11221820 true false 79 182 95 152 115 120 126 95 137 64 144 37 150 6 154 165

edit-layer
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -16777216 true false 75 135 225 150 225 165 75 150
Polygon -955883 true false 255 30 300 105 270 105 270 165 240 165 240 105 210 105 255 30
Polygon -955883 true false 45 0 0 75 30 75 30 120 60 120 60 75 90 75 45 0
Polygon -955883 true false 255 300 300 225 270 225 270 180 240 180 240 225 210 225 255 300
Polygon -955883 true false 45 270 0 195 30 195 30 135 60 135 60 195 90 195 45 270
Rectangle -16777216 true false 15 105 75 165
Rectangle -16777216 true false 225 135 285 195
Line -16777216 false 0 0 0 300
Line -16777216 false 0 0 300 0
Line -16777216 false 300 0 300 300
Line -16777216 false 0 300 300 300

eraser
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -2674135 true false 90 255 60 285 30 285 15 255 15 240 45 210
Polygon -955883 true false 240 75 240 105 90 255 60 255
Polygon -1184463 true false 45 210 45 240 225 60 195 60
Polygon -1184463 true false 210 105 195 90 45 240 60 255
Polygon -6459832 true false 210 105 240 105 255 45 195 60 195 90
Polygon -16777216 true false 255 45 226 52 225 60 240 75 249 75

explode
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -2674135 true false 120 0 105 105 15 45 75 120 0 180 105 165 45 285 135 195 285 240 210 180 285 60 165 105 120 0
Polygon -1184463 true false 75 45 75 90 30 90 90 135 45 195 120 165 150 285 165 195 285 165 150 150 225 60 150 105 165 15 135 75 75 45
Polygon -8630108 true false 105 105 150 135 195 120 150 180 120 165 75 150 120 135

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

layers
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -6459832 true false 0 75 225 15 300 45 300 150 195 120 0 165 0 75
Polygon -955883 true false 0 165 195 120 300 150 300 210 195 180
Polygon -5825686 true false 0 165 0 210 210 255 300 240 300 210 195 180 0 165 0 210
Polygon -16777216 true false 0 210 210 255 0 270 0 210
Rectangle -16777216 true false 180 120 195 135
Rectangle -16777216 true false 180 165 195 180
Rectangle -16777216 true false 0 150 15 165
Rectangle -16777216 true false 225 15 240 30
Rectangle -16777216 true false 0 60 15 75
Rectangle -16777216 true false 195 240 210 255
Rectangle -16777216 true false 285 225 300 240
Rectangle -16777216 true false 285 195 300 210
Rectangle -16777216 true false 285 135 300 150
Rectangle -16777216 true false 285 30 300 45
Rectangle -16777216 true false 0 210 15 225
Rectangle -16777216 true false 0 255 15 270

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

make-layer
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -6459832 true false 0 75 225 15 300 45 300 150 195 120 0 165 0 75
Polygon -955883 true false 0 165 195 120 300 150 300 210 195 180
Polygon -5825686 true false 0 165 0 210 210 255 300 240 300 210 195 180 0 165 0 210
Polygon -16777216 true false 0 210 210 255 0 270 0 210
Rectangle -16777216 true false 180 120 195 135
Rectangle -16777216 true false 180 165 195 180
Rectangle -16777216 true false 0 150 15 165
Rectangle -16777216 true false 225 15 240 30
Rectangle -16777216 true false 0 60 15 75
Rectangle -16777216 true false 195 240 210 255
Rectangle -16777216 true false 285 225 300 240
Rectangle -16777216 true false 285 195 300 210
Rectangle -16777216 true false 285 135 300 150
Rectangle -16777216 true false 285 30 300 45
Rectangle -16777216 true false 0 210 15 225
Rectangle -16777216 true false 0 255 15 270
Line -16777216 false 0 0 0 300
Line -16777216 false 0 0 300 0
Line -16777216 false 300 0 300 300
Line -16777216 false 0 300 300 300

mover1
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -955883 true false 0 150 60 90 60 120 150 135 150 165 60 180 60 210 0 150
Polygon -955883 true false 150 0 210 60 180 60 165 150 135 150 120 60 90 60 150 0
Polygon -955883 true false 300 150 240 210 240 180 150 165 150 135 240 120 240 90 300 150
Polygon -955883 true false 150 300 90 240 120 240 135 150 165 150 180 240 210 240 150 300
Rectangle -16777216 true false 105 105 195 195

mover2
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -16777216 true false 75 135 225 150 225 165 75 150
Polygon -955883 true false 255 30 300 105 270 105 270 165 240 165 240 105 210 105 255 30
Polygon -955883 true false 45 0 0 75 30 75 30 120 60 120 60 75 90 75 45 0
Polygon -955883 true false 255 300 300 225 270 225 270 180 240 180 240 225 210 225 255 300
Polygon -955883 true false 45 270 0 195 30 195 30 135 60 135 60 195 90 195 45 270
Rectangle -16777216 true false 15 105 75 165
Rectangle -16777216 true false 225 135 285 195

paintbrush
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -1 true false 87 191 103 218 238 53 223 38
Polygon -13345367 true false 104 204 104 218 239 53 235 47
Polygon -8630108 true false 99 173 83 175 71 186 64 207 52 235 45 251 77 238 108 227 124 205 118 185

pause
false
0
Rectangle -7500403 true true 0 0 300 300
Rectangle -955883 true false 75 60 120 240
Rectangle -955883 true false 180 60 225 240

pause-model
false
0
Rectangle -7500403 true true 0 0 300 300
Rectangle -955883 true false 75 60 120 240
Rectangle -955883 true false 180 60 225 240
Line -16777216 false 0 0 0 300
Line -16777216 false 0 0 300 0
Line -16777216 false 300 0 300 300
Line -16777216 false 0 300 300 300

pencil
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -2674135 true false 210 45 240 15 270 15 285 45 285 60 255 90
Polygon -955883 true false 255 60 255 90 105 240 90 225
Polygon -1184463 true false 60 195 75 210 240 45 210 45
Polygon -1184463 true false 90 195 105 210 255 60 240 45
Polygon -6459832 true false 90 195 60 195 45 255 105 240 105 210
Polygon -16777216 true false 45 255 74 248 75 240 60 225 51 225

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

pumphouse
false
0
Rectangle -7500403 true true 60 75 240 180
Polygon -7500403 true true 45 75 150 15 255 75

remove-layer
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -6459832 true false 0 75 225 15 300 45 300 150 195 120 0 165 0 75
Polygon -955883 true false 0 165 195 120 300 150 300 210 195 180
Polygon -5825686 true false 0 165 0 210 210 255 300 240 300 210 195 180 0 165 0 210
Polygon -16777216 true false 0 210 210 255 0 270 0 210
Rectangle -16777216 true false 180 120 195 135
Rectangle -16777216 true false 180 165 195 180
Rectangle -16777216 true false 0 150 15 165
Rectangle -16777216 true false 225 15 240 30
Rectangle -16777216 true false 0 60 15 75
Rectangle -16777216 true false 195 240 210 255
Rectangle -16777216 true false 285 225 300 240
Rectangle -16777216 true false 285 195 300 210
Rectangle -16777216 true false 285 135 300 150
Rectangle -16777216 true false 285 30 300 45
Rectangle -16777216 true false 0 210 15 225
Rectangle -16777216 true false 0 255 15 270
Polygon -2674135 true false 0 255 0 300 30 300 300 45 300 0 270 0 0 255
Polygon -2674135 true false 0 255 0 300 30 300 300 45 300 0 270 0 0 255
Polygon -2674135 true false 0 255 0 300 30 300 300 45 300 0 270 0 0 255
Line -16777216 false 300 0 300 300
Line -16777216 false 0 0 0 300
Line -16777216 false 0 0 300 0
Line -16777216 false 0 300 300 300

remove-pipes
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -1 true false -15 60 300 120 300 105 -15 45 -15 0
Polygon -1 true false 0 195 300 180 300 165 0 180
Polygon -1 true false 135 255 255 75 240 75 150 210 120 255
Polygon -2674135 true false 0 300 0 255 270 0 300 0 300 45 30 300
Line -16777216 false 0 0 0 300
Line -16777216 false 0 0 300 0
Line -16777216 false 300 0 300 300
Line -16777216 false 0 300 300 300

remove-soil
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -14835848 false false 90 150 90 270 120 270 180 195
Polygon -14835848 true false 210 210 300 120 75 120 90 150
Circle -16777216 true false 195 180 90
Polygon -6459832 true false 240 225 0 120 0 105 270 225 270 240
Polygon -6459832 true false 120 120 150 105 210 90 240 105 270 120 255 120
Polygon -2674135 true false 0 255 270 0 300 0 300 60 30 300 0 300
Line -16777216 false 0 0 0 300
Line -16777216 false 0 0 300 0
Line -16777216 false 300 0 300 300
Line -16777216 false 0 300 300 300

remove-well
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -1 true false 105 90 195 90 195 30 150 0 105 30
Line -1 false 150 90 150 285
Polygon -2674135 true false 0 255 270 0 300 0 300 45 30 300 0 300
Line -16777216 false 0 0 0 300
Line -16777216 false -15 300 285 300
Line -16777216 false 0 0 300 0
Line -16777216 false 300 0 300 300

reset-model
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -2674135 true false 270 30 105 150 270 270
Rectangle -2674135 true false 30 30 105 270
Line -16777216 false 0 0 0 300
Line -16777216 false 0 300 300 300
Line -16777216 false 0 0 300 0
Line -16777216 false 300 0 300 300

restart
true
0
Rectangle -7500403 true true 0 0 300 300
Rectangle -5825686 true false 60 45 105 255
Polygon -5825686 true false 135 150 240 45 240 255 135 150

run arrow
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -14835848 true false 75 60 255 150 75 240

run-model
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -14835848 true false 60 30 270 150 60 270
Rectangle -16777216 false false 0 0 300 300

set-climate
false
0
Rectangle -7500403 true true 0 0 300 300
Circle -13345367 true false 15 135 120
Polygon -13345367 true false 15 180 75 30 135 180
Rectangle -1 true false 210 15 270 210
Circle -1 true false 195 195 90
Circle -2674135 true false 206 206 67
Rectangle -2674135 true false 225 75 255 225
Line -16777216 false 210 45 255 45
Line -16777216 false 210 75 255 75
Line -16777216 false 210 105 255 105
Line -16777216 false 210 135 255 135
Line -16777216 false 210 165 255 165
Line -16777216 false 210 195 255 195
Rectangle -16777216 false false 0 0 300 300

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -1 true false 105 105 195 195

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

square 3
false
0
Rectangle -7500403 true true 30 30 270 270

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

wheelbarrow
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -2674135 false false 90 150 90 270 120 270 180 195
Polygon -2674135 true false 210 210 300 120 75 120 90 150
Circle -16777216 true false 195 180 90
Polygon -6459832 true false 240 225 0 120 0 105 270 225 270 240
Polygon -6459832 true false 120 120 150 105 210 90 240 105 270 120 255 120

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 4.1.2
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
