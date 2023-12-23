breed [humans human]
breed [hospitals hospital]

globals [
  %sick      ;This variable holds the number of sick humans
  %carry     ;This var holds the number of the humans carrying the virus
  %healthy   ;This var holds the number of the healthy humans
  ;%carrying  ;
  %Intencive-care ; the humans who needs the intensive care
  %Hospital-Empty-beds
  %recovered ; variable that show the number of humans recovered
  %age_0_29
  %age_30_49
  %age_50_64
  %age_65+

  ; The percentage of helthy people by age category
  %H_29
  %H_49
  %H_64
  %H_65
  %Vacc
  %TotalDeaths
]

hospitals-own [
  empty-beds
  hospital-location
]

humans-own [
  category-age-0_29?
  category-age-30_49?
  category-age-50_64?
  category-age-65+?
  carry?   ; a boolean variable that determins if the turtle is carrying the virus
  incubation-period ; the time between the moment on infection and the beginning of symptoms
  infection-time ; when the turtle has been infected (time)
  touched?
  wareMask?
  symptoms? ; a boolean variable to show if the human has the symptoms or not
  symptoms-time ; to know when the symptoms started
  need-hospital? ; a boolean varable to see if the human needs an intensive care or not (hospital)
  recovered? ;a boolean variable to check if a human has had the virus and he recovred from it
  move? ;used in the Quarantine situation
  human-home ; this variable will hold the coordinates of the human
  dead?
  in-hospital?
  befor-quarantine ;the human wait from 2 to 5 days befor he do the quarantine
  is-vaccinated?
]




to setup
  clear-all
  setupHumans
  update-global-variables
  create-hospital
  setup-vaccinated
  reset-ticks
end


to setupHumans
  ; >>>>>>>>> SetuUp the humans in the env <<<<<<<<<<

  ;Create the total population
  create-humans Totalpop [
    setxy random-xcor random-ycor
    set human-home patch-here
    set size 1
    set color green
    set shape "face happy"

    ;varibales init
    set touched? false
    set carry? false
    set wareMask? false
    set symptoms? false
    set need-hospital? false
    set recovered? false
    set move? true
    set in-hospital? false
    set dead? false
    set is-vaccinated? false
    set dead? false

    set incubation-period random 13 + 2
    set befor-quarantine random 4 + 2
    set category-age-0_29? false
    set category-age-30_49? false
    set category-age-50_64? false
    set category-age-65+? false
  ]

  ;Create the age Categories
  ;Set the number of humens in the 0 to 29 category
  ask n-of age-0-29 humans [
    set category-age-0_29? true
  ]

  ;Set the number of humens in the 30 to 49 category
  ask n-of age-30-49 humans with [category-age-0_29? = false] [
    set category-age-30_49? true
  ]

  ;Set the number of humens in the 50 to 64 category
  ask n-of age-50-64 humans with [category-age-0_29? = false and category-age-30_49? = false][
    set category-age-50_64? true
  ]

  ;Set the number of humens in the 65+ category
  ask n-of age-65+ humans with [category-age-0_29? = false and category-age-30_49? = false and category-age-50_64? = false ][
    set category-age-65+? true
  ]

  ask n-of WareMask humans [
    set wareMask? true
    set shape "circle"
  ]

  ;;Create the infected population
  ask n-of Infected humans [
    set color yellow
    set touched? true
    set carry? true
    set infection-time 0
  ]
end


