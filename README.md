# Guitar App

This is a Flutter app to make playing guitar accessible, particularly for those with disabilities.

It allows the user to choose the chord they want to play using the app, rather than having to finger the chords themselves, which requires significant dexterity.

The user can then pluck or strum the open strings to play the notes of the selected chord.

The device's touchscreen, or an accessibility switch such as AbleNet Blue2, can be used to control chord selection.

## How to use

### Home screen

<img width="1101" height="795" alt="Screenshot 2025-10-29 at 9 11 22 am" src="https://github.com/user-attachments/assets/512f8126-23aa-4755-8903-a992dd731d82" />

The app requires MIDI input from a Fishman TriplePlay Connect pickup to determine which strings are being played.

Each string has a corresponding note in the currently selected chord. The app plays this note each time the string is played.

The six buttons at the top represent each string, and illuminate when played. They can also be directly tapped to play notes.

To change to the next chord in the current progression, the user can either tap on the large onscreen button, or trigger it using switch 1 of a Blue2, which sends keyboard command 'space' by default.

To go back to the previous chord, the user can use Blue2's second switch, which sends keyboard command 'enter'.

A chord in the chord list may also be tapped directly to select it.


### Settings page

<img width="1101" height="795" alt="Screenshot 2025-10-29 at 9 12 21 am" src="https://github.com/user-attachments/assets/bd64ba69-f6b1-4856-847a-570314d62a25" />

The currently selected chord progression is displayed on the left, with a button for adding a new chord to the end of the list. 

Progressions can be created, duplicated, renamed and deleted with the buttons in the top right.

Below this is a dropdown menu for selecting a progression.

Under this is the chord editor, where the currently selected chord's root note and type can be changed, or deleted.

The info button brings up a popup listing the chord types and their symbols.

Lastly, there is a dropdown menu for selecting an instrument sound to be used for playing notes.




## Contributors

#### [Vincent Ekpanyaskun](https://github.com/vekp)

####  [Warren Kuah](https://github.com/W-Kuah)
