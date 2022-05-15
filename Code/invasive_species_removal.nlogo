globals [
  viable-land-color
  nonviable-land-color
  shallow-water-color
  size-to-flower
  time-to-flower-again
  terrain
  time-to-flower
  time-to-make-seeds
  time-to-finish-seeds
  max-size
  growth-period
  deep-water-color
  init-size
  t-root-land-mean
  t-root-land-sd
  init-phase
  ticks-at-zero
  days-spent-picking
]
extensions[ bitmap ]
breed [envs env] ;; define what mode of ticks we're in as demonstrated by color of the sun / moon
breed [plants plant] ;; young plants
breed [seeds seed ] ;; represents trees in their first year of growth
breed [people person]

plants-own [
  age
  flower-time
]

people-own[

]

seeds-own [
  age
  t-root-water
  t-root-land
  exp-time
]

to setup
  clear-all
  set terrain bitmap:import "map.png"
  set max-size 30
  set days-spent-picking 0
  set ticks-at-zero 100000
  set time-to-flower (365)*(4) ;; four years to first flower
  set size-to-flower 15
  set time-to-make-seeds (10.5)*(30)
  set init-size 5
  resize-world (-((bitmap:width terrain)/(2))) (((bitmap:width terrain)/(2))) (-((bitmap:height terrain)/(2))) ((bitmap:height terrain)/(2))
  create-terrain
  ; Defining colors
  ask patch 0 200 [ set nonviable-land-color pcolor ]
  ask patch 0 169 [ set viable-land-color pcolor ]
  set shallow-water-color black
  ask patch 0 -20 [ set deep-water-color pcolor ]
  ;; TODO: implement an optional number of previous growth years
  let day 0
  reset-ticks
  set init-phase true
  while [day <= 300] [
    go
    set day (day + 1)
  ]
  set init-phase false
  reset-ticks
end

to go
  if regular-picking = true and init-phase = false [
    set days-spent-picking (days-spent-picking + daily)
    let cut-down 0
    ask plants with [size >= 15][
      while [cut-down <= daily] [
        set cut-down (cut-down + 1)
        die
      ]
    ]
    set cut-down 0
    ask plants with [size < 15][
      while [cut-down <= daily] [
        set cut-down (cut-down + 1)
        if random 100 <= count plants with [size < 15]  [
          die ]
      ]
    ]
  ]

  if big-effort = true and init-phase = false [
    ;frequency
    if ticks mod period = 0 [
      let cut-down 0
      ask plants with [size >= 15][
        while [cut-down <= daily-avg * period] [
          set cut-down (cut-down + 1)
          die
        ]
      ]
      set days-spent-picking (days-spent-picking + daily-avg * period)

      set cut-down 0
      ask plants with [size < 15][
        while [cut-down <= daily-avg * period] [
          set cut-down (cut-down + 1)
          if random 100 <= count plants with [size < 15]  [
            die ]

        ]
      ]
    ]
  ]


  if count plants = 0 and ticks < ticks-at-zero[
    set ticks-at-zero ticks
  ]

  day-n-night
  grow-plants

  tick
end

to create-terrain
  bitmap:copy-to-pcolors terrain True
  create-envs 1 [
    set color yellow
    set shape "sun"
    set size 50
    move-to patch -200 169
  ]
  ; as a default, our world begins with just one plant
  create-plants 200 [
    set color red
    set flower-time 0
    set shape "plant"
    let random-val random 25
    set size (random 25 + init-size)
    set age (size)*(48) + 1000 ; age proportional to size
    move-to one-of patches with [pcolor = viable-land-color or pcolor =  shallow-water-color]
  ]
end

to grow-plants
  ;; PLANTS
  ask plants [
    set age (age + (1))
    if size <= max-size [
      if density <= 70 [
        set size (size + (0.5))
      ]
    ]

    ;
    ; Tree is ready to flower
    if (age >= time-to-flower) and (size >= size-to-flower) [
      set color white
      set flower-time (flower-time + (1))
    ]

    ; Tree putting out seeds (demonstrated by pink color)
    if (flower-time >= time-to-make-seeds)[
      set color pink
      set flower-time (flower-time + (1))
      let seed-today random 365 ;; Each tree produces about 200 - 300 seeds a year depending on its size
      if seed-today <= size * 3 [
        release-seeds 1 list xcor ycor
      ]
    ]
  ]

  ;; SEEDS:
  ask seeds [
    set age (age + 1)
    if age >= exp-time [ die ]
    ;if not member? pcolor list (list viable-land-color deep-water-color) shallow-water-color [

    ; die ]

    ;; Seed on land
    if pcolor = viable-land-color and age >= t-root-land[
      hatch-plants 1 [
        set color red
        set flower-time 0
        set shape "plant"
        set size init-size
        set age 0
      ]
      die
    ]
    ;; Seed in water
    if pcolor = shallow-water-color or pcolor = deep-water-color [

      move-to one-of patches with [member? pcolor (list shallow-water-color deep-water-color)]
      if age >= 40 and age >= t-root-water  [
        ; Seed drops in water that's shallow enough for it to survive in
        if pcolor = shallow-water-color [
          hatch-plants 1 [
            set color red
            set flower-time 0
            set shape "plant"
            set size init-size
            set age 0
          ]
          die
        ]
      ]
    ]
  ]
  choke-small-plants