;>>>>>>> Update the global variables
to update-global-variables
  if count humans > 0
    [
      set %age_0_29 (count humans with [ category-age-0_29? ] / Totalpop) * 100
      set %age_30_49 (count humans with [ category-age-30_49? ] / Totalpop) * 100
      set %age_50_64 (count humans with [ category-age-50_64? ] / Totalpop) * 100
      set %age_65+ (count humans with [ category-age-65+? ] / Totalpop) * 100
      set %carry (count humans with [carry? = true] / Totalpop) * 100
      set %healthy (count humans with [carry? = false] / Totalpop) * 100
      set %Intencive-care (count humans with [need-hospital? = true]/ Totalpop) * 100
      set %H_29 (count humans with [carry? = false and category-age-0_29? = true] / ( count humans with [category-age-0_29? = true])) * 100
      set %H_49 (count humans with [carry? = false and category-age-30_49? = true] / ( count humans with [category-age-30_49? = true])) * 100
      set %H_64 (count humans with [carry? = false and category-age-50_64? = true] / ( count humans with [category-age-50_64? = true])) * 100
      set %H_65 (count humans with [carry? = false and category-age-65+? = true] / ( count humans with [category-age-65+? = true])) * 100
      set %Vacc (count humans with [is-vaccinated? = true] / Totalpop) * 100
      ]
end

;; ------- Create the hospital
to create-hospital
  create-hospitals 1 [
    set hospital-location patch-here
    set shape "house ranch"
    set size 3.5
    set color red
    set empty-beds hospital-beds
    set %Hospital-Empty-beds hospital-beds
  ]
end

to setup-vaccinated
  ask n-of Vaccinated-pop humans with [color = green][
    set is-vaccinated? true
    set shape "person doctor"
    set size 1.5
    set color green
  ]
end

;;; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> The go method <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
to go
   if (count humans with [color = green or color = gray] + count humans with [dead? = true]) >= Totalpop [
    stop
  ]
 ask humans [
    move
    spreadInfection
    show-symptoms
    do-quarantine
    human-satuts
    recover
    go-to-hospital
    reInfection
    died
  ]
 update-global-variables
 wait 0.4
 tick
end

;; move the humans in the envirenment
to move
  ask humans with [move? = true][
    rt random 360
    lt random 360
    fd 0.09
  ]
end


;; Spread the infection among the humans
to spreadInfection
  ;; > the senario of a human not waring the mask but he is caring the virus, he can infect another human
  ask humans in-radius 1 with [(color = yellow or color = red or color = orange) and move? = true and wareMask? = false] [
    ; Calculate the probability of getting infected
    if random 100 <= Infection-Proba [
      ; Spread infection between sick human and a healthy human without mask (he is gonna get sick for the first time)
      if any? humans in-radius 1 with [color = green and wareMask? = false and is-vaccinated? = false] [
        ask one-of humans in-radius 1 with [color = green and wareMask? = false and is-vaccinated? = false] [
          set infection-time ticks
          set touched? true
          set carry? true
          set color yellow
        ]
      ]
      ; Spread infection between sick human and a healthy human with mask
      if any? humans in-radius 1 with [color = green and wareMask? = true and is-vaccinated? = false] [
        if random-float 100 > 95 [
          ask one-of humans in-radius 1 with [color = green and wareMask? = true and is-vaccinated? = false] [
            set infection-time ticks
            set touched? true
            set carry? true
            set color yellow
          ]
        ]
      ]

      ;; If the human is vaccinated (1.5% probability of infection)
      if any? humans in-radius 1 with [color = green and wareMask? = false and is-vaccinated? = true] [
        if random-float 100 <= 1.5 [
          ask one-of humans in-radius 1 with [color = green and wareMask? = false and is-vaccinated? = true] [
            set infection-time ticks
            set touched? true
            set carry? true
            set color yellow
          ]
        ]
      ]
      ; Spread infection between sick human and a healthy human with mask
      if any? humans in-radius 1 with [color = green and wareMask? = true and is-vaccinated? = true] [
        if random-float 100 > 95 [
         if random-float 100 <= 1.5 [
            ask one-of humans in-radius 1 with [color = green and wareMask? = true and is-vaccinated? = false] [
              set infection-time ticks
              set touched? true
              set carry? true
              set color yellow
            ]
          ]
        ]
      ]

    ]
  ]

  ;; > the senario where the human is waring the mask
  ask humans in-radius 1 with [(color = yellow or color = red or color = orange) and move? = true and wareMask? = true] [
    if random-float 100 > 95 [
      ; Calculate the probability of getting infected
      if random 100 <= Infection-Proba [
        ; Spread infection between sick human and a healthy human without mask
        if any? humans in-radius 1 with [color = green and wareMask? = false and is-vaccinated? = false][
          ask one-of humans in-radius 1 with [color = green and wareMask? = false and is-vaccinated? = false] [
            set infection-time ticks
            set touched? true
            set carry? true
            set color yellow
          ]
        ]
        ; Spread infection between sick human and a healthy human with mask
        if any? humans in-radius 1 with [color = green and wareMask? = true and is-vaccinated? = false] [
          if random-float 100 > 95 [
            ask one-of humans in-radius 1 with [color = green and wareMask? = true and is-vaccinated? = false] [
              set infection-time ticks
              set touched? true
              set carry? true
              set color yellow
            ]
          ]
        ]

        ;; If the human is vaccinated (1.5%)
        if any? humans in-radius 1 with [color = green and wareMask? = false and is-vaccinated? = true][
          if random-float 100 <= 1.5 [
            ask one-of humans in-radius 1 with [color = green and wareMask? = false and is-vaccinated? = true] [
              set infection-time ticks
              set touched? true
              set carry? true
              set color yellow
            ]
          ]
        ]
        ; Spread infection between sick human and a healthy human with mask
        if any? humans in-radius 1 with [color = green and wareMask? = true and is-vaccinated? = true] [
          if random-float 100 > 95 [
            if random-float 100 <= 1.5 [
              ask one-of humans in-radius 1 with [color = green and wareMask? = true and is-vaccinated? = true] [
                set infection-time ticks
                set touched? true
                set carry? true
                set color yellow
              ]
            ]
          ]
        ]
      ]
    ]
  ]
