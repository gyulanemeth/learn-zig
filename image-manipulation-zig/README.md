Mi lenne, ha a selection matrixot úgy állítanám be, hogy nem csak 0 és 1 értékek vannak, hanem a kettő között is? Így a hsl transzformációkat részben lehetne applyolni az edgeken...

kétféleképp is el tudom ezt képzelni, hogy pl az aknakereső algoval úgy megyünk tovább, hogy a fuzzy részeken is, vagy pedig overall...

ezen kívűl kellenek ilyen selectionök
 - hsl, ahol mindhárom komponenst tól-ig értékeit meg lehet határozni
 - valamint rgb tól-igok... akár valamilyen diff is lehet, amit én definiálok.

ez izgi!!!

Olyan is kell, hogy fogok egy hsl értéket, és azokat kikeresem az egész képen, majd azok alapján nyomom az aknakereső algoritmust.... Ezt is lehet fuzzy módon