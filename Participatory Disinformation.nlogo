extensions [ nw bitstring ]

;; # Interface controls

;; ## Population controls
;; num-people -- the number of agents in the network (not including elites)
;; frac-influencers -- the fraction of agents who are influencers

;; ## Network controls
;; network-type -- the type of network to generate (preferential, random, or small-world)
;; ### Preferential attachment settings
;; min-size -- the minimum degree of connection between nodes in the preferrential attachment network
;; ### Random network settings
;; network-density -- the density of the random network
;; ### Small world settings
;; neighborhood-size -- the number of nodes connected to each node in the small world network

;; ## Elite exposure
;; variant -- the distribution of the population exposed to top-down infuence from elite rumors (uniform, irregular, block)
;; initial-green-pct -- the percentage of patches that are not exposed to elite rumors

;; ## Operation
;; ticks-to-end -- the number of ticks before the simulation ends (if it doesn't end earlier due to total rumor dissemination)
;; model-rate-1-nth -- slow down the model execution by 1 / n number of ticks, as a further refinement of the model speed slider

;; ## Influence rates
;; elite-influence -- the chance for agents to be influenced by top-down elite rumor dissemination
;; social-influence -- the chance for agents to be influenced by adopt rumors from other agents in the network
;; trade-up-influence -- the chance for an influencer agent to "trade-up" a novel rumor to the elites

;; # Rumor generation
;; rumor-generation -- the chance for an agent to spontaneously generate a new rumor during a tick
;; max-rumors -- the maximum number of different rumors that can be spread through the network; used to initialize the bitstring of rumors-heard?
;; heard-rumors-to-generate -- deterimines whether an agent must have already heard at least one rumor before they can generate any new rumors
;; influencers-generate-rumors -- determines whether influencer agents can generate rumors in addition to regulars (who always generate rumors)
;; only-one-generates -- determines whether only a single agent has a chance of generating a rumor in one tick, or if all agents have a chance in one tick

;; # Rumor dissipation
;; dissipation-rate -- The chance that agents will "forget" a rumor during a tick
;; only-one-forgets -- determines whether only a single agent has a chance of forgetting a rumor in one tick, or if all agents have a chanced in one tick

globals [
  times-heard-from-elites
  times-heard-from-social
  times-traded-up
  times-created-rumor
]

patches-own [
  vote
  total
]

turtles-own [
  rumors-heard?
]

breed [ regulars regular ]
breed [ influencers influencer ]
breed [ elites elite ]

to setup
  clear-all

  set-default-shape regulars "person"
  set-default-shape influencers "star"
  set-default-shape elites "pentagon"

  ;; Create the social network and audience agents
  setup-network

  ;; Randomly select frac-influencers % of audience agents to be influencers
  ask n-of ( frac-influencers * num-people ) turtles [
    set breed influencers
    set size 2
  ]

  ;; Set the rest of the audience agents as regulars
  ask turtles [
    if breed != influencers [
      set breed regulars
    ]
  ]

  ;; Create elites separately from the network of other agents

  ;; Fist make room for the elites to be represented above the rest of the network
  ask turtles [
    facexy xcor min-pycor
    fd 4
  ]

  ;; Create a single elite agent at the top of the world
  create-elites 1 [
    setxy 0 max-pycor - 1
    set size 3
    initialize-elite
   ]

  ;; Set up the distribution of elite exposure
  if variant = "uniform" [
   setup-elite-uniform
  ]
  if variant = "block" [
    setup-elite-block
  ]
  if variant = "irregular" [
    setup-elite-irregular
  ]

  reset-ticks
end

;; Set up the social network based on the selected network-type
to setup-network
  if network-type = "preferential" [
    nw:generate-preferential-attachment turtles links num-people min-size [
      setxy random-xcor random-ycor
      initialize-agent
    ]

    let factor sqrt count turtles
    repeat 300 [
      layout-spring turtles links (1 / factor) (7 / factor) (1 / factor)
    ]
  ]

  if network-type = "random" [
    nw:generate-random turtles links num-people network-density [
      setxy random-xcor random-ycor
      initialize-agent
    ]

    repeat 30 [ layout-spring turtles links 0.3 (world-width / 2 ) 1 ]
  ]

  if network-type = "small-world" [
    nw:generate-watts-strogatz turtles links num-people neighborhood-size 0.1 [
      setxy random-xcor random-ycor
      initialize-agent
    ]

    repeat 300 [
      layout-spring turtles links 0.3 (world-width / 3) 3
    ]
  ]
end

;; Initialize an individual "normal" (regular or influencer) agent
to initialize-agent
  set color white
  ;; initialize a bitstring representing which rumors the agent has heard, with all being false
  set rumors-heard? bitstring:make max-rumors false
end

;; Initialize an elite agent
to initialize-elite
  ;; Initialize elites with a single random rumor to start with
  let set-rumor random (max-rumors)
  set rumors-heard? bitstring:make max-rumors false
  set rumors-heard? bitstring:set rumors-heard? set-rumor true
  set color scale-color red bitstring:count1 rumors-heard? max-rumors 0
end

;; Reset the results of the simulation while keeping the same network and elite exposure layout
to reinitialize
  ask turtles [
    initialize-agent
  ]

  ask elites [
    initialize-elite
  ]

  clear-all-plots

  set times-heard-from-elites 0
  set times-heard-from-social 0
  set times-traded-up 0
  set times-created-rumor 0

  reset-ticks
end

;; Elite exposure - setup by coloring patches
;; Color all of the patches uniformly
;; This is just for effect
to setup-elite-uniform
  ask patches [
    set vote 1
    recolor-patch
  ]
end

;; Elite exposure - setup by coloring patches
;; This version just colors a contiguous block of patches
to setup-elite-block
  ;; Setup elite exposure in two blocks
  ;; Base green portion on height of world
  let green-y% (max-pycor - (world-height * initial-green-pct / 100))

  ;; Upper part of world set to green
  ask patches [
    ifelse pycor > green-y%
      [ set vote 0 ]
      [ set vote 1 ]
    recolor-patch
  ]
end

;; This is from Voting Sensitivity Analysis, but not
;; doing exactly the same and not giving all the options
;; for different types of voting.
to setup-elite-irregular
  ;; First, set all the patches to something
  ask patches [
    ifelse random 100 < initial-green-pct
      [ set vote 0 ]
      [ set vote 1 ]
    recolor-patch
  ]
  ;; Want to set the elite exposure before start,
  ;; so loop through a few times here
  ;; alternatively, could do until no votes changed.
  ;; just in case, add a counter and a stop count
  let stop-count 100
  let counter 0
  loop [
    let any-votes-changed? FALSE
    ;; Patches total votes of neighbors
    ask patches [
      set total (sum [ vote ] of neighbors )
    ]
    ; Patches set votes based on neighbors
    ask patches [
      let previous-vote vote
      if total < 3 [ set vote 0 ] ;; if majority of your neighbors vote 0, set your vote to 0
      if total = 3 [
        set vote 0
      ]
      if total = 4  [
        set vote (1 - vote) ;; invert the vote if tied
      ]
      if total = 5 [
        set vote 1
      ]
      if total > 5 [ set vote 1 ] ;; if majority of your neighbors vote 1, set your vote to 1
      if vote != previous-vote [ set any-votes-changed? true ]
      recolor-patch
    ]
    set counter counter + 1
    ; Check if end conditions reached
    if not any-votes-changed? or counter = stop-count [ stop ]
  ]
end

to recolor-patch  ;; patch procedure
  ifelse vote = 0
    [ set pcolor 58 ]   ; light green to avoid conflicting with turtle colors
    [ set pcolor 28 ]   ; light orange - avoiding blues and reds
end

to go
  ;; End the simulation when either the number of ticks exceeds ticks-to-end or there are no turtles left who haven't heard all of the rumors
  if ( ticks >= ticks-to-end or not any? turtles with [ bitstring:any0? rumors-heard? ] ) [
    stop
  ]

  ;; Fine-grained control of the model speed beyond that offered by the tick speed, in case we want to observe nuanced behavior
  if ( ticks mod model-rate-1-nth = 0 ) [

    ;; Agents attempt to adopt rumors from elites, adopt rumors from the social network, generate new rumors, or forget rumors
    ask turtles with [ not (breed = elites) ] [
      adopt-from-elites
      adopt-from-network

      ;; For performance optimization we try to do all of our processing inside of a single loop of the full agentset.
      ;; Becuase we have parameters that let us selectively apply processing to only a single agent per tick, we use the idiom
      ;; `if (random num-people = who)` instead of `ask one-of turtles`. This lets us  apply these behaviors to either the
      ;; full agentset or a single agent without potentially looping through the agentset multiple times in a single tick.

      if (not only-one-generates or random num-people = who) [
        if (breed != influencers or influencers-generate-rumors) [
          generate-rumors
        ]
      ]

      if (not only-one-forgets or random num-people = who) [
        forget-rumors
      ]
    ]

    ;; Elites attempt to adopt a traded-up rumor
    trade-up-rumors
  ]

  tick
end

;; Agent attempts to adopt an unheard rumor from exposure to the elites, based on its distribution of exposure
to adopt-from-elites
  let elite-rumors [rumors-heard?] of one-of elites
  let elite-adoption elite-influence

  if variant = "irregular" or variant = "block" [
    ;; In this version, elite-influence environment is different depending on patch
    ;; Patch color green (58) corresponds to corrective influence,
    ;; patch color orange (28) corresponds to adoptive influence
    let near-adopt-pct (count neighbors with [ pcolor = 28 ] / 8 )
    let own-adopt 0
    ifelse pcolor = 28
      [ set own-adopt 1 ]
    [ set own-adopt 0 ]
    set elite-adoption ( elite-influence * 0.5 * (near-adopt-pct + own-adopt ) )
  ]

  if (random-float 1.0 < elite-adoption) [
    set rumors-heard? adopt-rumor rumors-heard? elite-rumors
    set times-heard-from-elites times-heard-from-elites + 1
    set color scale-color red bitstring:count1 rumors-heard? max-rumors 0
  ]
end

;; Agent attempts to adopt an unheard rumor from the social network, based on the fraction of neighbors who have already adopted any rumors
to adopt-from-network
  ;; Neighbors who have adopted any rumors have an influence on the chance of adoption
  let neighbors-adopted link-neighbors with [ any-rumors ]
  let total-neighbors link-neighbors

  ;; Randomly select one of the neighbors who have adopted any rumor to be the source of the rumor that will be adopted
  let rumor-source one-of neighbors-adopted

  if count total-neighbors > 0 and random-float 1.0 < ( social-influence * count neighbors-adopted / count total-neighbors ) [
    set rumors-heard? adopt-rumor rumors-heard? [rumors-heard?] of rumor-source
    set times-heard-from-social times-heard-from-social + 1
    set color scale-color red bitstring:count1 rumors-heard? max-rumors 0
  ]

end

;; Agent attempts to generate a new rumor
to generate-rumors
  ;; Only attempt to generate a rumor if we've already heard any rumors or if that requirement is disabled
  if (not heard-rumors-to-generate or not bitstring:all0? rumors-heard? ) [

    if (random-float 1.0 < rumor-generation) [
      ;; Create a new rumor pattern
      let new-rumors create-rumor rumors-heard?
      ;; Only increment the counter if we actually created a new rumor instead of setting an existing rumor
      if ( not (rumors-heard? bitstring:contains? new-rumors )) [
        set rumors-heard? new-rumors
        set times-created-rumor times-created-rumor + 1
      ]
    ]
  ]
end

;; Agent attempts to forget a rumor that it's already heard
to forget-rumors
  if ( random-float 1.0 < dissipation-rate ) [
    set rumors-heard? forget-rumor rumors-heard?
  ]
end

;; The elite agents will attempt to learn a rumor that is being traded-up by one of the influencer agents.
to trade-up-rumors
  ;; Elites will listen to a random influencer and attempt to adopt one of the unheard rumors
  if (count influencers > 0 and random-float 1.0 < trade-up-influence) [
    let one-influencer one-of influencers
    let influencer-rumors [rumors-heard?] of one-influencer
    ask elites [
      let new-rumors adopt-rumor rumors-heard? influencer-rumors
      ;; Adopt the set of rumors if we've never heard it before
      if ( not ( rumors-heard? bitstring:contains? new-rumors )) [
        set rumors-heard? new-rumors
        set color scale-color red bitstring:count1 rumors-heard? max-rumors 0
        set times-traded-up times-traded-up + 1
      ]
    ]
  ]
end

;; Utility procedure to adopt a single new rumor that the agent hasn't heard before, if there are any.
;; Reports a new bitstring of rumors with the first novel rumor adopted, or the original bitstring.
;; If there are > 1 novel rumors, only adopt the first one.
to-report adopt-rumor [my-rumors other-rumors]
  ;; Set a series of masks to identify only the bit positions that contain an unheard rumor
  let mask my-rumors bitstring:or other-rumors
  let novel-rumors my-rumors bitstring:xor mask

  ;; Only adopt a rumor if there are any novel rumors, or else return the original rumors
  ifelse (bitstring:count1 novel-rumors > 0) [
    ;; deterimine the position of the first novel rumor in the bitstring
    let pos 0
    while [ not bitstring:first? novel-rumors ] [
      ;; Drop the first bit because it wasn't novel and increment the index
      set novel-rumors bitstring:but-first novel-rumors
      set pos pos + 1
    ]
    report bitstring:set my-rumors pos true
  ]
  [
    report my-rumors
  ]
end

;; Utility procedure to create a random rumor by setting a random bit to true. It might be a rumor that we already heard before.
to-report create-rumor [my-rumors]
  let pos random max-rumors
  report bitstring:set my-rumors pos true
end

;; Utility procedure that attempts to forget a rumor by setting a random bit to false. It might be a rumor that we never heard in the first place.
to-report forget-rumor [my-rumors]
  let pos random max-rumors
  report bitstring:set my-rumors pos false
end

;; Report if the agent has heard any rumors
to-report any-rumors
  report bitstring:count1 rumors-heard? > 0
end

;; Report the fraction of total rumors heard by the agent
to-report frac-rumors
  report bitstring:count1 rumors-heard? / max-rumors
end

;; Reports a list of all of the indexes of specific rumors that have been heard by turtles, for plotting on a histogram
to-report rumor-counts
  report reduce sentence [ map-rumors-to-positions rumors-heard? ] of turtles
end

;; Utility procedure to map the rumors to their positions, for plotting on a histogram
to-report map-rumors-to-positions [rumors]
  report (map [ [ rumor index ] -> ifelse-value rumor [index + 1] [0] ]
    bitstring:to-list rumors (n-values max-rumors [ i -> i] ) )
end
@#$#@#$#@
GRAPHICS-WINDOW
435
30
976
572
-1
-1
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
10
265
76
298
NIL
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
85
265
148
298
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

SLIDER
210
375
382
408
max-rumors
max-rumors
1
50
10.0
1
1
NIL
HORIZONTAL

CHOOSER
195
30
333
75
network-type
network-type
"preferential" "random" "small-world"
0

SLIDER
195
150
367
183
network-density
network-density
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
10
30
182
63
num-people
num-people
2
500
250.0
1
1
NIL
HORIZONTAL

SLIDER
10
70
182
103
frac-influencers
frac-influencers
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
195
95
367
128
min-size
min-size
1
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
195
205
367
238
neighborhood-size
neighborhood-size
1
50
4.0
1
1
NIL
HORIZONTAL

TEXTBOX
195
10
345
28
Network layout
12
0.0
1

TEXTBOX
10
10
160
28
Population
12
0.0
1

SLIDER
10
335
182
368
elite-influence
elite-influence
0
1
0.6
0.01
1
NIL
HORIZONTAL

SLIDER
10
375
182
408
social-influence
social-influence
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
10
415
185
448
trade-up-influence
trade-up-influence
0
1
0.25
0.01
1
NIL
HORIZONTAL

SLIDER
210
335
382
368
rumor-generation
rumor-generation
0
1
0.05
0.01
1
NIL
HORIZONTAL

PLOT
765
585
1040
755
Rumor source
time
count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"from elites" 1.0 0 -2674135 true "" "plot times-heard-from-elites / count turtles"
"from social" 1.0 0 -13791810 true "" "plot times-heard-from-social / count turtles"
"no rumors" 1.0 0 -7500403 true "" "plot count turtles with [ not any-rumors  ] * 2.5"

BUTTON
160
265
252
298
NIL
reinitialize
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
555
585
755
755
Rumor generation
time
count
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"rumors created" 1.0 0 -16777216 true "" "plot times-created-rumor"

PLOT
235
585
545
755
Rumors heard
time
average
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"rumors heard" 1.0 0 -16777216 true "" "plot mean [frac-rumors] of turtles"
"traded up" 1.0 0 -612749 true "" "plot times-traded-up / max-rumors"

TEXTBOX
10
115
160
133
Elite exposure
12
0.0
1

CHOOSER
10
135
167
180
variant
variant
"uniform" "irregular" "block"
1

SLIDER
10
185
182
218
initial-green-pct
initial-green-pct
0
100
50.0
1
1
NIL
HORIZONTAL

SWITCH
210
455
420
488
influencers-generate-rumors
influencers-generate-rumors
1
1
-1000

SLIDER
10
495
182
528
dissipation-rate
dissipation-rate
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
265
265
420
298
ticks-to-end
ticks-to-end
0
6000
3000.0
100
1
NIL
HORIZONTAL

SWITCH
210
415
420
448
heard-rumors-to-generate
heard-rumors-to-generate
0
1
-1000

SWITCH
210
495
420
528
only-one-generates
only-one-generates
0
1
-1000

SWITCH
10
535
180
568
only-one-forgets
only-one-forgets
1
1
-1000

TEXTBOX
195
80
390
106
Preferential attachment settings
12
0.0
1

TEXTBOX
195
135
345
153
Random network settings
12
0.0
1

TEXTBOX
195
190
345
208
Small world settings\t\t\t
12
0.0
1

TEXTBOX
10
315
160
333
Influence rates
12
0.0
1

TEXTBOX
210
315
360
333
Rumor generation
12
0.0
1

TEXTBOX
10
475
160
493
Rumor dissipation
12
0.0
1

PLOT
10
585
225
755
Rumor counts
rumor
turtles
0.0
10.0
0.0
100.0
true
false
"set-plot-x-range 1 max-rumors + 1\nset-plot-y-range 0 count turtles\nset-histogram-num-bars max-rumors" ""
PENS
"default" 1.0 1 -2674135 true "" "histogram rumor-counts"

SLIDER
385
110
418
256
model-rate-1-nth
model-rate-1-nth
1
10
3.0
1
1
NIL
VERTICAL

@#$#@#$#@
## WHAT IS IT?

The purpose of this model is to simulate the top-down/bottom-up dynamics of what has come to be known as "participatory disinformation."

See the article ["What is participatory disinformation?"](https://www.cip.uw.edu/2021/05/26/participatory-disinformation-kate-starbird/
) for a description of the real-world phenomenon. This is based on the work of researchers at the University of Washington Center for an Informed Public, et al, in the context of disinformation about the 2020 United States presidential election.

In short, participatory disinformation describes the feedback loop by which disinformation about a particular topic or "frame" is dissimenated in a top-down fashion by political elites to their audiences, who then produce their own false/misleading rumors about the topic in a bottom-up participatory manner. These new rumors are then "traded-up" the media chain by connected social media influencers in an attempt to reach the ear of the political elites. Finally the political elites echo these new rumors back to the audiences who originally created them, reinforcing the frame of the disinformation story.

### Model Scope

This NetLogo model focuses on a particular scope of the problem, specifically:

- Specific unique rumors spread by political elites in a top-down manner to their audiences
- Audience members who adopt rumors from these elites and from their peers in a social network
- The audience members sporadically generate new rumors and communicate them with each other
- The new rumors are further communmicated by influencers within the audience in an attempt to get them adopted by the elites
- Upon adoption, the elites spread the new rumors back to the audiences

The original real-world particpiatory disinformation phenomenon also contains other dynamics that are not included in this model, such as the audience building a sense of collective grievance, and political elites mobilizing their agrieved audiences into collective action. These features are out of the scope of this model and are not represented in the simulation.

## HOW IT WORKS

### Agents

This model contains three types of agent breeds: elites, regulars, and influencers.

- `Elites` represent the political elite agents whose rumors are adopted by the audience (`regular` and `influencer`) agents.
- `Regulars` represent the audience agents who generate new rumors, and adopt and spread rumors amongst each other in the network.
- `Influencers` represent different audience agents whose rumors will be adopted by the `elites`. They also adopt and spread rumors in the network.

_In this documentation we sometimes refer to the combined set of `regular` and `influencer` agents together as "audience" agents where it is convenient. However "audience agents" are not a specific type of named breed in the model._

### Agent Properties

Every agent, regardless of its breed, posesses a property called `rumors-heard?`.

`rumors-heard?` is a bitstring (from the NetLogo _bitstring_ extension), where each bit represents one of the unique rumors that can be adopted. If the bit is `1` or true, the specific rumor has been adopted. If the bit is `0` or false, the rumor has not been adopted.

Agents adopt a rumor from another agent by looking for the first unheard rumor in another agent's bitstring and setting the corresponding bit from `0` to `1` in their own `rumors-heard?` bitstring.

`Regular` and `influencer` agents start with no rumors heard. `Elite` agents start with a single random rumor heard.

### Agent Actions

During the execution of the model, the agents perform the following actions each step:

#### Regular and influencer agents

`Regular` agents and `influencer` agents will attempt to adopt from `elites`, adopt from the network, generate rumors, and forget rumors.

- _Adopt from elites_: The agent has a random chance of adopting the first undeard rumor from the elite agents, based on the agent's distribution of exposure to the elites (see Model Environment).
- _Adopt from the network_: The agent has a random chance of adopting the first unheard rumor from a random one of its neighbors, if any, based on the fraction of neighbors who have heard any rumors.
- _Generate rumors_: The agent has a random chance of spontaneously "learning" a random rumor. It is possible that this rumor was already heard before.
- _Forget rumors_: The agent has a random chance of spontaneously "unlearning" a random rumor.

_By default, influencers will not generate rumors, but this behavior is controlled by a switch._

_It is also possible to limit rumor generation and rumor forgetting behavior to only a single agent each step via switches._


#### Elite agents

`Elite` agents will attempt to trade-up rumors from `influencers`:

- _Trade-up to elites_: The elite will select a random influencer agent and attempt to adopt the first unherad rumor from it, if any.

### Model Environment

The model environment consists of two significan features: patch coloring to control the distribution of elite exposure to regular agents for rumor adoption from elites, and a network connecting regular and influencer agents that controls network exposure for rumor adoption from other agents in the network.

**Patch coloring** is used to indicate which audience agents have a chance of adopting rumors from the elites, which is called _elite exposure_ in the model. There are three different variations of elite exposure:

- _uniform_: all audience agents have a chance of adopting from elites
- _irregular_: only certain irregular clusters of patches are colored, based on a voting algorithm, and agents on those colored patches have a chance of adoption
- _block_: a contiguous block of patches are colored and agents on those colored patches have a chance of adoption

_Patches colored green do not have elite exposure, while patches colored light red do have elite exposure._

The **network layout** is used to connect audience agents (`regulars` and `influencers`) together in a simulation of a social network. Agents have a chance of adopting rumors from the neighbors to which they are connected in the network, with a greater chance based on the relative number of their neighbors who have also adopted any rumors. There are three different network layouts:

- Preferential attachment
- Random
- Small world (uses the Watts Strogatz algorithm to get a better small world layout)

_These different layouts do not change the functional behavior of the model, but only determine the structure and distribution of the connections between networked agents._

### Setup and Go Procedures

The **`setup`** procedure executes the following steps to initialize the model:

- Runs the `clear-all` function to clear everything between executions
- Sets a default shape for each of the three agent breeds
- Sets up the network by generating a network with `num-people` number of "audience" agents based on the `network-type` and initializes the agents' `rumors-heard?` bitstring to set all rumors to false
- Randomly selects some fraction of the agents to be influencer agents
- Sets the rest of the agents to be regular agents
- Makes visual space for the elite agent to be represented in the world by moving all of the networked agents slightly toward the bottom of the world
- Creates an elite agent separately from the networked agents and initializes the elite agent's `rumors-heard?` to have a single random rumor set to true
- Sets up the patch coloring for the distribution of elite exposure based on the `variant`
- Resets the ticks

The **`go`** procedure executes the following steps to execute agent behaviors:

- Stop the model execution if either the number of ticks has exceeded `ticks-to-end` or if there are no turtles left who have not heard all of the possible rumors (i.e. full saturation of rumor disperal)
- Optionally slow down the model execution with a fine-grained speed control based on `model-rate-1-nth`
- Ask each audience agent (`regulars` and `influencers`) to do the following behaviors:
	- Attempt to adopt an unheard rumor from the elites
	- Attempt to adopt an unheard rumor from its neighbors in the social network
	- Attempt to randomly generate a new rumor
	- Attempt to randomly forget a previously heard rumor
- Ask the elite agent to attempt to adopt a rumor from one of the influencer agents
- Finally, increment the tick

## HOW TO USE IT

### Pre-execution Controls

Use the following controls to configure how the model will be set up prior to clicking the `setup` button:

#### Population settings

- _num-people_ -- the number of audience agents in the network (not including elites)
- _frac-influencers_ -- the fraction of audience agents who are `influencers` (the remainder are `regulars`)

#### Network layout settings

- _network-type_ -- the type of network to generate (preferential, random, or small-world)

_Preferential attachment settings_

- _min-size_ -- the minimum degree of connection between nodes in the preferrential attachment network

_Random network settings_

- _network-density_ -- the density of the random network

_Small world settings_

- _neighborhood-size_ -- the number of nodes connected to each node in the small world network

#### Elite exposure settings

- _variant_ -- the distribution of the population exposed to top-down infuence from elite rumors (uniform, irregular, block)
- _initial-green-pct_ -- the percentage of patches that are not exposed to elite rumors

### Operation Controls

Use the following controls to set up and operate the model's execution:

- _setup_ -- Click the `setup` button to initialize the agents, network, and patch coloration
- _go_ -- Click the `go` button to begin the simulation
- _reinitialize_ -- Click the `reinitialize` button to reset the state of the simulation without resetting the network layout, agent placement, or patch coloration
- _ticks-to-end_ -- the number of ticks before the simulation ends (if it doesn't end earlier due to total rumor dispersal)
- _model-rate-1-nth_ -- slow down the model execution by 1 / n number of ticks, as a further refinement of the model speed slider

### Model Parameter Controls

Use the following controls to adjust behavior of agents within the simulation. It can be useful to run the simulation by clicking `go`, adjust some of these sliders, and click `reinitialize` and then `go` again to see how the settings influence the behavior using an identical network layout:


;; ## Influence rates
;; elite-influence -- the chance for agents to be influenced by top-down elite rumor dissemination
;; social-influence -- the chance for agents to be influenced by adopt rumors from other agents in the network
;; trade-up-influence -- the chance for an influencer agent to "trade-up" a novel rumor to the elites

;; # Rumor generation
;; rumor-generation -- the chance for an agent to spontaneously generate a new rumor during a tick
;; max-rumors -- the maximum number of different rumors that can be spread through the network; used to initialize the bitstring of rumors-heard?
;; heard-rumors-to-generate -- deterimines whether an agent must have already heard at least one rumor before they can generate any new rumors
;; influencers-generate-rumors -- determines whether influencer agents can generate rumors in addition to regulars (who always generate rumors)
;; only-one-generates -- determines whether only a single agent has a chance of generating a rumor in one tick, or if all agents have a chance in one tick

;; # Rumor dissipation
;; dissipation-rate -- The chance that agents will "forget" a rumor during a tick
;; only-one-forgets -- determines whether only a single agent has a chance of forgetting a rumor in one tick, or if all agents have a chanced in one tick


(how to use the model, including a description of each of the items in the Interface tab)

[describe outputs]

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

[staggered regimes of mass adoption of newly generated rumors after they have been traded up by the influencers and broadcasted by the elites]
[repeated adoption of rumors by agents who have exposure to elite influence reinforces the frame of the rumors and counteracts dissipation of rumors displayed by non-exposed agents]
[sometimes specific rumors won't catch on or get traded up, but this might be an artifact of rumor generation]

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

[change the elite exposure distribution]
[change the relative balance of elite and social influence]
[turn rumor dissipation down to zero or up high]

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

[explicitly model the process of trading up newly generated rumors through the network itself in order to reach the elites, instead of this happening "outside" of the network environment of the model]
[include elites as both part of the network and as a disconnected media force]
[change the way influencers are modeled so that it more closely matches real-world patterns of influencers, for example by making it more likely that agents that are selected as influencers are the ones with a higher degree of connection within the network]
[make rumor generation more nuanced, e.g. generation happens relative to the amount of rumors already heard]

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

[network extension]
[bitstring extension to model different rumors]

netlogo-bitstring documentation: https://github.com/garypolhill/netlogo-bitstring/tree/nl6


## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

The Spread of a Meme Across a Social Network by Kristen Amaddio

http://modelingcommons.org/browse/one_model/4424#model_tabs_browse_info

Correcting Information - delay and media effects by Kjirste Morrell

http://modelingcommons.org/browse/one_model/5125#model_tabs_browse_info

[spread of a meme in a social network]
[correcting information]

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)

[participatory disinformation studies]
[related models]
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
NetLogo 6.2.0
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
