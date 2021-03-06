extensions [array]
extensions [string]
breed [humans human]

; used for drawing a line between the couples
undirected-link-breed [ pairs pair ]

; humans are turtles (common breed)

; NetLogo is case-insensitive

humans-own [
  id
  name
  maxMatchesInt
  sideInt
  partnerList
  rankList
  hasProposedToList
  gotProposedByList
  tmpMatchList
  activeFlag
]

;;global variables
globals [
  csv fileList ; fileList named csv
  startSideInt ; set in setup-globals from GUI-slider
  switchingFlag ; set in setup-globals from GUI-switch
  debugFlag ; set in setup-globals from GUI-switch
  user-input-filename ;
  input-filename; set default in setup-globals or from GUI-button
  current_nr_of_pairs
  current_nr_of_pairs_percent
  current_nr_of_rejects
]

;; method which is called from the setup button
to setup
  clear-all
  if debugFlag = true [
    show "after clear-all"
    show "clear-all"
    show count humans]
  setup-globals
  if debugFlag = true [show "after open-file"
     show "count humans after open-file"
     show count humans]
  reset-ticks
end

to reset
  clear-ticks
  clear-turtles
  clear-patches
  clear-drawing
  clear-all-plots
  clear-output
  if debugFlag = true [show "after clear-all"
     show "clear-all"
     show count humans]
  setup-globals
  if debugFlag = true [show "after open-file"
     show "count humans after open-file"
     show count humans]
  reset-ticks
end


;; stackoverflow.com/questions/27096948/how-to-read-a-csv-filve-with-netlogo
to open-file
  file-open (word input-filename ".csv")
  set fileList []

  while [not file-at-end?] [
    set csv file-read-line
    set csv word csv ";"  ; add comma for loop termination

    let mylist []  ; list of values
    let i 0
    while [not empty? csv]
    [
      let $x position ";" csv
      if i > 0 [
        let $item substring csv 0 $x  ; extract item
        carefully [set $item read-from-string $item][] ; convert if number
        set mylist lput $item mylist  ; append to list
      ]
      set csv substring csv ($x + 1) length csv  ; remove item and comma
      set i i + 1
    ]
    if debugFlag = true [show mylist]
    if item 0 mylist != "id"[
      create-humans 1 [
        set id item 0 mylist
        set name item 1 mylist
        set maxMatchesInt item 2 mylist
        set sideInt item 3 mylist
        let tmpPartnerListString string:split-string item 4 mylist "#"
        set partnerList read-from-string (word tmpPartnerListString)
        ;     set partnerList string:split-int item 4 mylist "#"
        let tmpRankListString string:split-string item 5 mylist "#"
        set rankList read-from-string (word tmpRankListString)
        ;     set rankList string:split-int item 5 mylist "#"
        set hasProposedToList []
        set gotProposedByList []
        set tmpMatchList []
        set activeFlag true
      ]
    ]
    set fileList lput mylist fileList
    if debugFlag = true [show "count humans at end of open-file"
     show count humans
     show "fileList at end of open-file"
     show fileList]
  ]
  file-close
end

to setup-globals
  ifelse starter = "Men" [set startSideInt 1] [set startSideInt 2]
  set debugFlag debug
  set switchingFlag switching
  ifelse user-input-filename = 0 [set input-filename "disco100NotPicky"] [set input-filename user-input-filename]
  set current_nr_of_rejects 0
  set current_nr_of_pairs 0
  set current_nr_of_pairs_percent 0
  let current_world_width world-width

  open-file ; and read initialisation data from csv file
  ; define starting position and start color
  let number_women count humans with [sideInt = 2]
  let xposHumansStart current_world_width / 2 ; starting position for humans
  let i 1
  foreach sort humans with [sideInt = startSideInt] [
    ask ? [
      let number_starting count humans with [sideInt = startSideInt]
      set shape "person"
      set size 1
      set heading 0
      ; positioning and color
      set ycor 4
      ifelse sideInt = 1 [set color blue] [set color red]
      let xposHumans i / (number_starting + 1) * current_world_width - xposHumansStart
      set xcor xposHumans
      set i i + 1
    ]
  ]
  set i 1
  foreach sort humans with [sideInt != startSideInt] [
    ask ? [
      let number_notstarting count humans with [sideInt != startSideInt]
      set shape "person"
      set size 1
      set heading 0
      ; positioning and color
      set ycor -4
      ifelse sideInt = 1 [set color blue] [set color red]
      let xposHumans i / (number_notstarting + 1) * current_world_width - xposHumansStart
      set xcor xposHumans
      set i i + 1
    ]
  ]
end

