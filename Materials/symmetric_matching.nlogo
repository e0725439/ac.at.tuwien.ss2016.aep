breed [ men man ]
breed [ women woman ]

men-own [ value aspiration dated left_potential potential marridge married_mate]
women-own [ value aspiration dated left_potential potential marridge married_mate]

undirected-link-breed [ pairs pair ]
pairs-own [ anniversary ]

globals [ men_ycor women_ycor person_width 
  max_date adjustment married_couple value_sum value_mean difference difference_mean more_match]

to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  ask patches [ set pcolor white ]

  let margin 1.1
  let ycor_offset 0.8
  
  set-default-shape turtles "person"
  set person_width (max-pxcor - min-pxcor) / (number_of_same_sex * margin)
  set men_ycor max-pycor * ycor_offset
  set women_ycor min-pycor * ycor_offset
    
  set more_match false
  
  set married_couple 0
  set value_sum 0
  set difference 0
  set value_mean 0
  set difference_mean 0
  
  set max_date number_of_same_sex * adolescence_period / 100
  set adjustment 50 / (1 + adolescence_period)
  
  let xpos min-pxcor / margin
  
  create-men number_of_same_sex [
    set value random 100
    
    set xcor xpos
    set xpos xpos + person_width
    set ycor men_ycor
  
    set color blue
    
    ifelse (decision_rule = "TNB")
    [ set aspiration 0 ]
    [ ifelse (decision_rule = "MEAN")
      [ set aspiration value - 5 ]
      [ set aspiration 50 ]
    ]
    
    set dated 0
    set potential number_of_same_sex   
    set marridge false
    set married_mate -1
  ]
  
  set xpos min-pxcor / margin
    
  create-women number_of_same_sex [
    set value random 100
    
    set xcor xpos
    set xpos xpos + person_width
    set ycor women_ycor
    
    set color pink
    
    ifelse (decision_rule = "TNB")
    [ set aspiration 0 ]
    [ ifelse (decision_rule = "MEAN")
      [ set aspiration value - 5 ]
      [ set aspiration 50 ]
    ]
    
    set dated 0
    set potential number_of_same_sex   
    set marridge false
    set married_mate -1
  ]
  
  ask men [
    set left_potential n-values number_of_same_sex [turtle (? + number_of_same_sex)]
  ]
  
  ask women [
    set left_potential n-values number_of_same_sex [turtle ?]
  ]
end

to go  
  ifelse ticks < max_date [
    ask men [go_adoles]
  ]
  [ 
    set more_match false
    
    let woman_wanted men with [ (not marridge) and potential > 0 ] 
    if any? woman_wanted
      [ ask woman_wanted [go_match] ]
    
    let man_wanted women with [ (not marridge) and potential > 0 ] 
    if any? man_wanted
      [ ask man_wanted [go_match]]
      
    if not more_match
    [
      ifelse (married_couple != 0) 
      [ set value_mean value_sum / (married_couple * 2)
        set difference_mean difference / married_couple
      ]
      [ set value_mean "N/A"
        set difference_mean "N/A"
      ]
      stop
    ]
  ]
 
  tick    
end

to go_adoles
  let partner nobody
  set partner one-of ((turtle-set left_potential) with [ dated <= ticks ])
  if partner != nobody
  [
    ask partner [date myself]
    set left_potential remove partner left_potential
    set potential potential - 1 
    set dated dated + 1 
  ]
end

to date [ partner ]
  let new_value 0
  
  if show_dated = true
  [  create-pair-with partner ]
  
  set left_potential remove partner left_potential
  set potential potential - 1  
  set dated dated + 1
  
  ifelse (decision_rule = "TNB")
    [ 
      if (aspiration < [value] of partner)
      [ learn [value] of partner]
  
      if ([aspiration] of partner < value)
      [ set new_value value
        ask partner [ learn new_value ] ] 
    ] 
  [
    ifelse (decision_rule = "MEAN")
    []
    [
      ifelse (decision_rule = "ADJUSTUD")
      [
        ifelse (aspiration < [value] of partner)
        [ set new_value [aspiration] of partner + adjustment
          ask partner [ learn new_value ]
        ]
        [ set new_value [aspiration] of partner - adjustment
          ask partner [ learn new_value ]
        ]
        
        ifelse ([aspiration] of partner < value)
        [ learn (aspiration + adjustment)]
        [ learn (aspiration - adjustment)]
      ]
      [
        ifelse (decision_rule = "ADJUSTREL")
        [
          ifelse (aspiration < [value] of partner)
          [ if (value > [aspiration] of partner)
            [ set new_value [aspiration] of partner + adjustment
              ask partner [ learn new_value ]
            ]
          ]
          [ if (value < [aspiration] of partner)
            [ set new_value [aspiration] of partner - adjustment
              ask partner [ learn new_value ]
            ]
          ]
      
          ifelse ([aspiration] of partner < value)
          [ if ([value] of partner > aspiration)
            [ learn (aspiration + adjustment)]
          ]
          [ if ([value] of partner < aspiration)
            [ learn (aspiration - adjustment)]
          ]         
        ]
        [
          if (decision_rule = "ADJUSTREL2")
          [
            ifelse (aspiration < [value] of partner)
            [ if (value > [aspiration] of partner)
              [ set new_value [aspiration] of partner + abs(value - [aspiration] of partner) / 2
                ask partner [ learn new_value ]
              ]
            ]
            [ if (value < [aspiration] of partner)
              [ set new_value [aspiration] of partner - abs(value - [aspiration] of partner) / 2
                ask partner [ learn new_value ]
              ]
            ]
      
            ifelse ([aspiration] of partner < value)
            [ if ([value] of partner > aspiration)
              [ learn (aspiration + abs([value] of partner - aspiration) / 2)]
            ]
            [ if ([value] of partner < aspiration)
              [ learn (aspiration - abs([value] of partner - aspiration) / 2)]
            ]
          ]
        ]
      ]
    ]
  ]  
