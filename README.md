# Meteor_Dodger
this is the final porject for the course csc258 and is designed to be used on the chip 5CSEMA5F31C6 

this project is coded in Verilog

Contributor: Yi Wai Chow, Renke Cao

**Usage**
 - decompress db.rar and audio.rar in the current directory
 - import DE1_Soc.qsf to Quartus
 - start a new project (select chip 5CSEMA5F31C6) and add all the file except the output file contain in the directory to the newly created project
 - compile and import the space_shooter.sof(file should appear in output file after compilation) to the chip 
 
 **alternative approach**
 - import the space_shooter.sof directly from the output file in the repository to the chip 5CSEMA5F31C6 
 
 ![](meteor.gif)

**Gameplay**
 - you as the player control the ship to dodge the meteor that will be floating around the screen
 - standard WASD control for ship movement
 - the amount and the speed of the meteors will increase as survival time increase
 - the number of meteors will be capped at 7 meteors
 - when the player's ship collide with any of the meteors, the game is over and will restart right after
 
 **The purpose of this game is to survival as long as you can**