to go
  if count humans with [activeFlag = true and (sideInt = startSideInt or switchingFlag = true)] = 0 [stop]
  step
end



to step
  if debugFlag = true [show "---------------- begin of step ----------------"
     show "count humans at begin of step"
     show count humans]
  clear-before-match
  foreach sort humans with [activeFlag = true and sideInt = startSideInt] [ ; start of proposing
    ask ? [
      if debugFlag = true [show "count humans at begin of ask humans with activeFlag=true and sideInt=startSideInt"
        show count humans with [activeFlag = true and sideInt = startSideInt]
        show "myId"
        show id
        show "myName"
        show name
        show "partnerList"
        show partnerList
        show "hasProposedToList"
        show hasProposedToList]
      let tmpPotentialPartnersList list-difference partnerList hasProposedToList ; set-difference of partnerList \ hasProposedToList
      if length tmpPotentialPartnersList = 0 [
        set activeFlag false ; this human has no potential partners to propose to
        stop ; break
      ]
      if length tmpMatchList >= maxMatchesInt [
        set activeFlag false ; this human has enough current matches
        stop
      ]
      let myPreferredPartner item 0 tmpPotentialPartnersList ; most preferred partner from tmp...List
      propose-to id myPreferredPartner
    ]
  ] ; end of proposing
  if debugFlag = true [show "end of proposing"]
  foreach sort humans with [length gotProposedByList > 0 and sideInt != startSideInt] [
    ask ? [
      process-proposals id
    ]
  ]
  if switchingFlag = true [set startSideInt ((startSideInt + 1) mod 2)]
  if startSideInt = 0 [set startSideInt 2]
   if debugFlag = true [show "switchingFlag"
     show switchingFlag
     show "startSideInt"
     show startSideInt]
  calc-stats
  tick
  if debugFlag = true [show "############### end of step ###############"]
end

to calc-stats
  set current_nr_of_pairs 0
  ask humans with [sideInt = startSideInt] [
    if length tmpMatchList = maxMatchesInt [
       set current_nr_of_pairs current_nr_of_pairs + 1
    ]
  ]
 let countedHumans count humans with [sideInt = startSideInt]
  ifelse countedHumans = 0 [
    set current_nr_of_pairs_percent 0
  ] [
    set current_nr_of_pairs_percent current_nr_of_pairs / countedHumans
    set current_nr_of_pairs_percent current_nr_of_pairs_percent * 100
    if current_nr_of_pairs = 0 [set current_nr_of_pairs_percent 0]
  ]
  if debugFlag = true [ show "Current Nr of Pairs"
   show current_nr_of_pairs
   show "Current Nr of Pairs Percent"
   show current_nr_of_pairs_percent
 ]
end

to clear-before-match
  ask humans [
    set gotProposedByList [] ; delete gotProposedbyList (in preparation for next matching-round)
  ]
end

to propose-to[sender receiver]
  if debugFlag = true [show "---------------- begin of propose-to ----------------"]
  ask humans with [id = sender] [
    set hasProposedToList lput receiver hasProposedToList
    if debugFlag = true [show "hasProposedToList"
       show hasProposedToList
       show "receiver"
       show receiver]
    ask humans with [id = receiver] [
      set gotProposedByList lput sender gotProposedByList
      if debugFlag = true [show "female side"
         show "gotProposedByList"
         show gotProposedByList]
    ]
  ]
  if debugFlag = true [show "############### end of propose-to ###############"]
end

to process-proposals [tmpId]
  if debugFlag = true [show "---------------- begin of process-proposals ----------------"
     show "count humans at begin of process-proposals"
     show count humans]
  ask humans with [id = tmpId] [
    if debugFlag = true [show "gotProposedByList"
       show gotProposedByList
       show "sideInt"
       show sideInt
       show "maxMatchesInt"
       show maxMatchesInt]
    let tmpPotentialCoupleList []
    ifelse length tmpMatchList = 0 [
      set tmpPotentialCoupleList gotProposedByList
    ] [
    set tmpPotentialCoupleList list-union-set tmpMatchList gotProposedByList
    ]
    if debugFlag = true [show "tmpPotentialCoupleList"
       show tmpPotentialCoupleList]
    let tmpRejectList []
    let tmpCoupleList []
    ifelse length tmpPotentialCoupleList > maxMatchesInt [
      set tmpCoupleList list-order tmpPotentialCoupleList rankList partnerList maxMatchesInt
      if debugFlag = true [show "has more proposals than willing to accept"
         show "tmpCoupleList"
         show tmpCoupleList]
      set tmpRejectList list-difference tmpPotentialCoupleList tmpCoupleList
    ] [
    set tmpCoupleList tmpPotentialCoupleList
    ]
    if length tmpRejectList > 0 [
      reject-proposals id tmpRejectList
    ]
    if length tmpCoupleList > 0 [
      create-tmpCouples id tmpCoupleList
    ]
  ]
  if debugFlag = true [show "############### end of process-proposals ###############"]
