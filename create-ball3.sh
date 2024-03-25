#!/bin/bash
#Pour inclure le décodeur dans les archives my-ball3.sh créées par create-ball3.sh 
# il faut s'assurer que le fichier decodeur est également inclus dans l'archive. 
#
# Erreurs sur les images/videos
[ $# -lt 0 ]&& exit 1 
#Nous permet d'encoder notre fichier avant de l'écrire dans notre archiveur
if test ! -e Encode.c
then
cat << 'encodeTMP' >> Encode.c
#include <stdio.h>
#include <unistd.h>

char CaraImprimable(unsigned char val) {
    char Cara[32] = {'0', '1', '2', '3', '4', '5', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'};
    return Cara[val];
}

void encode() {
    char buffer[5];
    int Lecture, flag;

    fseek(stdin, 0, SEEK_END);
    long tailleF = ftell(stdin);
    fseek(stdin, 0, SEEK_SET);

    if ((tailleF % 5) != 0) {
        flag = 1;
    }

    while ((Lecture = fread(buffer, 1, 5, stdin)) > 0) {
        for (int k = 0; k < 8; ++k) {
            char octetencode = 0;
            for (int j = 0; j < Lecture && j < 5; ++j) {
                octetencode = (octetencode << 1) | ((buffer[j] >> (7 - k)) & 1);
            }

            fprintf(stdout, "%c", CaraImprimable(octetencode));
        }
    }

    if (flag == 1)
        fprintf(stdout, "%c", '1');
    for (int i = 0; i < 7; i++)
        fprintf(stdout, "%c", '0');
}

int main() {
    encode();
    return 0;
}
encodeTMP
gcc Encode.c -o encode
fi



for j in $* 
do 
if [ ! -e my-ball3.sh ]
then
# on place le décodeur dans my-ball pour l'utiliser quand on en aura besoin
cat << 'decodeTMP' > my-ball3.sh
#!/bin/bash
cat << 'Decodage' >> Decode.c
#include <stdio.h>

char decodeChar(char c) {
    // Table de correspondance des caractères imprimables
    char Cara[32] = {'0', '1', '2', '3', '4', '5', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'};

    if (c == '\n') {
        return '\n';
    }
    for (int i = 0; i < 32; ++i) {
        if (c == Cara[i]) {
            return i;
        }
    }
    // Caractère non trouvé
    return 0;
}

void decode() {
    char buffer[8];
    int fin = 0;

    while (fread(buffer, 1, 8, stdin) > 0) {
        char octetsDecodes[5] = {0};

        if (buffer[0] == '1' && buffer[1] == '0' && buffer[2] == '0' && buffer[3] == '0' && buffer[4] == '0' && buffer[5] == '0' && buffer[6] == '0' && buffer[7] == '0') {
            fin = 1;
            break;
        }

        for (int k = 0; k < 5; ++k) {
            char octetdecode = 0;
            for (int j = 0; j < 8; ++j) {
                octetdecode = (octetdecode << 1) | ((decodeChar(buffer[j]) >> k) & 1);
            }

            octetsDecodes[4 - k] = octetdecode;
        }

        if (fin == 1) {
            break;
        }

        for (int i = 0; i < 5; ++i) {
            if (octetsDecodes[i] != 0) {
                fputc(octetsDecodes[i], stdout);
            }
        }
    }
}

int main() {
    decode();
    return 0;
}
Decodage
gcc Decode.c -o decode
chmod u+x decode
decodeTMP
fi




if [ -f $j ]
then
user=`ls -l $j | cut -d ' ' -f 1 | sed -E 's/.//' | sed 's/.../& /g'| cut -d ' ' -f 1`
group=`ls -l $j | cut -d ' ' -f 1 | sed -E 's/.//' | sed 's/.../& /g'| cut -d ' ' -f 2`
other=`ls -l $j | cut -d ' ' -f 1 | sed -E 's/.//' | sed 's/.../& /g'| cut -d ' ' -f 3`
uno=$(expr `echo  $user | sed -E 's/./& + /g' | tr 'r' '4' | tr 'w' '2' | tr 'x' '1' | tr '-' '0'`0)
dos=$(expr `echo  $group | sed -E 's/./& + /g' | tr 'r' '4' | tr 'w' '2' | tr 'x' '1' | tr '-' '0'`0)
tres=$(expr `echo  $other | sed -E 's/./& + /g' | tr 'r' '4' | tr 'w' '2' | tr 'x' '1' | tr '-' '0'`0)
#chmod contient la valeur octal des droit du fichier
chmodfin=`echo $uno$dos$tres`
#Nous archvions le fichier en l'encodant 
#Nous utilisons mkdir -p pour creer son fichier parent sa saisie soit correct grace au mkdir -p
cat <<TAG >> my-ball3.sh
./decode > "$j" << TAG_D
$(./encode -m < "$j")
TAG_D
chmod $chmodfin "$j"
TAG


fi

#On vérifie d'abord si l'argument en entrée est un dossier avant de réaliser le parcours récursive
if [ -d $j ]
then
#Tous les droits des dossiers (de forme octal) sont stocker dans les variable "uno" "dos" "tres" depuis le ls -ld 
user=`ls -ld $j | cut -d ' ' -f 1 | sed -E 's/.//' | sed 's/.../& /g'| cut -d ' ' -f 1`
group=`ls -ld $j | cut -d ' ' -f 1 | sed -E 's/.//' | sed 's/.../& /g'| cut -d ' ' -f 2`
other=`ls -ld $j | cut -d ' ' -f 1 | sed -E 's/.//' | sed 's/.../& /g'| cut -d ' ' -f 3`
uno=$(expr `echo  $user | sed -E 's/./& + /g' | tr 'r' '4' | tr 'w' '2' | tr 'x' '1' | tr '-' '0'`0)
dos=$(expr `echo  $group | sed -E 's/./& + /g' | tr 'r' '4' | tr 'w' '2' | tr 'x' '1' | tr '-' '0'`0)
tres=$(expr `echo  $other | sed -E 's/./& + /g' | tr 'r' '4' | tr 'w' '2' | tr 'x' '1' | tr '-' '0'`0)
#chmod contient la valeur octal des droit du dossier
chmoddossier=`echo $uno$dos$tres`



cat << TAG >> my-ball3.sh 
mkdir -p $j
chmod $chmoddossier "$j"
TAG
for i in $j/*
do
#Si le dossier contient un fichier, il est renvoyer dans la récusive   
  	  $0 $i
 done
 fi
done


chmod u+x my-ball3.sh
if test -e encode
then
rm encode
rm Encode.c
fi

#Nous permetera de retirer le décodeur de notre fichier après l'exec 
if test ! -e $1
then
cat << TAG >> my-ball3.sh
rm decode
rm Decode.c
TAG
fi
exit 0

