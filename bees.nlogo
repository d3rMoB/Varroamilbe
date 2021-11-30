breed [queens queen]
breed [bees bee]
breed [mites mite]

turtles-own [
  age               ;; how many days old the turtle is
  max-age
  infected
]

mites-own [
  bottom
  age-alone
  mature
  breeding
]

links-own [
  age-link
]

globals [
  minlife-summer
  minlife-winter
  month
  eggs
  spawn-diameter
  raid-start
  infested
  generation
]

to setup
  clear-all
  setup-constants
  setup-patches
  setup-turtles
  reset-ticks
end

to setup-constants
  set minlife-summer 60
  set minlife-winter 180
  set eggs start-bees * 2000 / 60000
  set spawn-diameter start-bees / 30
  set generation 1
  set month 0
end

to setup-patches
  ask patches [
    ifelse distancexy 0 0 < spawn-diameter
      [ set pcolor brown ]
      [ set pcolor green ]
  ]
end

to setup-turtles
  create-queens 1 [
    setxy 0 0
    set size 2
    set age 30
    set max-age (random (2 * 365)) + 3 * 365
    set color yellow
    set shape "bee"
  ]
  create-bees start-bees [
    setxy random-xcor random-ycor
    set size 1
    set age 30
    ifelse month <= 5
      [ set max-age (random 30) + minlife-summer ]
      [ set max-age (random 30) + minlife-winter ]
    set color green
    set shape "bee"
  ]
end

to go
  set month int ((ticks mod 365) / 30.4 )
  check-turtles
  check-links
  if count bees > 0 [ tick ]
end

to check-links
  ask links [
    set age-link age-link + 1
  ]
end

to check-turtles
  ask mites [
    mite-older
    new-victim
    infest-larva

    if breeding = 1 [
      let temp 1
      ask my-links [
          ask other-end [
            if age = 21 [ set temp 0 ]
        ]
      ]
      set breeding temp
    ]

    if mature = 1 [
      ask my-links [
        if other-end != nobody [
          ask other-end [
            if age = 13 [ breed-mites ]
          ]
        ]
      ]
    ]
  ]

  ask bees [
    bee-older
    if age >= 21 [
      set shape bee-shape
      move-bees
      infect-per-tick
    ]
  ]

  ask queens [
    bee-older
    remove-queens
    if age >= 16 [
      set shape bee-shape
      move-queens
    ]
  ]

  if month <= 7 and count bees with [ age >= 21 ] > start-bees / 5 [
    breed-bees
    breed-queens
  ]
end

to bee-older
  set age age + 1
  set max-age max-age - (count my-links)
  set max-age max-age - infected
  if age > max-age [
    ask my-links [
      ask other-end [
        if (random 10) > 8 [ set bottom 1 ]
      ]
    ]
    die
  ]
end

to mite-older
  if (count my-links) < 1 [
    set age-alone age-alone - 1
  ]
  set age age + 1
  if age > max-age or age-alone < 1 [ die ]
end

to move-bees
  let radius 19
  if month > 7 or month = 0
    [ set radius 8 ]
  ifelse distancexy 0 0 > radius
    [ facexy 0 0 ]
    [ right random 90
      left random 90 ]
  forward 1

  let xx xcor
  let yy ycor
  ask my-links [
    ask other-end [ setxy xx yy ]
  ]
end

to move-queens
  ifelse distancexy 0 0 > 2
    [ facexy 0 0 ]
    [ right random 90
      left random 90 ]
  forward 1
end