end

to learn [  new_value ]
  set aspiration new_value
end

to go_match
  let partner nobody
  set partner one-of ((turtle-set left_potential) with [ not marridge ])
  if partner != nobody
  [
    set more_match true
    ask partner [propose myself]  
    set left_potential remove partner left_potential
    set potential potential - 1  
    set dated dated + 1
  ]
end

to propose [ partner ]
  set left_potential remove partner left_potential
  set potential potential - 1  
  set dated dated + 1
  
  if show_dated = true
  [  create-pair-with partner ]

  if (aspiration < [value] of partner and [aspiration] of partner < value )
  [ get_married partner 
    ask partner [get_married myself]
    
    set married_couple married_couple + 1
    set value_sum value_sum + value + [value] of partner
    set difference difference + abs(value - [value] of partner)
  ]
end

to get_married [ partner ]
  set marridge true
  set married_mate partner

  if  show_married = true
  [ ifelse show_dated = true
    [ ask pair ([who] of self) ([who] of partner) [set color black]]
    [ create-pair-with partner [
        set color black
        set anniversary ticks
        ]]

  set color black
  ask partner [set color black]
  ] 
end
  
@#$#@#$#@
GRAPHICS-WINDOW
210
10
1247
470
39
16
13.0
1
10
1
1
1
0
0
0
1
-39
39
-16
16
0
0
1
ticks
30.0

SLIDER
11
10
200
43
number_of_same_sex
number_of_same_sex
0
100
100
1
1
NIL
HORIZONTAL

SLIDER
10
54
198
87
adolescence_period
adolescence_period
0
100
37
1
1
%
HORIZONTAL

BUTTON
27
111
93
144
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

CHOOSER
19
259
157
304
decision_rule
decision_rule
"TNB" "MEAN" "ADJUSTUD" "ADJUSTREL" "ADJUSTREL2"
4

BUTTON
118
112
181
145
NIL
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

MONITOR
21
315
111
360
NIL
married_couple\n
17
1
11

MONITOR
22
367
108
412
NIL
value_mean
1
1
11

MONITOR
22
421
106
466
NIL
difference_mean
1
1
11

SWITCH
23
163
154
196
show_dated
show_dated
1
1
-1000

SWITCH
22
209
166
242
show_married
show_married
0
1
-1000

@#$#@#$#@
Symmetric two-sided matching

This is a replication model of the matching problem including the mate search problem, which is the generalization of a traditional optimization problem.

Peter Todd conducted a simulation for two-sided matching problem in symmetric setting in 1999(*).  In his model there are the same number of agents in two parties, each of whom has his/her own mate value. Each agent in both parties tries to find his/her mate in the other party based on his/her candidate’s mate value and his/her own aspiration level for the partner’s mate values. Each agent learns his/her own mate value and adjusts his/her aspiration level through the trial period (adolescence). Todd tried a several search rules and the learning mechanisms. The rules and the mechanisms are symmetric for both parties in this setting.  This NetLogo model is a replication of his model.

(*) Peter M. Todd and Geoffery F. Miller, “From pride and prejudice to persuasion”, in Gred Gigerenzer, Peter M. Todd and the ABC Research Group, Simple heuristics that makes us smart, Oxford University Press, New York, 1999
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
NetLogo 5.0.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>married_couple</metric>
    <metric>value_mean</metric>
    <metric>difference_mean</metric>
    <enumeratedValueSet variable="decision_rule">
      <value value="&quot;TNB&quot;"/>
      <value value="&quot;MEAN&quot;"/>
      <value value="&quot;ADJUSTUD&quot;"/>
      <value value="&quot;ADJUSTREL&quot;"/>
      <value value="&quot;ADJUSTREL2&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="adolescence_period" first="0" step="1" last="90"/>
    <steppedValueSet variable="random-seed" first="0" step="1" last="9"/>
  </experiment>
</experiments>
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
