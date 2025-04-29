Installation Guide for Biddy-Hooker Script
If you encounter issues, reach out to me https://discord.gg/SxmhXXC9PJ

Step 1: Install the Script

Copy the Resource:
Place the Biddy-Hooker folder (containing client.lua, server.lua, config.lua, fxmanifest.lua) in your server's resources directory.


Ensure Resource:
Add ensure Biddy-Hooker to your server.cfg to start the resource.



Step 2: Set Up the Database

Import SQL File:
Locate install/sql/setup.sql in this folder.
Import it into your MySQL database using a tool like phpMyAdmin or a MySQL client.
This creates the player_stds table to store player STDs.
Example command (if using MySQL CLI):mysql -u your_username -p your_database < install/sql/setup.sql




Verify Table:
Ensure the player_stds table exists with columns citizenid (VARCHAR) and std (VARCHAR).



Step 3: Add Medicines to QBCore Items

Open install/items.lua in this folder.
Copy its contents to your QBCore shared items file
located at [qb]/qb-core/shared/items.lua.


Add the following to the QBShared.Items
["doxycycline"] = {["name"] = "doxycycline", ["label"] = "Doxycycline", ["weight"] = 100, ["type"] = "item", ["image"] = "doxycycline.png", ["unique"] = false, ["useable"] = true, ["shouldClose"] = true, ["combinable"] = nil, ["description"] = "Medicine to cure Chlamydia."},
["ceftriaxone"] = {["name"] = "ceftriaxone", ["label"] = "Ceftriaxone", ["weight"] = 100, ["type"] = "item", ["image"] = "ceftriaxone.png", ["unique"] = false, ["useable"] = true, ["shouldClose"] = true, ["combinable"] = nil, ["description"] = "Medicine to cure Gonorrhea."},
["penicillin"] = {["name"] = "penicillin", ["label"] = "Penicillin", ["weight"] = 100, ["type"] = "item", ["image"] = "penicillin.png", ["unique"] = false, ["useable"] = true, ["shouldClose"] = true, ["combinable"] = nil, ["description"] = "Medicine to cure Syphilis."},
["antiviral"] = {["name"] = "antiviral", ["label"] = "Antiviral", ["weight"] = 100, ["type"] = "item", ["image"] = "antiviral.png", ["unique"] = false, ["useable"] = true, ["shouldClose"] = true, ["combinable"] = nil, ["description"] = "Medicine to cure HIV."},




Add Item Images (Optional):
Place image files (doxycycline.png, ceftriaxone.png, penicillin.png, antiviral.png) in [qb]/qb-inventory/html/images/.
If you don’t have images, the items will still work, but they’ll show a no icon. 
(At  this moment i do not have Image files in,, This will be in on the next update)

Restart Server

Step 4: Test the Script

Start the Server:
Ensure oxmysql, qb-core, and Biddy-Hooker are running.


Test Hooker Service:
Go to a hooker location (e.g., vector3(139.64, -1306.44, 28.95)).
Enter a vehicle, honk (E key), and verify the hooker enters/exits the vehicle.
Check for STD contraction (25% chance) using /checkstd.


Test Health Drain:
Contract an STD (e.g., AIDS) via service or debug command.
Wait a few minutes and confirm health decreases (e.g., 10 HP/min for AIDS).
Check server logs for health drain messages.


Test Medicine Usage:
Add a medicine item to your inventory (e.g., /giveitem doxycycline 1 if admin).
Use the item (e.g., via inventory or /use doxycycline).
Verify the STD is cured if applicable (use /checkstd to confirm).


Test Multiple Hookers:
Add more locations to config.lua under Config.Hooker.locations.
Restart the script and verify hookers spawn at each spot.



Step 5: Troubleshooting

Health Drain Not Working:
Check server logs for hooker:startHealthDrain messages.
Ensure no mods interfere with health (e.g., god mode).
Share logs with the developer if issues persist.


Medicine Not Working:
Verify items are correctly added to qb-core/shared/items.lua.
Check server logs for hooker:cureSTD errors.


Hookers Not Spawning:
Confirm Config.Hooker.locations has valid coordinates.
Check client logs for spawn errors.


STD Persistence Issues:
Ensure player_stds table exists and oxmysql is configured.
Verify SQL queries in logs.