end


; After the incubation period the symptoms will start to show
to show-symptoms
  ask humans with [color = yellow][
    if ticks >= (infection-time + incubation-period) [
      set color orange
      set shape "face sad"
      set symptoms? true
      set symptoms-time ticks
    ]
  ]
end

; If a human get sick for a long time he needs the medical assistance
to human-satuts
  ask humans with [symptoms? = true and need-hospital? = false and (category-age-0_29? = true or category-age-30_49? = true) ][
    if ticks - symptoms-time > 15 [
      if random 100 < 21 [
        set need-hospital? true
        set color red
        set move? false
        face human-home
        move-to human-home
      ]
    ]
  ]

  ask humans with [symptoms? = true and need-hospital? = false and (category-age-50_64? = true or category-age-65+? = true)][
    if ticks - symptoms-time > 7 [
      if random 100 < 42 [
        set need-hospital? true
        set color red
        set move? false
        face human-home
        move-to human-home
      ]
    ]
  ]
end


to recover
  ask humans with [(color = yellow or color = orange or color = blue) and need-hospital? = false and category-age-0_29? = true][
    if ticks - symptoms-time > 15 [
      if random 100 < 99 [
        set color gray
        set size 0.8
        set recovered? true
        ;set infected? false
        set carry? false
        set symptoms? false
        set shape "face happy"
        set move? true
      ]
    ]
  ]

  ask humans with [(color = yellow or color = orange or color = blue) and need-hospital? = false and category-age-30_49? = true][
    if ticks - symptoms-time > 15[
      if random 100 < 94 [
        set color gray
        set size 0.8
        set recovered? true
        ;set infected? false
        set carry? false
        set symptoms? false
        set shape "face happy"
        set move? true
      ]
    ]
  ]

  ask humans with [(color = yellow or color = orange or color = blue) and need-hospital? = false and category-age-50_64? = true][
    if ticks - symptoms-time > 7 [
      if random 100 < 60 [
        set color gray
        set size 0.8
        set recovered? true
        ;set infected? false
        set carry? false
        set symptoms? false
        set shape "face happy"
        set move? true
      ]
    ]
  ]

  ask humans with [(color = yellow or color = orange or color = blue) and need-hospital? = false and category-age-65+? = true][
    if ticks - symptoms-time > 7 [
      if random 100 < 47 [
        set color gray
        set size 0.8
        set recovered? true
        ;set infected? false
        set carry? false
        set symptoms? false
        set shape "face happy"
        set move? true
      ]
    ]
  ]