end

to reject-proposals [tmpId rejectList]
  if debugFlag = true [show "---------------- begin of reject-proposals ----------------"]
  let rejecter 0
  ask humans with [id = tmpId] [
    set rejecter self
    set tmpMatchList  list-difference tmpMatchList rejectList
    if debugFlag = true [show "tmpMatchList"
       show tmpMatchList]
    foreach rejectList [
      ask humans with [id = ?] [
        set tmpMatchList  list-difference tmpMatchList lput tmpId []
        set activeFlag true
        ifelse sideInt = 1 [set color blue] [set color red]
        set current_nr_of_rejects current_nr_of_rejects + 1
        remove-link self rejecter
      ]
      ifelse sideInt = 1 [set color blue] [set color red]
    ]
  ]
  if debugFlag = true [show "############### end of reject-proposals ###############"]
end

to create-tmpCouples [tmpId acceptList]
  if debugFlag = true [show "---------------- begin of create-tmpCouples ----------------"]
  ask humans with [id = tmpId] [
    set tmpMatchList acceptList
    if debugFlag = true [show "tmpMatchList"
       show tmpMatchList]
    foreach acceptList [
      ask humans with [id = ?] [
        set tmpMatchList  list-union-set tmpMatchList lput tmpId []
        set color green
        create-link-with myself
      ]
      set color green
    ]
  ]
  if debugFlag = true [show "############### end of create-tmpCouples ###############"]
end


to-report list-order [listToOrder ranking partners maxMatches]
  if debugFlag = true [show "---------------- begin of list-order ----------------"]
  set listToOrder list-overlap listToOrder partners
  if debugFlag = true [show "listToOrder"
     show listToOrder]
  if length listToOrder > maxMatches [
    let tmpRanking get-rating-of-list partnerList listToOrder ranking
    let tmpList listToOrder
    if debugFlag = true [show "tmpRanking"
       show tmpRanking
       show "tmpList"
       show tmpList]
    set listToOrder []
    let i 0
    loop [
      if i >= maxMatches [report listToOrder]
      let j position (max tmpRanking) tmpRanking
      if debugFlag = true [show "j"
         show j
         show "item j tmpList"
         show item j tmpList
         show "tmpList"
         show tmpList]
      set listToOrder lput item j tmpList listToOrder
      set tmpRanking remove-item j tmpRanking
      set tmpList remove-item j tmpList
      if debugFlag = true [show "listToOrder"
         show listToOrder
         show "tmpList"
         show tmpList]
      set i i + 1
    ]

  ]
  report listToOrder
  if debugFlag = true [show "############### end of list-order ###############"]
end

;; symmetrical difference: fullList \ toRemoveList
to-report list-difference [fullList toRemoveList]
  report filter [not member? ? toRemoveList] fullList
end

;; intersection of listA and listB
to-report list-overlap [listA listB]
  if debugFlag = true [show "############### begin of list-overlap  ###############"
     show listA
     show listB
     show filter [member? ? listB] listA]
  if debugFlag = true [show "############### end of list-overlap  ###############"]
  report filter [member? ? listB] listA
end

;; union of listA and listB
to-report list-union-set [listA listB]
  let tmpList list-difference listB listA
  foreach tmpList [ set listA lput ? listA]
  report listA
end


;; gets ranking associated with fullList for partialList
to-report get-rating-of-list [fullList partialList ranking]
  let tmpList []
  foreach partialList [
    set tmpList lput item (position ? fullList) ranking tmpList
  ]
  report tmpList
end



;;;;;;;;;;;;;;;;;;;;;;;;
;;; Input filename   ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to change-input
  set user-input-filename user-input "Type input filename (without extension)."
  if debugFlag = true [show "user-input-filename"
     show user-input-filename]
end




;;;;;;;;;;;;;;;;;;;;;;;;
;;; Output matches   ;;;
;;;;;;;;;;;;;;;;;;;;;;;;


;; write-to-file taken from
;; Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/.
;; Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL
;; code from File/Models Library/Code Examples/File Output Example