end


to choke-small-plants
  ask plants with [size <= max-size / 4] [
    if (density >= 68)[
      set size (size - .5)
    ]
    if size <= 2 [die]
  ]
end

to-report density
  let init 0
  ask plants in-radius 40 with [size >= 10] [
    set init (init + size)
  ]
  report init
end

to day-n-night
  ask envs[set color green]
  if ticks mod 2 = 0[
    ask envs[set shape "moon"]
  ]
  if ticks mod 2 = 1 [
    ask envs[set shape "sun"]
  ]
end

to release-seeds [num-seeds loc]
  hatch-seeds num-seeds [
    set color red
    set shape "x"
    set size 6
    set age 0
    move-to one-of patches in-radius 20
    set t-root-water random-normal 40 8
    set t-root-land random-normal 12 2
    set exp-time ((random 18)*(random 18) + max list t-root-water (40))
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
470
10
1115
494
-1
-1
0.5
1
10
1
1
1
0
0
0
1
-322
322
-237
237
1
1
1
ticks
30.0

BUTTON
25
10
160
43
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
165
10
265
43
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
0

MONITOR
165
450
242
495
Mangroves
count plants
17
1
11

MONITOR
255
450
337
495
Propagules
count seeds
17
1
11

INPUTBOX
15
145
165
205
daily
1.0
1
0
Number

SWITCH
15
105
167
138
regular-picking
regular-picking
0
1
-1000

MONITOR
90
325
242
370
Ticks when #plants = 0
ticks-at-zero mod 100000
17
1
11

INPUTBOX
200
145
320
205
period
180.0
1
0
Number

SWITCH
200
105
317
138
big-effort
big-effort
1
1
-1000

INPUTBOX
200
210
320
270
daily-avg
10.0
1
0
Number

MONITOR
90
385
402
430
Days spent picking plants, weighted by daily-avg
days-spent-picking
17
1
11

@#$#@#$#@
## WHAT IS IT?

This model demonstrates the meandering of a river along its "middle course", where the gradient of the landscape is gradual and the river runs within a U-shaped river valley. The evolution of the shape of the river is governed by the path of its highest-velocity flow, as well as erosion and deposition.

## HOW IT WORKS

There are three main agents: Land patches, Water turtles and Flow turtles.

Land patches are green, and simply represent land where the river does not run through.

Water turtles, or "water tiles", are blue, and represent a segment of water, containing properties that describe the physical characteristics of this segment, such as depth, the amount of sediment deposited, and whether it is a source or drain. When a connected path of "water tiles" is made between a source and a drain, a "flow gradient" is formed to represent the direction of water flow.

Flow turtles are white, and represent the highest-velocity flow of the water. They move along the "flow gradient" from source to drain, as well as along the center of the river channel, as this is where water flows the fastest in real-life streams. These flow turtles are the main driving force for erosion and deposition along the river.

### Deposition
Each tick, sediment is deposited on all water tiles, increasing their "sediment-amount" by 1%. When this amount reaches 100%, the water-tile is converted to a Land patch.

When a Flow passes over a water tile, it "washes away" part of the deposited sediment, decreasing the "sediment-amount" by 15%. Thus, water tiles that experience little flow will eventually accumulate too much sediment and turn into Land patches.

### Erosion
When a Flow turtle collides with a Land patch, it "erodes" the Land, converting it into a water tile.

## HOW TO USE IT

When starting the model, simply press SETUP to initialize the land patches with a vertical line of water tiles along the center, representing a straight river. Pressing GO will commence the flow of flow turtles whose movements represent the path of fastest flow.

The two key switches labeled DEPOSITION? and EROSION? serve to enable or disable their respective mechanic, allowing you to observe how each mechanic affects the behavior of the river individually.

The four sliders are parameters that affect the flowing mechanics of the flow turtles. MAX-FLOW-SPEED determines the maximum speed flows will move at. FLOW-ACCELERATION determines how fast flow turtles will be accelerated down the flow gradient. RIVER-CENTER-ACCELERATION determines how fast flow turtles will be accelerated towards the center (i.e., deepest) part of the river. DOWNWARDS-INCLINE-FORCE determines the magnitude of the constant downwards force, essentially representing how steep the land gradient is.

The graph plots the sinuosity of the river over time. Sinuosity is the ratio of the path length of the river and the Euclidean distance between the two endpoints of the river. It is a measure of how much a river meanders; a sinuosity of 1 correlates to a completely straight river, and this value increases the more the path of the river deviates from the shortest path.

The monitor displays the exact sinuosity, The river would be categorized according to  conventional classes of sinuosity, where sinuosities between 1 and 1.05 are “almost straight”, between 1.05 and 1.25 “winding”, between 1.25 and 1.50 “twisty”, and above 1.50 “meandering”.

## THINGS TO NOTICE

Closely observe how erosion and deposition affect the depth of the river, and how that in turn affects the movement of the flow turtles, which leads to more erosion and deposition. This is the key positive feedback loop that drives the emergence of meanders along rivers.

Observe what causes the initially straight river to begin winding.

Observe how meanders are eventually cut-off once the main flow of the stream diverts itself, resulting in the formation of oxbows.

Keep an eye on the sinuosity graph as the river begins to meander, specifically on the rate at which sinuosity increases. Also, notice how once meander cut-offs become frequent, the sinuosity is impeded from getting too high, and remains mostly below 2.

## THINGS TO TRY

Try disabling erosion and deposition and running the model to observe how/whether the initial straight river changes. Then, enable just erosion and observe how erosion affects the shape of the river and the movement of the fastest flow. Finally, enable deposition as well as erosion, and observe how they interact with each other in order to produce full meanders.

Changing the MAX-FLOW-SPEED also affects the behavior of meanders a lot - try various speeds to see how the behavior of the river changes.

## EXTENDING THE MODEL

Improve the flow mechanics of the model to prevent the occasional unintended and unintentional behavior that detracts from the realism of the model.

## NETLOGO FEATURES

The model makes use of `dx` and `dy` to help replicate vector addition while still using the turtles' own "heading" property. This allows for modification of a turtle's motion with both NetLogo heading-related commands as well as with vector addition.

## RELATED MODELS

Erosion, Grand Canyon

## CREDITS AND REFERENCES

Credit to MrWeebl for the inspiration to create a model for river meanders and oxbow lakes.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Caldeira, F. and Wilensky, U. (2021).  NetLogo River Meanders model.  http://ccl.northwestern.edu/netlogo/models/RiverMeanders.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

This model was developed as part of the Spring 2021 Multi-agent Modeling course offered by Dr. Uri Wilensky at Northwestern University. For more info, visit http://ccl.northwestern.edu/courses/mam/. Special thanks to Teaching Assistants Jacob Kelter, Leif Rasmussen, and Connor Bain.

## COPYRIGHT AND LICENSE

Copyright 2021 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2021 MAM2021 Cite: Caldeira, F. -->
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

moon
false
0
Polygon -7500403 true true 175 7 83 36 25 108 27 186 79 250 134 271 205 274 281 239 207 233 152 216 113 185 104 132 110 77 132 51

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

sun
false
0
Circle -7500403 true true 75 75 150
Polygon -7500403 true true 300 150 240 120 240 180
Polygon -7500403 true true 150 0 120 60 180 60
Polygon -7500403 true true 150 300 120 240 180 240
Polygon -7500403 true true 0 150 60 120 60 180
Polygon -7500403 true true 60 195 105 240 45 255
Polygon -7500403 true true 60 105 105 60 45 45
Polygon -7500403 true true 195 60 240 105 255 45
Polygon -7500403 true true 240 195 195 240 255 255

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
NetLogo 6.2.2
@#$#@#$#@
setup repeat 1000 [ go ]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="regular-picking" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="20000"/>
    <exitCondition>ticks-at-zero &lt; 100000</exitCondition>
    <metric>ticks-at-zero</metric>
    <metric>days-spent-picking</metric>
    <enumeratedValueSet variable="regular-picking">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="big-effort">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="daily">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="big-effort" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="20000"/>
    <exitCondition>ticks-at-zero &lt; 100000</exitCondition>
    <metric>ticks-at-zero</metric>
    <metric>days-spent-picking</metric>
    <enumeratedValueSet variable="big-effort">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regular-picking">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="period">
      <value value="7"/>
      <value value="30"/>
      <value value="90"/>
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="daily">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="daily-avg">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
1
@#$#@#$#@