to breed-bees
  let larvas (count bees with [ age >= 21 ] * 0.035)
  if larvas > eggs [
    set larvas eggs
  ]
  create-bees larvas [
  ;create-bees count bees with [ age >= 21 ] / 40 [
    setxy random spawn-diameter - 1 - spawn-diameter / 2 + 1 random spawn-diameter - 1 - spawn-diameter / 2 + 1
    set age 0
    ifelse month >= 7                                           ;; birth month of winterbees
      [ set max-age (random 30) + minlife-winter ]
      [ set max-age (random 30) + minlife-summer ]
    set color green
    set shape "larva"
    set heading 90
  ]
end

to breed-queens
  if count queens < 1 [
    create-queens (random 2) + 2 [
      setxy 0 0
      set age 0
      set size 2
      set max-age (random (2 * 365)) + 3 * 365
      set color yellow
      set shape "larva"
    ]
  ]
end

to breed-mites
  hatch-mites (random 2 + 1) [
    create-link-with myself
    set size 1
    set age 20
    set age-alone 7
    ifelse month >= 7
      [ set max-age (random 30) + minlife-winter ]
      [ set max-age (random 30) + minlife-summer ]
    set color red
    set shape "dot"
  ]
end

to remove-queens
  if count queens with [ age > 16 ] > 1 [
    ask one-of queens [
      if (random 10) > 8 [ die ]
    ]
  ]
end

to infect-per-tick
  if (random 100) < probability-mites and month <= 7 [
    infest-bee
  ]
end

to bee-raid
  set raid-start ticks
  ask n-of ((count bees with [ age >= 21 ]) * percantage-infestation / 100) bees with [ age >= 21] [
    infest-bee
  ]
end

to infest-bee
  hatch-mites 1 [
    create-link-with myself
    set size 1
    set age 20
    set age-alone 7
    ifelse month >= 7
      [ set max-age (random 30) + minlife-winter ]
      [ set max-age (random 30) + minlife-summer ]
    set color red
    set shape "dot"
  ]
  set infected random 2
end

to infest-larva
  let victim one-of bees-here with [ age < 9 ]
  let count-links 0
  if victim != nobody [
    ask victim [ set count-links count my-links ]
    if count-links < 1 [
      set mature 1
      set breeding 1
      ask my-links [ die ]
      ask victim [
        create-link-with myself
        set infected random 2
     ]
    ]
  ]
end

to new-victim
  if (count my-links) < 1 and bottom = 0 [
    let victim one-of bees-here
    if victim != nobody [
      ask victim [ create-link-with myself ]
      set age-alone 7
    ]
  ]
end

to from-bee-to-new-bew
  let victim one-of bees-here
  let linkpartner 0
  ask my-links [ ask other-end [ set linkpartner count my-links ] ]
  if victim != nobody [
    if (linkpartner) >= 2 [
      ask my-links [ die ]
      ask victim [ create-link-with myself ]
    ]
  ]
end

to countermeasure
  ask n-of ((count mites) * percentage-mites / 100) mites [
    die
  ]
  ask n-of ((count bees) * percentage-bees / 100) bees [
    die
  ]
end

to setup-experiment
  set infested 0
  setup-turtles
  reset-ticks
end

to go-experiment
  if count mites >= count bees * 0.15 and infested = 0[
    output-print (word "gen" generation ": the mite population reached the critical point " (ticks - raid-start) " days after infestation")
    set infested 1
  ]
  if count bees <= 1 [
    output-print (word "gen" generation ": this generation exceeded " (ticks - raid-start) " days after the infestation")
    set generation generation + 1
    setup-experiment
  ]
  go
end
@#$#@#$#@
GRAPHICS-WINDOW
253
45
794
587
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-20
20
-20
20
0
0
1
ticks
30.0

BUTTON
37
41
101
74
Setup
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
118
41
181
74
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

PLOT
808
45
1105
195
Populations
days
amount
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"bees" 1.0 0 -1184463 true "" "plot count bees with [ age > 20 ]"
"larva" 1.0 0 -7500403 true "" "plot count bees with [ age <= 20 ]"
"mites" 1.0 0 -2674135 true "" "plot count mites"
"mites bottom" 1.0 0 -955883 true "" "plot count mites with [ bottom = 1 ]"
"infected bees" 1.0 0 -6459832 true "" "plot count bees with [ infected = 1 ]"

CHOOSER
39
540
177
585
bee-shape
bee-shape
"bee" "bee 2"
0

SLIDER
37
132
209
165
start-bees
start-bees
0
1000
395.0
1
1
NIL
HORIZONTAL

SLIDER
37
184
209
217
probability-mites
probability-mites
0
1
0.0
0.01
1
%
HORIZONTAL

MONITOR
814
252
871
297
NIL
month
17
1
11

SLIDER
37
239
230
272
percantage-infestation
percantage-infestation
0
100
5.0
1
1
%
HORIZONTAL

BUTTON
83
281
161
314
NIL
bee-raid
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
37
86
149
119
NIL
go-experiment
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
37
340
209
373
percentage-mites
percentage-mites
0
100
11.0
1
1
%
HORIZONTAL

BUTTON
62
424
183
457
NIL
countermeasure
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
37
382
209
415
percentage-bees
percentage-bees
0
100
0.0
1
1
%
HORIZONTAL

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

bee
true
0
Polygon -1184463 true false 152 149 77 163 67 195 67 211 74 234 85 252 100 264 116 276 134 286 151 300 167 285 182 278 206 260 220 242 226 218 226 195 222 166
Polygon -16777216 true false 150 149 128 151 114 151 98 145 80 122 80 103 81 83 95 67 117 58 141 54 151 53 177 55 195 66 207 82 211 94 211 116 204 139 189 149 171 152
Polygon -7500403 true true 151 54 119 59 96 60 81 50 78 39 87 25 103 18 115 23 121 13 150 1 180 14 189 23 197 17 210 19 222 30 222 44 212 57 192 58
Polygon -16777216 true false 70 185 74 171 223 172 224 186
Polygon -16777216 true false 67 211 71 226 224 226 225 211 67 211
Polygon -16777216 true false 91 257 106 269 195 269 211 255
Line -1 false 144 100 70 87
Line -1 false 70 87 45 87
Line -1 false 45 86 26 97
Line -1 false 26 96 22 115
Line -1 false 22 115 25 130
Line -1 false 26 131 37 141
Line -1 false 37 141 55 144
Line -1 false 55 143 143 101
Line -1 false 141 100 227 138
Line -1 false 227 138 241 137
Line -1 false 241 137 249 129
Line -1 false 249 129 254 110
Line -1 false 253 108 248 97
Line -1 false 249 95 235 82
Line -1 false 235 82 144 100

bee 2
true
0
Polygon -1184463 true false 195 150 105 150 90 165 90 225 105 270 135 300 165 300 195 270 210 225 210 165 195 150
Rectangle -16777216 true false 90 165 212 185
Polygon -16777216 true false 90 207 90 226 210 226 210 207
Polygon -16777216 true false 103 266 198 266 203 246 96 246
Polygon -6459832 true false 120 150 105 135 105 75 120 60 180 60 195 75 195 135 180 150
Polygon -6459832 true false 150 15 120 30 120 60 180 60 180 30
Circle -16777216 true false 105 30 30
Circle -16777216 true false 165 30 30
Polygon -7500403 true true 120 90 75 105 15 90 30 75 120 75
Polygon -16777216 false false 120 75 30 75 15 90 75 105 120 90
Polygon -7500403 true true 180 75 180 90 225 105 285 90 270 75
Polygon -16777216 false false 180 75 270 75 285 90 225 105 180 90
Polygon -7500403 true true 180 75 180 90 195 105 240 195 270 210 285 210 285 150 255 105
Polygon -16777216 false false 180 75 255 105 285 150 285 210 270 210 240 195 195 105 180 90
Polygon -7500403 true true 120 75 45 105 15 150 15 210 30 210 60 195 105 105 120 90
Polygon -16777216 false false 120 75 45 105 15 150 15 210 30 210 60 195 105 105 120 90
Polygon -16777216 true false 135 300 165 300 180 285 120 285

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

caterpillar
true
0
Polygon -7500403 true true 165 210 165 225 135 255 105 270 90 270 75 255 75 240 90 210 120 195 135 165 165 135 165 105 150 75 150 60 135 60 120 45 120 30 135 15 150 15 180 30 180 45 195 45 210 60 225 105 225 135 210 150 210 165 195 195 180 210
Line -16777216 false 135 255 90 210
Line -16777216 false 165 225 120 195
Line -16777216 false 135 165 180 210
Line -16777216 false 150 150 201 186
Line -16777216 false 165 135 210 150
Line -16777216 false 165 120 225 120
Line -16777216 false 165 106 221 90
Line -16777216 false 157 91 210 60
Line -16777216 false 150 60 180 45
Line -16777216 false 120 30 96 26
Line -16777216 false 124 0 135 15

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

larva
true
15
Polygon -7500403 true false 150 180 150 180
Polygon -7500403 true false 60 105
Polygon -1 true true 135 255
Polygon -7500403 true false 105 225
Polygon -1 true true 86 212 70 216 62 227 58 240 58 261 82 278 109 282 196 282 219 276 219 276 233 261 244 232 251 186 250 146 234 86 217 60 200 53 166 52 76 52 61 62 52 70 48 88 52 101 61 114 84 119 100 112 129 110 171 113 183 134 187 192 185 219 88 213 70 217
Polygon -1 true true 166 224 181 215 184 210
Polygon -1 true true 178 220 197 220 195 208 185 211 182 214 175 219
Polygon -1 true true 62 108 51 123 55 96 55 103 55 107 38 108 53 97
Polygon -1 true true 104 109 106 128 101 134 95 136 93 141 104 137 111 127 111 110 129 109 121 107 122 123 119 132 112 137 107 143 117 141 125 132 127 111 134 106 135 127 133 136 125 144 138 142 141 133 143 109
Rectangle -16777216 true false 89 214 96 280
Rectangle -16777216 true false 110 215 117 281
Rectangle -16777216 true false 131 216 138 282
Rectangle -16777216 true false 151 207 158 281
Rectangle -16777216 true false 171 215 178 281
Rectangle -16777216 true false 173 207 254 214
Rectangle -16777216 true false 186 186 250 195
Rectangle -16777216 true false 184 164 264 173
Rectangle -16777216 true false 183 148 262 156
Rectangle -16777216 true false 165 127 252 137
Rectangle -16777216 true false 69 210 74 280
Rectangle -16777216 true false 164 111 261 118
Polygon -16777216 true false 178 217 211 286 218 280 182 209
Polygon -16777216 true false 177 212 253 239 245 246 184 222
Polygon -16777216 true false 176 213 258 272 239 278 178 219
Polygon -16777216 true false 173 221 197 293 206 294 177 221
Polygon -16777216 true false 165 115 231 81 236 65 149 118 266 80 268 100 247 97 166 117
Polygon -16777216 true false 158 113 218 56 207 47 143 117
Rectangle -16777216 true false 143 46 152 129
Rectangle -16777216 true false 126 27 135 110
Rectangle -16777216 true false 103 26 112 109
Rectangle -16777216 true false 81 40 90 123
Circle -16777216 true false 57 68 13
Polygon -16777216 true false 162 51 156 123 167 47
Polygon -16777216 true false 171 46 164 102 140 181
Polygon -16777216 true false 168 44
Polygon -16777216 true false 123 155 123 148
Rectangle -16777216 true false 138 138 163 155

larva 2
true
15
Circle -1 true true 20 22 261
Circle -16777216 true false 96 78 117
Circle -16777216 true false 62 84 132
Circle -16777216 true false 75 90 132
Circle -16777216 true false 73 91 132
Circle -16777216 true false 77 85 132
Circle -16777216 true false 93 82 132
Circle -16777216 true false 76 75 132
Circle -16777216 true false 81 90 132
Circle -16777216 true false 8 105 132
Circle -16777216 true false 3 28 132
Polygon -1 true true 94 201 133 231 106 242 73 217 98 204
Polygon -1 true true 98 204 79 196 64 197 54 204 51 214 59 204 54 204 44 214 48 227 50 233
Polygon -1 true true 46 213 44 214 40 222 53 240 112 254 92 210 62 199 47 209
Polygon -1 true true 99 35 130 38 100 34 77 39 68 55 71 78 94 87 131 77 158 56
Polygon -1 true true 76 47 129 56 117 54
Circle -1 true true 84 34 24
Circle -16777216 false false -47 11 18
Polygon -1 true true 75 75 60 90 90 75 75 105 90 90 105 60
Polygon -1 true true 135 75 135 90 120 105 120 120 120 120 135 105 150 75 165 75
Polygon -1 true true 165 75 165 90 150 105 135 120 150 120 180 90 180 75
Circle -16777216 true false 120 120 30
Circle -16777216 true false 15 135 30
Polygon -1 true true 199 83 190 109 175 117 170 123 183 125 199 119 206 96
Circle -16777216 true false 82 38 19
Circle -1 true true 86 43 13
Polygon -16777216 true false 103 200 53 255 66 267 118 208 153 206
Polygon -16777216 true false 132 218 84 285 103 286 148 219
Polygon -16777216 true false 158 213 143 296 164 294 174 209
Polygon -16777216 true false 178 191 206 284 225 274 195 189
Polygon -16777216 true false 184 175 266 235 280 215 209 170
Polygon -16777216 true false 204 150 292 174 290 152 221 139
Polygon -16777216 true false 217 121 284 113 278 97 201 111
Polygon -16777216 true false 241 52 182 100 183 91 245 35
Polygon -16777216 true false 271 72 202 100 207 108 274 82
Polygon -16777216 true false 218 128 294 125 287 137 218 134
Polygon -16777216 true false 202 157 293 184 288 197 213 166
Polygon -16777216 true false 193 189 269 253 252 260 199 197
Circle -16777216 true false 42 129 46
Polygon -16777216 true false 196 25 155 91 154 81 188 19 220 28 176 80 183 87 225 38
Polygon -16777216 true false 150 21 151 91 152 76 143 76 142 16
Polygon -16777216 false false 134 75 148 75
Polygon -16777216 true false 122 24 129 84 120 89 111 25
Polygon -16777216 true false 173 213 183 290 192 284 179 208
Polygon -16777216 true false 143 213 128 294 136 292 148 213
Polygon -16777216 true false 119 213 75 270 83 277 123 216
Polygon -16777216 true false 91 192 38 238 49 240 97 195

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
NetLogo 6.2.1
@#$#@#$#@
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
