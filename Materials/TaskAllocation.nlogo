globals [

  assignments-fulfilled-by-one-worker
  assignments-fulfilled-by-a-team
  assignments-being-processed-or-fulfilled
  all-assignments
  total-processing-time
  mean-processing-time
  total-wasted-skills
  current-wasted-skills
  total-available-skills
  mean-wasted-skills
  current-time
  m-of-similarities
  min-of-similarities
  max-of-similarities
  last-200-similarities
]

breed [ workers worker ]

breed [ assignments assignment ]

workers-own [
  skills
  wasted-skills
  my-current-assignment
  my-current-helper
  my-current-boss
  range-of-vision
  done-for-this-round?
]

assignments-own [
  skills-requested
  remaining-skills-requested
  processing-time
  current-worker
  being-processed?
  fulfilled?
]

to setup
;;  random-seed 12345
  ;; (for your model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  set last-200-similarities []
  set current-time 0
  set assignments-fulfilled-by-one-worker 0
  set assignments-fulfilled-by-a-team 0
  set total-processing-time 0
  set total-wasted-skills 0
  set total-available-skills 0
  set-default-shape workers "person"
  create-workers workers-at-start
  ask workers [ 
    setxy random-xcor random-ycor 
    set color white
    
    set skills ( list (random-float 1) (random-float 1) (random-float 1) ) 
    set total-available-skills total-available-skills + sum skills
    set my-current-assignment nobody
    set my-current-helper nobody
    set my-current-boss nobody
    set done-for-this-round? false
    set range-of-vision min-range-of-vision + random-float ( max-range-of-vision - min-range-of-vision )
  ]
  set-default-shape assignments "minibox"
end

to new-assignments
  let a  ( new-assignments-per-period / time-scale )
  let b a - floor a
  let new-assignments-for-this-period floor a + ifelse-value ( random-float 1 < b ) [ 1 ] [ 0 ]
  create-assignments new-assignments-for-this-period [ 
    setxy random-xcor random-ycor 
    set color red
    set being-processed? false
    set fulfilled? false
    set current-worker nobody
    set processing-time 0
    set remaining-skills-requested ( list ( random-float time-scale ) ( random-float time-scale ) ( random-float time-scale ) )
    set skills-requested remaining-skills-requested
  ]
end

to go
  new-assignments
  set current-time current-time + 1
  ask workers 
  [ 
    set done-for-this-round? false
    ifelse my-current-assignment = nobody
    [
      set color white
    ] 
    [ 
      if my-current-helper != nobody [ set color orange ]
      if my-current-helper = nobody [ set color green ]
    ]
    if my-current-boss != nobody [ set color yellow ]
    if my-current-boss != nobody and my-current-helper != nobody [ show "boss and helper at the same time" ]
  ]
  let-busy-workers-work

  let-idle-workers-search 
  set current-wasted-skills 0
  ask workers
  [
    set total-wasted-skills total-wasted-skills + wasted-skills
    set current-wasted-skills current-wasted-skills + wasted-skills
  ]
  set assignments-being-processed-or-fulfilled count assignments with [ being-processed? or fulfilled? ]
  set all-assignments count assignments
  set mean-wasted-skills total-wasted-skills / current-time / total-available-skills
  ifelse assignments-fulfilled-by-one-worker + assignments-fulfilled-by-a-team = 0  
  [ set mean-processing-time 9 ]
  [ set mean-processing-time total-processing-time / ( assignments-fulfilled-by-one-worker + assignments-fulfilled-by-a-team ) ]
  let n-of-assignments count assignments with [  current-worker != nobody ]
  set m-of-similarities 0
  set max-of-similarities 0
  set min-of-similarities 180
  ask assignments with  [  current-worker != nobody ]
  [
    let his-skills []
    if current-worker != nobody
    [
      set his-skills [ skills ] of current-worker
      if [ my-current-helper ] of current-worker != nobody
      [
        let this-one's-skills [ skills ] of [ my-current-helper ] of current-worker
        ( foreach his-skills this-one's-skills 
        [
          set ?1 ?1 + ?2
        ]
        )
      ]
    ]
    let task-worker-similarity similarity his-skills skills-requested
    set m-of-similarities m-of-similarities + task-worker-similarity
    if task-worker-similarity < min-of-similarities [ set min-of-similarities task-worker-similarity ] 
    if task-worker-similarity > max-of-similarities [ set max-of-similarities task-worker-similarity ] 
    if fulfilled? 
    [ 
      ask current-worker 
      [ 
        set my-current-assignment nobody 
        set color white
        if my-current-helper != nobody
        [
          ask my-current-helper [ set color white ]
        ]
      ] 
    ]
  ]
  set m-of-similarities m-of-similarities / n-of-assignments
  ifelse length last-200-similarities < 200
  [
    set last-200-similarities lput m-of-similarities last-200-similarities
  ]
  [
    set last-200-similarities lput m-of-similarities but-first last-200-similarities
  ]
  ask assignments with [ fulfilled? ] [ die ]
  
  do-plots
end

to let-busy-workers-work
  ask workers with [ color = green or ( my-current-assignment != nobody and my-current-helper = nobody )]
  [
    set wasted-skills 0
    work-alone
  ]
  ask workers with [ color = orange ]
  [
    set wasted-skills 0
    work-as-team 
  ]
end

to let-idle-workers-search
  ask workers with [ color = white and not done-for-this-round? ]
  [
    set wasted-skills 0
    while [ ( color = white ) and any? assignments with [ not ( being-processed? or fulfilled? ) ]] 
    [ 
      search-for-assignment 
    ]
    ifelse my-current-assignment != nobody 
    [
      if team and my-current-helper = nobody and my-current-boss = nobody and not done-for-this-round?
      [ 
        let expected-duration how-long-will-it-take skills [ remaining-skills-requested ] of my-current-assignment
        if expected-duration > threshold-for-searching-colleague [ search-for-colleague ] 
      ]
      if my-current-helper = nobody 
      [ 
        set color green
        work-alone
      ]
      if my-current-helper != nobody 
      [ 
        set color orange 
        work-as-team
      ]
    ]
    [
      set wasted-skills wasted-skills + sum skills
    ]
  ]
end

to decrement-required-skills [ my-assignment my-skills my-wasted-skills ]
  let curr-skills-req [ remaining-skills-requested ] of my-assignment
  ( foreach ( list 0 1 2 ) my-skills curr-skills-req
    [
      ifelse ?3 > ?2 
      [ set curr-skills-req replace-item ?1 curr-skills-req (?3 - ?2) ]          
      [ set curr-skills-req replace-item ?1 curr-skills-req 0 
        set my-wasted-skills my-wasted-skills + ( ?2 - ?3 )
      ]
    ]                                     
  )   
  ask my-assignment [ set remaining-skills-requested curr-skills-req ]
end

to work-alone
  let finished? false
  decrement-required-skills my-current-assignment skills wasted-skills 
  ask my-current-assignment 
  [ 
    set processing-time ( processing-time + 1 )
    if sum remaining-skills-requested = 0.0 
    [
      set assignments-fulfilled-by-one-worker ( assignments-fulfilled-by-one-worker + 1 )
      set total-processing-time ( total-processing-time + processing-time )
      set fulfilled? true
      set being-processed? false
      set finished? true
    ]
  ]
  if finished? 
  [ 
    set color white     
    set my-current-assignment nobody
  ]
  set done-for-this-round? true
end

to-report vector-sum [ list1 list2 ]
  let result ( map [ ?1 + ?2 ] list1 list2 )
  report result
end

to work-as-team
  let finished? false
  let our-skills vector-sum skills [ skills ] of my-current-helper
  decrement-required-skills my-current-assignment our-skills wasted-skills    
  ask my-current-assignment 
  [ 
    set processing-time ( processing-time + 1 )
    if sum remaining-skills-requested = 0.0 
    [ 
      set assignments-fulfilled-by-a-team ( assignments-fulfilled-by-a-team + 1 )
      set total-processing-time ( total-processing-time + processing-time )
      set fulfilled? true
      set being-processed? false
      set finished? true
    ]
  ]
  set done-for-this-round? true
  ask my-current-helper [ set done-for-this-round? true ]  
  if finished?
  [ 
    set color white 
    ask my-current-assignment [ set color green ]
    ask my-current-helper 
    [ 
      set color white 
      set my-current-boss nobody
    ]
    set my-current-helper nobody
    set my-current-assignment nobody
    ask my-out-links [ die ]
  ]    
end

to-report random-assignment
  let next-target min-one-of ( assignments in-radius range-of-vision with [ not being-processed? ] ) [ distance self ]
  report next-target
end

to-report similarity [ list1 list2 ]
  let result 0
  if mode = "optimal-euclid" [
    ( foreach list1 list2 [
        set result result + ?1 * ?1 + ?2 * ?2
      ]
    )  
  ]
  if mode = "optimal-chebyshev" [
    ( foreach list1 list2 [
        if ?2 - ?1 > result [ set result ?2 - ?1 ] 
      ]
    )
  ]
  if mode = "cosinus" [
    let norm-list1 0
    let norm-list2 0
    ( foreach list1 list2 [
        set norm-list1 norm-list1 + ?1 * ?1
        set norm-list2 norm-list2 + ?2 * ?2
      ]
    )
    ( foreach list1 list2 [
        set result result + ?1 * ?2 / sqrt ( norm-list1 * norm-list2 )
      ]
    ) 
    set result ( acos result )
  ]
  report result
end 

to-report optimal-assignment 
  let visible-assignments assignments in-radius range-of-vision with [ not ( being-processed? or fulfilled? ) ]
  let next-target nobody
  let current-similarity 180
  ask visible-assignments [
    let this-similarity similarity [skills] of myself [remaining-skills-requested] of self
    if current-similarity > this-similarity
    [
      set current-similarity this-similarity
      set next-target self
    ]
  ]
  report next-target
end

to-report optimal-colleague [ needed-skills ]
  let visible-colleagues workers in-radius range-of-vision with [ color = white and not done-for-this-round? ]
  let next-colleague nobody
  let current-similarity 180
  ask visible-colleagues 
  [
    let this-similarity similarity [skills] of self needed-skills
    if current-similarity > this-similarity
    [
      set current-similarity this-similarity
      set next-colleague self
    ]
  ]
  report next-colleague
end

to search-for-assignment
  without-interruption
  [
    let next-target nobody
    if mode = "random" [ set next-target random-assignment ]
    if mode = "optimal-euclid" or mode = "optimal-chebyshev" or mode = "cosinus" 
    [set next-target optimal-assignment ]
    ifelse next-target = nobody 
    [ 
      left random 360 
      fd random 10 
      set color white
    ]
    [
      face next-target
      forward distance next-target 
      set my-current-assignment next-target
      ask my-current-assignment 
      [ 
        set color blue 
        set being-processed? true
        set current-worker myself
      ]
      set color green
    ]
  ]
end

to search-for-colleague
  let needed-skills [ remaining-skills-requested ] of my-current-assignment 
  ( foreach skills needed-skills
    [
      set ?2 ?2 - ( ?1 * time-scale )
    ]
  )
  without-interruption
  [
    set my-current-helper nobody
    if mode = "random" 
    [ set my-current-helper one-of other workers with [ color = white and not done-for-this-round?] ]
    if mode = "optimal-euclid" or mode = "optimal-chebyshev" or mode = "cosinus" 
    [ set my-current-helper optimal-colleague needed-skills ] 
    ifelse my-current-helper = nobody or my-current-helper = self
    [
      set color green
    ]
    [
      create-link-to my-current-helper
      set color orange
      ask my-current-helper 
      [ 
        set my-current-boss myself
        set color yellow
      ]
    ]
  ]
end

to-report how-long-will-it-take [ available-skills requested-skills ]
  let expected-time 0
  ( foreach available-skills requested-skills
    [
       let this-time ?2 / ?1
       if this-time > expected-time [ set expected-time this-time ]
    ]
  )  
  report expected-time
end

to do-plots
  set-current-plot "wasted skills (mean per time step)"
  if current-time > 0 [ 
    set-current-plot-pen "cws"
    plotxy current-time current-wasted-skills / total-available-skills
    set-current-plot-pen "wspw"
    plotxy current-time total-wasted-skills / ( current-time * workers-at-start ) 
    set-current-plot-pen "wsps"
    plotxy current-time total-wasted-skills / ( current-time * total-available-skills ) 
  ]
  set-current-plot "mean processing time"
  set-current-plot-pen "mpt"
  let assignments-fulfilled assignments-fulfilled-by-one-worker + assignments-fulfilled-by-a-team
  if assignments-fulfilled > 0 [ plotxy assignments-fulfilled total-processing-time / assignments-fulfilled ]
  set-current-plot "percent idle workers"
  set-current-plot-pen "%iw"
  if assignments-fulfilled > 0 [ plotxy current-time count workers with [ color = white ] * 100 / workers-at-start ]
  set-current-plot "task worker similarities"
  set-current-plot-pen "min"
  plotxy current-time min-of-similarities
  set-current-plot-pen "max"
  plotxy current-time max-of-similarities
  set-current-plot-pen "mean"
  plotxy current-time m-of-similarities
  set-current-plot-pen "mov av"
  plotxy current-time mean last-200-similarities
end
@#$#@#$#@
GRAPHICS-WINDOW
304
10
734
461
17
17
12.0
1
10
1
1
1
0
0
0
1
-17
17
-17
17
0
0
1
ticks
30.0

BUTTON
32
24
95
57
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
114
24
177
57
NIL
go
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
34
364
113
409
workers
count workers
3
1
11

MONITOR
136
365
273
410
tasks
all-assignments
3
1
11

MONITOR
33
416
112
461
idle workers
count workers with [  color = white ]
3
1
11

MONITOR
138
416
273
461
tasks being processed
assignments-being-processed-or-fulfilled
3
1
11

MONITOR
138
468
274
513
tasks fulfilled
( sentence assignments-fulfilled-by-one-worker \" + \" assignments-fulfilled-by-a-team )
0
1
11

SLIDER
31
61
203
94
workers-at-start
workers-at-start
0
100
50
1
1
NIL
HORIZONTAL

SLIDER
29
99
264
132
new-assignments-per-period
new-assignments-per-period
0
50
28
1
1
NIL
HORIZONTAL

MONITOR
169
521
273
566
mean processing time
total-processing-time / ( assignments-fulfilled-by-one-worker + assignments-fulfilled-by-a-team)
3
1
11

BUTTON
199
23
262
56
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
32
468
114
513
busy workers
count workers with [ color = green or color = orange or color = yellow ]
3
1
11

CHOOSER
146
213
298
258
mode
mode
"random" "optimal-euclid" "optimal-chebyshev" "cosinus"
3

PLOT
750
10
950
160
mean processing time
tasks fulfilled
NIL
0.0
10.0
0.0
4.0
true
true
"" ""
PENS
"mpt" 1.0 0 -16777216 true "" ""

SLIDER
28
136
200
169
max-range-of-vision
max-range-of-vision
0
100
100
1
1
NIL
HORIZONTAL

PLOT
751
163
951
313
percent idle workers
time steps
NIL
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"%iw" 1.0 0 -16777216 true "" ""

SLIDER
29
174
201
207
min-range-of-vision
min-range-of-vision
0
100
100
1
1
NIL
HORIZONTAL

MONITOR
29
521
143
566
mean wasted skills
total-wasted-skills / current-time / total-available-skills
3
1
11

PLOT
751
317
951
467
wasted skills (mean per time step)
time steps
NIL
0.0
10.0
0.0
3.0
true
true
"" ""
PENS
"wspw" 1.0 0 -16777216 true "" ""
"wsps" 1.0 0 -13345367 true "" ""
"cws" 1.0 0 -2674135 true "" ""

MONITOR
225
142
282
187
time
current-time
3
1
11

MONITOR
29
579
110
624
wasted skills
current-wasted-skills / total-available-skills
3
1
11

SWITCH
30
215
133
248
team
team
0
1
-1000

MONITOR
232
577
352
622
NIL
total-available-skills
17
1
11

MONITOR
449
577
643
622
assignments currently processed
list count assignments with [ being-processed? ] count assignments with [ being-processed? and [ my-current-helper ] of current-worker != nobody ]
17
1
11

SLIDER
32
266
204
299
time-scale
time-scale
1
10
10
1
1
NIL
HORIZONTAL

MONITOR
346
524
527
569
similarities' min, mean and max
( list  ( precision min-of-similarities 3 ) ( precision m-of-similarities 3 ) ( precision max-of-similarities 3 ) )
5
1
11

PLOT
752
472
952
622
task worker similarities
time steps
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"mean" 1.0 0 -16777216 true "" "plot m-of-similarities"
"min" 1.0 0 -10899396 true "" "plot min-of-similarities"
"max" 1.0 0 -2674135 true "" "plot max-of-similarities"
"mov av" 1.0 0 -13791810 true "" ""

SLIDER
32
315
301
348
threshold-for-searching-colleague
threshold-for-searching-colleague
0
20
10
1
1
NIL
HORIZONTAL

MONITOR
347
476
527
521
moving average of similarities
mean last-200-similarities
2
1
11

@#$#@#$#@
## WHAT IS IT?

A variant of the old garbage-can model (Cohen, Olsen, March 1972) where deciders (workers) have skills instead of energy and where problems (tasks) do not request energy to be solved but skills. And the choices that can be used by deciders to solve problems are in a way hidden in the skills of the deciders. Moreover workers can 
ask others for help.

## HOW IT WORKS

Tasks require different skills to be performed (for instance, technical, legal and managerial skills), and agents have the respective skills to different extents. 

Currently, three different skills are defined. The extent to which a certain task require agents to have the respective skills is expressed in a triple of numbers between 0 and 1. Similarly, the agents' skills are also defined as triples of numvers between 0 and 1. 

Idle agents (white) look around to find tasks that they can perform, according to one out of four organisationwide task allocation rules, comparing their own skills to the skills required by the tasks (red) they observe. When they decide to accept a task (which then turns blue) they start working on it (and turn green). In every time step (round) the amount of skill required to perform the task is decreased by the respective amount of skill the agent has, such that it takes one or more rounds to perform the task (the task then vanishes, but the worker's colour remains green until the next round when it either becomes white when no new task is found or remains green when the next task is found immediately). 

All four task allocation rules are based on the concept of some matching between the skills of an agent and the skills required to perform a task. The simplest rule is "random" (i.e. no match is aimed at), the rule "optimal-eucild" minimises the Eucildean distance between the two vectors describing the agent's and the task's skills, the rule "optimal-chebyshev" minimises the respective Chebyshev distance between the two vectors, and the rule "cosine" minimises the angle between the two vectors.
   
Thus, for instance, if an agent has skills (.1 .2 .3) and decides to perform a task that requires skills (.2 .2 .7) than it takes this agent three rounds to perform this task (after round one the remaining requested skills are decreased to (.1 .0 .4), after round two to (.0 .0 .1) and after round three the task is fulfilled. 

If the switch 'team' is turned on, workers can ask other workers for help when they find
that it would take them too long to perform the selected task. Worker and helper are connected by a directed link while their cooperation continues, and the worker turns red, while the helper turns yellow.

## HOW TO USE IT

As agents can find tasks only within the range of their vision, it is necessary to define the minimum and maximum ranges of vision. Individual agents then have ranges of vision uniformly distributed between these two values. 

New tasks come into being at the beginning of each round, and one can input the number of tasks arising per period.  

## THINGS TO NOTICE

One will soon notice that the performance of the organisation does not only depend on the speed of the task inflow, but more so on its task allocation rule and whether workers can or cannot form two-person teams.

## THINGS TO TRY

Task allocations rules should be changed between different runs, and for the same task allocation rules the task inflow parameter should be changed in a wide range (14 to 22 turned out most interesting).

## EXTENDING THE MODEL

One addition has been made in a companion model called EvTaskAlloc.nlogo, where the individual agents select tasks according to their individual selection rules and learn to change their rules according to their own and their colleagues' experience.

## NETLOGO FEATURES

No particularly interesting features of NetLogo were used.

## RELATED MODELS

EvTaskAlloc.nlogo is an extension.

## CREDITS AND REFERENCES

The model is described in detail in 

Troitzsch, Klaus G. (2008): The garbage can model of organisational behaviour: A theoretical reconstruction of some of its variants. In: Simulation Modelling Practice and Theory. Bd. 16. Nr. 2. S. 218-230 (http://dx.doi.org/10.1016/j.simpat.2007.11.019).

The team formation is described only in:

Troitzsch, Klaus G. (2012): Theory reconstruction of several version of modern organisation theories. In: Andreas Tolk, ed.: Ontology, Epistemology, and Teleology of Modeling and Simulation -
Philosophical Foundations for Intelligent M&S Applications, Berlin, Heidelberg (Springer) 2012 (forthcoming)
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
Polygon -7500403 true true 150 270 240 225 240 90 150 135
Polygon -7500403 true true 150 135 45 90 150 45 240 90
Polygon -7500403 true true 45 90 45 225 150 270 150 135
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

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

minibox
false
0
Polygon -7500403 true true 150 225 225 195 225 105 150 135
Polygon -7500403 true true 150 135 75 105 150 75 225 105
Polygon -7500403 true true 75 105 75 180 150 225 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

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
NetLogo 5.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="2nd experiment" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mean-wasted-skills</metric>
    <metric>mean-processing-time</metric>
    <metric>count assignments</metric>
    <metric>assignments-fulfilled-by-a-team / (assignments-fulfilled-by-one-worker + assignments-fulfilled-by-a-team )</metric>
    <metric>mean last-200-similarities</metric>
    <enumeratedValueSet variable="workers-at-start">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;cosinus&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-range-of-vision">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="new-assignments-per-period" first="14" step="1" last="28"/>
    <enumeratedValueSet variable="min-range-of-vision">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="team">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="threshold-for-searching-colleague" first="1" step="1" last="5"/>
  </experiment>
  <experiment name="3rd experiment" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mean-wasted-skills</metric>
    <metric>mean-processing-time</metric>
    <metric>count assignments</metric>
    <metric>assignments-fulfilled-by-a-team / (assignments-fulfilled-by-one-worker + assignments-fulfilled-by-a-team )</metric>
    <metric>mean last-200-similarities</metric>
    <enumeratedValueSet variable="workers-at-start">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;cosinus&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-range-of-vision">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="new-assignments-per-period" first="14" step="1" last="28"/>
    <enumeratedValueSet variable="min-range-of-vision">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="team">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="threshold-for-searching-colleague" first="0" step="5" last="20"/>
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
0
@#$#@#$#@