end

to do-quarantine
  if quarantine = "Quarantine" [
    ask humans with [symptoms? = true and need-hospital? = false][
      if ticks = (symptoms-time + befor-quarantine)[
        set color blue
        set move? false
        set shape "house"
      ]
    ]
  ]
end



;; If the human needs the medical assistance then he needs to go to the hospital
to go-to-hospital
  let availibale-hospitals hospitals with [empty-beds > 0] ;return the hospital number (the one that has empty beds)
  if any? availibale-hospitals [ ; if there is an empty bed in the hospital
    ask one-of availibale-hospitals [
      let location hospital-location
      let human-need-hospital one-of humans with [color = red] ;get a human that needs hospital
      if human-need-hospital != nobody [ ; if there is some one who needs hospital
        set empty-beds empty-beds - 1
        set %Hospital-Empty-beds %Hospital-Empty-beds - 1
        ask human-need-hospital [
          set color white
          set shape "face happy"
          wait 0.4
          face location
          move-to location
          set move? false
          set in-hospital? true
        ]
      ]
    ]
  ]
end

to reInfection
  ;; > the senario of a human not waring the mask but he is caring the virus, he can infect another human
  ask humans in-radius 1 with [(color = yellow or color = red or color = orange) and move? = true and wareMask? = false] [
    ; Calculate the probability of getting infected
    if random 100 <= Infection-Proba [
      ; Spread infection between sick human and a healthy human without mask (he is gonna get sick for the first time)
      if any? humans in-radius 1 with [color = gray and wareMask? = false][
        ;; 33% of humans with previous infection can get infected for the secound time
       if random 100 < 1.5 [
          ask one-of humans in-radius 1 with [color = gray] [
            set infection-time ticks
            set touched? true
            set carry? true
            set color yellow
          ]
        ]
      ]
      ; Spread infection between sick human and a healthy human with mask
      if any? humans in-radius 1 with [color = green and wareMask? = true] [
        if random-float 100 > 95 [
          if random 100 < 1.5 [
            ask one-of humans in-radius 1 with [color = green] [
              set infection-time ticks
              set touched? true
              set carry? true
              set color yellow
            ]
          ]
        ]
      ]
    ]
  ]

  ;; > the senario where the human is waring the mask
  ask humans in-radius 1 with [(color = yellow or color = red or color = orange) and move? = true and wareMask? = true] [
    if random-float 100 > 95 [
      ; Calculate the probability of getting infected
      if random 100 <= Infection-Proba [
        ; Spread infection between sick human and a healthy human without mask
        if any? humans in-radius 1 with [color = gray and wareMask? = false][
          if random 100 < 1.5 [
            ask one-of humans in-radius 1 with [color = gray] [
              set infection-time ticks
              set touched? true
              set carry? true
              set color yellow
            ]
          ]
        ]
        ; Spread infection between sick human and a healthy human with mask
        if any? humans in-radius 1 with [color = gray and wareMask? = true] [
          if random-float 100 > 95 [
            if random 100 < 1.5 [
              ask one-of humans in-radius 1 with [color = gray] [
                set infection-time ticks
                set touched? true
                set carry? true
                set color yellow
              ]
            ]
          ]
        ]
      ]
    ]
  ]
end

