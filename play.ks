
 parameter song. parameter bpm. parameter vo is getvoice(0). local time is 4 * 60 / bpm. local notes is list(). local i is 0. until i >= song:length { notes:add(note(song[i+1], time*song[i], time*song[i]-0.1)). set i to i + 2. } vo:play(notes). 
