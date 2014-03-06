PatternSequencer Version 0.8 (c) 2003, 2004, 2005,
	2006, 2010 Sebastian Lederer

For the website of this project, see
	http://www.insignificance.de/pseq.php

For comments, bug reports and questions contact me via
	http://www.insignificance.de/contact.php

New features in the 0.10 release:
- the interface was changed a bit: clicking on an existing
  note selects it, dragging it changes the length. A new
  button to delete the selected note was added.

New features in the 0.8 release:
- added the possibility to switch patterns via a keypress
  while playing: Pressing keys 0-9 in the "Score Window"
  selects a row and switches patterns accordingly

New features in the 0.7 release:
- compiled for Tiger
- fixed a problem when changing the current pattern while
  step recording

New features in the 0.6 release:
- the length of an existing note can now be changed by dragging
  the end of it
- step record mode added (recording a single step
  from MIDI input)

New features in the 0.5 release:
- added support for external clock
- added preferences panel, containing midi clock settings
  and color setting for the pattern matrix

New features in the 0.4 release:
- clicking inside the row above the pattern matrix changes
  current step
- new Parameter Panel allows sending of controller change
  messages

New features in the 0.3 release:
- fixed MIDI sync problems
- added auto rewind button

New features in the 0.2 release:
- MIDI port selection works
- sends MIDI clock
- velocity edit mode

This is my project to create a simple MIDI pattern/step sequencer
on Mac OS X using Cocoa and Objective-C.  It is far from finished
and will surely contain bugs, but still it is already quite usable.
It requires Mac OS X 10.3 and some kind of MIDI synthesizer. If you
don't have MIDI hardware, you can use a software synthesizer like
Pete Yandell's excellent SimpleSynth.

PatternSequencer features up to 16 parts, each of which can have 8
different patterns.  You can set MIDI channel, volume, bank and
program number for each part. Patterns can be up to 128 steps long.
Timing can be 4, 8 or 16 steps per beat.

Notes are edited on a 32x16 matrix. A note can span multiple steps
by dragging the mouse.

Patterns can be looped or arranged as a song. This is done in the
"Score Window" where you can specify which patterns should be played
in a certain sequence.


Future Plans:

- cut/paste, transpose tools, etc.
- MIDI Input
- ...



Usage Overview:

Pattern Sequencer Window:

More or less self-explanatory.  Clicking inside the pattern matrix
sets a note. If a note was already there, it is deleted. The buttons
on the left of the matrix shifts the displayed octave. The buttons
below select the section of the pattern when it is longer that the
32 steps displayed.  Dragging the mouse while setting a note changes
the length.  There are two different note editing modes: "poly" and
"mono". "Poly" mode is enabled with the button at the bottom. If
"poly" mode is enabled, different notes at the same step are allowed.
If it is disabled, setting a note clears any other notes at the
same step.  The velocity slider below the matrix sets the attack
velocity of new notes.

Velocity Edit Mode:
To the right and above the matrix are two buttons which select note
edit mode or velocity edit mode. In note edit mode clicking the
mouse sets or clears a note. In velocity edit mode, clicking a note
selects it (shown by a white selection rectangle) and allows to
change the velocity by using the velocity slider.



Score Window:

The buttons at the top create and remove new entries in the list.
You can also shuffle existing ones around with the "up" and "down"
buttons.

Just click inside the table to adjust the patterns. The length in
the first columns is in beats, not steps.

To play the song according to this list, activate the "Song Mode"
checkbox in the Pattern Sequencer Window.

When the sequencer is playing not in "Song Mode", clicking on an
entry switches patterns in all parts according to the entry.
The switch does not happen immediately, but on the first, 17th,
33th step etc (that is, on a 16-step boundary).
Also, when the "Score Window" is in front, pressing the keys "1",
"2","3", ... ,"0" selects one of the corresponding entries 1-10,
effecting a pattern switch in the same way.


Preferences Panel:

The upper section contains a color well that sets the grid color
of the pattern matrix.

The lower section contains the MIDI clock settings. You can select
whether to send clock messages and whether to use an external clock.

If the "Send Clock" and "External Clock" buttons are both checked,
the sequencer  echoes the clock messages it receives on the selected
input port to the output port selected in the pattern sequencer
window.

If "External Clock" is selected, external clock messages are only
honored if the Pattern Sequencer has been started (you clicked the
"Start" button). Please note that some operations are only possible
when the sequencer is stopped (e.g. creating new patterns). 

The "MIDI Input Port" menu selects the port to be used as an external
clock source. No other MIDI input functionality is implemented at
the moment.

The "Step Rec" button starts step recording mode. In this mode you
can record MIDI notes from an external keyboard, one step at a time.
If you hold a note (or a chord) for more than a second, the resulting
notes are 16 steps long, otherwise they have a length of one.

Click the "Stop" button to leave step recording mode.


Parameter Panel:

The Parameter Panel is accessible via the "Windows"-Menu (or
Command-3). Here you can set several MIDI parameters to be sent at
the currently selected step. The current step is the one marked
with the red rectangle in the single row above the pattern matrix.
Clicking inside this row changes the current step.

Currently, there are three parameters that can be set: Controller
Change, Program Change, and Pitch Bend.

For the Controller Change section, you can enter the controller
number and the value to be sent. You can send multiple interpolated
values during a step (for filter sweeps etc), by activating the
"Smooth" checkbox. If "Smooth" is on, several controller change
messages are sent during that step, with values beginning from the
number in the "Value" field to the "End Value" field.

In the Program Change section, you can enter the program number you
want to send at that step. (this is probably not very useful, except
for my Electribe where a program change message changes the current
pattern)

In the Pitch Bend section, there are two sliders corresponding to
the desired pitch bend value at the beginning and the end of the
step. Multiple interpolated values are automatically sent in between.

The Controller Change and Pitch Bend sections each have a "Next"
button, which sets the same parameters on the next step. If there
are different start and end values, these values are adjusted
accordingly. The end value becomes the start value, and the end
value is set off by the same amount as in the previous step. This
way, you can easily set up consecutive controller change or pitch
bend messages across multiple steps (I admit that this is a horrible
interface, but it was quick to implement)

A step for which any parameter changes are set is marked with a "P"
below the pattern matrix.