to export-to-csv
  let output-filename (word input-filename "_Starter_" starter "_Switch_" switching "_Ticks_" ticks ".csv")
  foreach sort humans [
    ask ? [
      let delimPartnerList list-concat-with-delim partnerList "#"
      let delimRankList list-concat-with-delim rankList "#"
      let delimHasProposedToList list-concat-with-delim hasProposedToList "#"
      let delimGotProposedByList list-concat-with-delim gotProposedByList "#"
      let delimTmpMatchList list-concat-with-delim tmpMatchList "#"
      write-csv output-filename (list (id) (name) (maxMatchesInt) (sideInt) (delimPartnerList) (delimRankList) (delimHasProposedToList) (delimGotProposedByList) (delimTmpMatchList) (activeFlag))
    ]
  ]
end


;; http://stackoverflow.com/questions/22462168/netlogo-export-tableau-issues
to write-csv [ #filename #items ]
  ;; #items is a list of the data (or headers!) to write.
  if is-list? #items and not empty? #items
  [ file-open #filename
    ;; quote non-numeric items
    set #items map quote #items
    ;; print the items
    ;; if only one item, print it.
    ifelse length #items = 1 [ file-print first #items ]
    [file-print reduce [ (word ?1 ";" ?2) ] #items]
    ;; close-up
    file-close
  ]
end

to remove-link [human1 human2]
  ask links with [(end1 = human1 and end2 = human2) or (end1 = human2 and end2 = human1)] [
    die]
end
;; http://stackoverflow.com/questions/22462168/netlogo-export-tableau-issues
to-report quote [ #thing ]
  ifelse is-number? #thing
  [ report #thing ]
  [ report (word "\"" #thing "\"") ]
end

;; https://groups.yahoo.com/neo/groups/netlogo-users/conversations/topics/6490
;; intersperse listA with delim
to-report list-concat-with-delim [listA delim]
  if length listA > 0 [report reduce [(word ?1 delim ?2)] listA]
  report ""
end
@#$#@#$#@
GRAPHICS-WINDOW
265
10
795
345
14
8
17.933333333333334
1
9
1
1
1
0
0
0
1
-14
14
-8
8
0
0
1
ticks
30.0

SLIDER
10
135
210
168
number_people
number_people
1
100
1
1
1
min between
HORIZONTAL

SLIDER
10
185
210
218
max-run-time
max-run-time
0
600001
0
1000
1
ticks
HORIZONTAL

BUTTON
125
75
210
115
Go
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

BUTTON
10
75
95
115
Next
step
NIL
1
T
OBSERVER
NIL
N
NIL
NIL
1

BUTTON
10
10
95
55
Setup
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
840
10
927
43
Export csv
export-to-csv
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SWITCH
10
230
112
263
debug
debug
1
1
-1000

CHOOSER
10
275
110
320
starter
starter
"Men" "Women"
0

PLOT
840
65
1040
215
Number of Pairs (%)
time steps
NIL
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"pen-0" 1.0 0 -2674135 true "" "plot current_nr_of_pairs_percent"

MONITOR
840
230
1040
275
Number of Pairs
current_nr_of_pairs
17
1
11

MONITOR
840
295
1040
340
Number of Rejections
current_nr_of_rejects
17
1
11

SWITCH
130
230
257
263
switching
switching
1
1
-1000

TEXTBOX
30
355
180
381
Default input filename: disco
11
0.0
1

BUTTON
20
380
172
413
change input filename
change-input
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
125
15
187
48
Reset
reset
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
145
270
227
315
Current Ticks
ticks
0
1
11

MONITOR
20
460
170
505
Current input filename
input-filename
3
1
11

TEXTBOX
20
425
205
466
Press \"Reset\" to update model!\nOr \"Setup\" to return to default!
11
0.0
1

@#$#@#$#@
## AUTHORS


## WHAT IS IT?


## HOW TO USE IT



## THINGS TO NOTICE



## THINGS TO TRY
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

ambulance
false
0
Rectangle -7500403 true true 30 90 210 195
Polygon -7500403 true true 296 190 296 150 259 134 244 104 210 105 210 190
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Circle -16777216 true false 69 174 42
Rectangle -1 true false 288 158 297 173
Rectangle -1184463 true false 289 180 298 172
Rectangle -2674135 true false 29 151 298 158
Line -16777216 false 210 90 210 195
Rectangle -16777216 true false 83 116 128 133
Rectangle -16777216 true false 153 111 176 134
Line -7500403 true 165 105 165 135
Rectangle -7500403 true true 14 186 33 195
Line -13345367 false 45 135 75 120
Line -13345367 false 75 135 45 120
Line -13345367 false 60 112 60 142

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

server
false
0
Rectangle -7500403 true true 75 75 225 90
Rectangle -7500403 true true 75 90 90 210
Rectangle -7500403 true true 210 90 225 210
Rectangle -7500403 true true 75 210 225 225

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
NetLogo 5.3.1
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
1
@#$#@#$#@
