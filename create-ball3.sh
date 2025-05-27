#!/bin/bash
# Script to create self-extracting archives with custom encoding

[ $# -lt 1 ] && exit 1

# Create encoder if needed
if test ! -e Encode.c; then
cat << 'encodeTMP' > Encode.c
#include <stdio.h>
#include <unistd.h>

const char table[64] = {
    'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
    'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
    'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
    'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/'
};

void encode() {
    unsigned char buffer[3];
    int bytesRead;

    while ((bytesRead = fread(buffer, 1, 3, stdin)) > 0) {
        unsigned char char1 = buffer[0] >> 2;
        unsigned char char2 = ((buffer[0] & 0x03) << 4) | (buffer[1] >> 4);
        unsigned char char3 = ((buffer[1] & 0x0F) << 2) | (buffer[2] >> 6);
        unsigned char char4 = buffer[2] & 0x3F;

        putchar(table[char1]);
        putchar(table[char2]);
        putchar(bytesRead >= 2 ? table[char3] : '=');
        putchar(bytesRead >= 3 ? table[char4] : '=');
    }
}

int main() {
    encode();
    return 0;
}
encodeTMP
gcc Encode.c -o encode || exit 1
fi

# Initialize archive if needed
if [ ! -e my-ball3.sh ]; then
cat << 'decodeTMP' > my-ball3.sh
#!/bin/bash
cat << 'Decodage' > Decode.c
#include <stdio.h>

int decodeChar(char c) {
    const char table[64] = {
        'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
        'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
        'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
        'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/'
    };
    for (int i = 0; i < 64; ++i) {
        if (c == table[i]) return i;
    }
    return -1;
}

void decode() {
    char buffer[4];
    while (fread(buffer, 1, 4, stdin) == 4) {
        int val1 = decodeChar(buffer[0]);
        int val2 = decodeChar(buffer[1]);
        int val3 = decodeChar(buffer[2]);
        int val4 = decodeChar(buffer[3]);

        if (val1 == -1 || val2 == -1) continue;

        putchar((val1 << 2) | (val2 >> 4));
        if (buffer[2] != '=') putchar((val2 << 4) | (val3 >> 2));
        if (buffer[3] != '=') putchar((val3 << 6) | val4);
    }
}

int main() {
    decode();
    return 0;
}
Decodage
gcc Decode.c -o decode && chmod +x decode || exit 1
decodeTMP
fi

for j in "$@"; do
    if [ -f "$j" ]; then
        # permissions
        perms=$(stat -c "%a" "$j")
        
        # Encode 
        cat <<TAG >> my-ball3.sh
./decode > "$j" << 'TAG_D'
$(./encode < "$j")
TAG_D
chmod $perms "$j"
TAG

    elif [ -d "$j" ]; then
        perms=$(stat -c "%a" "$j")
        cat <<TAG >> my-ball3.sh
mkdir -p "$j"
chmod $perms "$j"
TAG
        

        find "$j" -exec "$0" {} \;
    fi
done

chmod +x my-ball3.sh
[ -e encode ] && rm encode Encode.c

[ ! -e "$1" ] && cat <<TAG >> my-ball3.sh
rm decode Decode.c
TAG

exit 0
