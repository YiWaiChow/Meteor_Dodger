# Meteor_Dodger
This is the final porject for the course csc258 and is designed to be used on the chip 5CSEMA5F31C6 

This project is coded in Verilog

Contributor: Yi Wai Chow, Renke Cao

**Usage**
 - Decompress db.rar and audio.rar in the current directory
 - Import DE1_Soc.qsf to Quartus
 - Start a new project (select chip 5CSEMA5F31C6) and add all the file except the output file contain in the directory to the newly created project
 - Compile with the top level entity -project 
 - Import the space_shooter.sof(file should appear in output file after compilation) to the chip 
 - Play the Game
 
 **alternative approach**
 - Import the space_shooter.sof directly from the output file in the repository to the chip 5CSEMA5F31C6 
 
 ![](meteor.gif)

**Gameplay**
 - You as the player control the ship to dodge the meteor that will be floating around the screen
 - Standard WASD control for ship movement
 - The amount and the speed of the meteors will increase as survival time increase
 - The number of meteors will be capped at 7 meteors
 - When the player's ship collide with any of the meteors, the game is over and will restart right after
 
 **The purpose of this game is to survival as long as you can**
