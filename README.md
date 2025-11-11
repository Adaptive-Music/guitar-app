# Guitar App

This is a Flutter app to make playing guitar accessible, particularly for those with disabilities.

It allows the user to choose the chord they want to play using the app, rather than having to finger the chords themselves, which requires significant dexterity.

The user can then pluck or strum the open strings to play the notes of the selected chord.

The device's touchscreen, or an accessibility switch such as AbleNet Blue2, can be used to control chord selection.

## How to use

### Home screen

<img width="1097" height="846" alt="Screenshot 2025-11-11 at 2 01 22 pm" src="https://github.com/user-attachments/assets/0cab7607-6f12-4597-a002-c7884ebbb1b4" />

The app requires MIDI input from a Fishman TriplePlay Connect pickup to determine which strings are being played.

Each string has a corresponding note in the currently selected chord. The app plays this note each time the string is played.

The six buttons at the top represent each string, and illuminate when played. They can also be directly tapped to play notes.

There is a list of chord progressions saved in the current song on the right of the large button (hidden if there is only one progression). To change progressions, either tap directly on it in the list, or use switch 2 of Blue2, which sends a keyboard 'enter' command.

To change to the next chord in the current progression, the user can either tap on the large onscreen button, or trigger it using switch 1 of a Blue2, which sends keyboard command 'space' by default.

If there is only one progression, the user can use Blue2's switch 2 to return to the previous chord.

A chord in the chord list may also be tapped directly to select it.


### Settings page

<img width="2204" height="1690" alt="image" src="https://github.com/user-attachments/assets/6e670cc7-d313-4c33-972b-ab0b8dbc187a" />

On the left side, the chord progressions in the current song are displayed, with buttons for adding, duplicating, renaming and deleting progressions.

The currently selected chord progression is displayed underneath, with a button for adding a new chord to the end of the list. 

Songs can be created, duplicated, renamed and deleted with the buttons in the top right.

Below this is a dropdown menu for selecting a song.

Under this is the chord editor, where the currently selected chord's root note and type can be changed, or deleted.

The info button brings up a popup listing the chord types and their symbols.

Below this, there is a dropdown menu for selecting an instrument sound to be used for playing notes.

Finally, the volume boost slider can be used to output higher volume sound, reducing the effort required to play loudly, at the expense of dynamic range.


## Contributors

#### [Vincent Ekpanyaskun](https://github.com/vekp)

####  [Warren Kuah](https://github.com/W-Kuah)