to died
  ;; The people who need Intensive care and can't go to the hospital
  ask humans with [need-hospital? = true and in-hospital? = false and dead? = false][
    set color pink
    set shape "x"
    set dead? true
    set move? false
  ]

  ;; The people who didn't recover
  ask humans with [(color = orange or color = blue) and need-hospital? = false and category-age-65+? = true and dead? = false][
    if ticks - symptoms-time > 15 [
      if random 100 > 53 [
        set color pink
        set shape "x"
        set dead? true
        set move? false
        show "0 to 29"
      ]
    ]
  ]

  ask humans with [(color = orange or color = blue) and need-hospital? = false and category-age-50_64? = true and dead? = false][
    if ticks - symptoms-time > 15 [
      if random 100 > 60 [
        set color pink
        set shape "x"
        set dead? true
        set move? false
        show "50 to 64"
      ]
    ]
  ]

  ask humans with [(color = orange or color = blue) and need-hospital? = false and category-age-30_49? = true and dead? = false][
    if ticks - symptoms-time > 15 [
      if random 100 >= 94  [
        set color pink
        set shape "x"
        set dead? true
        set move? false
        show "50 to 64"
      ]
    ]
  ]

  ask humans with [(color = orange or color = blue) and need-hospital? = false and category-age-0_29? = true and dead? = false][
    if ticks - symptoms-time > 15 [
      if random 100 >= 99  [
        set color pink
        set shape "x"
        set dead? true
        set move? false
        show "50 to 64"
      ]
    ]
  ]

  ;; People in the hospital
  ask humans with [in-hospital? = true and dead? = false and (category-age-50_64? = true or category-age-65+? = true)][
    ifelse random 100 < 90 [
      set color pink
      set shape "x"
      set dead? true
      set move? false
    ]
    [
      set color gray
      set recovered? true
      set carry? false
      set symptoms? false
      set shape "face happy"
      set move? true
      set %Hospital-Empty-beds %Hospital-Empty-beds + 1
    ]
  ]

  ask humans with [in-hospital? = true and dead? = false and (category-age-0_29? = true or category-age-30_49? = true)][
    ifelse random 100 < 50 [
      set color pink
      set shape "x"
      set dead? true
      set move? false
    ]
    [
      set color gray
      set size 0.8
      set recovered? true
      ;set infected? false
      set carry? false
      set symptoms? false
      set shape "face happy"
      set move? true
      set %Hospital-Empty-beds %Hospital-Empty-beds + 1
    ]
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
398
50
990
643
-1
-1
12.303030303030303
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

TEXTBOX
499
15
888
48
SARS-Cov2 Outbreak simulation
24
125.0
1

BUTTON
19
49
177
111
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
196
50
386
113
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

SLIDER
19
128
383
161
Totalpop
Totalpop
0
400
81.0
1
1
NIL
HORIZONTAL

SLIDER
19
173
383
206
Infected
Infected
0
Totalpop
15.0
1
1
NIL
HORIZONTAL

SLIDER
19
216
382
249
Infection-Proba
Infection-Proba
0
100
100.0
1
1
%
HORIZONTAL

SLIDER
15
378
376
411
age-0-29
age-0-29
0
Totalpop - age-30-49 - age-50-64 - age-65+
14.0
1
1
NIL
HORIZONTAL

SLIDER
16
420
376
453
age-30-49
age-30-49
0
Totalpop - age-0-29 - age-50-64 - age-65+
11.0
1
1
NIL
HORIZONTAL

SLIDER
15
463
375
496
age-50-64
age-50-64
0
Totalpop - age-0-29 - age-30-49 - age-65+
11.0
1
1
NIL
HORIZONTAL

SLIDER
15
506
375
539
age-65+
age-65+
0
Totalpop - age-30-49 - age-50-64 - age-0-29
45.0
1
1
NIL
HORIZONTAL

MONITOR
1009
88
1142
133
% age-0-29
%age_0_29
2
1
11

MONITOR
1009
139
1144
184
% age-30-49
%age_30_49
2
1
11

MONITOR
1009
192
1145
237
% age-50-64
%age_50_64
2
1
11

MONITOR
1009
242
1145
287
% age-65+
%age_65+
2
1
11

SLIDER
15
555
220
588
hospital-beds
hospital-beds
0
Totalpop
10.0
1
1
NIL
HORIZONTAL

SLIDER
19
260
382
293
WareMask
WareMask
0
Totalpop
5.0
1
1
NIL
HORIZONTAL

MONITOR
159
603
285
648
Carrying The virus
%carry
2
1
11

MONITOR
16
603
151
648
Healthy
%healthy
2
1
11

MONITOR
1532
598
1757
643
% Need Intencive care
%Intencive-care
2
1
11

TEXTBOX
1015
53
1408
115
Age Category
15
105.0
1

CHOOSER
238
545
374
590
quarantine
quarantine
"Quarantine" "No Quarantine"
0

TEXTBOX
1189
55
1279
91
Healthy
15
105.0
1

MONITOR
1162
88
1290
133
00 to 29
%H_29
2
1
11

MONITOR
1162
140
1290
185
30 to 49
%H_49
2
1
11

MONITOR
1162
195
1288
240
50 to 64
%H_64
2
1
11

MONITOR
1162
246
1287
291
65 to +
%H_65
2
1
11

TEXTBOX
128
348
261
378
Age Controllers
15
105.0
1

SLIDER
19
303
381
336
Vaccinated-pop
Vaccinated-pop
0
Totalpop - Infected
0.0
1
1
NIL
HORIZONTAL

PLOT
1005
299
1755
592
Population
Days
Number Of Humans
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Healthy" 1.0 0 -15040220 true "" "plot count humans with [color = green or color = gray]"
"Carry" 1.0 0 -1184463 true "" "plot count humans with [color = yellow]"
"Sick" 1.0 0 -2674135 true "" "plot count humans with [color = orange]"

TEXTBOX
26
15
432
43
------------ Controll Panel ----------
22
105.0
1

MONITOR
295
603
383
648
Deaths
count humans with [dead? = true]
2
1
11

MONITOR
1316
598
1525
643
Vaccinated
%Vacc
2
1
11

MONITOR
1006
598
1142
643
Masks
%sick
17
1
11

PLOT
1302
48
1755
293
hospitalisation
Days
N° Human
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Need IC" 1.0 0 -13840069 true "" "plot (%Intencive-care * 100) / Totalpop"
"Recovered" 1.0 0 -7500403 true "" "plot count humans with [color = gray]"
"Died" 1.0 0 -2674135 true "" "plot count humans with [dead? = true]"

MONITOR
1152
598
1310
643
Hospital Empty Beds
%Hospital-Empty-beds
17
1
11

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

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

house ranch
false
0
Rectangle -7500403 true true 270 120 285 255
Rectangle -7500403 true true 15 180 270 255
Polygon -7500403 true true 0 180 300 180 240 135 60 135 0 180
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 45 195 105 240
Rectangle -16777216 true false 195 195 255 240
Line -7500403 true 75 195 75 240
Line -7500403 true 225 195 225 240
Line -16777216 false 270 180 270 255
Line -16777216 false 0 180 300 180

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

person doctor
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -13345367 true false 135 90 150 105 135 135 150 150 165 135 150 105 165 90
Polygon -7500403 true true 105 90 60 195 90 210 135 105
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -1 true false 105 90 60 195 90 210 114 156 120 195 90 270 210 270 180 195 186 155 210 210 240 195 195 90 165 90 150 150 135 90
Line -16777216 false 150 148 150 270
Line -16777216 false 196 90 151 149
Line -16777216 false 104 90 149 149
Circle -1 true false 180 0 30
Line -16777216 false 180 15 120 15
Line -16777216 false 150 195 165 195
Line -16777216 false 150 240 165 240
Line -16777216 false 150 150 165 150

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
NetLogo 6.3.0
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
