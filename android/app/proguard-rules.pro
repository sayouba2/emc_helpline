# Flutter et les greffons Firebase gèrent leurs propres règles ; ce fichier
# n'existe que pour ce qui leur échappe.

# Les modèles que Firestore sérialise par réflexion.
-keepattributes Signature
-keepattributes *Annotation*

# Les traces restent exploitables : sans ça, un plantage remonte des noms de
# classes obfusqués, et un rapport illisible ne sert à personne.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
